// Map Quest Insight's Quest List on CMF's map (adapter 2.1.0; 2.2.0 follows Map Quest Insight 2.1.0's list). Map Quest Insight 2.0 draws a list of the active
// quests beside the map in its own map file, opened from its [F] Quests key hint, and offers [G] Change tracked
// objective while its Corner HUD is Clean. CMF's map loads instead of that file, so neither shows. Wolfer, Map Quest
// Insight's author, allowed the adapter to carry Map Quest Insight 2.0's map features, credited, if they follow
// Map Quest Insight's own settings (2026-10-25). This file does that with CMF 13's general abilities: a screen
// movie of the adapter's own (movie-src/MqiAdapterQuestList.as, built into swf/modcmfadaptermqi/questlist.swf),
// fed through a listen key, and a managed key hint list. It copies no Map Quest Insight code; it reads Map Quest
// Insight's settings and calls only the names Wolfer listed as stable from 2.0.1 (QMI_QjHomeArea,
// QMI_QuestHiddenByCategory, QMI_OptQjClose, QMI_CfgReload; a filter save also calls QMI_MmQuestDirtyHud, as Map Quest
// Insight's own filter does, which is not on that list) and from 2.0.0 (QMI_GetQuestLevel, QMI_IconKind, QMI_LevelBandTint).
// From 2.2.0 it also reads the Quests Available names Wolfer listed as stable for 2.1.0 (2026-10-28): the QMI_qa*
// arrays its map fills while "Quests not started yet" is on, QMI_OptQuestGivers, QMI_QaTitleWord and the
// OnQmiQaPick event, which sets or removes the custom map marker at a row's "!" marker.
//
// The list writes only the two kinds of settings its own rows change in Map Quest Insight: "Only this region"
// and the hide switches, then saves them, as Map Quest Insight's own list does. Both are declared in its menu's
// qmiHide group ("Only this region" is stored in [qmiQuest] through the menu's overrideGroup), so both are read
// and written by that group's name, as Map Quest Insight's qmiSettings.ws does. The quests, their order, levels, regions and objectives come from the game's own
// journal and map menu (GetQuests, the same list the game's map sends its quest tracker).

@addField(CR4MapMenu)
var mqiAdapterQlQuests : array<CJournalQuest>;

@addField(CR4MapMenu)
var mqiAdapterQlObjs : array<CJournalQuestObjective>;

// The open number the movie counts: a new, larger number opens the list. Starts at 0 with each map opening.
@addField(CR4MapMenu)
var mqiAdapterQlOpen : int;

@addField(CR4MapMenu)
var mqiAdapterQlSeq : int;

@addField(CR4MapMenu)
var mqiAdapterQlOn : bool;

@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	var result : bool;
	result = wrappedMethod();
	mqiAdapterQlOpen = 0;
	mqiAdapterQlSeq = 0;
	mqiAdapterQlTrackKey = "";
	mqiAdapterQlAreaSent = "";
	mqiAdapterQlOn = MqiAdapterQlWanted();
	MqiAdapterQlDrawing(mqiAdapterQlOn);
	if (mqiAdapterQlOn)
	{
		MqiAdapterMotion('hints', 'list', "", 1);
	}
	else
	{
		MqiAdapterMotion('hints', 'list', "unset", 0);
	}
	LogChannel('CMF', "CMF mqi adapter questlist on=" + MqiAdapterYes(mqiAdapterQlOn) + " home=" + QMI_QjHomeArea() +
		" close=" + QMI_OptQjClose() + " other=" + MqiAdapterVar('qmiQuest', 'qmiQjOtherRegions', "1"));
	return result;
}

// Whether this opening has the Quest List: Map Quest Insight's panel is on and CMF can draw and focus it.
function MqiAdapterQlWanted() : bool
{
	return MqiAdapterOn('qmiQuest', 'qmiQjPanel', true) && CMFHasAbility('movie', 'focus') && CMFHasAbility('hints', 'list');
}

// The list's place: the left edge of the screen (the edge itself on a wide screen), full height.
function MqiAdapterQlDrawing(on : bool)
{
	var id : name;
	id = 'modMapQuestInsight.questList';
	if (!on)
	{
		CMFDraw("modMapQuestInsight", 'screen', id, '');
		return;
	}
	CMFDraw("modMapQuestInsight", 'screen', id, 'movie');
	CMFDrawSet("modMapQuestInsight", id, 'src', "swf/modcmfadaptermqi/questlist.swf", 0);
	CMFDrawSet("modMapQuestInsight", id, 'listen', "mqiadapter.questlist", 0);
	CMFDrawSet("modMapQuestInsight", id, 'focus', "", 1);
	CMFDrawSet("modMapQuestInsight", id, 'width', "", 640);
	CMFDrawSet("modMapQuestInsight", id, 'screenLeft', "", 0);
	CMFDrawSet("modMapQuestInsight", id, 'alignX', "", 0);
	CMFDrawSet("modMapQuestInsight", id, 'alignY', "", 0);
	CMFDrawSet("modMapQuestInsight", id, 'wideAnchor', "edges", 0);
	// As in Map Quest Insight's own map the list takes the whole left edge, top to bottom (1080 map units): the movie
	// asks CMF to hide the region title, the legend and the common menu's top bar while it shows (map.hidePanels, CMF API 16; on an older CMF
	// they stay).
	// On an older CMF the title and legend cannot be hidden and CMF draws them above screen drawings, so the list
	// keeps the gap between them (screen y 180 to 630) as in 2.5.0 before this round.
	if (CMFGetVersion() >= 16)
	{
		CMFDrawSet("modMapQuestInsight", id, 'screenTop', "", 0);
		CMFDrawSet("modMapQuestInsight", id, 'height', "", 1080);
	}
	else
	{
		CMFDrawSet("modMapQuestInsight", id, 'screenTop', "", 180);
		CMFDrawSet("modMapQuestInsight", id, 'height', "", 450);
	}
}

