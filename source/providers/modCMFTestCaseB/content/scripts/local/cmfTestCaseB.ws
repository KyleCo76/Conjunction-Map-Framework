// TEST ONLY: folder-order and failed-image probe pack (provider modCMFTestCaseB).
// Notice boards red. Its folder sorts before modcmfTestCaseA only when capital letters count,
// so with case-insensitive order modcmfTestCaseA's blue wins. Blacksmiths point at an image
// that does not exist, so the map keeps the stock icon and CMF logs "art failed".
// Version 2: labels the Blacksmith row "CMF B", which loses to modcmfTestCaseA's "CMF A" by folder
// order. Per pin, every notice board turns magenta through CMFStylePin; this file sorts after
// cmfTestCaseA.ws, so its wrapper runs last, and the boards modcmfTestCaseA already styled stay green.
// Version 3: hides the pin tagged seven_cats_noticeboard on maps opened with M (tag level, context
// GlobalMap), which wins although this folder loses every other conflict; hides herbalists and then
// withdraws that claim, so herbalists stay; and asks to hide the first notice board after CMF has
// already sent the list (this file sorts after cmfCore.ws, so its UpdateUserMapPins wrapper runs
// after CMF's), which is rejected (reason=late), so that board stays.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestCaseB", 1))
	{
		CMFRegisterTint("modCMFTestCaseB", 'NoticeBoard', 16728128);
		CMFRegisterTint("modCMFTestCaseB", 'NoticeBoardFull', 16728128);
		CMFRegisterIcon("modCMFTestCaseB", 'Blacksmith', "img://icons/modcmftestcaseb/missing.png");
	}
	if (CMFRequireVersion("modCMFTestCaseB", 2))
	{
		CMFRegisterLegendLabel("modCMFTestCaseB", 'Blacksmith', "CMF B");
	}
	if (CMFRequireVersion("modCMFTestCaseB", 3))
	{
		CMFRegisterHiddenForTag("modCMFTestCaseB", 'seven_cats_noticeboard', 'GlobalMap', "", true);
		CMFRegisterHidden("modCMFTestCaseB", 'Herbalist', '', "", true);
		CMFRegisterHidden("modCMFTestCaseB", 'Herbalist', '', "", false);
	}
	return result;
}

@wrapMethod(CR4MapMenu)
function AddPinTypeData(out dataObject : CScriptedFlashObject, targetPin : SCommonMapPinInstance) : void
{
	wrappedMethod(dataObject, targetPin);
	if (targetPin.visibleType == 'NoticeBoard' || targetPin.visibleType == 'NoticeBoardFull')
	{
		CMFStylePinTint("modCMFTestCaseB", dataObject, 16728319);
	}
}

// Too late on purpose: CMF's late pass has already removed the hidden pins and closed the list.
@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	var dataObject : CScriptedFlashObject;
	var i : int;
	var hidden : bool;
	wrappedMethod(flashArray, indexToUpdate);
	if (indexToUpdate >= 0 || !flashArray || !CMFHasProperty(9))
	{
		return;
	}
	for (i = 0; i < flashArray.GetLength(); i += 1)
	{
		dataObject = flashArray.GetElementFlashObject(i);
		if (dataObject && StrBeginsWith(dataObject.GetMemberFlashString("type"), "NoticeBoard"))
		{
			hidden = CMFHidePin("modCMFTestCaseB", dataObject);
			if (hidden)
			{
				LogChannel('CMF', "CMF_TEST_CASEB latehide=1");
			}
			else
			{
				LogChannel('CMF', "CMF_TEST_CASEB latehide=0");
			}
			return;
		}
	}
}
