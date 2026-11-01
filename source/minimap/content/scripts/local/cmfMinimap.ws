// Conjunction Map Framework minimap add-on: hands the core's type-level icon and tint winners to the add-on's
// own HUD part, which styles claimed pins of whichever minimap is loaded and replaces no game file.
// The part fills the HUD's unused PickedItemsInfoModule slot (hud_pickeditemsinfo); the game never creates it.
// The engine adds minimap pins itself, so styling is per pin type; single-pin claims stay off the minimap.
// A type every one of whose pins CMF hides on the world map has its minimap icon masked too.
// Needs mod0000_ConjunctionMapFramework (CMFCore.GetRevision, FindTypeWinner and its hide claims).

@wrapMethod(CR4ScriptedHud)
function OnConfigUI()
{
	var result : bool;
	result = wrappedMethod();
	if (!hudModulesNames.Contains('PickedItemsInfoModule'))
	{
		CreateHudModule("PickedItemsInfoModule");
		CMFLog("minimap add-on part requested");
	}
	return result;
}

// Raised by the add-on movie on the HUD itself once it is on stage, before the game binds the part.
@addMethod(CR4ScriptedHud)
event OnCMFMinimapAddonLoaded(hudClass : string)
{
	CMFLog("minimap add-on movie loaded hud=" + hudClass);
}

@addField(CR4HudModulePickedItemsInfo)
var cmfClearStylesSFF : CScriptedFlashFunction;

@addField(CR4HudModulePickedItemsInfo)
var cmfSetStyleSFF : CScriptedFlashFunction;

@addField(CR4HudModulePickedItemsInfo)
var cmfSetHiddenSFF : CScriptedFlashFunction;

@addField(CR4HudModulePickedItemsInfo)
var cmfApplyStylesSFF : CScriptedFlashFunction;

@addField(CR4HudModulePickedItemsInfo)
var cmfTickSFF : CScriptedFlashFunction;

@addField(CR4HudModulePickedItemsInfo)
var cmfSentRevision : int;

@addField(CR4HudModulePickedItemsInfo)
var cmfStylesSent : bool;

@wrapMethod(CR4HudModulePickedItemsInfo)
function OnConfigUI()
{
	var result : bool;
	result = wrappedMethod();
	cmfClearStylesSFF = NULL;
	cmfSetStyleSFF = NULL;
	cmfSetHiddenSFF = NULL;
	cmfApplyStylesSFF = NULL;
	cmfTickSFF = NULL;
	cmfStylesSent = false;
	CMFLog("minimap add-on part ready");
	CMFPushMinimapStyles();
	return result;
}

@wrapMethod(CR4HudModulePickedItemsInfo)
function OnTick(timeDelta : float)
{
	var result : bool;
	result = wrappedMethod(timeDelta);
	CMFPushMinimapStyles();
	if (cmfTickSFF)
	{
		cmfTickSFF.InvokeSelf();
	}
	return result;
}

@addMethod(CR4HudModulePickedItemsInfo)
event OnCMFMinimapFound(minimapClass : string, pinLayers : int)
{
	CMFLog("minimap found class=" + minimapClass + " layers=" + pinLayers);
}

@addMethod(CR4HudModulePickedItemsInfo)
event OnCMFMinimapPin(pinType : string, x : float, y : float, claimed : bool)
{
	var claimText : string;
	claimText = "no";
	if (claimed)
	{
		claimText = "yes";
	}
	CMFLog("minimap pin type=" + pinType + " x=" + FloatToString(x) + " y=" + FloatToString(y) + " claimed=" + claimText);
}

@addMethod(CR4HudModulePickedItemsInfo)
event OnCMFMinimapArtFailed(url : string)
{
	CMFLog("minimap art failed " + url);
}

