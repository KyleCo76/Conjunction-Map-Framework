// CMF Stage 0 test background pack (developer probe, not a player package).
// Swaps the Velen/Novigrad full-screen map art for numbered test tiles (levels 0 to 4, 1024 px)
// from this mod's own texture.cache; geometry and pins stay vanilla.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestBackgroundPack", 1))
	{
		CMFRegisterBackground("modCMFTestBackgroundPack", 'AN_NMLandNovigrad', "cmf_testbg");
	}
	return result;
}
