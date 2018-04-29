package js.react.websocket;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.rtti.Meta;

import js.html.WebSocket;
import js.html.MessageEvent;
import js.Browser;

import js.react.websocket.WebsocketTools;

import react.ReactUtil.*;
import redux.StoreMethods;

import redux.IReducer;
import redux.Redux;
import redux.StoreMethods;

/**
	Redux actions to dispatch from views and match in reducer/middleware
**/
enum WebsocketConnectionStatus
{
	Connecting;
	Connected;
	Disconnected;
}

typedef WebsocketState = {
	var status :WebsocketConnectionStatus;
	@:optional var lastSent :Action;
}

/**
 * Send only some actions to the server.
 */
typedef SendActionFilter=Action->Bool;

class WebsocketMiddleware<T:({ws:WebsocketState})>
	implements IReducer<WebsocketAction, WebsocketState>
{
	public var initState :WebsocketState = {
		status: WebsocketConnectionStatus.Connecting,
	};
	public var store :StoreMethods<T>;

	var _filter :SendActionFilter;

	var _ws :WebSocket;
	var _queuedMessages :Array<Action> = [];
	var _url :String;
	var _metadataFilterTag :String;

	public function new() {}

	public function setUrl(url :String)
	{
		_url = url;
		return this;
	}

	/**
	 * If passed, only send to the server messages
	 * that return true when passed.
	 * @param filter :SendActionFilter [description]
	 */
	public function setSendFilter(filter :SendActionFilter)
	{
		_filter = filter;
		return this;
	}

	/**
	 * If not null, any enum with this metadata, or one of
	 * the constructors, will be send down the ws wire.
	 * For example
	 * @server //All enums are sent
	 * enum Foo {
	 * 	    @server //If the Type meta is not present, then only constructors with this value are sent.
	 * 		Bar;
	 * }
	 */
	public function setMetaTagFilter(tag :String)
	{
		_metadataFilterTag = tag;
		return this;
	}

	function onWebsocketMessage(event :MessageEvent)
	{
		var message = event.data;
		switch(WebsocketTools.decodeMessage(message)) {
			case JsonMessage(obj):
				trace('Unhandled websocket JSON message=${Json.stringify(obj)}');
			case Unknown(unknown):
				trace('Error unknown websocket message=$message');
			case DecodingWebsocketError(error, message):
				trace('Error decoding websocket message=$message error=$error');
			case ActionMessage(action):
				store.dispatch(action);
			default:
				trace('Unhandled websocket message: ${message}');
		}
	}

	/* SERVICE */

	public function reduce(state :WebsocketState, action :WebsocketAction) :WebsocketState
	{
		return switch(action)
		{
			case Connect:
				copy(state, {status: WebsocketConnectionStatus.Connecting});
			case Connected:
				copy(state, {status: WebsocketConnectionStatus.Connected});
			case Disconnect:
				copy(state, {status: WebsocketConnectionStatus.Disconnected});
			case Reconnect:
				copy(state, {status: WebsocketConnectionStatus.Connecting});
			case ServerError(error, action):
				state;
		}
	}

	/* MIDDLEWARE */

	public function createMiddleware()
	{
		return function (store:StoreMethods<T>) {

			this.store = store;
			return function (next:Dispatch):Dynamic {
				return function (action:Action):Dynamic {
					if (action == null) {
						throw 'action == null';
					}
					if (action.type == null) {
						throw 'action.type == null, action=${action}';
					}

					if (action.type == Type.getEnumName(WebsocketAction)) {
						var en :WebsocketAction = cast action.value;
						switch(en) {
							case Connect,Reconnect:
								connect();
							case Disconnect:
								disconnect();
							case Connected:
							case ServerError(error, action):
								trace('Error returned from server error=${error} action=${action}');
						}
					}

					if (applyFilter(action) && applyMetaFilter(action)) {
						sendAction(action);
					}
					return next(action);
				}
			}
		}
	}

	function applyMetaFilter(action :Action) :Bool
	{
		if (_metadataFilterTag == null) {
			return true;
		}
		var enumType = Type.resolveEnum(action.type);
		//No enum, cannot filter
		if (enumType == null) {
			return true;
		}

		var mt = Meta.getType(enumType);
		if (mt != null && Reflect.hasField(mt, _metadataFilterTag)) {
			return true;
		}

		var enMeta = Meta.getFields(enumType);
		var name = Type.enumConstructor(action.value);
		if (enMeta != null
			&& Reflect.hasField(enMeta, name)
			&& Reflect.hasField(Reflect.field(enMeta, name), _metadataFilterTag)) {
			return true;
		}

		return false;
	}

	function applyFilter(action :Action) :Bool
	{
		return _filter == null || _filter(action);
	}

	function sendAction(action :Action)
	{
		if (_ws != null && _ws.readyState == WebSocket.OPEN) {
			_ws.send(WebsocketTools.encodeAction(action));
		} else {
			_queuedMessages.push(action);
		}
	}

	function connect()
	{
		disconnect();
		_ws = new WebSocket(_url);
		//React hot-loading can mess with this, so we cache
		//the websocket to the window object
		Reflect.setField(Browser.window, 'WS_INSTANCE', _ws);
		_ws.onerror = onWebsocketError;
		_ws.onopen = onWebsocketOpen;
		_ws.onclose = onWebsocketClose;
		_ws.onmessage = onWebsocketMessage;
	}

	function disconnect()
	{
		var closeAndCleanup = function() {
			if (_ws != null) {
				_ws.onopen = null;
				_ws.onerror = null;
				_ws.onclose = null;
				_ws.onmessage = null;
				_ws.close();
				_ws = null;
			}
		};
		closeAndCleanup();
		//Check static bound websocket, to reduce craziness when hot-loading
		_ws = Reflect.field(Browser.window, 'WS_INSTANCE');
		Reflect.deleteField(Browser.window, 'WS_INSTANCE');
		closeAndCleanup();
	}

	function onWebsocketError(err :Dynamic)
	{
		trace('websocket error ${Json.stringify(err)}');
	}

	function onWebsocketOpen()
	{
		store.dispatch(WebsocketAction.Connected);
		while (_queuedMessages.length > 0) {
			_ws.send(WebsocketTools.encodeAction(_queuedMessages.shift()));
		}
	}

	function onWebsocketClose(reason :js.html.CloseEvent)
	{
		if (store.getState().ws != null) {

		}
		switch (store.getState().ws.status) {
			case Connecting,Connected:
				//Websocket got disconnected prematurely, reconnect
				Browser.window.setTimeout(function() {
					store.dispatch(WebsocketAction.Reconnect);
				}, 5000);
			case Disconnected://Good
		}
	}
}
