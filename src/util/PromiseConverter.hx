package util;

/**
 * Working with promhx.Promise and core Promises in the same Haxe
 * codebase.
 *
 * Reason? promhx.Promises are better since they're typed, but
 * there are some super-useful npm modules using core promises
 * and you need to convert.
 */
class PromiseConverter
{
	public static function promhx<T>(p :js.Promise<T>) :promhx.Promise<T>
	{
		var promise = new promhx.deferred.DeferredPromise();
		p.then(function(t :T) {
			promise.resolve(t);
		})
		.catchError(function(err) {
			promise.boundPromise.reject(err);
		});
		return promise.boundPromise;
	}
}