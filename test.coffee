Remote = require './easyRPC'

remote = new Remote class:'Employee', methods:['getProfile', 'publish']

remote.getProfile 'john'
.then (rep) -> console.log rep
.catch (err) -> console.log err

remote.publish()
.then (rep) -> console.log rep
.catch (err) -> console.log err
