
Remote = require('avs-easyrpc').sseRemote

exports.Customer = class Customer extends Remote

  constructor: -> super ['test'] 

  _remoteReady: (remote) -> remote.test 'hi there'

