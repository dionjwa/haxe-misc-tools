package util;

import haxe.DynamicAccess;

class ArrayTools
{
	public static function containsDuplicates(a :Array<Dynamic>) :Bool
	{
		if (a == null || a.length <= 1) {
			return false;
		} else {
			var hasDuplicate = false;
			for (i in 0...(a.length - 1)) {
				for (j in (i + 1)...(a.length)) {
					if (a[i] == a[j]) {
						return true;
					}
				}
			}
			return false;
		}
	}

	public static function equalsDeep(a1 :Array<Dynamic>, a2 :Array<Dynamic>) :Bool
	{
		return if (a1 == null && a2 == null) {
			true;
		} else if ((a1 == null && a2 != null) || (a1 != null && a2 == null)) {
			false;
		} else if (a1.length != a2.length) {
			false;
		} else {
			var i = 0;
			//Assume equality
			var equal = true;
			while(i < a1.length) {
				if (a1[i] != a2[i]) {
					equal = false;
					break;
				}
				i++;
			}
			equal;
		}
	}

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

	public static function removeDuplicates<A:(String>)>(arr :Array<A>) :Array<A>
	{
		var a :DynamicAccess<A> = {};
		for (val in arr) {
			Reflect.setField(a, val, true);
		}
		return Reflect.fields(a);
	}
}