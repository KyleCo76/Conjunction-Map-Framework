// Ink and Iron adapter for Conjunction Map Framework. Requires CMF 9 (CMF 1.3.0) to compile, for the world
// overview pictures and the provider's menu name, and Ink and Iron 0.8.7 to 0.9.0, which stays unchanged: the
// separate modInkAndIronUI folder or the All In One file's modInkAndIron folder. Install and remove the two
// together: this file calls Ink and Iron's own functions, so the game stops at the script compile screen when
// Ink and Iron is missing.
//
// CMF replaces only Ink and Iron's world map; its HUD, compass and menus load as normal. Everything Ink and
// Iron's map adds comes back through CMF's general calls, written the way Ink and Iron's author would write
// them (docs/authors/ink-and-iron-adapter.md):
// - Quest levels. With its option "Quest levels on world map pins" on, Ink and Iron writes each quest
//   pin's level and difficulty on the pin (iaiLv, iaiDiff; inkironui_questlevel.ws 104-105) for its own map
//   file to draw. This adapter hands them to CMF as the pin's label ("Lv " and the level, as Ink and Iron
//   writes it in every language) and the label's colour (CMF property 17, LabelColor) in Ink and Iron's four
//   difficulty colours. The tag's plate, bar and gold border are drawings on CMF's pinLabel part below.
// - The key-hint row. Ink and Iron's map runs to the bottom of the screen and draws its own copy of the
//   common menu's key hints (inkironui_map.ws). CMF's map draws a display-only hint row from the list sent
//   to "cmf.map.hints" and asks for it with OnCMFMapHintsReady; this adapter sends Ink and Iron's list,
//   gathered with its own function, to that name. The common menu keeps handling every key. CMF's row
//   already sits at Ink and Iron's place, size and glow, so it needs no theme call.
// - The look. Ink and Iron draws its look with code in its map file: no image, only fills, gradients and
//   glows (MapMenu.ink*, iiFrame, HubMapContainer.inkEdge, TooltipMap, InputFeedbackButton.inkSyncCap,
//   KeyboardButtonIcon, StaticMapPinDescribed.iaiLvTab, HubMap and UniverseMap navigation). The same values
//   are registered here with CMFStylePart, CMFDraw and CMFDrawSet; the member each value was read from is
//   named next to it. No code of Ink and Iron's is copied.
// - The movement. Ink and Iron's map moves by the time since the last drawn frame, so held keys and the
//   sticks glide at any frame rate, and its movie runs at 60 frames a second. These are navigation keys
//   (InkAdapterLookNavigation); CMF's map acts on them from CMF 6.
// - The world overview pictures of Ink and Iron's optional World Map file (0.9.0): its engraved painting and
//   seven region crests, carried in this adapter's texture.cache with WinterElfeas's permission (2026-10-23,
//   "You can go ahead to carry it in the CMF pack"), cut unchanged from that file by
//   tools/cmf_ink_and_iron_art.py. A script cannot tell whether that optional file is installed, so they are
//   choice-only (InkAdapterWorldOverview): they show only when the player picks Ink and Iron on CMF's World
//   overview and Region crests and markers rows, and everyone else keeps the game's overview, as without CMF.
// Two of Ink and Iron's glitches are not copied (Kyle, 2026-10-20: "Don't copy a broken function"): its
// region title is cut at a word ("VELEN - NO") because its field keeps the game's line wrap, so here the
// title stays on one line (wrap none); and the legend frame always wraps every row it shows.
// Every claim uses Ink and Iron's folder name of 0.8.8 (modInkAndIronUI) as its provider; the name is only a
// label, so it works the same with the All In One folder (modInkAndIron). CMF's map declares
// iaiLv and iaiDiff for this adapter only, because the game drops pin fields its class does not declare.
//
// The file name sorts after inkironui_map.ws: wrappers nest by script file name, so this
// UpdateInputFeedback wrapper runs around Ink and Iron's.

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var level : int;
	wrappedMethod(dataObject, mapContext);
	level = dataObject.GetMemberFlashInt("iaiLv");
	if (level > 0 && dataObject.GetMemberFlashBool("isQuest"))
	{
		CMFStylePinLabel("modInkAndIronUI", dataObject, "Lv " + IntToString(level));
		CMFStylePin("modInkAndIronUI", dataObject, CMFPropertyLabelColor(), "",
			InkAdapterTagColor(dataObject.GetMemberFlashInt("iaiDiff")));
	}
}

// Ink and Iron's difficulty colours, iaiDiff 0 to 3 (StaticMapPinDescribed.iaiLvTab).
function InkAdapterTagColor(diff : int) : int
{
	if (diff <= 0)
	{
		return 9078136;	// 0x8A8578
	}
	if (diff == 1)
	{
		return 15722191;	// 0xEFE6CF
	}
	if (diff == 2)
	{
		return 14715194;	// 0xE0893A
	}
	return 13647919;	// 0xD0402F
}

// Ink and Iron's hint list (the body of its InkMapHints, inkironui_map.ws 13-36), sent to CMF's name.
@addMethod(CR4CommonMenu)
function InkAdapterMapHints() : void
{
	var mapMenu : CR4MapMenu;
	var st : CScriptedFlashValueStorage;
	var arr : CScriptedFlashArray;
	mapMenu = (CR4MapMenu)GetSubMenu();
	if (!mapMenu)
	{
		return;
	}
	st = mapMenu.GetMenuFlashValueStorage();
	if (!st)
	{
		return;
	}
	arr = st.CreateTempFlashArray();
	InkGatherHints(st, arr, m_contextBindings, 2, true);
	InkGatherHints(st, arr, m_GFxBindings, 1, false);
	InkGatherHints(st, arr, m_defaultBindings, 0, false);
	st.SetFlashArray("cmf.map.hints", arr);
}

