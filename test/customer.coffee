
Remote = require('avs-easyrpc').sseRemote

exports.Customer = class Customer

  test: -> 'customer'

  __sse: (@channel) -> # the __sse method is required to get the SSE channel 
    @remote = new Remote channel:@channel, methods:['test'] # client exposes the echo method
    @remote.test 'coucou'
    'OK'

    
