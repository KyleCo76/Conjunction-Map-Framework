// CMF provider order test pack B (developer probe, not a player package).
// Tints blacksmith pins blue (0x4040FF). It wins over modCMFTestOrderA only when CMF's provider order
// settings list modCMFTestOrderB first, and logs the first two order values it read at game start.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFRegisterTint("modCMFTestOrderB", 'Blacksmith', 4210943);
	LogChannel('CMF', "CMF test pack modCMFTestOrderB read order1=" +
		theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFProviderOrder1') + " order2=" +
		theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFProviderOrder2'));
	return result;
}