// Every time the common menu rebuilds its buttons, as Ink and Iron sends its own list.
@wrapMethod(CR4CommonMenu)
function UpdateInputFeedback() : void
{
	wrappedMethod();
	InkAdapterMapHints();
}

// CMF's map registered its hint listener: send the current list (the common menu may have built it earlier).
@addMethod(CR4MapMenu)
event OnCMFMapHintsReady()
{
	var common : CR4CommonMenu;
	common = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	if (common)
	{
		common.InkAdapterMapHints();
	}
}

// ---------------------------------------------------------------------------------------------------
// The look. Registered once, like every CMF claim; CMF hands it to its map each time the map opens.
// Colours are decimal 0xRRGGBB (the hex value is in the comment); px are 1920 x 1080 stage px.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modInkAndIronUI", 5))
	{
		InkAdapterLookMap();
		InkAdapterLookScreen();
		InkAdapterFrameTracker();
		InkAdapterFrameLegend();
		InkAdapterFrameTip();
		InkAdapterLookText();
		InkAdapterLookTitle();
		InkAdapterLookLegend();
		InkAdapterLookPreview();
		InkAdapterLookKeys();
		InkAdapterLookLevelTag();
		InkAdapterLookMarkerPanel();
		InkAdapterLookNavigation();
		CMFSetProviderName("modInkAndIronUI", "Ink and Iron");
		InkAdapterWorldOverview();
	}
	return result;
}

// Ink and Iron's optional World Map file (mod0InkAndIron_WorldMap, 0.9.0) ships its own copy of the map file
// with two pictures swapped: the overview painting (_i313, 2100 x 1380) and the region crests (cut-outs of _i1,
// Kaer Morhen's wolf medallion 135 x 130, the rest 135 x 116). CMF's map replaces that file, so the pictures
// come back through CMF 9's world overview calls, choice-only because the file is optional: Painting_World and
// Painting_Crests apply only while the player picks Ink and Iron there (menu add-on, or CMFFile_Painting_World
// and CMFFile_Painting_Crests in the settings file).
function InkAdapterWorldOverview()
{
	CMFRegisterChoiceOnly("modInkAndIronUI", "Painting_World");
	CMFRegisterChoiceOnly("modInkAndIronUI", "Painting_Crests");
	CMFRegisterWorldPainting("modInkAndIronUI", "img://icons/modcmfadapterinkandiron/world/painting.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'kaer_morhen', "img://icons/modcmfadapterinkandiron/world/crest_kaer_morhen.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'skellige', "img://icons/modcmfadapterinkandiron/world/crest_skellige.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'novigrad', "img://icons/modcmfadapterinkandiron/world/crest_novigrad.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'no_mans_land', "img://icons/modcmfadapterinkandiron/world/crest_no_mans_land.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'wyzima_castle', "img://icons/modcmfadapterinkandiron/world/crest_wyzima_castle.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'bob', "img://icons/modcmfadapterinkandiron/world/crest_bob.png");
	CMFRegisterWorldCrest("modInkAndIronUI", 'prolog_village', "img://icons/modcmfadapterinkandiron/world/crest_prolog_village.png");
}

// The map runs from under the menu bar to the bottom of the screen over an ink backdrop, panning stops at
// the screen's edge, and a smaller map is centred (MapMenu.inkEdgeFill, HubMapContainer.inkViewport,
// inkLim). The game's edge gradients give way to a curved fade into the backdrop along each edge of the map
// image: 300 px times the game's own edge scale, at least 8 px, at most half the map's smaller side,
// opacity rising as t^1.6 toward the edge (HubMapContainer.inkEdge).
function InkAdapterLookMap()
{
	CMFStylePart("modInkAndIronUI", 'map', 'top', "", 100);
	CMFStylePart("modInkAndIronUI", 'map', 'bottom', "", 1080);
	CMFStylePart("modInkAndIronUI", 'map', 'backdrop', "", 1380879);	// 0x15120F
	CMFStylePart("modInkAndIronUI", 'map', 'panLimit', "screen", 0);
	CMFStylePart("modInkAndIronUI", 'map', 'centerInLimit', "", 1);
	CMFStylePart("modInkAndIronUI", 'mapEdge', 'hide', "edgeFade", 0);
	InkAdapterEdge('inkEdgeLeft', "left");
	InkAdapterEdge('inkEdgeRight', "right");
	InkAdapterEdge('inkEdgeTop', "top");
	InkAdapterEdge('inkEdgeBottom', "bottom");
}

function InkAdapterEdge(id : name, side : string)
{
	CMFDraw("modInkAndIronUI", 'mapEdge', id, 'band');
	CMFDrawSet("modInkAndIronUI", id, 'side', side, 0);
	CMFDrawSet("modInkAndIronUI", id, 'size', "", 300);
	CMFDrawSet("modInkAndIronUI", id, 'sizeZoom', "", 1);
	CMFDrawSet("modInkAndIronUI", id, 'minSize', "", 8);
	CMFDrawSet("modInkAndIronUI", id, 'maxShare', "", 0.5);
	CMFDrawSet("modInkAndIronUI", id, 'fill', "", 1380879);	// 0x15120F, inner end
	CMFDrawSet("modInkAndIronUI", id, 'alpha', "", 0);
	CMFDrawSet("modInkAndIronUI", id, 'fill2', "", 1380879);	// 0x15120F, at the map's edge
	CMFDrawSet("modInkAndIronUI", id, 'alpha2', "", 1);
	CMFDrawSet("modInkAndIronUI", id, 'gradient', "linear", 0);
	CMFDrawSet("modInkAndIronUI", id, 'curve', "", 1.6);
	CMFDrawSet("modInkAndIronUI", id, 'layer', "over", 0);
}

// A dark fade under the menu bar, 110 px tall, opacity (1 - t)^1.7 from the top (MapMenu.inkTopFade), and
// faint fades 260 px wide at the left and right edges (MapMenu.inkCreateOverlay); above the map, under
// every panel.
function InkAdapterLookScreen()
{
	CMFDraw("modInkAndIronUI", 'screen', 'inkTopFade', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'screenLeft', "", -10);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'screenTop', "", 100);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'screenRight', "", 1930);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'screenBottom', "", 210);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'fill', "", 328707);	// 0x050403, bottom
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'alpha', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'fill2', "", 328707);	// 0x050403, top
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'alpha2', "", 1);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'gradient', "linear", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'angle', "", 270);	// from the bottom up
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'curve', "", 1.7);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'layer', "aboveMap", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTopFade', 'order', "", 0);

	CMFDraw("modInkAndIronUI", 'screen', 'inkLeftFade', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'screenLeft', "", -10);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'screenTop', "", 100);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'screenRight', "", 250);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'screenBottom', "", 1080);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'fill', "", 723465);	// 0x0B0A09
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'alpha', "", 0.16);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'fill2', "", 723465);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'alpha2', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'gradient', "linear", 0);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'angle', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'layer', "aboveMap", 0);
	CMFDrawSet("modInkAndIronUI", 'inkLeftFade', 'order', "", 1);

	CMFDraw("modInkAndIronUI", 'screen', 'inkRightFade', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'screenLeft', "", 1670);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'screenTop', "", 100);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'screenRight', "", 1930);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'screenBottom', "", 1080);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'fill', "", 723465);	// 0x0B0A09
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'alpha', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'fill2', "", 723465);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'alpha2', "", 0.16);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'gradient', "linear", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'angle', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'layer', "aboveMap", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRightFade', 'order', "", 2);
}

