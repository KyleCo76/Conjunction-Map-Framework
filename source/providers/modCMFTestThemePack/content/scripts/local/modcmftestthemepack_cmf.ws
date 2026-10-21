// TEST ONLY: the Cyberpunk check (Stage 6b design 6), provider modCMFTestThemePack, not a player package.
// A deliberately different look made from CMF's public calls only, with no CMF change: a near-black backdrop,
// neon map art for Velen and Novigrad (CMFRegisterBackground, root cmf_testneon), neon quest icons
// (CMFRegisterIcon; one legend image for the shared quest row), cyan frames with a strong glow round the
// tracker, legend and tooltip, magenta spaced title text on one line, cyan key caps, a cyan edge glow round
// the map and dark plates under pin labels. Every colour is decimal 0xRRGGBB with the hex value in the
// comment; px are 1920 x 1080 stage px. Its art is CMF's own procedural geometry (tools/cmf_test_theme.py).
// Install it without any other theme: the earliest folder that styles a part owns it, so a theme in an
// earlier folder (an Ink and Iron adapter, for example) keeps every part both style.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestThemePack", 5))
	{
		CMFRegisterBackground("modCMFTestThemePack", 'AN_NMLandNovigrad', "cmf_testneon");
		CMFRegisterIcon("modCMFTestThemePack", 'StoryQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CMFRegisterIcon("modCMFTestThemePack", 'ChapterQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CMFRegisterIcon("modCMFTestThemePack", 'SideQuest', "img://icons/modcmftestthemepack/quest_side.png");
		CMFRegisterIcon("modCMFTestThemePack", 'TreasureQuest', "img://icons/modcmftestthemepack/quest_side.png");
		CMFRegisterIcon("modCMFTestThemePack", 'MonsterQuest', "img://icons/modcmftestthemepack/quest_contract.png");
		CMFRegisterLegendIcon("modCMFTestThemePack", 'StoryQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CMFRegisterLegendIcon("modCMFTestThemePack", 'ChapterQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CMFRegisterLegendIcon("modCMFTestThemePack", 'SideQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CMFRegisterLegendIcon("modCMFTestThemePack", 'TreasureQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CMFRegisterLegendIcon("modCMFTestThemePack", 'MonsterQuest', "img://icons/modcmftestthemepack/quest_main.png");
		CyberTestMap();
		CyberTestTitle();
		CyberTestPanels();
		CyberTestKeys();
		CyberTestPinLabels();
	}
	return result;
}

// The map sits on a near-black backdrop with the game's edge gradients replaced by a cyan glow 24 px deep
// along each edge of the map image, and a magenta line runs under the menu bar.
function CyberTestMap()
{
	CMFStylePart("modCMFTestThemePack", 'map', 'backdrop', "", 329226);	// 0x05060A
	CMFStylePart("modCMFTestThemePack", 'mapEdge', 'hide', "edgeFade", 0);
	CyberTestEdge('cyberTestEdgeLeft', "left");
	CyberTestEdge('cyberTestEdgeRight', "right");
	CyberTestEdge('cyberTestEdgeTop', "top");
	CyberTestEdge('cyberTestEdgeBottom', "bottom");

	CMFDraw("modCMFTestThemePack", 'screen', 'cyberTestTopLine', 'rect');
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'screenLeft', "", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'screenRight', "", 1920);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'screenTop', "", 100);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'screenBottom', "", 103);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'fill', "", 16722902);	// 0xFF2BD6
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'glow1Color', "", 16722902);	// 0xFF2BD6
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'glow1Alpha', "", 0.9);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'glow1Blur', "", 14);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'glow1Strength', "", 3);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTopLine', 'layer', "aboveMap", 0);
}

function CyberTestEdge(id : name, side : string)
{
	CMFDraw("modCMFTestThemePack", 'mapEdge', id, 'band');
	CMFDrawSet("modCMFTestThemePack", id, 'side', side, 0);
	CMFDrawSet("modCMFTestThemePack", id, 'size', "", 24);
	CMFDrawSet("modCMFTestThemePack", id, 'fill', "", 61695);	// 0x00F0FF, inner end
	CMFDrawSet("modCMFTestThemePack", id, 'alpha', "", 0);
	CMFDrawSet("modCMFTestThemePack", id, 'fill2', "", 61695);	// 0x00F0FF, at the map's edge
	CMFDrawSet("modCMFTestThemePack", id, 'alpha2', "", 0.7);
	CMFDrawSet("modCMFTestThemePack", id, 'gradient', "linear", 0);
	CMFDrawSet("modCMFTestThemePack", id, 'curve', "", 2);
}

