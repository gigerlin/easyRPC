// Generated by CoffeeScript 1.10.0

/*
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
 */

(function() {
  var all, fs, routes;

  fs = require('fs');

  routes = [];

  all = '*';

  module.exports = function() {
    var app;
    app = function(req, res) {
      var index, next, roads, root;
      console.log('processing', req.url);
      if (routes[req.url]) {
        roads = (root = routes[all]) ? root.concat(routes[req.url]) : routes[req.url];
        index = 0;
        return (next = function() {
          if (index < roads.length) {
            return roads[index++](req, res, next);
          }
        })();
      } else {
        return fs.readFile("./" + req.url, function(err, data) {
          if (err) {
            res.statusCode = 404;
            return res.end("error: no class " + (req.url.substring(1)));
          } else {
            res.statusCode = 200;
            return res.end(data);
          }
        });
      }
    };
    app.post = app.get = app.use = function(path, route) {
      var road;
      if (typeof path === 'function') {
        route = path;
        path = all;
      }
      if (road = routes[path]) {
        return road.push(route);
      } else {
        return routes[path] = [route];
      }
    };
    return app;
  };

}).call(this);
