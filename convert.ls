require! <[fs fs-extra shapefile topojson d3-geo d3-geo-projection]>

d3 = {} <<< d3-geo
d3 <<< d3-geo-projection

# there is a know issue in Windows Firefox that create a path in abnormal position if we over-simplify.
# be sure to test with the win firefox and major browsers before actually changing these params.
opt = do
  # mw is for filtering. this will remove small polygons.
  mw: county: 0.0001, town: 0.0001, village: 0.000001
  # this is for polygon simplification. will wipe out some polygons if too simple
  w: county: 0.0001, town: 0.00004, village: 0.00001

proc = (lv) ->
  Promise.resolve!
    .then ->
      console.log "process #lv..."
      name = fs.readdir-sync("download/#lv").filter(-> /\.shp$/.exec(it)).0
      if !name => return
      name = name.replace /\.shp$/, ''
      shapefile.read(
        fs.read-file-sync("download/#lv/#name.shp")
        fs.read-file-sync("download/#lv/#name.dbf")
        {encoding: 'utf-8'}
      )
    .then (divisions) ->
      meta = county: {}, town: {}, village: {}
      meta = name: {}
      divisions.features.map (d) -> <[COUNTYNAME TOWNNAME VILLNAME]>.map ->
        if d.properties[it] => meta.name[that] = 1
      meta.name = [k for k of meta.name]
      divisions.features.map (d) ->
        p = d.properties
        d.properties = q = {}
        [<[c COUNTYNAME]> <[t TOWNNAME]> <[v VILLNAME]>].map -> 
          v = meta.name.indexOf p[it.1]
          if v >= 0 => q[it.0] = v

      topo = topojson.topology {pdmaptw: divisions}, 1e5
      topo = topojson.presimplify topo
      topo = topojson.simplify(topojson.filter(topo,topojson.filterWeight(topo,opt.mw[lv])), opt.w[lv])
      try
        topo = topojson.quantize(topo, 1e5)
      catch e
        console.log e
      fs-extra.ensure-dir-sync "src/topojson"
      fs.write-file-sync "src/topojson/#lv.topo.json", JSON.stringify(topo)
      fs.write-file-sync "src/topojson/#lv.meta.json", JSON.stringify(meta)

proc \county
  .then -> proc \town
  .then -> proc \village
