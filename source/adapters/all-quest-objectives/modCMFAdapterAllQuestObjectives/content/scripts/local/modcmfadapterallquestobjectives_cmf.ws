// All Quest Objectives adapter for Conjunction Map Framework. Requires CMF 8 (CMF 1.2.0) or later and All
// Quest Objectives On Map - Remastered 1.2.1 (Nexus 14319), which stays unchanged. Install and remove the two
// together: this file calls All Quest Objectives' own functions, so the game stops at the script compile
// screen when that mod is missing, and it wraps CMF 6's click hook and calls CMF 8's CMFSetProviderName,
// which earlier CMF versions do not have.
//
// Three of All Quest Objectives' map features come back here.
//
// Difficulty icons. All Quest Objectives writes a frame name on the pins of untracked quest objectives
// (wmkIcon, by the quest's suggested level against Geralt's: WmkQuestIconGray, Green, Orange or Red by
// default, any of 19 names if its settings are edited), and its own map file draws that frame: a round
// badge with an exclamation mark, or a bare exclamation mark, in one of its colours. Those drawings live
// inside its map file, which CMF's map replaces, so this adapter draws them with two placeholder pictures
// of its own (white badge and white mark, in its texture cache) and colours each pin with the colour All
// Quest Objectives names, through CMF's per-pin icon and tint calls, as the mod's author would when porting.
//
// Its own legend row. All Quest Objectives' map file lists the objectives of untracked quests (filteredType
// QuestObjectiveOther) in their own row instead of the game's shared quest row, so the player can hide them
// on their own: the game's Quests tab, priority 200, named by aqoomRowLabel ("All Quest Objectives", its
// constant FILTER_LABEL). This adapter registers that row and its name once per session.
//
// Its name in CMF's in-game menu. The menu lists each mod by name, and without one it tidies the provider's
// folder name, which here reads "AQOOMRemastered". The adapter names the provider "All Quest Objectives",
// the mod's own name for its row, once per session with the row. The name changes nothing on the map.
//
// Cached merchant pins. All Quest Objectives keeps a grey "[CACHED]" copy of a merchant's pin once the game
// stops showing it, and lets the player remove that copy by using it twice. Its own map file did the click:
// on E, Enter, gamepad A, a double-click or a tap it sent the game's fast-travel event OnStaticMapPinUsed
// with the fake area number -(aqoomCachedPin + 999), which its OnStaticMapPinUsed wrapper picks out. CMF's
// map sends no such number. This adapter claims the click on each cached pin through CMF instead and, when
// CMF hands the click back, calls the same two functions that wrapper calls. The messages, the sound and the
// removal stay the mod's own.
//
// It copies no code and ships none of All Quest Objectives' art. Every claim uses All Quest Objectives' own
// folder name as its provider, so folder order between mods is the same with CMF as without it.
//
// wmkIcon and aqoomCachedPin ride on the pin objects: CMF's map declares those names for this adapter only,
// because the game drops any field its class does not declare. CMF itself never reads them.
//
// Claim order: every claim is made on one pin (CMFStylePin and its icon and tint forms), the most specific
// level, so it beats any tag or type claim another mod makes on the same pin. Against another one-pin claim
// the earlier folder in CMF's provider order wins (modAQOOMRemastered sorts before most mod folders, Map
// Quest Insight's included). Cached pins are neither fast-travel nor quest pins, so CMF lets the click claim
// take "use" and "doubleClick".

// All Quest Objectives' own legend row for the objectives of untracked quests, as its map file lists it, and
// the mod's name in CMF's in-game menu.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFRegisterLegendRow("modAQOOMRemastered", 'QuestObjectiveOther', 'Quests', 200);
	CMFRegisterLegendLabel("modAQOOMRemastered", 'QuestObjectiveOther', "All Quest Objectives");
	CMFSetProviderName("modAQOOMRemastered", "All Quest Objectives");
	return result;
}

@addField(CMFCore)
var aqoAdapterLogged : int;

@addField(CMFCore)
var aqoAdapterIconsLogged : int;

