// TEST ONLY: the smooth map movement check (smooth map movement research 2026-10-20, section 9 step 7),
// provider modZZCMFTestSmooth, not a player package. While its "Smooth Map check" switch is on (Options > Mods >
// Conjunction Map Framework > CMF Smooth Map Check, default off) it sends Smooth Map's column of the navigation
// and opening keys under its own name; off, it withdraws them ("unset"). Its folder sorts after
// modMapQuestInsight, as modSmoothMap does, so Map Quest Insight's keys win wherever both set one.

@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	CMFTestSmoothApply();
	return wrappedMethod();
}

function CMFTestSmoothApply()
{
	var text : string;
	if (!CMFHasAbility('opening', ''))
	{
		return;
	}
	text = "unset";
	if (theGame.GetInGameConfigWrapper().GetVarValue('CMFTestSmooth', 'CMFTS_Enabled') == "true")
	{
		text = "";
	}
	CMFTestSmoothKey('navigation', 'frameTimed', text, 1);
	CMFTestSmoothKey('navigation', 'stepMs', text, 17);
	CMFTestSmoothKey('navigation', 'worldStepMs', text, 24);
	CMFTestSmoothKey('navigation', 'maxStepMs', text, 100);
	CMFTestSmoothKey('navigation', 'zoomTimed', text, 1);
	CMFTestSmoothKey('navigation', 'padHoldMs', text, 0);
	CMFTestSmoothKey('navigation', 'tweenEveryFrame', text, 1);
	CMFTestSmoothKey('opening', 'pinsDuringSlide', text, 1);
	CMFTestSmoothKey('opening', 'pinStepMs', text, 1);
	CMFTestSmoothKey('opening', 'pinBatch', text, 0);
	CMFTestSmoothKey('opening', 'pinBudgetMs', text, 8);
	CMFTestSmoothKey('opening', 'showDelayMs', text, 1);
	CMFTestSmoothKey('opening', 'fadeSeconds', text, 0.2);
	CMFTestSmoothKey('opening', 'tileFadeSeconds', text, 0.2);
	CMFTestSmoothKey('opening', 'revealSeconds', text, 0.2);
}

function CMFTestSmoothKey(part : name, key : name, text : string, number : float)
{
	if (CMFHasAbility(part, key))
	{
		CMFStylePart("modZZCMFTestSmooth", part, key, text, number);
	}
}
