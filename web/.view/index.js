 (function() { function pug_attr(t,e,n,r){if(!1===e||null==e||!e&&("class"===t||"style"===t))return"";if(!0===e)return" "+(r?t:t+'="'+t+'"');var f=typeof e;return"object"!==f&&"function"!==f||"function"!=typeof e.toJSON||(e=e.toJSON()),"string"==typeof e||(e=JSON.stringify(e),n||-1===e.indexOf('"'))?(n&&(e=pug_escape(e))," "+t+'="'+e+'"'):" "+t+"='"+e.replace(/'/g,"&#39;")+"'"}
function pug_escape(e){var a=""+e,t=pug_match_html.exec(a);if(!t)return e;var r,c,n,s="";for(r=t.index,c=0;r<a.length;r++){switch(a.charCodeAt(r)){case 34:n="&quot;";break;case 38:n="&amp;";break;case 60:n="&lt;";break;case 62:n="&gt;";break;default:continue}c!==r&&(s+=a.substring(c,r)),c=r+1,s+=n}return c!==r?s+a.substring(c,r):s}
var pug_match_html=/["&<>]/;function template(locals) {var pug_html = "", pug_mixins = {}, pug_interp;;
    var locals_for_with = (locals || {});
    
    (function (Array, c, defer, libLoader, url, version) {
      pug_html = pug_html + "\u003C!DOCTYPE html\u003E";
if(!libLoader) {
  libLoader = {
    js: {url: {}},
    css: {url: {}},
    root: function(r) { libLoader._r = r; },
    _r: "/assets/lib",
    _v: "",
    version: function(v) { libLoader._v = (v ? "?v=" + v : ""); }
  }
  if(version) { libLoader.version(version); }
}

pug_mixins["script"] = pug_interp = function(os,cfg){
var block = (this && this.block), attributes = (this && this.attributes) || {};
if(!Array.isArray(os)) { os = [os]; }
// iterate os
;(function(){
  var $$obj = os;
  if ('number' == typeof $$obj.length) {
      for (var pug_index0 = 0, $$l = $$obj.length; pug_index0 < $$l; pug_index0++) {
        var o = $$obj[pug_index0];
c = o;
if(typeof(o) == "string") { url = o; c = cfg || {};}
else if(o.url) { url = o.url; }
else { url = libLoader._r + "/" + o.name + "/" + (o.version || 'main') + "/" + (o.path || "index.min.js"); }
if (!libLoader.js.url[url]) {
libLoader.js.url[url] = true;
defer = (typeof(c.defer) == "undefined" ? true : !!c.defer);
if (/^https?:\/\/./.exec(url)) {
pug_html = pug_html + "\u003Cscript" + (" type=\"text\u002Fjavascript\""+pug_attr("src", url, true, true)+pug_attr("defer", defer, true, true)+pug_attr("async", !!c.async, true, true)) + "\u003E\u003C\u002Fscript\u003E";
}
else {
pug_html = pug_html + "\u003Cscript" + (" type=\"text\u002Fjavascript\""+pug_attr("src", url + libLoader._v, true, true)+pug_attr("defer", defer, true, true)+pug_attr("async", !!c.async, true, true)) + "\u003E\u003C\u002Fscript\u003E";
}
}
      }
  } else {
    var $$l = 0;
    for (var pug_index0 in $$obj) {
      $$l++;
      var o = $$obj[pug_index0];
c = o;
if(typeof(o) == "string") { url = o; c = cfg || {};}
else if(o.url) { url = o.url; }
else { url = libLoader._r + "/" + o.name + "/" + (o.version || 'main') + "/" + (o.path || "index.min.js"); }
if (!libLoader.js.url[url]) {
libLoader.js.url[url] = true;
defer = (typeof(c.defer) == "undefined" ? true : !!c.defer);
if (/^https?:\/\/./.exec(url)) {
pug_html = pug_html + "\u003Cscript" + (" type=\"text\u002Fjavascript\""+pug_attr("src", url, true, true)+pug_attr("defer", defer, true, true)+pug_attr("async", !!c.async, true, true)) + "\u003E\u003C\u002Fscript\u003E";
}
else {
pug_html = pug_html + "\u003Cscript" + (" type=\"text\u002Fjavascript\""+pug_attr("src", url + libLoader._v, true, true)+pug_attr("defer", defer, true, true)+pug_attr("async", !!c.async, true, true)) + "\u003E\u003C\u002Fscript\u003E";
}
}
    }
  }
}).call(this);

};
pug_mixins["css"] = pug_interp = function(os,cfg){
var block = (this && this.block), attributes = (this && this.attributes) || {};
if(!Array.isArray(os)) { os = [os]; }
// iterate os
;(function(){
  var $$obj = os;
  if ('number' == typeof $$obj.length) {
      for (var pug_index1 = 0, $$l = $$obj.length; pug_index1 < $$l; pug_index1++) {
        var o = $$obj[pug_index1];
c = o;
if(typeof(o) == "string") { url = o; c = cfg || {};}
else if(o.url) { url = o.url; }
else { url = libLoader._r + "/" + o.name + "/" + (o.version || 'main') + "/" + (o.path || "index.min.css"); }
if (!libLoader.css.url[url]) {
libLoader.css.url[url] = true;
pug_html = pug_html + "\u003Clink" + (" rel=\"stylesheet\" type=\"text\u002Fcss\""+pug_attr("href", url + libLoader._v, true, true)) + "\u003E";
}
      }
  } else {
    var $$l = 0;
    for (var pug_index1 in $$obj) {
      $$l++;
      var o = $$obj[pug_index1];
c = o;
if(typeof(o) == "string") { url = o; c = cfg || {};}
else if(o.url) { url = o.url; }
else { url = libLoader._r + "/" + o.name + "/" + (o.version || 'main') + "/" + (o.path || "index.min.css"); }
if (!libLoader.css.url[url]) {
libLoader.css.url[url] = true;
pug_html = pug_html + "\u003Clink" + (" rel=\"stylesheet\" type=\"text\u002Fcss\""+pug_attr("href", url + libLoader._v, true, true)) + "\u003E";
}
    }
  }
}).call(this);

};
pug_html = pug_html + "\u003Chtml\u003E\u003Chead\u003E";
pug_mixins["css"]("https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css");
pug_mixins["css"]("/assets/lib/@loadingio/bootstrap.ext/main/index.min.css");
pug_html = pug_html + "\u003Cstyle\u003E\u003C\u002Fstyle\u003E\u003C\u002Fhead\u003E\u003Cbody class=\"p-4\"\u003E\u003Cdiv class=\"row mb-4\" style=\"min-height:500px\"\u003E\u003Cdiv class=\"col-md\"\u003E\u003Cdiv class=\"aspect-ratio w-100\" style=\"padding-top:120%\"\u003E\u003Csvg class=\"border bg-light shadow w-100 h-100\"\u003E\u003Cg\u003E\u003C\u002Fg\u003E\u003C\u002Fsvg\u003E\u003C\u002Fdiv\u003E\u003Cdiv class=\"text-center\"\u003E\u003Cdiv\u003EPath Count: \u003Cspan ld=\"count\" data-name=\"county\"\u003E\u003C\u002Fspan\u003E\u003C\u002Fdiv\u003E\u003Cdiv ld=\"elapsed\" data-name=\"county\"\u003E\u003C\u002Fdiv\u003E\u003Cdiv ld=\"size\" data-name=\"county\"\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003Cdiv class=\"col-md\"\u003E\u003Cdiv class=\"aspect-ratio w-100\" style=\"padding-top:120%\"\u003E\u003Csvg class=\"border bg-light shadow w-100 h-100\"\u003E\u003Cg\u003E\u003C\u002Fg\u003E\u003C\u002Fsvg\u003E\u003C\u002Fdiv\u003E\u003Cdiv class=\"text-center\"\u003E\u003Cdiv\u003EPath Count: \u003Cspan ld=\"count\" data-name=\"town\"\u003E\u003C\u002Fspan\u003E\u003C\u002Fdiv\u003E\u003Cdiv ld=\"elapsed\" data-name=\"town\"\u003E\u003C\u002Fdiv\u003E\u003Cdiv ld=\"size\" data-name=\"town\"\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003Cdiv class=\"col-md\"\u003E\u003Cdiv class=\"aspect-ratio w-100\" style=\"padding-top:120%\"\u003E\u003Csvg class=\"border bg-light shadow w-100 h-100\"\u003E\u003Cg\u003E\u003C\u002Fg\u003E\u003C\u002Fsvg\u003E\u003C\u002Fdiv\u003E\u003Cdiv class=\"text-center\"\u003E\u003Cdiv\u003EPath Count: \u003Cspan ld=\"count\" data-name=\"village\"\u003E\u003C\u002Fspan\u003E\u003C\u002Fdiv\u003E\u003Cdiv ld=\"elapsed\" data-name=\"village\"\u003E\u003C\u002Fdiv\u003E\u003Cdiv ld=\"size\" data-name=\"village\"\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003C\u002Fdiv\u003E\u003Ch3 class=\"text-center\" ld=\"info\"\u003En\u002Fa\u003C\u002Fh3\u003E";
pug_mixins["script"]([
      {name: "d3", version: "main", path: "dist/d3.min.js"},
      {name: "d3-color", version: "main", path: "dist/d3-color.min.js"},
      {name: "d3-interpolate", version: "main", path: "dist/d3-interpolate.min.js"},
      {name: "d3-scale-chromatic", version: "main", path: "dist/d3-scale-chromatic.min.js"},
      {name: "d3-geo", version: "main", path: "dist/d3-geo.min.js"},
      {name: "d3-geo-projection", version: "main", path: "dist/d3-geo-projection.min.js"},
      {name: "topojson", version: "main", path: "dist/topojson.min.js"},
      {name: "@loadingio/debounce.js", version: "main"},
      {name: "@loadingio/ldquery", version: "main"},
      {name: "ldview", version: "main"}
    ]);
pug_mixins["script"]("assets/lib/pdmaptw/dev/index.min.js");
pug_mixins["script"]("assets/lib/pdmaptw/dev/county.map.js");
pug_mixins["script"]("assets/lib/pdmaptw/dev/town.map.js");
pug_mixins["script"]("assets/lib/pdmaptw/dev/village.map.js");
pug_mixins["script"]("js/data.js");
pug_html = pug_html + "\u003Cscript type=\"module\"\u003E(function(t){return t()})(function(){var i,t,e;i=new ldview({root:document.body,handler:{count:function(){},elapsed:function(){},info:function(){}}});t=function(v,w){var b,j,t,e;b={};j=Date.now();t=\"assets\u002Flib\u002Fpdmaptw\u002Fdev\u002F\"+w+\".topo.json\";e=\"assets\u002Flib\u002Fpdmaptw\u002Fdev\u002F\"+w+\".meta.json\";return ld$.fetch(t,{method:\"GET\"},{type:\"json\"}).then(function(t){b.topo=t;return ld$.fetch(e,{method:\"GET\"},{type:\"json\"})}).then(function(n){var t,e,r,o,a,i,d,u,l,c,s,p,f,h,m,g;t=JSON.stringify(b.topo).length;e=Date.now();r=topojson.bbox(b.topo);o=d3.geoPath().projection(pdmaptw.projection());a=topojson.feature(b.topo,b.topo.objects[\"pdmaptw\"]).features;i={};data.map(function(r){return i[function(){var t,e,n=[];for(t=0,e=r.length-1;t\u003Ce;++t){n.push(t)}return n}().map(function(t){return r[t]}).filter(function(t){return t}).join(\"\")]=r[r.length-1]});a.map(function(e){var t;e.properties.name=t=[\"c\",\"t\",\"v\"].map(function(t){return n.name[e.properties[t]]}).filter(function(t){return t}).join(\"\");return e.properties.value=i[t]||0});a=a.filter(function(t){return o.area(t)\u003E1e-5});d3.select(v).select(\"svg g\").selectAll(\"path\").data(a).enter().append(\"path\").attr(\"d\",o).attr(\"fill\",function(t){var e;e=t.properties.tid===\"T\"?.2+Math.random()*.2:Math.random()*.2;if(t.properties.value){e=1}else{e=Math.random()}return d3.interpolateSpectral(e)}).attr(\"stroke\",function(){return\"#000\"}).attr(\"stroke-width\",function(){return 0});a.map(function(t){return t.properties.value=Math.random()});debounce(2e3).then(function(){return;return d3.select(v).selectAll(\"path\").attr(\"fill\",function(t){return d3.interpolateSpectral((o.centroid(t)[0]-482)\u002F10)}).attr(\"stroke\",function(t){return d3.interpolateSpectral((o.centroid(t)[0]-482)\u002F10)})});d=ld$.find(v,\"g\",0);u=v.getBoundingClientRect();(b.bbox||(b.bbox=[])).push(r=d.getBBox());l=[u.width,u.height],c=l[0],s=l[1];p=20;f=Math.min((c-2*p)\u002Fr.width,(s-2*p)\u002Fr.height);l=[c\u002F2,s\u002F2],h=l[0],m=l[1];d.setAttribute(\"transform\",\"translate(\"+h+\",\"+m+\") scale(\"+f+\") translate(\"+(-r.x-r.width\u002F2)+\",\"+(-r.y-r.height\u002F2)+\")\");ld$.find(document,\"[ld=count][data-name=\"+w,0).innerText=a.length;g=Date.now();ld$.find(document,\"[ld=elapsed][data-name=\"+w,0).innerText=\"fetch: \"+(e-j)+\"ms \u002F render: \"+(g-e)+\"ms\";return ld$.find(document,\"[ld=size][data-name=\"+w,0).innerText=\"size: \"+Math.round(t\u002F1024)+\"KB\"})};document.body.addEventListener(\"mouseover\",function(t){var e,n,r,o,a;e=d3.select(t.target).data()[0];if(!e){return}console.log(e.properties.name);i.get(\"info\").innerText=e.properties.name;n=t.target.getBBox();r=ld$.find(document,\"svg\",2);o=r.getBoundingClientRect();a=Math.min(o.width\u002Fn.width,o.height\u002Fn.height);return d3.select(r).select(\"g\").transition().attr(\"transform\",[\"translate(\"+o.width\u002F2+\",\"+o.height\u002F2+\")\",\"scale(\"+a+\")\",\"translate(\"+(-n.x-n.width\u002F2)+\",\"+(-n.y-n.height\u002F2)+\")\"].join(\" \"))});e=ld$.find(document.body,\"svg\");t(e[0],\"county\");t(e[1],\"town\");return t(e[2],\"village\")});\u003C\u002Fscript\u003E\u003C\u002Fbody\u003E\u003C\u002Fhtml\u003E";
    }.call(this, "Array" in locals_for_with ?
        locals_for_with.Array :
        typeof Array !== 'undefined' ? Array : undefined, "c" in locals_for_with ?
        locals_for_with.c :
        typeof c !== 'undefined' ? c : undefined, "defer" in locals_for_with ?
        locals_for_with.defer :
        typeof defer !== 'undefined' ? defer : undefined, "libLoader" in locals_for_with ?
        locals_for_with.libLoader :
        typeof libLoader !== 'undefined' ? libLoader : undefined, "url" in locals_for_with ?
        locals_for_with.url :
        typeof url !== 'undefined' ? url : undefined, "version" in locals_for_with ?
        locals_for_with.version :
        typeof version !== 'undefined' ? version : undefined));
    ;;return pug_html;}; module.exports = template; })() 