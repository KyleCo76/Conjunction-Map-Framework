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

@wrapMethod(CR4MapMenu)
function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void
{
	var start : int;
	var i : int;
	var k : int;
	var asked : int;
	var hiddenCount : int;
	var marked : int;
	var logged : int;
	var dropped : bool;
	var pin : CScriptedFlashObject;
	var marker : CScriptedFlashObject;
	var scratch : CScriptedFlashArray;
	var candidates : array<int>;
	var outcome : string;
	start = flashArray.GetLength();
	wrappedMethod(flashArray);
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
	k = 0;
	hiddenCount = 0;
	marked = 0;
	logged = 0;
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
			outcome = "refused";
			if (CMFStylePin("modFogOfWar", pin, 9, "", 1))
			{
				marked += 1;
				outcome = "marked";
			}
			// Launch evidence: the first eight pins of each build that the fog hides here.
			if (logged < 8)
			{
				logged += 1;
				LogChannel('CMF', "CMF adapter provider=modFogOfWar type=" +
					pin.GetMemberFlashString("type") + " hidden=1 result=" + outcome);
			}
		}
		k += 1;
		dropped = true;
	}
	LogChannel('CMF', "CMF adapter provider=modFogOfWar area=" + NameToString(GetShownMapType()) +
		" asked=" + asked + " hidden=" + hiddenCount + " marked=" + marked);
}
