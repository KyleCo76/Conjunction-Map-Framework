// CMF Customizer 1.0.0 for Conjunction Map Framework. Requires CMF API 19 (the Player setting level and the size factors).
//
// The player's own pin settings: overall, quest and "?" pin size as multipliers of the size the winning mod gives
// (property 51), selected-pin growth as a multiplier (52), Standardize icon sizes (53), how icon labels show, which pin
// groups hide, and which hide when zoomed out. Every row starts Off, and a row at Off sends nothing, so CMF's Mod
// order decides that setting exactly as it does without this add-on. A row the player sets is sent as claims for this
// provider, and the properties that one winner decides (28, 36, 53) are marked as the player's own settings (property
// 50), so the claims win over every map mod and the Mod order (CMF's own pick rows still come first). Factors (51, 52)
// and hides add together, so they need no mark. The add-on never writes CMF's settings.
//
// A later version adds a per-icon-type size submenu. Its var names are reserved as CMFCZ_T_<Type>; each type's factor is
// then a type claim on 51 and the add-on sends, for each type, the most specific set row (type, group, overall).
//
// The rows are read at each map opening, before the first pin build: the wrapper of CR4MapMenu.OnConfigUI sends first.
// CMF without API 19 gets nothing at all; claims sent without the mark would be decided by the Mod order.

function CMFCZProvider() : string
{
	return "modCMFCustomizer";
}

// Row numbers: 0 pin size, 1 quest markers, 2 undiscovered places, 3 selected pin growth, 4 icon labels,
// 5 to 9 hide a group by zoom (General, Quests, Exploration, NPCs, Buffs), 10 Standardize icon sizes (the menu shows
// it under the pin size row).
function CMFCZVarName(row : int) : name
{
	switch (row)
	{
		case 0:
			return 'CMFCZ_Size';
		case 1:
			return 'CMFCZ_Quest';
		case 2:
			return 'CMFCZ_Unknown';
		case 3:
			return 'CMFCZ_Selected';
		case 4:
			return 'CMFCZ_Labels';
		case 5:
			return 'CMFCZ_Far_General';
		case 6:
			return 'CMFCZ_Far_Quests';
		case 7:
			return 'CMFCZ_Far_Exploration';
		case 8:
			return 'CMFCZ_Far_NPCs';
		case 9:
			return 'CMFCZ_Far_Buffs';
		case 10:
			return 'CMFCZ_Standard';
	}
	return 'CMFCZ_Size';
}

function CMFCZSizePercent(index : int) : int
{
	switch (index)
	{
		case 1:
			return 50;
		case 2:
			return 75;
		case 3:
			return 90;
		case 4:
			return 110;
		case 5:
			return 125;
		case 6:
			return 150;
		case 7:
			return 175;
		case 8:
			return 200;
		case 9:
			return 250;
		case 10:
			return 300;
	}
	return 0;
}

function CMFCZGrowthPercent(index : int) : int
{
	switch (index)
	{
		case 1:
			return 110;
		case 2:
			return 125;
		case 3:
			return 150;
		case 4:
			return 175;
		case 5:
			return 200;
	}
	return 0;
}

// The value a row sends for an option index: a percent (a factor of the pack's size) for the size and growth rows, the option index itself for the
// others (labels 1 Always, 2 Never, 3 On hover; zoom rows 1 hide when zoomed far out, 2 hide when zoomed out, 3 always hide). 0 = Off or out of range.
function CMFCZValue(row : int, index : int) : int
{
	if (row <= 2)
	{
		return CMFCZSizePercent(index);
	}
	if (row == 3)
	{
		return CMFCZGrowthPercent(index);
	}
	if (row == 4 && index >= 1 && index <= 3)
	{
		return index;
	}
	if (row >= 5 && row <= 9 && index >= 1 && index <= 3)
	{
		return index;
	}
	if (row == 10 && index == 1)
	{
		return 1;
	}
	return 0;
}

