// Generated by CoffeeScript 1.10.0
(function() {
  var Remote, Test, expose, remote, url,
    slice = [].slice;

  Remote = require('avs-easyrpc').Remote;

  expose = require('avs-easyrpc').expose;

  url = 'http://localhost:4145';

  remote = new Remote({
    "class": 'Employee',
    methods: ['getProfile', 'speak'],
    url: url
  });

  Test = (function() {
    function Test() {}

    Test.prototype.echo = function() {
      var text, user;
      user = arguments[0], text = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      return console.log.apply(console, [user + ":"].concat(slice.call(text)));
    };

    return Test;

  })();

  remote = new Remote({
    "class": 'doesnotexist',
    methods: ['test'],
    url: url
  });

  remote.test().then(function(rep) {
    return console.log('then', rep);
  })["catch"](function(err) {
    return console.log('cath', err);
  });

}).call(this);
