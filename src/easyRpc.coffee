###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

log = require './log'

if typeof window is 'object' # for Safari & IE
  fetch = window.fetch or require './fetch'
  Promise = window.Promise or require './promise'

module.exports = class Remote 
  constructor: (options) -> 
    ctx = count:0, uid:Math.random().toString().substring(2, 10), request:"#{options.url or location.origin}/#{options.class}"

    ( (method) => @[method] = -> send ctx.request, method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in options.methods

send = (request, msg) ->
  log "#{msg.id}: out", msg
  new Promise (resolve, reject) ->
    fetch request, headers:{'Content-Type':'application/json; charset=utf-8'}, method:'post', body:JSON.stringify msg 
    .catch (err) -> log "#{msg.id}: network error #{err}"; reject err
    .then (response) -> response.json() if response # no response when page reloads
    .then (rep) -> if rep
      log "#{msg.id}: in", rep    
      if rep.err then reject rep.err else resolve rep.rep