// The map only receives the list's value once it listens; send it then (and again on every change).
@wrapMethod(CMFCore)
function OnMapListening(menu : CR4MapMenu, keys : string)
{
	wrappedMethod(menu, keys);
	if (menu && menu.mqiAdapterQlOn && StrFindFirst(keys, "mqiadapter.questlist") >= 0)
	{
		menu.MqiAdapterQlSend();
	}
}

// Map Quest Insight's key hints: [F] Quests opens the list; [G] Change tracked objective, while its Corner HUD is
// Clean (qmiSideHud 0), cycles the tracked quest's objectives as the game's own map does.
@wrapMethod(CMFCore)
function OnMapHints(menu : CR4MapMenu, owner : string)
{
	var storage : CScriptedFlashValueStorage;
	var list : CScriptedFlashArray;
	var metadata : CScriptedFlashObject;
	var count : int;
	wrappedMethod(menu, owner);
	if (owner != "modMapQuestInsight" || !menu)
	{
		return;
	}
	storage = menu.GetMenuFlashValueStorage();
	if (!storage)
	{
		return;
	}
	list = storage.CreateTempFlashArray();
	metadata = storage.CreateTempFlashObject();
	metadata.SetMemberFlashString("owner", owner);
	list.PushBackFlashObject(metadata);
	list.PushBackFlashObject(MqiAdapterQlHint(storage, 70, "gamepad_L2", "mqiadapter_ql_hint_quests", 1));
	count = 1;
	if (MqiAdapterVar('qmiGeneral', 'qmiSideHud', "0") == "0")
	{
		list.PushBackFlashObject(MqiAdapterQlHint(storage, 71, "gamepad_R2", "mqiadapter_ql_hint_objective", 2));
		count = 2;
	}
	storage.SetFlashArray("cmf.map.hints.owned", list);
	LogChannel('CMF', "CMF mqi adapter questlist hints entries=" + count);
}

function MqiAdapterQlHint(storage : CScriptedFlashValueStorage, keyCode : int, pad : string, key : string, click : int) : CScriptedFlashObject
{
	var item : CScriptedFlashObject;
	item = storage.CreateTempFlashObject();
	item.SetMemberFlashInt("actionId", 2400 + click);
	item.SetMemberFlashInt("level", 0);
	item.SetMemberFlashInt("keyboard_keyCode", keyCode);
	item.SetMemberFlashString("gamepad_navEquivalent", pad);
	item.SetMemberFlashString("label", GetLocStringByKeyExt(key));
	item.SetMemberFlashInt("click", click);
	return item;
}

@wrapMethod(CMFCore)
function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
{
	var result : bool;
	result = wrappedMethod(menu, provider, id, input, value);
	// The [F] Quests box under the region title (Clean) does what the F key does.
	if (provider == "modMapQuestInsight" && id == 'mqiQuestsBox' && input == "click" && menu && menu.mqiAdapterQlOn)
	{
		menu.MqiAdapterQlOpenList();
		return true;
	}
	if (provider != "modMapQuestInsight" || id != 'hints' || input != "hint" || !menu)
	{
		return result;
	}
	if (value == 1 && menu.mqiAdapterQlOn)
	{
		menu.MqiAdapterQlOpenList();
		return true;
	}
	if (value == 2)
	{
		menu.OnCycleObjectivesDefault();
		LogChannel('CMF', "CMF mqi adapter questlist cycle objective");
		if (menu.mqiAdapterQlOn)
		{
			menu.MqiAdapterQlSend();
		}
		return true;
	}
	return result;
}

@addMethod(CR4MapMenu)
function MqiAdapterQlOpenList()
{
	mqiAdapterQlOpen += 1;
	MqiAdapterQlSend();
	LogChannel('CMF', "CMF mqi adapter questlist open count=" + mqiAdapterQlOpen + " quests=" + mqiAdapterQlQuests.Size());
}

