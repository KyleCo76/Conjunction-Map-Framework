// Optional CMF Adapter Check: deferred startup detection and changed-set notices.
// Generator owns only the marked table; keep runtime additions outside it.
struct SCMFAdapterCheckEntry
{
	var modName : string;
	var adapterFolder : string;
	var messageKey : string;
	var providers : array<string>;
	var groups : array<name>;
	var textKeys : array<string>;
}

// BEGIN generated adapter table: tools/cmf_adapter_check.py
// Populated detector categories combine with AND; alternatives within each are OR.
function CMFAdapterCheckEntries(out entries : array<SCMFAdapterCheckEntry>)
{
	var rowValue : SCMFAdapterCheckEntry;
	entries.Clear();
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Map Quest Insight";
	rowValue.adapterFolder = "modCMFAdapterMapQuestInsight";
	rowValue.messageKey = "cmf_adapter_check_mod_000";
	rowValue.providers.PushBack("modMapQuestInsight");
	rowValue.groups.PushBack('qmiPins');
	rowValue.groups.PushBack('qmiColors');
	rowValue.groups.PushBack('qmiBox');
	rowValue.groups.PushBack('qmiHide');
	rowValue.groups.PushBack('qmiWide');
	rowValue.textKeys.PushBack("panel_qmiPins");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Gwent Players Map";
	rowValue.adapterFolder = "modCMFAdapterGwentPlayersMap";
	rowValue.messageKey = "cmf_adapter_check_mod_001";
	rowValue.providers.PushBack("modGwentPlayersMap");
	rowValue.groups.PushBack('GwentPlayersMap');
	rowValue.textKeys.PushBack("gwm_label_gwent_player");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Witcher Gear Map";
	rowValue.adapterFolder = "modCMFAdapterWitcherGearMap";
	rowValue.messageKey = "cmf_adapter_check_mod_002";
	rowValue.providers.PushBack("modWitcherGearMap");
	rowValue.groups.PushBack('wgm_Settings');
	rowValue.textKeys.PushBack("wgm_legendary");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Fog of War";
	rowValue.adapterFolder = "modCMFAdapterFogOfWar";
	rowValue.messageKey = "cmf_adapter_check_mod_003";
	rowValue.providers.PushBack("modFogOfWar");
	rowValue.groups.PushBack('FogOfWar');
	rowValue.textKeys.PushBack("option_fow_enabled");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Witcher's Path";
	rowValue.adapterFolder = "modCMFAdapterWitchersPath";
	rowValue.messageKey = "cmf_adapter_check_mod_004";
	rowValue.providers.PushBack("modWitchersPath");
	rowValue.groups.PushBack('WitchersPath');
	rowValue.textKeys.PushBack("option_wp_enabled");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Botanist";
	rowValue.adapterFolder = "modCMFAdapterBotanist";
	rowValue.messageKey = "cmf_adapter_check_mod_005";
	rowValue.providers.PushBack("modBotanist");
	rowValue.groups.PushBack('Botanist_GeneralSettings');
	rowValue.textKeys.PushBack("BT_HerbMapPinInfo");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "Ink and Iron";
	rowValue.adapterFolder = "modCMFAdapterInkAndIron";
	rowValue.messageKey = "cmf_adapter_check_mod_006";
	rowValue.providers.PushBack("modInkAndIronUI");
	rowValue.groups.PushBack('InkAndIronOptions');
	rowValue.textKeys.PushBack("panel_InkAndIron");
	entries.PushBack(rowValue);
	rowValue.providers.Clear();
	rowValue.groups.Clear();
	rowValue.textKeys.Clear();
	rowValue.modName = "The Stable";
	rowValue.adapterFolder = "modCMFAdapterTheStable";
	rowValue.messageKey = "cmf_adapter_check_mod_007";
	rowValue.providers.PushBack("modArdDhuStable");
	rowValue.textKeys.PushBack("map_location_arddhustable");
	entries.PushBack(rowValue);
}
// END generated adapter table

