// Generated by CoffeeScript 1.10.0

/*
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
 */

(function() {
  var Channel, Promise, Remote, Rpc, classServer, expressRpc, log, parser, sessionTimeOut, sse, tag;

  parser = require('body-parser');

  if (typeof Promise === 'undefined') {
    Promise = require('./promise');
  }

  log = require('./log');

  tag = 'rpc';

  sse = '__sse';

  sessionTimeOut = 30 * 60 * 1000;

  Rpc = (function() {
    function Rpc(local) {
      this.local = local;
    }

    Rpc.prototype.process = function(msg, res) {
      var e, error, ref, rep;
      log(msg.id + " in", msg);
      if (this.local[msg.method]) {
        try {
          if (msg.method === sse) {
            msg.args = [Channel.channels[msg.args[0]]];
          }
          rep = (ref = this.local)[msg.method].apply(ref, msg.args);
          if (typeof rep["catch"] === 'function') {
            rep.then((function(_this) {
              return function(rep) {
                return _this._return(msg, {
                  rep: rep
                }, res);
              };
            })(this));
            return rep["catch"]((function(_this) {
              return function(err) {
                return _this._return(msg, {
                  err: err
                }, res);
              };
            })(this));
          } else {
            return this._return(msg, {
              rep: rep
            }, res);
          }
        } catch (error) {
          e = error;
          return this._return(msg, {
            err: "error in " + msg.method + ": " + e
          }, res);
        }
      } else {
        return this._return(msg, {
          err: "error: method " + msg.method + " is unknown"
        }, res);
      }
    };

    Rpc.prototype._return = function(msg, rep, res) {
      log(msg.id + " out", rep);
      return res.send(rep);
    };

    return Rpc;

  })();

  classServer = (function() {
    function classServer(classes, timeOut) {
      var Class;
      this.timeOut = timeOut != null ? timeOut : sessionTimeOut;
      for (Class in classes) {
        this[Class] = {
          Class: classes[Class],
          sessions: []
        };
      }
    }

    classServer.prototype.process = function(Class, msg, res) {
      var rpc, uid;
      uid = msg.id.split('-')[0];
      if (rpc = this[Class].sessions[uid]) {
        clearTimeout(rpc.timeOut);
      } else {
        this[Class].sessions[uid] = rpc = new Rpc(new this[Class].Class[Class]());
        log("adding new session " + Class + " " + uid + " (# sessions: " + (Object.keys(this[Class].sessions).length) + ")");
      }
      rpc.timeOut = setTimeout((function(_this) {
        return function() {
          delete _this[Class].sessions[uid];
          return log("removing session " + uid + " (# sessions: " + (Object.keys(_this[Class].sessions).length) + ")");
        };
      })(this), this.timeOut);
      return rpc.process(msg, res);
    };

    return classServer;

  })();

  exports.expressRpc = expressRpc = (function() {
    function expressRpc(app, classes, options) {
      var Class, fn, server;
      if (options == null) {
        options = {};
      }
      process.on('uncaughtException', function(err) {
        return log('Caught exception: ', err.stack);
      });
      app.use(parser.json({
        limit: options.limit || '512kb'
      }));
      app.use(function(err, req, res, next) {
        log(err.stack);
        return next(err);
      });
      server = new classServer(classes, options.timeOut);
      fn = function(Class) {
        log("listening on class " + Class);
        return app.post("/" + Class, function(req, res) {
          return server.process(Class, req.body, res);
        });
      };
      for (Class in classes) {
        fn(Class);
      }
      app.get("/" + tag, function(req, res, next) {
        return new Channel(req, res, next);
      });
    }

    return expressRpc;

  })();

  exports.Remote = Remote = (function() {
    function Remote(options) {
      var ctx, fn, i, len, method, ref;
      if (!options.channel) {
        log('SSE error: no channel for remote object create');
        return;
      }
      ctx = {
        count: 0,
        uid: Math.random().toString().substring(2, 10)
      };
      options.methods = options.methods || [];
      ref = options.methods;
      fn = (function(_this) {
        return function(method) {
          return _this[method] = function() {
            return options.channel.send({
              method: method,
              args: [].slice.call(arguments),
              id: ctx.uid + "-" + (++ctx.count)
            });
          };
        };
      })(this);
      for (i = 0, len = ref.length; i < len; i++) {
        method = ref[i];
        fn(method);
      }
    }

    return Remote;

  })();

  Channel = Channel = (function() {
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
      log(msg.id + " out " + this.uid, msg);
      return this.socket.write("event: " + tag + "\ndata: " + (JSON.stringify(msg)) + "\n\n");
    };

    return Channel;

  })();

}).call(this);
