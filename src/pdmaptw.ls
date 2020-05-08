(->
  pdmaptw = do
    # Projection for TPKMD ( Tai/Peng/Kin/Ma/Diaoyutai )
    projection: d3.geoProjection (x,y) ->
      lat = y * 180 / Math.PI
      lng = x * 180 / Math.PI
      if lng > 123 and lat > 25.7 => lng -= 1.5; lat -= 0.5  # diaoyutai
      else if lat < 23.82 and lng < 119.9 => lng += 0.2      # penghu
      else if lat > 25.7 and lng < 122 => lat -= 1.1         # mazu
      else if lng < 119.4 => lng += 1.5                      # kinmen
      else if lat > 25.4 and lng > 122 => lat -= 1 # pengjia islet
      # flatten outliner
      if lat > 25.819 => lat = 25.819
      if lat < 21.798 => lat = 21.798
      if lng < 119.369 => lng = 119.369
      if lng > 122.300 => lng = 122.300
      x = lng * Math.PI / 180
      y = lat * Math.PI / 180
      return [x, y]
    create: (opt = {}) -> new inst opt
    normalize: -> it.replace /臺/g, '台'

  inst = (opt = {}) ->
    @root = if typeof(opt.root) == typeof('') => document.querySelector(opt.root) else opt.root
    @ <<< {lc: {}, type: opt.type, popup: opt.popup}
    @

  inst.prototype = Object.create(Object.prototype) <<< do
    init: ->
      {root, type, popup} = @{root, type, popup}
      root.addEventListener \mousemove, (e) ->
        if !(n = e.target) => return
        if n.nodeType != 1 => return
        if !(data = d3.select(n).datum!) => return
        if popup? => popup {evt: e, data}
      ld$.fetch "/assets/lib/pdmaptw/#type.topo.json", {method: \GET}, {type: \json}
        .then (topo) ~>
          @lc.topo = topo
          ld$.fetch "/assets/lib/pdmaptw/#type.meta.json", {method: \GET}, {type: \json}
        .then (meta) ~>
          @lc.meta = meta
          @lc.features = features = topojson.feature(@lc.topo, @lc.topo.objects["pdmaptw"]).features
          features.map ~>
            name = [meta.name[it.properties.c], meta.name[it.properties.t], meta.name[it.properties.v]]
              .filter(->it) .join('')
            it.properties.name = pdmaptw.normalize name
          @lc.path = path = d3.geoPath().projection(pdmaptw.projection)
          d3.select(root).append(\svg).append(\g)
            .selectAll \path
            .data features
            .enter!
              .append \path
              .attr \d, path

    fit: ->
      root = @root
      g = ld$.find root, \g, 0
      svg = d3.select(root).select(\svg)
      svg.attr \width, \100%
      svg.attr \height, \100%
      bcr = root.getBoundingClientRect!
      bbox = g.getBBox!
      [width,height] = [bcr.width,bcr.height]
      padding = 20
      scale = Math.min((width - 2 * padding) / bbox.width, (height - 2 * padding) / bbox.height)
      [w,h] = [width / 2, height / 2]
      g.setAttribute(
        \transform
        "translate(#w,#h) scale(#scale) translate(#{-bbox.x - bbox.width/2},#{-bbox.y - bbox.height/2})"
      )

  if window? => window.pdmaptw = pdmaptw
  if module? => module.exports = pdmaptw
)!