// Ink and Iron's frame round the tracker card, the legend and (on the world view only) the tooltip
// (MapMenu.iiFrame, inkTrackerCard, inkLegendPanel, inkTipPanel): a shadow of 28 rings 1 px apart, a fill, 12
// sheen strips, an outline, a border and an inner gold line. Each piece is placed outward from the part's
// measured box; the box with 20 px of padding is the frame's own edge. A higher order draws on top.
// maxRight keeps the tracker's padded box at x 1912 or less; each piece adds its distance outside that box.
function InkAdapterFrameRing(anchor : name, id : name, outward : float, width : float, rgb : int, alpha : float,
	order : int, view : string, maxRight : float)
{
	CMFDraw("modInkAndIronUI", anchor, id, 'ring');
	CMFDrawSet("modInkAndIronUI", id, 'left', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'top', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'right', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'bottom', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'inset', "", width);
	CMFDrawSet("modInkAndIronUI", id, 'fill', "", rgb);
	CMFDrawSet("modInkAndIronUI", id, 'alpha', "", alpha);
	CMFDrawSet("modInkAndIronUI", id, 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", id, 'order', "", order);
	if (view != "")
	{
		CMFDrawSet("modInkAndIronUI", id, 'view', view, 0);
	}
	if (maxRight > 0)
	{
		CMFDrawSet("modInkAndIronUI", id, 'maxRight', "", maxRight + outward - 20);
	}
}

// The fill is the padded box itself; the sheen strips are tied to it, so their share of its height is a
// share of the padded box.
function InkAdapterFrameFill(anchor : name, id : name, view : string, maxRight : float)
{
	CMFDraw("modInkAndIronUI", anchor, id, 'rect');
	CMFDrawSet("modInkAndIronUI", id, 'left', "", 20);
	CMFDrawSet("modInkAndIronUI", id, 'top', "", 20);
	CMFDrawSet("modInkAndIronUI", id, 'right', "", 20);
	CMFDrawSet("modInkAndIronUI", id, 'bottom', "", 20);
	CMFDrawSet("modInkAndIronUI", id, 'fill', "", 723464);	// 0x0B0A08
	CMFDrawSet("modInkAndIronUI", id, 'alpha', "", 0.78);
	CMFDrawSet("modInkAndIronUI", id, 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", id, 'order', "", 28);
	if (view != "")
	{
		CMFDrawSet("modInkAndIronUI", id, 'view', view, 0);
	}
	if (maxRight > 0)
	{
		CMFDrawSet("modInkAndIronUI", id, 'maxRight', "", maxRight);
	}
}

// Sheen strip k of 12: full width, from the top, 0.6 x k / 12 of the padded box's height.
function InkAdapterFrameSheen(fill : name, id : name, k : int, view : string)
{
	CMFDraw("modInkAndIronUI", fill, id, 'rect');
	CMFDrawSet("modInkAndIronUI", id, 'widthShare', "", 1);
	CMFDrawSet("modInkAndIronUI", id, 'heightShare', "", 0.05 * (float)k);
	CMFDrawSet("modInkAndIronUI", id, 'alignX', "", 0);
	CMFDrawSet("modInkAndIronUI", id, 'alignY', "", 0);
	CMFDrawSet("modInkAndIronUI", id, 'fill', "", 3881526);	// 0x3B3A36
	CMFDrawSet("modInkAndIronUI", id, 'alpha', "", 0.1 / 12);
	CMFDrawSet("modInkAndIronUI", id, 'order', "", 28 + k);
	if (view != "")
	{
		CMFDrawSet("modInkAndIronUI", id, 'view', view, 0);
	}
}

// The shadow: one ring 1 px wide, 21 to 22 px outside the measured box (1 px outside the padded box),
// repeated 28 times 1 px further out each time. Copy i has opacity 0.45 / (1 + e^(-1.702 x (3 - (i + 0.5)) / 11)).
function InkAdapterFrameShadow(anchor : name, id : name, view : string, maxRight : float)
{
	InkAdapterFrameRing(anchor, id, 21, 1, 328707, 0.268, 0, view, maxRight);	// 0x050403
	CMFDrawSet("modInkAndIronUI", id, 'repeat', "", 28);
	CMFDrawSet("modInkAndIronUI", id, 'repeatStep', "", 1);
	CMFDrawSet("modInkAndIronUI", id, 'alphaList', "0.268,0.251,0.2337,0.2163,0.199,0.182,0.1655,0.1497,0.1347,0.1205,0.1074,0.0952,0.0841,0.0741,0.065,0.0568,0.0496,0.0432,0.0375,0.0325,0.0281,0.0243,0.021,0.0181,0.0156,0.0134,0.0116,0.0099", 0);
}

function InkAdapterFrameTracker()
{
	InkAdapterFrameShadow('tracker', 'inkTrackerShadow', "", 1912);
	InkAdapterFrameFill('tracker', 'inkTrackerFill', "", 1912);
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen1', 1, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen2', 2, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen3', 3, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen4', 4, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen5', 5, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen6', 6, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen7', 7, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen8', 8, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen9', 9, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen10', 10, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen11', 11, "");
	InkAdapterFrameSheen('inkTrackerFill', 'inkTrackerSheen12', 12, "");
	InkAdapterFrameRing('tracker', 'inkTrackerOutline', 21, 1, 328707, 0.65, 41, "", 1912);	// 0x050403, 0 to 1 px outside
	InkAdapterFrameRing('tracker', 'inkTrackerBorder', 20, 1.5, 8025708, 0.95, 42, "", 1912);	// 0x7A766C, 0 to 1.5 px inside
	InkAdapterFrameRing('tracker', 'inkTrackerInner', 16, 1, 11832388, 0.55, 43, "", 1912);	// 0xB48C44, 4 to 5 px inside
}

function InkAdapterFrameLegend()
{
	InkAdapterFrameShadow('legend', 'inkLegendShadow', "", 0);
	InkAdapterFrameFill('legend', 'inkLegendFill', "", 0);
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen1', 1, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen2', 2, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen3', 3, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen4', 4, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen5', 5, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen6', 6, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen7', 7, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen8', 8, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen9', 9, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen10', 10, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen11', 11, "");
	InkAdapterFrameSheen('inkLegendFill', 'inkLegendSheen12', 12, "");
	InkAdapterFrameRing('legend', 'inkLegendOutline', 21, 1, 328707, 0.65, 41, "", 0);	// 0x050403, 0 to 1 px outside
	InkAdapterFrameRing('legend', 'inkLegendBorder', 20, 1.5, 8025708, 0.95, 42, "", 0);	// 0x7A766C, 0 to 1.5 px inside
	InkAdapterFrameRing('legend', 'inkLegendInner', 16, 1, 11832388, 0.55, 43, "", 0);	// 0xB48C44, 4 to 5 px inside
}

// The info box's frame on every map view (Ink and Iron 0.8.10 frames it on the region and interior maps too,
// MapMenu.inkPinTipPanel; 0.8.9 only on the world view). CMF 7 or later also gets 0.8.10's two touches for a
// tall box (330 px or more with its 20 px padding, so a measured box of 290 px or more), on the region and
// interior maps only: a second dark fill under the frame (0x0B0A08 at 0.5455, about 90 percent dark with the
// frame's own fill), and the box moved clear of the cursor and the panels (MapMenu.inkTipPlace: right of the
// cursor first, inside 24 to 1896 by 104 to 1000 with the padding, so 44 to 1876 by 124 to 980 for the box).
// CMF 11 or later also keeps inkTipPlace's larger area round the cursor clear (Ink and Iron 0.8.10 to 0.9.0, read
// 2026-10-24): 70 px each way, a strip from 20 px above to 90 px below the cursor as wide as the box's title, 12 by
// 20 px more on each side and a 6 px gap to the box's frame (28 px round the box), trying the right, left and
// unchanged place against the unchanged, top, bottom and each panel's edges, the one covering least, the cursor
// area counting 12 times a panel.
function InkAdapterFrameTip()
{
	InkAdapterFrameShadow('tooltip', 'inkTipShadow', "", 0);
	InkAdapterFrameFill('tooltip', 'inkTipFill', "", 0);
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen1', 1, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen2', 2, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen3', 3, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen4', 4, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen5', 5, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen6', 6, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen7', 7, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen8', 8, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen9', 9, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen10', 10, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen11', 11, "");
	InkAdapterFrameSheen('inkTipFill', 'inkTipSheen12', 12, "");
	InkAdapterFrameRing('tooltip', 'inkTipOutline', 21, 1, 328707, 0.65, 41, "", 0);	// 0x050403, 0 to 1 px outside
	InkAdapterFrameRing('tooltip', 'inkTipBorder', 20, 1.5, 8025708, 0.95, 42, "", 0);	// 0x7A766C, 0 to 1.5 px inside
	InkAdapterFrameRing('tooltip', 'inkTipInner', 16, 1, 11832388, 0.55, 43, "", 0);	// 0xB48C44, 4 to 5 px inside
	if (CMFHasAbility('rect', 'minPartHeight'))
	{
		CMFDraw("modInkAndIronUI", 'tooltip', 'inkTipBacking', 'rect');
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'left', "", 20);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'top', "", 20);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'right', "", 20);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'bottom', "", 20);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'fill', "", 723464);	// 0x0B0A08
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'alpha', "", 0.5455);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'layer', "under", 0);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'order', "", 27);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'view', "region,interior", 0);
		CMFDrawSet("modInkAndIronUI", 'inkTipBacking', 'minPartHeight', "", 290);
	}
	if (CMFHasAbility('tooltip', 'clearMinHeight'))
	{
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearMinHeight', "", 290);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearView', "region,interior", 0);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearSide', "right", 0);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearLeft', "", 44);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearTop', "", 124);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearRight', "", 1876);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearBottom', "", 980);
		CMFStylePart("modInkAndIronUI", 'tooltip', 'clearCursor', "", 70);
		if (CMFHasAbility('tooltip', 'clearCursorTitle'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearCursorTitle', "", 1);
		}
		if (CMFHasAbility('tooltip', 'clearCursorAbove'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearCursorAbove', "", 20);
		}
		if (CMFHasAbility('tooltip', 'clearCursorBelow'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearCursorBelow', "", 90);
		}
		if (CMFHasAbility('tooltip', 'clearPadX'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearPadX', "", 12);
		}
		if (CMFHasAbility('tooltip', 'clearPadY'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearPadY', "", 20);
		}
		if (CMFHasAbility('tooltip', 'clearGap'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearGap', "", 6);
		}
		if (CMFHasAbility('tooltip', 'clearBoxPad'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearBoxPad', "", 28);
		}
		if (CMFHasAbility('tooltip', 'clearPick'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearPick', "", 1);
		}
		if (CMFHasAbility('tooltip', 'clearCursorWeight'))
		{
			CMFStylePart("modInkAndIronUI", 'tooltip', 'clearCursorWeight', "", 12);
		}
	}
}

// Two dark glows on the text of the tracker, tooltip and legend (MapMenu.inkShadow, TooltipMap.inkFont):
// CMF gives a part's glow to each of its text fields that has no filter of its own, as Ink and Iron does.
function InkAdapterTextGlow(part : name)
{
	CMFStylePart("modInkAndIronUI", part, 'glow1Color', "", 723465);	// 0x0B0A09
	CMFStylePart("modInkAndIronUI", part, 'glow1Alpha', "", 0.95);
	CMFStylePart("modInkAndIronUI", part, 'glow1Blur', "", 4);
	CMFStylePart("modInkAndIronUI", part, 'glow1Strength', "", 3);
	CMFStylePart("modInkAndIronUI", part, 'glow2Color', "", 723465);	// 0x0B0A09
	CMFStylePart("modInkAndIronUI", part, 'glow2Alpha', "", 0.75);
	CMFStylePart("modInkAndIronUI", part, 'glow2Blur', "", 14);
	CMFStylePart("modInkAndIronUI", part, 'glow2Strength', "", 2);
}

// Text: fonts and colours of the tracker and tooltip, the game's plates hidden, and the glows. The world-view
// button takes the softer button glow; the controller's "World map" hint that slides in when zoomed out
// takes the text glow, its plate hidden (MapMenu.inkRestyle).
function InkAdapterLookText()
{
	CMFStylePart("modInkAndIronUI", 'tracker', 'hide', "plate", 0);
	CMFStylePart("modInkAndIronUI", 'tracker', 'nameFont', "$TitleFont", 0);
	CMFStylePart("modInkAndIronUI", 'tracker', 'nameSize', "", 21);
	CMFStylePart("modInkAndIronUI", 'tracker', 'nameColor', "", 14537403);	// 0xDDD2BB
	InkAdapterTextGlow('tracker');

	CMFStylePart("modInkAndIronUI", 'tooltip', 'hide', "plate,trackedPlate,divider", 0);
	CMFStylePart("modInkAndIronUI", 'tooltip', 'titleFont', "$TitleFont", 0);
	CMFStylePart("modInkAndIronUI", 'tooltip', 'titleSize', "", 21);
	CMFStylePart("modInkAndIronUI", 'tooltip', 'titleColor', "", 14537403);	// 0xDDD2BB
	CMFStylePart("modInkAndIronUI", 'tooltip', 'bodyFont', "$BodyFont", 0);
	CMFStylePart("modInkAndIronUI", 'tooltip', 'bodySize', "", 19);
	CMFStylePart("modInkAndIronUI", 'tooltip', 'bodyColor', "", 10787199);	// 0xA4997F
	InkAdapterTextGlow('tooltip');

	InkAdapterTextGlow('legend');

	CMFStylePart("modInkAndIronUI", 'worldButton', 'hide', "plate", 0);
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow1Color', "", 723465);	// 0x0B0A09
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow1Alpha', "", 0.9);
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow1Blur', "", 5);
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow1Strength', "", 2.4);
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow2Color', "", 723465);	// 0x0B0A09
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow2Alpha', "", 0.6);
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow2Blur', "", 12);
	CMFStylePart("modInkAndIronUI", 'worldButton', 'glow2Strength', "", 1.6);

	CMFStylePart("modInkAndIronUI", 'worldHint', 'hide', "plate", 0);
	InkAdapterTextGlow('worldHint');
}

// The region title: Ink and Iron's lettering, left-aligned with its field's top-left at x 56, y 140, one
// glow, its plate hidden, and a gold diamond 14 px left of the text, level with the middle of the letters
// (MapMenu.inkStyleMapName, inkRestyle). wrap none keeps the whole name on one line; Ink and Iron's own
// field wraps and cuts the name, a glitch not copied. With one line, the title's box is the text's height,
// so originY 0.5 is the middle of the letters.
function InkAdapterLookTitle()
{
	CMFStylePart("modInkAndIronUI", 'title', 'font', "$TitleFont", 0);
	CMFStylePart("modInkAndIronUI", 'title', 'size', "", 27);
	CMFStylePart("modInkAndIronUI", 'title', 'color', "", 14537403);	// 0xDDD2BB
	CMFStylePart("modInkAndIronUI", 'title', 'spacing', "", 5);
	CMFStylePart("modInkAndIronUI", 'title', 'align', "left", 0);
	CMFStylePart("modInkAndIronUI", 'title', 'wrap', "none", 0);
	CMFStylePart("modInkAndIronUI", 'title', 'screenX', "", 56);
	CMFStylePart("modInkAndIronUI", 'title', 'screenY', "", 140);
	CMFStylePart("modInkAndIronUI", 'title', 'hide', "plate", 0);
	CMFStylePart("modInkAndIronUI", 'title', 'glow1Color', "", 723465);	// 0x0B0A09
	CMFStylePart("modInkAndIronUI", 'title', 'glow1Alpha', "", 0.9);
	CMFStylePart("modInkAndIronUI", 'title', 'glow1Blur', "", 8);
	CMFStylePart("modInkAndIronUI", 'title', 'glow1Strength', "", 2);
	CMFStylePart("modInkAndIronUI", 'title', 'glow2Alpha', "", 0);
	CMFDraw("modInkAndIronUI", 'title', 'inkTitleMark', 'polygon');
	CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'originX', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'originY', "", 0.5);
	CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'points', "-14,-5 -9,0 -14,5 -19,0", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'fill', "", 13214812);	// 0xC9A45C
	CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'layer', "under", 0);
}

// The legend: row colours, the game's row plates and selection hidden; the selected row gets a warm strip
// from screen x 52 (at least 300 px wide, 18 px past the row) and a diamond at screen x 44; the tab name is
// spaced out and, when selected, underlined by a 140 x 1 gold line 2 px below its full field
// (MapMenu.inkLegendPanel, inkWarm, inkLoz; HubMapPinCategoryItemRenderer.setColoredText, setCounter).
function InkAdapterLookLegend()
{
	CMFStylePart("modInkAndIronUI", 'legendRow', 'hide', "plate,selection,arrowPlate", 0);
	CMFStylePart("modInkAndIronUI", 'legendRow', 'color', "", 10787199);	// 0xA4997F
	CMFStylePart("modInkAndIronUI", 'legendRow', 'colorSelected', "", 14537403);	// 0xDDD2BB
	CMFStylePart("modInkAndIronUI", 'legendRow', 'colorOff', "", 6249557);	// 0x5F5C55
	CMFStylePart("modInkAndIronUI", 'legendRow', 'counterColor', "", 9340795);	// 0x8E877B
	InkAdapterTextGlow('legendRow');
	CMFStylePart("modInkAndIronUI", 'legendTab', 'hide', "plate,selection", 0);
	CMFStylePart("modInkAndIronUI", 'legendTab', 'spacing', "", 2.5);
	CMFStylePart("modInkAndIronUI", 'legendTab', 'color', "", 14537403);	// 0xDDD2BB
	InkAdapterTextGlow('legendTab');

	CMFDraw("modInkAndIronUI", 'legendRow', 'inkRowGlow', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'when', "selected", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'screenLeft', "", 52);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'right', "", 18);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'top', "", -2);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'bottom', "", -2);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'minWidth', "", 300);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'fill', "", 13214812);	// 0xC9A45C
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'alpha', "", 0.24);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'fill2', "", 13214812);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'alpha2', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'gradient', "linear", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'angle', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowGlow', 'order', "", 0);

	CMFDraw("modInkAndIronUI", 'legendRow', 'inkRowMark', 'polygon');
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'when', "selected", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'screenLeft', "", 44);
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'originX', "", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'originY', "", 0.5);
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'points', "0,-4.5 4.5,0 0,4.5 -4.5,0", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'fill', "", 14861439);	// 0xE2C47F
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", 'inkRowMark', 'order', "", 1);

	CMFDraw("modInkAndIronUI", 'legendTab', 'inkTabLine', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'when', "selected", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'measure', "field", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'width', "", 140);
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'height', "", 1);
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'alignX', "", 0.5);
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'alignY', "", 1);
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'offsetY', "", 3);	// top edge 2 px below the field
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'fill', "", 11832388);	// 0xB48C44
	CMFDrawSet("modInkAndIronUI", 'inkTabLine', 'layer', "under", 0);
}

