//a
import funkin.backend.system.net.WebSocketUtil;
import funkin.backend.system.net.WebSocketPacket;

import funkin.editors.ui.UIState;

function update() {
	
	if (FlxG.keys.justPressed.K) FlxG.switchState(new UIState(true, "room/ui.RoomList"));
}