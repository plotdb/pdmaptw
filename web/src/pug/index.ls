<-(->it!) _
view = new ldView do
  root: document.body
  handler: do
    "count": (->)
    "elapsed": (->)
    "info": (->)

proc = (root, name) ->
  lc = {}
  t1 = Date.now!
  topofn = "assets/lib/pdmaptw/dev/#name.topo.json"
  metafn = "assets/lib/pdmaptw/dev/#name.meta.json"
  ld$.fetch topofn, {method: \GET}, {type: \json}
    .then (topo) ->
      lc.topo = topo
      ld$.fetch metafn, {method: \GET}, {type: \json}
    .then (meta) ->
      
      size = JSON.stringify(lc.topo).length
      t2 = Date.now!
      bbox = topojson.bbox(lc.topo)
      path = d3.geoPath!.projection(pdmaptw.projection!)
      features = topojson.feature(lc.topo, lc.topo.objects["pdmaptw"]).features
      hash = {}
      data.map (d) -> hash[[0 til (d.length - 1)].map(->d[it]).filter(->it).join('')] = d[* - 1]
      features.map (f) ->
        f.properties.name = n = <[c t v]>.map((d) -> meta.name[f.properties[d]]).filter(->it).join('')
        f.properties.value = hash[n] or 0
      features = features.filter (f) -> path.area(f) > 0.00001

      d3.select root .select "svg g"
        .selectAll \path
        .data features
        .enter!
          .append \path
          .attr \d, path
          .attr \fill, ->
            v = if it.properties.tid == \T => 0.2 + Math.random! * 0.2 else Math.random! * 0.2
            if it.properties.value => v = 1 else v = Math.random!

            d3.interpolateSpectral v
          .attr \stroke, -> \#000
          .attr \stroke-width, -> 0.00
      features.map (f) -> f.properties.value = Math.random!
      debounce 2000 .then ->
        return
        #d3.select root .selectAll \path .transition!
        #  .duration 3000
        d3.select root .selectAll \path
          .attr \fill -> 
            #d3.interpolateSpectral path(it).centroid #it.properties.value or 0
            #d3.interpolateSpectral(path.area(it) * 1)
            d3.interpolateSpectral((path.centroid(it).0 - 482)/10)
          .attr \stroke -> 
            d3.interpolateSpectral((path.centroid(it).0 - 482)/10)
      g = ld$.find root, 'g', 0
      bcr = root.getBoundingClientRect!
      lc.[]bbox.push bbox = g.getBBox!
      [width,height] = [bcr.width,bcr.height]
      padding = 20
      scale = Math.min((width - 2 * padding) / bbox.width, (height - 2 * padding) / bbox.height)
      [w,h] = [width / 2, height / 2]
      g.setAttribute(
        \transform
        "translate(#w,#h) scale(#scale) translate(#{-bbox.x - bbox.width/2},#{-bbox.y - bbox.height/2})"
      )
      ld$.find(document,"[ld=count][data-name=#{name}",0).innerText = features.length
      t3 = Date.now!
      ld$.find(document,"[ld=elapsed][data-name=#{name}",0).innerText = 
        "fetch: #{t2 - t1}ms / render: #{t3 - t2}ms"
      ld$.find(document,"[ld=size][data-name=#{name}",0).innerText = "size: #{Math.round(size / 1024)}KB"

document.body.addEventListener \mouseover, (e) ->
  d = d3.select(e.target).data().0
  if !d => return
  console.log d.properties.name
  view.get \info .innerText = d.properties.name
  bbox = e.target.getBBox!
  root = ld$.find document, \svg, 2
  bcr = root.getBoundingClientRect!
  scale = Math.min(bcr.width / bbox.width, bcr.height / bbox.height)
  d3.select root .select \g .transition!
    .attr(
      \transform, 
      [
        "translate(#{bcr.width/2},#{bcr.height/2})"
        "scale(#scale)"
        "translate(#{-bbox.x - bbox.width/2},#{-bbox.y - bbox.height/2})"
      ].join(' ')
    )

svgs = ld$.find document.body, \svg
proc svgs.0, \county
proc svgs.1, \town
proc svgs.2, \village

