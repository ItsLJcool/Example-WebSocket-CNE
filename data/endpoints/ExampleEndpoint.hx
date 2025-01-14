//a
import StringTools;

function onConnect(ws) { }

// if it wans't a WebSocketPacket.
function rawPacketData(data) { }

var __onPacket = () -> {};
function set_onPacket(f) {
	if (f == null) return;
	__onPacket = f;
}
function onPacket(data) {
	// custom code here for managing your own endpoint for management, but you can do whatever.
	__onPacket(data);
}

function onError(error) { }

function onClose() { }


// from GlobalScript.hx
function postUpdate(elapsed) { }