// Witcher's Path adapter for Conjunction Map Framework. Requires CMF 6 with map-space drawing and Witcher's
// Path 1.0.3 (Nexus 13423), which stays unchanged. Install and remove the two together: this file calls
// Witcher's Path's own settings, text and erase functions, so the game stops at the script compile screen when
// Witcher's Path is missing, and it wraps CMF 6's drawing click hook, which earlier CMF versions do not have.
//
// Witcher's Path records where Geralt travels and draws it in its own map file: a line along the route (one
// colour, or one colour per way of travel), its own last filter tab "WITCHER'S PATH" on which only Geralt
// shows, and four boxes stacked above the filter selector (from the selector up: "Erase path", the region and
// total distances, the "Single color" switch and, only while single colour is off, the colour legend). Its script sends the route of the shown region,
// with the two distance lines, to the map menu's storage key worldmap.witcherspath. CMF's map loads instead of
// its map file, so under CMF none of that shows while the recorder keeps recording.
//
// This adapter describes the same things to CMF: one line drawing on the map itself that reads the route from
// worldmap.witcherspath (listen), so Witcher's Path keeps computing and sending it exactly as now and an erase
// redraws on its own; four text boxes above legendTab with the mod's look; the tab, made by the drawings' tab
// key. Witcher's Path's first send comes before CMF's map listens, so when CMF's map starts listening the
// adapter asks Witcher's Path to send the route once more. A click on "Erase path" calls Witcher's Path's own
// OnWitchersPathClearRequest (its popup, its erase and its redraw); a click on "Single color" calls its own
// OnWitchersPathUseGeneralColor (it saves the choice), then the adapter redraws with the new colours. It ships
// no art and copies no code; nothing here adds a feature.
//
// Claim order: every drawing uses Witcher's Path's own folder name, modWitchersPath, as its provider, so folder
// order is the same with CMF as without it. Drawing ids start with witchersPath; an id belongs to the earliest
// folder that made it, and another folder's calls on it are refused and logged. The route sits in the under
// layer of mapSpace (above the map tiles, below every pin) with order 10, so it draws above a map-space drawing
// left at order 0 whatever the folders; the boxes share legendTab with any theme and show only on the
// Witcher's Path tab. Clicks on a drawing go only to its owner.
//
// Every Witcher's Path name, setting, text key, default and colour below was read from Witcher's Path 1.0.3's
// own scripts (modWitchersPathConfig.ws, modWitchersPathMap.ws WitchersPathSendConfig) and its strings.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	WpAdapterSetUp();
	return result;
}

// Witcher's Path reads its settings when the map opens; so does the adapter, before the game builds the map.
@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	WpAdapterSetUp();
	return wrappedMethod();
}

// True when this CMF draws everything the adapter describes; otherwise the route stays missing, as without the
// adapter.
function WpAdapterReady() : bool
{
	return CMFRequireVersion("modWitchersPath", 6) && CMFHasAbility('mapSpace', '') &&
		CMFHasAbility('line', 'listen') && CMFHasAbility('line', 'colors') && CMFHasAbility('text', 'listen') &&
		CMFHasAbility('text', 'above') && CMFHasAbility('text', 'click') && CMFHasAbility('text', 'colorHover') &&
		CMFHasAbility('text', 'tab');
}

// Describes everything to CMF for Witcher's Path's current settings and switch.
function WpAdapterSetUp()
{
	if (!WpAdapterReady())
	{
		return;
	}
	// Seeds Witcher's Path's settings when they are still empty, as Witcher's Path does itself.
	WitchersPathEnsureConfigDefaults();
	// Its "Enable Witcher's Path" option, read as it reads it: on unless set to false (without its menu file the
	// option is empty and the mod stays on).
	if (WitchersPathGetVar('WPEnabled') == "false" || WitchersPathGetVar('WPEnabled') == "0")
	{
		CMFReleaseProvider("modWitchersPath");
		return;
	}
	WpAdapterDraw(WpAdapterSingle());
}

// Witcher's Path's "Single color" switch, which it keeps in the save (CWitchersPathData.useGeneralColor).
function WpAdapterSingle() : bool
{
	var w : W3PlayerWitcher;
	w = GetWitcherPlayer();
	if (w && w.witchersPathData)
	{
		return w.witchersPathData.useGeneralColor;
	}
	return false;
}

