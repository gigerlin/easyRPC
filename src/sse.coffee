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
exports.expose = (local, remote) ->

  new Promise (resolve, reject) ->
    unless remote
      log err = 'SSE error: no remote object to create channel' 
      reject err
    
    source = new EventSource tag
    source.addEventListener tag, ( (e) -> 
      log 'SSE in', e.data 
      msg = JSON.parse e.data
      if msg.method then local[msg.method] msg.args...
      else if msg.uid
        remote.__sse msg.uid
        resolve msg.uid
    ), false

    source.addEventListener 'error', ( (e) -> 
      log 'SSE error', e
      # source.close()
    ), false

#
# server side
#
exports.Remote = class Remote 
  constructor: (options) -> 
    ctx = count:0, uid:Math.random().toString().substring(2, 10)

    ( (method) => @[method] = -> send options.channel, method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in options.methods

send = (channel, msg) ->
  log "#{msg.id} out #{channel.__uid}", msg
  channel.json msg
