// Map Quest Insight adapter 2.2.0 for Conjunction Map Framework. Requires CMF 1.6.0 (API version 13) and Map Quest
// Insight 2.1.0 or later (Nexus 14219; the Quest List file uses names that exist from 2.1.0), which stays
// unchanged. Install and remove the two together: this file calls Map Quest Insight's own functions (QMI_OptTypeIcons, QMI_IconKind, QMI_LevelBandTint and QMI_ColorTrackedIcon exist
// from 2.0.0, which Wolfer named stable), so the game stops at the script compile screen when Map Quest Insight is
// missing or older, and it uses CMF 13's per-type theme call (CMFStyle) and info box fold hook (OnInfoFold), which
// earlier CMF versions do not have. Players on Map Quest Insight 2.0.1 keep adapter 2.1.0, on 2.0.0 adapter 2.0.0,
// on an older CMF or Map Quest Insight adapter 1.2.0.
//
// Map Quest Insight talks to its own map file: it asks the map for its handshake number (MapMenu.qmiApi),
// then writes icon sizes, quest icons by type, level and signpost labels, the crosshair-label switch,
// level colours and the scrolling info box height into the map, and hides signposts per filter tab. CMF's
// map answers none of those names. This adapter gives Map Quest Insight its handshake in script, then turns
// each value into CMF's general calls, as Map Quest Insight's author would when porting. It copies no code.
// Its pictures are Map Quest Insight's own, sent by its author, Wolfer, for the adapter and shipped with their
// permission: three quest icons (2026-10-21) and the 2.0.1 Sticker icons, round badges and type symbols
// (2026-10-25). Map Quest Insight 2.0's map features are carried with permission from Wolfer. Every claim uses Map Quest Insight's own folder name as its provider, so folder order
// between mods is the same with CMF as without it.
//
// The pin values ride on the pin objects, which the game builds from the map's pin class: CMF's map
// declares Map Quest Insight's pin field names (qmi*) for this adapter only, because the game drops any
// field its class does not declare. CMF itself never reads them.
//
// The file name starts with zz_ so it sorts after qmiSettings.ws and questMapInfo.ws: wrappers nest by
// script file name, so these wrappers run around Map Quest Insight's.

// Presence is independent of map settings; the existing source-mod compile dependency stays required.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFHasProperty(38))
	{
		CMFRegister("modMapQuestInsight", 38, '', '', "", 1);
	}
	return result;
}

// The tabs that hide signposts in this map opening, from UpdateDisabledMapPins to OnPinReady.
@addField(CR4Game)
var mqiAdapterNoSignTabs : string;

// theGame is a constant outside its own class, so the game object assigns its own field.
@addMethod(CR4Game)
function MqiAdapterSetNoSignTabs(tabs : string)
{
	mqiAdapterNoSignTabs = tabs;
}

// The icon for a Map Quest Insight quest kind (questMapInfo.ws QMI_IconKind): a frame of the game's pin
// icon for kinds 4 and 6-10, Map Quest Insight's own icons (art/, in this adapter's texture.cache) for kinds
// 1, 3 and 5, or "" (kind 0 and 2 keep the diamond).
function MqiAdapterKindIcon(kind : int) : string
{
	switch (kind)
	{
		case 1:
			return "img://icons/modcmfadaptermapquestinsight/quest_main.png";
		case 3:
			return "img://icons/modcmfadaptermapquestinsight/quest_contract.png";
		case 4:
			return "frame:TreasureHuntMappin";
		case 5:
			return "img://icons/modcmfadaptermapquestinsight/quest_gwent.png";
		case 6:
			return "frame:HorseRace";
		case 7:
			return "frame:BoatRace";
		case 8:
			return "frame:FistFight";
		case 9:
			return "frame:KnightErrant";
		case 10:
			return "frame:WineContract";
	}
	return "";
}

// Map Quest Insight's handshake (questMapInfo.ws 3260-3279): it reads MapMenu.qmiApi once per map opening
// and sends what that map file can show. CMF's map answers every feature of map file 3 through this
// adapter, so the adapter records 3 in Map Quest Insight's own fields before anything is sent. Its
// settings reload inside this call (qmiSettings.ws OnConfigUI), so the info box height is read later.
@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	var result : bool;
	var descMore : bool;
	QMI_swfApi = 3;
	QMI_swfApiRead = true;
	// Map Quest Insight reads its Show more handshake once per opening, inside its own wrapper.
	descMore = MqiAdapterAskDescMore();
	MqiAdapterAskHubOver();
	mqiAdapterPinsReady = false;
	result = wrappedMethod();
	MqiAdapterPinsInit();
	MqiAdapterSendMotion();
	MqiAdapterSendSpread(mqiAdapterTravelMap);
	MqiAdapterSendWide();
	MqiAdapterSendBox();
	MqiAdapterSendBeside();
	MqiAdapterSendPanels();
	MqiAdapterSendFold(descMore, GetMenuFlash());
	MqiAdapterSendFullScreen();
	MqiAdapterSendCornerHud();
	MqiAdapterLogOpening(descMore, GetMenuFlash(), mqiAdapterTravelMap);
	return result;
}

// This opening is the fast travel map (or the player sails), from OnConfigUI to the pins.
@addField(CR4MapMenu)
var mqiAdapterTravelMap : bool;

@addField(CR4MapMenu)
var mqiAdapterPinsReady : bool;

