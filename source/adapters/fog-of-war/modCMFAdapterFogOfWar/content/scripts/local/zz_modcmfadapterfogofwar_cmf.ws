// Fog of War adapter for Conjunction Map Framework. Requires Fog of War 1.2.1 (Nexus 13627), which
// stays unchanged, and hides pins only with CMF 3 or later. Install and remove the two together: this
// file calls Fog of War's own functions, so the game stops at the script compile screen when Fog of War
// is missing.
//
// Fog of War hides map pins under its fog by removing them from the pin list in its UpdateEntityPins
// wrapper. That wrapper only filters the pins added inside it, so pins another mod pushes from a wrapper
// whose script file sorts after modFogOfWarMap.ws (Witcher Gear Map's wgm.ws) show through the fog.
// This adapter asks Fog of War's own filter, with its own rule and settings, about every pin in the
// finished entity list, and hands each pin the filter drops to CMF as a hide (property 9), which CMF
// removes in its late pass. It ships no art and copies no code.
//
// The file name starts with zz_ so it sorts after modFogOfWarMap.ws, questMapInfo.ws and wgm.ws:
// wrappers nest by script file name, so this wrapper is outermost and sees every pushed pin.
//
// 1.0.3: a mod that ships CR4MapMenu.UpdateEntityPins precompiled (The Stable 2.2.1 in Ard Dhu Stable) skips
// every loose wrapper on it, Fog of War's own filter and this adapter's alike, so pins under the fog showed.
// The game's UpdateData builds one list: UpdateEntityPins, the player pin, then UpdateUserMapPins(list, -1).
// When the entity wrapper did not run in this build, the UpdateUserMapPins wrapper asks Fog of War about
// every pin already in the list, before CMF's late pass, and logs the same line with step=fallback. One
// question per build either way.
//
// 1.1.0 (CMF API 14, grid drawings): Fog of War's fog itself, in its "cloud textures off" look, on CMF's map. Each
// full build, the UpdateUserMapPins wrapper reads the shown area's explored grid with Fog of War's own functions
// (after its filter ran, so the grid is current) and its colour, opacity and edge detail, and hands them to CMF as
// one map-space grid drawing under the pins; Fog of War switched off withdraws it. With cloud textures on, the dark
// fog is drawn too, until CMF has cloud art. It never reads Fog of War's own map key (worldmap.fogofwar).
//
// 1.1.1 (launch fog5): pins another mod pushes after this wrapper asked Fog of War (Gwent Players Map's cards) showed
// over the fog. The fog drawing now asks CMF to hide every pin on a covered cell (hidePins), and each pin Fog of War's
// filter saw and kept is marked kept (CMFGridKeepPin), so its exemptions stay: the tracked quest, known signposts,
// in-world hints and places revealed from afar.

// Presence is independent of map settings; the existing source-mod compile dependency stays required.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFHasProperty(38))
	{
		CMFRegister("modFogOfWar", 38, '', '', "", 1);
	}
	return result;
}

// Set by the entity wrapper or the fallback in each map build, so Fog of War is asked once.
@addField(CR4MapMenu) var fowAdapterAsked : bool;

// A full map build starts here; this wrapper sorts after CMF's, so it is the outermost.
@wrapMethod(CR4MapMenu)
function UpdateData(optional ignoreSelectionChange : bool)
{
	fowAdapterAsked = false;
	wrappedMethod(ignoreSelectionChange);
}

@wrapMethod(CR4MapMenu)
function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void
{
	var start : int;
	start = flashArray.GetLength();
	wrappedMethod(flashArray);
	fowAdapterAsked = true;
	FowAdapterHidePins(flashArray, start, "");
}

// The fallback: only in a full build (indexToUpdate -1) whose entity wrapper did not run, and before
// wrappedMethod, so the hides reach CMF's late pass inside it. The list holds the entity pins and the
// player pin here; the user's own pins come after.
@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	if (indexToUpdate < 0 && !fowAdapterAsked)
	{
		fowAdapterAsked = true;
		FowAdapterHidePins(flashArray, 0, " step=fallback");
	}
	if (indexToUpdate < 0)
	{
		FowAdapterSendFog();
	}
	wrappedMethod(flashArray, indexToUpdate);
}