// What the list sends back: track, objective, journal, thisRegion, filter, qaPick, and its own open and region notes.
@wrapMethod(CMFCore)
function OnMovieEvent(menu : CR4MapMenu, provider : string, id : string, eventName : string, value : string) : bool
{
	var result : bool;
	result = wrappedMethod(menu, provider, id, eventName, value);
	if (provider != "modMapQuestInsight" || id != "modMapQuestInsight.questList" || !menu)
	{
		return result;
	}
	menu.MqiAdapterQlEvent(eventName, value);
	return true;
}

// A filter changed: the game's own pin build runs again on this open map (Map Quest Insight itself calls UpdateData(true)
// on a filter change). CMF's UpdateData wrapper still runs. Plain game call, so no CMF API above the adapter's own.
@addMethod(CR4MapMenu)
function MqiAdapterRefreshPins()
{
	UpdateData(true);
}

// The tracked quest and highlighted objective by tag, as the last send showed them. Every pin build (UpdateData) checks
// them after the game's build and resends once if they differ, so a map pin, the G key or a journal that changes them
// is followed; the list's own track sends itself (mqiAdapterQlOwnTrack), so it is not sent twice.
@addField(CR4MapMenu)
var mqiAdapterQlOwnTrack : bool;

@addField(CR4MapMenu)
var mqiAdapterQlAreaSent : string;

@addField(CR4MapMenu)
var mqiAdapterQlTrackKey : string;

@addMethod(CR4MapMenu)
function MqiAdapterQlTrackKey() : string
{
	var trackedQuest : CJournalQuest;
	var objective : CJournalQuestObjective;
	var key : string;
	key = "";
	trackedQuest = theGame.GetJournalManager().GetTrackedQuest();
	if (trackedQuest)
	{
		key = NameToString(trackedQuest.GetUniqueScriptTag());
	}
	key += "|";
	objective = theGame.GetJournalManager().GetHighlightedObjective();
	if (objective)
	{
		key += NameToString(objective.GetUniqueScriptTag());
	}
	return key;
}

@addMethod(CR4MapMenu)
function MqiAdapterQlNoteTracked()
{
	mqiAdapterQlTrackKey = MqiAdapterQlTrackKey();
}

@addMethod(CR4MapMenu)
function MqiAdapterQlTrackChanged() : bool
{
	return mqiAdapterQlSeq > 0 && mqiAdapterQlTrackKey != MqiAdapterQlTrackKey();
}

@wrapMethod(CR4MapMenu)
function UpdateData(optional ignoreSelectionChange : bool)
{
	wrappedMethod(ignoreSelectionChange);
	if (mqiAdapterQlOn && !mqiAdapterQlOwnTrack && MqiAdapterQlTrackChanged())
	{
		MqiAdapterQlSend();
	}
}

@addMethod(CR4MapMenu)
function MqiAdapterQlEvent(eventName : string, value : string)
{
	var journalQuest : CJournalQuest;
	var objective : CJournalQuestObjective;
	var left, right : string;
	var index, objectiveIndex : int;
	var hide : array<name>;
	if (eventName == "padlog")
	{
		LogChannel('CMF', "CMF mqi adapter questlist pad " + value);
		return;
	}
	if (eventName == "track" || eventName == "journal" || eventName == "objective")
	{
		left = value;
		right = "";
		if (StrFindFirst(value, ":") >= 0)
		{
			left = StrBeforeFirst(value, ":");
			right = StrAfterFirst(value, ":");
		}
		index = StringToInt(left, -1);
		if (index < 0 || index >= mqiAdapterQlQuests.Size() || !mqiAdapterQlQuests[index])
		{
			LogChannel('CMF', "CMF mqi adapter questlist " + eventName + " unknown=" + value);
			return;
		}
		journalQuest = mqiAdapterQlQuests[index];
		if (eventName == "journal")
		{
			LogChannel('CMF', "CMF mqi adapter questlist journal quest=" + journalQuest.GetUniqueScriptTag());
			OnShowQuestInJournal(journalQuest.GetUniqueScriptTag());
			return;
		}
		if (eventName == "objective")
		{
			objectiveIndex = StringToInt(right, -1);
			if (objectiveIndex >= 0 && objectiveIndex < mqiAdapterQlObjs.Size() && mqiAdapterQlObjs[objectiveIndex] &&
				theGame.GetJournalManager().GetEntryStatus(mqiAdapterQlObjs[objectiveIndex]) == JS_Active)
			{
				objective = mqiAdapterQlObjs[objectiveIndex];
				mqiAdapterQlOwnTrack = true;
				OnHighlightObjectiveWithQuestChange(journalQuest.GetUniqueScriptTag(), objective.GetUniqueScriptTag());
				mqiAdapterQlOwnTrack = false;
				LogChannel('CMF', "CMF mqi adapter questlist objective quest=" + journalQuest.GetUniqueScriptTag() + " objective=" +
					objective.GetUniqueScriptTag());
				MqiAdapterQlSend();
				return;
			}
		}
		mqiAdapterQlOwnTrack = true;
		OnTrackQuest(journalQuest.GetUniqueScriptTag());
		mqiAdapterQlOwnTrack = false;
		LogChannel('CMF', "CMF mqi adapter questlist track quest=" + journalQuest.GetUniqueScriptTag());
		MqiAdapterQlSend();
		return;
	}
	if (eventName == "thisRegion")
	{
		theGame.GetInGameConfigWrapper().SetVarValue('qmiHide', 'qmiQjThisRegion', MqiAdapterQlBool(value == "1"));
		theGame.SaveUserSettings();
		QMI_CfgReload();
		LogChannel('CMF', "CMF mqi adapter questlist thisRegion=" + value);
		// Only the list's rows change (Map Quest Insight's own OnQmiThisRegion saves the setting and builds no pins), so
		// no pin build runs and the map's panels stay as they are; the list only needs its new rows.
		MqiAdapterQlSend();
		return;
	}
	if (eventName == "filter")
	{
		left = StrBeforeFirst(value, ":");
		right = StrAfterFirst(value, ":");
		index = StringToInt(left, -1);
		hide = MqiAdapterQlHideVars();
		if (index >= 0 && index < hide.Size())
		{
			theGame.GetInGameConfigWrapper().SetVarValue('qmiHide', hide[index], MqiAdapterQlBool(right == "1"));
			theGame.SaveUserSettings();
			QMI_CfgReload();
			MqiAdapterRefreshPins();
			// As Map Quest Insight's own filter does: its minimap HUD marks the quest records dirty (nothing happens without the HUD).
			QMI_MmQuestDirtyHud();
			LogChannel('CMF', "CMF mqi adapter questlist filter " + hide[index] + "=" + right);
			// Also the movie's cue to hide the map's panels again after the pin build.
			MqiAdapterQlSend();
		}
		return;
	}
	// A Quests Available row picked on its own map: Map Quest Insight sets or removes the custom map marker at the
	// row's "!" marker (its value is the row's QMI_qaGv number; Map Quest Insight acts only on the shown map).
	if (eventName == "qaPick")
	{
		index = StringToInt(value, -1);
		if (index >= 0)
		{
			OnQmiQaPick(index);
		}
		LogChannel('CMF', "CMF mqi adapter questlist qaPick=" + value);
		return;
	}
	LogChannel('CMF', "CMF mqi adapter questlist " + eventName + "=" + value);
}

