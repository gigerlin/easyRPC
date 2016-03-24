###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

log = require './log'
cnf = require './config'

#
# Client Side
#
exports.Remote = class Remote 
  constructor: (options) -> 
    ctx = count:0, uid:Math.random().toString().substring(2, 10), request:"#{options.url or location.origin}/#{options.class}"
    options.methods = options.methods or []
    options.methods.push cnf.sse # SSE support

    ( (method) => @[method] = -> send ctx.request, method:method, args:[].slice.call(arguments), id:"#{ctx.uid}-#{++ctx.count}"
    ) method for method in options.methods

  send = (request, msg) ->
    log "#{msg.id} out", msg
    new Promise (resolve, reject) ->
      fetch request, headers:{'Content-Type':'application/json; charset=utf-8'}, method:'post', body:JSON.stringify msg
      .catch (err) -> 
        log "#{msg.id} in: network error", err
        reject err
      .then (response) -> 
        if response.ok then response.json() 
        else
          log "#{msg.id} in: network error", response.statusText
          reject response.statusText
      .then (rep) -> if rep
        log "#{msg.id} in", rep
        if rep.err then reject rep.err else resolve rep.rep

#
# SSE Support
#
exports.expose = (local, remote, url) -> 
  local = local or {}
  methods = (method for method of local when method.charAt(0) isnt '_')
  remote = remote or "#{cnf.sse}": -> log "missing remote object in expose"
  new Promise (resolve, reject) ->
    source = new EventSource if url then "#{url}/#{cnf.tag}" else cnf.tag
    source.addEventListener cnf.tag, (e) -> 
      log 'SSE in', e.data 
      msg = JSON.parse e.data
      if msg.method
        if local[msg.method] then local[msg.method] msg.args...
        else log 'SSE error: no method', msg.method, 'for local object', local
      else if msg.uid # tell the remote object on the server which channel and methods to use
        remote[cnf.sse] msg.uid, methods
        resolve source # return source so that source.stop() can be called
    , false

#
# Required modules
#
if typeof window is 'object' # for Safari & IE
  fetch = window.fetch or require './fetch'
  Promise = window.Promise or require './promise'
  EventSource = window.EventSource

else if typeof global is 'object' # Nodejs
  Promise = global.Promise
  http = require 'http'
  EventSource = require 'EventSource'
  fetch = (uri, options) -> new Promise (resolve, reject) ->
    uri = uri.replace /https?:\/\//, ''
    tmp = uri.split '/'
    options.path = "/#{tmp[1]}"
    tmp = tmp[0].split ':'
    options.hostname = tmp[0]
    options.port = tmp[1] if tmp[1]
    req = http.request options, (res) ->
      res.setEncoding('utf8')
      res.on 'data', (body) -> if body.indexOf('"') is -1 then reject body else resolve new Response body
    req.on 'error', (e) -> reject e.message
    req.write(options.body)
    req.end()

class Response
  constructor: (@data, @ok = true) ->
  json: -> JSON.parse @data

