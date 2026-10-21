// CMF Stage 0 second test icon pack (developer probe, not a player package).
// Competes with modCMFTestIconPack for notice boards (and loses while it is installed);
// also claims blacksmiths, which nobody else claims, and the Seven Cats Inn notice board alone
// (an instance claim, which beats the other pack's type icon on that one pin).
// Art lives in this mod's own texture.cache.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestIconPackB", 1))
	{
		CMFRegisterIcon("modCMFTestIconPackB", 'NoticeBoard', "img://icons/modcmftesticonpackb/badge.png");
		CMFRegisterIcon("modCMFTestIconPackB", 'NoticeBoardFull', "img://icons/modcmftesticonpackb/badge.png");
		CMFRegisterIcon("modCMFTestIconPackB", 'Blacksmith', "img://icons/modcmftesticonpackb/badge.png");
		CMFRegisterIconForTag("modCMFTestIconPackB", 'seven_cats_noticeboard', "img://icons/modcmftesticonpackb/badge.png");
	}
	return result;
}
