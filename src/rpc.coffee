###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

parser = require('body-parser')
Channel = require('./sse').Channel

if typeof Promise is 'undefined' then Promise = require './promise'

#
# Server Side
#
log = require './log'
sessionTimeOut = 30 * 60 * 1000 # 30 minutes
tag = 'rpc'

class Rpc # inspired from minimum-rpc
  constructor: (@local) ->

  process: (msg, res) ->
    log "#{msg.id} in", msg
    if @local[msg.method]
      try
        msg.args = [Channel.channels[msg.args[0]]] if msg.method is '__sse' # SSE Support
        rep = @local[msg.method] msg.args...
        if typeof rep.catch is 'function' # rep instanceof Promise
          rep.then (rep) =>  @_return msg, rep:rep, res
          rep.catch (err) => @_return msg, err:err, res
        else @_return msg, rep:rep, res
      catch e then @_return msg, err:"error in #{msg.method}: #{e}", res
    else @_return msg, err:"error: method #{msg.method} is unknown", res

  _return: (msg, rep, res) ->
    log "#{msg.id} out", rep
    res.send rep # sends response to client
    
#
# Class Server
#
class classServer # for Http POST
  constructor: (classes, @timeOut = sessionTimeOut) -> # list of classes that the server can instantiate
    @[Class] = Class:classes[Class], sessions:[] for Class of classes

  process: (Class, msg, res) ->
    uid = msg.id.split('-')[0]
    if rpc = @[Class].sessions[uid] then clearTimeout rpc.timeOut
    else # new session / new object
      # @[Class].date = new Date()
      @[Class].sessions[uid] = rpc = new Rpc new @[Class].Class()
      log "adding new session #{Class} #{uid} (total: #{Object.keys(@[Class]).length})"
    rpc.timeOut = setTimeout =>
      delete @[Class].sessions[uid]
      log "removing session #{uid} (total: #{Object.keys(@[Class]).length})"
    , @timeOut
    
    rpc.process msg, res

#
# Class expressRpc: dispatch incoming HTTP requests / class
#
module.exports = class expressRpc
  constructor: (app, classes, options = {}) ->
    process.on 'uncaughtException', (err) -> log 'Caught exception: ', err.stack
    app.use parser.json limit:options.limit or '512kb'
    app.use (err, req, res, next) -> log err.stack; next err
    server = new classServer classes, options.timeOut
    ( (Class) -> 
      log "listening on class #{Class}"
      app.post "/#{Class}", (req, res) -> server.process Class, req.body, res
    ) Class for Class of classes
#
# Add SSE Support
#
    app.get "/#{tag}", (req, res, next) -> new Channel req, res, next
