# build the open data release: the same boundaries the frontend draws, in formats people
# can use outside this library. writes into `release/`, plus a `manifest.json` that the
# download site reads instead of hardcoding a file list.
#
# the files themselves are published as github release assets - they are too big for npm
# and open data needs permanent links, so `manifest.json` points at a tagged release.
require! <[fs fs-extra path crypto topojson-client d3-geo]>

global.d3 = d3-geo
pdmaptw = require './dist/index.js'

pkg = JSON.parse (fs.read-file-sync 'package.json').toString!
tag = "v#{pkg.version}"
base = "https://github.com/#{pkg.repository.url.replace /.*github\.com\//, ''}/releases/download/#tag"
out = 'release'

# the boundaries are published as the government writes them - 臺, not 台 - so a code and
# a name from these files join against other government datasets as-is. the javascript
# api still normalizes to 台 at runtime; that is a display convenience, not the data.
levels = <[county town village]>
level-cn = county: '縣市', town: '鄉鎮市區', village: '村里'

round = (n, d) -> +n.to-fixed d
# quantization is 1e5 over ~3 degrees, so anything past the 6th decimal is noise.
round-coords = (c) ->
  if Array.isArray c.0 => c.map round-coords else [round(c.0, 6), round(c.1, 6)]

read = (lv) ->
  topo = JSON.parse (fs.read-file-sync "src/topojson/#lv.topo.json").toString!
  meta = JSON.parse (fs.read-file-sync "src/topojson/#lv.meta.json").toString!
  # area and anchor come from `convert.ls`, which computes them on the source geometry
  # before simplification. deriving them here would inherit whatever simplification threw
  # away - 連江縣 loses a fifth of its area that way.
  stat = JSON.parse (fs.read-file-sync "src/topojson/#lv.stat.json").toString!
  features = topojson-client.feature topo, topo.objects.pdmaptw .features
    .map (f) ->
      [c, t, v] = <[c t v]>.map (k) -> meta.name[f.properties[k]]
      geometry = if f.geometry
        then {type: f.geometry.type, coordinates: round-coords f.geometry.coordinates}
        else null
      type: \Feature
      properties: {code: f.properties.code, name: [c, t, v].filter(->it).join(''), county: c, town: t, village: v}
      geometry: geometry
  {meta, features, stat}

# ---- writing -------------------------------------------------------------------------

files = []
write = (name, content, desc) ->
  fn = "#out/#name"
  fs-extra.ensure-dir-sync path.dirname fn
  fs.write-file-sync fn, content
  files.push {} <<< desc <<< do
    name: name
    size: Buffer.byte-length content
    sha256: crypto.create-hash \sha256 .update content .digest \hex
    url: "#base/#name"
  console.log "  #name ( #{Math.round(Buffer.byte-length(content) / 1024)}KB )"

geojson = (features) ->
  JSON.stringify {type: \FeatureCollection, features}

# ---- svg -----------------------------------------------------------------------------

projection = pdmaptw.projection!
geo-path = d3-geo.geoPath!projection projection

# the projection pulls 澎湖 / 金門 / 馬祖 / 釣魚臺 in towards the main island so a
# statistical map has no empty corners. that is what these svg files are for. it also
# means the shapes are not where they are on the earth - the note goes inside every file,
# because a downloaded svg gets separated from the page that explained it.
svg-note = """
  台灣行政區界 ( #{level-cn.county} / #{level-cn.town} / #{level-cn.village} ) - pdmaptw #tag
  離島 ( 澎湖、金門、馬祖、釣魚臺、彭佳嶼 ) 位置經過位移，以利於統計圖表呈現，
  非真實地理位置；需要真實座標請使用同一份 release 的 GeoJSON。
  資料來源: 內政部 / 國土測繪中心，政府資料開放授權條款第 1 版。
"""

# d3 hands the path to a context as it streams; scaling there keeps the output in a
# 1000-unit box whatever the region, so two decimals of precision means the same thing in
# a single-county file as in the national one, and one stroke-width suits both.
box-context = (k, x0, y0) ->
  d = []
  n = (v) -> +v.to-fixed 2
  moveTo: (x, y) -> d.push "M#{n (x - x0) * k},#{n (y - y0) * k}"
  lineTo: (x, y) -> d.push "L#{n (x - x0) * k},#{n (y - y0) * k}"
  closePath: -> d.push \Z
  arc: ->
  result: -> d.join ''

width = 1000

to-svg = (features, source) ->
  drawn = features.filter (f) -> f.geometry and f.geometry.coordinates.length
  [[x0, y0], [x1, y1]] = geo-path.bounds {type: \FeatureCollection, features: drawn}
  pad = Math.max(x1 - x0, y1 - y0) * 0.02
  [x0, y0, x1, y1] = [x0 - pad, y0 - pad, x1 + pad, y1 + pad]
  k = width / (x1 - x0)
  height = round (y1 - y0) * k, 2
  esc = -> it.replace /&/g, '&amp;' .replace /</g, '&lt;' .replace /"/g, '&quot;'
  # group by county so one county can be selected in an editor without hunting for it.
  groups = {}
  drawn.map (f) -> (groups[f.properties.county] ?= []).push f
  body = [c for c of groups].map (county) ->
    paths = groups[county].map (f) ->
      ctx = box-context k, x0, y0
      (d3-geo.geoPath!.projection(projection).context(ctx)) f
      "    <path id=\"#{f.properties.code}\" data-name=\"#{esc f.properties.name}\" d=\"#{ctx.result!}\"/>"
    "  <g data-name=\"#{esc county}\">\n#{paths.join '\n'}\n  </g>"
  """
  <?xml version="1.0" encoding="UTF-8"?>
  <!--
  #svg-note
  來源檔案: #{source.file} ( #{source.date} )
  -->
  <svg xmlns="http://www.w3.org/2000/svg" width="#width" height="#height" viewBox="0 0 #width #height" fill="none" stroke="#000" stroke-width="0.5">
  #{body.join '\n'}
  </svg>
  """

