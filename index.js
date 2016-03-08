exports.Remote = require('./js/easyRpc');
exports.Server = require('./js/rpc');

exports.expose = require('./js/sse').expose;
exports.sseRemote = require('./js/sse').Remote;

exports.log = require('./js/log');

// for browser compatibility
exports.Promise = require('./js/promise');
exports.fetch = require('./js/fetch');
