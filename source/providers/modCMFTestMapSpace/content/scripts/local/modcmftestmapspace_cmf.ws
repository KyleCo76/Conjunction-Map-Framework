// TEST ONLY: the map-space drawing check (map-space drawing research 2026-10-20, section 5.2), provider
// modCMFTestMapSpace, not a player package. It ships CMF's own test movie (content/blob0.bundle, built by
// tools/cmf_test_movie.py from source/panel/test-movie/CMFTestMapSpace.as) and draws, around Geralt on the
// region map:
// - a "movie" drawing: the test movie draws an orange square on Geralt, a white cross 100 m east and west of
//   him, and an orange dot on him in the corner overview (preview 1); it fades in over 250 ms;
// - a "line" drawing: a ring of 40 m around Geralt, half green and half blue (one colour per segment), shown
//   only while the legend tab "CMF TEST" is selected; that tab is added with no pins (only Geralt shows);
// - a "text" drawing at Geralt's position: "CMF MAP SPACE", the same size at every zoom;
// - a button above the legend's tab selector (text, hover and click 1), on the "CMF TEST" tab only: a click
//   swaps the ring's two colours through CMFDrawSetList and CMFMapRefresh, and logs "drawing click";
// - two "listen" probes at the top left of the screen, below the region name: the text of each comes from a
//   storage key this script writes. EARLY is written before the map panel exists (OnConfigUI, before the
//   game's own handler), which launch D1 showed never arrives, and again from the OnMapListening hook once the
//   panel listens: "EARLY: received after listen ready" proves the hook. LATE is written on each button click
//   while the map is open: "LATE: click 1", "LATE: click 2", ... proves a value written while listening arrives.

@addField(CMFCore)
var modCMFTestMapSpaceSwapped : bool;

@addField(CMFCore)
var modCMFTestMapSpaceClicks : int;

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	ModCMFTestMapSpaceDraw();
	return result;
}

function ModCMFTestMapSpaceDraw()
{
	var p : string;
	p = "modCMFTestMapSpace";
	if (!CMFHasAbility('mapSpace', '') || !CMFHasAbility('movie', 'src') || !CMFHasAbility('line', 'colors'))
	{
		LogChannel('CMF', "CMF_TEST_MAPSPACE skipped reason=noability");
		return;
	}
	CMFDraw(p, 'mapSpace', 'cmfTestMapSpaceMovie', 'movie');
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'src', "swf/cmftestmapspace/cmftestmapspace.swf", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'layer', "under", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'view', "region", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'preview', "", 1);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'fadeMs', "", 250);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'size', "", 60);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'color', "", 16753920);

	CMFDraw(p, 'mapSpace', 'cmfTestMapSpaceRing', 'line');
	CMFDrawSet(p, 'cmfTestMapSpaceRing', 'layer', "over", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceRing', 'strokeWidth', "", 4);
	CMFDrawSet(p, 'cmfTestMapSpaceRing', 'strokeAlpha', "", 0.9);
	CMFDrawSet(p, 'cmfTestMapSpaceRing', 'strokeZoom', "", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceRing', 'tab', "CMFTestMapSpace", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceRing', 'tabLabel', "CMF TEST", 0);

	CMFDraw(p, 'mapSpace', 'cmfTestMapSpaceLabel', 'text');
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'text', "CMF MAP SPACE", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'size', "", 20);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'color', "", 16777215);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'fill', "", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'alpha', "", 0.6);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'padding', "", 4);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'offsetY', "", -48);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'layer', "over", 0);

	CMFDraw(p, 'legendTab', 'cmfTestMapSpaceButton', 'text');
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'text', "Swap colours", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'font', "legendTab", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'color', "", 16777215);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'fill', "", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'alpha', "", 0.6);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'stroke', "", 5921370);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'strokeAlpha', "", 0.6);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'strokeWidth', "", 1);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'padding', "", 6);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'widthShare', "", 1);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'minHeight', "", 38);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'above', "", 6);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'click', "", 1);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'strokeHover', "", 15252828);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'colorHover', "", 15252828);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'alphaHover', "", 0.8);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'tab', "CMFTestMapSpace", 0);
	CMFDrawSet(p, 'cmfTestMapSpaceButton', 'view', "region", 0);

	ModCMFTestMapSpaceProbe('cmfTestMapSpaceEarly', "modcmftestmapspace.early", "EARLY: waiting", 240);
	ModCMFTestMapSpaceProbe('cmfTestMapSpaceLate', "modcmftestmapspace.late", "LATE: waiting", 276);
	LogChannel('CMF', "CMF_TEST_MAPSPACE registered");
}

