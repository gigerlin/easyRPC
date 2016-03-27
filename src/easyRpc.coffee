###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

log = require './log'
cnf = require './config'
className = 'class name'

#
# Client Side
#
exports.Remote = class Remote 
  constructor: (options) -> 
    @[className] = options.class
    count = 0; uid = cnf.random()
    
    ctx = use:options.use, request:"#{options.url or location.origin}/#{encodeURIComponent options.class}"
    options.methods = options.methods or []
    options.methods.push cnf.sse # SSE support

    ( (method) => @[method] = -> send ctx, method:method, args:[].slice.call(arguments), id:"#{uid}-#{++count}"
    ) method for method in options.methods

send = (ctx, msg) ->
  log "#{msg.id} out", msg
  if ctx.use 
    msg.args = [ctx.use, msg.method].concat msg.args
    msg.method = 'invoke'
  new Promise (resolve, reject) ->
    fetch ctx.request, headers:{'Content-Type':'application/json; charset=utf-8'}, method:'post', body:JSON.stringify msg
    .catch (err) -> 
      log "#{msg.id} in", err
      reject err
    .then (response) -> 
      if response.ok then response.json() else
        log "#{msg.id} in network error:", response.statusText # 404 for example
        reject response.statusText
    .then (rep) -> if rep
      log "#{msg.id} in", rep
      if rep.err then reject rep.err else resolve rep.rep

#
# SSE Support
#
class Source
  constructor: (@source, @remoteID) ->
  close: -> source.close()

exports.expose = (local, remote, url = location.origin) -> 
  local = local or {}
  methods = (method for method of local when method.charAt(0) isnt '_')
  remote = remote or "#{cnf.sse}": -> log "missing remote object in expose"
  new Promise (resolve, reject) ->
    source = new EventSource "#{url}/#{cnf.tag}"
    source.addEventListener cnf.tag, (init) -> 
      log 'SSE init', init.data 
      msg = JSON.parse init.data
      if msg.uid # tell the remote object on the server which channel and methods to use
        source.uid = msg.uid
        source.addEventListener "#{cnf.tag}/#{msg.uid}", (e) -> 
          log 'SSE in', e.type, e.data
          msg = JSON.parse e.data
          if msg.method
            if local[msg.method] 
              rep = local[msg.method] msg.args...
              if msg.args = rep # only if there is a value to be returned
                msg.method = cnf.srv
                send request:"#{url}/#{encodeURIComponent remote[className]}", msg
            else log 'SSE error: no method', msg.method, 'for local object', local
        remote[cnf.sse] msg.uid, methods # this calls _remoteReady
        .then (remoteID) -> resolve new Source source, remoteID # return source so that source.stop() can be called and P2P can be used
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
#    console.log "#{options.hostname}:#{options.port}#{options.path}"
    req = http.request options, (res) ->
      res.setEncoding('utf8')
      res.on 'data', (body) -> if body.indexOf('"') is -1 then reject body else resolve new Response body
    req.on 'error', (e) -> reject e.message
    req.write options.body
    req.end()

class Response
  constructor: (@data, @ok = true) ->
  json: -> JSON.parse @data

