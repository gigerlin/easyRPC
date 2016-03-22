###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

fs = require 'fs'

routes = []
module.exports = ->
  app = (req, res) ->
    #console.log req.headers
    body = []
    req.on 'data', (chunk) -> body.push chunk
    req.on 'end', ->
      if route = routes[req.url]
        req.body = Buffer.concat(body).toString() 
        req.body = JSON.parse req.body if req.headers['content-type'] and req.headers['content-type'].indexOf('application/json') > -1
        res.send = (msg) -> res.end JSON.stringify msg
        route req, res
      else # this is a file
        fs.readFile "./#{req.url}", (err, data) ->
          res.statusCode = unless err then 200 else 404
          res.end data

  app.post= (path, route) -> routes[path] = route
  app.get = (path, route) -> routes[path] = route
  app.use = (path, route) -> routes[path] = route
  return app 
