# pdmaptw

台灣 ( "中華民國自由地區"，含台、澎、金、馬 ) 縣市、鄉鎮、村里界圖。含前端繪圖函式 ( 基於 d3.js，v4 ~ v7 皆可 )


## Installation

  npm install --save pdmaptw


## Frontend Usage

`pdmaptw` needs two globals at runtime: `d3` and `topojson` ( topojson-client ).
It only uses `d3.geoProjection` / `d3.geoPath` / `d3.select`, which are identical from
d3 v4 through v7 — the released files are tested against v7.

    <script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
    <script src="https://cdn.jsdelivr.net/npm/topojson-client@3"></script>

Colour scales are not used by the library itself; include them only if your own code
needs them:

    <script src="https://cdn.jsdelivr.net/npm/d3-scale-chromatic@3"></script>

include main js file:

    <script src="path/to/dist/index.js>"></script>

include corresponding map files:

    <script src="path/to/dist/county.map.js>"></script>
    <script src="path/to/dist/town.map.js>"></script>
    <script src="path/to/dist/village.map.js>"></script>

A single county is also available on its own, at both levels. These are much smaller than
the national files ( a county's villages are 30 ~ 220KB against 1.8MB for all of them ),
so load one of these instead when you only render one county:

    <script src="path/to/dist/county/臺中市.map.js>"></script>
    <script src="path/to/dist/county/臺中市.village.map.js>"></script>

Each map file registers itself under a type when it loads. Load them on demand if you let
the user switch levels — see `web/static/sample.html`.


Then, create map object:

    var obj = new pdmaptw(opt);
    obj.init().then(function() {
      obj.fit();
    });


## Constructor Options

 - `root`: container for this map. a CSS selector, or a DOM node — a plain `<div>`, an
   existing `<svg>`, or a `<g>` inside one. no extra dependency is needed for any of them.
 - `type`: which map to draw. must match a map file that has been loaded.
   - `'county'` / `'town'` / `'village'`: the whole country at that level.
   - `'county/<縣市名>'`: the towns of one county, e.g. `'county/臺中市'`.
     `'county/<縣市名>/town'` is the same thing spelled out.
   - `'county/<縣市名>/village'`: the villages of one county.
   - county names here are as the government writes them — `臺中市`, not `台中市`.
 - `padding`: padding in pixels used by `fit()`. defaults to 20.


## API

 - `init()`: map initialization, include data fetching / path elements creating. return promise.
 - `fit(opt)`: fit map to the size of container. options:
   - `box`: bounding box `{width, height}` for fix size hinting 
 - `scale()`: the scale factor applied by the last `fit()`.
 - `choropleth(opt)`: fill the regions from a value lookup. returns the map object.
   - `data`: an object keyed by region, e.g. `{"63000": 270, "65000": 400}`.
   - `key`: which property `data` is keyed by — `'code'` ( default ) or `'name'`.
   - `scale`: a function turning a value into a colour. omit it to use the values in
     `data` as colours directly.
   - `empty`: colour for regions absent from `data`. defaults to `#eee`.

The drawn `<path>` elements carry no fill of their own, so nothing is coloured until you
say so:

    var map = new pdmaptw({root: '#map', type: 'county'});
    map.init().then(function() {
      map.choropleth({
        data: {"63000": 270, "65000": 400, "64000": 277},
        scale: d3.scaleSequential(d3.interpolateBlues).domain([0, 400])
      });
      map.fit();
    });

`choropleth()` only sets `fill`; stroke, hover styling and anything else stays yours to do
on `map.g`.


## Events

 - `hover`: fired when user hovers on geographic paths. with parameters:
   - evt: event for mouseover.
   - data: not null if mouseover path element of map. a geojson feature — see
     [Feature Properties](#feature-properties) for what its `properties` holds.


## Class Methods

 - `projection()`: return a d3js GeoProjection for 台澎金馬地區, as compact as possible.
   It moves 澎湖 / 金門 / 馬祖 / 釣魚臺 / 彭佳嶼 in towards the main island and clamps the
   result to the resulting box, so the map has no large empty corners. The same instance is
   shared by every map object.
   - It takes one argument, an array in `[lng, lat]` order — longitude first, which is the
     GeoJSON order and the reverse of how coordinates are usually said out loud.
     `pdmaptw.projection()([121.5645, 25.0338])` is 台北 101.
   - It returns `[x, y]` in the same coordinate space the `<path>` elements are drawn in,
     so anything you position with it lines up with the map and moves with `fit()` as long
     as you append it inside `map.g`. Sizes do not scale with it, so divide a radius or a
     stroke width by `map.scale()` to keep it constant on screen.
   - Because of the offsets above, feeding it a coordinate outside 台澎金馬 gives a point
     that is clamped into the box rather than a meaningful position.
 - `normalize(str)` - name normalization, e.g., replace '臺' with '台'.


## Building Map File

After `npm install`, Fetch data and build:

    npm run build

Alternatively, execute the script manually:

    ./fetch
    ./node_modules/.bin/lsc convert.ls
    ./node_modules/.bin/lsc filter.ls
    ./build
    ./node_modules/.bin/lsc verify.ls

Past releases are kept under `archive/` — see `archive/README.md`. The government only
serves the current version of each dataset, so building over the old files is the only way
back to an earlier boundary set.

What the above commands do:

 - `fetch` downloads and unzips the shp files into `download/`. The files live on tgos.tw
   and their names carry a release date that changes on every update, so `fetch` resolves
   the current url from the data.gov.tw dataset API rather than hardcoding it, and records
   the url it used in `download/<level>/source.txt`.
 - `convert.ls` will process all shp files and convert them to topojson.
   - tweak `mw` and `w` for tweaking topojson size. be sure to test in major browsers before
     using, escpecially windows firefox since we encountered an abnormal path before.
   - simplification can leave a ring degenerate or wound the wrong way, and d3-geo reads
     such a ring as covering the whole sphere — one of them paints the entire map. the
     `clean` step drops and re-winds those, so check its output if you change `mw` / `w`.
 - `filter.ls` will generate separated county files, under `src/topojson/county/`.
   `<county>.topo.json` holds that county's towns and `<county>.village.topo.json` its
   villages. `-n <county>` limits it to one county and `-l <level>` to one level, which is
   useful while tuning.
 - `build` build the utility js `twmap` for frontend rendering.
 - `verify.ls` checks what landed in `dist/`, and `npm run build` finishes by running it.
   It loads the built files the way a browser does and asserts the things that broke in
   past rebuilds: every feature carries a code of the right length, the codes nest, no
   geometry covers the whole sphere, the smallest district survived filtering, every county
   has both of its subfiles and they add up to the national totals, no file is unexpectedly
   large, and `init` / `fit` / `choropleth` / `hover` still work in a jsdom page. Run it on
   its own with `npm run verify`.
 - `tool/build.sh` will process all shp files and convert them to geojson, topojson and sample svg.
   - for getting topojson, simply use `convert.ls` directly.


## Demonstration

For a sample usage in frontend:

    npm start

the script will start a simple server and open the demo page automatically.

`/sample.html` on that server is a smaller, self-contained page — plain HTML with no build
step, kept at `web/static/sample.html` so it can be read as one file. It covers `init()`,
`fit()` including refit on resize, `choropleth()` keyed by `code`, the `hover` event,
loading a map file on demand when the level changes, and placing a marker from a
`[lng, lat]` pair with `pdmaptw.projection()`.



## Feature Properties

Each feature drawn by `init()` carries:

 - `code`: the official 行政區代碼 from the source shapefile — 5 digits for a county
   ( `"63000"` 臺北市 ), 8 for a town ( `"63000030"` 臺北市大安區 ), 11 for a village
   ( `"63000030037"` ). A county code is a prefix of its town codes, which are a prefix
   of their village codes, so a coarser code is always `code.substring(0, 5)` /
   `code.substring(0, 8)`. **Prefer this over the name when joining your own data.**
 - `name`: the composed Chinese name, normalized with `pdmaptw.normalize` — so `"台北市"`,
   `"高雄市左營區"`, `"台東縣成功鎮"`, always in 台 form, never 臺. Town and village names
   include the county prefix; a bare `"大安區"` will not match.
 - `c` / `t` / `v`: indices into `meta.name`, from which `name` is composed. These are an
   implementation detail of the file format.

`meta` ( the second half of each `*.map.js`, also released as `<level>.meta.json` ) is:

    {
      name: [ ...names, deduplicated across all levels... ],
      source: {level: "town", file: "TOWN_MOI_1140318", date: "2025-03-18"}
    }

`meta.source` records which government shapefile release the file was built from.
It is reachable as `obj.lc.meta.source` after `init()`.

A handful of the smallest urban 里 collapse to nothing during simplification. They are
kept as features with an empty geometry, so a join on `code` still finds them — they just
draw no visible shape. Unnamed islets ( `未編定村里` ) are dropped entirely.

## 詳細產製流程

 * 取得 shp files. 
   - 可以從政府開放資料平台取得. e.g., 
     - 縣市: https://data.gov.tw/dataset/7442
     - 鄉鎮: https://data.gov.tw/dataset/7441
     - 村里: https://data.gov.tw/dataset/7438
 * shp to geojson
   - 使用 npm module: shapefile
     - npm install shapefile
     - shp2json <shp-file> ( -o <json> )
   * ( geojson 的格式說明? )
   - 轉出的geojson 仍需做投影, 而這可以先做, 就不用 runtime 做. 使用 d3-geo-projection
     - npm install d3-geo-projection
     - geoproject 'd3.geoConicEqualArea().parallels([34, 40.5]).rotate([120, 0]).fitSize([960, 960], d)' \
       < <geojson> \
       > <geojson>
     - geoConicEqualArea 適用於北美加州, 我們可以自已換投影法. 參考
       - https://github.com/d3/d3-geo-projection/blob/master/README.md
     - 可以用 geo2svg ( from d3-geo-projection ) 先輸出範本 svg ( 但大概會非常大 ):
       - geo2svg -w 960 -h 960 < <geojson> > <svg>
   - Data Join: 利用 ndjson 將 geojson 分 features 切成很多行, 方便後續處理
     - npm install ndjson
     - 切開: ndjson-split 'd.features' < <geojson> > <nd-geojson>
     - 轉換: ndjson-map 'd.id = d.properties.GEOID.slice(2), d' < <nd-geojson> > <nd-alt-geojson>
     - 串接: ndjson-cat <nd-alt-geojson> ...
     - join data: ndjson-join ...
     - 轉回 geojson: ndjson-reduce
   - 最佳化: 使用 topojson 格式.
     - npm install topojson
     - geo2topo -n tracts=<geojson> > <topojson>
     - toposimplify -p 1 -f  < <topojson> > <topojson2>
     - topoquantize 1e5 < <topojson2> > <topojson3>
   - 合併行政區塊: 使用 topomerge ( in topojson package )
     - topomerge -k 'd.id.slice(0,3)' counties=tracts < <topojson3> > <topojson4>

 * geojson to topojson


## License

Source code: MIT

