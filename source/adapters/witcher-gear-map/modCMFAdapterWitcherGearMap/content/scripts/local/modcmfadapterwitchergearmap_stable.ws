// Witcher Gear Map adapter: its markers when another mod takes over CR4MapMenu.UpdateEntityPins.
//
// The Stable 2.2.1 ships a precompiled CR4MapMenu.UpdateEntityPins of its own, and while it is
// installed Witcher Gear Map's UpdateEntityPins wrapper never runs, so its markers never reach the map
// (final matrix launches M1 and M1c, 2026-10-21). CMF's UpdateUserMapPins wrapper still runs. This
// wrapper on the same method checks, before the game adds the user pins, whether the list already
// holds a WitcherGear marker. Only when it holds none does it ask Witcher Gear Map for its markers,
// the way that mod's own wrapper does: its saved data, its options, the diagrams the player knows, its
// journal checks, its texts and its pin ids. Nothing of Witcher Gear Map is stored here; without that
// mod this file does not compile, and with its wrapper running this adds nothing.

@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	if (indexToUpdate < 0 && !WgmAdapterHasMarkers(flashArray))
	{
		WgmAdapterAddMarkers(flashArray);
	}
	wrappedMethod(flashArray, indexToUpdate);
}

function WgmAdapterHasMarkers(flashArray : CScriptedFlashArray) : bool
{
	var i : int;
	// Wrappers append their pins, so the markers sit near the end when they are there.
	for (i = flashArray.GetLength() - 1; i >= 0; i -= 1)
	{
		if (flashArray.GetElementFlashObject(i).GetMemberFlashString("filteredType") == "WitcherGear")
		{
			return true;
		}
	}
	return false;
}

// Witcher Gear Map's markers for the shown map, with its own filters, states and texts.
@addMethod(CR4MapMenu)
function WgmAdapterAddMarkers(out flashArray : CScriptedFlashArray)
{
	var data : wgm_Data;
	var mapManager : CCommonMapManager;
	var player : W3PlayerWitcher;
	var known : array<name>;
	var worldKey : string;
	var school : int;
	var tier : int;
	var iconStyle : int;
	var hideObtained : bool;
	var newGamePlus : bool;
	var discoveredOnly : bool;
	var discovered : bool;
	var obtained : bool;
	var allObtained : bool;
	var plainInNgp : bool;
	var shown : int;
	var pinSchool : int;
	var item : wgm_Item;
	var title : string;
	var description : string;
	var pinType : string;
	var pos : Vector;
	var playerPos : Vector;
	var obj : CScriptedFlashObject;
	var i : int;
	var j : int;

	if (!wgm_ConfigBool('wgm_ShowPins', true))
	{
		return;
	}
	player = (W3PlayerWitcher)thePlayer;
	if (!player)
	{
		return;
	}
	data = theGame.wgm_GetData();
	known = player.GetCraftingSchematicsNames();
	mapManager = theGame.GetCommonMapManager();
	worldKey = wgm_WorldKey(mapManager.GetWorldPathFromAreaType(m_shownArea));
	if (worldKey == "")
	{
		return;
	}
	school = wgm_ConfigInt('wgm_School');
	tier = wgm_ConfigInt('wgm_Tier');
	iconStyle = wgm_ConfigInt('wgm_IconStyle');
	hideObtained = wgm_ConfigBool('wgm_HideObtained', false);
	newGamePlus = FactsQuerySum("NewGamePlus") > 0;
	discoveredOnly = wgm_ConfigInt('wgm_ShowMode') == 0;
	playerPos = player.GetWorldPosition();

	for (i = 0; i < data.pins.Size(); i += 1)
	{
		if (data.pins[i].world != worldKey)
		{
			continue;
		}
		description = "";
		shown = 0;
		allObtained = true;
		plainInNgp = false;
		discovered = !discoveredOnly || wgm_Discovered(data.pins[i]);
		for (j = 0; j < data.pins[i].items.Size(); j += 1)
		{
			item = data.pins[i].items[j];
			if ((item.tier == 5 && !theGame.GetDLCManager().IsEP2Available()) || (item.tier == 6 && !theGame.GetDLCManager().IsEP1Available()))
			{
				continue;
			}
			if ((school != 0 && school != item.school) || (tier != 0 && tier != item.tier))
			{
				continue;
			}
			obtained = known.Contains(wgm_SchematicName(item));
			if (hideObtained && obtained)
			{
				continue;
			}
			if (!discovered && !obtained)
			{
				continue;
			}
			if (shown == 0)
			{
				title = wgm_MarkerTitle(item);
				pinSchool = item.school;
				if (newGamePlus && IsNameValid(item.ngpSchematic))
				{
					title += " (" + wgm_Loc("wgm_legendary", "Legendary") + ")";
				}
			}
			else
			{
				description += "<br>";
			}
			plainInNgp = plainInNgp || (newGamePlus && !IsNameValid(item.ngpSchematic));
			allObtained = allObtained && obtained;
			description += wgm_DiagramName(player, item) + " - ";
			if (obtained)
			{
				description += wgm_Loc("wgm_obtained", "Diagram learned.");
			}
			else
			{
				description += wgm_Loc("wgm_not_obtained", "Diagram not learned yet.");
			}
			shown += 1;
		}
		if (shown == 0)
		{
			continue;
		}
		if (plainInNgp)
		{
			description += "<br>" + wgm_Loc("wgm_note_ngp_crafted", "New Game+: the crafted item is Legendary.");
		}
		description += "<br>" + wgm_Loc(data.pins[i].hintKey, data.pins[i].hintEnglish);
		pinType = "WitcherGear";
		if (allObtained)
		{
			pinType = "WitcherGearObtained";
		}
		pinType += wgm_IconSuffix(pinSchool);
		if (iconStyle == 1)
		{
			pinType += "Ring";
		}
		if (shown > 1)
		{
			title += " (+" + (shown - 1) + ")";
		}

		pos = Vector(data.pins[i].x, data.pins[i].y, 0);
		obj = GetMenuFlashValueStorage().CreateTempFlashObject("red.game.witcher3.data.StaticMapPinData");
		// Witcher Gear Map's own pin id: its offset plus its marker id.
		obj.SetMemberFlashUInt("id", 1464287232 + data.pins[i].id);
		obj.SetMemberFlashUInt("areaId", NameToFlashUInt(m_shownArea));
		obj.SetMemberFlashUInt("journalAreaId", NameToFlashUInt(mapManager.GetJournalAreaByPosition(m_shownArea, pos)));
		obj.SetMemberFlashNumber("posX", pos.X);
		obj.SetMemberFlashNumber("posY", pos.Y);
		obj.SetMemberFlashString("type", pinType);
		obj.SetMemberFlashString("filteredType", "WitcherGear");
		obj.SetMemberFlashNumber("radius", 0);
		obj.SetMemberFlashBool("isFastTravel", false);
		obj.SetMemberFlashBool("isQuest", false);
		obj.SetMemberFlashBool("isPlayer", false);
		obj.SetMemberFlashBool("isUserPin", false);
		if (IsCurrentAreaShown())
		{
			obj.SetMemberFlashNumber("distance", VecDistanceSquared2D(playerPos, pos));
		}
		else
		{
			obj.SetMemberFlashNumber("distance", 0);
		}
		obj.SetMemberFlashString("label", title);
		obj.SetMemberFlashString("description", description);
		flashArray.PushBackFlashObject(obj);
	}
}