// What the pins of this opening follow: the travel map and the quest icons. The game adds its pins inside
// OnConfigUI, after Map Quest Insight's wrapper has loaded its settings and before the adapter's wrapper returns,
// so the first pin reads them; values kept from the last opening would draw the first opening's pins without
// the badges.
@addMethod(CR4MapMenu)
function MqiAdapterPinsInit()
{
	if (mqiAdapterPinsReady)
	{
		return;
	}
	mqiAdapterPinsReady = true;
	// Map Quest Insight 2.0.1 spreads nothing on the fast travel map or while sailing; the same test.
	mqiAdapterTravelMap = QMI_MapCanFastTravel();
	theGame.MqiAdapterSetIcons(MqiAdapterIconMode(), MqiAdapterIconPercent(), MqiAdapterHexColour(QMI_ColorTrackedIcon()));
}

// Map Quest Insight's "Faster map" and "Zoom out to whole region" switches (Map markers, both default On;
// qmiSettings.ws QMI_OptFasterMap, QMI_OptZoomOut), read after its wrapper reloaded its settings and before
// CMF's map asks for its theme. Its own map file changes its timing and zoom limit when they are on
// (MapMenu.qmiSetFastMap, qmiSetZoomOut); under CMF the same values become CMF's navigation and opening keys,
// and a switch that is off withdraws them ("unset"), so another mod's values or the game's apply. A CMF
// without the opening part has neither these keys nor "unset", so nothing is sent there.
function MqiAdapterSendMotion()
{
	var faster : string;
	var zoomOut : string;
	if (!CMFHasAbility('opening', ''))
	{
		return;
	}
	faster = "unset";
	if (QMI_OptFasterMap())
	{
		faster = "";
	}
	zoomOut = "unset";
	if (QMI_OptZoomOut())
	{
		zoomOut = "";
	}
	MqiAdapterMotion('navigation', 'frameTimed', faster, 1);
	MqiAdapterMotion('navigation', 'stepMs', faster, 17);
	MqiAdapterMotion('navigation', 'worldStepMs', faster, 24);
	MqiAdapterMotion('navigation', 'maxStepMs', faster, 50);
	MqiAdapterMotion('navigation', 'zoomTimed', faster, 1);
	MqiAdapterMotion('navigation', 'padHoldMs', faster, 60);
	MqiAdapterMotion('navigation', 'tweenEveryFrame', faster, 1);
	MqiAdapterMotion('opening', 'slideSeconds', faster, 0.2);
	MqiAdapterMotion('opening', 'slideOffset', faster, 0);
	MqiAdapterMotion('opening', 'closeSeconds', faster, 0.1);
	MqiAdapterMotion('opening', 'pinsDuringSlide', faster, 1);
	MqiAdapterMotion('opening', 'pinStepMs', faster, 1);
	MqiAdapterMotion('opening', 'pinBatch', faster, 120);
	MqiAdapterMotion('opening', 'showDelayMs', faster, 1);
	MqiAdapterMotion('opening', 'fadeSeconds', faster, 0.1);
	MqiAdapterMotion('opening', 'tileFadeSeconds', faster, 0.2);
	MqiAdapterMotion('navigation', 'zoomOutFit', zoomOut, 1);
	MqiAdapterMotion('navigation', 'edgeOvershoot', zoomOut, 48);
}

// Map Quest Insight's "Spread stacked quest markers" switch (Map markers, default On; QMI_SpreadStackedMarkers,
// from 1.6.0). Its own map file then fans out the markers on one spot into a row under the cursor; under CMF
// the same values (its map file's: quest pins open a row within 20 px, pins within 24 px join, up to 8, 48 px
// apart, 150 ms to open and 120 ms to close, the pick kept within 24 px and the row within 48 px) become CMF's
// spread keys, and a switch that is off withdraws them ("unset"). Its ALSO HERE list stays: Map Quest Insight
// drops it only when its own map file answers qmiSpreadMap, which CMF's map does not.
function MqiAdapterSendSpread(travelMap : bool)
{
	var spread : string;
	if (!CMFHasAbility('spread', ''))
	{
		return;
	}
	spread = "unset";
	if (QMI_SpreadStackedMarkers() && !travelMap)
	{
		spread = "";
	}
	MqiAdapterMotion('spread', 'on', spread, 1);
	MqiAdapterMotion('spread', 'anyPin', spread, 0);
	MqiAdapterMotion('spread', 'enterRadius', spread, 20);
	MqiAdapterMotion('spread', 'stackDistance', spread, 24);
	MqiAdapterMotion('spread', 'maxPins', spread, 8);
	MqiAdapterMotion('spread', 'gap', spread, 48);
	MqiAdapterMotion('spread', 'openMs', spread, 150);
	MqiAdapterMotion('spread', 'closeMs', spread, 120);
	MqiAdapterMotion('spread', 'lockRadius', spread, 24);
	MqiAdapterMotion('spread', 'keepRadius', spread, 48);
}

