package promhx;

import haxe.Json;

import js.node.Buffer;

import promhx.Deferred;
import promhx.Promise;

enum RetryType {
	regular;
	decaying;
}

class RetryPromise
{
	public static function retry<T>(f :Void->Promise<T>, type :RetryType, maxRetryAttempts :Int = 5, ?intervalMilliseconds :Int = 0, ?logPrefix :String = '', ?supressLogs :Bool= false) :Promise<T>
	{
		return switch(type) {
			case regular: retryRegular(f, maxRetryAttempts, intervalMilliseconds, logPrefix, supressLogs);
			case decaying: retryDecayingInterval(f, maxRetryAttempts, intervalMilliseconds, logPrefix, supressLogs);
		}
	}

	public static function retryRegular<T>(f :Void->Promise<T>, maxRetryAttempts :Int = 5, ?intervalMilliseconds :Int = 0, ?logPrefix :String = '', ?supressLogs :Bool= false) :Promise<T>
	{
		var deferred = new promhx.deferred.DeferredPromise();
		var attempts = 0;
		var retryLocal = null;
		retryLocal = function() {
			attempts++;
			var p = f();
			if (p == null) {
				throw 'RetryPromise.pollRegular f() returned a null promise';
			}
			p.then(function(val) {
				if (attempts > 1 && !supressLogs) {
					Log.debug('$logPrefix Success after $attempts');
				}
				deferred.resolve(val);
			});
			p.catchError(function(err) {
				if (attempts < maxRetryAttempts) {
					if (!supressLogs) {
						Log.debug('$logPrefix Failed attempt $attempts err=${errToString(err)}');
					}
					js.Node.setTimeout(retryLocal, intervalMilliseconds);
				} else {
					if (!supressLogs) {
						Log.error('$logPrefix Failed all $maxRetryAttempts err=${errToString(err)}');
					}
					deferred.boundPromise.reject(err);
				}
			});
		}
		retryLocal();
		return deferred.boundPromise;
	}

	public static function retryDecayingInterval<T>(f :Void->Promise<T>, maxRetryAttempts :Int = 5, ?doublingRetryIntervalMilliseconds :Int = 0, logPrefix :String, ?supressLogs :Bool= false) :Promise<T>
	{
		var deferred = new promhx.deferred.DeferredPromise();

		var attempts = 0;
		var currentDelay = doublingRetryIntervalMilliseconds;
		var retryLocal = null;
		retryLocal = function() {
			attempts++;
			var p = f();
			p.then(function(val) {
				if (attempts > 1 && !supressLogs) {
					Log.debug('$logPrefix Success after $attempts');
				}
				deferred.resolve(val);
			});
			p.catchError(function(err) {
				if (attempts < maxRetryAttempts) {
					if (!supressLogs) {
						Log.debug('$logPrefix Failed attempt $attempts err=${errToString(err)}');
					}
					js.Node.setTimeout(retryLocal, currentDelay);
					currentDelay *= 2;
				} else {
					if (!supressLogs) {
						Log.error('$logPrefix Failed all $maxRetryAttempts err=${errToString(err)}');
					}
					deferred.boundPromise.reject(err);
				}
			});
		}
		retryLocal();
		return deferred.boundPromise;
	}

	inline static function errToString(err :Dynamic) :String
	{
		if (err == null) {
			return "null";
		}
		return if (Buffer.isBuffer(err)) {
			cast(err, js.node.Buffer).toString();
		} else {
			Json.stringify(err);
		}
	}
}