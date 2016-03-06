###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

http = require 'http'
express = require 'express'
expressRpc = require('./rpc')

new expressRpc store = express(), Employee:require('./employee'), timeOut:10 * 60 * 1000
store.use express.static(__dirname + '/')

port = 4145
http.createServer store
.listen port, -> console.log "Server started at #{port}", new Date()
