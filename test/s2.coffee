http = require 'http'
express = require './express'
expressRpc = require('avs-easyrpc').server

store = express()

port = 4145
http.createServer store
.listen port, -> 
  console.log "Server started at #{port}", new Date(), '\n'
  expressRpc store, { Employee:require('./employee'), Customer:require('./customer') }
