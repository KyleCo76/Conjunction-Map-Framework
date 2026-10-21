// CMF Stage 0 test icon pack (developer probe, not a player package).
// Art lives in this mod's own content/texture.cache. Its "Show test icons" setting
// (Options > Mods > Conjunction Map Framework > CMF Test Icon Pack) is read at game start
// and again each time the world map opens, before the map builds its pins.

function CMFTestIconPackApply()
{
	if (theGame.GetInGameConfigWrapper().GetVarValue('CMFTestPack', 'CMFTP_Enabled') == "false")
	{
		CMFReleaseProvider("modCMFTestIconPack");
		return;
	}
	CMFRegisterIcon("modCMFTestIconPack", 'NoticeBoard', "img://icons/cmf_s03/icon.png");
	CMFRegisterIcon("modCMFTestIconPack", 'NoticeBoardFull', "img://icons/cmf_s03/icon.png");
	CMFRegisterIcon("modCMFTestIconPack", 'RoadSign', "img://icons/cmf_testpack/signpost.png");
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFTestIconPackApply();
	return result;
}

@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	CMFTestIconPackApply();
	return wrappedMethod();
}
