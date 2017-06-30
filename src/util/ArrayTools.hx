package util;

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

	public static function mapFromField<A>(it :Iterator<A>, fieldName :String) :Map<String,A>
	{
		var a = new Map<String, A>();
		while(it.hasNext()) {
			var val = it.next();
			a.set(Reflect.field(val, fieldName), val);
		}
		return a;
	}
}