// Map Quest Insight's "Ultrawide map" page (1.6.2; qmiSettings.ws, page qmiWide: the switch qmiUwMap, default On, and
// the side panels position qmiUwSidePos, 0 to 100 %, default 100). Its own map file then fills a screen wider than
// 16:9 and moves the side panels outward by that share; under CMF 10 the same choice becomes CMF's wide keys: off sends
// fill 0, so the switch keeps its meaning, and on sends fill 1 with panels at that share. The values are read by their
// menu names, not through QMI_OptUwMap and QMI_OptUwSidePos, so Map Quest Insight 1.6.1, which has no such page, still
// compiles and sends nothing (CMF's own layout then applies). A value never saved reads "" or "-1" and means Map Quest
// Insight's own default (On, 100 %).
function MqiAdapterSendWide()
{
	var config : CInGameConfigWrapper;
	var on, side : string;
	var panels : float;
	var i : int;
	var found : bool;
	if (!CMFHasAbility('wide', 'fill'))
	{
		return;
	}
	config = theGame.GetInGameConfigWrapper();
	found = false;
	for (i = 0; i < config.GetGroupsNum() && !found; i += 1)
	{
		found = config.GetGroupName(i) == 'qmiWide';
	}
	if (!found)
	{
		return;
	}
	on = config.GetVarValue('qmiWide', 'qmiUwMap');
	if (on != "" && on != "-1" && on != "true" && on != "1")
	{
		MqiAdapterMotion('wide', 'fill', "", 0);
		MqiAdapterMotion('wide', 'panels', "unset", 0);
		return;
	}
	panels = 1;
	side = config.GetVarValue('qmiWide', 'qmiUwSidePos');
	if (side != "" && side != "-1")
	{
		panels = ClampF(StringToFloat(side) / 100, 0, 1);
	}
	MqiAdapterMotion('wide', 'fill', "", 1);
	MqiAdapterMotion('wide', 'panels', "", panels);
}

// Where Map Quest Insight's own map file puts a tall info box (1.6.2 and 2.0.0 MapMenu.as alike, read 2026-10-25,
// probe info_box_place): a box over 330 px goes to x 1300 between y 130 and 906, or to x 112 between y 206 and 1006
// when the cursor is on the right half or the quest tracker is not in its normal state, under the legend, scaled down
// to fit; a shorter box keeps the game's place. CMF 12 takes that place apart from the box height (the info box height
// claim only makes the text scroll), so the adapter sends it as CMF's tall tooltip keys. A CMF before 12 has no such
// keys and places the scrolling box this way by itself. Its map file does this only while "Info box height" is set,
// so with the height at 0 the keys are withdrawn ("unset") and the game's place stays. Its map hides its category panel
// and shows its overview only while moving, so those corners are free there; CMF's map keeps its legend and overview,
// so tallClear keeps the places off them (Kyle 2026-10-25).
function MqiAdapterSendBox()
{
	var text : string;
	if (!CMFHasAbility('tooltip', 'tallMinHeight'))
	{
		return;
	}
	text = "";
	if ((int)(QMI_InfoBoxMaxHeight() + 0.5) <= 0)
	{
		text = "unset";
	}
	MqiAdapterMotion('tooltip', 'tallMinHeight', text, 330);
	MqiAdapterMotion('tooltip', 'tallX', text, 1300);
	MqiAdapterMotion('tooltip', 'tallTop', text, 130);
	MqiAdapterMotion('tooltip', 'tallBottom', text, 906);
	MqiAdapterMotion('tooltip', 'tallAltX', text, 112);
	MqiAdapterMotion('tooltip', 'tallAltTop', text, 206);
	MqiAdapterMotion('tooltip', 'tallAltBottom', text, 1006);
	MqiAdapterMotion('tooltip', 'tallUnderLegend', text, 1);
	MqiAdapterMotion('tooltip', 'tallClear', text, 1);
}

// One key under Map Quest Insight's folder name, only when this CMF takes it.
function MqiAdapterMotion(part : name, key : name, text : string, number : float)
{
	if (CMFHasAbility(part, key))
	{
		CMFStylePart("modMapQuestInsight", part, key, text, number);
	}
}

// After Map Quest Insight's own wrapper (settings loaded, before the pins are sent): the filter tabs in
// which it hides signposts for this map opening (its own options and fast-travel test, questMapInfo.ws
// 3452-3463), kept for OnPinReady, and its "Info box height" (QMI_InfoBoxMaxHeight, 224-229) as CMF's info
// box height claim for this opening; 0 withdraws it.
@wrapMethod(CR4MapMenu)
function UpdateDisabledMapPins()
{
	var tabs : string;
	var canTravel : bool;
	var height : int;
	wrappedMethod();
	tabs = "";
	canTravel = QMI_MapCanFastTravel();
	if (QMI_SignsHiddenNow(QMI_SignsInQuestsFilter(), canTravel))
	{
		tabs = "Quests";
	}
	if (QMI_SignsHiddenNow(QMI_SignsInOtherFilters(), canTravel))
	{
		if (tabs != "")
		{
			tabs += ",";
		}
		tabs += "Exploration,NPCs,Buffs";
		// Map Quest Insight 2.0 widened "Signposts in other filters" to All and Default, and to General while fast
		// travel is not possible here. 2.0 is told apart by the flag its one-time settings update leaves.
		if (MqiAdapterIs20())
		{
			tabs += ",All,Default";
			if (!canTravel)
			{
				tabs += ",General";
			}
		}
	}
	theGame.MqiAdapterSetNoSignTabs(tabs);
	// CMF takes 100-1080 px; 0 keeps the game's box.
	height = (int)(QMI_InfoBoxMaxHeight() + 0.5);
	if (height > 0 && height < 100)
	{
		height = 100;
	}
	if (height > 1080)
	{
		height = 1080;
	}
	CMFRegister("modMapQuestInsight", CMFPropertyInfoBoxHeight(), '', '', "", height);
}

