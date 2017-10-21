package js.react.websocket;

enum WebsocketAction
{
	Connect;
	Connected;
	Disconnect;
	Reconnect;
	ServerError(error :Dynamic, e :EnumValue);
}