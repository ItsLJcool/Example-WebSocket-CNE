//a
import haxe.io.Bytes;
import funkin.backend.system.net.WebSocketUtil;
import funkin.backend.system.net.WebSocketPacket;
import funkin.backend.MusicBeatState;

import funkin.backend.utils.WindowUtils;

import funkin.backend.system.Logs;

import haxe.io.Path;
import funkin.backend.scripting.Script;

import funkin.backend.utils.DiscordUtil;
import funkin.editors.ui.UIState;
static var redirectStates:Map<FlxState, String> = [
	MainMenuState => "room/ui.RoomList",
];

function preStateSwitch() {
	for (redirectState in redirectStates.keys()) {
		if (!(FlxG.game._requestedState is redirectState)) continue;
		var name = redirectStates.get(redirectState);
				
		var stateName = name.split("/").pop();
		var isUI = (StringTools.startsWith(stateName, "ui."));
		var state = (isUI) ? new UIState(true, name) : new ModState(name);
		FlxG.game._requestedState = state;
		break;
	}
}


static var onlineWebSocket:WebSocketUtil = null;
static function sendPacket(packet) {
	if (!connectedToServer) return false;
	onlineWebSocket.send(packet);
	return true;
}

var endpointScripts:Array<Script> = [];
static function get_endpointScript(name:String) {
	for (script in endpointScripts) {
		var scriptName = Path.withoutExtension(script.fileName);
		if (name != scriptName) continue;
		return script;
	}
	return false;
}

static function _resetEndpoints() {
	Logs.traceColored([
		Logs.logText("[Endpoints] ", 9),
		Logs.logText('Resetting Enpoints'),
	], 0);
	for (script in endpointScripts) script.destroy();
	endpointScripts = [];
	for (_path in Paths.getFolderContent("data/endpoints")) {
		var script = importScript("data/endpoints/"+_path);
		endpointScripts.push(script);
	}

	if (FlxG.state is MusicBeatState) FlxG.state.stateScripts.call("onResetEndPoints");
}

static var connectedToServer:Bool = false;

var reconnectTime:Float = 3;
var __time:Float = 0;
var maxReconnectAttempts:Int = 5;
var _attempts:Int = 0;
function new() {
	connectedToServer = false;
	_resetEndpoints();
	__connect();
	
	var prev_onClosing = WindowUtils.onClosing;
	WindowUtils.onClosing = () -> {
		onlineWebSocket.destroy();
		prev_onClosing();
	};

	FlxG.autoPause = false;
}

var tryingToConnect:Bool = false;
function __connect() {
	if (tryingToConnect || connectedToServer) return;
	_attempts++;
	if (_attempts > maxReconnectAttempts) {
		tryingToConnect = true;
		var timeLol = (_attempts == 1) ? "time" : "times";
		Logs.traceColored([
			Logs.logText("[WebSocket Attempts] ", 14),
			Logs.logText('Failed to connect ' + (_attempts-1) + " "+timeLol+". No Longer Attempting to Reconnect."),
		], 1);
		return;
	}
	attemptConnection();
}

// var url = "ws://anti-laundry.gl.at.ply.gg:9132";
var url = "ws://localhost:5000";

var __send_onClose:Bool = false;
var __send_onError = {error: null};
static function attemptConnection() {
	tryingToConnect = true;
	onlineWebSocket = new WebSocketUtil(url, (ws) -> {
		tryingToConnect = false;
		connectedToServer = true;
		_attempts = 0;
		if (DiscordUtil.ready) sendPacket(new WebSocketPacket("client.login", {method: "discord"}));
		endpoint("onConnect", [ws]);
	});
	onlineWebSocket._threadedConnection = true;

	onlineWebSocket.onError = (error) -> { __send_onError = {error: error}; };

	onlineWebSocket.onClose = () -> { __send_onClose = true; };

	onlineWebSocket.open();
}

function endpoint(call:String, ?params:Array) {
	params ??= [];
	for (script in endpointScripts) {
		if (script == null) continue;
		script.call(call, params);
	}
}

function destroy() {
	if (onlineWebSocket != null) onlineWebSocket.destroy();
	// onlineWebSocket = connectedToServer = attemptConnection = null;
}

function postUpdate(elapsed) {
	
	endpoint("postUpdate", [elapsed]);

	if (FlxG.keys.justPressed.F8) {
		tryingToConnect = connectedToServer = false;
		if (onlineWebSocket != null) onlineWebSocket.destroy();
		__connect();
	}

	if (onlineWebSocket != null) {
		if (onlineWebSocket.__packets.length > 0) popPackets();
		if (__send_onClose) {
			__send_onClose = false;
			tryingToConnect = false;
			connectedToServer = false;
			endpoint("onClose", []);
		}
		if (__send_onError?.error != null) {
			tryingToConnect = false;
			var error = __send_onError.error;
			if (error == "EOF") connectedToServer = false;
			__send_onError = {error: null};
			endpoint("onError", [error]);
		}
	}

	if (tryingToConnect || connectedToServer) return;
	if (__time < reconnectTime) {
		__time += elapsed;
		return;
	}
	__time = 0;
	__connect();
}

function popPackets() {
	var packet = onlineWebSocket.getRecentPacket();
	var eventName = (WebSocketPacket.isServerPacket(packet)) ? "onPacket" : "rawPacketData";

	endpoint(eventName, [packet]);
}