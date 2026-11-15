require! <[fs fs-extra shapefile topojson d3-geo d3-geo-projection]>

d3 = {} <<< d3-geo
d3 <<< d3-geo-projection

# there is a know issue in Windows Firefox that create a path in abnormal position if we over-simplify.
# be sure to test with the win firefox and major browsers before actually changing these params.
opt = do
  # mw is for filtering. this will remove small polygons.
  # town uses a lower threshold than county: at 0.0001 the smallest district
  # ( 臺中市中區 ) is filtered out entirely, for ~1KB of savings.
  mw: county: 0.0001, town: 0.00003, village: 0.000001
  # this is for polygon simplification. will wipe out some polygons if too simple
  # village was 0.00001 until 2.7.0: urban villages are only a few hundred meters across, and a
  # single town's villages drawn on their own looked like low poly. 0.000001 costs ~16% in size.
  w: county: 0.0001, town: 0.00004, village: 0.000001

# simplification leaves two kinds of broken rings behind, and both are fatal because
# d3-geo reads them as covering the whole sphere - one of them paints the entire map:
#
#  - fully degenerate rings: every point identical. dropped here. the threshold is kept
#    at exactly zero on purpose - the smallest urban 里 are only a few times bigger than
#    any tolerance one would pick, and dropping them loses real regions.
#    rings whose winding got flipped. d3-geo treats a ring as the region to its right,
#    so exterior rings must be clockwise ( negative shoelace ) and holes counter-clockwise.
#    re-wind every ring instead of trusting the simplifier to keep it.
#
# the topology is then rebuilt from what survives.
eps = 0

# shoelace. positive when the ring is counter-clockwise.
ring-area = (ring) ->
  s = 0
  for i from 0 til ring.length - 1
    s += ring[i].0 * ring[i + 1].1 - ring[i + 1].0 * ring[i].1
  s / 2

rewind = (ring, ccw) ->
  if (ring-area(ring) >= 0) == !!ccw => ring else ring.slice!reverse!

clean-features = (topo, name) ->
  topojson.feature(topo, topo.objects[name]).features
  .map (f) ->
    g = f.geometry
    if !g => return null
    polygons = if g.type == \MultiPolygon => g.coordinates else [g.coordinates]
    # a polygon survives only if its outer ring does. holes are checked on their own.
    polygons = polygons
      .map (p) -> p.filter (ring, i) -> i == 0 or Math.abs(ring-area(ring)) > eps
      .filter (p) -> p.length and Math.abs(ring-area(p.0)) > eps
      .map (p) -> p.map (ring, i) -> rewind ring, i != 0
    # keep a feature whose every ring collapsed ( a handful of the smallest urban 里 ) as
    # an empty geometry: it draws nothing, but stays joinable by name / code. dropping it
    # silently would leave a hole in the data.
    if !polygons.length =>
      f.geometry = {type: \MultiPolygon, coordinates: []}
      return f
    f.geometry = if g.type == \MultiPolygon
      then {type: \MultiPolygon, coordinates: polygons}
      else {type: \Polygon, coordinates: polygons.0}
    f
  .filter -> it

# arc indices of a geometry ( negative ones are reversed: ~i )
walk-arcs = (arcs, cb) ->
  if !arcs => return
  for a in arcs => if Array.isArray(a) => walk-arcs(a, cb) else cb(if a < 0 => ~a else a)

# regions whose every ring collapsed ( zero area ), as {"<object>/<code>": true }
collapsed = (topo) ->
  ret = {}
  for name, obj of topo.objects
    for f in topojson.feature(topo, obj).features
      g = f.geometry
      polygons = if !g => [] else if g.type == \MultiPolygon => g.coordinates else [g.coordinates]
      if !polygons.some((p) -> p.length and Math.abs(ring-area(p.0)) > eps) => ret["#name/#{f.properties.code}"] = true
  ret

# every object in the topology goes through the same cleanup, and they are rebuilt into one
# topology together, so arcs shared between objects stay shared.
clean = (topo) ->
  objs = {}
  for name of topo.objects => objs[name] = {type: \FeatureCollection, features: clean-features(topo, name)}
  topojson.topology objs, 1e5

# the centroid of the largest polygon, not of the whole feature: a feature made of
# scattered islands has its spherical centroid out at sea, which is useless as a label
# position.
anchor = (g) ->
  polygons = if g.type == \MultiPolygon => g.coordinates else [g.coordinates]
  biggest = polygons
    .map (p) -> {p, a: d3.geoArea {type: \Polygon, coordinates: p}}
    .sort (a, b) -> b.a - a.a
    .0.p
  d3.geoCentroid {type: \Polygon, coordinates: biggest}

