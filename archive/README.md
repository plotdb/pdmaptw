# archive

歷史圖資保存區。`src/topojson` 只保留最新一版建置結果，過去的版本放在這裡，
以便回溯、比對，或讓需要特定年份行政區界的使用者取用。

## `shp/<發布日期>/`

政府原始 shapefile 壓縮檔快照。目前只保存最初一份：

| 日期 | 內容 | 說明 |
| --- | --- | --- |
| `2019-11-21` | `COUNTY_MOI_1081121` / `TOWN_MOI_1081121` / `VILLAGE_MOI_1081121` | 專案初版 (2020-01) 使用的圖資 |

後續版本不再把原始 zip 收進版控（三份合計約 38MB）。原始檔可用 `./fetch` 重新下載，
它會從 data.gov.tw 的 dataset API 解析當前網址，並把實際使用的網址寫進
`download/<level>/source.txt`：

 - county  — https://data.gov.tw/dataset/7442 直轄市、縣市界線(TWD97經緯度)
 - town    — https://data.gov.tw/dataset/7441 鄉鎮市區界線(TWD97經緯度)
 - village — https://data.gov.tw/dataset/7438 村里界圖(TWD97經緯度)

注意這些網址提供的永遠是「當前版本」，政府端不保留舊版下載點。要保存某個年份的圖資，
就得留下當時的檔案或建置結果。

## `topojson/<版本>/`

各 pdmaptw 版本實際發布的 topojson / meta 快照（不含 `county/` 子檔，那些可由
`town.topo.json` 透過 `filter.ls` 重新產生）。

| 版本 | 圖資來源 |
| --- | --- |
| `v2.2.1` | 內政部圖資，確切發布日期不明（介於 2019-11 與 2023-04 之間，當時的下載檔未保存）。村里名稱含少數編碼損毀字元。 |

同樣的內容也存在 git 歷史裡（`git show v2.2.1-commit:src/topojson/village.topo.json`），
這裡另外放一份是為了不必翻歷史就能直接引用。
