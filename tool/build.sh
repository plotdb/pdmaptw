#!/usr/bin/env bash

#
# Command Line Alternative for build.ls. perhaps just use build.ls instead.
#

LBIN=./node_modules/.bin
SIZE=480

LV=town
mkdir -p web/static/assets/img/ web/static/assets/topojson/

C=$(find download 2> /dev/null | grep "\.shp$" | wc | awk '{print $1; exit}')
if [ $C != 3 ]; then
  echo "Please run 'fetch' before building."
else
  for LV in county town village
  do
    echo "processing level $LV"
    echo "generate geojson..."
    $LBIN/shp2json --encoding utf-8 download/$LV/*.shp > out/$LV.raw.geo.json

    echo "generate simplified topojson..."
    # -P 0.003 --> larger gives more detail.
    $LBIN/geo2topo out=out/$LV.raw.geo.json | \
      $LBIN/toposimplify -P 0.003 -f | \
      $LBIN/topoquantize 1e5 > out/$LV.topo.json
    cp out/$LV.topo.json web/static/assets/
    echo "generate simplified geojson..."
    cat out/$LV.topo.json | \
      $LBIN/topo2geo out=out/$LV.geo.json 

    echo "generate simplified svg..."
    cat out/$LV.geo.json | \
      $LBIN/geo2svg -n -w $SIZE -h $SIZE > web/static/assets/img/$LV.svg
    cp out/$LV.topo.json web/static/assets/topojson/

  done

  echo "copy files to dist/ folder.."
  mkdir -p src/topojson
  rm -f src/topjson/*.json
  ls out | grep -v "raw" | xargs -I % cp out/% src/topojson

  echo "done."

  #echo "generated projected geojson..."
  #cat out/town.geo.json | \
  #  $LBIN/geoproject 'd3.geoNaturalEarth1().rotate([0, 0]).fitSize(['$SIZE', '$SIZE'], d)' > out/projected.geo.json
  #cat out/town.geo.json > out/projected.geo.json

fi
