Remote = require('avs-easyrpc').Remote

remote = new Remote class:'Employee', methods:['getProfile', 'publish'], url:location.origin

remote.getProfile 'john'
.then (rep) -> console.log rep
.catch (err) -> console.log err

remote.publish()
.then (rep) -> console.log rep
.catch (err) -> console.log err

# browserify -i ./node_modules/avs-easyrpc/js/rpc.js test.js > test.min.js