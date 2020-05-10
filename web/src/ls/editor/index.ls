(->
  lc = do
    hover: {}
    scale: d3.interpolateSpectral
    name-to-feature: {}

  ldld = new ldLoader className: 'ldld full z-fixed'
  ldld.on!

  el = do
    sheet: ld$.find document, '#sheet', 0
    preview: ld$.find document, '#preview', 0

  dataset = do
    active-sheet: 'admin'
    sheets: sheets = do
      admin:
        order: {}
        data: [["縣市", "鄉鎮", "數值"]]
      latlng:
        order: {}
        data: [["緯度", "經度", "數值"]] ++ [['','',''] for i from 0 til 50]
    random: ->
      sheets.admin.data.map (d,i) -> if i > 0 => d.2 = Math.round(Math.random! * 100)
      sheets.latlng.data.map (d,i) ->
        if !i => return
        d.0 = (Math.random! * 3.2) + 23.89 - 1.6
        d.1 = (Math.random! * 2.4) + 121 - 1.2
        d.2 = Math.round(Math.random! * 100)
      min = Math.min.apply null, sheets.latlng.data.map((d)-> d.2).splice(1)
      max = Math.max.apply null, sheets.latlng.data.map((d)-> d.2).splice(1)
      lc.rscale = d3.scaleSqrt!.domain [min, max] .range [0, 0.3]
      dataset.switch dataset.active-sheet

    sort: ({sheet, idx, is-ascending}) ->
      if !(sheet = sheets[sheet or dataset.active-sheet]) => return
      asc = if is-ascending? => sheet.order[idx] = is-ascending else (sheet.order[idx] = !sheet.order[idx])
      asc = if asc => 1 else -1
      head = sheet.data.splice(0,1).0
      sheet.data.sort (a,b) -> return asc * (if a[idx] > b[idx] => 1 else if a[idx] < b[idx] => -1 else 0)
      sheet.data.splice 0, 0, head
      dataset.hot.render!

      /*
      head = sheets.admin.data.splice(0, 1).0
      sheets.admin.data.sort (a,b) -> return asc * (if a[idx] > b[idx] => 1 else if a[idx] < b[idx] => -1 else 0)
      sheets.admin.data.splice 0, 0, head
      hot.render!
      */

    switch: (name) ->
      if !name =>
        names = [k for k of sheets]
        name = names[(names.indexOf(dataset.active-sheet) + 1) % names.length]
      if !sheets[name] => return
      dataset.active-sheet = name
      dataset.hot.loadData sheets[dataset.active-sheet].data
      dataset.hot.render!

    init: ->
      Handsontable.renderers.registerRenderer(
        \myrenderer
        (instance, td, row, col, prop, value, cellProperties) ->
          Handsontable.renderers.TextRenderer.apply @, arguments
          if row == 0 => td.classList.add \head
          if isNaN(value) or !value => return
      )

      /*
      sort-order = {}
      sort-data = (idx,asc) ->
        asc = if asc => 1 else -1
        head = sheets.admin.data.splice(0, 1).0
        sheets.admin.data.sort (a,b) -> return asc * (if a[idx] > b[idx] => 1 else if a[idx] < b[idx] => -1 else 0)
        sheets.admin.data.splice 0, 0, head
        hot.render!
      */

      dataset.hot = hot = new Handsontable el.sheet, do
        afterChange: ->
          sheets.admin.data.map ->
            if lc.name-to-feature[it.0] => lc.name-to-feature[it.0][it.1].properties.value = it.2
          vals = sheets.admin.data.map(-> it.2 or 0).splice 1
          lc.max = Math.max.apply null, vals
          lc.min = Math.min.apply null, vals
          vis.render!
        afterSelection: (r1,c1,r2,c2) ->
          if !(r1 == r2 == 0 and c1 == c2 and c2 < 3) => return
          dataset.sort {idx: c2}
          #sort-data c2, (sort-order[c2] = !sort-order[c2])
        data: sheets.admin.data
        fixedRowsTop: 1
        rowHeaders: true
        colHeaders: true
        filters: true
        dropdownMenu: true
        stretchH: \all
        rowHeights: 25
        minRows: 50
        minCols: 10

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

      dataset.random!

  ctrl = do
    view: null
    download: debounce 350, -> if ctrl.view? => ctrl.view.render \download
    init: ->
      view = new ldView do
        root: document.body
        handler: do
          download: ({node}) ->
            if vis.map and vis.map.root => svg = ld$.find vis.map.root, 'svg', 0
            if !svg => return
            svg.setAttribute \xmlns, "http://www.w3.org/2000/svg"
            url = URL.createObjectURL(new Blob([svg.outerHTML], type: 'text/svg+xml'))
            node.setAttribute \href, url
            node.setAttribute \download, \map.svg
            node.classList.remove \disabled
        action: click: do
          toggle: ({node}) ->
            dataset.switch node.getAttribute(\data-name)
            view.getAll(\toggle).map -> it.classList.remove \active
            node.classList.add \active
          palette: ({node}) ->
            vis.ldpp.0.get!then (ret) -> vis.set \palette, ret
          random: ({node}) -> dataset.random!


  vis = do
    map: null
    ldpp: ldPalettePicker.init {ldcv: {}, pals: ldPalettePicker.get("loadingio")}
    set: (name, value) ->
      if name != \palette => return
      if !value => return
      pal = value.colors.map -> ldColor.hex(it)
      d = pal.map (d,i) -> i / (pal.length - 1)
      lc.scale = d3.scaleLinear!.domain(d).range pal .interpolate(d3.interpolateHcl)
      vis.render!

    render: ->
      root = d3.select vis.map.root
      root.selectAll \path
        .transition!duration 350
        .attr \fill, -> 
          val = (it.properties.value - lc.min) / ((lc.max - lc.min) or 1)
          lc.scale val
      root.select \g .selectAll \circle
        .data sheets.latlng.data
        .enter!append \circle
      root.select \g .selectAll \circle
        .attr \fill, -> \#000
        .attr 'fill-opacity', 0.2
        .attr \cx, (d,i,n) -> 
          [lat,lng] = [d.0, d.1]
          ret = pdmaptw.projection([lng, lat]).0
          return if isNaN ret => 0 else ret
        .attr \cy, (d,i,n) -> 
          [lat,lng] = [d.0, d.1]
          ret = pdmaptw.projection([lng, lat]).1
          return if isNaN ret => 0 else ret
        .attr \r, (d,i) ->
          ret = if lc.rscale => lc.rscale(d.2) else 0
          return if isNaN(ret) => 0 else ret
      ctrl.download!

    init: ->
      vis.map = map = pdmaptw.create { root: el.preview, type: 'town' }

      map.init!
        .then ->
          map.fit!
          n = map.lc.meta.name
          map.lc.features.map ->
            [c,t] = [n[it.properties.c], n[it.properties.t]]
            sheets.admin.data.push [c, t]
            lc.name-to-feature{}[c][t] = it
          
          dataset.init!

          # set palette will render vis
          pals = ldPalettePicker.get(\loadingio).filter -> it.colors.length > 3
          vis.set \palette, pals[Math.floor(pals.length * Math.random!)]

          svg = ld$.find vis.map.root, \svg, 0
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
            if !(row = sheets.admin.data.filter(-> it.0 == c and it.1 == t).0) => return
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
          ldld.off!

  vis.init!
  ctrl.init!
)!
/*
  * customizable data path
  * map init promise hint in doc
  * properties access
  * how to customize
  * how to access / update data
*/