// Witcher's Path's own texts, with its own keys and English fallbacks, through its own WitchersPathLoc. Its tab
// name is the literal "Witcher's Path" in its map file, which has no text key for it.
function WpAdapterLabel(what : name) : string
{
	switch (what)
	{
		case 'tab':
			return "Witcher's Path";
		case 'erase':
			return WitchersPathLoc("wp_erase_path", "Erase path");
		case 'singleOn':
			return WitchersPathLoc("wp_single_color_on", "Single color: on");
		case 'singleOff':
			return WitchersPathLoc("wp_single_color_off", "Single color: off");
		case 'foot':
			return WitchersPathLoc("wp_mode_foot", "On foot");
		case 'horse':
			return WitchersPathLoc("wp_mode_horse", "On horseback");
		case 'boat':
			return WitchersPathLoc("wp_mode_boat", "By boat");
	}
	return "";
}

// One colour per way of travel, indexed as the route's modes list (its EWitchersPathMode: WPM_Foot 0, WPM_Horse 1,
// WPM_Boat 2), from Witcher's Path's own options (palette numbers turned into colours by its own
// WitchersPathPaletteRGB, with its own defaults green, red, blue). With single colour on, its general colour
// three times.
function WpAdapterColors(singleColor : bool) : array<float>
{
	var colors : array<float>;
	var general : float;
	general = WpAdapterGeneralColor();
	if (singleColor)
	{
		colors.PushBack(general);
		colors.PushBack(general);
		colors.PushBack(general);
	}
	else
	{
		colors.PushBack((float)WitchersPathPaletteRGB(WitchersPathGetInt('WPColorFoot', 2)));
		colors.PushBack((float)WitchersPathPaletteRGB(WitchersPathGetInt('WPColorHorse', 0)));
		colors.PushBack((float)WitchersPathPaletteRGB(WitchersPathGetInt('WPColorBoat', 1)));
	}
	return colors;
}

// Witcher's Path's single colour (default green).
function WpAdapterGeneralColor() : float
{
	return (float)WitchersPathPaletteRGB(WitchersPathGetInt('WPColorGeneral', 2));
}

// 0xRRGGBB as the six hex digits the game's HTML text takes.
function WpAdapterHex(rgb : int) : string
{
	var digits, hex : string;
	var i, d, rest : int;
	digits = "0123456789ABCDEF";
	hex = "";
	rest = rgb;
	for (i = 0; i < 6; i += 1)
	{
		d = rest % 16;
		rest = rest / 16;
		hex = StrMid(digits, d, 1) + hex;
	}
	return hex;
}

// The colour legend: each way of travel in its own colour, four spaces apart, as Witcher's Path writes it.
function WpAdapterLegendText() : string
{
	var colors : array<float>;
	colors = WpAdapterColors(false);
	return "<font color='#" + WpAdapterHex((int)colors[0]) + "'>" + WpAdapterLabel('foot') + "</font>    " +
		"<font color='#" + WpAdapterHex((int)colors[1]) + "'>" + WpAdapterLabel('horse') + "</font>    " +
		"<font color='#" + WpAdapterHex((int)colors[2]) + "'>" + WpAdapterLabel('boat') + "</font>";
}

// Everything Witcher's Path draws, for one state of its "Single color" switch.
function WpAdapterDraw(singleColor : bool)
{
	var tabLabel : string;
	var colors : array<float>;
	tabLabel = WpAdapterLabel('tab');
	colors = WpAdapterColors(singleColor);

	// The route: the shown region's segments from Witcher's Path's own storage key, in the under layer of the
	// map itself, the same px width at every zoom, 0.9 opaque, only on its tab.
	CMFDraw("modWitchersPath", 'mapSpace', 'witchersPathRoute', 'line');
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'listen', "worldmap.witcherspath", 0);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'layer', "under", 0);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'order', "", 10);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'view', "region", 0);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'tab', "WitchersPath", 0);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'tabLabel', tabLabel, 0);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeWidth', "", (float)WitchersPathGetInt('WPThickness', 4));
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeAlpha', "", 0.9);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeZoom', "", 0);
	CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'stroke', "", WpAdapterGeneralColor());
	CMFDrawSetList("modWitchersPath", 'witchersPathRoute', 'colors', colors);

	// The boxes, stacked upward from the filter selector 6 px apart: erase, distances, switch, and on top the
	// legend, only while single colour is off, so the other three never move.
	CMFDraw("modWitchersPath", 'legendTab', 'witchersPathErase', 'text');
	WpAdapterBox('witchersPathErase', WpAdapterLabel('erase'), 1, tabLabel);
	CMFDraw("modWitchersPath", 'witchersPathErase', 'witchersPathDistance', 'text');
	WpAdapterBox('witchersPathDistance', " ", 0, tabLabel);
	CMFDrawSet("modWitchersPath", 'witchersPathDistance', 'listen', "worldmap.witcherspath", 0);
	CMFDrawSet("modWitchersPath", 'witchersPathDistance', 'listenFields', "text=regionText|totalText", 0);
	CMFDraw("modWitchersPath", 'witchersPathDistance', 'witchersPathSingle', 'text');
	if (singleColor)
	{
		WpAdapterBox('witchersPathSingle', WpAdapterLabel('singleOn'), 2, tabLabel);
		CMFDraw("modWitchersPath", 'witchersPathSingle', 'witchersPathLegend', '');
	}
	else
	{
		WpAdapterBox('witchersPathSingle', WpAdapterLabel('singleOff'), 2, tabLabel);
		CMFDraw("modWitchersPath", 'witchersPathSingle', 'witchersPathLegend', 'text');
		WpAdapterBox('witchersPathLegend', WpAdapterLegendText(), 0, tabLabel);
	}
}