// Runtime checks once after each load; no catalogue work runs per map pin.
@addField(CR4Game)
var cmfAdapterCheckPending : bool;
@addField(CR4Game)
var cmfAdapterCheckChecked : bool;
@addField(CR4Game)
var cmfAdapterCheckFallback : bool;
// The box was shown in this game session (an older adapter can register later in the session and empty the set).
@addField(CR4Game)
var cmfAdapterCheckWarned : bool;

// Mutate state through its owning object: theGame is a constant global.
@addMethod(CR4Game)
function CMFAdapterCheckConsume()
{
	cmfAdapterCheckPending = false;
	cmfAdapterCheckChecked = true;
	cmfAdapterCheckFallback = false;
}

@addMethod(CR4Game)
function CMFAdapterCheckSetFallback(value : bool)
{
	cmfAdapterCheckFallback = value;
}

@addMethod(CR4Game)
function CMFAdapterCheckSetWarned()
{
	cmfAdapterCheckWarned = true;
}

function CMFAdapterCheckEnabled() : bool
{
	var value : string;
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFAdapterCheck', 'CMFAdapterCheckEnabled'));
	return value != "0" && value != "false";
}

function CMFAdapterCheckBusy() : bool
{
	// The native dialog API reuses MessagePopup; wait rather than replace another notice.
	if (theGame.GetGuiManager().GetPopup('MessagePopup')) { return true; }
	return !theGame.IsActive() || theGame.IsBlackscreen() || theGame.GetGuiManager().IsAnyMenu() || theGame.IsDialogOrCutscenePlaying();
}

function CMFAdapterCheckInstalled(rowValue : SCMFAdapterCheckEntry) : bool
{
	var config : CInGameConfigWrapper;
	var i, j : int;
	var groupFound, textFound : bool;
	var text : string;
	config = theGame.GetInGameConfigWrapper();
	for (i = 0; i < rowValue.groups.Size(); i += 1)
	{
		for (j = 0; j < config.GetGroupsNum(); j += 1)
		{
			if (config.GetGroupName(j) == rowValue.groups[i])
			{
				groupFound = true;
				break;
			}
		}
		if (groupFound) { break; }
	}
	if (rowValue.groups.Size() > 0 && !groupFound) { return false; }
	for (i = 0; i < rowValue.textKeys.Size(); i += 1)
	{
		text = GetLocStringByKeyExt(rowValue.textKeys[i]);
		if (text != "" && !StrBeginsWith(text, "#"))
		{
			textFound = true;
			break;
		}
	}
	if (rowValue.textKeys.Size() > 0 && !textFound) { return false; }
	return rowValue.groups.Size() > 0 || rowValue.textKeys.Size() > 0;
}

function CMFAdapterCheckMissing(out missing : array<SCMFAdapterCheckEntry>)
{
	var entries : array<SCMFAdapterCheckEntry>;
	var i, j : int;
	var present : bool;
	missing.Clear();
	CMFAdapterCheckEntries(entries);
	for (i = 0; i < entries.Size(); i += 1)
	{
		present = false;
		for (j = 0; j < entries[i].providers.Size(); j += 1)
		{
			if (CMFProviderPresent(entries[i].providers[j]))
			{
				present = true;
				break;
			}
		}
		if (!present && CMFAdapterCheckInstalled(entries[i]))
		{
			missing.PushBack(entries[i]);
		}
	}
}

function CMFAdapterCheckSignature(entries : array<SCMFAdapterCheckEntry>) : string
{
	var names : array<string>;
	var folder, signature : string;
	var i : int;
	for (i = 0; i < entries.Size(); i += 1)
	{
		folder = StrLower(entries[i].adapterFolder);
		if (names.FindFirst(folder) < 0) { names.PushBack(folder); }
	}
	ArraySortStrings(names);
	for (i = 0; i < names.Size(); i += 1)
	{
		if (i > 0) { signature += "|"; }
		signature += names[i];
	}
	return signature;
}

