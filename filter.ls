fs = require "fs-extra"
require! <[topojson-client topojson yargs]>

argv = yargs
  .option \name, do
    alias: \n
    description: "county name"
    type: \string
  .help \help
  .alias \help, \h
  .check (argv, options) -> return true
  .argv

county-meta = JSON.parse(fs.read-file-sync "src/topojson/county.meta.json" .toString!)
names = if argv.n => [argv.n] else county-meta.name

topo = JSON.parse(fs.read-file-sync "src/topojson/town.topo.json" .toString!)
meta = JSON.parse(fs.read-file-sync "src/topojson/town.meta.json" .toString!)
geojson = topojson-client.feature topo, topo.objects.pdmaptw

generate = (name) ->
  console.log "generating topojson for #{name} ..."
  features = geojson.features.filter (f) -> meta.name[f.properties.c] in [name]
  if !features.length =>
    console.error "no features found for county #{name}. skipped."
    return
  filtered-geojson = {pdmaptw: {type: \FeatureCollection, features}}
  topology = topojson.topology filtered-geojson, {quantization: 1e6}
  fs.ensure-dir-sync "src/topojson/county"
  fs.write-file-sync "src/topojson/county/#{name}.topo.json", JSON.stringify(topology)

names.map (n) -> generate n
