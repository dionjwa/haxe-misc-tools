package promhx;

import haxe.Json;

import promhx.Deferred;
import promhx.Promise;
import promhx.CallbackPromise;

using promhx.PromiseTools;

class RedisPromises
{
	inline public static function info(redis :Dynamic) :Promise<Dynamic>
	{
		var promise = new promhx.CallbackPromise();
		redis.info(promise.cb2);
		return cast promise;
	}

	inline public static function keys(redis :Dynamic, keyString :String) :Promise<Array<String>>
	{
		var promise = new promhx.CallbackPromise();
		redis.keys(keyString, promise.cb2);
		return cast promise;
	}

	inline public static function set(redis :Dynamic, key :String, val :String) :Promise<Bool>
	{
		var promise = new promhx.CallbackPromise();
		redis.set(key, val, promise.cb2);
		return promise.thenTrue();
	}

	inline public static function setex(redis :Dynamic, key :String, time :Int, val :String) :Promise<String>
	{
		var promise = new promhx.CallbackPromise();
		redis.setex(key, time, val, promise.cb2);
		return promise.then(function(s) return s.asString());
	}

	inline public static function get(redis :Dynamic, key :String) :Promise<String>
	{
		var promise = new promhx.CallbackPromise();
		redis.get(key, promise.cb2);
		return promise.then(function(s) return s.asString());
	}

	inline public static function hget(redis :Dynamic, hashkey :String, hashField :String) :Promise<String>
	{
		var promise = new promhx.CallbackPromise();
		redis.hget(hashkey, hashField, promise.cb2);
		return promise.then(function(s) return s.asString());
	}

	inline public static function hgetall(redis :Dynamic, hashkey :String) :Promise<Dynamic>
	{
		var promise = new promhx.CallbackPromise();
		redis.hgetall(hashkey, promise.cb2);
		return promise;
	}

	inline public static function hkeys(redis :Dynamic, hashkey :String) :Promise<Array<Dynamic>>
	{
		var promise = new promhx.CallbackPromise();
		redis.hkeys(hashkey, promise.cb2);
		return promise;
	}

	inline public static function hset(redis :Dynamic, hashkey :String, hashField :String, val :String) :Promise<Int>
	{
		var promise = new promhx.CallbackPromise<Int>();
		redis.hset(hashkey, hashField, val, promise.cb2);
		return promise;
	}

	inline public static function hexists(redis :Dynamic, hashkey :String, hashField :String) :Promise<Bool>
	{
		var promise = new promhx.CallbackPromise<Int>();
		redis.hexists(hashkey, hashField, promise.cb2);
		return promise
			.then(function(out :haxe.extern.EitherType<Int, Bool>) {
				return out == 1 || out == true;
			});
	}

	inline public static function hdel(redis :Dynamic, hashkey :String, hashField :String) :Promise<Int>
	{
		var promise = new promhx.CallbackPromise<Int>();
		redis.hdel(hashkey, hashField, promise.cb2);
		return promise;
	}

	public static function getHashInt(redis :Dynamic, hashId :String, hashKey :String) :Promise<Int>
	{
		return hget(redis, hashId, hashKey)
			.then(function(val) {
				return Std.parseInt(val + '');
			});
	}

	public static function setHashInt(redis :Dynamic, hashId :String, hashKey :String, val :Int) :Promise<Int>
	{
		return hset(redis, hashId, hashKey, Std.string(val));
	}

	public static function getHashJson<T>(redis :Dynamic, hashId :String, hashKey :String) :Promise<T>
	{
		return hget(redis, hashId, hashKey)
			.then(function(val) {
				return Json.parse(val);
			});
	}

	public static function sadd(redis :Dynamic, set :String, members :Array<String>) :Promise<Int>
	{
		if (members == null || members.length == 0) {
			return Promise.promise(0);
		}
		members = members.concat([]);
		members.insert(0, set);
		var promise = new promhx.CallbackPromise();
		redis.sadd(members, promise.cb2);
		return promise;
	}

	public static function spop(redis :Dynamic, key :String) :Promise<Dynamic>
	{
		var promise = new promhx.CallbackPromise();
		redis.spop(key, promise.cb2);
		return promise;
	}

	public static function sismember(redis :Dynamic, key :String, member :String) :Promise<Bool>
	{
		var promise = new promhx.CallbackPromise();
		redis.sismember(key, member, promise.cb2);
		return promise
			.then(function(exists :Int) {
				return exists == 1;
			});
	}