// The colour (0xRRGGBB) of one of All Quest Objectives' icon names, as its own map file draws it, or -1 for
// a name it does not have. Names starting with WmkQuestIcon are badges, WmkExclamationIcon bare marks.
function AqoAdapterIconColour(frame : string) : int
{
	if (frame == "WmkQuestIconWhite" || frame == "WmkExclamationIconWhite")
	{
		return 16777215;	// 0xFFFFFF
	}
	if (frame == "WmkExclamationIconLightGray")
	{
		return 13421772;	// 0xCCCCCC
	}
	if (frame == "WmkQuestIconGray" || frame == "WmkExclamationIconGray")
	{
		return 10066329;	// 0x999999
	}
	if (frame == "WmkQuestIconGreen" || frame == "WmkExclamationIconGreen")
	{
		return 9033865;	// 0x89D889
	}
	if (frame == "WmkExclamationIconPureGreen")
	{
		return 65280;	// 0x00FF00
	}
	if (frame == "WmkExclamationIconAltGreen")
	{
		return 440658;	// 0x06B952
	}
	if (frame == "WmkQuestIconYellow" || frame == "WmkExclamationIconYellow")
	{
		return 16763904;	// 0xFFCC00
	}
	if (frame == "WmkQuestIconOrange" || frame == "WmkExclamationIconOrange")
	{
		return 16750848;	// 0xFF9900
	}
	if (frame == "WmkExclamationIconLightRed")
	{
		return 16737894;	// 0xFF6666
	}
	if (frame == "WmkQuestIconRed")
	{
		return 14241872;	// 0xD95050
	}
	if (frame == "WmkExclamationIconRed")
	{
		return 16711680;	// 0xFF0000
	}
	if (frame == "WmkExclamationIconDarkRed")
	{
		return 10878976;	// 0xA60000
	}
	if (frame == "WmkExclamationIconMagenta")
	{
		return 16711935;	// 0xFF00FF
	}
	if (frame == "WmkExclamationIconPink")
	{
		return 16751103;	// 0xFF99FF
	}
	return -1;
}

// An untracked quest objective with All Quest Objectives' difficulty icon: the badge or the mark, coloured.
// A name it does not have keeps the game's icon, as its own map file would show no frame.
function AqoAdapterStyleIcon(dataObject : CScriptedFlashObject, frame : string) : string
{
	var colour : int;
	var url : string;
	colour = AqoAdapterIconColour(frame);
	if (colour < 0)
	{
		return "unknown";
	}
	url = "img://icons/modcmfadapterallquestobjectives/badge.png";
	if (StrBeginsWith(frame, "WmkExclamationIcon"))
	{
		url = "img://icons/modcmfadapterallquestobjectives/mark.png";
	}
	if (!CMFStylePinIcon("modAQOOMRemastered", dataObject, url))
	{
		return "refused";
	}
	CMFStylePinTint("modAQOOMRemastered", dataObject, colour);
	return "styled";
}

// Every pin All Quest Objectives marked. A difficulty icon name (wmkIcon) styles the pin's icon. A cached
// merchant pin (aqoomCachedPin = its list index + 1) gets a claim on the inputs its map file acted on, E,
// Enter, gamepad A and a tap ("use") and a mouse double-click ("doubleClick"), with that number as the value
// CMF hands back. No hint and no button: the mod has none.
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var frame : string;
	var cached : int;
	var outcome : string;
	wrappedMethod(dataObject, mapContext);
	frame = dataObject.GetMemberFlashString("wmkIcon");
	if (frame != "")
	{
		outcome = AqoAdapterStyleIcon(dataObject, frame);
		// Launch evidence: the first eight difficulty icons of the session.
		if (aqoAdapterIconsLogged < 8)
		{
			aqoAdapterIconsLogged += 1;
			LogChannel('CMF', "CMF adapter provider=modAQOOMRemastered icon=" + frame + " type=" +
				dataObject.GetMemberFlashString("type") + " result=" + outcome);
		}
	}
	cached = dataObject.GetMemberFlashInt("aqoomCachedPin");
	if (cached <= 0)
	{
		return;
	}
	outcome = "refused";
	if (CMFStylePin("modAQOOMRemastered", dataObject, CMFPropertyPinClick(), "use, doubleClick", cached))
	{
		outcome = "claimed";
	}
	// Launch evidence: the first eight cached pins of the session.
	if (aqoAdapterLogged < 8)
	{
		aqoAdapterLogged += 1;
		LogChannel('CMF', "CMF adapter provider=modAQOOMRemastered cached=" + cached + " type=" +
			dataObject.GetMemberFlashString("type") + " result=" + outcome);
	}
}

// A click CMF passes back. Only All Quest Objectives' own clicks are handled here; every other click goes on
// unchanged. The fake area number is rebuilt exactly as the mod's map file built it, and the mod's own test
// (the index is in range and that merchant's tag is this pin's) decides as before.
@wrapMethod(CMFCore)
function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string,
	input : string, value : int) : bool
{
	var aqoomMap : AqoomMap;
	var areaNameId : int;
	var outcome : string;
	if (provider != "modAQOOMRemastered")
	{
		return wrappedMethod(menu, provider, pinTag, pinId, pinType, input, value);
	}
	aqoomMap = AqoomGetMap();
	areaNameId = -(value + 999);
	outcome = "notcached";
	if (aqoomMap && aqoomMap.IsCachedPinUse(pinTag, areaNameId))
	{
		aqoomMap.OnCachedPinUsed(menu, areaNameId);
		outcome = "used";
	}
	LogChannel('CMF', "CMF adapter provider=modAQOOMRemastered click input=" + input + " value=" + value +
		" tag=" + NameToString(pinTag) + " result=" + outcome);
	return true;
}
