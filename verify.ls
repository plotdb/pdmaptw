# check what `build` produced in `dist/`, the way a consumer loads it: eval the
# `*.map.js` files against a fake `pdmaptw.register` and inspect the result.
#
# the checks here are the ones that caught real breakage in past rebuilds - a ring
# wound the wrong way covering the whole sphere, a district filtered out by `mw`, a
# quantization argument silently ignored. run it after every `npm run build`.
require! <[fs path topojson-client d3-geo]>

reg = {}
global.topojson = topojson-client
global.pdmaptw = register: (type, data) -> reg[type] = data

failed = 0
ok = (cond, msg) ->
  if cond => console.log "  ok   #msg"
  else
    failed := failed + 1
    console.log "  FAIL #msg"
  cond
info = (msg) -> console.log "  --   #msg"
# render the first few offenders after a failing check, and nothing at all after a
# passing one - an empty "( )" in the log reads like a bug in the checker.
show = (list, n = 3) ->
  if !list.length => '' else " ( #{list.length}: #{list.slice(0, n).join '; '} )"

load = (fn) ->
  if !fs.exists-sync fn => return null
  (new Function (fs.read-file-sync fn).toString!)!
  reg

# expected feature counts. these are floors, not equalities: boundaries do change
# between releases. a drop below them means something was filtered out, not redistricted.
floor = county: 22, town: 360, village: 7000

parse = (data) ->
  features = topojson-client.feature data.topo, data.topo.objects.pdmaptw .features
  features.map (f) ->
    f.properties.name = <[c t v]>.map((k) -> data.meta.name[f.properties[k]]).filter(->it).join('')
  features

code-len = county: 5, town: 8, village: 11

check-features = (label, features, lv) ->
  codes = {}
  [no-code, bad-len, dup, unnamed, empty, sphere] = [0 0 0 0 0 0]
  huge = []
  features.map (f) ->
    c = f.properties.code
    if !c => no-code := no-code + 1
    else
      if c.length != code-len[lv] => bad-len := bad-len + 1
      if codes[c] => dup := dup + 1
      codes[c] = f
    if !f.properties.name => unnamed := unnamed + 1
    if !f.geometry or !f.geometry.coordinates.length => empty := empty + 1
    else
      # a ring wound the wrong way is read as the whole sphere ( 4pi ~ 12.57 sr ).
      # nothing in taiwan is anywhere near 1 sr.
      a = d3-geo.geoArea f
      if a > 1 =>
        sphere := sphere + 1
        if huge.length < 5 => huge.push "#{f.properties.name} ( #{c} ): #{a.to-fixed 2} sr"
  ok no-code == 0, "#label: every feature has a code"
  ok bad-len == 0, "#label: every code is #{code-len[lv]} digits"
  ok dup == 0, "#label: no duplicated code"
  ok unnamed == 0, "#label: every feature has a name"
  ok sphere == 0, "#label: no sphere-covering geometry#{show huge}"
  if empty => info "#label: #empty feature(s) with empty geometry ( collapsed by simplification )"
  codes

console.log "verifying dist/ ..."

national = {}
<[county town village]>.map (lv) ->
  console.log "\n#lv:"
  if !ok(!!load("dist/#lv.map.js"), "#lv: dist/#lv.map.js loads") => return
  data = reg[lv]
  features = parse data
  ok features.length >= floor[lv], "#lv: #{features.length} features ( >= #{floor[lv]} )"
  national[lv] = check-features lv, features, lv
  src = data.meta.source
  ok !!(src and src.file and src.date), "#lv: meta.source = #{JSON.stringify src}"

# the codes nest: a town code starts with its county code, a village code with its town
# code. consumers rely on this to derive a coarser code by substring.
console.log "\ncode nesting:"
if national.county and national.town =>
  orphan = [c for c of national.town when !national.county[c.substr 0 5]]
  ok orphan.length == 0, "every town code has its county#{show orphan}"
if national.town and national.village =>
  orphan = [c for c of national.village when !national.town[c.substr 0 8]]
  ok orphan.length == 0, "every village code has its town#{show orphan}"

# a specific past regression: 臺中市中區 is the smallest district in the country and gets
# filtered out by a slightly-too-high `mw`. it is the canary for that threshold.
if national.town =>
  ok !!national.town['66000010'], "臺中市中區 ( 66000010 ) survived filtering"

