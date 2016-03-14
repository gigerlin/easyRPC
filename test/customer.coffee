
exports.Customer = class Customer extends require('avs-easyrpc').SSE

  _remoteReady: (remote) -> 
    remote.setMethods ['test']
    remote.test 'hi there'

