// TEST ONLY: N4 probe pack (provider modCMFTestN4Pack), not a player package.
// The Seven Cats Inn signpost (tag seven_cats_inn) shows at twice the game's size with the label
// "CMF test" in blue under it, and its name over the crosshair is hidden. The size and label are per-pin
// calls from the OnPinReady hook, so they beat Map Quest Insight's own signpost size and name on that pin
// (this folder sorts first); the crosshair hide is a tag claim, which reaches the pin in CMF's late pass.
// The info box takes the smallest height CMF allows (100 px), so any quest description taller than that
// scrolls; this beats Map Quest Insight's "Info box height" (at least 320 px) because this folder sorts first.

@addField(CMFCore) var cmfTestN4Logged : bool;

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestN4Pack", 4))
	{
		CMFRegisterForTag("modCMFTestN4Pack", CMFPropertyLabelHide(), 'seven_cats_inn', '', "crosshair", 1);
		CMFRegister("modCMFTestN4Pack", CMFPropertyInfoBoxHeight(), '', '', "", 100);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	wrappedMethod(dataObject, mapContext);
	if (dataObject.GetMemberFlashUInt("id") == NameToFlashUInt('seven_cats_inn'))
	{
		CMFStylePinScale("modCMFTestN4Pack", dataObject, 200);
		CMFStylePinLabel("modCMFTestN4Pack", dataObject, "<font color='#33ccff'>CMF test</font>");
		if (!cmfTestN4Logged)
		{
			cmfTestN4Logged = true;
			LogChannel('CMF', "CMF test pack modCMFTestN4Pack styled seven_cats_inn");
		}
	}
}
