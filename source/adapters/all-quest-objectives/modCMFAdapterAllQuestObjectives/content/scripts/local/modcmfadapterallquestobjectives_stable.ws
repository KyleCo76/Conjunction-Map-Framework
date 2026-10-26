// All Quest Objectives adapter: its map work when another mod takes over CR4MapMenu.UpdateEntityPins.
//
// The Stable 2.2.1 ships a precompiled CR4MapMenu.UpdateEntityPins of its own, and while it is
// installed All Quest Objectives' UpdateEntityPins wrapper (aqoomMapHooks.ws) never runs, so its
// difficulty icons, suggested levels, row label and cached merchant pins never reach the map (Show
// Chests starts A and D, 2026-10-25: no icon lines with The Stable in, two without). The game's
// UpdateUserMapPins still runs next with the same list. This wrapper on it asks All Quest Objectives
// to do that work, through the same public call and with the same three arguments its own hook uses,
// only when that call has not run during this build.
//
// All Quest Objectives changes pins already in the list (the level text on every quest pin), so a
// look at the list cannot tell whether it ran. A wrapper on its own AqoomMap.UpdateEntityPins, which
// The Stable does not touch, records each run instead. Without The Stable its hook runs first and
// this adds nothing.
//
// The file name sorts after cmfCore.ws, so this wrapper is outside CMF's: the fields All Quest
// Objectives writes are on the pins when CMF's late pass calls OnPinReady (this adapter's _cmf.ws).
// Nothing of All Quest Objectives is stored or copied here; without that mod this file does not
// compile.

@addField(AqoomMap)
var aqoAdapterStepRan : bool;

@addField(AqoomMap)
var aqoAdapterFallbackLogged : bool;

@wrapMethod(AqoomMap)
function UpdateEntityPins(mapMenu : CR4MapMenu, shownArea : name, out flashArray : CScriptedFlashArray)
{
	wrappedMethod(mapMenu, shownArea, flashArray);
	aqoAdapterStepRan = true;
}

@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	var aqoomMap : AqoomMap;
	aqoomMap = AqoomGetMap();
	if (indexToUpdate < 0 && aqoomMap && !aqoomMap.aqoAdapterStepRan)
	{
		aqoomMap.UpdateEntityPins(this, m_shownArea, flashArray);
		// Launch evidence: once per session.
		if (!aqoomMap.aqoAdapterFallbackLogged)
		{
			aqoomMap.aqoAdapterFallbackLogged = true;
			LogChannel('CMF', "CMF adapter provider=modAQOOMRemastered fallback=1");
		}
	}
	wrappedMethod(flashArray, indexToUpdate);
	if (indexToUpdate < 0 && aqoomMap)
	{
		aqoomMap.aqoAdapterStepRan = false;
	}
}
