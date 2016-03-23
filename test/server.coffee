###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

http = require 'http'
express = require 'express'
#connect = require 'connect'
expressRpc = require('avs-easyrpc').server

store = express()
store.use express.static(__dirname + '/')

process.on 'uncaughtException', (err) -> console.log 'Caught exception: ', err.stack

port = 4145
http.createServer store
.listen port, -> 
  console.log "Server started at #{port}", new Date(), '\n'
  expressRpc store, { Employee:require('./employee'), Customer:require('./customer') }, timeOut:10 * 60 * 1000

