// Generated by CoffeeScript 1.8.0

/*
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
 */

(function() {
  var Channel, Promise, Remote, log, tag;

  log = require('./log');

  tag = 'rpc';

  if (typeof window === 'object') {
    Promise = window.Promise || require('./promise');
  }

  exports.expose = function(local, remote) {
    return new Promise(function(resolve, reject) {
      var err, source;
      if (!remote) {
        log(err = 'SSE error: no remote object to create channel');
        reject(err);
      }
      source = new EventSource(tag);
      return source.addEventListener(tag, function(e) {
        var msg;
        log('SSE in', e.data);
        msg = JSON.parse(e.data);
        if (msg.method) {
          return local[msg.method].apply(local, msg.args);
        } else if (msg.uid) {
          remote.__sse(msg.uid);
          return resolve(msg.uid);
        }
      }, false);
    });
  };


  /*
    source.addEventListener 'error', ( (e) -> 
      log 'SSE error', e
       * source.close()
    ), false
   */

  exports.Remote = Remote = (function() {
    function Remote(options) {
      var ctx, method, _fn, _i, _len, _ref;
      if (!options.channel) {
        log('SSE error: no channel for remote object create');
        return;
      }
      ctx = {
        count: 0,
        uid: Math.random().toString().substring(2, 10)
      };
      options.methods = options.methods || [];
      _ref = options.methods;
      _fn = (function(_this) {
        return function(method) {
          return _this[method] = function() {
            return options.channel.send({
              method: method,
              args: [].slice.call(arguments),
              id: "" + ctx.uid + "-" + (++ctx.count)
            });
          };
        };
      })(this);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        method = _ref[_i];
        _fn(method);
      }
    }

    return Remote;

  })();

  exports.Channel = Channel = (function() {
    Channel.channels = [];

    function Channel(req, resp, next) {
      this.socket = resp;
      Channel.channels[this.uid = Number(new Date()).toString()] = this;
      resp.statusCode = 200;
      resp.setHeader('Content-Type', 'text/event-stream');
      resp.setHeader('Cache-Control', 'no-cache');
      resp.setHeader('Connection', 'keep-alive');
      resp.setHeader('Access-Control-Allow-Origin', '*');
      req.on('close', (function(_this) {
        return function() {
          log('SSE', _this.uid, 'closed');
          delete Channel.channels[_this.uid];
          return _this.closed = true;
        };
      })(this));
      this.send({
        uid: this.uid,
        id: 'SSE'
      });
      next();
    }

    Channel.prototype.send = function(msg) {
      log("" + msg.id + " out " + this.uid, msg);
      return this.socket.write("event: " + tag + "\ndata: " + (JSON.stringify(msg)) + "\n\n");
    };

    return Channel;

  })();

}).call(this);
