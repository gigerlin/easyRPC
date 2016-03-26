

remotes = []

module.exports = class Peer2peer

  _remoteReady: (@remote, @uid) -> 
    console.log 'Peer2peer', @uid
    remotes[@uid] = @remote

  invoke: (uid, method, args...) -> 
    console.log 'invoke', uid, method, remotes[uid]?
    if remotes[uid]
      if remotes[uid][method] 
        new Promise (resolve, reject) ->
          remotes[uid][method] args... 
          .then (rep) -> 
            console.log rep
            resolve rep
      else throw "method #{method} is unknown for object #{uid}"
    else throw "no object remote at #{uid}"
