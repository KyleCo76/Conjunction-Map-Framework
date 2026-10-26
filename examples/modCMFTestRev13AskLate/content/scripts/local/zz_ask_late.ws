// Standalone append-list source input for the controller-owned fixture build.
// UpdateUserMapPins runs on the full list even when a REDkit-compiled mod (Ard Dhu Stable) carries its own
// CR4MapMenu.UpdateEntityPins and so skips every UpdateEntityPins wrapper. The zz_ name sorts after cmfCore.ws:
// this wrapper runs outside CMF's, so it writes before calling the game, and CMF reads the asks after.
@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	var dataObject : CScriptedFlashObject;
	var providers : string;
	var i : int;
	if (indexToUpdate < 0)
	{
		for (i = 0; i < flashArray.GetLength(); i += 1)
		{
			dataObject = flashArray.GetElementFlashObject(i);
			if (!dataObject || dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin")) { continue; }
			if (dataObject.GetMemberFlashString("type") != "Boat") { continue; }
			providers = dataObject.GetMemberFlashString("cmfAskBy");
			if (StrFindFirst("," + StrLower(providers) + ",", ",modcmftestrev13asklate,") < 0)
			{
				if (providers != "") { providers += ","; }
				providers += "modCMFTestRev13AskLate";
				dataObject.SetMemberFlashString("cmfAskBy", providers);
			}
			dataObject.SetMemberFlashString("cmfAskIcon_modCMFTestRev13AskLate", "img://icons/modcmftestrev13asklate/ask.png");
			dataObject.SetMemberFlashString("cmfAskTint_modCMFTestRev13AskLate", "16777215");
		}
	}
	wrappedMethod(flashArray, indexToUpdate);
}