// Map Quest Insight 2.0 or later: its one-time update to the 2.0.0 defaults sets [qmiGeneral] qmiMigrated200, which no
// older version has.
function MqiAdapterIs20() : bool
{
	var done : string;
	done = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('qmiGeneral', 'qmiMigrated200'));
	return done == "true" || done == "1";
}

// Which quest pin of a spread stack is selected first: Map Quest Insight's own rank of the pin's quest
// (QMI_SpreadRank: main quests first, then quests with a level, then the rest, one more when tracked), from the
// quest and level it uses itself (objective to quest as the game does, QMI_GetQuestLevel), claimed as CMF's
// SpreadRank. The quest is known here, from the game's pin, and not in OnPinReady, so the claim is made here.
@wrapMethod(CR4MapMenu)
function AddPinTypeData(out dataObject : CScriptedFlashObject, targetPin : SCommonMapPinInstance) : void
{
	var curObjective : CJournalQuestObjective;
	var curQuest : CJournalQuest;
	var rank : int;
	var level : int;
	var spread : bool;
	var file : string;
	var picture : float;
	wrappedMethod(dataObject, targetPin);
	if (!dataObject || !dataObject.GetMemberFlashBool("isQuest") || dataObject.GetMemberFlashBool("isFastTravel"))
	{
		return;
	}
	MqiAdapterPinsInit();
	spread = QMI_SpreadStackedMarkers() && !mqiAdapterTravelMap;
	if (!spread && theGame.mqiAdapterIconMode == 0)
	{
		return;
	}
	curObjective = (CJournalQuestObjective)theGame.GetJournalManager().GetEntryByGuid(targetPin.guid);
	if (!curObjective)
	{
		return;
	}
	curQuest = curObjective.GetParentQuest();
	if (!curQuest)
	{
		return;
	}
	level = QMI_GetQuestLevel(curQuest);
	if (spread)
	{
		rank = QMI_SpreadRank(curQuest, level);
		if (rank > 0)
		{
			CMFStylePin("modMapQuestInsight", dataObject, CMFPropertySpreadRank(), "", rank);
		}
	}
	if (theGame.mqiAdapterIconMode > 0)
	{
		file = MqiAdapterKindFile(QMI_IconKind(curQuest));
		picture = 0;
		if (file == "")
		{
			// A quest without a type keeps the diamond, with Map Quest Insight's own size and tint.
			MqiAdapterOwnScale(dataObject);
			MqiAdapterOwnTint(dataObject);
		}
		else
		{
			// The tracked quest's pins are the ones the game does not draw as another quest's objective.
			picture = MqiAdapterQuestIcon(dataObject, file, QMI_LevelBandTint(level),
				targetPin.visibleType != 'QuestObjectiveOther');
		}
		MqiAdapterLabelPlace(dataObject, picture);
	}
}

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var number : float;
	var text : string;
	var flags : int;
	var questPin : bool;
	var drawn : bool;
	var travel : bool;
	wrappedMethod(dataObject, mapContext);
	questPin = dataObject.GetMemberFlashBool("isQuest");
	travel = dataObject.GetMemberFlashBool("isFastTravel");
	// With quest icons by type on, AddPinTypeData already styled the quest pins' pictures.
	drawn = questPin && !travel && theGame.mqiAdapterIconMode > 0;
	if (!drawn)
	{
		MqiAdapterOwnScale(dataObject);
	}
	if (!drawn)
	{
		MqiAdapterLabelPlace(dataObject, 0);
	}
	if (questPin && !travel && !drawn)
	{
		text = MqiAdapterKindIcon(dataObject.GetMemberFlashInt("qmiIconKind"));
		if (text != "")
		{
			CMFStylePinIcon("modMapQuestInsight", dataObject, text);
		}
	}
	// A signpost name of " " hides the name on the map (it stays in the box title and crosshair label).
	flags = 0;
	if (dataObject.GetMemberFlashBool("qmiNoCrosshairLabel"))
	{
		flags += CMFLabelHideCrosshair();
	}
	text = dataObject.GetMemberFlashString("qmiLevelText");
	if (travel && text == " ")
	{
		flags += CMFLabelHidePin();
	}
	// Map Quest Insight writes "Lv x-y" on quest pins, signposts and, from 2.1.0, its "Quests not started yet" markers
	// (the giver's own type, not a quest pin), so any pin that carries it gets it.
	else if (text != "")
	{
		CMFStylePinLabel("modMapQuestInsight", dataObject, text);
	}
	if (flags == CMFLabelHidePin())
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyLabelHide(), "pin", 1);
	}
	else if (flags == CMFLabelHideCrosshair())
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyLabelHide(), "crosshair", 1);
	}
	else if (flags > 0)
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyLabelHide(), "pin,crosshair", 1);
	}
	if (!drawn)
	{
		MqiAdapterOwnTint(dataObject);
	}
	if (travel && theGame.mqiAdapterNoSignTabs != "")
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyTabHide(), theGame.mqiAdapterNoSignTabs, 1);
	}
}

// One of Map Quest Insight's own settings by its menu name, lower case; a value never saved ("" or "-1") is its
// own default, given here from its menu XML.
function MqiAdapterVar(group : name, item : name, fallback : string) : string
{
	var value : string;
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue(group, item));
	if (value == "" || value == "-1")
	{
		return fallback;
	}
	return value;
}

