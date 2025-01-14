//a
import flixel.util.FlxTimer;
import funkin.backend.system.net.WebSocketPacket;

import flixel.input.keyboard.FlxKey;
import flixel.uitl.FlxColor;

import funkin.editors.ui.UIState;

import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UITopMenu;
import funkin.editors.ui.UIUtil;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UISliceSprite;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISubstateWindow;

import flixel.group.FlxTypedSpriteGroup;

function getCurrentRoom() {
	var __room = roomEndpoint.get("current_room");
	if (__room == null || __room == {}) return false;
	return __room;
}
function getServerUser() {
	var __user = clientEndpoint.get("serverUser");
	if (__user == null || __user == {}) return false;
	return __user;
}
function isHost() {
	var room = getCurrentRoom();
	var user = getServerUser();
	if (room == false || user == false) return false;
	return room.host == user.clientId;
}


var roomEndpoint = get_endpointScript("Rooms");
var clientEndpoint = get_endpointScript("Client");
function onResetEndPoints() {
	roomEndpoint = get_endpointScript("Rooms");
	clientEndpoint = get_endpointScript("Client");
	roomEndpoint.call("set_onPacket", [onRoomPacket]);
}

function onRoomPacket(packet) {
	switch (packet.name) {
		case "room.create", "room.join":
			updateDebugText(getCurrentRoom());
		case "room.leave":
			var userLeaving = packet.data?.user;
			var user = getServerUser();
			if (userLeaving == null) return;
			if (userLeaving != user.clientId) return;
			roomEndpoint.set("inARoom", false);
			FlxG.switchState(new UIState(true, "room/RoomList"));
		case "room.timeout":
			roomEndpoint.set("inARoom", false);
			FlxG.switchState(new UIState(true, "room/RoomList"));
	}
}

var coolBG = importScript("data/util/CoolMenuBG");
var pingRoomTimer = new FlxTimer();
function create() {

	coolBG.call("createBG", [[0xB75E3FA7, 0xB73F83A7, 0xC61DB398]]);


	debugText = new UIText(0, 0, 0, "", 28, -1);
	debugText.alignment = "center";
	add(debugText);
	var _room = getCurrentRoom();
	updateDebugText(_room);

	if (isHost()) {
		var pingTime = _room?.pingHostTime ?? (_room?.pingTimeout*0.25 ?? 5);
		pingRoomTimer.start(pingTime , () -> {
			var _room = getCurrentRoom();
			var pingPacket = new WebSocketPacket("room.ping", {room: _room.name});
			sendPacket(pingPacket);
		}, 0);
	}
	onResetEndPoints();
}

function updateDebugText(roomData) {	
	trace("update debug text");
	var debugLol = "Name of Room: "+roomData.name+"\nUsers in Room: " +roomData.users.length+"\nHost UUID: "+roomData.host;
	debugText.text = debugLol;
	debugText.screenCenter();
}

function update(elapsed) {
	if (controls.BACK) {
		var _room = getCurrentRoom();
		sendPacket(new WebSocketPacket("room.leave", {name: _room.name}));
	}

	if (FlxG.keys.justPressed.P) {
		var _room = getCurrentRoom();
		var _data = {jumout: "flp"};
		var testPacket = new WebSocketPacket("room.send.users", {room: _room.name, data: _data, includeSelf: true});
		sendPacket(testPacket);
	}
}