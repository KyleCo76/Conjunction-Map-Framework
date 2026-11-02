// Map-mod inventory (CMF In-Game Menu add-on). One row per map-related mod that never tells CMF it is installed:
// provider|name|what|kind|signal|text. The provider is the identity an adapter or the mod declares, else its Mods
// folder. kind "listener" rows are found by CMF's map file (the core presence list), "group" rows by their menu group
// in the game's settings, "string" rows by a string id that reads as the given text, "key" rows by a text key that exists. Folders and versions were read
// on 2026-11-02. To remove a row see docs/development/map-mod-inventory.md.

function CMFMenuInventoryCount() : int
{
	return 21;
}

function CMFMenuInventoryEntry(i : int) : string
{
	switch (i)
	{
		case 0: return "modmapredraw|Map Remastered|Map painting|listener|SetRedesignedMapIcons|";
		case 1: return "mod00000_UltrawideMenus|Ultrawide Menus|Wide menus|group|uwMenu|";
		case 2: return "modMalaombraMap|Malaombra's Map|Map pins|group|MalaombraMapGeneral|";
		case 3: return "modHideQuests|Hide Quests Remastered|Hides quest pins|group|HideQuests|";
		case 4: return "modCleanMap|Clean Map|Hides map pins|string|2116418000|Clean Map";
		case 5: return "modMonsterHuntContracts|Monster Hunt Contracts|Contract pins|group|MHCContracts|";
		case 6: return "modMinimapZoom|Configurable Minimap Zoom|Minimap zoom|group|MinimapZoom|";
		case 7: return "modHUDPositionManager|HUD Position Manager|Minimap place|group|HUDPositionManager|";
		case 8: return "modcgui|Community GUI|Minimap|group|CGUI_HUDMinimapSettings|";
		case 9: return "modWolfsBearing|Wolf's Bearing|Minimap|group|WolfsBearing|";
		case 10: return "modRoachLove|Roach Love|Roach pin|group|RoachLove|";
		case 11: return "modDanoFlotante|Floating Damage|Minimap clock|group|DanoFlotante|";
		case 12: return "modMapQuestInsight|Map Quest Insight|Needs its adapter|group|qmiGeneral|";
		case 13: return "modFogOfWar|Fog of War|Needs its adapter|group|FogOfWar|";
		case 14: return "modWitchersPath|Witcher's Path|Needs its adapter|group|WitchersPath|";
		case 15: return "modInkAndIronUI|Ink and Iron|Needs its adapter|group|InkAndIronOptions|";
		case 16: return "modGwentPlayersMap|Gwent Players Map|Needs its adapter|group|GwentPlayersMap|";
		case 17: return "modWitcherGearMap|Witcher Gear Map|Needs its adapter|group|wgm_Settings|";
		case 18: return "modBotanist|Botanist|Needs its adapter|group|Botanist_GeneralSettings|";
		case 19: return "mod000SmoothMap|Smooth Map|Map movement|group|SmoothMapCMF|";
		case 20: return "modArdDhuStable|The Stable|Needs its adapter|key|map_location_arddhustable|";
	}
	return "";
}

// Field n (0-based) of a row; "" when the row has fewer fields.
function CMFMenuInventoryField(rowText : string, n : int) : string
{
	var rest : string;
	var i : int;
	rest = rowText;
	for (i = 0; i < n; i += 1)
	{
		if (StrFindFirst(rest, "|") < 0)
		{
			return "";
		}
		rest = StrAfterFirst(rest, "|");
	}
	if (StrFindFirst(rest, "|") >= 0)
	{
		return StrBeforeFirst(rest, "|");
	}
	return rest;
}

// The row of a provider (case-insensitive), or -1.
function CMFMenuInventoryIndex(provider : string) : int
{
	var i : int;
	var identity : string;
	identity = StrLower(provider);
	for (i = 0; i < CMFMenuInventoryCount(); i += 1)
	{
		if (StrLower(CMFMenuInventoryField(CMFMenuInventoryEntry(i), 0)) == identity)
		{
			return i;
		}
	}
	return -1;
}

// The settings group of a "group" row as a name literal (the game has no text-to-name call), or '' for other rows.
function CMFMenuInventoryGroup(i : int) : name
{
	switch (i)
	{
		case 1:
			return 'uwMenu';
		case 2:
			return 'MalaombraMapGeneral';
		case 3:
			return 'HideQuests';
		case 5:
			return 'MHCContracts';
		case 6:
			return 'MinimapZoom';
		case 7:
			return 'HUDPositionManager';
		case 8:
			return 'CGUI_HUDMinimapSettings';
		case 9:
			return 'WolfsBearing';
		case 10:
			return 'RoachLove';
		case 11:
			return 'DanoFlotante';
		case 12:
			return 'qmiGeneral';
		case 13:
			return 'FogOfWar';
		case 14:
			return 'WitchersPath';
		case 15:
			return 'InkAndIronOptions';
		case 16:
			return 'GwentPlayersMap';
		case 17:
			return 'wgm_Settings';
		case 18:
			return 'Botanist_GeneralSettings';
		case 19:
			return 'SmoothMapCMF';
		default:
			return '';
	}
}

// Providers found in the game's settings now: a group row whose menu group exists, a string row whose id reads as its text, a key row whose text key exists.
function CMFMenuInventoryFound(out providers : array<string>)
{
	var config : CInGameConfigWrapper;
	var rowText, kind, signal, keyText : string;
	var i : int;
	var found : bool;
	config = theGame.GetInGameConfigWrapper();
	providers.Clear();
	for (i = 0; i < CMFMenuInventoryCount(); i += 1)
	{
		rowText = CMFMenuInventoryEntry(i);
		kind = CMFMenuInventoryField(rowText, 3);
		signal = CMFMenuInventoryField(rowText, 4);
		found = false;
		if (kind == "group")
		{
			found = config.GetGroupIdx(CMFMenuInventoryGroup(i)) >= 0;
		}
		else if (kind == "string")
		{
			found = GetLocStringById(StringToInt(signal)) == CMFMenuInventoryField(rowText, 5);
		}
		else if (kind == "key")
		{
			// A missing key reads as "" or as "#<key>".
			keyText = GetLocStringByKeyExt(signal);
			found = keyText != "" && !StrBeginsWith(keyText, "#");
		}
		if (found)
		{
			providers.PushBack(CMFMenuInventoryField(rowText, 0));
		}
	}
}

// True when a "Needs its adapter" mod is in the settings and no provider has told CMF it is there.
function CMFMenuInventoryNeedsAdapter(provider : string) : bool
{
	var index : int;
	var found : array<string>;
	index = CMFMenuInventoryIndex(provider);
	if (index < 0 || CMFMenuInventoryField(CMFMenuInventoryEntry(index), 2) != "Needs its adapter")
	{
		return false;
	}
	CMFMenuInventoryFound(found);
	return found.Contains(provider) && !CMFProviderPresent(provider);
}