// Pin zoom ranges: the panel hides a pin when the map's zoom is below its minimum or above its maximum, and a higher zoom
// is closer. 1 hides the group when zoomed far out (below 2.75) and 2 when zoomed out (below 4.7, so pins show only at the
// closest zoom of most regions), the game's own switch points. The maximum is above every region's closest zoom (9). The
// panel holds a minimum inside the region's range, so 4.7 in White Orchard (0.9 to 3.5) acts as its closest zoom. 3 is not a
// zoom range: it hides the group at every zoom with the hide claim (property 9), which a range cannot express (the core
// refuses a minimum above the maximum).
function CMFCZZoomRange(level : int) : string
{
	if (level == 1)
	{
		return "2.75,1000";
	}
	return "4.7,1000";
}

// BEGIN pin type lists: written by tools/cmf_customizer_addon.py from tools/cmf_pin_types.json
function CMFCZAddQuest(out list : array<name>)
{
	list.PushBack('StoryQuest');
	list.PushBack('ChapterQuest');
	list.PushBack('SideQuest');
	list.PushBack('MonsterQuest');
	list.PushBack('TreasureQuest');
	list.PushBack('QuestReturn');
	list.PushBack('QuestBelgard');
	list.PushBack('QuestCoronata');
	list.PushBack('QuestVermentino');
	list.PushBack('QuestAvailable');
	list.PushBack('QuestAvailableHoS');
	list.PushBack('QuestAvailableBaW');
	list.PushBack('QuestAvailableLy');
	list.PushBack('QuestObjective');
	list.PushBack('QuestObjectiveOther');
}

function CMFCZAddUnknown(out list : array<name>)
{
	list.PushBack('NotDiscoveredPOI');
	list.PushBack('NotDiscoveredPOI_1');
	list.PushBack('NotDiscoveredPOI_2');
	list.PushBack('NotDiscoveredPOI_3');
}

function CMFCZAddGeneral1(out list : array<name>)
{
	list.PushBack('RoadSign');
	list.PushBack('Harbor');
	list.PushBack('NoticeBoardFull');
	list.PushBack('NoticeBoard');
	list.PushBack('PlayerStash');
	list.PushBack('PlayerStashDiscoverable');
	list.PushBack('Horse');
	list.PushBack('Transport');
}

function CMFCZAddQuests1(out list : array<name>)
{
	list.PushBack('StoryQuest');
	list.PushBack('ChapterQuest');
	list.PushBack('SideQuest');
	list.PushBack('MonsterQuest');
	list.PushBack('TreasureQuest');
	list.PushBack('QuestReturn');
	list.PushBack('HorseRace');
	list.PushBack('NonQuestHorseRace');
	list.PushBack('BoatRace');
	list.PushBack('QuestBelgard');
	list.PushBack('QuestCoronata');
	list.PushBack('QuestVermentino');
}

function CMFCZAddQuests2(out list : array<name>)
{
	list.PushBack('QuestAvailable');
	list.PushBack('QuestAvailableHoS');
	list.PushBack('QuestAvailableBaW');
	list.PushBack('QuestAvailableLy');
	list.PushBack('QuestObjective');
	list.PushBack('QuestObjectiveOther');
}

function CMFCZAddExploration1(out list : array<name>)
{
	list.PushBack('Entrance');
	list.PushBack('NotDiscoveredPOI');
	list.PushBack('NotDiscoveredPOI_1');
	list.PushBack('NotDiscoveredPOI_2');
	list.PushBack('NotDiscoveredPOI_3');
	list.PushBack('MonsterNest');
	list.PushBack('MonsterNest_1');
	list.PushBack('MonsterNest_2');
	list.PushBack('MonsterNest_3');
	list.PushBack('MonsterNestDisabled');
	list.PushBack('TreasureHuntMappin');
	list.PushBack('TreasureHuntMappin_1');
}

