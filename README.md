> [!WARNING]
> This Codename Engine MOD was made for the [**WebSocket Implementation Pull Request**](https://github.com/CodenameCrew/CodenameEngine/pull/520)
>
> Only use this in that version of Codename Engine, or you will get errors.

## Example WebSocket for the JavaScript WebSocket Server Template for Codename Engine
Hello!<br>
basically this mod is a simple example of how to use the WebSocket Server Template for Codename Engine.

To test the client, you need to use the [**WebSocket Server Template**](https://github.com/ItsLJcool/WebSocket-Server-Template-for-CNE) I made for Codename Engine.

> [!INFO]
> Quick heads up!
>
>  Pressing `F8` will re-connect to the server if you are disconnected and you ran out of the reconnect attempts.
>
> This code is probably messy, and thats because It was just make as a quick example for debuigging, and testing server to client communication.
>
> If you truely want an example, take the idea of `global.hx` and make it work for you.

Please report any bugs in the issues tab or DM on Discord. ***(@itsljcool)***

## How does this example work?
First lets look at the `data/global.hx` file.

`onlineWebSocket` is just the `WebSocketUitl` for connecting to the Server.<br>
This example orients the server messages as endpoints, any file placed in the `data/endpoints` folder will be an endpoint that Global.hx will send packets or events to.

You can get the `Script` object from that enpoint by using
```haxe
// Reference: funkin.backend.scripting.Script - If you want to understand how to fully uitlize this.
var exampleEndpoint = get_endpointScript("ExampleEndpoint");
// this allows for a layer of abstraction, so you can hold data in the specific endpoint and use it everywhere like a static variable but easier to understand.

exampleEndpoint.set("someData", true);
exampleEndpoint.get("someData"); // returns true

exampleEndpoint.call("someFunction", ["parameter1"]); // calls the function "someFunction" on the endpoint with 1 argument
```
If you need to reset your endpoints, you can use `onResetEndPoints()` in `data/global.hx` to reset them.
```haxe
// Initalize the endpoint at least :sob:
var exampleEndpoint = get_endpointScript("ExampleEndpoint");
function onResetEndPoints() {
	exampleEndpoint = get_endpointScript("ExampleEndpoint");
}
// We do this since this is 1 script object that is loaded in `global.hx`, so all `get_endpointScript` calls will return the same Script object.
```

Now basically you have all the utils / tools to get all the server events! Up from here you can code your own custom endpoints and code whatever you want to do with the server data!