// The region title in magenta, widely spaced, on one line, with a magenta glow and a cyan underline.
function CyberTestTitle()
{
	CMFStylePart("modCMFTestThemePack", 'title', 'font', "$TitleFont", 0);
	CMFStylePart("modCMFTestThemePack", 'title', 'color', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'title', 'spacing', "", 9);
	CMFStylePart("modCMFTestThemePack", 'title', 'wrap', "none", 0);
	CMFStylePart("modCMFTestThemePack", 'title', 'hide', "plate", 0);
	CMFStylePart("modCMFTestThemePack", 'title', 'glow1Color', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'title', 'glow1Alpha', "", 0.8);
	CMFStylePart("modCMFTestThemePack", 'title', 'glow1Blur', "", 12);
	CMFStylePart("modCMFTestThemePack", 'title', 'glow1Strength', "", 2);

	CMFDraw("modCMFTestThemePack", 'title', 'cyberTestTitleLine', 'rect');
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'left', "", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'right', "", 40);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'bottom', "", 8);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'height', "", 3);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'alignY', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'fill', "", 61695);	// 0x00F0FF
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'glow1Color', "", 61695);	// 0x00F0FF
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'glow1Alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'glow1Blur', "", 10);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestTitleLine', 'glow1Strength', "", 2);
}

// The tracker, legend and tooltip lose the game's plates and get a dark panel inside a glowing cyan ring,
// with a magenta tab on the top-left corner. Their text turns cyan, magenta and ice white.
function CyberTestPanels()
{
	CMFStylePart("modCMFTestThemePack", 'tracker', 'hide', "plate", 0);
	CMFStylePart("modCMFTestThemePack", 'tracker', 'nameColor', "", 61695);	// 0x00F0FF
	CMFStylePart("modCMFTestThemePack", 'tooltip', 'hide', "plate,trackedPlate,divider", 0);
	CMFStylePart("modCMFTestThemePack", 'tooltip', 'titleColor', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'tooltip', 'bodyColor', "", 13630207);	// 0xCFFAFF
	CMFStylePart("modCMFTestThemePack", 'legendRow', 'hide', "plate", 0);
	CMFStylePart("modCMFTestThemePack", 'legendRow', 'color', "", 61695);	// 0x00F0FF
	CMFStylePart("modCMFTestThemePack", 'legendRow', 'colorSelected', "", 16576010);	// 0xFCEE0A
	CMFStylePart("modCMFTestThemePack", 'legendRow', 'colorOff', "", 3038310);	// 0x2E5C66
	CMFStylePart("modCMFTestThemePack", 'legendRow', 'counterColor', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'legendTab', 'hide', "plate", 0);
	CMFStylePart("modCMFTestThemePack", 'legendTab', 'color', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'legendTab', 'spacing', "", 3);
	CMFStylePart("modCMFTestThemePack", 'worldButton', 'hide', "plate", 0);
	CMFStylePart("modCMFTestThemePack", 'worldHint', 'hide', "plate", 0);
	CyberTestFrame('tracker', 'cyberTestTrackerPanel', 'cyberTestTrackerRing', 'cyberTestTrackerTab');
	CyberTestFrame('legend', 'cyberTestLegendPanel', 'cyberTestLegendRing', 'cyberTestLegendTab');
	CyberTestFrame('tooltip', 'cyberTestTipPanel', 'cyberTestTipRing', 'cyberTestTipTab');
}

