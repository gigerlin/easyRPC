// Generated by CoffeeScript 1.8.0
(function() {
  var Remote, remote;

  Remote = require('avs-easyrpc').Remote;

  remote = new Remote({
    "class": 'Employee',
    methods: ['getProfile', 'publish']
  });

  remote.getProfile('john').then(function(rep) {
    return console.log(rep);
  })["catch"](function(err) {
    return console.log(err);
  });

  remote.publish().then(function(rep) {
    return console.log(rep);
  })["catch"](function(err) {
    return console.log(err);
  });

}).call(this);
