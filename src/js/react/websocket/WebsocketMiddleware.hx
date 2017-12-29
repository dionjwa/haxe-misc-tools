package js.react.websocket;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;

import js.html.WebSocket;
import js.html.MessageEvent;
import js.Browser;

import js.react.util.WebsocketTools;

import react.ReactUtil.*;
import redux.StoreMethods;

import redux.IReducer;
import redux.Redux;
import redux.StoreMethods;

enum WebsocketAction
{
	Connect;
	Connected;
	Disconnect;
	Reconnect;
	ServerError(error :Dynamic, e :EnumValue);
}

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
 * Send some actions to the server.
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

	public function new() {}

	public function setUrl(url :String)
	{
		_url = url;
		return this;
	}

	public function setSendFilter(filter :SendActionFilter)
	{
		_filter = filter;
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

					if (_filter == null || _filter(action)) {
						sendAction(action);
					}
					return next(action);
				}
			}
		}
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
		var port = Browser.location.port != null ? ":" + Browser.location.port : "";
#if WEBSOCKET_MIDDLEWARE_PORT
		//Force the debug websocket to avoid clobbering the livereloadx websocket
		port = util.MacroUtils.getDefine('WEBSOCKET_MIDDLEWARE_PORT');
		port = ':${port}';
#end
		var protocol = Browser.location.protocol == "https:" ? "wss:" : "ws:";
		var wsUrl = '${protocol}//${Browser.location.hostname}${port}${_url}';
		_ws = new WebSocket(wsUrl);
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
