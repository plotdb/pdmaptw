require! <[fs shapefile topojson d3-geo d3-geo-projection]>

d3 = {} <<< d3-geo
d3 <<< d3-geo-projection

opt = do
  # mw is for filtering. this will remove small polygons.
  mw: county: 0.0001, town: 0.0001, village: 0.00001
  # this is for polygon simplification. will wipe out some polygons if too simple
  w: county: 0.0001, town: 0.0001, village: 0.00001

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
      topo = topojson.topology {out: divisions}, 1e5
      topo = topojson.presimplify topo
      topo = topojson.quantize(
        topojson.simplify(topojson.filter(topo,topojson.filterWeight(topo,opt.mw[lv])), opt.w[lv]), 1e5
      )
      fs.write-file-sync "web/static/assets/topojson/#lv.topo.json", JSON.stringify(topo)
      fs.write-file-sync "dist/#lv.topo.json", JSON.stringify(topo)

proc \county
  .then -> proc \town
  .then -> proc \village