// Cheap when nothing changed: one revision read per HUD tick.
@addMethod(CR4HudModulePickedItemsInfo)
public function CMFPushMinimapStyles()
{
	var core : CMFCore;
	var flashModule : CScriptedFlashSprite;
	var types : array<name>;
	var claim : SCMFClaim;
	var iconPath, poster : string;
	var tint : int;
	var tinted : bool;
	var revision, i, sent, hidden, nativePosters, unrepresented : int;
	core = theGame.CMFGetCore();
	revision = core.GetRevision();
	if (cmfStylesSent && revision == cmfSentRevision)
	{
		return;
	}
	if (!cmfSetStyleSFF)
	{
		flashModule = GetModuleFlash();
		if (!flashModule)
		{
			return;
		}
		cmfClearStylesSFF = flashModule.GetMemberFlashFunction("CMFClearTypeStyles");
		cmfSetStyleSFF = flashModule.GetMemberFlashFunction("CMFSetTypeStyle");
		cmfSetHiddenSFF = flashModule.GetMemberFlashFunction("CMFSetTypeHidden");
		cmfApplyStylesSFF = flashModule.GetMemberFlashFunction("CMFApplyTypeStyles");
		cmfTickSFF = flashModule.GetMemberFlashFunction("CMFTick");
	}
	if (!cmfClearStylesSFF || !cmfSetStyleSFF || !cmfSetHiddenSFF || !cmfApplyStylesSFF)
	{
		return;
	}
	cmfClearStylesSFF.InvokeSelf();
	CMFMinimapPinTypes(types);
	sent = 0;
	hidden = 0;
	for (i = 0; i < types.Size(); i += 1)
	{
		// A hide wins over every other property, as on the world map.
		if (core.CMFMinimapHidesType(types[i]))
		{
			cmfSetHiddenSFF.InvokeSelfOneArg(FlashArgString(NameToString(types[i])));
			hidden += 1;
			continue;
		}
		iconPath = "";
		tint = 0;
		tinted = false;
		if (core.FindTypeWinner(CMFPropertyIcon(), types[i], claim))
		{
			iconPath = claim.text;
		}
		// Property 1 is one legacy bitmap URL: commas and semicolons can be part of its path.
		// Only the animation route below applies frame-token delimiter rules.
		if (!StrBeginsWith(iconPath, "img://"))
		{
			iconPath = "";
		}
		// GetRevision is a winner-cache revision, never an API capability check.
		if (CMFGetVersion() >= 14)
		{
			if (core.FindTypeWinner(45, types[i], claim))
			{
				poster = CMFMinimapPoster(claim.text);
				if (CMFMinimapBitmap(poster))
				{
					iconPath = poster;
				}
				else if (StrBeginsWith(poster, "frame:"))
				{
					nativePosters += 1;
				}
				else
				{
					unrepresented += 1;
				}
			}
		}
		if (core.FindTypeWinner(CMFPropertyTint(), types[i], claim))
		{
			tint = claim.number;
			tinted = true;
		}
		if (iconPath != "" || tinted)
		{
			cmfSetStyleSFF.InvokeSelfFourArgs(FlashArgString(NameToString(types[i])), FlashArgString(iconPath),
				FlashArgInt(tint), FlashArgBool(tinted));
			sent += 1;
		}
	}
	cmfApplyStylesSFF.InvokeSelf();
	cmfSentRevision = revision;
	cmfStylesSent = true;
	if (nativePosters > 0 || unrepresented > 0)
	{
		CMFLog("minimap posters revision=" + revision + " native=" + nativePosters + " unrepresented=" + unrepresented +
			" reason=keep still or native picture");
	}
	CMFLog("minimap styles revision=" + revision + " types=" + sent + " hidden=" + hidden);
}

// Local extraction from the winning core-validated author claim. This optional script must not
// reference API 14 core helpers, even behind a runtime guard. Only a single safe path leaves here.
function CMFMinimapTrim(text : string) : string
{
	var first, last : int;
	var letter : string;
	last = StrLen(text);
	while (first < last)
	{
		letter = StrMid(text, first, 1);
		if (letter != " " && letter != StrChar(9) && letter != StrChar(10) &&
			letter != StrChar(11) && letter != StrChar(12) && letter != StrChar(13)) { break; }
		first += 1;
	}
	while (last > first)
	{
		letter = StrMid(text, last - 1, 1);
		if (letter != " " && letter != StrChar(9) && letter != StrChar(10) &&
			letter != StrChar(11) && letter != StrChar(12) && letter != StrChar(13)) { break; }
		last -= 1;
	}
	return StrMid(text, first, last - first);
}

function CMFMinimapPath(text : string) : bool
{
	var i : int;
	if ((!StrBeginsWith(text, "img://") || StrLen(text) <= 6) &&
		(!StrBeginsWith(text, "frame:") || StrLen(text) <= 6)) { return false; }
	if (StrFindFirst(text, ",") >= 0 || StrFindFirst(text, "|") >= 0 || StrFindFirst(text, ";") >= 0) { return false; }
	for (i = 0; i < 32; i += 1)
	{
		if (StrFindFirst(text, StrChar(i)) >= 0) { return false; }
	}
	return StrFindFirst(text, StrChar(127)) < 0;
}

function CMFMinimapBitmap(text : string) : bool
{
	return StrBeginsWith(text, "img://") && CMFMinimapPath(text);
}

// Validate the list boundary while selecting its first authored position. Repeated paths are valid.
function CMFMinimapFirstFrame(text : string) : string
{
	var rest, path, first : string;
	var count : int;
	var more : bool;
	rest = text;
	more = true;
	while (more)
	{
		more = StrFindFirst(rest, ",") >= 0;
		path = rest;
		if (more)
		{
			path = StrBeforeFirst(rest, ",");
			rest = StrAfterFirst(rest, ",");
		}
		path = CMFMinimapTrim(path);
		if (!CMFMinimapPath(path)) { return ""; }
		if (count == 0) { first = path; }
		count += 1;
		if (count > 16) { return ""; }
	}
	if (count < 2) { return ""; }
	return first;
}

