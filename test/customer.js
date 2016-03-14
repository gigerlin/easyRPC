// Generated by CoffeeScript 1.10.0
(function() {
  var Customer, Remote,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Remote = require('avs-easyrpc').sseRemote;

  exports.Customer = Customer = (function(superClass) {
    extend(Customer, superClass);

    function Customer() {
      Customer.__super__.constructor.call(this, ['test']);
    }

    Customer.prototype._remoteReady = function(remote) {
      return remote.test('hi there');
    };

    return Customer;

  })(Remote);

}).call(this);