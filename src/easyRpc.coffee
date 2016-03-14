###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

if typeof window is 'object' # for Safari & IE
  fetch = window.fetch or require './fetch'
  Promise = window.Promise or require './promise'

log = require './log'
tag = 'rpc'
sse = '__sse'

#
# Client Side
#
exports.Remote = class Remote 
  constructor: (options) -> 
    ctx = count:0, uid:Math.random().toString().substring(2, 10), request:"#{options.url or location.origin}/#{options.class}"
    options.methods = options.methods or []
    options.methods.push sse # SSE support

    ( (method) => @[method] = -> send ctx.request, method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in options.methods

send = (request, msg) ->
  log "#{msg.id} out", msg
  new Promise (resolve, reject) ->
    fetch request, headers:{'Content-Type':'application/json; charset=utf-8'}, method:'post', body:JSON.stringify msg 
    .catch (err) -> log "#{msg.id}: network error #{err}"; reject err
    .then (response) -> response.json() if response # no response when page reloads
    .then (rep) -> if rep
      log "#{msg.id} in", rep    
      if rep.err then reject rep.err else resolve rep.rep

#
# SSE Support
#
exports.expose = (local, remote) -> new Promise (resolve, reject) ->
  unless remote
    log err = 'SSE error: no remote object to create channel' 
    reject err
  
  source = new EventSource tag
  source.addEventListener tag, (e) -> 
    log 'SSE in', e.data 
    msg = JSON.parse e.data
    if msg.method
      if local[msg.method] then local[msg.method] msg.args...
      else log 'SSE error: no method', msg.method, 'for local object', local
    else if msg.uid # tell the remote object on the server which channel to use
      remote[sse] msg.uid
      resolve source # return source so that source.stop() can be called
  , false
