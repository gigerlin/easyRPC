###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

http = require 'http'
express = require 'express'
parser = require 'body-parser'

store = express()
store.use express.static(__dirname + '/')
store.use parser.json limit:'512kb'
store.use (err, req, res, next) -> log err.stack; next err

expressRpc = require('avs-easyrpc').server

port = 4145
http.createServer store
.listen port, -> 
  console.log "Server started at #{port}", new Date(), '\n'
  expressRpc store, { Employee:require('./employee'), Customer:require('./customer') }, timeOut:10 * 60 * 1000