function CMFCZAddExploration2(out list : array<name>)
{
	list.PushBack('TreasureHuntMappin_2');
	list.PushBack('TreasureHuntMappin_3');
	list.PushBack('TreasureHuntMappinDisabled');
	list.PushBack('SpoilsOfWar');
	list.PushBack('SpoilsOfWar_1');
	list.PushBack('SpoilsOfWar_2');
	list.PushBack('SpoilsOfWar_3');
	list.PushBack('SpoilsOfWarDisabled');
	list.PushBack('BanditCamp');
	list.PushBack('BanditCamp_1');
	list.PushBack('BanditCamp_2');
	list.PushBack('BanditCamp_3');
}

function CMFCZAddExploration3(out list : array<name>)
{
	list.PushBack('BanditCampDisabled');
	list.PushBack('BanditCampfire');
	list.PushBack('BanditCampfire_1');
	list.PushBack('BanditCampfire_2');
	list.PushBack('BanditCampfire_3');
	list.PushBack('BanditCampfireDisabled');
	list.PushBack('BossAndTreasure');
	list.PushBack('BossAndTreasure_1');
	list.PushBack('BossAndTreasure_2');
	list.PushBack('BossAndTreasure_3');
	list.PushBack('BossAndTreasureDisabled');
	list.PushBack('Contraband');
}

function CMFCZAddExploration4(out list : array<name>)
{
	list.PushBack('Contraband_1');
	list.PushBack('Contraband_2');
	list.PushBack('Contraband_3');
	list.PushBack('ContrabandDisabled');
	list.PushBack('ContrabandShip');
	list.PushBack('ContrabandShip_1');
	list.PushBack('ContrabandShip_2');
	list.PushBack('ContrabandShip_3');
	list.PushBack('ContrabandShipDisabled');
	list.PushBack('RescuingTown');
	list.PushBack('RescuingTown_1');
	list.PushBack('RescuingTown_2');
}

function CMFCZAddExploration5(out list : array<name>)
{
	list.PushBack('RescuingTown_3');
	list.PushBack('RescuingTownDisabled');
	list.PushBack('DungeonCrawl');
	list.PushBack('DungeonCrawl_1');
	list.PushBack('DungeonCrawl_2');
	list.PushBack('DungeonCrawl_3');
	list.PushBack('DungeonCrawlDisabled');
	list.PushBack('Hideout');
	list.PushBack('HideoutDisabled');
	list.PushBack('InfestedVineyard');
	list.PushBack('InfestedVineyard_1');
	list.PushBack('InfestedVineyard_2');
}

function CMFCZAddExploration6(out list : array<name>)
{
	list.PushBack('InfestedVineyard_3');
	list.PushBack('InfestedVineyardDisabled');
	list.PushBack('Plegmund');
	list.PushBack('WineContract');
	list.PushBack('KnightErrant');
	list.PushBack('SignalingStake');
	list.PushBack('Boat');
}

function CMFCZAddNPCs1(out list : array<name>)
{
	list.PushBack('Shopkeeper');
	list.PushBack('Archmaster');
	list.PushBack('Blacksmith');
	list.PushBack('Armorer');
	list.PushBack('Alchemic');
	list.PushBack('Herbalist');
	list.PushBack('Innkeeper');
	list.PushBack('Enchanter');
	list.PushBack('Prostitute');
	list.PushBack('Hairdresser');
	list.PushBack('Torch');
	list.PushBack('WineMerchant');
}

function CMFCZAddNPCs2(out list : array<name>)
{
	list.PushBack('DyeMerchant');
	list.PushBack('Cammerlengo');
}

function CMFCZAddBuffs1(out list : array<name>)
{
	list.PushBack('PlaceOfPower');
	list.PushBack('PlaceOfPower_1');
	list.PushBack('PlaceOfPower_2');
	list.PushBack('PlaceOfPower_3');
	list.PushBack('PlaceOfPowerDisabled');
	list.PushBack('Whetstone');
	list.PushBack('GrindStone');
	list.PushBack('ArmorRepairTable');
	list.PushBack('AlchemyTable');
	list.PushBack('MutagenDismantle');
	list.PushBack('Bookshelf');
}