function CyberTestFrame(anchor : name, panel : name, ring : name, tab : name)
{
	CMFDraw("modCMFTestThemePack", anchor, panel, 'rect');
	CMFDrawSet("modCMFTestThemePack", panel, 'left', "", 14);
	CMFDrawSet("modCMFTestThemePack", panel, 'top', "", 14);
	CMFDrawSet("modCMFTestThemePack", panel, 'right', "", 14);
	CMFDrawSet("modCMFTestThemePack", panel, 'bottom', "", 14);
	CMFDrawSet("modCMFTestThemePack", panel, 'fill', "", 659226);	// 0x0A0F1A
	CMFDrawSet("modCMFTestThemePack", panel, 'alpha', "", 0.88);
	CMFDrawSet("modCMFTestThemePack", panel, 'layer', "under", 0);
	CMFDrawSet("modCMFTestThemePack", panel, 'order', "", 0);

	CMFDraw("modCMFTestThemePack", anchor, ring, 'ring');
	CMFDrawSet("modCMFTestThemePack", ring, 'left', "", 14);
	CMFDrawSet("modCMFTestThemePack", ring, 'top', "", 14);
	CMFDrawSet("modCMFTestThemePack", ring, 'right', "", 14);
	CMFDrawSet("modCMFTestThemePack", ring, 'bottom', "", 14);
	CMFDrawSet("modCMFTestThemePack", ring, 'inset', "", 2);
	CMFDrawSet("modCMFTestThemePack", ring, 'fill', "", 61695);	// 0x00F0FF
	CMFDrawSet("modCMFTestThemePack", ring, 'alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", ring, 'glow1Color', "", 61695);	// 0x00F0FF
	CMFDrawSet("modCMFTestThemePack", ring, 'glow1Alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", ring, 'glow1Blur', "", 18);
	CMFDrawSet("modCMFTestThemePack", ring, 'glow1Strength', "", 3);
	CMFDrawSet("modCMFTestThemePack", ring, 'layer', "under", 0);
	CMFDrawSet("modCMFTestThemePack", ring, 'order', "", 1);

	CMFDraw("modCMFTestThemePack", anchor, tab, 'rect');
	CMFDrawSet("modCMFTestThemePack", tab, 'left', "", 14);
	CMFDrawSet("modCMFTestThemePack", tab, 'top', "", 18);
	CMFDrawSet("modCMFTestThemePack", tab, 'width', "", 64);
	CMFDrawSet("modCMFTestThemePack", tab, 'height', "", 6);
	CMFDrawSet("modCMFTestThemePack", tab, 'alignX', "", 0);
	CMFDrawSet("modCMFTestThemePack", tab, 'alignY', "", 0);
	CMFDrawSet("modCMFTestThemePack", tab, 'fill', "", 16722902);	// 0xFF2BD6
	CMFDrawSet("modCMFTestThemePack", tab, 'alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", tab, 'layer', "under", 0);
	CMFDrawSet("modCMFTestThemePack", tab, 'order', "", 2);
}

// Key caps without the game's plate: cyan key names in brackets with a cyan glow, magenta key icons, and a
// cyan glow on the hint row.
function CyberTestKeys()
{
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'hide', "plate", 0);
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'color', "", 61695);	// 0x00F0FF
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'iconColor', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'glow1Color', "", 61695);	// 0x00F0FF
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'glow1Alpha', "", 0.7);
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'glow1Blur', "", 8);
	CMFStylePart("modCMFTestThemePack", 'keyCap', 'glow1Strength', "", 2);
	CMFStylePart("modCMFTestThemePack", 'hints', 'glow1Color', "", 61695);	// 0x00F0FF
	CMFStylePart("modCMFTestThemePack", 'hints', 'glow1Alpha', "", 0.5);
	CMFStylePart("modCMFTestThemePack", 'hints', 'glow1Blur', "", 6);
	CMFStylePart("modCMFTestThemePack", 'hints', 'glow1Strength', "", 2);
}

// Pin labels get a magenta glow, a dark plate with a cyan outline under them, and a bar in the label's own
// colour on the plate's left.
function CyberTestPinLabels()
{
	CMFStylePart("modCMFTestThemePack", 'pinLabel', 'shadowDistance', "", 0);
	CMFStylePart("modCMFTestThemePack", 'pinLabel', 'shadowColor', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modCMFTestThemePack", 'pinLabel', 'shadowAlpha', "", 1);
	CMFStylePart("modCMFTestThemePack", 'pinLabel', 'shadowBlur', "", 6);
	CMFStylePart("modCMFTestThemePack", 'pinLabel', 'shadowStrength', "", 2);

	CMFDraw("modCMFTestThemePack", 'pinLabel', 'cyberTestLabelPlate', 'rect');
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'left', "", 8);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'right', "", 4);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'top', "", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'bottom', "", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'fill', "", 329226);	// 0x05060A
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'alpha', "", 0.85);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'stroke', "", 61695);	// 0x00F0FF
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'strokeAlpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'strokeWidth', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelPlate', 'layer', "under", 0);

	CMFDraw("modCMFTestThemePack", 'cyberTestLabelPlate', 'cyberTestLabelBar', 'rect');
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelBar', 'left', "", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelBar', 'width', "", 3);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelBar', 'alignX', "", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelBar', 'fill', "label", 0);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelBar', 'alpha', "", 1);
	CMFDrawSet("modCMFTestThemePack", 'cyberTestLabelBar', 'layer', "under", 0);
}
