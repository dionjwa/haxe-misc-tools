package util;

import haxe.Json;
import haxe.DynamicAccess;

class ObjectTools
{
	public static function assign(target:Dynamic, sources:Array<Dynamic>):Dynamic
	{
		for (source in sources)
			if (source != null)
				for (field in Reflect.fields(source))
					Reflect.setField(target, field, Reflect.field(source, field));
		return target;
	}

	public static function copy(source1:Dynamic, ?source2:Dynamic):Dynamic
	{
		var target = {};
		for (field in Reflect.fields(source1))
			Reflect.setField(target, field, Reflect.field(source1, field));
		if (source2 != null)
			for (field in Reflect.fields(source2))
				Reflect.setField(target, field, Reflect.field(source2, field));
		return target;
	}

	public static function shallowCompare(a:Dynamic, b:Dynamic):Bool
	{
		var aFields = Reflect.fields(a);
		var bFields = Reflect.fields(b);
		if (aFields.length != bFields.length)
			return false;
		for (field in aFields)
			if (!Reflect.hasField(b, field) || Reflect.field(b, field) != Reflect.field(a, field))
				return false;
		return true;
	}

	/**
	 * obj1 fields will be overridden by obj2 fields.
	 */
	public static function mergeDeepCopy<T>(obj1 :Dynamic, obj2 :Dynamic) :T
	{
		obj1 = Json.parse(Json.stringify(obj1));
		if (obj2 == null) {
			return obj1;
		}
		obj2 = Json.parse(Json.stringify(obj2));
		merge(cast obj1, cast obj2);
		return obj1;
	}

	public static function merge(obj1 :DynamicAccess<Dynamic>, obj2 :DynamicAccess<Dynamic>)
	{
		var fields = obj2.keys();
		for (fieldName in fields) {
			var field = obj2[fieldName];
			if (!obj1.exists(fieldName)) {
				obj1[fieldName] = field;
			} else {
				var originalField = obj1[fieldName];
				switch(Type.typeof(originalField)) {
					case TObject: merge(originalField, field);
					case TClass(c): merge(originalField, field);
					default: obj1[fieldName] = field;
				}
			}
		}
	}

	public static function removeNulls<T>(obj :T) :T
	{
		if (obj != null) {
			for (field in Reflect.fields(obj)) {
				if (Reflect.field(obj, field) == null) {
					Reflect.deleteField(obj, field);
				}
			}
		}
		return obj;
	}
}