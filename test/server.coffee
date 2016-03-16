###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

http = require 'http'
express = require 'express'
store = express()
store.use express.static(__dirname + '/')

expressRpc = require('avs-easyrpc').Server

port = 4145
http.createServer store
.listen port, -> 
  console.log "Server started at #{port}", new Date(), '\n'
  new expressRpc store, { Employee:require('./employee'), Customer:require('./customer') }, timeOut:10 * 60 * 1000