function MqiAdapterOn(group : name, item : name, fallback : bool) : bool
{
	var value : string;
	value = MqiAdapterVar(group, item, "");
	if (value == "")
	{
		return fallback;
	}
	return value == "true" || value == "1";
}

// The game's quest pin types: the ones Map Quest Insight 2.0 puts its info box beside.
function MqiAdapterQuestTypes() : array<name>
{
	var types : array<name>;
	types.PushBack('StoryQuest');
	types.PushBack('ChapterQuest');
	types.PushBack('SideQuest');
	types.PushBack('MonsterQuest');
	types.PushBack('TreasureQuest');
	types.PushBack('QuestObjective');
	types.PushBack('QuestObjectiveOther');
	types.PushBack('QuestReturn');
	types.PushBack('QuestGiverStory');
	types.PushBack('QuestGiverChapter');
	types.PushBack('QuestGiverSide');
	types.PushBack('QuestAvailable');
	types.PushBack('QuestAvailableHoS');
	types.PushBack('QuestAvailableBaW');
	types.PushBack('QuestAvailableLy');
	types.PushBack('Quest');
	types.PushBack('QuestBelgard');
	types.PushBack('QuestCoronata');
	types.PushBack('QuestVermentino');
	return types;
}

// Map Quest Insight 2.0's "Info box beside the marker" ([qmiBox] qmiQjBoxBeside, default on): a quest marker's
// box sits beside the marker, on the right or, without room, the left, above or below, and never covers it. Its
// own map file does this from the pin's drawn bounds; CMF 13 does the same with clearAnchor pin, for the quest
// pin types only, and every quest box takes that place (clearMinHeight 1). Other pins keep their place. Off
// withdraws both keys.
function MqiAdapterSendBeside()
{
	var types : array<name>;
	var on, anchor : string;
	var i : int;
	if (!CMFHasAbility('tooltip', 'clearAnchor'))
	{
		return;
	}
	on = "unset";
	anchor = "unset";
	if (MqiAdapterOn('qmiBox', 'qmiQjBoxBeside', true))
	{
		on = "";
		anchor = "pin";
	}
	types = MqiAdapterQuestTypes();
	for (i = 0; i < types.Size(); i += 1)
	{
		CMFStyle("modMapQuestInsight", 'tooltip', types[i], 'clearMinHeight', on, 1);
		CMFStyle("modMapQuestInsight", 'tooltip', types[i], 'clearAnchor', anchor, 0);
	}
}

// Map Quest Insight 2.0's "Map category panel" ([qmiGeneral] qmiCatPanel: 0 Auto-hide, the default, 1 Always
// shown) and "Map overview" ([qmiGeneral] qmiMapOverview: 0 On, 1 Only while moving, the default, 2 Off). Its own
// map file hides the panel 3 s after its last use (the first pad Up press only shows it) and shows the overview
// while the map moves and 1.5 s after; CMF 13's panel visibility keys do the same.
function MqiAdapterSendPanels()
{
	var overview : string;
	if (!CMFHasAbility('legend', 'show'))
	{
		return;
	}
	if (MqiAdapterVar('qmiGeneral', 'qmiCatPanel', "0") == "1")
	{
		MqiAdapterMotion('legend', 'show', "always", 0);
		MqiAdapterMotion('legend', 'autoHideMs', "unset", 0);
		MqiAdapterMotion('legend', 'padShowFirst', "unset", 0);
	}
	else
	{
		MqiAdapterMotion('legend', 'show', "auto", 0);
		MqiAdapterMotion('legend', 'autoHideMs', "", 3000);
		MqiAdapterMotion('legend', 'padShowFirst', "", 1);
	}
	overview = MqiAdapterVar('qmiGeneral', 'qmiMapOverview', "1");
	if (overview == "0")
	{
		MqiAdapterMotion('preview', 'show', "always", 0);
		MqiAdapterMotion('preview', 'movingMs', "unset", 0);
	}
	else if (overview == "2")
	{
		MqiAdapterMotion('preview', 'show', "never", 0);
		MqiAdapterMotion('preview', 'movingMs', "unset", 0);
	}
	else
	{
		MqiAdapterMotion('preview', 'show', "moving", 0);
		MqiAdapterMotion('preview', 'movingMs', "", 1500);
	}
}

// Quest icons by type for this opening, from OnConfigUI to the pins: 0 the adapter's 1.x icons (Map Quest Insight's
// "Quest icons by type" off), 1 round badges ("Round quest icons" on too), 2 the type symbols alone.
@addField(CR4Game)
var mqiAdapterIconMode : int;

@addField(CR4Game)
var mqiAdapterIconPct : float;

@addField(CR4Game)
var mqiAdapterTrackedRgb : int;

@addMethod(CR4Game)
function MqiAdapterSetIcons(mode : int, percent : float, trackedRgb : int)
{
	mqiAdapterIconMode = mode;
	mqiAdapterIconPct = percent;
	mqiAdapterTrackedRgb = trackedRgb;
}

function MqiAdapterIconMode() : int
{
	if (!QMI_OptTypeIcons() || !CMFHasProperty(44))
	{
		return 0;
	}
	if (QMI_OptUniformIcons())
	{
		return 1;
	}
	return 2;
}

