
Remote = require('avs-easyrpc').Remote

expose = require('avs-easyrpc').expose
url = 'http://localhost:4145'
remote =  new Remote class:'sseRet', url:url

class Test
  get: (p) -> ++p

expose new Test(), remote, url