function CMFAdapterCheckRun()
{
	var missing : array<SCMFAdapterCheckEntry>;
	var signature, known, text, title : string;
	var i : int;
	if (!theGame.cmfAdapterCheckPending || theGame.cmfAdapterCheckChecked || CMFAdapterCheckBusy()) { return; }
	// Consume pending state before config writes or native dialog dispatch can reenter.
	theGame.CMFAdapterCheckConsume();
	if (!CMFAdapterCheckEnabled()) { return; }
	CMFAdapterCheckMissing(missing);
	signature = CMFAdapterCheckSignature(missing);
	for (i = 0; i < missing.Size(); i += 1)
	{
		CMFLog("adapter check missing mod=" + missing[i].modName + " adapter=" + missing[i].adapterFolder);
	}
	CMFLog("adapter check missing count=" + missing.Size() + " set=" + signature);
	known = theGame.GetInGameConfigWrapper().GetVarValue('CMFAdapterCheck', 'CMFAdapterCheckKnown');
	if (known == "-1") { known = ""; }
	if (known == signature) { return; }
	// An adapter that registers only once the map has opened empties the set on a later load; the warned set stays,
	// so the box does not come back after a restart.
	if (signature == "" && theGame.cmfAdapterCheckWarned) { return; }
	theGame.GetInGameConfigWrapper().SetVarValue('CMFAdapterCheck', 'CMFAdapterCheckKnown', signature);
	theGame.SaveUserSettings();
	if (signature == "") { return; }
	theGame.CMFAdapterCheckSetWarned();
	title = GetLocStringByKeyExt("panel_cmf_adapter_check");
	text = GetLocStringByKeyExt("cmf_adapter_check_intro");
	for (i = 0; i < missing.Size(); i += 1)
	{
		text += "<br><br>" + GetLocStringByKeyExt(missing[i].messageKey);
	}
	text += "<br><br>" + GetLocStringByKeyExt("cmf_adapter_check_footer");
	theGame.GetGuiManager().ShowUserDialogAdv(0, title, text, false, UDB_Ok);
}

function CMFAdapterCheckSchedule()
{
	if (!theGame.cmfAdapterCheckPending || theGame.cmfAdapterCheckChecked) { return; }
	if (!thePlayer)
	{
		if (!theGame.cmfAdapterCheckFallback) { CMFLog("adapter check deferred reason=noplayer wait=mapclose"); }
		theGame.CMFAdapterCheckSetFallback(true);
		return;
	}
	theGame.CMFAdapterCheckSetFallback(false);
	thePlayer.AddTimer('CMFAdapterCheckAfterLoad', 0.1, false, , , false, true);
}

@addMethod(CR4Player)
timer function CMFAdapterCheckAfterLoad(dt : float, id : int)
{
	if (!theGame.cmfAdapterCheckPending || theGame.cmfAdapterCheckChecked) { return; }
	if (CMFAdapterCheckBusy())
	{
		CMFAdapterCheckSchedule();
		return;
	}
	CMFAdapterCheckRun();
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	cmfAdapterCheckPending = true;
	cmfAdapterCheckChecked = false;
	cmfAdapterCheckFallback = false;
	CMFAdapterCheckSchedule();
	return result;
}

@wrapMethod(CR4Game)
function OnGameEnded()
{
	var result : bool;
	cmfAdapterCheckPending = false;
	cmfAdapterCheckFallback = false;
	if (thePlayer) { thePlayer.RemoveTimer('CMFAdapterCheckAfterLoad'); }
	result = wrappedMethod();
	return result;
}

@wrapMethod(CR4MapMenu)
function OnClosingMenu()
{
	var result : bool;
	result = wrappedMethod();
	// Only an unavailable scheduler enables this fallback. Never scan on map opening.
	if (theGame.cmfAdapterCheckPending && theGame.cmfAdapterCheckFallback)
	{
		CMFAdapterCheckSchedule();
		if (theGame.cmfAdapterCheckFallback && !CMFAdapterCheckBusy()) { CMFAdapterCheckRun(); }
	}
	return result;
}