function CMFMinimapPoster(text : string) : string
{
	var rest, record, fields, field, key, value, poster, first, stageFirst : string;
	var seen, stageSeen : string;
	var stageCount : int;
	var more, fieldMore : bool;
	text = CMFMinimapTrim(text);
	if (StrLen(text) > 8192) { return ""; }
	if (StrFindFirst(text, "|") < 0 || CMFMinimapTrim(StrBeforeFirst(text, "|")) != "program:v1")
	{
		return CMFMinimapFirstFrame(text);
	}
	rest = StrAfterFirst(text, "|");
	more = true;
	while (more)
	{
		more = StrFindFirst(rest, "|") >= 0;
		record = rest;
		if (more)
		{
			record = StrBeforeFirst(rest, "|");
			rest = StrAfterFirst(rest, "|");
		}
		record = CMFMinimapTrim(record);
		if (StrFindFirst(record, "=") < 0) { return ""; }
		key = CMFMinimapTrim(StrBeforeFirst(record, "="));
		if (key == "stage")
		{
			stageCount += 1;
			if (stageCount > 8) { return ""; }
			fields = record;
			fieldMore = true;
			stageFirst = "";
			stageSeen = ",";
			while (fieldMore)
			{
				fieldMore = StrFindFirst(fields, ";") >= 0;
				field = fields;
				if (fieldMore)
				{
					field = StrBeforeFirst(fields, ";");
					fields = StrAfterFirst(fields, ";");
				}
				if (StrFindFirst(field, "=") < 0) { return ""; }
				key = CMFMinimapTrim(StrBeforeFirst(field, "="));
				value = CMFMinimapTrim(StrAfterFirst(field, "="));
				if (key == "" || value == "" || StrFindFirst(stageSeen, "," + key + ",") >= 0) { return ""; }
				stageSeen += key + ",";
				if (key == "frames")
				{
					stageFirst = CMFMinimapFirstFrame(value);
					if (stageFirst == "") { return ""; }
				}
				else if (key != "stage" && key != "fps" && key != "plays" && key != "direction" && key != "holdFirst" &&
					key != "holdLast" && key != "offset" && key != "delay") { return ""; }
			}
			if (stageFirst == "") { return ""; }
			if (stageCount == 1) { first = stageFirst; }
		}
		else
		{
			value = CMFMinimapTrim(StrAfterFirst(record, "="));
			if (value == "" || StrFindFirst(seen, "," + key + ",") >= 0) { return ""; }
			seen += "," + key + ",";
			if (key == "poster")
			{
				if (value != "first" && !CMFMinimapPath(value)) { return ""; }
				poster = value;
			}
			else if (key != "delay" && key != "finish" && key != "join" && key != "repeat" && key != "repeatFrom") { return ""; }
		}
	}
	if (stageCount == 0) { return ""; }
	if (poster == "" || poster == "first") { return first; }
	return poster;
}

// True when a type-level hide claim (CMF 3) covers every minimap pin of this type: it names the type itself,
// holds for every map context, and carries no exemption that a pin of this type could meet (fast travel:
// RoadSign, Harbor and Transport, as the game's map sets isFastTravel; quest and tracked: any type the game
// calls a quest pin type, any type named ...Quest..., and the races, which the game's map tracks like quest
// objectives; erring towards showing the pin). The minimap shows a pin's
// type only, so a hide that spares some pins of a type, by tag, by one pin or by an exemption, stays
// world-map only, and the pin keeps showing.
@addMethod(CMFCore)
public function CMFMinimapHidesType(pinType : name) : bool
{
	var i : int;
	var flags : int;
	var questType : bool;
	var travelType : bool;
	questType = theGame.GetCommonMapManager().IsQuestPinType(pinType) ||
		StrFindFirst(NameToString(pinType), "Quest") >= 0 || pinType == 'HorseRace' || pinType == 'BoatRace';
	travelType = pinType == 'RoadSign' || pinType == 'Harbor' || pinType == 'Transport';
	for (i = 0; i < hideClaims.Size(); i += 1)
	{
		if (hideClaims[i].level != 1 || hideClaims[i].pinType != pinType || IsNameValid(hideClaims[i].mapContext))
		{
			continue;
		}
		flags = hideClaims[i].number;
		if (questType && (CMFHasFlag(flags, CMFExemptQuest()) || CMFHasFlag(flags, CMFExemptTracked())))
		{
			continue;
		}
		if (travelType && CMFHasFlag(flags, CMFExemptFastTravel()))
		{
			continue;
		}
		return true;
	}
	return false;
}