// The corner overview: the game's frame hidden; a 1 px dark line and a 3 px light line on its box drawn
// 8 px in, with a dot at each corner (MapMenu.inkFrame3, inkRestyle). Strokes are centred on their line,
// so the 1 px line covers 4.5 to 5.5 px inside the box and the 3 px line 6.5 to 9.5 px.
function InkAdapterLookPreview()
{
	CMFStylePart("modInkAndIronUI", 'preview', 'hide', "frame", 0);
	InkAdapterPreviewLine('inkPreviewOuter', -4.5, 1, 723465, 0.9, 0);	// 0x0B0A09
	InkAdapterPreviewLine('inkPreviewLine', -6.5, 3, 10262154, 1, 1);	// 0x9C968A
	InkAdapterPreviewDot('inkPreviewDotTL', 0, 0);
	InkAdapterPreviewDot('inkPreviewDotTR', 1, 0);
	InkAdapterPreviewDot('inkPreviewDotBL', 0, 1);
	InkAdapterPreviewDot('inkPreviewDotBR', 1, 1);
}

function InkAdapterPreviewLine(id : name, outward : float, width : float, rgb : int, alpha : float, order : int)
{
	CMFDraw("modInkAndIronUI", 'preview', id, 'ring');
	CMFDrawSet("modInkAndIronUI", id, 'left', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'top', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'right', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'bottom', "", outward);
	CMFDrawSet("modInkAndIronUI", id, 'inset', "", width);
	CMFDrawSet("modInkAndIronUI", id, 'fill', "", rgb);
	CMFDrawSet("modInkAndIronUI", id, 'alpha', "", alpha);
	CMFDrawSet("modInkAndIronUI", id, 'layer', "over", 0);
	CMFDrawSet("modInkAndIronUI", id, 'order', "", order);
}

