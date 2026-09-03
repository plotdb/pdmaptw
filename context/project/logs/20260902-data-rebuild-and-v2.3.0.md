# 工作紀錄 2026-09-02 — 圖資重建與 v2.3.0 發布

本次工作源於另一個 session ( `0902-opendata-58` ) 使用 pdmaptw 時提出的四項需求：
帶入行政區代碼、移除 `ld$` 相依、內建 choropleth、更新過期的 README。過程中發現
`fetch` 的下載來源已失效，連帶把整條圖資產製流程重跑並修掉數個既有問題，最後發布
`2.3.0`。


## 資料來源修復

原本 `fetch` 直接寫死 `data.moi.gov.tw` 的下載網址，該 host 現已無法連線。改為從
政府資料開放平臺的 dataset API 解析當前的 SHP distribution：

    https://data.gov.tw/api/v2/rest/dataset/<id>

    county  - 7442  直轄市、縣市界線 ( TWD97 經緯度 )
    town    - 7441  鄉鎮市區界線 ( TWD97 經緯度 )
    village - 7438  村里界圖 ( TWD97 經緯度 )

實作重點：

 - 檔案實際放在 tgos.tw，路徑含中文與括號，需 percent-encode 後才能下載。
 - 下載網址寫入 `download/<lv>/source.txt` 留存。
 - 解壓縮只取 `*.shp` `*.dbf` `*.prj` `*.shx`。zip 內另有一個檔名非 UTF-8 的 xlsx，
   macOS 的 `unzip` 遇到它會以 `write error ( disk full? )` 中止。

政府端只提供最新版，舊版無法回溯下載，因此把歷史資料整理進 `archive/`：

 - `archive/shp/2019-11-21/{county,town,village}.zip` — 原本散在 `archive/` 的舊 shp
 - `archive/topojson/v2.2.1/*.{topo,meta}.json` — 即將被覆蓋、且無法再重現的 2.2.1 產出
 - `archive/README.md` — 說明來源、dataset 網址與「只有當期版本」這件事


## 行政區代碼

`convert.ls` 將 MOI 的 `COUNTYCODE` / `TOWNCODE` / `VILLCODE` 取最細的一層寫進
`properties.code`。三層有前綴關係 ( 5 / 8 / 11 碼 )，因此 consumer 可以用
`code.substring(0, 5)` 或 `(0, 8)` 自行推出上層代碼，不必再用中文名稱 join。

同時把來源資訊寫進 meta：

    meta.source = {level, file, date}

`date` 由檔名的民國日期換算，例如 `COUNTY_MOI_1140318` → `2025-03-18`。


## 產製流程的問題修正

### shapefile 選檔不穩定

新版 zip 內含補充圖層 ( `Town_Majia_Sanhe`、`Village_Sanhe` )，原本的
`readdir(...)[0]` 取到哪一個依檔案系統順序而定。改為優先比對
`<LEVEL>_<AGENCY>_<民國日期>.shp` 命名，比對不到時退回取最大的檔案。

### `filter.ls` 產出的檔案大 200 倍

`topojson.topology` 的第二個參數是 quantization 數值，原本傳的是
`{quantization: 1e6}`。物件不會通過內部的 `quantization > 0` 判斷，量化被靜默跳過。
改成 `1e5` 之後，`dist/county/*.map.js` 從最大 2.7MB 降到 8–17KB，該目錄總計
28MB → 196KB。

### 整張地圖被塗滿

`澎湖縣望安鄉` ( 10016030 ) 的 `geoArea` 為 12.6 sr ( 約 4π )，d3-geo 判定它涵蓋整個
球面，畫出來會蓋住整張圖。已發布的 2.2.1 村里資料也有兩筆同樣的問題。

原因是簡化 ( `simplify` ) 之後有兩種壞掉的環：完全退化 ( 所有點重合 ) 的環，以及
繞向被翻轉的環。d3-geo 以環的右側為區域，因此外環必須是順時針 ( shoelace 為負 )、
內環逆時針。新增的 `clean` 步驟逐環處理後重建 topology：

 - 面積為零的內環丟棄，門檻刻意設為 0 —— 都市裡最小的里只比任何合理容差大幾倍，
   設高一點就會連真實區域一起消滅 ( 曾試過 1e-9，直接少掉 8 個村里 )。
 - 每個環一律重新定向，不信任簡化器保留繞向。
 - 所有環都塌掉的 feature 保留為空的 `MultiPolygon`：畫不出東西，但仍可用 code /
   name join，不會在資料裡留下一個看不見的洞。

### 臺中市中區消失

town 層的 `filterWeight` 門檻 `mw` 在 0.0001 時會濾掉全國面積最小的行政區。
town 的 `mw` 降到 0.00003，town 從 367 筆回到 368 筆，代價約 1KB。


## 前端

### 移除 `ld$` 相依

`init()` 原本用 ldquery 找上層 svg。改用原生：

    @svg = if root.closest => root.closest \svg

`closest` 會把節點自己算進去，因此傳入 `<svg>` 時會解析成它自己，行為與原本一致。
現在傳一個單純的 `<div>` 也能運作。

### choropleth

新增 `choropleth({data, key, scale, empty})`。`data` 以 `key` ( 預設 `code`，也可用
`name` ) 為索引；有 `scale` 時把值轉成顏色，沒有就直接當顏色用；查不到的區域填
`empty` ( 預設 `#eee` )。


## 驗證

Bash 是 sandbox 環境，本機起的 http server 從宿主的 Chrome 連不到，瀏覽器驗證走不通
( 試過換檔名、127.0.0.1 / localhost、三個 port 都不行 )。改用 node 直接載入
`dist/index.js` 與 `*.map.js`，設好 `global.d3` / `global.topojson`，用 `d3.geoPath()`
產出 SVG，再以 `qlmanage` 轉 PNG 目視確認 —— 走的是同一條程式路徑。

發布後對 registry 上的 tarball 重跑同一份驗證：

 - county 22 / town 368 / village 7856，全部帶 `properties.code`
 - 三層皆無覆蓋球面的多邊形
 - `meta.source` 正確：county / town 為 `*_MOI_1140318`，village 為 `VILLAGE_NLSC_1150817`
 - `臺中市中區` ( 66000010 ) 存在；`choropleth` 以 code join 正常
 - `index.js` 與 `index.min.js` 皆無 `ld$`
 - 打包結構與 2.2.1 一致，unpacked 32.9MB → 4.2MB


## 對使用端的影響

村里邊界隨新版圖資變動：新增 241、消失 220、改名 18 ( 罕用字改為方括號表示，
例如 `磚[磘]里` )。仍以名稱 join 村里的程式會在這 18 筆上出錯，應改用 `code`。


## 待處理

GitHub 回報 21 個 dependabot 弱點，都位於 `web/static/assets/lib` 的 devDependencies，
不在 `dist` 內，未處理。
