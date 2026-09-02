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
  w: county: 0.0001, town: 0.00004, village: 0.00001

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

clean = (topo) ->
  features = topojson.feature(topo, topo.objects.pdmaptw).features
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
  topojson.topology {pdmaptw: {type: \FeatureCollection, features}}, 1e5

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

      topo = topojson.topology {pdmaptw: divisions}, 1e5
      topo = topojson.presimplify topo
      topo = topojson.simplify(topojson.filter(topo,topojson.filterWeight(topo,opt.mw[lv])), opt.w[lv])
      topo = clean topo
      console.log "  #{topo.objects.pdmaptw.geometries.length} geometries"
      fs-extra.ensure-dir-sync "src/topojson"
      fs.write-file-sync "src/topojson/#lv.topo.json", JSON.stringify(topo)
      fs.write-file-sync "src/topojson/#lv.meta.json", JSON.stringify(meta)

proc \county
  .then -> proc \town
  .then -> proc \village
