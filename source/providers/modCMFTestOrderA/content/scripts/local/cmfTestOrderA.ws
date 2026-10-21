// CMF provider order test pack A (developer probe, not a player package).
// Tints blacksmith pins red (0xFF4040). Its folder sorts before modCMFTestOrderB, so it wins unless the
// CMFProviderOrder setting lists modCMFTestOrderB first.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFRegisterTint("modCMFTestOrderA", 'Blacksmith', 16728128);
	return result;
}
