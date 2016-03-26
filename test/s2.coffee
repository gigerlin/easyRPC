http = require 'http'
#express = require './express'
express = require 'express'

expressRpc = require('avs-easyrpc').server

store = express()
store.use express.static(__dirname + '/')

port = 4145
http.createServer store
.listen port, -> 
  console.log "Server started at #{port}", new Date(), '\n'
  expressRpc store, { Employee:require('./employee'), Customer:require('./customer'), sseRet:require('./sseRet')}
#, Peer2peer:require('./p2p')