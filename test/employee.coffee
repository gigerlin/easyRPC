#
# Server Side
#

if typeof Promise is 'undefined' then Promise = require('avs-easyrpc').Promise

log = require('avs-easyrpc').log
Remote = require('avs-easyrpc').sseRemote

chat = [] # the list of all members
count = 0 # automatic naming of members

exports.Employee = class Employee

  speak: (msg) ->
    delete chat[member] for member of chat when chat[member].channel.closed # remove members who left
    unless @alias then chat[@alias = "joe-#{++count}"] = @  # join the chat
    chat[member].remote.echo @alias, msg for member of chat # broadcast to every member
    'OK'

  __sse: (@channel) -> # the __sse method is required to get the SSE channel 
    @remote = new Remote channel:@channel, methods:['echo'] # client exposes the echo method
    'OK'

  getProfile: (name) -> 
    new Promise (resolve, reject) ->
      setTimeout (-> resolve age:32, email:'john@acme.com'), 3000 


    
