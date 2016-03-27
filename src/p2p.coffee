

remotes = []

module.exports = class Peer2peer

  _remoteReady: (@remote, @remoteID) -> remotes[@remoteID] = @remote

  invoke: (remoteID, method, args...) -> 
    console.log 'invoke', remoteID, method, remotes[remoteID]?
    if remotes[remoteID]
      if remotes[remoteID][method] 
        new Promise (resolve, reject) ->
          remotes[remoteID][method] args... 
          .then (rep) -> resolve rep
      else throw "method #{method} is unknown for object #{remoteID}"
    else throw "no object remote at #{remoteID}"