# ---- csv -----------------------------------------------------------------------------

csv-cell = -> if /[",\n]/.exec("#it") => "\"#{"#it".replace /"/g, '""'}\"" else "#it"
csv = (rows) -> (rows.map (r) -> r.map(csv-cell).join(',')).join('\n') + '\n'

# ---- run -----------------------------------------------------------------------------

console.log "building #out/ for #tag ..."
fs-extra.remove-sync out

data = {}
sources = {}
rows = [<[code level name county town village lng lat area_km2]>]

levels.map (lv) ->
  console.log "\n#lv:"
  {meta, features, stat} = data[lv] = read lv
  sources[lv] = meta.source
  common = {level: lv, source: meta.source}
  date = meta.source.date
  write "#lv-#date.geojson", geojson(features), {} <<< common <<< {format: \geojson, scope: \all, scope_name: \全國, projection: \wgs84}
  write "#lv-#date.svg", to-svg(features, meta.source), {} <<< common <<< {format: \svg, scope: \all, scope_name: \全國, projection: \compact}
  features.map (f) ->
    st = stat[f.properties.code] or {}
    rows.push [
      f.properties.code, lv, f.properties.name
      f.properties.county, (f.properties.town or ''), (f.properties.village or '')
      (st.lng ? ''), (st.lat ? ''), (st.area ? '')
    ]

# per county. the file name uses the county code rather than its name: these are uploaded
# as github release assets, whose names are sanitized towards ascii, and that would collapse
# every chinese name to the same string. the name lives in the manifest instead.
counties = data.county.features.map (f) -> {code: f.properties.code, name: f.properties.county}
console.log "\nper county:"
<[town village]>.map (lv) ->
  {meta, features} = data[lv]
  date = meta.source.date
  common = {level: lv, source: meta.source}
  counties.map ({code, name}) ->
    sub = features.filter (f) -> f.properties.county == name
    if !sub.length => return
    scope = {scope: code, scope_name: name}
    write "#lv-#code-#date.geojson", geojson(sub), {} <<< common <<< scope <<< {format: \geojson, projection: \wgs84}
    write "#lv-#code-#date.svg", to-svg(sub, meta.source), {} <<< common <<< scope <<< {format: \svg, projection: \compact}

console.log "\nlookup table:"
write "regions-#{sources.village.date}.csv", csv(rows), do
  level: \all, scope: \all, scope_name: \全國, format: \csv, projection: null, source: sources.village

manifest =
  name: pkg.name
  version: pkg.version
  tag: tag
  # what each government release these files were built from. the boundaries move between
  # releases, so a file is only meaningful together with this.
  source: sources
  license:
    data: '政府資料開放授權條款第 1 版'
    data_url: 'https://data.gov.tw/license'
    attribution: '內政部 / 內政部國土測繪中心'
    code: 'MIT'
  notes:
    projection:
      wgs84: 'EPSG:4326 經緯度，真實地理位置。'
      compact: '離島位置經過位移以利統計圖表呈現，非真實地理位置。'
    area: 'area_km2 為原始界線多邊形的球面面積，非簡化後的幾何；與內政部公布的土地面積統計仍有數個百分點以內的差異。'
    anchor: 'lng / lat 為該行政區最大一塊多邊形的中心，適合作標籤定位，不是幾何重心，也不保證位於陸地上。'
  files: files

fs.write-file-sync "#out/manifest.json", JSON.stringify(manifest, null, 2)
# the body of the github release. it is the page most people will land on, so it has to
# carry the source versions, the licence and the projection caveat on its own.
count = (fmt) -> files.filter(-> it.format == fmt).length
notes = """
  台灣縣市 / 鄉鎮市區 / 村里界圖，供統計圖表使用。

  ## 內容

   - GeoJSON ( #{count \geojson} 檔 ): EPSG:4326 經緯度，真實地理位置。全國一份，另按縣市分檔。
   - SVG ( #{count \svg} 檔 ): 每區一個 path，id 為行政區代碼、data-name 為名稱，依縣市分組。
   - CSV ( #{count \csv} 檔 ): 行政區代碼、名稱、標籤定位點與面積對照表。
   - manifest.json: 全部檔案的清單，含層級、範圍、格式、大小、SHA-256 與下載網址。

  ## 資料版本

  #{levels.map(-> " - #{level-cn[it]}: #{sources[it].file} ( #{sources[it].date} )").join '\n'}

  ## 注意

  SVG 的離島 ( 澎湖、金門、馬祖、釣魚臺、彭佳嶼 ) 位置經過位移，讓統計圖不會有大片空白，
  因此不是真實地理位置。需要真實座標請用 GeoJSON。

  界線經過簡化以利網頁繪製，不適合用於面積量測或套疊分析；CSV 的 area_km2 由簡化前的原始
  界線計算，與內政部公布的土地面積統計仍有數個百分點以內的差異。

  ## 授權

  原始資料為內政部 / 內政部國土測繪中心所有，依政府資料開放授權條款第 1 版提供；本 release
  為其衍生作品，沿用相同授權，使用時請標示來源。產製這些檔案的程式碼為 MIT。
  """
fs.write-file-sync "#out/NOTES.md", notes

fs-extra.copy-sync "#out/manifest.json", 'manifest.json'
total = files.reduce ((a, f) -> a + f.size), 0
console.log "\n#{files.length} files, #{Math.round total / 1048576}MB. manifest.json written."
