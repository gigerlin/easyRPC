Remote = require('avs-easyrpc').Remote
expose = require('avs-easyrpc').expose

module.exports = remote = new Remote class:'Employee', methods:['getProfile', 'speak']
###
remote.getProfile 'john'
.then (rep) -> console.log rep
.catch (err) -> console.log err

remote.publish()
.then (rep) -> console.log rep
.catch (err) -> console.log err
###
class Test
  echo: (user, text...) -> 
    console.log "#{user}:", text...
    $('#messages').append($('<li>').text("#{user}:#{text[0]}"))

expose new Test(), remote
.then -> remote.speak 'hello'

remote.prespeak = -> 
  remote.speak $('#m').val()
  $('#m').val('')

# browserify -i ./node_modules/avs-easyrpc/js/rpc.js -s LS test.js > test.min.js