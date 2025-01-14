//a
import funkin.backend.system.net.WebSocketUtil;
import funkin.backend.system.net.WebSocketPacket;

function onReady() {
	sendPacket(new WebSocketPacket("client.login", {method: "discord"}));
}