function MqiAdapterQlBool(on : bool) : string
{
	if (on)
	{
		return "true";
	}
	return "false";
}

// Map Quest Insight's hide switches, in the order of its "Hide on the map" page and of the list's filter rows.
function MqiAdapterQlHideVars() : array<name>
{
	var vars : array<name>;
	vars.PushBack('qmiHideContracts');
	vars.PushBack('qmiHideTreasure');
	vars.PushBack('qmiHideGwent');
	vars.PushBack('qmiHideHorseRaces');
	vars.PushBack('qmiHideBoatRaces');
	vars.PushBack('qmiHideFistFights');
	vars.PushBack('qmiHideHeroesPursuits');
	vars.PushBack('qmiHideVintner');
	vars.PushBack('qmiHideSecondary');
	vars.PushBack('qmiHideDeadly');
	vars.PushBack('qmiHideMain');
	return vars;
}

// The picture of a filter row, by its MqiAdapterQlHideVars index: Wolfer's symbol of that kind; Deadly (9) has none and
// the list draws its own skull.
function MqiAdapterQlFilterIcon(base : string, index : int) : string
{
	switch (index)
	{
		case 0:
			return base + "symbol_contract.png";
		case 1:
			return base + "symbol_treasure.png";
		case 2:
			return base + "symbol_gwent.png";
		case 3:
			return base + "symbol_horse_race.png";
		case 4:
			return base + "symbol_boat_race.png";
		case 5:
			return base + "symbol_fist_fight.png";
		case 6:
			return base + "symbol_heroes_pursuits.png";
		case 7:
			return base + "symbol_vintners_contract.png";
		case 8:
			return base + "symbol_secondary.png";
		case 10:
			return base + "symbol_main.png";
	}
	return "";
}

// Velen and Novigrad share one map, which the game names either way.
function MqiAdapterQlMap(area : name) : string
{
	if (area == 'AN_Velen')
	{
		return "AN_NMLandNovigrad";
	}
	return NameToString(area);
}

// The filter row (MqiAdapterQlHideVars index) that hides a quest of this kind (QMI_IconKind) and journal type.
function MqiAdapterQlFilter(kind : int, type : int) : int
{
	switch (kind)
	{
		case 1:
			return 10;
		case 3:
			return 0;
		case 4:
			return 1;
		case 5:
			return 2;
		case 6:
			return 3;
		case 7:
			return 4;
		case 8:
			return 5;
		case 9:
			return 6;
		case 10:
			return 7;
	}
	if (type == 0 || type == 1 || type == 6 || type == 7)
	{
		return 10;
	}
	return 8;
}