	public static function srem(redis :Dynamic, key :String, member :String) :Promise<Dynamic>
	{
		var promise = new promhx.CallbackPromise();
		redis.srem(key, member, promise.cb2);
		return promise;
	}

	public static function srandmember(redis :Dynamic, key :String) :Promise<Dynamic>
	{
		var promise = new promhx.CallbackPromise();
		redis.srandmember(key, promise.cb2);
		return promise;
	}

	public static function smembers(redis :Dynamic, key :String) :Promise<Array<Dynamic>>
	{
		var promise = new promhx.CallbackPromise();
		redis.smembers(key, promise.cb2);
		return promise
			.then(function(arr) {
				if (isArrayObjectEmpty(arr)) {
					arr = [];
				}
				return arr;
			});
	}

	public static function sinter(redis :Dynamic, keys :Array<String>) :Promise<Array<Dynamic>>
	{
		var promise = new promhx.CallbackPromise();
		redis.sinter(keys, promise.cb2);
		return promise
			.then(function(arr) {
				if (isArrayObjectEmpty(arr)) {
					arr = [];
				}
				return arr;
			});
	}

	public static function zismember(redis :Dynamic, key :String, member :String) :Promise<Bool>
	{
		var promise = new promhx.CallbackPromise();
		redis.zscore(key, member, promise.cb2);
		return promise
			.then(function(score) {
				return score != null;
			});
	}

	public static function zadd(redis :Dynamic, key :String, score :Int, value :String) :Promise<Int>
	{
		var promise = new promhx.CallbackPromise();
		redis.zadd(key, score, value, promise.cb2);
		return promise;
	}

	public static function zrange(redis :Dynamic, key :String, from :Int, to :Int) :Promise<Array<Dynamic>>
	{
		var promise = new promhx.CallbackPromise();
		redis.zrange(key, from, to, promise.cb2);
		return promise;
	}

	public static function zrangebyscore(redis :Dynamic, key :String, from :Float, to :Float) :Promise<Array<Dynamic>>
	{
		var promise = new promhx.CallbackPromise();
		redis.zrangebyscore(key, from, to, promise.cb2);
		return promise;
	}

	public static function zscore(redis :Dynamic, key :String, value :String) :Promise<Float>
	{
		var promise = new promhx.CallbackPromise();
		redis.zscore(key, value, promise.cb2);

		return promise
			.then(function(scoreString) {
				if (scoreString == null || scoreString == "") {
					return null;
				} else {
					return Std.parseFloat(scoreString);
				}
			});
	}

	public static function lpush(redis :Dynamic, key :String, value :String) :Promise<Int>
	{
		var promise = new promhx.CallbackPromise();
		redis.lpush(key, value, promise.cb2);
		return promise;
	}

	public static function lrange(redis :Dynamic, key :String, start :Int, end :Int) :Promise<Array<Dynamic>>
	{
		var promise = new promhx.CallbackPromise();
		redis.lrange(key, start, end, promise.cb2);
		return promise;
	}

	public static function del(redis :Dynamic, key :String) :Promise<Int>
	{
		var promise = new promhx.CallbackPromise();
		redis.del(key, promise.cb2);
		return promise;
	}

	public static function hmset(redis :Dynamic, key :String, fieldVals :Dynamic<String>) :Promise<String>
	{
		var promise = new promhx.CallbackPromise();
		var keyS :String = key;
		var fieldValsS :Dynamic<String> = cast fieldVals;
		var cb :Null<js.Error>->Void = cast promise.cb2;
		redis.hmset(cast keyS, cast fieldValsS, cb);
		return promise.then(function(s) return s.asString());
	}

	public static function deleteAllKeys(redis :Dynamic) :Promise<Bool>
	{
		var promise = new promhx.deferred.DeferredPromise();
		redis.keys('*', function(err, keys :Array<String>) {
			var commands :Array<Array<String>> = [];
			for (key in keys) {
				commands.push(['del', key]);
			}
			redis.multi(commands).exec(function(err, result) {
				if (err != null) {
					promise.boundPromise.reject(err);
					return;
				}
				promise.resolve(true);
			});
		});
		return promise.boundPromise;
	}

	/**
	 * Empty arrays can be returned as objects, which have no length.
	 * It's annoying.
	 * @param  obj :Dynamic      [description]
	 * @return     [description]
	 */
	static function isArrayObjectEmpty(obj :Dynamic) :Bool
	{
		if (obj == null) {
			return true;
		} else {
			return Std.is(obj, Array) ? obj.length == 0 : true;
		}
	}
}