proc = (lv) ->
  name = null
  Promise.resolve!
    .then ->
      console.log "process #lv..."
      # the government zip may contain more than one shapefile ( e.g. `Town_Majia_Sanhe`,
      # supplementary layers for undetermined boundaries ). the main boundary layer is
      # named `<LEVEL>_<AGENCY>_<ROC date>` and is by far the largest, so prefer a name
      # matching that pattern, and fall back to the biggest file.
      names = fs.readdir-sync("download/#lv").filter(-> /\.shp$/.exec(it))
      if !names.length => return
      name := names.filter(-> (new RegExp("^#{lv}_[a-z]+_\\d+\\.shp$", 'i')).exec(it)).0
      if !name =>
        name := names.sort((a,b) -> fs.stat-sync("download/#lv/#b").size - fs.stat-sync("download/#lv/#a").size).0
      name := name.replace /\.shp$/, ''
      console.log "  using download/#lv/#name.shp"
      shapefile.read(
        fs.read-file-sync("download/#lv/#name.shp")
        fs.read-file-sync("download/#lv/#name.dbf")
        {encoding: 'utf-8'}
      )
    .then (divisions) ->
      meta = name: {}
      divisions.features.map (d) -> <[COUNTYNAME TOWNNAME VILLNAME]>.map ->
        if d.properties[it] => meta.name[that] = 1
      meta.name = [k for k of meta.name]
      # keep provenance: which shapefile this build came from.
      meta.source = {level: lv, file: name}
      if (date = /_(\d{7})$/.exec(name)) =>
        # roc date, e.g. 1140318 -> 2025-03-18
        d = date.1
        meta.source.date = "#{+d.substr(0,3) + 1911}-#{d.substr(3,2)}-#{d.substr(5,2)}"
      divisions.features.map (d) ->
        p = d.properties
        d.properties = q = {}
        [<[c COUNTYNAME]> <[t TOWNNAME]> <[v VILLNAME]>].map -> 
          v = meta.name.indexOf p[it.1]
          if v >= 0 => q[it.0] = v
        # the official 行政區代碼. the finest level available wins: county code is a
        # prefix of town code, which is a prefix of village code, so consumers can
        # always derive a coarser code with `code.substring(0, 5)` / `(0, 8)`.
        code = p.VILLCODE or p.TOWNCODE or p.COUNTYCODE
        if code => q.code = code

      # area and anchor point are computed here, from the untouched source geometry:
      # simplification drops small islands, which costs 連江縣 a fifth of its area, and a
      # density map built on that number would be quietly wrong. not shipped in dist -
      # `release.ls` reads it for the published lookup table.
      stat = {}
      divisions.features.map (d) ->
        code = d.properties.code
        if !code or !d.geometry => return
        [lng, lat] = anchor d.geometry
        stat[code] =
          area: +(d3.geoArea(d) * 6371.0088 * 6371.0088).to-fixed 4
          lng: +lng.to-fixed 6
          lat: +lat.to-fixed 6
      fs.write-file-sync "src/topojson/#lv.stat.json", JSON.stringify(stat)

      # each level's file also carries the level above it, merged from its own regions: village
      # files carry the towns ( object `town` ), town files the counties ( object `county` ). the
      # upper level files are drawn from different shapefiles and simplified on their own, so
      # their boundaries never line up with the level below. these are merged from the source
      # geometry and built into the same topology, so they are made of the very same arcs and
      # still line up after simplification.
      # the merge has to happen before quantization: at 1e5 the shared edges of neighbouring
      # villages no longer match everywhere, and about a third of the merged towns come out as
      # rings broken into open pieces. on the source coordinates every ring closes. one region
      # at a time keeps the unquantized topology small.
      objs = {pdmaptw: divisions}
      upper = {village: {name: \town, len: 8, keys: <[c t]>}, town: {name: \county, len: 5, keys: <[c]>}}[lv]
      if upper =>
        groups = {}
        for f in divisions.features
          if !(f.geometry and f.properties.code) => continue
          (groups[f.properties.code.substring(0, upper.len)] ||= []).push f
        objs[upper.name] =
          type: \FeatureCollection
          features: [k for k of groups].sort!map (code) ->
            fs = groups[code]
            # topology() rewrites the geometries it is given in place. work on a copy
            t = topojson.topology {v: {type: \FeatureCollection, features: JSON.parse(JSON.stringify fs)}}
            properties = {}
            for k in upper.keys => properties[k] = fs.0.properties[k]
            properties.code = code
            {type: \Feature, properties, geometry: topojson.merge(t, t.objects.v.geometries)}
      topo = topojson.topology objs, 1e5
      # simplification can collapse a small region entirely ( 36 villages at the old threshold ).
      # simplify once, find the regions that collapsed, then simplify again with every arc they use
      # kept whole ( weight Infinity ). only those regions and the edges they share keep their detail,
      # so the size barely changes. simplify() rewrites the topology, so each pass starts from a copy.
      json = JSON.stringify topo
      simplify = (keep = {}) ->
        t = topojson.presimplify JSON.parse(json)
        for name, obj of t.objects => for g in obj.geometries
          if !keep["#name/#{(g.properties or {}).code}"] => continue
          walk-arcs g.arcs, (i) -> for p in t.arcs[i] => p.2 = Infinity
        topojson.simplify(topojson.filter(t, topojson.filterWeight(t, opt.mw[lv])), opt.w[lv])
      topo = simplify!
      keep = collapsed topo
      if (n = [k for k of keep].length) =>
        console.log "  #n region(s) collapsed by simplification, simplify again keeping them: #{[k for k of keep].slice(0, 5).join ', '}"
        topo = simplify keep
        if (left = [k for k of collapsed topo]).length => console.log "  still collapsed: #{left.join ', '}"
      topo = clean topo
      console.log "  #{topo.objects.pdmaptw.geometries.length} geometries"
      fs-extra.ensure-dir-sync "src/topojson"
      fs.write-file-sync "src/topojson/#lv.topo.json", JSON.stringify(topo)
      fs.write-file-sync "src/topojson/#lv.meta.json", JSON.stringify(meta)

proc \county
  .then -> proc \town
  .then -> proc \village