// The journal's own category of a quest type, in its order, and its heading. Map Quest Insight 2.1.0 gives Gwent
// quests (QMI_IconKind 5) their own section between Treasure hunts and Hearts of Stone.
function MqiAdapterQlCategory(kind : int, type : int) : int
{
	if (kind == 5)
	{
		return 4;
	}
	switch (type)
	{
		case 0:
		case 1:
			return 0;
		case 3:
			return 2;
		case 4:
			return 3;
		case 6:
			return 5;
		case 7:
			return 6;
	}
	return 1;
}

function MqiAdapterQlCategoryWord(category : int) : string
{
	switch (category)
	{
		case 0:
			return GetLocStringByKeyExt("panel_journal_queststatus_story");
		case 2:
			return GetLocStringByKeyExt("panel_journal_legend_monsterhunt");
		case 3:
			return GetLocStringByKeyExt("panel_journal_legend_treasurehunt");
		case 4:
			return GetLocStringByKeyExt("mqiadapter_ql_filter_gwent");
		case 5:
			return GetLocStringByKeyExt("panel_journal_legend_ep1");
		case 6:
			return GetLocStringByKeyExt("panel_journal_legend_ep2");
	}
	return GetLocStringByKeyExt("panel_journal_queststatus_side");
}

// The game's own difficulty colour of a quest name (the journal's: deadly red, high orange, white, low grey).
function MqiAdapterQlDiffColour(lvlDiff : int) : string
{
	if (lvlDiff >= theGame.params.LEVEL_DIFF_DEADLY)
	{
		return "#d61010";
	}
	if (lvlDiff >= theGame.params.LEVEL_DIFF_HIGH)
	{
		return "#d68f29";
	}
	if (lvlDiff > -theGame.params.LEVEL_DIFF_HIGH)
	{
		return "#ffffff";
	}
	return "#969696";
}

