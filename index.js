exports.Remote = require('./js/easyRpc').Remote;
exports.expose = require('./js/easyRpc').expose;

exports.Server = require('./js/rpc');

exports.log = require('./js/log');

// for browser compatibility
exports.Promise = require('./js/promise');
exports.fetch = require('./js/fetch');
