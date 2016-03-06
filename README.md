# easyRPC
RPC made easy for browser

This tiny library allows to easily invoke methods on remote objects from a web browser via an HTTP request. It uses the browser native fetch function (cf. https://developer.mozilla.org/en/docs/Web/API/Fetch_API for browser compatibility). Polyfills exist for browser which do not support fetch.

### Browser Side
Remote objects are defined by their class name and the methods that need to be invoked. For example:

Remote = require('avs-easyrpc').Remote;

remote = new Remote({
  "class": 'Employee',
  methods: ['getProfile', 'publish']
});

An optional attribute url can be used to point to a cross origin web server if needed (the default url is location.origin)

Invokation is then possible on remote objects in a way similar to local objects. The main difference is that all methods return a Promise object (since the result of the invokation is deferred), that can be used to wait for the result. For example:

remote.getProfile('john').then(function(rep) {
  return console.log(rep);
})["catch"](function(err) {
  return console.log(err);
});

### Server Side
On the server side, a server is required to instantiate the requested remote objects and process the method invokations.

var express = require('express');
var expressRpc = require('avs-easyrpc').Server;
var test = express();
test.use(express["static"](__dirname + '/'));
new expressRpc(test, { Employee: require('./employee'), timeOut: 10 * 60 * 1000 });

var http = require('http');
http.createServer(test).listen(8080, function() {
    return console.log("Server started at 8080", new Date());
  });
  
On the first invokation, the remote object is created and subsequent invokations will be processed by the object (this .
timeOut is the life duration of the remote object on the server or the session duration. If no request is made to the object in that period of time, the remote object is deleted. An invokation that happens after timeOut is reached will create a new object. Default timeOut is 30 minutes.

Exposed classes are needed so that the server can instantiate the objects requested by the browser. For example, the file exmployee.js could be:

function Employee() {};
Employee.prototype.getProfile = function(name) {
  console.log('getProfile of', name);
  return { age: 32, email: 'john@acme.com' };
};
module.exports = Employee;

All methods of class Employee will be automatically exposed but the constructor and the methods beginning with '_' (private methods).

### Debug
Outgoing and incoming messages are logged to the console on both sides.

Browser Example
2016-03-06 14:51:03 rpc 88487158-1: out {"method":"getProfile","args":["john"],"id":"88487158-1"}
2016-03-06 14:51:03 rpc 88487158-1: in {"rep":{"age":32,"email":"john@acme.com"}}

Server example
2016-03-06 14:51:03 rpc adding new session Employee 88487158
2016-03-06 14:51:03 rpc 88487158-1: in { method: 'getProfile', args: [ 'john' ], id: '88487158-1' }
2016-03-06 14:51:03 rpc 88487158-1: out { age: 32, email: 'john@acme.com' }

Messages have an unique ID composed of the session ID and a chronological number. Example: 88487158-1 is the first message of the session 88487158