// The shown area's fog as one CMF grid drawing: a cell's bit set means explored (left clear), as in Fog of War's
// own data; only the words with a set bit go. CMF sends it to the map after this build's OnMapReady.
@addMethod(CR4MapMenu)
function FowAdapterSendFog()
{
	var data : CFogOfWarData;
	var grid : CFogOfWarArea;
	var area : name;
	var idx : array<int>;
	var words : array<int>;
	var i : int;
	if (!CMFHasAbility('grid', 'bits'))
	{
		return;
	}
	area = GetShownMapType();
	data = FogOfWarGetData();
	if (IsNameValid(area) && data && FogOfWarEnabled())
	{
		grid = data.GetArea(area, true);
	}
	if (!grid || grid.n <= 0)
	{
		CMFDraw("modFogOfWar", 'mapSpace', 'modFogOfWar.fog', '');
		return;
	}
	for (i = 0; i < grid.words.Size(); i += 1)
	{
		if (grid.words[i] != 0)
		{
			idx.PushBack(i);
			words.PushBack(grid.words[i]);
		}
	}
	CMFDraw("modFogOfWar", 'mapSpace', 'modFogOfWar.fog', 'grid');
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'area', NameToString(area), 0);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'layer', "under", 0);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'n', "", grid.n);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'left', "", -grid.mapSize / 2);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'top', "", grid.mapSize / 2);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'span', "", grid.mapSize);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'fill', "", FogOfWarColor());
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'alpha', "", FogOfWarOpacity());
	// Fog of War fades its edge over 15 cells (FOW_FADE_MAX) in its edge-detail bands, and fades in over 250 ms.
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'soft', "", 15);
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'steps', "", FogOfWarEdgeDetail());
	CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'fadeMs', "", 250);
	if (CMFHasAbility('grid', 'hidePins'))
	{
		CMFDrawSet("modFogOfWar", 'modFogOfWar.fog', 'hidePins', "", 1);
	}
	CMFDrawSetBits("modFogOfWar", 'modFogOfWar.fog', idx, words);
}

// Asks Fog of War's own filter about the pins from start on and hides each one it drops through CMF.
@addMethod(CR4MapMenu)
function FowAdapterHidePins(flashArray : CScriptedFlashArray, start : int, step : string)
{
	var i : int;
	var k : int;
	var asked : int;
	var hiddenCount : int;
	var marked : int;
	var dropped : bool;
	var keep : bool;
	var pin : CScriptedFlashObject;
	var marker : CScriptedFlashObject;
	var scratch : CScriptedFlashArray;
	var candidates : array<int>;
	// CMF 2 has no hide property; Fog of War switched off in its menu hides nothing.
	if (!CMFHasProperty(9) || !FogOfWarEnabled())
	{
		return;
	}
	// One scratch list per map build, so Fog of War's filter runs once (it ticks its recorder and logs
	// one line per call). Every pin is followed by one shared marker object that the filter always keeps
	// (a known travel point), so a marker with no pin right before it means the filter dropped that pin.
	scratch = m_flashValueStorage.CreateTempFlashArray();
	marker = m_flashValueStorage.CreateTempFlashObject();
	marker.SetMemberFlashBool("fowAdapterMarker", true);
	marker.SetMemberFlashBool("isFastTravel", true);
	marker.SetMemberFlashString("filteredType", "");
	for (i = start; i < flashArray.GetLength(); i += 1)
	{
		pin = flashArray.GetElementFlashObject(i);
		if (!pin || pin.GetMemberFlashBool("isPlayer") || pin.GetMemberFlashBool("isUserPin"))
		{
			continue;
		}
		candidates.PushBack(i);
		scratch.PushBackFlashObject(pin);
		scratch.PushBackFlashObject(marker);
	}
	asked = candidates.Size();
	if (asked == 0)
	{
		return;
	}
	// Fog of War's own decision: explored cells, its reach, and its exemptions for the tracked quest,
	// known travel points, in-world hints and places revealed from afar.
	FogOfWarFilterPins(scratch, 0);
	keep = CMFHasAbility('grid', 'hidePins');
	k = 0;
	hiddenCount = 0;
	marked = 0;
	dropped = true;
	for (i = 0; i < scratch.GetLength() && k < asked; i += 1)
	{
		pin = scratch.GetElementFlashObject(i);
		if (!pin || !pin.GetMemberFlashBool("fowAdapterMarker"))
		{
			dropped = false;
			continue;
		}
		if (dropped)
		{
			pin = flashArray.GetElementFlashObject(candidates[k]);
			hiddenCount += 1;
			// The one CMF 3 entry this adapter depends on (Stage 1 spec, section 7.1): hide this pin.
			if (CMFStylePin("modFogOfWar", pin, 9, "", 1))
			{
				marked += 1;
			}
		}
		else if (keep)
		{
			// Fog of War showed it: the fog drawing's hidePins rule leaves it.
			CMFGridKeepPin("modFogOfWar", flashArray.GetElementFlashObject(candidates[k]));
		}
		k += 1;
		dropped = true;
	}
	LogChannel('CMF', "CMF adapter provider=modFogOfWar area=" + NameToString(GetShownMapType()) +
		" asked=" + asked + " hidden=" + hiddenCount + " marked=" + marked + step);
}