// Map Quest Insight's "Quest marker size" ([qmiPins] qmiQuestIconSize, 50 to 150 %, default 100).
function MqiAdapterIconPercent() : float
{
	return ClampF(StringToFloat(MqiAdapterVar('qmiPins', 'qmiQuestIconSize', "100")), 50, 150);
}

// "#RRGGBB" as 0xRRGGBB; 0 when it is not a colour.
function MqiAdapterHexColour(text : string) : int
{
	var digits, hex : string;
	var value, digit, i : int;
	digits = "0123456789abcdef";
	hex = StrLower(StrReplace(text, "#", ""));
	if (StrLen(hex) != 6)
	{
		return 0;
	}
	value = 0;
	for (i = 0; i < 6; i += 1)
	{
		digit = StrFindFirst(digits, StrMid(hex, i, 1));
		if (digit < 0)
		{
			return 0;
		}
		value = value * 16 + digit;
	}
	return value;
}

// The picture names of Wolfer's badges and symbols for Map Quest Insight's quest kinds 1 to 10 (QMI_IconKind).
function MqiAdapterKindFile(kind : int) : string
{
	switch (kind)
	{
		case 1:
			return "main";
		case 2:
			return "secondary";
		case 3:
			return "contract";
		case 4:
			return "treasure";
		case 5:
			return "gwent";
		case 6:
			return "horse_race";
		case 7:
			return "boat_race";
		case 8:
			return "fist_fight";
		case 9:
			return "heroes_pursuits";
		case 10:
			return "vintners_contract";
	}
	return "";
}

// One quest pin's picture with quest icons by type on, as Map Quest Insight 2.0's own map draws it (its README in
// Wolfer's icon set): a round badge whose ring takes the level colour (band, QMI_LevelBandTint, white when 0), with
// the type symbol on it, white, or gold on the tracked quest's pins; or, with round icons off, the symbol alone in
// the level colour, gold when tracked. The badge is the picture under the icon (42) with its own tint (43), so the
// two keep their own colours. The pictures are cut so these sizes match its own at the Quest marker size: the
// badge's 31 map units and the symbol's 18 over the game's quest icon, about 14.5. Only the picture grows (44):
// the pin's size (10) stays the Quest marker size, so the game's glow and the tracked quest's ring keep Map Quest
// Insight's size, as on its own map. Returns how much the picture grew.
function MqiAdapterQuestIcon(dataObject : CScriptedFlashObject, file : string, band : int, tracked : bool) : float
{
	var base : string;
	var picture : float;
	base = "img://icons/modcmfadaptermapquestinsight/";
	if (theGame.mqiAdapterIconPct != 100)
	{
		CMFStylePinScale("modMapQuestInsight", dataObject, (int)(theGame.mqiAdapterIconPct + 0.5));
	}
	if (theGame.mqiAdapterIconMode == 1)
	{
		if (band == 0)
		{
			band = 16777215;
		}
		CMFStylePinIcon("modMapQuestInsight", dataObject, base + "badgesym_" + file + ".png");
		CMFStylePin("modMapQuestInsight", dataObject, 42, base + "badge_" + file + ".png", 0);
		CMFStylePin("modMapQuestInsight", dataObject, 43, "", band);
		if (tracked && theGame.mqiAdapterTrackedRgb != 0)
		{
			CMFStylePinTint("modMapQuestInsight", dataObject, theGame.mqiAdapterTrackedRgb);
		}
		picture = 31.0 / 14.5;
	}
	else
	{
		CMFStylePinIcon("modMapQuestInsight", dataObject, base + "symbol_" + file + ".png");
		if (tracked && theGame.mqiAdapterTrackedRgb != 0)
		{
			CMFStylePinTint("modMapQuestInsight", dataObject, theGame.mqiAdapterTrackedRgb);
		}
		else if (band != 0)
		{
			CMFStylePinTint("modMapQuestInsight", dataObject, band);
		}
		picture = 18.0 / 14.5;
	}
	CMFStylePin("modMapQuestInsight", dataObject, 44, "", (int)(picture * 100 + 0.5));
	return picture;
}

// The label's distance above the pin: Map Quest Insight's own (qmiIconTop, or the game's 14 pin units), grown with
// the picture so the label keeps the same room above a badge or symbol.
function MqiAdapterLabelPlace(dataObject : CScriptedFlashObject, picture : float)
{
	var number : float;
	number = dataObject.GetMemberFlashNumber("qmiIconTop");
	if (picture > 0)
	{
		if (number <= 0)
		{
			number = 14;
		}
		number *= picture;
	}
	if (number > 0)
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyLabelPlace(), "", (int)(number * 10 + 0.5));
	}
}

// Map Quest Insight's own size and tint of a pin (its pin fields qmiIconScale and qmiIconTint).
function MqiAdapterOwnScale(dataObject : CScriptedFlashObject)
{
	var number : float;
	number = dataObject.GetMemberFlashNumber("qmiIconScale");
	if (number > 0 && number != 1)
	{
		CMFStylePinScale("modMapQuestInsight", dataObject, (int)(number * 100 + 0.5));
	}
}

function MqiAdapterOwnTint(dataObject : CScriptedFlashObject)
{
	var tint : int;
	tint = dataObject.GetMemberFlashUInt("qmiIconTint");
	if (tint != 0)
	{
		CMFStylePinTint("modMapQuestInsight", dataObject, tint);
	}
}

