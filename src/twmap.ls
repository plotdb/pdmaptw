(->
  twmap = do
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

  if window? => window.twmap = twmap
  if module? => module.exports = twmap
)!
