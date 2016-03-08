###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

parser = require('body-parser')

if typeof Promise is 'undefined' then Promise = require './promise'

log = require './log'
sessionTimeOut = 30 * 60 * 1000 # 30 minutes
tag = 'rpc'

#
# Http Rpc
#
class Rpc # inspired from minimum-rpc
  constructor: (@local) ->

  process: (msg, res) ->
    log "#{msg.id} in", msg
    if @local[msg.method]
      try
        msg.args = [channels[msg.args[0]]] if msg.method is '__sse' # SSE Support
        rep = @local[msg.method] msg.args...
        if typeof rep.catch is 'function' # rep instanceof Promise
          rep.then (rep) =>  @_return msg, rep:rep, res
          rep.catch (err) => @_return msg, err:err, res
        else @_return msg, rep:rep, res
      catch e then @_return msg, err:"error in #{msg.method}: #{e}", res
    else @_return msg, err:"error: method #{msg.method} is unknown", res

  _return: (msg, rep, res) ->
    log "#{msg.id} out", rep
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
      log "listening on class #{Class}"
      app.post "/#{Class}", (req, res) -> server.process req, res
#
# SSE Support
#
    app.get "/#{tag}", sse, (req, res) -> 
      channels[uid = Number(new Date())] = res
      log 'SSE channel uid:', uid
      res.__uid = uid
      res.json uid:uid

channels = []
sse = (req, resp, next) ->
  resp.statusCode = 200
  resp.setHeader 'Content-Type', 'text/event-stream'
  resp.setHeader 'Cache-Control', 'no-cache'
  resp.setHeader 'Connection', 'keep-alive'
  resp.json = (msg) -> resp.write "event: #{tag}\ndata: #{JSON.stringify msg}\n\n"
  next()
