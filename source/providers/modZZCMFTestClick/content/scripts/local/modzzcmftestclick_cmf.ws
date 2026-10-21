// TEST ONLY: the pin click order check (pin click research 2026-10-20, section 7), provider modZZCMFTestClick,
// not a player package. It claims "use" on the player's own pins (type User1), as the Map Pin Teleport adapter
// does. Its folder sorts after modMapPinTeleport, so it must lose that pin's click: scriptslog.txt then shows
// "click shadowed provider=modZZCMFTestClick by=modMapPinTeleport" and no click line for this pack. It wraps no
// hook, so a click it ever won would log "click provider=modZZCMFTestClick ... reason=nohandler".

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFHasProperty(16))
	{
		CMFRegister("modZZCMFTestClick", 16, 'User1', '', "use", 1);
	}
	return result;
}
