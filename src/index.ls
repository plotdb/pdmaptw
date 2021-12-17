ns = "http://www.w3.org/2000/svg"

# `root`: element passed in
# `svg`: calculated svg element ( either in parent, exactly the root, or created and append under root )
# `g`: the group element containing the whole map. created by pdmaptw 
# `node`: the element where to put the `g` element. 
pdmaptw = (opt = {}) ->
  @root = if typeof(opt.root) == typeof('') => document.querySelector(opt.root) else opt.root
  @evt-handler = {}
  @ <<< {lc: {}, type: opt.type, popup: opt.popup, baseurl: opt.baseurl, padding: opt.padding}
  @

pdmaptw.register = (type, json) -> pdmaptw.{}_data[type] = json
pdmaptw.get = (type) -> Promise.resolve(pdmaptw._data[type])

pdmaptw.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  init: ->
    {root, type, popup} = @
    @svg = if root.nodeName.toLowerCase! == \svg => root
    else ld$.parent(root, 'svg')
    if !@svg =>
      root.appendChild(@svg = document.createElement \svg)
      @svg.setAttribute \width, \100%
      @svg.setAttribute \height, \100%
    if root.nodeName.toLowerCase! == \g => @node = root
    else @node = @svg
    @node.appendChild(@g = document.createElementNS(ns, \g))
    @svg.addEventListener \mousemove, (e) ~>
      if !(n = e.target) or n.nodeType != 1 => return
      if !(data = d3.select(n).datum!) => return
      @fire \hover, {evt: e, data}
    pdmaptw.get type
      .then ({topo, meta}) ~>
        @lc <<< {topo, meta}
        @lc.features = features = topojson.feature(@lc.topo, @lc.topo.objects["pdmaptw"]).features
        features.map ~>
          name = [meta.name[it.properties.c], meta.name[it.properties.t], meta.name[it.properties.v]]
            .filter(->it) .join('')
          it.properties.name = pdmaptw.normalize name
        @lc.path = path = d3.geoPath!.projection(pdmaptw.projection!)

        d3.select @g
          .attr \class, \pdmaptw
          .selectAll \path
          .data features
          .enter!append(\path).attr(\d, path)

  fit: (opt = {}) ->
    {box} = opt
    bcr = if box => box else if @node.getBoundingClientRect => @node.getBoundingClientRect! else @node.getBBox!
    bbox = @g.getBBox!
    [width,height] = [bcr.width,bcr.height]
    padding = if @padding? => @padding else 20
    scale = Math.min((width - 2 * padding) / bbox.width, (height - 2 * padding) / bbox.height)
    [w,h] = [width / 2, height / 2]
    @g.setAttribute(
      \transform
      "translate(#w,#h) scale(#scale) translate(#{-bbox.x - bbox.width/2},#{-bbox.y - bbox.height/2})"
    )

# Projection for TPKMD ( Tai/Peng/Kin/Ma/Diaoyutai )
pdmaptw.projection = ->
  if pdmaptw._projection => return that
  pdmaptw._projection = d3.geoProjection (x,y) ->
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
pdmaptw.normalize = -> it.replace /臺/g, '台'


if module? => module.exports = pdmaptw
else if window? => window.pdmaptw = pdmaptw