// Base names of the vanilla 5.01 minimap's class<Type> pin symbols (the add-on also matches the _1 to _3
// level variants to their base type). tools/cmf_minimap_panel.py refuses a build when this list and the
// game's minimap movie differ.
function CMFMinimapPinTypes(out types : array<name>)
{
	types.Clear();
	types.PushBack('Alchemic');
	types.PushBack('AlchemyTable');
	types.PushBack('Archmaster');
	types.PushBack('ArmorRepairTable');
	types.PushBack('Armorer');
	types.PushBack('BanditCamp');
	types.PushBack('BanditCampDisabled');
	types.PushBack('BanditCampfire');
	types.PushBack('BanditCampfireDisabled');
	types.PushBack('Bed');
	types.PushBack('Blacksmith');
	types.PushBack('Boat');
	types.PushBack('BoatBuilder');
	types.PushBack('BoatRace');
	types.PushBack('Bookshelf');
	types.PushBack('BossAndTreasure');
	types.PushBack('BossAndTreasureDisabled');
	types.PushBack('Cammerlengo');
	types.PushBack('ChapterQuest');
	types.PushBack('Companion');
	types.PushBack('Contraband');
	types.PushBack('ContrabandDisabled');
	types.PushBack('ContrabandShip');
	types.PushBack('ContrabandShipDisabled');
	types.PushBack('DungeonCrawl');
	types.PushBack('DungeonCrawlDisabled');
	types.PushBack('DyeMerchant');
	types.PushBack('Enchanter');
	types.PushBack('Enemy');
	types.PushBack('EnemyDead');
	types.PushBack('Entrance');
	types.PushBack('GenericFocus');
	types.PushBack('Hairdresser');
	types.PushBack('Harbor');
	types.PushBack('Herb');
	types.PushBack('Herbalist');
	types.PushBack('Hideout');
	types.PushBack('HideoutDisabled');
	types.PushBack('Horse');
	types.PushBack('HorseRace');
	types.PushBack('HorseRaceDummy');
	types.PushBack('HorseRaceTarget');
	types.PushBack('HorseRacingNPC');
	types.PushBack('InfestedVineyard');
	types.PushBack('InfestedVineyardDisabled');
	types.PushBack('Innkeeper');
	types.PushBack('KnightErrant');
	types.PushBack('KnightErrantDisabled');
	types.PushBack('MagicLamp');
	types.PushBack('MonsterHunt');
	types.PushBack('MonsterNest');
	types.PushBack('MonsterNestDisabled');
	types.PushBack('MonsterQuest');
	types.PushBack('MutagenDismantle');
	types.PushBack('NonQuestHorseRace');
	types.PushBack('NotDiscoveredPOI');
	types.PushBack('NoticeBoard');
	types.PushBack('NoticeBoardFull');
	types.PushBack('PlaceOfPower');
	types.PushBack('PlaceOfPowerDisabled');
	types.PushBack('PlayerStash');
	types.PushBack('PlayerStashDiscoverable');
	types.PushBack('Plegmund');
	types.PushBack('PlegmundDisabled');
	types.PushBack('Prostitute');
	types.PushBack('QuestAvailable');
	types.PushBack('QuestAvailableBaW');
	types.PushBack('QuestAvailableHoS');
	types.PushBack('QuestBelgard');
	types.PushBack('QuestCoronata');
	types.PushBack('QuestLoot');
	types.PushBack('QuestObjective');
	types.PushBack('QuestObjectiveOther');
	types.PushBack('QuestReturn');
	types.PushBack('QuestVermentino');
	types.PushBack('RescuingTown');
	types.PushBack('RescuingTownDisabled');
	types.PushBack('Rift');
	types.PushBack('RoadSign');
	types.PushBack('Shopkeeper');
	types.PushBack('SideQuest');
	types.PushBack('SignalingStake');
	types.PushBack('SignalingStakeDisabled');
	types.PushBack('SpoilsOfWar');
	types.PushBack('SpoilsOfWarDisabled');
	types.PushBack('Stables');
	types.PushBack('StoryQuest');
	types.PushBack('Teleport');
	types.PushBack('Torch');
	types.PushBack('TreasureHuntMappin');
	types.PushBack('TreasureHuntMappinDisabled');
	types.PushBack('TreasureQuest');
	types.PushBack('User1');
	types.PushBack('User2');
	types.PushBack('User3');
	types.PushBack('User4');
	types.PushBack('Whetstone');
	types.PushBack('WineContract');
	types.PushBack('WineContractDisabled');
	types.PushBack('WineMerchant');
	types.PushBack('WitcherHouse');
}
