# easyRPC
RPC made easy for browser

This tiny library allows to easily invoke methods on remote objects from a web browser via an HTTP request. It uses the browser native fetch function (cf. [Fetch API](https://developer.mozilla.org/en/docs/Web/API/Fetch_API "Fetch API") for browser compatibility). Polyfills are provided for browser which do not support fetch or Promise.

Communication from the server to the clients is also supported via the native HTML5 EventSource (also known as Server-Side Event, SSE). This allows the server to invoke methods on client objects. The example provided is a very simple chat application.

Since it is based on pure HTTP, it should pass through main corporate firewalls.

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
Each remote object is allocated a unique session ID (see the debug section for details). Several remote objects can be created on the same remote class. They will all get a unique session ID. For example, one can create Bob and Alice as remote employees. Bob and Alice will have their own data and sessions...

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

A reserved method **__sse** is used for SSE support (cf. chat example for detail).

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
### API
#### Browser Side
##### new Remote
Create a remote object and invoke a method
```javascript
var remote = new Remote({ class:'rcn', methods:['rcm1', 'rcm2',...], url:'server'});
remote.rcm1(p1, p2).then(function(rep){ console.log(rep); });
```
  + *rcn* is the name of the remote class
  + *rcm1, rcm2, etc* are the methods that will be invoked on the remote object
  + *url (optional) is the URL of the server. Default is location.origin*

The method invocation always returns a Promise.

##### expose
Use SSE to process messages initiated by the server
```javascript
var local = new Local();
expose(local, new Remote({class:'rcn'}))
.then(function(source){ ... });
```
+ *local* is the local object that will process the messages sent by the server
+ expose needs a remote object to send to the server the SSE channel to use (see the Server side for counterpart). No specific method is needed. Remote objects have a reserved '__sse' method which is used to send SSE channel to the server.
+ expose returns a Promise that resolves when the source is connected to the server. The source is returned so that listening to the server can be stopped by invoking `source.stop()`.

#### Server Side
##### new Server
```javascript
var expressRpc = require('avs-easyrpc').Server;
new expressRpc(exp, { Employee: require('./employee') }, { timeOut: 10 * 60 * 1000, limit: '512kb' });
```
+ *exp* is the express instance (cf. example above)
+ *{ classes }* is the object containing all the classes the server can instantiate. Each object attribute is the name of the class that will be used on the client side to request an object creation.
+ *{ options }* are timeOut, i.e. the session duration (default is 30 minutes), and limit, the maximum message capacity (for each method invocation)

##### __sse
A class may define a '__sse' method if the server needs to send data to the client via SSE.
```javascript
  Employee.prototype.__sse = function(channel) {
    this.channel = channel;
    this.remote = new Remote({
      channel: this.channel,
      methods: ['echo']
    });
    return 'OK';
  };
```
The method '__sse' takes as input the SSE channel that the client is using. This channel allows the creation of a remote object on the client side (cf. the local object above) and the definition of the methods that can be invoked on the client object by the server. See the test files provided for a complete example. 

Unlike the remote objects on the client side, the methods of the remote objects created on the server side (which invoke method on the client) do not return values. If values have to be returned, the standard remote objects on the client are used.

### Debug
Outgoing and incoming messages are logged to the console on both sides.

#### Browser Side

2016-03-06 14:51:03 rpc 88487158-1: out {"method":"getProfile","args":["john"],"id":"88487158-1"}

2016-03-06 14:51:03 rpc 88487158-1: in {"rep":{"age":32,"email":"john@acme.com"}}

#### Server Side

2016-03-06 14:51:03 rpc adding new session Employee 88487158

2016-03-06 14:51:03 rpc 88487158-1: in { method: 'getProfile', args: [ 'john' ], id: '88487158-1' }

2016-03-06 14:51:03 rpc 88487158-1: out { age: 32, email: 'john@acme.com' }

Messages have a unique ID composed of the session ID and a chronological number. Example: 88487158-1 is the first message of the session 88487158.

#### Error Handling

Errors are reported from the server to the browser. For example, publish is not exposed by Employee:

2016-03-06 14:51:03 rpc 88487158-2: out {"method":"publish","args":[],"id":"88487158-2"}

2016-03-06 14:51:03 rpc 88487158-2: in {"err":"error: method publish is unknown"}

### Test - Chat Application
A minimalist sample is provided for test purpose. It includes all necessary files, in coffeescript and javascript format. The html file uses a browserified javascript file (test.min.js), that can be obtained via the command line:

`browserify -i ../js/rpc.js -i ../js/fetch.js -i ../js/promise.js -s LS test.js > test.min.js`

The sample is a chat application which demoes calls from client to server (speak) and from server to clients (echo). Here is the coffeescript **client side** of the chat application (file test.coffee):

```javascript
class Test
  echo: (user, text...) -> # the method invoked by the server 
    console.log "#{user}:", text...
    $('#messages').append($('<li>').text("#{user}:#{text[0]}"))

module.exports = remote = new Remote class:'Employee', methods:['speak']

expose new Test(), remote # this starts the SSE so that the Test object can be invoked
.then -> remote.speak 'hello'

remote.prespeak = -> # called by HTML button
  remote.speak $('#m').val()
  $('#m').val('') 
```

On the **server side** (file employee.coffee):

```javascript
chat = [] # the list of all members
count = 0 # automatic naming of members

module.exports = class Employee

  speak: (msg) ->
    delete chat[member] for member of chat when chat[member].channel.closed # remove members who left
    unless @alias then chat[@alias = "joe-#{++count}"] = @  # join the chat
    chat[member].remote.echo @alias, msg for member of chat # broadcast to every member
    'OK'
    
  __sse: (@channel) -> # the __sse method is required to get the SSE channel 
    @remote = new Remote channel:@channel, methods:['echo'] # client exposes the echo method
    'OK'
```  
