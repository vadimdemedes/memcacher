var Memcacher, async, memcached;

memcached = require('memcached');

async = require('async');

Memcacher = (function() {

  function Memcacher(servers) {
    if (servers == null) servers = [];
    this.client = new memcached(servers);
  }

  Memcacher.prototype.set = function(key, value, expireIn, tags, callback) {
    var tag, _i, _len;
    if (tags == null) tags = [];
    for (_i = 0, _len = tags.length; _i < _len; _i++) {
      tag = tags[_i];
      this.bindTagToKey(tag, key);
    }
    this.client.set(key, value, expireIn, function() {
      return process.nextTick(function() {
        if (callback) return callback(false);
      });
    });
    return this;
  };

  Memcacher.prototype.get = function(key, callback) {
    this.client.get(key, function(err, value) {
      return process.nextTick(function() {
        if (callback) return callback(err, value);
      });
    });
    return this;
  };

  Memcacher.prototype.delByTag = function(tag, callback) {
    var that;
    that = this;
    that.client.get("" + tag + "-keys", function(err, value) {
      var keys;
      if (!value) return callback(false);
      that.client.del("" + tag + "-keys", function() {});
      keys = JSON.parse(value);
      return async.forEach(keys, function(key, nextKey) {
        return that.client.del(key, function() {
          return nextKey();
        });
      }, function() {
        return process.nextTick(function() {
          if (callback) return callback(false);
        });
      });
    });
    return this;
  };

  Memcacher.prototype.del = function(key, callback) {
    var that;
    that = this;
    this.client.get("" + key + "-tags", function(err, value) {
      var tags;
      if (!value) return;
      tags = JSON.parse(value);
      return async.forEach(tags, function(tag, nextTag) {
        return that.delByTag(tag, nextTag);
      }, function() {
        that.client.del("" + key + "-tags", function() {});
        return that.client.del(key, function() {
          return process.nextTick(function() {
            if (callback) return callback(false);
          });
        });
      });
    });
    return this;
  };

  Memcacher.prototype.bindTagToKey = function(tag, key, callback) {
    var bindKeys, bindTags, that;
    that = this;
    bindKeys = function(done) {
      return that.client.get("" + tag + "-keys", function(err, value) {
        var keys;
        if (!value) {
          return that.client.set("" + tag + "-keys", JSON.stringify([key]), 2592000, function() {
            return process.nextTick(function() {
              return done();
            });
          });
        } else {
          keys = JSON.parse(value);
          keys.push(key);
          return that.client.set("" + tag + "-keys", JSON.stringify(keys), 2592000, function() {
            return process.nextTick(function() {
              return done();
            });
          });
        }
      });
    };
    bindTags = function(done) {
      return that.client.get("" + key + "-tags", function(err, value) {
        var tags;
        if (!value) {
          return that.client.set("" + key + "-tags", JSON.stringify([tag]), 2592000, function() {
            return process.nextTick(function() {
              return done();
            });
          });
        } else {
          tags = JSON.parse(value);
          tags.push(tag);
          return that.client.set("" + key + "-tags", JSON.stringify(tags), 2592000, function() {
            return process.nextTick(function() {
              return done();
            });
          });
        }
      });
    };
    return async.parallel([bindKeys, bindTags], function() {
      return process.nextTick(function() {
        if (callback) return callback(false);
      });
    });
  };

  Memcacher.prototype.close = function() {
    return this.client.end();
  };

  return Memcacher;

})();

module.exports = Memcacher;