// One value with everything the list shows: its settings (Map Quest Insight's), its words (the adapter's string
// table and the game's journal words), the active quests in the game's quest log order and, while "Quests not
// started yet" is on, Map Quest Insight's Quests Available rows.
@addMethod(CR4MapMenu)
function MqiAdapterQlSend()
{
	var storage : CScriptedFlashValueStorage;
	var root, conf, words, questObject, objectiveEntry : CScriptedFlashObject;
	var questList, questPins, objectivePins, objectiveList, filterList, iconList, availList : CScriptedFlashArray;
	var journal : CWitcherJournalManager;
	var quests : array<CJournalQuest>;
	var journalQuest : CJournalQuest;
	var phase : CJournalQuestPhase;
	var objective : CJournalQuestObjective;
	var mapPin : CJournalQuestMapPin;
	var hide : array<name>;
	var home : name;
	var i, j, k, m, level, kind, type, category, lvlDiff, playerLevel, contentType : int;
	var status : EJournalStatus;
	var file, base : string;
	storage = GetMenuFlashValueStorage();
	if (!storage)
	{
		return;
	}
	journal = theGame.GetJournalManager();
	quests = GetQuests();
	mqiAdapterQlQuests.Clear();
	mqiAdapterQlObjs.Clear();
	mqiAdapterQlSeq += 1;
	// Wolfer's type symbols, the same pictures as the quest markers (art/, in this adapter's texture.cache).
	base = "img://icons/modcmfadaptermapquestinsight/";
	home = QMI_QjHomeArea();
	playerLevel = thePlayer.GetLevel();

	root = storage.CreateTempFlashObject();
	root.SetMemberFlashInt("seq", mqiAdapterQlSeq);
	root.SetMemberFlashInt("open", mqiAdapterQlOpen);
	root.SetMemberFlashInt("at", -1);
	root.SetMemberFlashString("home", NameToString(home));
	root.SetMemberFlashString("homeMap", MqiAdapterQlMap(home));
	root.SetMemberFlashInt("playerLevel", playerLevel);

	conf = storage.CreateTempFlashObject();
	conf.SetMemberFlashInt("sort", StringToInt(MqiAdapterVar('qmiQuest', 'qmiQjSort', "0"), 0));
	conf.SetMemberFlashBool("thisRegion", MqiAdapterOn('qmiHide', 'qmiQjThisRegion', true));
	conf.SetMemberFlashInt("textSize", StringToInt(MqiAdapterVar('qmiQuest', 'qmiQjTextSize', "90"), 90));
	conf.SetMemberFlashBool("pan", MqiAdapterOn('qmiQuest', 'qmiQjPan', false));
	conf.SetMemberFlashBool("centre", MqiAdapterOn('qmiQuest', 'qmiQjCentre', true));
	conf.SetMemberFlashInt("other", StringToInt(MqiAdapterVar('qmiQuest', 'qmiQjOtherRegions', "1"), 1));
	conf.SetMemberFlashInt("close", QMI_OptQjClose());
	conf.SetMemberFlashBool("distance", MqiAdapterOn('qmiQuest', 'qmiQjDistance', true));
	conf.SetMemberFlashBool("region", MqiAdapterOn('qmiQuest', 'qmiQjRegion', true));
	conf.SetMemberFlashBool("nameCol", MqiAdapterOn('qmiQuest', 'qmiQjNameCol', true));
	conf.SetMemberFlashBool("dlc", MqiAdapterOn('qmiQuest', 'qmiQjDlcName', true));
	conf.SetMemberFlashBool("fullScreen", MqiAdapterVar('qmiGeneral', 'qmiFullScreen', "3") != "0");
	conf.SetMemberFlashBool("foldAll", MqiAdapterOn('qmiQuest', 'qmiQjFoldAll', false));
	conf.SetMemberFlashBool("objHover", MqiAdapterOn('qmiQuest', 'qmiQjObjHover', false));
	conf.SetMemberFlashBool("givers", QMI_OptQuestGivers());
	conf.SetMemberFlashInt("corner", MqiAdapterQlCorner());
	root.SetMemberFlashObject("conf", conf);

	words = storage.CreateTempFlashObject();
	words.SetMemberFlashString("listTitle", GetLocStringByKeyExt("mqiadapter_ql_list_title"));
	words.SetMemberFlashString("sort", GetLocStringByKeyExt("mqiadapter_ql_sort"));
	words.SetMemberFlashString("sorts", GetLocStringByKeyExt("mqiadapter_ql_sort_nearest") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_sort_level") + "|" + GetLocStringByKeyExt("mqiadapter_ql_sort_level_high") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_sort_name") + "|" + GetLocStringByKeyExt("mqiadapter_ql_sort_log"));
	words.SetMemberFlashString("otherRegion", GetLocStringByKeyExt("mqiadapter_ql_other_region"));
	words.SetMemberFlashString("thisRegion", GetLocStringByKeyExt("mqiadapter_ql_this_region"));
	words.SetMemberFlashString("filtersTitle", GetLocStringByKeyExt("mqiadapter_ql_filters_title"));
	words.SetMemberFlashString("on", GetLocStringByKeyExt("mqiadapter_ql_on"));
	words.SetMemberFlashString("off", GetLocStringByKeyExt("mqiadapter_ql_off"));
	words.SetMemberFlashString("collapse", GetLocStringByKeyExt("mqiadapter_ql_collapse"));
	words.SetMemberFlashString("objectives", GetLocStringByKeyExt("mqiadapter_ql_objectives"));
	words.SetMemberFlashString("close", GetLocStringByKeyExt("mqiadapter_ql_hint_close"));
	words.SetMemberFlashString("track", GetLocStringByKeyExt("mqiadapter_ql_hint_track"));
	words.SetMemberFlashString("allRegions", GetLocStringByKeyExt("mqiadapter_ql_hint_all_regions"));
	words.SetMemberFlashString("filterNames", GetLocStringByKeyExt("mqiadapter_ql_filter_contracts") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_filter_treasure") + "|" + GetLocStringByKeyExt("mqiadapter_ql_filter_gwent") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_filter_horse_races") + "|" + GetLocStringByKeyExt("mqiadapter_ql_filter_boat_races") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_filter_fist_fights") + "|" + GetLocStringByKeyExt("mqiadapter_ql_filter_heroes") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_filter_vintner") + "|" + GetLocStringByKeyExt("mqiadapter_ql_filter_secondary") + "|" +
		GetLocStringByKeyExt("mqiadapter_ql_filter_deadly") + "|" + GetLocStringByKeyExt("mqiadapter_ql_filter_main"));
	words.SetMemberFlashString("empty", GetLocStringByKeyExt("mqiadapter_ql_empty"));
	words.SetMemberFlashString("currentLevel", GetLocStringByKeyExt("mqiadapter_ql_current_level"));
	words.SetMemberFlashString("regionCount", GetLocStringByKeyExt("mqiadapter_ql_region_count"));
	words.SetMemberFlashString("regionCountOne", GetLocStringByKeyExt("mqiadapter_ql_region_count_one"));
	words.SetMemberFlashString("regionNone", GetLocStringByKeyExt("mqiadapter_ql_region_none"));
	words.SetMemberFlashString("available", QMI_QaTitleWord());
	root.SetMemberFlashObject("words", words);

	filterList = storage.CreateTempFlashArray();
	hide = MqiAdapterQlHideVars();
	for (i = 0; i < hide.Size(); i += 1)
	{
		filterList.PushBackFlashBool(MqiAdapterOn('qmiHide', hide[i], false));
	}
	root.SetMemberFlashArray("filters", filterList);

	iconList = storage.CreateTempFlashArray();
	for (i = 0; i < hide.Size(); i += 1)
	{
		iconList.PushBackFlashString(MqiAdapterQlFilterIcon(base, i));
	}
	root.SetMemberFlashArray("filterIcons", iconList);

	questList = storage.CreateTempFlashArray();
	for (i = 0; i < quests.Size(); i += 1)
	{
		journalQuest = quests[i];
		if (!journalQuest)
		{
			continue;
		}
		mqiAdapterQlQuests.PushBack(journalQuest);
		level = QMI_GetQuestLevel(journalQuest);
		lvlDiff = 0;
		if (level > 0)
		{
			lvlDiff = level - playerLevel;
		}
		kind = QMI_IconKind(journalQuest);
		type = (int)journalQuest.GetType();
		category = MqiAdapterQlCategory(kind, type);
		file = MqiAdapterKindFile(kind);
		if (file == "" || kind == 2)
		{
			file = "secondary";
			if (category == 0 || category == 5 || category == 6)
			{
				file = "main";
			}
		}
		questObject = storage.CreateTempFlashObject();
		questObject.SetMemberFlashInt("i", mqiAdapterQlQuests.Size() - 1);
		questObject.SetMemberFlashString("name", GetLocStringById(journalQuest.GetTitleStringId()));
		questObject.SetMemberFlashInt("cat", category);
		questObject.SetMemberFlashString("catLabel", MqiAdapterQlCategoryWord(category));
		questObject.SetMemberFlashString("icon", base + "symbol_" + file + ".png");
		questObject.SetMemberFlashInt("band", QMI_LevelBandTint(level));
		questObject.SetMemberFlashInt("lvl", level);
		questObject.SetMemberFlashString("diff", MqiAdapterQlDiffColour(lvlDiff));
		questObject.SetMemberFlashBool("deadly", level > 0 && lvlDiff >= theGame.params.LEVEL_DIFF_DEADLY);
		questObject.SetMemberFlashInt("fk", MqiAdapterQlFilter(kind, type));
		questObject.SetMemberFlashBool("hid", QMI_QuestHiddenByCategory(journalQuest, level));
		contentType = (int)journalQuest.GetContentType();
		if (contentType == 1)
		{
			questObject.SetMemberFlashString("dlc", GetLocStringByKeyExt("panel_journal_legend_ep1"));
		}
		else if (contentType == 2)
		{
			questObject.SetMemberFlashString("dlc", GetLocStringByKeyExt("panel_journal_legend_ep2"));
		}
		else
		{
			questObject.SetMemberFlashString("dlc", "");
		}
		questObject.SetMemberFlashString("map", MqiAdapterQlMap(journalQuest.GetWorld()));
		questObject.SetMemberFlashString("area", NameToString(journalQuest.GetWorld()));
		questObject.SetMemberFlashString("region", GetLocStringByKeyExt(NameToString(GetAreaName(journalQuest))));
		questObject.SetMemberFlashBool("tracked", journal.GetTrackedQuest() == journalQuest);

		questPins = storage.CreateTempFlashArray();
		objectiveList = storage.CreateTempFlashArray();
		for (j = 0; j < journalQuest.GetNumChildren(); j += 1)
		{
			phase = (CJournalQuestPhase)journalQuest.GetChild(j);
			if (!phase || journal.GetEntryStatus(phase) == JS_Inactive)
			{
				continue;
			}
			for (k = 0; k < phase.GetNumChildren(); k += 1)
			{
				objective = (CJournalQuestObjective)phase.GetChild(k);
				if (!objective)
				{
					continue;
				}
				status = journal.GetEntryStatus(objective);
				if (status == JS_Inactive)
				{
					continue;
				}
				objectiveEntry = storage.CreateTempFlashObject();
				objectiveEntry.SetMemberFlashInt("o", mqiAdapterQlObjs.Size());
				mqiAdapterQlObjs.PushBack(objective);
				objectiveEntry.SetMemberFlashString("text", GetLocStringById(objective.GetTitleStringId()));
				if (status == JS_Success)
				{
					objectiveEntry.SetMemberFlashInt("state", 1);
				}
				else if (status == JS_Failed)
				{
					objectiveEntry.SetMemberFlashInt("state", 2);
				}
				else
				{
					objectiveEntry.SetMemberFlashInt("state", 0);
				}
				objectiveEntry.SetMemberFlashBool("tracked", journal.GetHighlightedObjective() == objective);
				objectivePins = storage.CreateTempFlashArray();
				if (status == JS_Active)
				{
					for (m = 0; m < objective.GetNumChildren(); m += 1)
					{
						mapPin = (CJournalQuestMapPin)objective.GetChild(m);
						if (mapPin)
						{
							objectivePins.PushBackFlashUInt(NameToFlashUInt(mapPin.GetMapPinID()));
							questPins.PushBackFlashUInt(NameToFlashUInt(mapPin.GetMapPinID()));
						}
					}
				}
				objectiveEntry.SetMemberFlashArray("pins", objectivePins);
				objectiveList.PushBackFlashObject(objectiveEntry);
			}
		}
		questObject.SetMemberFlashArray("pins", questPins);
		questObject.SetMemberFlashArray("objs", objectiveList);
		questList.PushBackFlashObject(questObject);
	}
	root.SetMemberFlashArray("quests", questList);
	availList = MqiAdapterQlAvailable(storage, base, playerLevel);
	root.SetMemberFlashArray("available", availList);
	storage.SetFlashObject("mqiadapter.questlist", root);
	LogChannel('CMF', "CMF mqi adapter questlist sent seq=" + mqiAdapterQlSeq + " open=" + mqiAdapterQlOpen + " quests=" +
		mqiAdapterQlQuests.Size() + " objectives=" + mqiAdapterQlObjs.Size() + " available=" + availList.GetLength());
	MqiAdapterQlNoteTracked();
}

