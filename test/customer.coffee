
exports.Customer = class Customer

  _remoteReady: (remote) -> 
    remote.setMethods ['test']
    remote.test 'hi there'

