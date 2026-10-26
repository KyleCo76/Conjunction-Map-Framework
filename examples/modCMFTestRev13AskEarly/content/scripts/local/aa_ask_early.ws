// Standalone append-list source input for the controller-owned fixture build.
// UpdateUserMapPins runs on the full list even when a REDkit-compiled mod (Ard Dhu Stable) carries its own
// CR4MapMenu.UpdateEntityPins and so skips every UpdateEntityPins wrapper. The aa_ name sorts before cmfCore.ws:
// this wrapper runs inside CMF's, writing after the game's user pins and before CMF reads the asks.
@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	var dataObject : CScriptedFlashObject;
	var providers : string;
	var i : int;
	wrappedMethod(flashArray, indexToUpdate);
	if (indexToUpdate >= 0) { return; }
	for (i = 0; i < flashArray.GetLength(); i += 1)
	{
		dataObject = flashArray.GetElementFlashObject(i);
		if (!dataObject || dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin")) { continue; }
		if (dataObject.GetMemberFlashString("type") != "Boat") { continue; }
		providers = dataObject.GetMemberFlashString("cmfAskBy");
		if (StrFindFirst("," + StrLower(providers) + ",", ",modcmftestrev13askearly,") < 0)
		{
			if (providers != "") { providers += ","; }
			providers += "modCMFTestRev13AskEarly";
			dataObject.SetMemberFlashString("cmfAskBy", providers);
		}
		dataObject.SetMemberFlashString("cmfAskIcon_modCMFTestRev13AskEarly", "img://icons/modcmftestrev13askearly/ask.png");
		dataObject.SetMemberFlashString("cmfAskTint_modCMFTestRev13AskEarly", "0");
	}
}