// Map Quest Insight 2.0's Show more ([qmiBox] qmiJournalText and qmiDescOnAsk both on): a quest box opens without
// its journal text and offers Show more / Show less. Its own way for a map to ask for it (Wolfer, 2026-10-25) is two
// numbers on the map's root, qmiDmApi and qmiDrApi, which it reads once per opening; it then wraps the hidden text
// in <font qmimore='1'></font> ... <font qmimore='0'></font>. CMF 13 lets a mod's script set its own numbers on the
// map's root and folds the box at a marker it is told (foldTag), so the adapter sets the two numbers before Map
// Quest Insight's wrapper runs and tells CMF its marker, its words and its keys. A toggle goes back to Map Quest
// Insight's own event, which saves the state ([qmiBox] qmiDescMoreOpen) as on its own map.
@addMethod(CR4MapMenu)
function MqiAdapterAskDescMore() : bool
{
	var root : CScriptedFlashSprite;
	if (!CMFHasAbility('map', 'rootValues') || !CMFHasAbility('tooltip', 'foldTag') ||
		!MqiAdapterOn('qmiBox', 'qmiJournalText', true) || !MqiAdapterOn('qmiBox', 'qmiDescOnAsk', true))
	{
		return false;
	}
	root = GetMenuFlash();
	if (!root)
	{
		return false;
	}
	root.SetMemberFlashNumber("qmiDmApi", 1);
	root.SetMemberFlashNumber("qmiDrApi", 1);
	return true;
}

// Map Quest Insight 2.0.1's menu files draw the game's menu above any map. With its Full-screen map on it hides the
// menu's dark background and X over another map; with it Off ([qmiGeneral] qmiFullScreen 0) it keeps them, and they
// cover CMF's whole map. Its own opt-in for a map that is drawn under the menu (Wolfer, 2026-10-25) is the true value
// qmiHubOver on the map's root, read once per opening inside its wrapper, so the adapter sets it before that runs.
// With Full-screen on Map Quest Insight hides them anyway; CMF's map keeps the game's height while it is Off.
@addMethod(CR4MapMenu)
function MqiAdapterAskHubOver()
{
	var root : CScriptedFlashSprite;
	if (!CMFHasAbility('map', 'rootValues') || MqiAdapterVar('qmiGeneral', 'qmiFullScreen', "3") != "0")
	{
		return;
	}
	root = GetMenuFlash();
	if (root)
	{
		root.SetMemberFlashBool("qmiHubOver", true);
	}
}

// The fold keys, or "unset" for each while Show more is off. The words are the ones Map Quest Insight writes on the
// map's root inside its wrapper (qmiDmMoreW, qmiDmLessW), in the player's language. Its own keys are X and R3: the
// game's actions on those keys are SpawnHorse (keyboard X) and CameraLock (pad R3), so CMF shows and takes the keys
// the player bound to them. The box opens the way the player last left one while "Remember Show more"
// ([qmiBox] qmiDescRemember, default on) is on.
function MqiAdapterSendFold(on : bool, root : CScriptedFlashSprite)
{
	var text, more, less : string;
	var open : float;
	text = "unset";
	more = "";
	less = "";
	if (on && root)
	{
		text = "";
		more = root.GetMemberFlashString("qmiDmMoreW");
		less = root.GetMemberFlashString("qmiDmLessW");
	}
	open = 0;
	if (MqiAdapterOn('qmiBox', 'qmiDescRemember', true) && MqiAdapterOn('qmiBox', 'qmiDescMoreOpen', false))
	{
		open = 1;
	}
	MqiAdapterFoldKey('foldTag', text == "", "qmimore", 0);
	MqiAdapterFoldKey('foldMoreText', text == "" && more != "", more, 0);
	MqiAdapterFoldKey('foldLessText', text == "" && less != "", less, 0);
	MqiAdapterFoldKey('foldKeyKb', text == "", "SpawnHorse", 0);
	MqiAdapterFoldKey('foldKeyPad', text == "", "CameraLock", 0);
	MqiAdapterMotion('tooltip', 'foldOpen', text, open);
}

function MqiAdapterFoldKey(key : name, on : bool, text : string, number : float)
{
	if (on)
	{
		MqiAdapterMotion('tooltip', key, text, number);
	}
	else
	{
		MqiAdapterMotion('tooltip', key, "unset", number);
	}
}

// Map Quest Insight's own map calls this event when the player shows or folds the text (1 shown, 0 folded).
@addMethod(CR4MapMenu)
function MqiAdapterDescMore(open : bool)
{
	if (open)
	{
		OnQmiDescMore(1);
	}
	else
	{
		OnQmiDescMore(0);
	}
}

@wrapMethod(CMFCore)
function OnInfoFold(menu : CR4MapMenu, provider : string, open : bool)
{
	wrappedMethod(menu, provider, open);
	if (provider == "modMapQuestInsight" && menu)
	{
		menu.MqiAdapterDescMore(open);
	}
}

