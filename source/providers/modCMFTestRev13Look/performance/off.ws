// Isolated final-list fixture. aa_ filename targets inside the core late wrapper.
// Native player/user additions have finished; CMF late processing remains outside.
function Rev13PerformanceAsks() : bool
{
	return false; // only off/on variant difference
}

@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	var storage : CScriptedFlashValueStorage;
	var dataObject : CScriptedFlashObject;
	var i : int;
	wrappedMethod(flashArray, indexToUpdate);
	if (indexToUpdate >= 0) { return; }
	storage = GetMenuFlashValueStorage();
	if (!storage || !flashArray) { return; }
	flashArray.ClearElements();
	for (i = 0; i < 1800; i += 1)
	{
		dataObject = storage.CreateTempFlashObject("red.game.witcher3.data.StaticMapPinData");
		dataObject.SetMemberFlashUInt("id", 100000 + i);
		dataObject.SetMemberFlashUInt("areaId", NameToFlashUInt(m_shownArea));
		dataObject.SetMemberFlashUInt("journalAreaId", NameToFlashUInt(m_shownArea));
		dataObject.SetMemberFlashString("type", "Boat");
		dataObject.SetMemberFlashString("filteredType", "Boat");
		dataObject.SetMemberFlashInt("posX", (i % 60) * 50);
		dataObject.SetMemberFlashInt("posY", (i / 60) * 50);
		dataObject.SetMemberFlashBool("isPlayer", false);
		dataObject.SetMemberFlashBool("isUserPin", false);
		dataObject.SetMemberFlashBool("isQuest", false);
		dataObject.SetMemberFlashBool("isFastTravel", false);
		if (Rev13PerformanceAsks())
		{
			dataObject.SetMemberFlashString("cmfAskBy", "modCMFTestRev13Performance");
			dataObject.SetMemberFlashString("cmfAskTint_modCMFTestRev13Performance", "16744448");
		}
		flashArray.PushBackFlashObject(dataObject);
	}
	if (Rev13PerformanceAsks()) { LogChannel('CMF', "CMF rev13 performance pins=" + flashArray.GetLength() + " asks=on"); }
	else { LogChannel('CMF', "CMF rev13 performance pins=" + flashArray.GetLength() + " asks=off"); }
}
