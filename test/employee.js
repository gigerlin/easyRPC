// Generated by CoffeeScript 1.10.0
(function() {
  var Employee, Promise, chat, count;

  if (typeof Promise === 'undefined') {
    Promise = require('avs-easyrpc').Promise;
  }

  chat = [];

  count = 0;

  module.exports = Employee = (function() {
    function Employee() {}

    Employee.prototype._remoteReady = function(remote) {
      this.remote = remote;
      return 'OK';
    };

    Employee.prototype.speak = function(msg) {
      var member;
      for (member in chat) {
        if (chat[member]._sseChannel.closed) {
          delete chat[member];
        }
      }
      if (!this.alias) {
        chat[this.alias = "joe-" + (++count)] = this.remote;
      }
      for (member in chat) {
        chat[member].echo(this.alias, msg);
      }
      return 'OK';
    };

    Employee.prototype.getProfile = function(name) {
      return new Promise(function(resolve, reject) {
        return setTimeout((function() {
          return resolve({
            age: 32,
            email: 'john@acme.com'
          });
        }), 3000);
      });
    };

    return Employee;

  })();

}).call(this);