// Witcher's Path's box: black at 0.6 with a 1 px 0x5A5A5A outline at 0.6, white centred words in the filter tab
// name's font at size 22, the selector's width, at least 38 px high (its words plus 6 px above and below), 6 px
// above the box below. Its two buttons take the mouse and turn their outline 0xE8B85C at 0.9, their words
// 0xE8B85C and the fill 0.8 under the pointer.
function WpAdapterBox(id : name, text : string, click : int, tabLabel : string)
{
	CMFDrawSet("modWitchersPath", id, 'text', text, 0);
	CMFDrawSet("modWitchersPath", id, 'font', "legendTab", 0);
	CMFDrawSet("modWitchersPath", id, 'size', "", 22);
	CMFDrawSet("modWitchersPath", id, 'color', "", 16777215);
	CMFDrawSet("modWitchersPath", id, 'align', "center", 0);
	CMFDrawSet("modWitchersPath", id, 'fill', "", 0);
	CMFDrawSet("modWitchersPath", id, 'alpha', "", 0.6);
	CMFDrawSet("modWitchersPath", id, 'stroke', "", 5921370);
	CMFDrawSet("modWitchersPath", id, 'strokeAlpha', "", 0.6);
	CMFDrawSet("modWitchersPath", id, 'strokeWidth', "", 1);
	CMFDrawSet("modWitchersPath", id, 'padding', "", 6);
	CMFDrawSet("modWitchersPath", id, 'minHeight', "", 38);
	CMFDrawSet("modWitchersPath", id, 'widthShare', "", 1);
	CMFDrawSet("modWitchersPath", id, 'above', "", 6);
	CMFDrawSet("modWitchersPath", id, 'view', "region", 0);
	CMFDrawSet("modWitchersPath", id, 'tab', "WitchersPath", 0);
	CMFDrawSet("modWitchersPath", id, 'tabLabel', tabLabel, 0);
	if (click > 0)
	{
		CMFDrawSet("modWitchersPath", id, 'click', "", (float)click);
		CMFDrawSet("modWitchersPath", id, 'strokeHover', "", 15251548);
		CMFDrawSet("modWitchersPath", id, 'strokeAlphaHover', "", 0.9);
		CMFDrawSet("modWitchersPath", id, 'colorHover', "", 15251548);
		CMFDrawSet("modWitchersPath", id, 'alphaHover', "", 0.8);
	}
}

// Witcher's Path sends the first region's route while the map is still opening, before CMF's map listens, and
// such a value never arrives (launch D1). CMF calls this once its map starts listening; when the keys include
// Witcher's Path's own, the adapter asks Witcher's Path to send its route again with its own WitchersPathSend.
@wrapMethod(CMFCore)
function OnMapListening(menu : CR4MapMenu, keys : string)
{
	wrappedMethod(menu, keys);
	if (menu && StrFindFirst("|" + keys + "|", "|worldmap.witcherspath|") >= 0)
	{
		menu.WitchersPathSend(true);
	}
}

// CMF passes back every click on this adapter's buttons: 1 "Erase path", 2 "Single color". Clicks on other
// mods' drawings go on unchanged.
@wrapMethod(CMFCore)
function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
{
	if (provider != "modWitchersPath")
	{
		return wrappedMethod(menu, provider, id, input, value);
	}
	if (value == 1)
	{
		// Witcher's Path's own popup; on yes it erases the shown region and sends the route again, which the
		// route and distance drawings read at once.
		menu.OnWitchersPathClearRequest();
	}
	else if (value == 2)
	{
		// Witcher's Path keeps the choice in the save; the adapter redraws the open map with it, keeping tab, pan
		// and zoom.
		menu.OnWitchersPathUseGeneralColor(!WpAdapterSingle());
		WpAdapterDraw(WpAdapterSingle());
		CMFMapRefresh();
	}
	return true;
}
