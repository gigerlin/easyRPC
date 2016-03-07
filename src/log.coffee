###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

module.exports = (text...) -> console.log new Date().toISOString().replace('T', ' ').slice(0, 19), 'rpc', text...
