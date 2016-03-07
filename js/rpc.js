// Generated by CoffeeScript 1.8.0

/*
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
 */

(function() {
  var Promise, Rpc, classServer, expressRpc, log, parser, sessionTimeOut;

  parser = require('body-parser');

  if (typeof Promise === 'undefined') {
    Promise = require('./promise');
  }

  log = require('./log');

  sessionTimeOut = 30 * 60 * 1000;

  Rpc = (function() {
    function Rpc(local) {
      this.local = local;
    }

    Rpc.prototype.process = function(msg, res) {
      var e, rep, _ref;
      log("" + msg.id + ": in", msg);
      if (this.local[msg.method]) {
        try {
          rep = (_ref = this.local)[msg.method].apply(_ref, msg.args);
          if (rep instanceof Promise) {
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
        } catch (_error) {
          e = _error;
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
      log("" + msg.id + ": out", rep);
      return res.send(rep);
    };

    return Rpc;

  })();

  classServer = (function() {
    function classServer(classes, timeOut) {
      var Class, method;
      this.classes = classes;
      this.timeOut = timeOut != null ? timeOut : sessionTimeOut;
      this.methods = [];
      for (Class in this.classes) {
        this["" + Class + ".sessions"] = [];
        this.methods[Class] = (function() {
          var _results;
          _results = [];
          for (method in this.classes[Class].prototype) {
            if (method.charAt(0) !== '_' && method !== 'constructor') {
              _results.push(method);
            }
          }
          return _results;
        }).call(this);
      }
    }

    classServer.prototype.process = function(req, res) {
      var Class, msg, rpc, uid;
      Class = req.path.substring(1);
      msg = req.body;
      uid = msg.id.split('-')[0];
      rpc = this["" + Class + ".sessions"][uid];
      this._resetTimeOut(Class, rpc, uid);
      if (!rpc) {
        this["" + Class + ".sessions"][uid] = rpc = new Rpc(new this.classes[Class]());
        this._timeOut(Class, rpc, uid);
        log("adding new session " + Class + " " + uid + " (total: " + (Object.keys(this["" + Class + ".sessions"]).length) + ")");
      }
      return rpc.process(msg, res);
    };

    classServer.prototype._timeOut = function(Class, rpc, uid) {
      return rpc.timeOut = setTimeout((function(_this) {
        return function() {
          delete _this["" + Class + ".sessions"][uid];
          return log("removing session " + uid + " (total: " + (Object.keys(_this["" + Class + ".sessions"])) + ")");
        };
      })(this), this.timeOut);
    };

    classServer.prototype._resetTimeOut = function(Class, rpc, uid) {
      if (rpc) {
        clearTimeout(rpc.timeOut);
        return this._timeOut(Class, rpc, uid);
      }
    };

    return classServer;

  })();

  module.exports = expressRpc = (function() {
    function expressRpc(app, classes, options) {
      var Class, server;
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
      for (Class in classes) {
        log("listening on class " + Class);
        app.post("/" + Class, function(req, res) {
          return server.process(req, res);
        });
      }
    }

    return expressRpc;

  })();

}).call(this);
