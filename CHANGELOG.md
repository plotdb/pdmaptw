# Change Logs

## v2.3.0

 - map data now carries the official 行政區代碼 as `properties.code` ( 5 / 8 / 11 digits for
   county / town / village ), so consumers can join on a stable code instead of the
   Chinese name.
 - add `choropleth({data, key, scale, empty})` for filling regions from a value lookup,
   keyed by `code` or `name`.
 - `meta.source` records which government shapefile release each file was built from.
 - rebuild from the current data: county / town `COUNTY_MOI_1140318` `TOWN_MOI_1140318`
   ( 2025-03-18 ), village `VILLAGE_NLSC_1150817` ( 2026-08-17 ).
 - drop the `ld$` ( @loadingio/ldquery ) runtime dependency: `init()` now uses native
   `Element.closest`, so a plain `<div>` root works with no extra library.
 - fix: simplification could leave a ring degenerate or wound the wrong way, which d3-geo
   reads as covering the whole sphere — one such ring painted the entire map. affected two
   村里 in v2.2.1.
 - fix: 臺中市中區 was filtered out of the town map entirely.
 - fix: `filter.ls` passed the quantization factor as an object, which silently disabled
   quantization. `dist/county/` drops from 28MB to 300KB, and the whole package from
   33MB to 4.1MB.
 - fix: `fetch` pointed at data.moi.gov.tw, which no longer exists. it now resolves the
   current download url from the data.gov.tw dataset API.
 - fix: `convert.ls` picked the first `.shp` in the folder, which is no longer the main
   boundary layer now that the government zips ship supplementary shapefiles.
 - `npm run build` now runs `filter.ls` as well, so per-county files stay in sync.
 - past releases and the original shapefiles are kept under `archive/`.

## v2.2.1

 - fix bug: released dist topojson files are not simplified.


## v2.2.0

 - generate topojsons for each county (and their corresponding towns)


## v2.1.1

 - upgrade devdeps for vulnerabilities fixing


## v2.1.0

 - add `scale()` api for getting map scale


## v2.0.1

 - bug fix: SVG element should be created with namespace.
 - upgrade dev dependencies and do audit fix


## v2.0.0

 - add `browser` field in `package.json`.
 - upgrade modules
 - patch test code to make it work with upgraded modules
 - release with compact directory structure


## v1.0.0

 - remove scoping ( scope by build script )
 - patch `window` only if module doesn't exist
 - tweak API interface: now pdmaptw itself is a constructor
 - construct necessary DOM based on any type of root.
 - map data is now js file so we can easily import.
 - fire `hover` event instead of callback by `popup` for hover event.
 - download and rebuild map files
 - upgrade dependencies


## v0.0.4

 - remove useless dependency.


## v0.0.3

 - use ssl when fetching shp files. store shp file urls in variables.
 - use deploy module instead of a deploy script.
 - build to `pdmaptw/dev` folder.
 - update build script using npx and ignore livescript header.
 - upgrade modules
 - update map data

## v0.0.2

 - upgrade modules to fix vulnerabilities

