// Original test-only provider. Plain wrappers; no saved state or settings.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestRev13Look", 13))
	{
		CMFStylePart("modCMFTestRev13Look", 'legend', 'x', "", 60);
		CMFStylePart("modCMFTestRev13Look", 'tracker', 'y', "", 40);
		CMFStylePart("modCMFTestRev13Look", 'preview', 'x', "", -60);
		CMFRegister("modCMFTestRev13Look", 31, 'Boat', '', "img://icons/modcmftestrev13look/ask.png", 0);
		CMFRegister("modCMFTestRev13Look", 32, 'Boat', '', "", 140);
		CMFRegister("modCMFTestRev13Look", 33, 'Boat', '', "", 90);
		CMFRegister("modCMFTestRev13Look", 34, 'Boat', '', "", 7);
		CMFRegister("modCMFTestRev13Look", 35, 'Boat', '', "1,1", 0);
		CMFRegister("modCMFTestRev13Look", 36, 'Boat', '', "0,100", 0);
		CMFRegister("modCMFTestRev13Look", 42, 'Boat', '', "img://icons/modcmftestrev13look/ask.png", 0);
		CMFRegister("modCMFTestRev13Look", 43, 'Boat', '', "", 65535);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'plateColor', "", 1581887);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'plateAlpha', "", 0.95);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'thumbColor', "", 65535);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'trackColor', "", 4210752);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'scrollStep', "", 2);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'titleCase', "keep", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'hideScrollBar', "", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'showSeconds', "", 0.15);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'hideSeconds', "", 0.1);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'slide', "", 12);
		CMFStylePart("modCMFTestRev13Look", 'crosshair', 'glow1Color', "", 65535);
		CMFStylePart("modCMFTestRev13Look", 'edgePointer', 'glow1Color', "", 65535);
		CMFStylePart("modCMFTestRev13Look", 'pin', 'glowAlpha', "", 0.6);
		CMFDraw("modCMFTestRev13Look", 'tooltip', 'modCMFTestRev13Look.image', 'image');
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'src', "img://icons/modcmftestrev13look/ask.png", 0);
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'width', "", 16);
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'height', "", 16);
		// Fix round 1: the anchor box is the box's visible text, and edge keys push outward, so the image
		// takes the top-right corner (alignX 1, alignY 0) and sits 8 px right of the text.
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'alignX', "", 1);
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'alignY', "", 0);
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'right', "", 24);
		CMFDrawSet("modCMFTestRev13Look", 'modCMFTestRev13Look.image', 'withLook', "", 1);
		CMFRegister("modCMFTestRev13Look", 39, 'Boat', '', "", 480);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'foldTag', "rev13fold", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'foldMoreText', "[[cmf_rev13_look_more]]", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'foldLessText', "[[cmf_rev13_look_less]]", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'foldKeyKb', "DrinkPotion2", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'foldKeyPad', "DrinkPotion1", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'foldOpen', "", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'clearAnchor', "pin", 0);
		CMFStyle("modCMFTestRev13Look", 'tooltip', 'Boat', 'clearMinHeight', "", 1);
		CMFStylePart("modCMFTestRev13Look", 'legend', 'show', "auto", 0);
		CMFStylePart("modCMFTestRev13Look", 'legend', 'autoHideMs', "", 1200);
		CMFStylePart("modCMFTestRev13Look", 'legend', 'padShowFirst', "", 1);
		CMFStylePart("modCMFTestRev13Look", 'preview', 'show', "moving", 0);
		CMFStylePart("modCMFTestRev13Look", 'preview', 'movingMs', "", 600);
		CMFStylePart("modCMFTestRev13Look", 'opening', 'waitForMap', "", 1);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	wrappedMethod(dataObject, mapContext);
	if (dataObject && dataObject.GetMemberFlashString("type") == "Boat")
	{
		CMFStylePin("modCMFTestRev13Look", dataObject, CMFPropertyInfoTitle(), GetLocStringByKeyExt("cmf_rev13_look_title"), 0);
		CMFStylePin("modCMFTestRev13Look", dataObject, CMFPropertyInfoText(), GetLocStringByKeyExt("cmf_rev13_look_body"), 0);
	}
}

@wrapMethod(CMFCore)
function OnMapTab(menu : CR4MapMenu, category : string)
{
	wrappedMethod(menu, category);
	LogChannel('CMF', "CMF rev13 hooks tab=" + category);
}

@wrapMethod(CMFCore)
function OnMapHints(menu : CR4MapMenu, owner : string)
{
	wrappedMethod(menu, owner);
	LogChannel('CMF', "CMF rev13 hooks hints owner=" + owner);
}

@wrapMethod(CMFCore)
function OnInfoFold(menu : CR4MapMenu, provider : string, open : bool)
{
	wrappedMethod(menu, provider, open);
	if (open) { LogChannel('CMF', "CMF rev13 fold provider=" + provider + " open=true"); }
	else { LogChannel('CMF', "CMF rev13 fold provider=" + provider + " open=false"); }
}

@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	var rootFlash : CScriptedFlashSprite;
	rootFlash = GetMenuFlash();
	if (rootFlash)
	{
		rootFlash.SetMemberFlashNumber("rev13OwnNumber", 13);
		rootFlash.SetMemberFlashString("rev13OwnText", "original root handshake");
	}
	wrappedMethod();
	if (rootFlash)
	{
		LogChannel('CMF', "CMF rev13 rootValues number=" + rootFlash.GetMemberFlashNumber("rev13OwnNumber") + " text=" + rootFlash.GetMemberFlashString("rev13OwnText"));
	}
}
