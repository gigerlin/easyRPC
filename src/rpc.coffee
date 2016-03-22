###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

#
# Server Side
#
log = require './log'
cnf = require './config'

class Rpc # inspired from minimum-rpc
  constructor: (@local) ->

  process: (msg, res) ->
    log "#{msg.id} in", msg
    if msg.method is cnf.sse # SSE Support
      if typeof @local[cnf.sse] is 'function'
        @local[cnf.sse] new Remote Channel.channels[msg.args[0]], msg.args[1]
        _return msg, rep:'sse OK', res
      else _return msg, err:"error: no _remoteReady method for channel #{msg.args[0]}", res
    else if @local[msg.method]
      try
        rep = @local[msg.method] msg.args...
        if typeof rep.catch is 'function' # rep instanceof Promise
          rep.then (rep) ->  _return msg, rep:rep, res
          rep.catch (err) -> _return msg, err:err, res
        else _return msg, rep:rep, res
      catch e then _return msg, err:"error in #{msg.method}: #{e}", res
    else _return msg, err:"error: method #{msg.method} is unknown", res

  _return = (msg, rep, res) ->
    log "#{msg.id} out", rep
    res.send rep # sends response to client
    
#
# Class Server
#
class classServer # for Http POST
  constructor: (classes, @timeOut = cnf.sessionTimeOut) -> # list of classes that the server can instantiate
    @["def #{Class}"] = Class:classes[Class], sessions:[] for Class of classes # 'def Class' to allow Class = process

  process: (Class, msg, res) ->
    uid = msg.id.split('-')[0] # get session ID
    if rpc = @["def #{Class}"].sessions[uid] then clearTimeout rpc.timeOut
    else # new session / new object
      # @[Class].date = new Date()
      @["def #{Class}"].sessions[uid] = rpc = new Rpc new @["def #{Class}"].Class()
      @_echo Class, 'adding', uid
    rpc.timeOut = setTimeout =>
      delete @["def #{Class}"].sessions[uid]
      @_echo Class, 'removing', uid
    , @timeOut
    
    rpc.process msg, res # at last process the message

  _echo: (Class, operation, uid) -> log "#{operation} #{Class} session #{uid} (# sessions: #{Object.keys(@["def #{Class}"].sessions).length})"

#
# Class expressRpc: dispatch incoming HTTP requests / class
#
module.exports = (app, classes, options = {}) ->
  process.on 'uncaughtException', (err) -> log 'Caught exception: ', err.stack
  server = new classServer classes, options.timeOut
  ( (Class) -> 
    log "listening on class #{Class}"
    app.post "/#{Class}", (req, res) -> server.process Class, req.body, res
  ) Class for Class of classes
#
# Add SSE Support
#
  app.get "/#{cnf.tag}", (req, res, next) -> new Channel req, res, next

class Remote
  constructor: (@_sseChannel, methods) -> 
    ctx = count:0, uid:Math.random().toString().substring(2, 10)

    ( (method) => @[method] = => @_sseChannel.send method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in methods or []

class Channel
  @channels:[]
  constructor: (req, @resp, next) ->
    Channel.channels[@uid = Number(new Date()).toString()] = @
    @resp.statusCode = 200
    @resp.setHeader 'Content-Type', 'text/event-stream'
    @resp.setHeader 'Cache-Control', 'no-cache'
    @resp.setHeader 'Connection', 'keep-alive'
    @resp.setHeader 'Access-Control-Allow-Origin', '*'
    req.on 'close', => 
      log 'SSE', @uid, 'closed' 
      delete Channel.channels[@uid]
      @closed = true
    @send uid:@uid, id:'SSE'
    next() if next

  send: (msg) -> 
    log "#{msg.id} out #{@uid}", msg
    @resp.write "event: #{cnf.tag}\ndata: #{JSON.stringify msg}\n\n"


