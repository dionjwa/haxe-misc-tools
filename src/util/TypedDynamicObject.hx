package util;

/**
	DynamicAccess is an abstract type for working with anonymous structures
	that are intended to hold collections of objects by the string key.

	For example, these types of structures are often created from JSON.

	Basically, it wraps `Reflect` calls in a `Map`-like interface.
**/
abstract TypedDynamicAccess<K:String,T>(Dynamic<T>) from Dynamic<T> to Dynamic<T> {

	/**
		Creates a new structure.
	**/
	public inline function new() this = {};

	/**
		Returns a value by specified `key`.

		If the structure does not contain the given key, null is returned.

		If `key` is null, the result is unspecified.
	**/
	@:arrayAccess
	public inline function get(key:K):Null<T> {
		#if js
		return untyped this[key]; // we know it's an object, so we don't need a check
		#else
		return Reflect.field(this, key);
		#end
	}

	/**
		Sets a `value` for a specified `key`.

		If the structure contains the given key, its value will be overwritten.

		Returns the given value.

		If `key` is null, the result is unspecified.
	**/
	@:arrayAccess
	public inline function set(key:K, value:T):T {
		#if js
		return untyped this[key] = value;
		#else
		Reflect.setField(this, key, value);
		return value;
		#end
	}

	/**
		Tells if the structure contains a specified `key`.

		If `key` is null, the result is unspecified.
	**/
	public inline function exists(key:K):Bool return Reflect.hasField(this, key);

	/**
		Removes a specified `key` from the structure.

		Returns true, if `key` was present in structure, or false otherwise.

		If `key` is null, the result is unspecified.
	**/
	public inline function remove(key:K):Bool return Reflect.deleteField(this, key);

	/**
		Returns an array of `keys` in a structure.
	**/
	public inline function keys():Array<K> return Reflect.fields(this);
}
