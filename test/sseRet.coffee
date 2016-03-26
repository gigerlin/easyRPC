

remotes = []

module.exports = class seeRet

  _remoteReady: (@remote) -> 
    @remote.get 35
    .then (rep) -> console.log 'johnny', rep

    @remote.get 351
    .then (rep) -> console.log 'be good', rep
 