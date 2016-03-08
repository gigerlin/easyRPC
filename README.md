# easyRPC
RPC made easy for browser

This tiny library allows to easily invoke methods on remote objects from a web browser via an HTTP request. It uses the browser native fetch function (cf. [Fetch API](https://developer.mozilla.org/en/docs/Web/API/Fetch_API "Fetch API") for browser compatibility). Polyfills are provided for browser which do not support fetch or Promise.

It uses also the native HTML5 EventSource to allow server to invoke methods on client obects. The example provided is a very simple chat application.

### Installation
`npm install avs-easyrpc`

The server needs the modules express and body-parser: `npm install express body-parser`

### Browser Side
Remote objects are defined by their class name and the methods that need to be invoked. For example:

```javascript
var Remote = require('avs-easyrpc').Remote;

var remote = new Remote({
  "class": 'Employee',
  methods: ['getProfile', 'publish'],
  url: location.origin
});
```
The third attribute, url, is optional. Default is location.origin. It can be used to point to a cross origin web server if needed.

Invocation is then possible on remote objects in a way similar to local objects. The main difference is that all methods return a Promise object (since the result of the invocation is deferred), that can be used to wait for the result. For example:

```javascript
remote.getProfile('john').then(function(rep) {
  var john = rep;
  console.log(john);
}).catch(function(err) {
  console.log(err);
});
```
Each remote object is allocated a unique session ID (see the debug section for details). Several remote objects can be created on the same remote class. They will all get a unique session ID. For example, one can create Bob and Alice are remote employees. Bob and Alice will have their own data and sessions...

### Server Side
On the server side, a server is required to instantiate the requested remote objects and process the method invocations. The server is based upon the express web framework.

```javascript
var express = require('express');
var test = express();
test.use(express.static(__dirname + '/'));

// Load the employee class
var expressRpc = require('avs-easyrpc').Server;
new expressRpc(test, { Employee: require('./employee') }, { timeOut: 10 * 60 * 1000, limit: '512kb' });

// Listen on port 8080
var http = require('http');
http.createServer(test).listen(8080, function() {
    return console.log("Server started at 8080", new Date());
  });
```  
On the first invocation, the remote object is created and subsequent invocations will be processed by this object. The timeOut option is the maximum inactivity duration of the remote object on the server, i.e., the session duration. If no request is made to the object in that period of time, the remote object is deleted. An invocation that happens after timeOut is reached will create a new object. Default timeOut is 30 minutes.

A second option is the maximum size of data transferred to remote object.Default is 512kb. Make it bigger if need be.

Exposed classes are needed so that the server can instantiate the objects requested by the browser. For example, the file employee.js could be:

```javascript
function Employee() {};
Employee.prototype.getProfile = function(name) {
  console.log('getProfile of', name);
  return { age: 32, email: 'john@acme.com' };
};
module.exports = Employee;
```
All methods of class Employee will be **automatically** exposed but the constructor and the methods beginning with '_' (those are seen as private methods).

If a method is asynchronous, meaning it does not return a result synchronously, a Promise mut be returned. For example:

```javascript
Employee.prototype.getProfile = function(name) {
  console.log('getProfile of', name);
  return new Promise(function(resolve, reject) {
    setTimeout(function() {
      resolve({ age: 32, email: 'john@acme.com' });
    }, 3000);
  });
};
```
**N.B.:** the rpc server can serve as many classes as required. For example:

```javascript
new expressRpc(test, { 
  Employee: require('./employee'), 
  Customer: require('./customer') 
}, { timeOut: 10 * 60 * 1000 });
```

### Debug
Outgoing and incoming messages are logged to the console on both sides.

#### Browser Example

2016-03-06 14:51:03 rpc 88487158-1: out {"method":"getProfile","args":["john"],"id":"88487158-1"}

2016-03-06 14:51:03 rpc 88487158-1: in {"rep":{"age":32,"email":"john@acme.com"}}

#### Server example

2016-03-06 14:51:03 rpc adding new session Employee 88487158

2016-03-06 14:51:03 rpc 88487158-1: in { method: 'getProfile', args: [ 'john' ], id: '88487158-1' }

2016-03-06 14:51:03 rpc 88487158-1: out { age: 32, email: 'john@acme.com' }

Messages have a unique ID composed of the session ID and a chronological number. Example: 88487158-1 is the first message of the session 88487158.

#### Error Handling

Errors are reported from the server to the browser. For example, publish is not exposed by Employee:

2016-03-06 14:51:03 rpc 88487158-2: out {"method":"publish","args":[],"id":"88487158-2"}

2016-03-06 14:51:03 rpc 88487158-2: in {"err":"error: method publish is unknown"}

### Test
A minimalist sample is provided for test purpose. It includes all necessary files, in coffeescript and javascript format. The html file uses a browserified javascript file (test.min.js), that can be obtained via the command line:

`browserify -i ./node_modules/avs-easyrpc/js/rpc.js -s LS test.js > test.min.js`

The sample is a chat application which demoes calls from client to server (speak) and from server to clients (echo). Here is the coffeescript server side of the chat application:

```javascript
chat = [] # the list of all members
count = 0 # automatic naming of members

module.exports = class Employee

  speak: (msg) ->
    unless @alias then chat[@alias = "joe-#{++count}"] = @ 
    chat[member].remote.echo @alias, msg for member of chat # broadcast to every member
    'OK'
```

On the client side:

```javascript
class Test
  echo: (user, text...) -> 
    console.log "#{user}:", text...
    $('#messages').append($('<li>').text("#{user}:#{text[0]}"))

module.exports = remote = new Remote class:'Employee', methods:['getProfile', 'speak']

expose new Test(), remote
.then -> remote.speak 'hello'

remote.prespeak = -> 
  remote.speak $('#m').val()
  $('#m').val('') 
```  