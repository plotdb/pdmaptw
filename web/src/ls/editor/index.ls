(->

  map = pdmaptw.create do
    root: '#map'
    type: 'town'
  data = [["縣市", "鄉鎮", "數值"]]
  lc = {hover: {}, scale: d3.interpolateSpectral}
  namemap = {}
  map.init!
    .then ->
      map.fit!
      n = map.lc.meta.name
      map.lc.features.map ->
        [c,t] = [n[it.properties.c], n[it.properties.t]]
        data.push [c, t]
        namemap{}[c][t] = it
      
      debounced-view-download = debounce 350, -> if view? => view.render \download
      render = ->
        d3.select map.root .selectAll \path
          .transition!duration 350
          .attr \fill, -> 
            val = (it.properties.value - lc.min) / ((lc.max - lc.min) or 1)
            lc.scale val
        debounced-view-download!
      render!

      Handsontable.renderers.registerRenderer \myrenderer, (instance, td, row, col, prop, value, cellProperties) ->
        Handsontable.renderers.TextRenderer.apply @, arguments
        if row == 0 => td.classList.add \head
        if isNaN(value) or !value => return

      sort-order = {}
      sort-data = (idx,asc) ->
        asc = if asc => 1 else -1
        head = data.splice(0, 1).0
        data.sort (a,b) -> return asc * (if a[idx] > b[idx] => 1 else if a[idx] < b[idx] => -1 else 0)
        data.splice 0, 0, head
        hot.render!

      hot = new Handsontable sheet, do
        afterChange: ->
          data.map -> if namemap[it.0] => namemap[it.0][it.1].properties.value = it.2
          vals = data.map(-> it.2 or 0).splice 1
          lc.max = Math.max.apply null, vals
          lc.min = Math.min.apply null, vals
          render!
        afterSelection: (r1,c1,r2,c2) ->
          if !(r1 == r2 == 0 and c1 == c2 and c2 < 3) => return
          sort-data c2, (sort-order[c2] = !sort-order[c2])
        data: data
        fixedRowsTop: 1
        rowHeaders: true
        colHeaders: true
        filters: true
        dropdownMenu: true
        stretchH: \all
        rowHeights: 25
        minRows: 50
        minCols: 15

        cells: (row, col) ->
          cellProperties = {}
          cellProperties.renderer = \myrenderer
          if row == 0 => cellProperties.readOnly = true
          return cellProperties

        customBorders: [
          {
            range:  { from : {row: 0, col: 0}, to: {row: 0, col: 99} },
            bottom: { width: 2, color: \#000}
          }
        ]

      random-data = ->
        data.map (d,i) -> if i > 0 => d.2 = Math.round(Math.random! * 100)
        hot.loadData data
        hot.render!
      random-data!

      ldpp = ldPalettePicker.init {ldcv: {}, pals: ldPalettePicker.get("loadingio")}
      update-palette = (ret) ->
        if !ret => return
        pal = ret.colors.map -> ldColor.hex(it)
        d = pal.map (d,i) -> i / (pal.length - 1)
        lc.scale = d3.scaleLinear!.domain(d).range pal .interpolate(d3.interpolateHcl)
        render!
      pals = ldPalettePicker.get(\loadingio).filter -> it.colos.length > 3
      update-palette pals[Math.floor(pals.length * Math.random!)]

      svg = ld$.find document.body, \svg, 0

      view = new ldView do
        root: document.body
        handler: do
          download: ({node}) ->
            svg.setAttribute \xmlns, "http://www.w3.org/2000/svg"
            url = URL.createObjectURL(new Blob([svg.outerHTML], type: 'text/svg+xml'))
            node.setAttribute \href, url
            node.setAttribute \download, \map.svg
            node.classList.remove \disabled

        action: click: do
          palette: ({node}) ->
            ldpp.0.get!then (ret) -> update-palette ret
          random: ({node}) -> random-data!


      popup = ld$.find document.body, \#popup, 0
      popupview = new ldView do
        root: popup
        handler: do
          name: ({node}) -> node.innerText = (lc.hover.name or '')
          value: ({node}) -> node.innerText = (lc.hover.value)
      fade-popup = debounce 2000, -> popup.classList.add \ld, \ld-fade-out
      svg.addEventListener \mouseover, (evt) ->
        if !(d = d3.select(evt.target).datum!) => return
        c = map.lc.meta.name[d.properties.c]
        t = map.lc.meta.name[d.properties.t]
        if !(row = data.filter(-> it.0 == c and it.1 == t).0) => return
        v = row.2
        lc.hover = {name: "#c#t", value: v}
        popupview.render!
        pbox = popup.parentNode.getBoundingClientRect!
        bbox = popup.getBoundingClientRect!
        [mx, my] = [evt.clientX - pbox.x, evt.clientY - pbox.y]
        dx = (if mx < pbox.width / 2 => 1 else -1 ) * (pbox.width * 0.05 >? 20)
        dy = (if my < pbox.height / 2 => 1 else -1 ) * (pbox.height * 0.05 >? 20)
        if mx > pbox.width / 2 => dx -= bbox.width
        if my > pbox.height / 2 => dy -= bbox.height
        [x,y] = [mx + dx, my + dy]
        popup.style.transform = "translate(#{x}px, #{y}px)"
        popup.classList.remove \ld, \ld-fade-out, \d-none
        fade-popup!
        
)!
/*
  * customizable data path
  * map init promise hint in doc
  * properties access
  * how to customize
  * how to access / update data
*/