function ModCMFTestMapSpaceProbe(id : name, key : string, waiting : string, top : float)
{
	var p : string;
	p = "modCMFTestMapSpace";
	CMFDraw(p, 'screen', id, 'text');
	CMFDrawSet(p, id, 'text', waiting, 0);
	CMFDrawSet(p, id, 'listen', key, 0);
	CMFDrawSet(p, id, 'listenFields', "text=label", 0);
	CMFDrawSet(p, id, 'screenLeft', "", 40);
	CMFDrawSet(p, id, 'screenTop', "", top);
	CMFDrawSet(p, id, 'width', "", 420);
	CMFDrawSet(p, id, 'height', "", 30);
	CMFDrawSet(p, id, 'alignX', "", 0);
	CMFDrawSet(p, id, 'alignY', "", 0);
	CMFDrawSet(p, id, 'align', "left", 0);
	CMFDrawSet(p, id, 'size', "", 18);
	CMFDrawSet(p, id, 'color', "", 16777215);
	CMFDrawSet(p, id, 'fill', "", 0);
	CMFDrawSet(p, id, 'alpha', "", 0.6);
	CMFDrawSet(p, id, 'padding', "", 4);
	CMFDrawSet(p, id, 'layer', "top", 0);
}

function ModCMFTestMapSpaceWrite(storage : CScriptedFlashValueStorage, key : string, label : string)
{
	var item : CScriptedFlashObject;
	if (!storage)
	{
		LogChannel('CMF', "CMF_TEST_MAPSPACE listen write skipped key=" + key + " reason=nostorage");
		return;
	}
	item = storage.CreateTempFlashObject();
	item.SetMemberFlashString("label", label);
	storage.SetFlashObject(key, item);
	LogChannel('CMF', "CMF_TEST_MAPSPACE listen write key=" + key);
}

// The early probe: written before the game's own OnConfigUI, so before the map panel listens to anything.
@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	ModCMFTestMapSpaceWrite(GetMenuFlashValueStorage(), "modcmftestmapspace.early", "EARLY: received");
	return wrappedMethod();
}

// The early probe again, once the panel listens to it (the hook a mod uses for a value it wrote too early).
@wrapMethod(CMFCore)
function OnMapListening(menu : CR4MapMenu, keys : string)
{
	wrappedMethod(menu, keys);
	if (menu && StrFindFirst(keys, "modcmftestmapspace.early") >= 0)
	{
		ModCMFTestMapSpaceWrite(menu.GetMenuFlashValueStorage(), "modcmftestmapspace.early",
			"EARLY: received after listen ready");
	}
}

// Every map build (and CMFMapRefresh): put the drawings on Geralt's position.
@wrapMethod(CMFCore)
function OnMapReady(menuFlash : CScriptedFlashSprite)
{
	var p : string;
	var pos : Vector;
	var xs, ys, starts, modes, colors, marks : array<float>;
	var i : int;
	var angle : float;
	wrappedMethod(menuFlash);
	p = "modCMFTestMapSpace";
	pos = thePlayer.GetWorldPosition();
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'x', "", pos.X);
	CMFDrawSet(p, 'cmfTestMapSpaceMovie', 'y', "", pos.Y);
	marks.PushBack(pos.X + 100);
	marks.PushBack(pos.Y);
	marks.PushBack(pos.X - 100);
	marks.PushBack(pos.Y);
	CMFDrawSetList(p, 'cmfTestMapSpaceMovie', 'marks', marks);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'x', "", pos.X);
	CMFDrawSet(p, 'cmfTestMapSpaceLabel', 'y', "", pos.Y);
	for (i = 0; i <= 25; i += 1)
	{
		// Two segments of 13 points: 0-180 degrees, then 180-360 (point 13 repeats point 12).
		if (i <= 12)
		{
			angle = Deg2Rad(15.0 * i);
		}
		else
		{
			angle = Deg2Rad(15.0 * (i - 1));
		}
		xs.PushBack(pos.X + 40 * CosF(angle));
		ys.PushBack(pos.Y + 40 * SinF(angle));
	}
	starts.PushBack(0);
	starts.PushBack(13);
	modes.PushBack(0);
	modes.PushBack(1);
	if (modCMFTestMapSpaceSwapped)
	{
		colors.PushBack(3381759);
		colors.PushBack(3394611);
	}
	else
	{
		colors.PushBack(3394611);
		colors.PushBack(3381759);
	}
	CMFDrawSetList(p, 'cmfTestMapSpaceRing', 'xs', xs);
	CMFDrawSetList(p, 'cmfTestMapSpaceRing', 'ys', ys);
	CMFDrawSetList(p, 'cmfTestMapSpaceRing', 'starts', starts);
	CMFDrawSetList(p, 'cmfTestMapSpaceRing', 'modes', modes);
	CMFDrawSetList(p, 'cmfTestMapSpaceRing', 'colors', colors);
}

// The button: swap the ring's colours, then redraw the open map without rebuilding it.
@wrapMethod(CMFCore)
function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
{
	var refreshed : int;
	if (provider != "modCMFTestMapSpace" || id != 'cmfTestMapSpaceButton')
	{
		return wrappedMethod(menu, provider, id, input, value);
	}
	modCMFTestMapSpaceSwapped = !modCMFTestMapSpaceSwapped;
	modCMFTestMapSpaceClicks += 1;
	if (menu)
	{
		ModCMFTestMapSpaceWrite(menu.GetMenuFlashValueStorage(), "modcmftestmapspace.late",
			"LATE: click " + modCMFTestMapSpaceClicks);
	}
	refreshed = 0;
	if (CMFMapRefresh())
	{
		refreshed = 1;
	}
	LogChannel('CMF', "CMF_TEST_MAPSPACE swap value=" + value + " refreshed=" + refreshed);
	return true;
}
