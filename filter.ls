fs = require "fs-extra"
require! <[topojson-client topojson yargs]>

argv = yargs
  .option \name, do
    alias: \n
    description: "county name"
    type: \string
  .option \level, do
    alias: \l
    description: "level to split: town ( default ) or village. repeatable."
    type: \array
  .help \help
  .alias \help, \h
  .check (argv, options) -> return true
  .argv

county-meta = JSON.parse(fs.read-file-sync "src/topojson/county.meta.json" .toString!)
names = if argv.n => [argv.n] else county-meta.name
levels = if argv.l and argv.l.length => argv.l else <[town village]>

# town files keep the historical `<county>.topo.json` name; village files get an explicit
# suffix. see `build` for the `pdmaptw.register` type each one ends up with.
suffix = town: '', village: '.village'

generate = (lv, geojson, meta, name) ->
  features = geojson.features.filter (f) -> meta.name[f.properties.c] in [name]
  if !features.length =>
    console.error "  no #lv features found for county #{name}. skipped."
    return
  filtered-geojson = {pdmaptw: {type: \FeatureCollection, features}}
  # `topology` takes the quantization factor as a plain number. passing an object
  # here silently disabled quantization and made these files ~200x bigger than needed.
  topology = topojson.topology filtered-geojson, 1e5
  fn = "src/topojson/county/#{name}#{suffix[lv]}.topo.json"
  fs.write-file-sync fn, JSON.stringify(topology)
  console.log "  #{name}: #{features.length} features -> #fn"

fs.ensure-dir-sync "src/topojson/county"
levels.map (lv) ->
  if !suffix[lv]?  =>
    console.error "unknown level #lv. skipped."
    return
  console.log "splitting #lv by county ..."
  topo = JSON.parse(fs.read-file-sync "src/topojson/#lv.topo.json" .toString!)
  meta = JSON.parse(fs.read-file-sync "src/topojson/#lv.meta.json" .toString!)
  geojson = topojson-client.feature topo, topo.objects.pdmaptw
  names.map (n) -> generate lv, geojson, meta, n