// A dot of radius 3.2 centred on a corner of the box drawn 8 px in.
function InkAdapterPreviewDot(id : name, alignX : float, alignY : float)
{
	CMFDraw("modInkAndIronUI", 'preview', id, 'ellipse');
	CMFDrawSet("modInkAndIronUI", id, 'width', "", 6.4);
	CMFDrawSet("modInkAndIronUI", id, 'height', "", 6.4);
	CMFDrawSet("modInkAndIronUI", id, 'alignX', "", alignX);
	CMFDrawSet("modInkAndIronUI", id, 'alignY', "", alignY);
	CMFDrawSet("modInkAndIronUI", id, 'offsetX', "", 4.8 - 9.6 * alignX);
	CMFDrawSet("modInkAndIronUI", id, 'offsetY', "", 4.8 - 9.6 * alignY);
	CMFDrawSet("modInkAndIronUI", id, 'fill', "", 13156008);	// 0xC8BEA8
	CMFDrawSet("modInkAndIronUI", id, 'layer', "over", 0);
	CMFDrawSet("modInkAndIronUI", id, 'order', "", 2);
}

// Key caps: gold key letters with a dark glow and no brackets, the game's key plates (KeyboardButtonIcon's
// mcBackground) and click plates (InputFeedbackButton's mcClickRect) hidden, the letter
// 7 px and the label 12 px further right (InputFeedbackButton.displayKeyboardIcon, inkSyncCap); plain key
// icons in a darker gold (KeyboardButtonIcon.label).
function InkAdapterLookKeys()
{
	CMFStylePart("modInkAndIronUI", 'keyCap', 'hide', "plate,clickRect", 0);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'brackets', "", 0);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'color', "", 14861439);	// 0xE2C47F
	CMFStylePart("modInkAndIronUI", 'keyCap', 'iconColor', "", 13214812);	// 0xC9A45C
	CMFStylePart("modInkAndIronUI", 'keyCap', 'keyGap', "", 7);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'labelGap', "", 12);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow1Color', "", 328707);	// 0x050403
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow1Alpha', "", 0.95);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow1Blur', "", 4);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow1Strength', "", 3);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow2Color', "", 328707);	// 0x050403
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow2Alpha', "", 0.7);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow2Blur', "", 12);
	CMFStylePart("modInkAndIronUI", 'keyCap', 'glow2Strength', "", 2);
}

