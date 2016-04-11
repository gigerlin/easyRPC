###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

#
# Server Side
#
Promise = global.Promise or require './promise'

log = require './log'
cnf = require './config'
sseChannel = 'c hannel'

class Rpc # inspired from minimum-rpc
  constructor: (@local) ->

  process: (msg, res) ->
    log "#{msg.id} in", msg
    if msg.method is cnf.sse # SSE Support
      if typeof @local[cnf.sse] is 'function' # channel opens, cnf.sse is called
        _return msg, rep:uid = "r-#{cnf.random()}", res
        @local[cnf.sse] new Remote(@local, msg), uid
      else _return msg, err:"error: no _remoteReady method for channel #{msg.args[0]}", res
    else if msg.method is cnf.srv
      @local[sseChannel].resolve msg

    else if @local[msg.method] # standard remote
      try
        rep = @local[msg.method] msg.args...
        if rep and typeof rep.then is 'function' # rep is thenable (ie, it is a Promise)
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
getSession = (msg) -> msg.id.split('-')[0] if msg.id # get session ID

class classServer # for Http POST
  constructor: (classes, @timeOut = cnf.sessionTimeOut) -> # list of classes that the server can instantiate
    for Class of classes when typeof classes[Class] is 'function'
      @["def #{Class}"] = Class:classes[Class], sessions:[] # 'def Class' to allow Class = process
    @["def #{cnf.p2p}"] = Class:require('./p2p'), sessions:[]

  process: (Class, msg, res) ->
    uid = getSession msg # get session ID
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
json = (req, res, next) ->
  body = []
  req.on 'data', (chunk) -> body.push chunk
  req.on 'end', ->
    req.body = Buffer.concat(body).toString()
    if req.headers['content-type'] and req.headers['content-type'].indexOf('application/json') > -1
      req.body = JSON.parse req.body
      unless res.send then res.send = (msg) -> res.end JSON.stringify msg 
    next()

module.exports = (app, classes, options = {}) ->
  server = new classServer classes, options.timeOut
  app.use json
  app.post "/#{encodeURIComponent cnf.p2p}", (req, res) -> server.process cnf.p2p, req.body, res
  ( (Class) -> 
    log "listening on class #{Class}"
    app.post "/#{encodeURIComponent Class}", (req, res) -> server.process Class, req.body, res
  ) Class for Class of classes
#
# Add SSE Support
#
  app.get "/#{cnf.tag}", (req, res, next) -> new Channel req, res if req.headers.accept and req.headers.accept is 'text/event-stream'

class Remote
  constructor: (local, msg) -> 
    local[sseChannel] = new ChannelQ() # add a queue to the remote object
    @_sseChannel = Channel.channels[msg.args[0]] # set _sseChannel so that it can be closed
    count = 0; uid = getSession msg # send message with same session ID

    ( (method) => @[method] = => send @_sseChannel, local[sseChannel], method:method, args:[].slice.call(arguments), id:"#{uid}-s#{++count}"
    ) method for method in msg.args[1] or []

  send = (channel, q, msg) ->
    new Promise (resolve, reject) ->
      q.push msg, resolve
      channel.send msg

class Channel
  @channels:[]
  constructor: (req, @resp) ->
    Channel.channels[@uid = "c-#{cnf.random()}"] = @
    log "SSE out #{@uid}", msg = uid:@uid
    @resp.writeHead 200, 'Content-Type':'text/event-stream', 'Cache-Control':'no-cache', Connection:'keep-alive', 'Access-Control-Allow-Origin':'*'
    @resp.write "event: #{cnf.tag}\ndata: #{JSON.stringify msg}\n\n"
    req.on 'close', => 
      log 'SSE', @uid, 'closed' 
      delete Channel.channels[@uid]
      @closed = true

  send: (msg) -> 
    log "#{msg.id} out #{@uid}", msg
    @resp.write "event: #{cnf.tag}/#{@uid}\ndata: #{JSON.stringify msg}\n\n"

class ChannelQ
  constructor: -> @queue = []
  push: (msg, resolve) -> @queue[msg.id] = resolve
  resolve: (msg) -> 
    if resolve = @queue[msg.id]
      resolve msg.args
      delete @queue[msg.id]

process.on 'uncaughtException', (err) -> console.log 'Caught exception: ', err.stack