// The pin types of a group (General, Quests, Exploration, NPCs, Buffs). Never Player or User1 to User7.
function CMFCZAddGroup(group : int, out list : array<name>)
{
	if (group == 0)
	{
		CMFCZAddGeneral1(list);
	}
	if (group == 1)
	{
		CMFCZAddQuests1(list);
		CMFCZAddQuests2(list);
	}
	if (group == 2)
	{
		CMFCZAddExploration1(list);
		CMFCZAddExploration2(list);
		CMFCZAddExploration3(list);
		CMFCZAddExploration4(list);
		CMFCZAddExploration5(list);
		CMFCZAddExploration6(list);
	}
	if (group == 3)
	{
		CMFCZAddNPCs1(list);
		CMFCZAddNPCs2(list);
	}
	if (group == 4)
	{
		CMFCZAddBuffs1(list);
	}
}
// END pin type lists

// The targets of a row: the pin types it claims on, or one empty name for every pin.
function CMFCZTargets(row : int, out list : array<name>)
{
	list.Clear();
	if (row == 0 || row == 3 || row == 4 || row == 10)
	{
		list.PushBack('');
	}
	else if (row == 1)
	{
		CMFCZAddQuest(list);
	}
	else if (row == 2)
	{
		CMFCZAddUnknown(list);
	}
	else
	{
		CMFCZAddGroup(row - 5, list);
	}
}

// The properties a row sends (all of them are withdrawn when the row changes or goes Off).
function CMFCZProps(row : int) : string
{
	switch (row)
	{
		case 0:
			return "51";
		case 1:
			return "51";
		case 2:
			return "51";
		case 3:
			return "52";
		case 4:
			return "28,13";
		case 10:
			return "53";
	}
	return "36,9";
}

function CMFCZHead(list : string) : string
{
	if (StrFindFirst(list, ",") < 0)
	{
		return list;
	}
	return StrBeforeFirst(list, ",");
}

function CMFCZTail(list : string) : string
{
	if (StrFindFirst(list, ",") < 0)
	{
		return "";
	}
	return StrAfterFirst(list, ",");
}

// The state of the session: -1 never read; the option index last sent per row; the mark list last sent.
@addField(CR4Game)
var cmfczSent : array<int>;

@addField(CR4Game)
var cmfczMarks : string;

// 0 not asked, 1 CMF takes player settings, 2 it does not (nothing is sent).
@addField(CR4Game)
var cmfczState : int;

@addMethod(CR4Game)
function CMFCZReset()
{
	var i : int;
	cmfczSent.Clear();
	for (i = 0; i < 11; i += 1)
	{
		cmfczSent.PushBack(-1);
	}
	cmfczMarks = "";
	cmfczState = 0;
}

@addMethod(CR4Game)
function CMFCZReady() : bool
{
	if (cmfczState == 0)
	{
		cmfczState = 2;
		if (CMFHasAbility('claims', 'playerSetting') && CMFHasAbility('claims', 'scaleFactor') && CMFHasAbility('claims', 'scaleStandard'))
		{
			cmfczState = 1;
		}
		else
		{
			CMFLog("customizer needs CMF API 19 (found " + CMFGetVersion() + ")");
		}
	}
	return cmfczState == 1;
}

// One claim of a row: size factors, growth factor, Standardize, labels, hides and zoom ranges for one target.
@addMethod(CR4Game)
function CMFCZSendOne(row : int, value : int, pin : name)
{
	var label : int;
	if (row <= 2)
	{
		CMFRegister(CMFCZProvider(), 51, pin, '', "", value);
	}
	else if (row == 3)
	{
		CMFRegister(CMFCZProvider(), 52, pin, '', "", value);
	}
	else if (row == 10)
	{
		CMFRegister(CMFCZProvider(), 53, pin, '', "", 1);
	}
	else if (row == 4)
	{
		label = 0;
		if (value == 3)
		{
			label = 1;
		}
		if (value == 2)
		{
			CMFRegister(CMFCZProvider(), 13, pin, '', "pin", 1);
		}
		else
		{
			CMFRegister(CMFCZProvider(), 28, pin, '', "", label);
		}
	}
	else if (value == 3)
	{
		CMFRegister(CMFCZProvider(), 9, pin, '', "", 1);
	}
	else
	{
		CMFRegister(CMFCZProvider(), 36, pin, '', CMFCZZoomRange(value), 0);
	}
}

