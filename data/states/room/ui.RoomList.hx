//a
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

import funkin.menus.ModSwitchMenu;
import funkin.editors.EditorPicker;

import flixel.group.FlxTypedSpriteGroup;

import funkin.backend.system.framerate.Framerate;

var coolBG = importScript("data/util/CoolMenuBG");

var roomEndpoint = get_endpointScript("Rooms");
var clientEndpoint = get_endpointScript("Client");
function onResetEndPoints() {
	roomEndpoint = get_endpointScript("Rooms");
	clientEndpoint = get_endpointScript("Client");

	roomEndpoint.call("set_onPacket", [onRoomPacket]);
	clientEndpoint.call("set_onPacket", [onClientPacket]);
	clientEndpoint.call("set_onClose", [onClientClose]);
}
var topMenu:UITopMenu;
function new() {
	if (Framerate.isLoaded) Framerate.fpsCounter.alpha = Framerate.memoryCounter.alpha =  Framerate.codenameBuildField.alpha = 0.4;

	coolBG.call("createBG");

    topMenu = new UITopMenu(topOptions);
    add(topMenu);

	connectedServerStatusText = new UIText(0, 0, 0, "Not Connected", 24, -1);
	connectedServerStatusText.alignment = "left";
	connectedServerStatusText.setPosition(5, topMenu.y + topMenu.bHeight + 5);
	add(connectedServerStatusText);
}

var creatingRoom:Bool = false;

var roomList:UIWindow;
var roomCamera:FlxCamera;

var gatherRoomsTimer:FlxTimer = new FlxTimer();
function create() {

	var _width = 300;
	var _height = FlxG.height * 0.7;
	roomList = new UIWindow(FlxG.width - _width - 15, FlxG.height * 0.5 - _height * 0.5, _width, _height, "Room List");
	add(roomList);

	roomCamera = new FlxCamera(Std.int(roomList.x), Std.int(roomList.y + 30), _width, _height - 30 - 1);
	FlxG.cameras.add(roomCamera, false);
	roomCamera.bgColor = 0;

	var _buttonWidth = roomList.bWidth * 0.41;
	createRoomButton = new UIButton(0, 0, "Create", () -> {
		creatingRoom = true;
		openSubState(new UISubstateWindow(true, "substates/RoomCreation"));
	}, _buttonWidth, 32);
	createRoomButton.x = roomList.x + roomList.bWidth * 0.5 - _buttonWidth * 0.5;
	createRoomButton.y = roomList.y + roomList.bHeight + 5;
	add(createRoomButton);

	sendPacket(new WebSocketPacket("room.getRooms"));
	gatherRoomsTimer.start(4, () -> {
		if (attemptJoinRoom || creatingRoom) return;
		sendPacket(new WebSocketPacket("room.getRooms"));
	}, 0);

	onResetEndPoints();
}

function update(elapsed) {

	if (FlxG.keys.justPressed.SEVEN) {
		persistentUpdate = false;
		persistentDraw = true;
		openSubState(new EditorPicker());
	}

	if (controls.SWITCHMOD) {
		persistentUpdate = false;
		persistentDraw = true;
		openSubState(new ModSwitchMenu());
	}

	updateRoomList(elapsed);
	
	if (FlxG.keys.justPressed.ANY) UIUtil.processShortcuts(topOptions);

	if (FlxG.keys.justPressed.P) _resetEndpoints();
}

function updateRoomList(elapsed) {
	var list = roomList.members.copy();
	list.shift();

	var _spacing = 10;
	for (i=>group in list) {
		if (!(group is FlxTypedSpriteGroup)) continue;
		var groupWidth = group.members[0]?.bWidth ?? group.width;
		var _math = (roomList.bWidth - groupWidth) * 0.5;
		group.setPosition(_math, CoolUtil.fpsLerp(group.y, ((150 + _spacing) * i) + 10, 0.25));
	}
	
	var last = list[list.length-1];
	if (last == null) return;
	var __height = last.members[0].bHeight;
	roomCamera.scroll.y = FlxMath.bound(roomCamera.scroll.y - (FlxG.mouse.wheel) * 35, -_spacing, Math.max((last.y + __height) - roomCamera.height + _spacing, -_spacing));
}

