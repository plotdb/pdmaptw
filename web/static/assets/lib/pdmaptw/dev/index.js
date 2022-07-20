(function(){
  var ns, pdmaptw;
  ns = "http://www.w3.org/2000/svg";
  pdmaptw = function(opt){
    opt == null && (opt = {});
    this.root = typeof opt.root === typeof ''
      ? document.querySelector(opt.root)
      : opt.root;
    this.evtHandler = {};
    this.lc = {};
    this.type = opt.type;
    this.popup = opt.popup;
    this.baseurl = opt.baseurl;
    this.padding = opt.padding;
    return this;
  };
  pdmaptw.register = function(type, json){
    return (pdmaptw._data || (pdmaptw._data = {}))[type] = json;
  };
  pdmaptw.get = function(type){
    return Promise.resolve(pdmaptw._data[type]);
  };
  pdmaptw.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var this$ = this;
      return (Array.isArray(n)
        ? n
        : [n]).map(function(n){
        var ref$;
        return ((ref$ = this$.evtHandler)[n] || (ref$[n] = [])).push(cb);
      });
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this.evtHandler[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    init: function(){
      var root, type, popup, this$ = this;
      root = this.root, type = this.type, popup = this.popup;
      this.svg = root.nodeName.toLowerCase() === 'svg'
        ? root
        : ld$.parent(root, 'svg');
      if (!this.svg) {
        root.appendChild(this.svg = document.createElementNS(ns, 'svg'));
        this.svg.setAttribute('width', '100%');
        this.svg.setAttribute('height', '100%');
      }
      if (root.nodeName.toLowerCase() === 'g') {
        this.node = root;
      } else {
        this.node = this.svg;
      }
      this.node.appendChild(this.g = document.createElementNS(ns, 'g'));
      this.svg.addEventListener('mousemove', function(e){
        var n, data;
        if (!(n = e.target) || n.nodeType !== 1) {
          return;
        }
        if (!(data = d3.select(n).datum())) {
          return;
        }
        return this$.fire('hover', {
          evt: e,
          data: data
        });
      });
      return pdmaptw.get(type).then(function(arg$){
        var topo, meta, ref$, features, path;
        topo = arg$.topo, meta = arg$.meta;
        ref$ = this$.lc;
        ref$.topo = topo;
        ref$.meta = meta;
        this$.lc.features = features = topojson.feature(this$.lc.topo, this$.lc.topo.objects["pdmaptw"]).features;
        features.map(function(it){
          var name;
          name = [meta.name[it.properties.c], meta.name[it.properties.t], meta.name[it.properties.v]].filter(function(it){
            return it;
          }).join('');
          return it.properties.name = pdmaptw.normalize(name);
        });
        this$.lc.path = path = d3.geoPath().projection(pdmaptw.projection());
        return d3.select(this$.g).attr('class', 'pdmaptw').selectAll('path').data(features).enter().append('path').attr('d', path);
      });
    },
    fit: function(opt){
      var box, bcr, bbox, ref$, width, height, padding, scale, w, h;
      opt == null && (opt = {});
      box = opt.box;
      bcr = box
        ? box
        : this.node.getBoundingClientRect
          ? this.node.getBoundingClientRect()
          : this.node.getBBox();
      bbox = this.g.getBBox();
      ref$ = [bcr.width, bcr.height], width = ref$[0], height = ref$[1];
      padding = this.padding != null ? this.padding : 20;
      scale = Math.min((width - 2 * padding) / bbox.width, (height - 2 * padding) / bbox.height);
      ref$ = [width / 2, height / 2], w = ref$[0], h = ref$[1];
      return this.g.setAttribute('transform', "translate(" + w + "," + h + ") scale(" + scale + ") translate(" + (-bbox.x - bbox.width / 2) + "," + (-bbox.y - bbox.height / 2) + ")");
    }
  });
  pdmaptw.projection = function(){
    var that;
    if (that = pdmaptw._projection) {
      return that;
    }
    return pdmaptw._projection = d3.geoProjection(function(x, y){
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
    });
  };
  pdmaptw.normalize = function(it){
    return it.replace(/臺/g, '台');
  };
  if (typeof module != 'undefined' && module !== null) {
    module.exports = pdmaptw;
  } else if (typeof window != 'undefined' && window !== null) {
    window.pdmaptw = pdmaptw;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
