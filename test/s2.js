// Generated by CoffeeScript 1.10.0
(function() {
  var express, expressRpc, http, port, store;

  http = require('http');

  express = require('./express');

  expressRpc = require('avs-easyrpc').Server;

  store = express();

  port = 4145;

  http.createServer(store).listen(port, function() {
    console.log("Server started at " + port, new Date(), '\n');
    return expressRpc(store, {
      Employee: require('./employee'),
      Customer: require('./customer')
    });
  });

}).call(this);