@addMethod(CR4Game)
function CMFCZSendRow(row : int, index : int)
{
	var value, i : int;
	var targets : array<name>;
	value = CMFCZValue(row, index);
	if (value <= 0)
	{
		return;
	}
	CMFCZTargets(row, targets);
	for (i = 0; i < targets.Size(); i += 1)
	{
		CMFCZSendOne(row, value, targets[i]);
	}
}

// Withdraw (property 40) every claim the row can have sent, at the same slots.
@addMethod(CR4Game)
function CMFCZDropRow(row : int)
{
	var targets : array<name>;
	var props, prop : string;
	var i : int;
	CMFCZTargets(row, targets);
	for (i = 0; i < targets.Size(); i += 1)
	{
		props = CMFCZProps(row);
		while (StrLen(props) > 0)
		{
			prop = CMFCZHead(props);
			props = CMFCZTail(props);
			CMFRegister(CMFCZProvider(), 40, targets[i], '', "", StringToInt(prop, 0));
		}
	}
}

// The properties of the set rows that one winner decides, in ascending order: 28 labels Always or On hover, 36 the zoom
// rows (not Always hide), 53 Standardize. Size and growth factors (51, 52), hiding and Never labels add together, so they
// are not marked.
@addMethod(CR4Game)
function CMFCZMarks() : string
{
	var marks : string;
	var i : int;
	var zoom : bool;
	marks = "";
	if (cmfczSent[4] == 1 || cmfczSent[4] == 3)
	{
		marks = "28";
	}
	zoom = false;
	for (i = 5; i < 10; i += 1)
	{
		if (cmfczSent[i] == 1 || cmfczSent[i] == 2) { zoom = true; }
	}
	if (zoom)
	{
		if (StrLen(marks) > 0) { marks += ","; }
		marks += "36";
	}
	if (cmfczSent[10] > 0)
	{
		if (StrLen(marks) > 0) { marks += ","; }
		marks += "53";
	}
	return marks;
}

// At each map opening, before the first pin build: send what changed since the last time.
@addMethod(CR4Game)
function CMFCZApply()
{
	var i, index : int;
	var marks, note : string;
	var config : CInGameConfigWrapper;
	if (!CMFCZReady())
	{
		return;
	}
	config = theGame.GetInGameConfigWrapper();
	note = "";
	for (i = 0; i < 11; i += 1)
	{
		index = StringToInt(config.GetVarValue('CMFCustomizer', CMFCZVarName(i)), 0);
		if (index != cmfczSent[i])
		{
			if (cmfczSent[i] > 0)
			{
				CMFCZDropRow(i);
			}
			if (index > 0)
			{
				CMFCZSendRow(i, index);
			}
			cmfczSent[i] = index;
			note += " " + NameToString(CMFCZVarName(i)) + "=" + index;
		}
	}
	marks = CMFCZMarks();
	if (marks != cmfczMarks)
	{
		CMFRegister(CMFCZProvider(), 50, '', '', marks, 1);
		cmfczMarks = marks;
		note += " marks=" + marks;
	}
	if (StrLen(note) > 0)
	{
		CMFLog("customizer sent" + note);
	}
}

// Presence and the menu name. The state is set up once per session and kept across save loads: CMF's core lives as long
// as the game object and keeps the claims and marks, so a row set to Off after a load must still withdraw what it sent.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (cmfczSent.Size() != 11)
	{
		CMFCZReset();
	}
	CMFDeclareProvider(CMFCZProvider());
	CMFSetProviderName(CMFCZProvider(), "CMF Customizer");
	return result;
}

// Before the map's own wrapper builds anything, so the opening's first pin build has the claims.
@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	var result : bool;
	theGame.CMFCZApply();
	result = wrappedMethod();
	return result;
}
