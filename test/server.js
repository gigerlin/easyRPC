// Generated by CoffeeScript 1.10.0

/*
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
 */

(function() {
  var express, expressRpc, port, store;

  express = require('express');

  expressRpc = require('avs-easyrpc').server;

  store = express();

  store.use(express["static"](__dirname + '/'));

  process.on('uncaughtException', function(err) {
    return console.log('Caught exception: ', err.stack);
  });

  store.listen(port = 4145, function() {
    console.log("Server started at " + port, new Date(), '\n');
    return expressRpc(store, {
      Employee: require('./employee'),
      Customer: require('./customer')
    }, {
      timeOut: 10 * 60 * 1000
    });
  });

}).call(this);
