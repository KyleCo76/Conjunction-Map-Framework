// CMF Stage 0 test signpost pack (developer probe, not a player package).
// Shows CMF's disabled appearance: every signpost greyed when the map is opened from a signpost,
// and the Seven Cats Inn signpost greyed in every context. Appearance only; travel is unchanged.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestSignpostPack", 1))
	{
		CMFRegisterDisabled("modCMFTestSignpostPack", 'RoadSign', 'FastTravel', true);
		CMFRegisterDisabledForTag("modCMFTestSignpostPack", 'seven_cats_inn', '', true);
	}
	return result;
}
