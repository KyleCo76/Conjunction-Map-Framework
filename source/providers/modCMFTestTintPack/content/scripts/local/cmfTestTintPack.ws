// CMF Stage 0 test tint pack (developer probe, not a player package).
// Tints shopkeeper, cave entrance and blacksmith icons cyan (0x00FFFF) through CMF; ships no art.
// Blacksmiths carry modCMFTestIconPackB art, so they also show tint on custom art.
// Untracked quest pins turn light blue (0x40C0FF); the followed quest must stay gold.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFRegisterTint("modCMFTestTintPack", 'Shopkeeper', 65535);
	CMFRegisterTint("modCMFTestTintPack", 'Entrance', 65535);
	CMFRegisterTint("modCMFTestTintPack", 'Blacksmith', 65535);
	CMFRegisterTint("modCMFTestTintPack", 'QuestObjectiveOther', 4243711);
	return result;
}
