// Map Quest Insight adapter for Conjunction Map Framework. Requires CMF 6 with spreading of stacked pins
// (CMFPropertySpreadRank) and Map Quest Insight 1.6.1 or later (Nexus 14219), which stays unchanged. Install and
// remove the two together: this file calls Map Quest Insight's own functions (QMI_OptZoomOut,
// QMI_SpreadStackedMarkers and QMI_SpreadRank exist from 1.6.0), so the game stops at the script compile screen
// when Map Quest Insight is missing or older, and it uses CMF's spread rank, CMF 5's theme calls and CMF 4's pin
// hook, which earlier CMF versions do not have.
//
// Map Quest Insight talks to its own map file: it asks the map for its handshake number (MapMenu.qmiApi),
// then writes icon sizes, quest icons by type, level and signpost labels, the crosshair-label switch,
// level colours and the scrolling info box height into the map, and hides signposts per filter tab. CMF's
// map answers none of those names. This adapter gives Map Quest Insight its handshake in script, then turns
// each value into CMF's general calls, as Map Quest Insight's author would when porting. It copies no code.
// Its three quest icons are Map Quest Insight's own, sent by its author for the adapter and shipped with their
// permission (2026-10-21). Every claim uses Map Quest Insight's own folder name as its provider, so folder order
// between mods is the same with CMF as without it.
//
// The pin values ride on the pin objects, which the game builds from the map's pin class: CMF's map
// declares Map Quest Insight's pin field names (qmi*) for this adapter only, because the game drops any
// field its class does not declare. CMF itself never reads them.
//
// The file name starts with zz_ so it sorts after qmiSettings.ws and questMapInfo.ws: wrappers nest by
// script file name, so these wrappers run around Map Quest Insight's.

// The tabs that hide signposts in this map opening, from UpdateDisabledMapPins to OnPinReady.
@addField(CR4Game)
var mqiAdapterNoSignTabs : string;

// theGame is a constant outside its own class, so the game object assigns its own field.
@addMethod(CR4Game)
function MqiAdapterSetNoSignTabs(tabs : string)
{
	mqiAdapterNoSignTabs = tabs;
}

@addField(CMFCore)
var mqiAdapterLogged : int;

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
	QMI_swfApi = 3;
	QMI_swfApiRead = true;
	wrappedMethod();
	MqiAdapterSendMotion();
	MqiAdapterSendSpread();
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
function MqiAdapterSendSpread()
{
	var spread : string;
	if (!CMFHasAbility('spread', ''))
	{
		return;
	}
	spread = "unset";
	if (QMI_SpreadStackedMarkers())
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
	wrappedMethod(dataObject, targetPin);
	if (!dataObject || !dataObject.GetMemberFlashBool("isQuest") || dataObject.GetMemberFlashBool("isFastTravel") ||
		!QMI_SpreadStackedMarkers())
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
	rank = QMI_SpreadRank(curQuest, QMI_GetQuestLevel(curQuest));
	if (rank > 0)
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertySpreadRank(), "", rank);
	}
}

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var number : float;
	var text : string;
	var flags : int;
	var tint : int;
	var questPin : bool;
	var travel : bool;
	wrappedMethod(dataObject, mapContext);
	questPin = dataObject.GetMemberFlashBool("isQuest");
	travel = dataObject.GetMemberFlashBool("isFastTravel");
	number = dataObject.GetMemberFlashNumber("qmiIconScale");
	if (number > 0 && number != 1)
	{
		CMFStylePinScale("modMapQuestInsight", dataObject, (int)(number * 100 + 0.5));
	}
	number = dataObject.GetMemberFlashNumber("qmiIconTop");
	if (number > 0)
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyLabelPlace(), "", (int)(number * 10 + 0.5));
	}
	if (questPin && !travel)
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
	else if (text != "" && (travel || questPin))
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
	tint = dataObject.GetMemberFlashUInt("qmiIconTint");
	if (tint != 0)
	{
		CMFStylePinTint("modMapQuestInsight", dataObject, tint);
	}
	if (travel && theGame.mqiAdapterNoSignTabs != "")
	{
		CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyTabHide(), theGame.mqiAdapterNoSignTabs, 1);
	}
	// Launch evidence: the first eight quest pins of each game session (the count lives on CMFCore).
	if (questPin && mqiAdapterLogged < 8)
	{
		mqiAdapterLogged += 1;
		LogChannel('CMF', "CMF adapter provider=modMapQuestInsight scale=" +
			FloatToString(dataObject.GetMemberFlashNumber("qmiIconScale")) + " kind=" +
			dataObject.GetMemberFlashInt("qmiIconKind") + " label=" + dataObject.GetMemberFlashString("qmiLevelText") +
			" tint=" + tint + " noSignTabs=" + theGame.mqiAdapterNoSignTabs);
	}
}