function onRoomPacket(packet) {
	var connectedText = (connectedToServer) ? "Connected to Server" : "Not Connected";
	connectedServerStatusText.text = connectedText;
	if (packet.data == null) return;
	var data = packet.data;
	switch(packet.name) {
		case "room.getRooms":
			if (data.rooms.length == 0) {
				for (room in __roomsData) removeRoom(room.name);
			}
			for (_data in data.rooms) addRoom(_data.name, _data.users);
		case "room.create", "room.join":
			addRoom(data.room.name, data.room.users);
			if (roomEndpoint.get("inARoom") ?? false) FlxG.switchState(new UIState(true, "room/ConnectedRoom"));
		case "room.timeout":
			removeRoom(data.room.name);
	}
}
function onClientPacket(packet) {
	onClientClose();
}
function onClientClose() {
	trace("connectedToServer: " + connectedToServer);
	var connectedText = (connectedToServer) ? "Connected to Server" : "Not Connected";
	connectedServerStatusText.text = connectedText;
}

// Room UI
var __roomsData = [];
function addRoom(?name:String, ?users:Array) {
	name ??= "Room #"+roomList.members.length;
	users ??= [];

	var _index:Int = -1;
	for (i=>room in __roomsData) {
		if (room.name != name) continue;
		if (room.users.length == users.length) return;
		_index = i;
		break;
	}
	if (_index != -1) {
		_index++;
		roomList.members[_index].destroy();
		remove(roomList.members[_index], true);
		roomList.members.remove(roomList.members[_index]);
	}

	var roomGroup = new FlxTypedSpriteGroup();
	roomGroup.cameras = [roomCamera];
	var roomBG:UISliceSprite = new UISliceSprite(0, 0, roomList.bWidth - 50, 150, "editors/ui/context-bg");
	roomGroup.add(roomBG);

	var roomName = new UIText(0, 2.5, roomBG.bWidth - 5, name, 15, -1);
	roomName.alignment = "center";
	roomGroup.add(roomName);
	
	var usersText = new UIText(2.5, (roomName.y + roomName.height) + 5, roomBG.bWidth * 0.35, "Users: "+users.length, 15, -1);
	usersText.alignment = "left";
	roomGroup.add(usersText);

	var _buttonWidth = roomBG.bWidth * 0.41;
	var joinButton = new UIButton(0, 0, "Join", () -> { joinRoom(name); }, _buttonWidth, 32);
	joinButton.x = roomBG.bWidth * 0.5 - _buttonWidth * 0.5;
	joinButton.y = roomBG.bHeight - joinButton.bHeight - 5;
	joinButton.ID = -1;
	if (attemptJoinRoom) joinButton.selectable = false;
	roomGroup.add(joinButton);

	var _math = (roomList.bWidth - roomBG.bWidth) * 0.5;

	roomList.members.insert((_index == -1) ? 1 : _index, roomGroup);
	var _data = {
		name: name,
		users: users
	};
	if (_index == -1) __roomsData.push(_data);
	else __roomsData[_index] = _data;
		

	roomGroup.setPosition(_math, roomList.members[1].y);
	return roomGroup;
}

function removeRoom(name:String) {
	if (__roomsData.length == 0) return;
	var _index:Int = -1;
	for (i=>room in __roomsData) {
		trace("room: " + room + " | name: " + name);
		if (room.name != name) continue;
		_index = i;
		break;
	}
	if (_index == -1) return;
	_index++;

	var bruh = roomList.members[_index];
	if (bruh == null) return;

	bruh.destroy();
	remove(bruh, true);
	roomList.members.remove(bruh);

	__roomsData.remove(__roomsData[_index-1]);
}

var attemptJoinRoom:Bool = false;
function joinRoom(name:String) {
	if (attemptJoinRoom) return;
	attemptJoinRoom = true;

	for (group in roomList.members) {
		if (!(group is FlxTypedSpriteGroup)) continue;
		for (item in group.members) {
			if (item.ID != -1) continue;
			item.selectable = false;
		}
	}
	
	trace("Joining Room: "+name);
	roomEndpoint.set("current_room", {});
	sendPacket(new WebSocketPacket("room.join", {name: name}));
}

function onCloseSubstate(?data:Dynamic) {
	var data = data ?? {}
	creatingRoom = false;
	onResetEndPoints();
	var joinNewRoom = data.newRoom ?? false;
	var roomName = data.roomName ?? false;
	if (!joinNewRoom || !roomName) return;
}

// Top UI Options
var topOptions = [
// {
// 	label: "Rooms",
// 	childs: [{
// 		label: "Create a Room",
// 		closeOnSelect: true,
// 		onSelect: () -> { trace("Create a Room"); }
// 	}, {
// 		label: "Leave Room",
// 		closeOnSelect: true,
// 		onSelect: () -> { trace("Leave Room"); }
// 	}, {
// 		label: "List all Rooms",
// 		closeOnSelect: true,
// 		onSelect: () -> { trace("List all Rooms"); }
// 	}]
// },
];

function destroy() {
	if (Framerate.isLoaded) Framerate.fpsCounter.alpha = Framerate.memoryCounter.alpha = Framerate.codenameBuildField.alpha = 1;
}