// The level tag on quest pins (StaticMapPinDescribed.iaiLvTab): $BoldFont 12 in the difficulty colour
// (LabelColor, from OnPinReady above) on a dark plate with a 2 px bar in the same colour at its foot; a
// tracked pin's plate sits on a gold rectangle 1 px larger, whose gold shows faintly through the plate. The
// plate is w = textWidth + 10 by h = textHeight + 5 round the text, its foot 10.625 + 3 px above the pin's
// centre (11 when tracked). Ink and Iron draws the tag inside the pin icon, so in game the whole tag shows
// at the icon's scale of 1.5 (launch T1 against its reference shots: 59 against 39 px wide); here that is
// $BoldFont 18 with every offset x 1.5. From the label's text box (textWidth + 4 by textHeight + 4) the plate
// is 5.5 px out on the left and right, 1 px out at the top and 2.5 px out at the foot, the bar 3 px high, the
// gold rectangle 1.5 px larger. The box's foot sits 10.625 x the pin's scale + 7 px above the pin's centre
// (19 when tracked), so the plate's foot sits 2.5 px lower, where Ink and Iron's does; one drop shadow
// covers the tag.
function InkAdapterLookLevelTag()
{
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'font', "$BoldFont", 0);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'size', "", 18);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'rise', "", 10.625);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'riseOffset', "", 7);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'riseTracked', "", 10.625);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'riseOffsetTracked', "", 19);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'shadowDistance', "", 1);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'shadowAngle', "", 90);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'shadowColor', "", 0);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'shadowAlpha', "", 0.6);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'shadowBlur', "", 2);
	CMFStylePart("modInkAndIronUI", 'pinLabel', 'shadowStrength', "", 1);

	CMFDraw("modInkAndIronUI", 'pinLabel', 'inkTagTracked', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'when', "tracked", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'left', "", 7);
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'top', "", 2.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'right', "", 7);
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'bottom', "", 4);
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'fill', "", 13214282);	// 0xC9A24A
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTagTracked', 'order', "", 0);

	CMFDraw("modInkAndIronUI", 'pinLabel', 'inkTagPlate', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'left', "", 5.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'top', "", 1);
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'right', "", 5.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'bottom', "", 2.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'fill', "", 1183500);	// 0x120F0C
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'alpha', "", 0.94);
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTagPlate', 'order', "", 1);

	CMFDraw("modInkAndIronUI", 'pinLabel', 'inkTagBar', 'rect');
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'left', "", 5.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'right', "", 5.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'height', "", 3);
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'alignY', "", 1);
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'offsetY', "", 2.5);
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'fill', "label", 0);	// the label's own colour
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'layer', "under", 0);
	CMFDrawSet("modInkAndIronUI", 'inkTagBar', 'order', "", 2);
}

