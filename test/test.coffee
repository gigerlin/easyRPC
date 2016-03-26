Remote = require('avs-easyrpc').Remote
expose = require('avs-easyrpc').expose

module.exports = remote = new Remote class:'Employee', methods:['getProfile', 'speak']

class Test
  echo: (user, text...) -> 
    console.log "#{user}:", text...
    $('#messages').append($('<li>').text("#{user}:#{text[0]}"))
    null # to prevent sending response to server

expose new Test(), remote # this starts the SSE so that the Test object can be invoked
.then -> remote.speak 'hello'

remote.prespeak = -> # called by HTML button
  remote.speak $('#m').val()
  $('#m').val('')

src = null
class Deux
  test: (msg) -> 
    console.log 'deux: ', msg
    src.close()
    null

expose new Deux(), new Remote class:'Customer'
.then (source) -> src = source

rem2 = new Remote class:'doesnotexist', methods:['test']
rem2.test()
.then (rep) -> console.log rep
.catch (err) -> console.log err

###
remote.getProfile 'john'
.then (rep) -> console.log rep
.catch (err) -> console.log err

remote.publish()
.then (rep) -> console.log rep
.catch (err) -> console.log err
###

# browserify -i ./node_modules/avs-easyrpc/js/rpc.js -s LS test.js > test.min.js