//a
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIText;
import funkin.options.Options;

import flixel.text.FlxTextBorderStyle;

import funkin.backend.system.net.WebSocketPacket;

import funkin.backend.utils.DiscordUtil;

winWidth = 850;
winHeight = 550;
winTitle = "Room Settings";

var _height = 32;
function postCreate() {
	var defaultText = "My Custom Room";
	if (DiscordUtil.user.globalName != null) defaultText = DiscordUtil.user.globalName+"'s Room";

	roomDisplay = new UIText(5, _height + 20, 0, "Room's Name");
	add(roomDisplay);

	roomName = new UITextBox(5, roomDisplay.y + roomDisplay.height + 2, defaultText);
	add(roomName);
	
    continueButton = new UIButton(0, 0, "Continue", createRoomExit, 126, 45);
    continueButton.x = winWidth * 0.5 - continueButton.bWidth * 0.5;
    continueButton.y = winHeight - continueButton.bHeight - 10;
    add(continueButton);
	
    leaveButton = new UIButton(0, 0, "X", closeSubState, 28, 28);
    leaveButton.x = winWidth - leaveButton.bWidth - 2;
	leaveButton.y += 2;
    leaveButton.color = 0xFFFF0000;
    add(leaveButton);

	
	validRoomName = new UIText(0, 0, 0, "Invalid Room Name!", 25);
	validRoomName.x = continueButton.x + continueButton.bWidth * 0.5 - validRoomName.width * 0.5;
	validRoomName.y = continueButton.y + continueButton.bHeight + validRoomName.height + 5;
    validRoomName.color = 0xFFFF0000;
	validRoomName.borderStyle = FlxTextBorderStyle.OUTLINE;
	validRoomName.borderColor = 0xFF000000;
	validRoomName.borderSize = 2.5;
	validRoomName.alpha = 0.0001;
	add(validRoomName);
}

function createRoomExit() {
	sendPacket(new WebSocketPacket("room.checkRoom", {name: StringTools.trim(roomName.label.text)}));
    // close();
}

function closeSubState(?_args:Array) {
	var args = _args ?? [];
    FlxG.state.stateScripts.call("onCloseSubstate", args);
	close();
}

var tweenAlpha:FlxTween;
function onPacket(packet) {
	if (packet.name != "room.checkRoom") return;
	if (packet.data.valid) {
		sendPacket(new WebSocketPacket("room.joinOrCreate", {name: packet.data.roomName}));
		closeSubState([{newRoom: true, roomName: packet.data.roomName}]);
		return;
	}
	validRoomName.alpha = 1;
	tweenAlpha?.cancel();
	tweenAlpha = FlxTween.tween(validRoomName, {alpha: 0.0001}, 1, {startDelay: 0.75, ease: FlxEase.quadInOut});
}
var roomEndpoint = get_endpointScript("Rooms");
roomEndpoint.call("set_onPacket", [onPacket]);