// TEST ONLY: revision 10 check pack (CMF 1.4.0), provider modCMFTestHoverNames, not a player package. No art.
// - names only on hover (property 28) for every pin, value 3: a pin's label line and its tag drawings show only on the
//   hovered pin, and the hovered pin shows its name; signposts (RoadSign) keep the game's labels (a type claim of 0);
// - the screen's shape: every map opening logs "CMF test hover screen=<width>x<height>" from CMFScreenWidth and
//   CMFScreenHeight, which the map reports in map units.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestHoverNames", 10))
	{
		CMFSetProviderName("modCMFTestHoverNames", "CMF Test Hover Names");
		CMFRegister("modCMFTestHoverNames", CMFPropertyHoverName(), '', '', "", 3);
		CMFRegister("modCMFTestHoverNames", CMFPropertyHoverName(), 'RoadSign', '', "", 0);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	wrappedMethod(menu, area, mapContext);
	LogChannel('CMF', "CMF test hover screen=" + FloatToString(CMFScreenWidth()) + "x" + FloatToString(CMFScreenHeight()));
}
