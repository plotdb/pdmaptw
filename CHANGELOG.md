# Change Logs

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

