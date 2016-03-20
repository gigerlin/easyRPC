
Remote = require('avs-easyrpc').Remote
expose = require('avs-easyrpc').expose

url = 'http://localhost:4145'

remote =  new Remote class:'Employee', methods:['getProfile', 'speak'], url:url
remote.getProfile 'alice'

class Test
  echo: (user, text...) -> console.log "#{user}:", text...

expose new Test(), remote, url
.then (rep) -> remote.speak 'Hello from nodejs'
