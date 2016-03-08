#
# Server Side
#

if typeof Promise is 'undefined' then Promise = require('avs-easyrpc').Promise

log = require('avs-easyrpc').log
Remote = require('avs-easyrpc').sseRemote

chat = [] # the list of all members
count = 0 # automatic naming of members

module.exports = class Employee

  getProfile: (name) -> 
    new Promise (resolve, reject) ->
      setTimeout (-> resolve age:32, email:'john@acme.com'), 3000 

  __sse: (channel) -> # the __sse method is required to get the SSE channel 
    @remote = new Remote channel:channel, methods:['echo'] # client exposes the echo method
    'OK'

  speak: (msg) ->
    unless @alias then chat[@alias = "joe-#{++count}"] = @ 
    chat[member].remote.echo @alias, msg for member of chat # broadcast to every member
    'OK'
    


    
