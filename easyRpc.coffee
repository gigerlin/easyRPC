###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

module.exports = class Remote 
  constructor: (options) -> 
    ctx = count:0, uid:Math.random().toString().substring(2, 10), request:"#{options.url or location.origin}/#{options.class}"

    ( (method) => @[method] = -> send ctx.request, method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in options.methods

send = (request, msg) ->
  message = JSON.stringify msg
  log "#{msg.id}: out #{message}"
  new Promise (resolve, reject) ->
    fetch request, headers:{'Content-Type':'application/json; charset=utf-8'}, method:'post', body:message 
    .catch (err) -> log "#{msg.id}: network error #{err}"; reject err
    .then (response) -> response.json() if response # no response when page reloads
    .then (rep) -> if rep
      log "#{msg.id}: in #{JSON.stringify rep}"    
      if rep.err then reject rep.err else resolve rep.rep

log = (text) ->
  text = text.substring(0, 127) + ' ...' if text.length > 127
  console.log new Date().toISOString().replace('T', ' ').slice(0, 19), 'rpc', text
