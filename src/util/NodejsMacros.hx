package util;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

class NodejsMacros
{
	/*
	 * If a var or property has the metadata tag '@NodeProcessVar' then
	 * the value is converted to a property (if not already) and the
	 * value is pulled from process.env and possibly converted to a
	 * basic type (Int,Float,Bool) or defaults to a String.
	 * The value of an Int is parsed from the value, 0 if null or parsing fails.
	 * The value of a Float is parsed from the value, 0.0 if null or parsing fails.
	 * The value of a Bool is parsed from the value, false if null, "0", or "false"
	 * (ignoring case), true otherwise.
	*/
	macro static public function addProcessEnvVars() :Array<Field>
	{
		var fields = Context.getBuildFields();
		var pos = haxe.macro.Context.currentPos();

		var newFields = [];
		for (field in fields) {
			if (field.meta != null && field.meta.exists(function(m) return m.name == 'NodeProcessVar')) {

				var fname = field.name;
				var theType;
				var defaultExpr;
				var fieldType = switch(field.kind) {
					case FVar(t, e):
						theType = t;
						defaultExpr = e;
						FieldType.FProp('get', 'null', t, e);
					case FFun(f):
						Context.error('${Context.getLocalModule()} ${fname}: cannot replace a function with a property', pos);
					case FProp(get, set, t, e):
						theType = t;
						defaultExpr = e;
						FieldType.FProp('get', 'null', t, e);
				}
				newFields.push({
					access: field.access,
					doc: field.doc,
					meta: field.meta,
					name: field.name,
					pos: field.pos,
					kind: fieldType
				});

				newFields.push({
					access: field.access,
					doc: null,
					meta: null,
					name: 'get_${fname}',
					pos: field.pos,
					kind: FieldType.FFun({
						args: [],
						ret: theType,
						expr: switch(theType) {
							case TPath(p):
								var fullPath = '${p.name}';
								if (p.pack != null && p.pack.length > 0) {
									fullPath = '${p.pack.join(".")}.${fullPath}';
								}

								var defaultVal :String = defaultExpr == null ? null : switch(defaultExpr.expr) {
									case EConst(c):
										switch(c) {
											case CInt(s),CFloat(s),CIdent(s):
												s;
											case CString(s):
												'"$s"';
											default:
												Context.error('${Context.getLocalModule()} ${field.name}: The build macro cannot handle regular expressions as default constant values for process.env defaults', pos);
										}
									default:
										Context.error('${Context.getLocalModule()} ${field.name}: Non-constant value as default, the macro cannot handle this case', pos);
								}

								switch(fullPath) {
									case 'Bool':
										if (defaultVal != null) {
											Context.parse('{ return js.Node.process.env.get("${fname}") == null ? $defaultVal : !(js.Node.process.env.get("${fname}") == "0" || js.Node.process.env.get("${fname}").toLowerCase() == "false");}', pos);
										} else {
											Context.parse('{ return !(js.Node.process.env.get("${fname}") == null || js.Node.process.env.get("${fname}") == "0" || js.Node.process.env.get("${fname}").toLowerCase() == "false");}', pos);
										}
									case 'Int':
										if (defaultVal != null) {
											Context.parse('{ return js.Node.process.env.get("${fname}") == null ? $defaultVal : try{Std.parseInt(js.Node.process.env.get("${fname}"));} catch(err :Dynamic) { 0; };}', pos);
										} else {
											Context.parse('{ return js.Node.process.env.get("${fname}") == null ? 0 : try{Std.parseInt(js.Node.process.env.get("${fname}"));} catch(err :Dynamic) { 0; };}', pos);
										}
									case 'Float':
										if (defaultVal != null) {
											Context.parse('{ return js.Node.process.env.get("${fname}") == null ? $defaultVal : try{Std.parseFloat(js.Node.process.env.get("${fname}"));} catch(err :Dynamic) { 0.0; };}', pos);
										} else {
											Context.parse('{ return js.Node.process.env.get("${fname}") == null ? 0.0 : try{Std.parseFloat(js.Node.process.env.get("${fname}"));} catch(err :Dynamic) { 0.0; };}', pos);
										}
									default:
										if (defaultVal != null) {
											Context.parse('{ return js.Node.process.env.get("${fname}") == null ? $defaultVal : js.Node.process.env.get("${fname}");}', pos);
										} else {
											Context.parse('{ return js.Node.process.env.get("${fname}");}', pos);
										}
								}
							default:
								Context.error('${Context.getLocalModule()} ${field.name}: return type must be a path type', pos);
						}
					})
				});
			} else {
				newFields.push(field);
			}
		}
		return newFields;
	}
}