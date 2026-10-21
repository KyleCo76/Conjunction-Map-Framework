// Map Pin Teleport adapter for Conjunction Map Framework. Requires CMF 6 or later and Map Pin Teleport
// 1.2.2 (Nexus 13541), which stays unchanged. Install and remove the two together: this file calls Map Pin
// Teleport's own ModPinTP_Request, so the game stops at the script compile screen when Map Pin Teleport is
// missing, and it wraps CMF 6's click hook, which earlier CMF versions do not have.
//
// Map Pin Teleport's own map file draws a "GO NOW" button beside every pin the player places and shows
// "Go Now" beside E in the button bar while such a pin is selected. A click on the button, or E, Enter or
// gamepad A on the selected pin, sends the game's fast-travel event OnStaticMapPinUsed with a made-up area
// number, -2 minus the pin's id, which its script picks out and hands to ModPinTP_Request. CMF's map has no
// button and sends no such number, so under CMF the teleport is gone. This adapter claims the same inputs on
// the same pins through CMF's pin clicks, gives CMF the same hint and button text and the same button look,
// and calls ModPinTP_Request when CMF passes a click back. Messages, the quick save, refusals, the teleport
// and the settling stay in Map Pin Teleport's scripts. It ships no art and copies no code. Every claim uses
// Map Pin Teleport's own folder name as its provider, so folder order between mods is the same with CMF as
// without it.
//
// Claim order: the click on a pin goes to one mod only. A claim on one pin beats a claim on its tag, which
// beats a claim on its type; between claims at the same level the mod earlier in CMF's provider order wins
// (folder order unless the player set one). These claims are type claims on the player's own pin types
// User1 to User7, and nothing else: a mod that claims a single placed pin beats them there, and a type claim
// from a folder sorting after modMapPinTeleport (for example modZZCMFTestClick) loses. The hint and the
// button text are shown only on pins whose click this adapter won.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modMapPinTeleport", 6))
	{
		// The inputs Map Pin Teleport's map file acts on: E, Enter or gamepad A on the selected pin ("use") and
		// its button beside the pin ("button"). Double-click and hold stay the game's (nothing on these pins).
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User1', '', "use,button", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User2', '', "use,button", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User3', '', "use,button", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User4', '', "use,button", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User5', '', "use,button", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User6', '', "use,button", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User7', '', "use,button", 1);
		// Its button bar hint, the literal text its OnAppendGFxButton wrapper shows for the label
		// modPinTP_GoNow.
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User1', '', "Go Now", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User2', '', "Go Now", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User3', '', "Go Now", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User4', '', "Go Now", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User5', '', "Go Now", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User6', '', "Go Now", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User7', '', "Go Now", 1);
		// Its button's text.
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User1', '', "GO NOW", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User2', '', "GO NOW", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User3', '', "GO NOW", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User4', '', "GO NOW", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User5', '', "GO NOW", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User6', '', "GO NOW", 1);
		CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User7', '', "GO NOW", 1);
		// Its button's look, as its map file draws it: 150 x 40 px, corners 10, fill 0x1A1410 at 0.9, a 2 px
		// 0xC8A55A outline, centred $NormalFont text at 20 px in 0xE8D3A0, its top-left corner 28 px right of
		// and 20 px above the pin. The earliest folder that styles pinButton owns the look of every button.
		CMFStylePart("modMapPinTeleport", 'pinButton', 'width', "", 150);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'height', "", 40);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'curve', "", 10);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'fill', "", 1709072);	// 0x1A1410
		CMFStylePart("modMapPinTeleport", 'pinButton', 'alpha', "", 0.9);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'stroke', "", 13149530);	// 0xC8A55A
		CMFStylePart("modMapPinTeleport", 'pinButton', 'strokeWidth', "", 2);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'offsetX', "", 28);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'offsetY', "", -20);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'font', "$NormalFont", 0);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'size', "", 20);
		CMFStylePart("modMapPinTeleport", 'pinButton', 'color', "", 15258528);	// 0xE8D3A0
		CMFStylePart("modMapPinTeleport", 'pinButton', 'align', "center", 0);
	}
	return result;
}

// CMF passes back every click this adapter won. Map Pin Teleport's map file sent the pin's id masked to its
// low 30 bits (id & 0x3FFFFFFF), and ModPinTP_Request finds the pin by those bits; the remainder modulo
// 2^30, kept positive, is the same number. Clicks won by other mods go on unchanged.
@wrapMethod(CMFCore)
function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string,
	input : string, value : int) : bool
{
	var lowBits : int;
	if (provider != "modMapPinTeleport")
	{
		return wrappedMethod(menu, provider, pinTag, pinId, pinType, input, value);
	}
	lowBits = pinId % 1073741824;
	if (lowBits < 0)
	{
		lowBits += 1073741824;
	}
	ModPinTP_Request(menu, lowBits);
	return true;
}
