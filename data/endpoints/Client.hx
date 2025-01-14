//a
import StringTools;

var serverUser = {};

var __onPacket = () -> {};
function set_onPacket(f) {
	if (f == null) return;
	__onPacket = f;
}
function onPacket(packet) {
	if (!StringTools.startsWith(packet.name, "client.")) return;

	switch (packet.name) {
		case "client.login":
			serverUser = {account: packet.data?.account ?? {}, clientId: packet.data?.clientId ?? false};
	}
	
	__onPacket(packet);
}


var __onClose = () -> {};
function set_onClose(f) {
	if (f == null) return;
	__onClose = f;
}
function onClose() {
	trace("client closed");
	__onClose();
}