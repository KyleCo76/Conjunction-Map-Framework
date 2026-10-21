// CMF Example Icon Pack for Conjunction Map Framework. Requires CMF 1 or later.
// Innkeepers get a mug icon (a purple one in the legend), armorers a shield icon,
// and herbalists keep their stock icon tinted lime green (0x40FF40 = 4259648). Cleared bandit camps and
// monster nests get a grey tick: the game gives a completed place its own pin type (BanditCampDisabled,
// BanditCampfireDisabled, MonsterNestDisabled), so completed art is an icon on that type.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFExampleIconPack", 1))
	{
		CMFRegisterIcon("modCMFExampleIconPack", 'Innkeeper', "img://icons/modcmfexampleiconpack/innkeeper.png");
		CMFRegisterLegendIcon("modCMFExampleIconPack", 'Innkeeper', "img://icons/modcmfexampleiconpack/innkeeper_legend.png");
		CMFRegisterIcon("modCMFExampleIconPack", 'Armorer', "img://icons/modcmfexampleiconpack/armorer.png");
		CMFRegisterIcon("modCMFExampleIconPack", 'BanditCampDisabled', "img://icons/modcmfexampleiconpack/cleared.png");
		CMFRegisterIcon("modCMFExampleIconPack", 'BanditCampfireDisabled', "img://icons/modcmfexampleiconpack/cleared.png");
		CMFRegisterIcon("modCMFExampleIconPack", 'MonsterNestDisabled', "img://icons/modcmfexampleiconpack/cleared.png");
		// The generic form: test the property id, then register it. A pack written this way also
		// compiles against a CMF that lacks a newer property, and simply skips it.
		if (CMFHasProperty(CMFPropertyTint()))
		{
			CMFRegister("modCMFExampleIconPack", CMFPropertyTint(), 'Herbalist', '', "", 4259648);
		}
	}
	return result;
}
