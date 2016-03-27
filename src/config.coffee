###
  @author Gilles Gerlinger
  Copyright 2016. All rights reserved.
###

module.exports = 
  tag: 'rpc'
  sse: '_remoteReady'
  srv: 'channel response'
  p2p: 'Peer 2 Peer'
  sessionTimeOut: 30 * 60 * 1000 # 30 minutes
  random: -> Math.random().toString().substring(2, 10)