console.log "\ncounty subfiles:"
if !national.county => console.log "  -- skipped: no county data"
else
  counties = [f.properties.name for _, f of national.county]
  [missing, mismatch] = [[], []]
  total = town: 0, village: 0
  counties.map (name) ->
    <[town village]>.map (lv) ->
      fn = if lv == \town => "dist/county/#name.map.js" else "dist/county/#name.village.map.js"
      type = if lv == \town => "county/#name" else "county/#name/village"
      if !fs.exists-sync fn => return missing.push fn
      load fn
      if !reg[type] => return missing.push "#fn ( registered nothing as #type )"
      features = parse reg[type]
      total[lv] += features.length
      # every feature in a county file must belong to that county.
      outsider = features.filter (f) -> f.properties.name.index-of(name) != 0
      if outsider.length => mismatch.push "#type: #{outsider.length} feature(s) from another county"
      # the same sphere-covering / code checks, on the re-built topology.
      features.map (f) ->
        if f.geometry and f.geometry.coordinates.length and d3-geo.geoArea(f) > 1 =>
          mismatch.push "#type: #{f.properties.name} covers the sphere"
  ok missing.length == 0, "every county has a town and a village file#{show missing}"
  ok mismatch.length == 0, "county files contain only their own county#{show mismatch}"
  <[town village]>.map (lv) ->
    n = Object.keys(national[lv] or {}).length
    ok total[lv] == n, "#lv total across county files == national ( #{total[lv]} vs #n )"

# size is not correctness, but a missing quantization argument once made these files
# ~200x bigger without any other symptom.
console.log "\nsize:"
big = (if fs.exists-sync "dist/county" => fs.readdir-sync "dist/county" else [])
  .map (n) -> {n, size: fs.stat-sync("dist/county/#n").size}
  .filter (d) -> d.size > 512 * 1024
ok big.length == 0, "no county file over 512KB#{show big.map(-> "#{it.n} #{Math.round it.size / 1024}KB")}"
<[county town village]>.map (lv) ->
  fn = "dist/#lv.map.js"
  if !fs.exists-sync fn => info "#fn: missing"
  else info "#fn: #{Math.round fs.stat-sync(fn).size / 1024}KB"

# the checks above only look at the data. this one exercises the code a browser runs:
# load `dist/index.min.js` into a dom the way a page would, and drive the public api.
console.log "\nfrontend api:"
jsdom = try require \jsdom catch => null
if !jsdom => console.log "  -- skipped: jsdom not installed"
else
  dom = new jsdom.JSDOM "<div id='map'></div>", {url: 'http://localhost/', runScripts: \dangerously}
  win = dom.window
  # jsdom does no svg layout, so `fit()` has nothing to measure. give it fixed numbers -
  # what is under test is that fit computes and applies a transform, not the geometry.
  win.SVGElement::getBBox = -> {x: 0, y: 0, width: 2, height: 3}
  win.Element::getBoundingClientRect = -> {x: 0, y: 0, top: 0, left: 0, width: 800, height: 600}
  run = (fn) ->
    if !fs.exists-sync fn => throw new Error "#fn is missing"
    win.eval (fs.read-file-sync fn).toString!
  files = <[node_modules/d3/dist/d3.min.js node_modules/topojson-client/dist/topojson-client.min.js
    dist/index.min.js dist/town.map.js]>
  root = win.document.getElementById \map
  err = null
  map = null
  Promise.resolve!
    .then ->
      files.map run
      map := new win.pdmaptw {root, type: \town, padding: 16}
      map.init!
    .then ->
      ok win.document.querySelectorAll('#map path').length == Object.keys(national.town or {}).length,
        "init() draws one path per region"
      map.choropleth data: {'66000010': '#f00'}, empty: '#eee'
      paths = [].slice.call win.document.querySelectorAll '#map path'
      filled = paths.filter -> it.get-attribute(\fill) == '#f00'
      ok filled.length == 1, "choropleth() colours exactly the region matching the code"
      map.fit!
      ok !!(map.g.get-attribute(\transform) or '').match(/scale\(/), "fit() applies a transform"
      ok map.scale! > 0, "scale() reports the factor fit() used ( #{map.scale!.to-precision 4} )"
      hovered = null
      map.on \hover, (e) -> hovered := e.data
      paths.0.dispatch-event new win.MouseEvent \mousemove, {bubbles: true}
      ok !!(hovered and hovered.properties.code), "hover fires with the feature under the pointer"
    .catch (e) -> err := e
    .then ->
      if err =>
        failed := failed + 1
        console.log "  FAIL frontend api threw: #{err.message}"
      done!

done = ->
  console.log "\n#{if failed => "#failed check(s) FAILED" else 'all checks passed'}."
  process.exit (if failed => 1 else 0)

if !jsdom => done!
