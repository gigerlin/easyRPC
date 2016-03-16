#
# Server Side
#

if typeof Promise is 'undefined' then Promise = require('avs-easyrpc').Promise

chat = [] # the list of all members
count = 0 # automatic naming of members

# !!! __sse is a reserved word

exports.Employee = class Employee

  _remoteReady: (@remote) -> @remote.setMethods ['echo']; 'OK' # called when SSE channel opens

  speak: (msg) ->
    delete chat[member] for member of chat when chat[member]._sseChannel.closed # remove members who left
    unless @alias then chat[@alias = "joe-#{++count}"] = @remote  # join the chat
    chat[member].echo @alias, msg for member of chat # broadcast to every member
    'OK'

  getProfile: (name) -> 
    new Promise (resolve, reject) ->
      setTimeout (-> resolve age:32, email:'john@acme.com'), 3000 


    
