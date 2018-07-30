package util;

import haxe.macro.Expr;
import haxe.macro.Context;

class MacroUtils
{
	macro public static function compilationTime():Expr
	{
		var now_str = Date.now().toString();
		// an "ExprDef" is just a piece of a syntax tree. Something the compiler
		// creates itself while parsing an a .hx file
		return {expr: EConst(CString(now_str)) , pos : Context.currentPos()};
	}

	// Shorthand for retrieving compiler flag values.
	macro public static function getDefine(key : String) : haxe.macro.Expr
	{
		return macro $v{haxe.macro.Context.definedValue(key)};
	}

	macro public static function getNpmVersion(?path:String) :Expr
	{
		try {
			var p = haxe.macro.Context.resolvePath(path == null ? './package.json' : path);
			var version :String = haxe.Json.parse(sys.io.File.getContent(p)).version;
			// an "ExprDef" is just a piece of a syntax tree. Something the compiler
			// creates itself while parsing an a .hx file
			return {expr: EConst(CString(version)) , pos : Context.currentPos()};
		}
		catch(e:Dynamic) {
			return haxe.macro.Context.error('Failed to load file $path: $e', Context.currentPos());
		}
	}
}