// Map Quest Insight 2.0's "Full-screen map" ([qmiGeneral] qmiFullScreen: 0 Off, 1 Clear, 2 Soft fade, 3 Dark fade,
// the default). Its own map then runs to the top and bottom edges of the screen, under the hub's tabs, which its
// menu files draw over any map, and fades the two edges. CMF's map area becomes the whole height (map top 0,
// bottom 1080) and the fades are two gradient bands of the adapter's own on the screen, under every panel (Clear
// draws none). The panels already sit inside the game's map area, below the tabs, so none moves. Off withdraws
// all of it: the game's area and no bands. Map Quest Insight itself hides the hub's backdrop and close button only
// while this setting is on (2.0.1).
function MqiAdapterSendFullScreen()
{
	var mode : string;
	var alpha : float;
	if (!CMFHasAbility('map', 'top') || !CMFHasAbility('band', 'side'))
	{
		return;
	}
	mode = MqiAdapterVar('qmiGeneral', 'qmiFullScreen', "3");
	if (mode != "1" && mode != "2" && mode != "3")
	{
		MqiAdapterMotion('map', 'top', "unset", 0);
		MqiAdapterMotion('map', 'bottom', "unset", 0);
		MqiAdapterFade('modMapQuestInsight.fadeTop', "", 0);
		MqiAdapterFade('modMapQuestInsight.fadeBottom', "", 0);
		return;
	}
	MqiAdapterMotion('map', 'top', "", 0);
	MqiAdapterMotion('map', 'bottom', "", 1080);
	alpha = 0;
	if (mode == "2")
	{
		alpha = 0.55;
	}
	else if (mode == "3")
	{
		alpha = 0.85;
	}
	if (alpha <= 0)
	{
		MqiAdapterFade('modMapQuestInsight.fadeTop', "", 0);
		MqiAdapterFade('modMapQuestInsight.fadeBottom', "", 0);
		return;
	}
	MqiAdapterFade('modMapQuestInsight.fadeTop', "top", alpha);
	MqiAdapterFade('modMapQuestInsight.fadeBottom', "bottom", alpha);
}

// One fade band along a screen edge, black at the edge and clear 180 px in; side "" withdraws it.
function MqiAdapterFade(id : name, side : string, alpha : float)
{
	if (side == "")
	{
		CMFDraw("modMapQuestInsight", 'screen', id, '');
		return;
	}
	CMFDraw("modMapQuestInsight", 'screen', id, 'band');
	CMFDrawSet("modMapQuestInsight", id, 'side', side, 0);
	CMFDrawSet("modMapQuestInsight", id, 'size', "", 180);
	CMFDrawSet("modMapQuestInsight", id, 'fill', "", 0);
	CMFDrawSet("modMapQuestInsight", id, 'alpha', "", 0);
	CMFDrawSet("modMapQuestInsight", id, 'fill2', "", 0);
	CMFDrawSet("modMapQuestInsight", id, 'alpha2', "", alpha);
	CMFDrawSet("modMapQuestInsight", id, 'gradient', "linear", 0);
	CMFDrawSet("modMapQuestInsight", id, 'layer', "under", 0);
}

// Map Quest Insight 2.0's "Corner HUD" ([qmiGeneral] qmiSideHud: 0 Clean, the default, 1 Game look). Clean takes
// the tracked quest's dark boxes away and keeps its text readable with a black outline and shadow; CMF's tracker
// part does the same with its plate hidden and two glows. Game look withdraws them.
function MqiAdapterSendCornerHud()
{
	var text : string;
	if (!CMFHasAbility('tracker', 'hide'))
	{
		return;
	}
	text = "unset";
	if (MqiAdapterVar('qmiGeneral', 'qmiSideHud', "0") == "0")
	{
		text = "";
	}
	if (text == "")
	{
		MqiAdapterMotion('tracker', 'hide', "plate", 0);
	}
	else
	{
		MqiAdapterMotion('tracker', 'hide', "unset", 0);
	}
	MqiAdapterMotion('tracker', 'glow1Color', text, 0);
	MqiAdapterMotion('tracker', 'glow1Alpha', text, 1);
	MqiAdapterMotion('tracker', 'glow1Blur', text, 2);
	MqiAdapterMotion('tracker', 'glow1Strength', text, 6);
	MqiAdapterMotion('tracker', 'glow2Color', text, 0);
	MqiAdapterMotion('tracker', 'glow2Alpha', text, 0.8);
	MqiAdapterMotion('tracker', 'glow2Blur', text, 6);
	MqiAdapterMotion('tracker', 'glow2Strength', text, 2);
}

// One line per map opening: which of Map Quest Insight's settings the adapter follows now.
function MqiAdapterLogOpening(descMore : bool, root : CScriptedFlashSprite, travelMap : bool)
{
	var words : string;
	words = "no";
	if (root && root.GetMemberFlashString("qmiDmMoreW") != "")
	{
		words = "yes";
	}
	LogChannel('CMF', "CMF mqi adapter opening icons=" + theGame.mqiAdapterIconMode + " size=" +
		(int)theGame.mqiAdapterIconPct + " sticker=" + MqiAdapterYes(theGame.mqiAdapterStickerOn) + " beside=" +
		MqiAdapterYes(MqiAdapterOn('qmiBox', 'qmiQjBoxBeside', true)) + " panel=" + MqiAdapterVar('qmiGeneral', 'qmiCatPanel', "0") +
		" overview=" + MqiAdapterVar('qmiGeneral', 'qmiMapOverview', "1") + " showMore=" + MqiAdapterYes(descMore) + " words=" + words +
		" fullScreen=" + MqiAdapterVar('qmiGeneral', 'qmiFullScreen', "3") + " cornerHud=" +
		MqiAdapterVar('qmiGeneral', 'qmiSideHud', "0") + " travelMap=" + MqiAdapterYes(travelMap));
}

function MqiAdapterYes(on : bool) : string
{
	if (on)
	{
		return "yes";
	}
	return "no";
}
