package js.react.util;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;

import redux.Redux;

using StringTools;

enum DecodedWebsocketMessage {
	ActionMessage(action :Action);
	JsonMessage(obj :Dynamic);
	Unknown(unknown :Dynamic);
	DecodingWebsocketError(error :Dynamic, message :Dynamic);
}

class WebsocketTools
{
	static var HAXE_SERIALIZATION_PREFIX = 'hxx__';
	public static function encodeAction(action :Action) :String
	{
		var e :EnumValue = action.value;
		return encodeEnum(e);
	}

	public static function encodeEnum(e :EnumValue) :String
	{
		var serializer = new Serializer();
	    serializer.serialize(e);
	    return '${HAXE_SERIALIZATION_PREFIX}${serializer.toString()}';
	}

	public static function decodeMessage(message :Dynamic) :DecodedWebsocketMessage
	{
		var type :String = untyped __typeof__(message);
		switch type {
			case 'string':
				try {
					var s :String = message;
					if (s.startsWith(HAXE_SERIALIZATION_PREFIX)) {
						s = s.substr(HAXE_SERIALIZATION_PREFIX.length);
						var unserializer = new Unserializer(s);
						var e :EnumValue = unserializer.unserialize();
						return DecodedWebsocketMessage.ActionMessage(Action.map(e));
					} else {
						try {
							var jsonObj = Json.parse(s);
							return DecodedWebsocketMessage.JsonMessage(jsonObj);
						} catch(err :Dynamic) {
							return DecodedWebsocketMessage.Unknown(s);
						}
					}
				} catch(err :Dynamic) {
					trace('ERROR failed to parse websocket message=${message} err=${err}');
					return DecodedWebsocketMessage.DecodingWebsocketError(err, message);
				}
			case 'object':
				return DecodedWebsocketMessage.JsonMessage(message);
			default:
				return DecodedWebsocketMessage.Unknown(message);
		}
	}
}