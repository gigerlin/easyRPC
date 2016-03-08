###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

module.exports = (text...) -> console.log new Date().toLocaleString(), 'rpc', text...
