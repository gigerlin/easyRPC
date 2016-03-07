###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

parser = require('body-parser')

log = require './log'
sessionTimeOut = 30 * 60 * 1000 # 30 minutes

#
# Http Rpc
#
class Rpc # inspired from minimum-rpc
  constructor: (@local) ->

  process: (msg, res) ->
    log "#{msg.id}: in", msg
    if @local[msg.method]
      try
        rep = @local[msg.method] msg.args...
        if rep instanceof Promise
          rep.then (rep) =>  @_return msg, rep:rep, res
          rep.catch (err) => @_return msg, err:err, res
        else @_return msg, rep:rep, res
      catch e then @_return msg, err:"error in #{msg.method}: #{e}", res
    else @_return msg, err:"error: method #{msg.method} is unknown", res

  _return: (msg, rep, res) ->
    log "#{msg.id}: out", rep
    res.send rep
    
#
# Class Server
#
class classServer # for Http POST
  constructor: (@classes, @timeOut = sessionTimeOut) -> # list of classes that the server can instantiate
    @methods = []
    for Class of @classes
      @["#{Class}.sessions"] = []
      @methods[Class] = (method for method of @classes[Class].prototype when method.charAt(0) isnt '_' and method isnt 'constructor')

  process: (req, res) ->
    Class = req.path.substring(1)
    msg = req.body
    uid = msg.id.split('-')[0]
    rpc = @["#{Class}.sessions"][uid]
    @_resetTimeOut Class, rpc, uid
    unless rpc
      @["#{Class}.sessions"][uid] = rpc = new Rpc(new @classes[Class]())
      @_timeOut Class, rpc, uid
      log "adding new session #{Class} #{uid} (total: #{Object.keys(@["#{Class}.sessions"]).length})"

    rpc.process msg, res

  _timeOut: (Class, rpc, uid) ->
    rpc.timeOut = setTimeout => 
      delete @["#{Class}.sessions"][uid]
      log "removing session #{uid} (total: #{Object.keys(@["#{Class}.sessions"])})"
    , @timeOut

  _resetTimeOut: (Class, rpc, uid) -> if rpc then clearTimeout rpc.timeOut; @_timeOut Class, rpc, uid

#
# Class expressRpc: dispatch incoming HTTP requests / class
#
module.exports = class expressRpc
  constructor: (app, classes, options = {}) ->
    process.on 'uncaughtException', (err) -> log 'Caught exception: ', err.stack
    app.use parser.json limit:options.limit or '512kb'
    app.use (err, req, res, next) -> log err.stack; next err
    server = new classServer classes, options.timeOut
    for Class of classes
      app.post "/#{Class}", (req, res) -> server.process req, res

