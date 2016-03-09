###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

log = require './log'
tag = 'rpc'

if typeof window is 'object' then Promise = window.Promise or require './promise' # for Safari & IE

#
# client side
#
exports.expose = (local, remote) -> new Promise (resolve, reject) ->
  unless remote
    log err = 'SSE error: no remote object to create channel' 
    reject err
  
  source = new EventSource tag
  source.addEventListener tag, ( (e) -> 
    log 'SSE in', e.data 
    msg = JSON.parse e.data
    if msg.method then local[msg.method] msg.args...
    else if msg.uid # tell the remote object on the server which channel to use
      remote.__sse msg.uid
      resolve msg.uid
  ), false
###
  source.addEventListener 'error', ( (e) -> 
    log 'SSE error', e
    # source.close()
  ), false
###
#
# server side
#
exports.Remote = class Remote 
  constructor: (options) -> 
    unless options.channel
      log 'SSE error: no channel for remote object create'
      return

    ctx = count:0, uid:Math.random().toString().substring(2, 10)
    options.methods = options.methods or []

    ( (method) => @[method] = -> options.channel.send method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in options.methods

exports.Channel = class Channel
  @channels:[]
  constructor: (req, resp, next) ->
    @socket = resp
    Channel.channels[@uid = Number(new Date()).toString()] = @
    resp.statusCode = 200
    resp.setHeader 'Content-Type', 'text/event-stream'
    resp.setHeader 'Cache-Control', 'no-cache'
    resp.setHeader 'Connection', 'keep-alive'
    resp.setHeader 'Access-Control-Allow-Origin', '*'
    req.on 'close', => 
      log 'SSE', @uid, 'closed' 
      delete Channel.channels[@uid]
      @closed = true
    @send uid:@uid, id:'SSE'
    next()

  send: (msg) -> 
    log "#{msg.id} out #{@uid}", msg
    @socket.write "event: #{tag}\ndata: #{JSON.stringify msg}\n\n"

