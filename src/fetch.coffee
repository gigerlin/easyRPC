###
  @author Gilles Gerlinger
  Copyright 2015. All rights reserved.
###

if typeof window is 'object' then Promise = window.Promise or require './promise' # for Safari & IE

module.exports = fetch = (uri, options) ->
  # console.log 'using own fetch'
  new Promise (resolve, reject) ->
    xhr = new XMLHttpRequest()
    xhr.open options.method, uri, true
    xhr.setRequestHeader 'Content-type', 'application/json; charset=utf-8'
    # xhr.ontimeout = -> alert 'time out' # timeout is 0
    xhr.send options.body or null
    xhr.onload = -> resolve data:xhr.response
    xhr.onerror = -> reject "xhr error: #{xhr.statusText}"
