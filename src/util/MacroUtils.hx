package util;

import haxe.macro.Expr;
import haxe.macro.Context;

using Lambda;
using StringTools;

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

	/**
	 * Compile time: parses .env and returns the value for the given key
	 */
	macro public static function getDotEnvValue(key :String, ?def :String, ?dotEnvPath :String = '.env') :Expr
	{
		try {
			if (!sys.FileSystem.exists(dotEnvPath)) {
				return {expr: EConst(CString(def)), pos : Context.currentPos()};
			}
			var line :String = sys.io.File.getContent(p)
				.split('\n')
				.find(function(line :String) return line.startsWith('${key}='));
			if (line != null) {
				line = line.trim().split('=')[1];
			} else {
				line = def;
			}
			// an "ExprDef" is just a piece of a syntax tree. Something the compiler
			// creates itself while parsing an a .hx file
			return {expr: EConst(CString(line)) , pos : Context.currentPos()};
		}
		catch(e:Dynamic) {
			return haxe.macro.Context.error('Failed to load file $dotEnvPath: $e', Context.currentPos());
		}
	}
}
