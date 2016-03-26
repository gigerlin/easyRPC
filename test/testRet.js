// Generated by CoffeeScript 1.10.0
(function() {
  var Remote, Test, expose, remote, url;

  Remote = require('avs-easyrpc').Remote;

  expose = require('avs-easyrpc').expose;

  url = 'http://localhost:4145';

  remote = new Remote({
    "class": 'sseRet',
    url: url
  });

  Test = (function() {
    function Test() {}

    Test.prototype.get = function(p) {
      return ++p;
    };

    return Test;

  })();

  expose(new Test(), remote, url);

}).call(this);