// Map Quest Insight's Quests Available rows (QMI_qa*, filled by its map with the pins, for this map's "!" markers and
// the other regions' quests, already passed through its hide switches as its markers are): name, level, place
// (AN_ area names, Velen's under AN_NMLandNovigrad) and distance (QMI_qaD, -1 off the player's map), in the row's
// QMI_qaGv number. Its map refills them on a region switch, so they are sent again when the new area is ready.
@addMethod(CR4MapMenu)
function MqiAdapterQlAvailable(storage : CScriptedFlashValueStorage, base : string, playerLevel : int) : CScriptedFlashArray
{
	var list : CScriptedFlashArray;
	var row : CScriptedFlashObject;
	var journalQuest : CJournalQuest;
	var i, count, level, lvlDiff, kind, contentType : int;
	var file : string;
	list = storage.CreateTempFlashArray();
	count = QMI_qaGv.Size();
	if (QMI_qaQuest.Size() < count || QMI_qaTitle.Size() < count || QMI_qaLvl.Size() < count || QMI_qaX.Size() < count ||
		QMI_qaY.Size() < count || QMI_qaD.Size() < count || QMI_qaAr.Size() < count)
	{
		LogChannel('CMF', "CMF mqi adapter questlist available sizes differ gv=" + count);
		return list;
	}
	for (i = 0; i < count; i += 1)
	{
		journalQuest = QMI_qaQuest[i];
		level = QMI_qaLvl[i];
		// Map Quest Insight's own rule: a row whose quest the hide switches hide is left out (the counts never include these rows).
		if (journalQuest && QMI_QuestHiddenByCategory(journalQuest, level))
		{
			continue;
		}
		lvlDiff = 0;
		if (level > 0)
		{
			lvlDiff = level - playerLevel;
		}
		file = "";
		contentType = 0;
		if (journalQuest)
		{
			kind = QMI_IconKind(journalQuest);
			file = MqiAdapterKindFile(kind);
			if (file == "" || kind == 2)
			{
				file = "secondary";
			}
			contentType = (int)journalQuest.GetContentType();
		}
		row = storage.CreateTempFlashObject();
		row.SetMemberFlashInt("i", 100000 + QMI_qaGv[i]);
		row.SetMemberFlashInt("gv", QMI_qaGv[i]);
		row.SetMemberFlashBool("avail", true);
		row.SetMemberFlashString("name", GetLocStringById(QMI_qaTitle[i]));
		if (file != "")
		{
			row.SetMemberFlashString("icon", base + "symbol_" + file + ".png");
		}
		else
		{
			row.SetMemberFlashString("icon", "");
		}
		row.SetMemberFlashInt("band", QMI_LevelBandTint(level));
		row.SetMemberFlashInt("lvl", level);
		row.SetMemberFlashString("diff", MqiAdapterQlDiffColour(lvlDiff));
		row.SetMemberFlashBool("deadly", level > 0 && lvlDiff >= theGame.params.LEVEL_DIFF_DEADLY);
		if (contentType == 1)
		{
			row.SetMemberFlashString("dlc", GetLocStringByKeyExt("panel_journal_legend_ep1"));
		}
		else if (contentType == 2)
		{
			row.SetMemberFlashString("dlc", GetLocStringByKeyExt("panel_journal_legend_ep2"));
		}
		else
		{
			row.SetMemberFlashString("dlc", "");
		}
		row.SetMemberFlashString("map", MqiAdapterQlMap(QMI_qaAr[i]));
		row.SetMemberFlashString("area", NameToString(QMI_qaAr[i]));
		if (journalQuest)
		{
			row.SetMemberFlashString("region", GetLocStringByKeyExt(NameToString(GetAreaName(journalQuest))));
		}
		else
		{
			row.SetMemberFlashString("region", "");
		}
		row.SetMemberFlashNumber("x", QMI_qaX[i]);
		row.SetMemberFlashNumber("y", QMI_qaY[i]);
		row.SetMemberFlashNumber("d", QMI_qaD[i]);
		row.SetMemberFlashBool("tracked", false);
		list.PushBackFlashObject(row);
	}
	return list;
}

@wrapMethod(CMFCore)
function OnMapAreaReady(menu : CR4MapMenu, area : name)
{
	wrappedMethod(menu, area);
	if (menu && menu.mqiAdapterQlOn)
	{
		LogChannel('CMF', "CMF mqi adapter questlist area=" + area);
		// CMF 1.12.0 reports the area ready after every rebuild, not once per area: the Quests Available rows are
		// refilled by a region switch only, so the list is sent here once per area, as before.
		if (QMI_OptQuestGivers() && menu.mqiAdapterQlAreaSent != NameToString(area))
		{
			menu.mqiAdapterQlAreaSent = NameToString(area);
			menu.MqiAdapterQlSend();
		}
	}
}
