//a

var backgroundActive = false;
function createBG(?_colors:Array) {
	menuTansparent = new FlxSprite().loadGraphic(Paths.image("menus/menuTransparent"));
	menuTansparent.setGraphicSize(FlxG.width, FlxG.height);
	menuTansparent.updateHitbox();
	add(menuTansparent);
	backgroundActive = true;
	colors = _colors ?? [0xFF23DAA0, 0xD437CB3C];
	return menuTansparent;
}


var colors = [0xFF23DAA0, 0xD437CB3C];
var _colorTimes:Int = 0;
var colorTimer:Float = 0;
function update(elapsed) {
	if (!backgroundActive) return;
	colorTimer += elapsed*0.0625;
	if (colorTimer >= 1) {
		colorTimer = 0;
		_colorTimes++;
	}

	var color1 = colors[_colorTimes % colors.length];
	var color2 = colors[(_colorTimes+1) % colors.length];

	menuTansparent.color = FlxColor.interpolate(color1, color2, colorTimer);
}