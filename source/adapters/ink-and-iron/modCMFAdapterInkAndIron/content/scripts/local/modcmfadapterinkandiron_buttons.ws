// Ink and Iron adapter for Conjunction Map Framework: Ink and Iron's gold controller button pictures on CMF's
// map (CMF 9, CMFRegisterButtonPicture). Ink and Iron's map file (All In One, 0.8.7 to 0.9.0) re-draws the
// game's two button sheets (_i49 and the lower rows of _i1) with gold outlines and keeps the game's layout, so
// each button's picture is cut from Ink and Iron's sheets at the game's own places by
// tools/cmf_ink_and_iron_art.py buttons (tools/cmf_button_sheet.py's map of 143 buttons in five controller
// families). WinterElfeas's art, carried with the author's permission. These ship in the All In One every
// player of this adapter has, so they are not choice-only: they answer the Look_Hints choice like the rest of
// the adapter's look. This file and art/buttons/ are kept apart from the rest of the adapter so they can be left
// out on their own.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modInkAndIronUI", 9))
	{
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_X", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_x.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "enter-gamepad_A", "img://icons/modcmfadapterinkandiron/buttons/xbox_enter_gamepad_a.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "escape-gamepad_B", "img://icons/modcmfadapterinkandiron/buttons/xbox_escape_gamepad_b.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_Y", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_y.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_L1", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_l1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R1", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_L2", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_l2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R2", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_L3", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_l3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R3", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_RTLT", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_RBLB", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_rblb.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "dpad_up", "img://icons/modcmfadapterinkandiron/buttons/xbox_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "double_dpad_up", "img://icons/modcmfadapterinkandiron/buttons/xbox_double_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "dpad_down", "img://icons/modcmfadapterinkandiron/buttons/xbox_dpad_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "dpad_right", "img://icons/modcmfadapterinkandiron/buttons/xbox_dpad_right.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "dpad_left", "img://icons/modcmfadapterinkandiron/buttons/xbox_dpad_left.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_dpad_lr", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_dpad_up_down", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_dpad_up_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_dpad_all", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_dpad_all.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "start", "img://icons/modcmfadapterinkandiron/buttons/xbox_start.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "back", "img://icons/modcmfadapterinkandiron/buttons/xbox_back.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R_Tab", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R_Scroll", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_L_Hold", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R_Hold", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_L_Tab", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_L_Scroll", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'xbox', "gamepad_R_down", "img://icons/modcmfadapterinkandiron/buttons/xbox_gamepad_r_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_X", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_x.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "enter-gamepad_A", "img://icons/modcmfadapterinkandiron/buttons/ps4_enter_gamepad_a.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "escape-gamepad_B", "img://icons/modcmfadapterinkandiron/buttons/ps4_escape_gamepad_b.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_Y", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_y.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_L1", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_l1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R1", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_L2", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_l2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R2", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_L3", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_l3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R3", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_RTLT", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_RBLB", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_rblb.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "dpad_up", "img://icons/modcmfadapterinkandiron/buttons/ps4_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "double_dpad_up", "img://icons/modcmfadapterinkandiron/buttons/ps4_double_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "dpad_down", "img://icons/modcmfadapterinkandiron/buttons/ps4_dpad_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "dpad_right", "img://icons/modcmfadapterinkandiron/buttons/ps4_dpad_right.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "dpad_left", "img://icons/modcmfadapterinkandiron/buttons/ps4_dpad_left.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_dpad_lr", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_dpad_up_down", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_dpad_up_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_dpad_all", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_dpad_all.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "start", "img://icons/modcmfadapterinkandiron/buttons/ps4_start.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "back", "img://icons/modcmfadapterinkandiron/buttons/ps4_back.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R_Tab", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R_Scroll", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_L_Hold", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R_Hold", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_L_Tab", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_L_Scroll", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps4', "gamepad_R_down", "img://icons/modcmfadapterinkandiron/buttons/ps4_gamepad_r_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_X", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_x.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "enter-gamepad_A", "img://icons/modcmfadapterinkandiron/buttons/ps5_enter_gamepad_a.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "escape-gamepad_B", "img://icons/modcmfadapterinkandiron/buttons/ps5_escape_gamepad_b.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_Y", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_y.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_L1", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_l1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R1", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_L2", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_l2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R2", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_L3", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_l3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R3", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_RTLT", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_RBLB", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_rblb.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "dpad_up", "img://icons/modcmfadapterinkandiron/buttons/ps5_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "double_dpad_up", "img://icons/modcmfadapterinkandiron/buttons/ps5_double_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "dpad_down", "img://icons/modcmfadapterinkandiron/buttons/ps5_dpad_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "dpad_right", "img://icons/modcmfadapterinkandiron/buttons/ps5_dpad_right.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "dpad_left", "img://icons/modcmfadapterinkandiron/buttons/ps5_dpad_left.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_dpad_lr", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_dpad_up_down", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_dpad_up_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_dpad_all", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_dpad_all.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "start", "img://icons/modcmfadapterinkandiron/buttons/ps5_start.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "back", "img://icons/modcmfadapterinkandiron/buttons/ps5_back.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R_Tab", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R_Scroll", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_L_Hold", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R_Hold", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_L_Tab", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_L_Scroll", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'ps5', "gamepad_R_down", "img://icons/modcmfadapterinkandiron/buttons/ps5_gamepad_r_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_X", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_x.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "enter-gamepad_A", "img://icons/modcmfadapterinkandiron/buttons/steam_enter_gamepad_a.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "escape-gamepad_B", "img://icons/modcmfadapterinkandiron/buttons/steam_escape_gamepad_b.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_Y", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_y.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_L1", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_l1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R1", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_L2", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_l2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R2", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_L3", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_l3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R3", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_RTLT", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_RBLB", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_rblb.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "dpad_up", "img://icons/modcmfadapterinkandiron/buttons/steam_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "double_dpad_up", "img://icons/modcmfadapterinkandiron/buttons/steam_double_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "dpad_down", "img://icons/modcmfadapterinkandiron/buttons/steam_dpad_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "dpad_right", "img://icons/modcmfadapterinkandiron/buttons/steam_dpad_right.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "dpad_left", "img://icons/modcmfadapterinkandiron/buttons/steam_dpad_left.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_dpad_lr", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "start", "img://icons/modcmfadapterinkandiron/buttons/steam_start.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "back", "img://icons/modcmfadapterinkandiron/buttons/steam_back.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R_Tab", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R_Scroll", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_L_Hold", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R_Hold", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_L_Tab", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_L_Scroll", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'steam', "gamepad_R_down", "img://icons/modcmfadapterinkandiron/buttons/steam_gamepad_r_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_X", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_x.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "enter-gamepad_A", "img://icons/modcmfadapterinkandiron/buttons/switch_enter_gamepad_a.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "escape-gamepad_B", "img://icons/modcmfadapterinkandiron/buttons/switch_escape_gamepad_b.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_Y", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_y.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_L1", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_l1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R1", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r1.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_L2", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_l2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R2", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r2.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_L3", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_l3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R3", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r3.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_RTLT", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_rtlt.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_RBLB", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_rblb.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "dpad_up", "img://icons/modcmfadapterinkandiron/buttons/switch_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "double_dpad_up", "img://icons/modcmfadapterinkandiron/buttons/switch_double_dpad_up.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "dpad_down", "img://icons/modcmfadapterinkandiron/buttons/switch_dpad_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "dpad_right", "img://icons/modcmfadapterinkandiron/buttons/switch_dpad_right.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "dpad_left", "img://icons/modcmfadapterinkandiron/buttons/switch_dpad_left.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_dpad_lr", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_dpad_lr.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_dpad_up_down", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_dpad_up_down.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_dpad_all", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_dpad_all.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "start", "img://icons/modcmfadapterinkandiron/buttons/switch_start.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "back", "img://icons/modcmfadapterinkandiron/buttons/switch_back.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R_Tab", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R_Scroll", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_L_Hold", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_l_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R_Hold", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r_hold.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_L_Tab", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_l_tab.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_L_Scroll", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_l_scroll.png");
		CMFRegisterButtonPicture("modInkAndIronUI", 'switch', "gamepad_R_down", "img://icons/modcmfadapterinkandiron/buttons/switch_gamepad_r_down.png");
	}
	return result;
}
