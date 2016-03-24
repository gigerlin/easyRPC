###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

fs = require 'fs'

routes = []; all = '*'
module.exports = ->
  app = (req, res) ->
    if routes[req.url]
      roads = if root = routes[all] then root.concat(routes[req.url]) else routes[req.url]
      index = 0
      (next = -> if index < roads.length then roads[index++] req, res, next)()    
    else # this is a file
      fs.readFile "./#{req.url}", (err, data) ->
        if err
          res.statusCode = 404
          res.end "error: no class #{req.url.substring(1)}"   
         else 
          res.statusCode = 200
          res.end data

  app.post = app.get = app.use = (path, route) -> 
    if typeof path is 'function' then route = path; path = all
    if road = routes[path] then road.push route else routes[path] = [route]

  return app 
