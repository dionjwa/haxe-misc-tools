package util;

import haxe.DynamicAccess;

class ArrayTools
{
	public static function array<A>(it :Iterator<A>) :Array<A>
	{
		var a = new Array<A>();
		while(it.hasNext()) {
			a.push(it.next());
		}
		return a;
	}

	public static function mapFromField<A>(arr :Array<A>, fieldName :String) :Map<String,A>
	{
		var a = new Map<String, A>();
		for (val in arr) {
			a.set(Reflect.field(val, fieldName), val);
		}
		return a;
	}

	public static function toDynamicAccess<A>(arr :Array<A>, f :A->String) :DynamicAccess<A>
	{
		var a :DynamicAccess<A> = {};
		for (val in arr) {
			a.set(f(val), val);
		}
		return a;
	}
}