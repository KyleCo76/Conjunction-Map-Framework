// Gwent Players Map adapter: its cards when another mod takes over CR4MapMenu.UpdateEntityPins.
//
// The Stable 2.2.1 ships a precompiled CR4MapMenu.UpdateEntityPins of its own, and while it is
// installed Gwent Players Map's UpdateEntityPins wrapper never runs, so its cards never reach the map
// (final matrix launches M1 and M1c, 2026-10-21). CMF's UpdateUserMapPins wrapper still runs. This
// wrapper on the same method checks, before the game adds the user pins, whether the list already
// holds a GwentPlayer card. Only when it holds none does it ask Gwent Players Map for its cards, the
// way that mod's own wrapper does: its saved data, its options, its world keys, its shop list, its
// texts and its pin ids. Nothing of Gwent Players Map is stored here; without that mod this file
// does not compile, and with its wrapper running this adds nothing.

@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	if (indexToUpdate < 0 && !GwmAdapterHasCards(flashArray))
	{
		GwmAdapterAddCards(flashArray);
	}
	wrappedMethod(flashArray, indexToUpdate);
}

function GwmAdapterHasCards(flashArray : CScriptedFlashArray) : bool
{
	var i : int;
	// Wrappers append their pins, so the cards sit near the end when they are there.
	for (i = flashArray.GetLength() - 1; i >= 0; i -= 1)
	{
		if (flashArray.GetElementFlashObject(i).GetMemberFlashString("filteredType") == "GwentPlayer")
		{
			return true;
		}
	}
	return false;
}

// Gwent Players Map's cards for the shown map, with its own options, positions and texts.
@addMethod(CR4MapMenu)
function GwmAdapterAddCards(out flashArray : CScriptedFlashArray)
{
	var data : GwmData;
	var mapManager : CCommonMapManager;
	var worldPath : string;
	var worldKey : string;
	var instances : array<SCommonMapPinInstance>;
	var shopPos : array<Vector>;
	var shopUses : array<int>;
	var largeCards : bool;
	var showDefeated : bool;
	var showSellers : bool;
	var greyed : bool;
	var defeated : bool;
	var unavailable : bool;
	var playerPos : Vector;
	var pos : Vector;
	var pinType : string;
	var description : string;
	var obj : CScriptedFlashObject;
	var nearest : int;
	var bestDist : float;
	var dist : float;
	var i : int;
	var k : int;

	if (!GwmConfigBool('GwmShowPins', true))
	{
		return;
	}
	data = GwmGetData();
	mapManager = theGame.GetCommonMapManager();
	worldPath = mapManager.GetWorldPathFromAreaType(m_shownArea);
	worldKey = GwmWorldKey(worldPath);
	if (worldKey == "")
	{
		return;
	}
	largeCards = theGame.GetInGameConfigWrapper().GetVarValue('GwentPlayersMap', 'GwmCardSize') == "1";
	showDefeated = GwmConfigBool('GwmShowDefeated', true);
	showSellers = GwmConfigBool('GwmShowSellers', false);

	// Outside its "Gwent" tab a merchant's card stands beside the shop icon the map shows.
	instances = mapManager.GetMapPinInstances(worldPath);
	for (i = 0; i < instances.Size(); i += 1)
	{
		if ((instances[i].isDiscovered || instances[i].isKnown) && GwmIsShopPinType(instances[i].type))
		{
			shopPos.PushBack(instances[i].position);
			shopUses.PushBack(0);
		}
	}

	playerPos = thePlayer.GetWorldPosition();
	for (i = 0; i < data.pins.Size(); i += 1)
	{
		if (data.pins[i].world != worldKey)
		{
			continue;
		}
		defeated = data.IsDefeated(i);
		unavailable = !defeated && data.IsUnavailable(i);
		greyed = defeated || unavailable;
		if (greyed && !showDefeated)
		{
			continue;
		}
		if (greyed && largeCards)
		{
			pinType = "GwentPlayerLargeDisabled";
		}
		else if (greyed)
		{
			pinType = data.iconDefeated;
		}
		else if (largeCards)
		{
			pinType = "GwentPlayerLarge";
		}
		else
		{
			pinType = data.iconNormal;
		}

		pos = Vector(data.pins[i].x, data.pins[i].y, 0);
		nearest = -1;
		if (IsNameValid(data.pins[i].tag) && !data.gwentFilter)
		{
			bestDist = 900;
			for (k = 0; k < shopPos.Size(); k += 1)
			{
				dist = VecDistanceSquared2D(pos, shopPos[k]);
				if (dist < bestDist)
				{
					bestDist = dist;
					nearest = k;
				}
			}
		}
		if (nearest >= 0)
		{
			pos = shopPos[nearest];
			pos.X += GwmSideOffset() * (shopUses[nearest] + 1);
			shopUses[nearest] += 1;
		}

		description = GwmRoleText(data.pins[i]) + " - " + GwmStatusText(data.pins[i], defeated, unavailable)
			+ GwmNoteText(data.pins[i]) + GwmSellerText(showSellers && !unavailable && data.SellsCardsYouLack(i));

		obj = GetMenuFlashValueStorage().CreateTempFlashObject("red.game.witcher3.data.StaticMapPinData");
		// Gwent Players Map's own pin id: its offset plus its player id.
		obj.SetMemberFlashUInt("id", 1196883968 + data.pins[i].id);
		obj.SetMemberFlashUInt("areaId", NameToFlashUInt(m_shownArea));
		obj.SetMemberFlashUInt("journalAreaId", NameToFlashUInt(mapManager.GetJournalAreaByPosition(m_shownArea, pos)));
		obj.SetMemberFlashNumber("posX", pos.X);
		obj.SetMemberFlashNumber("posY", pos.Y);
		obj.SetMemberFlashString("type", pinType);
		obj.SetMemberFlashString("filteredType", "GwentPlayer");
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
		obj.SetMemberFlashString("label", GwmLoc("gwm_label_gwent_player", "Gwent player"));
		obj.SetMemberFlashString("description", description);
		flashArray.PushBackFlashObject(obj);
	}
}
