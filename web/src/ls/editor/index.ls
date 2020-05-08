(->

  map = pdmaptw.create do
    root: '#map'
    type: 'town'
  data = [["縣市", "鄉鎮"]]
  lc = {scale: d3.interpolateSpectral}
  namemap = {}
  map.init!
    .then ->
      map.fit!
      n = map.lc.meta.name
      map.lc.features.map ->
        [c,t] = [n[it.properties.c], n[it.properties.t]]
        data.push [c, t]
        namemap{}[c][t] = it

      render = ->
        d3.select map.root .selectAll \path
          .attr \fill, -> 
            val = (it.properties.value - lc.min) / ((lc.max - lc.min) or 1)
            lc.scale val
      render!

      hot = new Handsontable sheet, do
        afterChange: ->
          data.map -> if namemap[it.0] => namemap[it.0][it.1].properties.value = it.2
          lc.max = Math.max.apply null, data.map(-> it.2 or 0)
          lc.min = Math.min.apply null, data.map(-> it.2 or 0)
          render!
        data: data
        rowHeaders: true
        colHeaders: true
        filters: true
        dropdownMenu: true
        stretchH: \all
        rowHeights: 25
        minRows: 50
        minCols: 15

      ldpp = ldPalettePicker.init {ldcv: {}}
      console.log ldpp.0.get
      update-palette = (ret) ->
        pal = ret.colors.map -> ldColor.hex(it)
        d = pal.map (d,i) -> i / (pal.length - 1)
        lc.scale = d3.scaleLinear!.domain(d).range pal .interpolate(d3.interpolateHcl)
        render!

      ldpp.0.get!then (ret) -> update-palette ret

      view = new ldView do
        root: document.body
        action: click: do
          palette: ({node}) ->
            ldpp.0.get!then (ret) -> update-palette ret
          random: ({node}) ->
            data.map -> it.2 = Math.round(Math.random! * 100)
            hot.loadData data
            hot.render!

)!
/*
  * customizable data path
  * map init promise hint in doc
  * properties access
  * how to customize
  * how to access / update data
*/
