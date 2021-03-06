(function(){
  (function(){
    var pdmaptw, inst;
    pdmaptw = {
      projection: d3.geoProjection(function(x, y){
        var lat, lng;
        lat = y * 180 / Math.PI;
        lng = x * 180 / Math.PI;
        if (lng > 123 && lat > 25.7) {
          lng -= 1.5;
          lat -= 0.5;
        } else if (lat < 23.82 && lng < 119.9) {
          lng += 0.2;
        } else if (lat > 25.7 && lng < 122) {
          lat -= 1.1;
        } else if (lng < 119.4) {
          lng += 1.5;
        } else if (lat > 25.4 && lng > 122) {
          lat -= 1;
        }
        if (lat > 25.819) {
          lat = 25.819;
        }
        if (lat < 21.798) {
          lat = 21.798;
        }
        if (lng < 119.369) {
          lng = 119.369;
        }
        if (lng > 122.300) {
          lng = 122.300;
        }
        x = lng * Math.PI / 180;
        y = lat * Math.PI / 180;
        return [x, y];
      }),
      create: function(opt){
        opt == null && (opt = {});
        return new inst(opt);
      },
      normalize: function(it){
        return it.replace(/臺/g, '台');
      }
    };
    inst = function(opt){
      opt == null && (opt = {});
      this.root = typeof opt.root === typeof ''
        ? document.querySelector(opt.root)
        : opt.root;
      this.lc = {};
      this.type = opt.type;
      this.popup = opt.popup;
      this.baseurl = opt.baseurl;
      this.padding = opt.padding;
      return this;
    };
    inst.prototype = import$(Object.create(Object.prototype), {
      init: function(){
        var ref$, root, type, popup, this$ = this;
        ref$ = {
          root: this.root,
          type: this.type,
          popup: this.popup
        }, root = ref$.root, type = ref$.type, popup = ref$.popup;
        root.addEventListener('mousemove', function(e){
          var n, data;
          if (!(n = e.target)) {
            return;
          }
          if (n.nodeType !== 1) {
            return;
          }
          if (!(data = d3.select(n).datum())) {
            return;
          }
          if (popup != null) {
            return popup({
              evt: e,
              data: data
            });
          }
        });
        return ld$.fetch((this.baseurl || "") + ("/" + type + ".topo.json"), {
          method: 'GET'
        }, {
          type: 'json'
        }).then(function(topo){
          this$.lc.topo = topo;
          return ld$.fetch((this$.baseurl || "") + ("/" + type + ".meta.json"), {
            method: 'GET'
          }, {
            type: 'json'
          });
        }).then(function(meta){
          var features, path, node;
          this$.lc.meta = meta;
          this$.lc.features = features = topojson.feature(this$.lc.topo, this$.lc.topo.objects["pdmaptw"]).features;
          features.map(function(it){
            var name;
            name = [meta.name[it.properties.c], meta.name[it.properties.t], meta.name[it.properties.v]].filter(function(it){
              return it;
            }).join('');
            return it.properties.name = pdmaptw.normalize(name);
          });
          this$.lc.path = path = d3.geoPath().projection(pdmaptw.projection);
          node = root.nodeName.toLowerCase() === 'svg'
            ? d3.select(root)
            : d3.select(root).append('svg');
          return node.append('g').attr('class', 'pdmaptw').selectAll('path').data(features).enter().append('path').attr('d', path);
        });
      },
      fit: function(){
        var root, g, svg, bcr, bbox, ref$, width, height, padding, scale, w, h;
        root = this.root;
        g = ld$.find(root, 'g', 0);
        if (root.nodeName.toLowerCase() !== 'svg') {
          svg = d3.select(root).select('svg');
          svg.attr('width', '100%');
          svg.attr('height', '100%');
        }
        bcr = root.getBoundingClientRect();
        bbox = g.getBBox();
        ref$ = [bcr.width, bcr.height], width = ref$[0], height = ref$[1];
        padding = this.padding != null ? this.padding : 20;
        scale = Math.min((width - 2 * padding) / bbox.width, (height - 2 * padding) / bbox.height);
        ref$ = [width / 2, height / 2], w = ref$[0], h = ref$[1];
        return g.setAttribute('transform', "translate(" + w + "," + h + ") scale(" + scale + ") translate(" + (-bbox.x - bbox.width / 2) + "," + (-bbox.y - bbox.height / 2) + ")");
      }
    });
    if (typeof window != 'undefined' && window !== null) {
      window.pdmaptw = pdmaptw;
    }
    if (typeof module != 'undefined' && module !== null) {
      return module.exports = pdmaptw;
    }
  })();
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
