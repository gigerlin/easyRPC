
Remote = require('avs-easyrpc').Remote
expose = require('avs-easyrpc').expose

url = 'http://localhost:4145'

remote =  new Remote class:'Employee', methods:['getProfile', 'speak'], url:url
#remote.getProfile 'alice'

class Test
  echo: (user, text...) -> 
    console.log "#{user}:", text...
    45

#expose new Test(), remote, url
#.then (rep) -> remote.speak 'Hello from nodejs'

###
remote = new Remote class:'doesnotexist', methods:['test'], url:url
remote.test()
.then (rep) -> console.log 'then', rep
.catch (err) -> console.log 'cath', err

###

# client 1
p2p = new Remote class:'Peer 2 Peer', url:url
expose new Test(), p2p, url
.then (source) -> # return uid of peer
  console.log 'p2p', source.remoteID

  # client 2
  bob = new Remote class:'Peer 2 Peer', methods:['echo', 'test'], url:url, use:source.remoteID  
  bob.echo 'bob', msg:'Hello for peer 1234' # no return value
  # bob.test()