// The custom-marker panel stays clear of the screen's edges (MapMenu.enableUserPinPanel).
function InkAdapterLookMarkerPanel()
{
	CMFStylePart("modInkAndIronUI", 'markerPanel', 'minLeft', "", 24);
	CMFStylePart("modInkAndIronUI", 'markerPanel', 'maxRight', "", 1896);
	CMFStylePart("modInkAndIronUI", 'markerPanel', 'minTop', "", 110);
	CMFStylePart("modInkAndIronUI", 'markerPanel', 'maxBottom', "", 1000);
}

// Pan and zoom stepped by elapsed time (17 ms steps on the region map, 24 on the world view, gaps over
// 100 ms capped); with a controller the crosshair moves on toward the edge inside x 96-1824, y 146-984
// once the map stops, snapping in 0.3 s and centring in 0.25 s (HubMap.handleScrollAndZoomTimer, inkSafe,
// inkAim, inkPan, inkRingGo; UniverseMap.handleScrollTimer).
// CMF 6 adds three keys Ink and Iron's map decides, each asked for with CMFHasAbility so CMF 5 still loads
// the rest: its key and stick zoom keeps one step per 17 ms through its own counter instead of scaling by
// elapsed time (zoomTimed 0), it uses each stick reading once as the game does (padHoldMs 0), and its movie
// runs at 60 frames a second (frameRate 60; the movie's header). They are sent although two equal the game's,
// so a later folder's smooth-map keys do not replace Ink and Iron's own choice. Ink and Iron changes nothing
// in how the map opens or closes, and its map has no button beside a pin, so it sets no opening or pinButton
// key.
function InkAdapterLookNavigation()
{
	CMFStylePart("modInkAndIronUI", 'navigation', 'frameTimed', "", 1);
	CMFStylePart("modInkAndIronUI", 'navigation', 'stepMs', "", 17);
	CMFStylePart("modInkAndIronUI", 'navigation', 'worldStepMs', "", 24);
	CMFStylePart("modInkAndIronUI", 'navigation', 'maxStepMs', "", 100);
	CMFStylePart("modInkAndIronUI", 'navigation', 'crosshairRoam', "", 1);
	CMFStylePart("modInkAndIronUI", 'navigation', 'safeLeft', "", 96);
	CMFStylePart("modInkAndIronUI", 'navigation', 'safeTop', "", 146);
	CMFStylePart("modInkAndIronUI", 'navigation', 'safeRight', "", 1824);
	CMFStylePart("modInkAndIronUI", 'navigation', 'safeBottom', "", 984);
	CMFStylePart("modInkAndIronUI", 'navigation', 'snapSeconds', "", 0.3);
	CMFStylePart("modInkAndIronUI", 'navigation', 'centerSeconds', "", 0.25);
	if (CMFHasAbility('navigation', 'zoomTimed'))
	{
		CMFStylePart("modInkAndIronUI", 'navigation', 'zoomTimed', "", 0);
	}
	if (CMFHasAbility('navigation', 'padHoldMs'))
	{
		CMFStylePart("modInkAndIronUI", 'navigation', 'padHoldMs', "", 0);
	}
	if (CMFHasAbility('navigation', 'frameRate'))
	{
		CMFStylePart("modInkAndIronUI", 'navigation', 'frameRate', "", 60);
	}
}
