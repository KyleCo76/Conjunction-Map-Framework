// TEST ONLY: generic-registration probe pack (provider modcmfTestCaseA).
// Uses only CMFHasProperty and CMFRegister, with literal property ids, as a pack written for a
// newer CMF would. Notice boards blue (3 = tint). Property 99 does not exist: the guarded call is
// skipped, and one unguarded call shows the rejection line.
// Version 2 (guarded by CMFHasProperty(8)): labels the vanilla Blacksmith row "CMF A" (7), declares
// tab cmfTestA_tab (8) and asks for the vanilla Shopkeeper row in it (6), which the panel must ignore,
// so the tab stays empty and never appears. Category 'Quests' is rejected (reason=vanilla), and a
// per-pin call with the legend icon property is rejected (reason=style). Per pin, notice boards whose
// pin id is even turn green through CMFStylePin.
// Version 3 (guarded by CMFHasProperty(9)): hides every pin when the map is opened from a signpost
// (level 0, context FastTravel), except quest pins and signposts; hides notice boards whose pin id is
// odd, per pin through CMFStylePin, so every board left is green; one hide claim with the unknown
// exemption "bogus" is rejected (reason=exemption), so armourers stay. Two empty tabs check the tab
// order in the log: cmfTestA_early (7) and cmfTestA_tie (8, the same number as Gear's wgm_gear).

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	var accepted : bool;
	var skipped : bool;
	var rejected : bool;
	var legend : bool;
	var vanillaRejected : bool;
	var styleRejected : bool;
	var hide : bool;
	var exemptionRejected : bool;
	result = wrappedMethod(restored);
	accepted = false;
	skipped = true;
	legend = false;
	vanillaRejected = false;
	styleRejected = false;
	hide = false;
	exemptionRejected = false;
	if (CMFHasProperty(3))
	{
		accepted = CMFRegister("modcmfTestCaseA", 3, 'NoticeBoard', '', "", 4210943);
		accepted = CMFRegister("modcmfTestCaseA", 3, 'NoticeBoardFull', '', "", 4210943) && accepted;
	}
	if (CMFHasProperty(99))
	{
		skipped = false;
		CMFRegister("modcmfTestCaseA", 99, 'NoticeBoard', '', "", 1);
	}
	rejected = !CMFRegister("modcmfTestCaseA", 99, 'NoticeBoard', '', "", 1);
	if (CMFHasProperty(8))
	{
		legend = CMFRegister("modcmfTestCaseA", 7, 'Blacksmith', '', "CMF A", 0);
		legend = CMFRegister("modcmfTestCaseA", 8, 'cmfTestA_tab', '', "CMF Test A", 5) && legend;
		legend = CMFRegister("modcmfTestCaseA", 6, 'Shopkeeper', '', "cmfTestA_tab", 0) && legend;
		vanillaRejected = !CMFRegister("modcmfTestCaseA", 8, 'Quests', '', "CMF Test A quests", 0);
		styleRejected = !CMFStylePin("modcmfTestCaseA", NULL, 2, "", 0);
		legend = CMFRegister("modcmfTestCaseA", 8, 'cmfTestA_early', '', "CMF Test A early", 7) && legend;
		legend = CMFRegister("modcmfTestCaseA", 8, 'cmfTestA_tie', '', "CMF Test A tie", 8) && legend;
	}
	if (CMFHasProperty(9))
	{
		hide = CMFRegister("modcmfTestCaseA", 9, '', 'FastTravel', "fasttravel,quest", 1);
		exemptionRejected = !CMFRegister("modcmfTestCaseA", 9, 'Armorer', '', "bogus", 1);
	}
	LogChannel('CMF', "CMF_TEST_CASEA tint3=" + CMFTestCaseAFlag(accepted) + " skipped99=" + CMFTestCaseAFlag(skipped) +
		" rejected99=" + CMFTestCaseAFlag(rejected) + " legend=" + CMFTestCaseAFlag(legend) + " rejectedVanilla=" +
		CMFTestCaseAFlag(vanillaRejected) + " rejectedStyle=" + CMFTestCaseAFlag(styleRejected) + " hide=" +
		CMFTestCaseAFlag(hide) + " rejectedExemption=" + CMFTestCaseAFlag(exemptionRejected));
	return result;
}

// Notice boards with an even pin id (the id the map panel uses) turn green, whatever the type tint;
// those with an odd pin id are hidden.
@wrapMethod(CR4MapMenu)
function AddPinTypeData(out dataObject : CScriptedFlashObject, targetPin : SCommonMapPinInstance) : void
{
	wrappedMethod(dataObject, targetPin);
	if ((targetPin.visibleType == 'NoticeBoard' || targetPin.visibleType == 'NoticeBoardFull') &&
		NameToFlashUInt(targetPin.tag) % 2 == 0)
	{
		CMFStylePinTint("modcmfTestCaseA", dataObject, 4259648);
	}
	else if ((targetPin.visibleType == 'NoticeBoard' || targetPin.visibleType == 'NoticeBoardFull') &&
		CMFHasProperty(9))
	{
		CMFStylePin("modcmfTestCaseA", dataObject, 9, "", 1);
	}
}

function CMFTestCaseAFlag(value : bool) : string
{
	if (value)
	{
		return "1";
	}
	return "0";
}
