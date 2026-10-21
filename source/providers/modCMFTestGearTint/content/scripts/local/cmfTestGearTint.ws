// TEST ONLY: observation pack for Witcher Gear Map pins under CMF (provider modCMFTestGearTint).
// Witcher Gear Map pushes its own pins with type WitcherGear or WitcherGearObtained and filteredType
// WitcherGear. Red on WitcherGear; green on WitcherGearObtained, which only applies when CMF looks
// up a pin's own type before its filteredType.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestGearTint", 1))
	{
		CMFRegisterTint("modCMFTestGearTint", 'WitcherGear', 16728128);
		CMFRegisterTint("modCMFTestGearTint", 'WitcherGearObtained', 4259648);
	}
	return result;
}
