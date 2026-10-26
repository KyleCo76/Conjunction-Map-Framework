// Original screen movie provider; all visible words come from string tables.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestRev13Movie", 13))
	{
		CMFRegister("modCMFTestRev13Movie", 16, 'Boat', '', "hold", 13);
		CMFDraw("modCMFTestRev13Movie", 'screen', 'modCMFTestRev13Movie.list', 'movie');
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'src', "swf/cmftestrev13movie/cmftestrev13movie.swf", 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'width', "", 360);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'height', "", 360);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'screenRight', "", 1880);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'alignX', "", 1);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'screenTop', "", 344);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'alignY', "", 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'wideAnchor', "edges", 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'focus', "", 1);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'caption', GetLocStringByKeyExt("cmf_rev13_movie_caption"), 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'release', GetLocStringByKeyExt("cmf_rev13_movie_release"), 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'region', GetLocStringByKeyExt("cmf_rev13_movie_region"), 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'empty', GetLocStringByKeyExt("cmf_rev13_movie_empty"), 0);
		CMFDrawSet("modCMFTestRev13Movie", 'modCMFTestRev13Movie.list', 'help', GetLocStringByKeyExt("cmf_rev13_movie_help"), 0);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnMovieEvent(menu : CR4MapMenu, provider : string, id : string, eventName : string, value : string) : bool
{
	var result : bool;
	result = wrappedMethod(menu, provider, id, eventName, value);
	if (provider == "modCMFTestRev13Movie")
	{
		LogChannel('CMF', "CMF rev13 movie id=" + id + " event=" + eventName + " value=" + value);
		return true;
	}
	return result;
}

@wrapMethod(CMFCore)
function OnMapAreaReady(menu : CR4MapMenu, area : name)
{
	wrappedMethod(menu, area);
	LogChannel('CMF', "CMF rev13 areaReady area=" + area);
}

// Hold is a log-only fixture diagnostic, not another visual launch element.
@wrapMethod(CMFCore)
function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string, input : string, value : int) : bool
{
	var result : bool;
	result = wrappedMethod(menu, provider, pinTag, pinId, pinType, input, value);
	if (provider == "modCMFTestRev13Movie")
	{
		LogChannel('CMF', "CMF rev13 hold input=" + input + " pin=" + pinId + " value=" + value);
		return true;
	}
	return result;
}
