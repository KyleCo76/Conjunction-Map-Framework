// Witcher Gear Map adapter: Gear Map's markers over the fog while its Show Diagrams option is All.
//
// Without CMF, Fog of War's filter never sees Gear Map's markers (wgm.ws sorts after modFogOfWarMap.ws), so
// they show over its fog. Fog of War's adapter for CMF hides every pin under the fog, Gear Map's included.
// With Gear Map's own Show Diagrams option on All (wgm_ShowMode not 0), the player asked to see every
// diagram, so this wrapper marks each Gear Map marker kept over the fog (CMFGridKeepPin, CMF 1.7.0 or
// later): Fog of War's adapter 1.1.3 or later then leaves it, and so does any grid drawing's hidePins rule.
// With Discovered (0) nothing is marked and the fog hides the markers as before.
//
// The file name starts with z_ so it sorts after wgm.ws and before Fog of War's adapter
// (zz_modcmfadapterfogofwar_cmf.ws): wrappers nest by script file name, so Gear Map's markers are already in
// the list here, and the marks are set before Fog of War's adapter asks about them. It calls Gear Map's own
// wgm_ConfigInt, like modcmfadapterwitchergearmap_stable.ws.

@wrapMethod(CR4MapMenu)
function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void
{
	var start : int;
	start = flashArray.GetLength();
	wrappedMethod(flashArray);
	WgmAdapterKeepOverFog(flashArray, start);
}

// Marks Gear Map's markers from start on kept over the fog, only while Show Diagrams is All. Returns how many.
// A map menu method, as the Stable fallback's WgmAdapterAddMarkers, since it reads Gear Map's option.
@addMethod(CR4MapMenu)
function WgmAdapterKeepOverFog(flashArray : CScriptedFlashArray, start : int) : int
{
	var pin : CScriptedFlashObject;
	var kept : int;
	var i : int;
	if (!CMFHasAbility('grid', 'hidePins') || wgm_ConfigInt('wgm_ShowMode') == 0)
	{
		return 0;
	}
	for (i = start; i < flashArray.GetLength(); i += 1)
	{
		pin = flashArray.GetElementFlashObject(i);
		if (pin && pin.GetMemberFlashString("filteredType") == "WitcherGear" && CMFGridKeepPin("modWitcherGearMap", pin))
		{
			kept += 1;
		}
	}
	// One line per map build while it keeps any, for the launch check.
	if (kept > 0)
	{
		LogChannel('CMF', "CMF adapter provider=modWitcherGearMap kept over fog=" + kept);
	}
	return kept;
}
