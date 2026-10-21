// The Stable adapter for Conjunction Map Framework. Requires CMF 2 or later and The Stable - Roach-Horse
// Customization Mod 2.2.1 (Nexus 6132), which stays unchanged. This file calls only CMF, so it compiles
// without The Stable; it asks for the row only when The Stable's own text is in the game (its dlc folder
// ships map_location_arddhustable), so without The Stable it adds nothing. Install and remove the two together.
//
// The Stable's stable masters are the game's own Stables pins, drawn with the game's own Stables frame; its
// own scripts give them their names and descriptions. Its copy of the world map file differs from the
// game's in one line of HubMapPinPanel: the Stables row under NPCs at priority 516 ("Added the stable map
// pin to the map pin filters, in the merchants section", its 2.0 changelog). Under CMF its map file does
// not load (CMF's map sorts first), so the pins still draw but have no row to show or hide them by. This
// adapter asks CMF for that row with CMF's general call, as The Stable's author would when porting.
//
// The claim uses The Stable's own folder name as its provider, so folder order between mods is the same
// with CMF as without it: Community Patch - World Map's adapter makes the same claim with the same value
// and, its folder sorting first, wins it, as Community Patch's map file wins over The Stable's without CMF.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (StableAdapterModPresent() && CMFRequireVersion("modArdDhuStable", 2))
	{
		// CMF 2 legend row (property id 6): the game's Stables pins join NPCs at The Stable's priority.
		// Stables has no row in the game's own legend, so CMF may place it.
		CMFRegister("modArdDhuStable", 6, 'Stables', '', "NPCs", 516);
	}
	return result;
}

// The Stable's scripts ship precompiled, so nothing of it can be called to tie this file to it. Its own
// text key is the test: the game returns "" or a "#" placeholder for a key no installed string table has.
function StableAdapterModPresent() : bool
{
	var text : string;
	text = GetLocStringByKeyExt("map_location_arddhustable");
	return StrLen(text) > 0 && !StrBeginsWith(text, "#");
}
