# taiwan-map

台灣 ( "中華民國自由地區"，含台、澎、金、馬 ) 縣市、鄉鎮、村里界圖。

## usage

Fetch data and build:

```
    npm run build
```

Alternatively, execute the script manually:

```
    ./fetch
    lsc convert.ls
    ./build
```

`fetch` will download and unzip shp files from government website to download folder.
`convert.ls` will process all shp files and convert them to topojson.
`build` build the utility js `twmap` for frontend rendering.
`tool/build.sh` will process all shp files and convert them to geojson, topojson and sample svg. for getting topojson, simply use `convert.ls` directly.

For a sample usage in frontend:

```
    npm start
```

then open http://localhost:3000/



## meta.json structure

for keeping topojson metadata. lookup with cid/tid/vcode.

```
   {
     county: {
      "county-id": {c: "county-code", n: "county-name"}, ...
     },
     town: {
      "town-id": {c: "town-code", n: "town-name"}, ...
     },
     village: {
      "village-code": {n: "village-name"}, ...
     }
   }
```

properties in topojson is then converted to: 

```
    { cid: "county-id", tid: "town-id", vcode: "village-code" }
```

each field exists only when applicable.


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
