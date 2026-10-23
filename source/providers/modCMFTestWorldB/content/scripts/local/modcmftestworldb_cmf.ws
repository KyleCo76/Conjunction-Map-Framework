// TEST ONLY: revision 9 check pack B (CMF 1.3.0), provider modCMFTestWorldB, not a player package. Our own
// placeholder art (tools/cmf_test_world.py), every picture marked "B":
// - the world overview's painting as 2 x 2 tiles of 1052 x 692 (each tile also shows its XxY), so seams show;
// - crests for skellige, novigrad, bob and prolog_village, all choice-only: they show only when B is picked on the
//   "Region crests and markers" row (or its Painting feature) in the menu or the settings file;
// - a button picture for every Xbox button whose name starts with gamepad_ (numbered as in pack A);
// - an opening view on Geralt's place for the region he is in (CMFSetOpeningWorld, the game's zoom), so the map
//   opens on him even while pack A hides his marker; for other regions B withdraws its view.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestWorldB", 9))
	{
		CMFSetProviderName("modCMFTestWorldB", "CMF Test World B");
		CMFRegisterWorldPaintingTiles("modCMFTestWorldB", "img://icons/modcmftestworldb/world/painting_{x}x{y}.png", 2, 2);
		CMFRegisterChoiceOnly("modCMFTestWorldB", "Painting_Crests");
		CMFRegisterWorldCrest("modCMFTestWorldB", 'skellige', "img://icons/modcmftestworldb/world/crest_skellige.png");
		CMFRegisterWorldCrest("modCMFTestWorldB", 'novigrad', "img://icons/modcmftestworldb/world/crest_novigrad.png");
		CMFRegisterWorldCrest("modCMFTestWorldB", 'bob', "img://icons/modcmftestworldb/world/crest_bob.png");
		CMFRegisterWorldCrest("modCMFTestWorldB", 'prolog_village', "img://icons/modcmftestworldb/world/crest_prolog_village.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_X", "img://icons/modcmftestworldb/buttons/xbox_gamepad_x.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_Y", "img://icons/modcmftestworldb/buttons/xbox_gamepad_y.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_L1", "img://icons/modcmftestworldb/buttons/xbox_gamepad_l1.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R1", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r1.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_L2", "img://icons/modcmftestworldb/buttons/xbox_gamepad_l2.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R2", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r2.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_L3", "img://icons/modcmftestworldb/buttons/xbox_gamepad_l3.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R3", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r3.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_RTLT", "img://icons/modcmftestworldb/buttons/xbox_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_RBLB", "img://icons/modcmftestworldb/buttons/xbox_gamepad_rblb.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_dpad_lr", "img://icons/modcmftestworldb/buttons/xbox_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R_Tab", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R_Scroll", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_L_Hold", "img://icons/modcmftestworldb/buttons/xbox_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R_Hold", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_L_Tab", "img://icons/modcmftestworldb/buttons/xbox_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_L_Scroll", "img://icons/modcmftestworldb/buttons/xbox_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_R_down", "img://icons/modcmftestworldb/buttons/xbox_gamepad_r_down.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_dpad_up_down", "img://icons/modcmftestworldb/buttons/xbox_gamepad_dpad_up_down.png");
		CMFRegisterButtonPicture("modCMFTestWorldB", 'xbox', "gamepad_dpad_all", "img://icons/modcmftestworldb/buttons/xbox_gamepad_dpad_all.png");
	}
	return result;
}

@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	var spot : Vector;
	wrappedMethod(menu, area, mapContext);
	if (menu && menu.IsCurrentAreaShown())
	{
		spot = thePlayer.GetWorldPosition();
		CMFSetOpeningWorld("modCMFTestWorldB", area, spot.X, spot.Y, 0);
	}
	else
	{
		CMFSetOpeningView("modCMFTestWorldB", area, 0, 0, 0, true);
	}
}
