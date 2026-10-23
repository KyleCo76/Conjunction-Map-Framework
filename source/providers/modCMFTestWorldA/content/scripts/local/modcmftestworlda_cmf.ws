// TEST ONLY: revision 9 check pack A (CMF 1.3.0), provider modCMFTestWorldA, not a player package. Our own
// placeholder art (tools/cmf_test_world.py), every picture marked "A":
// - the world overview's painting as one 2100 x 1380 picture;
// - crests for six regions (not prolog_village, so White Orchard keeps the game's crest unless B is picked);
// - the overview's player marker;
// - a button picture for every Xbox button (numbered in the order of the pack tool's BUTTON_NAMES);
// - the player's marker hidden on the region map in the GlobalMap context only (opened from the menus);
// - the map's view: OnMapView logs every report (as "CMF test world A view ...") and keeps the last view per area for this session (not saved);
//   OnMapOpening hands that view back with CMFSetOpeningView (place and zoom, keepPlace false).

@addField(CMFCore)
var modCMFTestWorldAAreas : array<name>;

@addField(CMFCore)
var modCMFTestWorldAX : array<float>;

@addField(CMFCore)
var modCMFTestWorldAY : array<float>;

@addField(CMFCore)
var modCMFTestWorldAZoom : array<float>;

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestWorldA", 9))
	{
		CMFSetProviderName("modCMFTestWorldA", "CMF Test World A");
		CMFRegisterWorldPainting("modCMFTestWorldA", "img://icons/modcmftestworlda/world/painting.png");
		CMFRegisterWorldCrest("modCMFTestWorldA", 'kaer_morhen', "img://icons/modcmftestworlda/world/crest_kaer_morhen.png");
		CMFRegisterWorldCrest("modCMFTestWorldA", 'skellige', "img://icons/modcmftestworlda/world/crest_skellige.png");
		CMFRegisterWorldCrest("modCMFTestWorldA", 'novigrad', "img://icons/modcmftestworlda/world/crest_novigrad.png");
		CMFRegisterWorldCrest("modCMFTestWorldA", 'no_mans_land', "img://icons/modcmftestworlda/world/crest_no_mans_land.png");
		CMFRegisterWorldCrest("modCMFTestWorldA", 'wyzima_castle', "img://icons/modcmftestworlda/world/crest_wyzima_castle.png");
		CMFRegisterWorldCrest("modCMFTestWorldA", 'bob', "img://icons/modcmftestworlda/world/crest_bob.png");
		CMFRegisterWorldMarker("modCMFTestWorldA", 'player', "img://icons/modcmftestworlda/world/marker_player.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_X", "img://icons/modcmftestworlda/buttons/xbox_gamepad_x.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "enter-gamepad_A", "img://icons/modcmftestworlda/buttons/xbox_enter_gamepad_a.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "escape-gamepad_B", "img://icons/modcmftestworlda/buttons/xbox_escape_gamepad_b.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_Y", "img://icons/modcmftestworlda/buttons/xbox_gamepad_y.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_L1", "img://icons/modcmftestworlda/buttons/xbox_gamepad_l1.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R1", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r1.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_L2", "img://icons/modcmftestworlda/buttons/xbox_gamepad_l2.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R2", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r2.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_L3", "img://icons/modcmftestworlda/buttons/xbox_gamepad_l3.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R3", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r3.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_RTLT", "img://icons/modcmftestworlda/buttons/xbox_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_RBLB", "img://icons/modcmftestworlda/buttons/xbox_gamepad_rblb.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "dpad_up", "img://icons/modcmftestworlda/buttons/xbox_dpad_up.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "double_dpad_up", "img://icons/modcmftestworlda/buttons/xbox_double_dpad_up.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "dpad_down", "img://icons/modcmftestworlda/buttons/xbox_dpad_down.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "dpad_right", "img://icons/modcmftestworlda/buttons/xbox_dpad_right.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "dpad_left", "img://icons/modcmftestworlda/buttons/xbox_dpad_left.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_dpad_lr", "img://icons/modcmftestworlda/buttons/xbox_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "start", "img://icons/modcmftestworlda/buttons/xbox_start.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "back", "img://icons/modcmftestworlda/buttons/xbox_back.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R_Tab", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R_Scroll", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_L_Hold", "img://icons/modcmftestworlda/buttons/xbox_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R_Hold", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_L_Tab", "img://icons/modcmftestworlda/buttons/xbox_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_L_Scroll", "img://icons/modcmftestworlda/buttons/xbox_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_R_down", "img://icons/modcmftestworlda/buttons/xbox_gamepad_r_down.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_dpad_up_down", "img://icons/modcmftestworlda/buttons/xbox_gamepad_dpad_up_down.png");
		CMFRegisterButtonPicture("modCMFTestWorldA", 'xbox', "gamepad_dpad_all", "img://icons/modcmftestworlda/buttons/xbox_gamepad_dpad_all.png");
		CMFRegisterHidden("modCMFTestWorldA", 'Player', 'GlobalMap', "", true);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float, zoom : float, reason : name)
{
	var i : int;
	wrappedMethod(menu, area, x, y, worldX, worldY, zoom, reason);
	LogChannel('CMF', "CMF test world A view area=" + NameToString(area) + " reason=" + NameToString(reason) + " x=" + FloatToString(x)
		+ " y=" + FloatToString(y) + " zoom=" + FloatToString(zoom));
	i = modCMFTestWorldAAreas.FindFirst(area);
	if (i < 0)
	{
		modCMFTestWorldAAreas.PushBack(area);
		modCMFTestWorldAX.PushBack(x);
		modCMFTestWorldAY.PushBack(y);
		modCMFTestWorldAZoom.PushBack(zoom);
	}
	else
	{
		modCMFTestWorldAX[i] = x;
		modCMFTestWorldAY[i] = y;
		modCMFTestWorldAZoom[i] = zoom;
	}
}

@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	var i : int;
	wrappedMethod(menu, area, mapContext);
	i = modCMFTestWorldAAreas.FindFirst(area);
	if (i >= 0)
	{
		CMFSetOpeningView("modCMFTestWorldA", area, modCMFTestWorldAX[i], modCMFTestWorldAY[i], modCMFTestWorldAZoom[i],
			false);
	}
}
