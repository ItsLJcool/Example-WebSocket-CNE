//a
import StringTools;

var inARoom:Bool = false;
var current_room = {};

function onConnect(ws) { }

// if it wans't a WebSocketPacket.
function rawPacketData(data) { }

var __onPacket = () -> {};
function set_onPacket(f) {
	if (f == null) return;
	__onPacket = f;
}
function onPacket(packet) {
	trace("Packet Name: " + packet.name + " | data: " + packet.data);
	if (!StringTools.startsWith(packet.name, "room.")) return;

	switch (packet.name) {
		case "room.create", "room.join":
			var roomJson = packet.data?.room;
			current_room = roomJson ?? {};
			if (roomJson != null) inARoom = true;
			trace("inARoom: " + inARoom);
		case "account.getSelf":
			serverUser = {account: packet.data?.account ?? {}, clientId: packet.data?.clientId ?? false};
	}
	
	__onPacket(packet);
}

function onError(error) { }

function onClose() { }



// from GlobalScript.hx
function postUpdate(elapsed) { }