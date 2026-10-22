// CMF In-Game Menu (modCMFInGameMenu): the optional Options > Mods > Conjunction Map Framework entry for CMF 1.2.0
// and later (CMFGetVersion 8). Its menu file declares every row with spare placeholder choices; while the game builds
// a page, this script replaces them with the loaded map mods and remembers which folder name each position stands
// for. A chosen row keeps the folder name in a hidden name var beside it (CMFName_<key>, CMFOrderName<n>), so a
// choice survives mods being added or removed. CMF reads the rows each time it prepares winners (ReadMenuChoices).
// Without this add-on every in-game level reads Automatic.

// The positions each live row showed when its page was built: one comma-joined list of answers per row var ("" is
// Automatic, then "vanilla" where shown, then folder names). The game keeps the position; the answer is the folder.
class CMFMenuState extends CObject
{
	private var rowVars : array<name>;
	private var rowAnswers : array<string>;
	private var helpVars : array<name>;
	private var helpTexts : array<string>;
	private var boxShown : bool;

	// 1.1.0: the help line of a choice row ("Offered by: ..."), made when its page is built.
	public function RememberHelp(varName : name, text : string)
	{
		var i : int;
		i = helpVars.FindFirst(varName);
		if (i < 0)
		{
			helpVars.PushBack(varName);
			helpTexts.PushBack(text);
		}
		else
		{
			helpTexts[i] = text;
		}
	}

	public function Help(varName : name, out text : string) : bool
	{
		var i : int;
		i = helpVars.FindFirst(varName);
		text = "";
		if (i < 0)
		{
			return false;
		}
		text = helpTexts[i];
		return true;
	}

	// Whether the Options list's help box shows a CMF help line now.
	public function SetBoxShown(shown : bool)
	{
		boxShown = shown;
	}

	public function BoxShown() : bool
	{
		return boxShown;
	}

	public function Remember(varName : name, answers : string)
	{
		var i : int;
		i = rowVars.FindFirst(varName);
		if (i < 0)
		{
			rowVars.PushBack(varName);
			rowAnswers.PushBack(answers);
		}
		else
		{
			rowAnswers[i] = answers;
		}
	}

	// The answer at a position of a row, or false when the row was not built this session.
	public function Answer(varName : name, position : int, out answer : string) : bool
	{
		var i : int;
		var found : bool;
		answer = "";
		if (position <= 0)
		{
			return true;
		}
		i = rowVars.FindFirst(varName);
		if (i < 0)
		{
			return false;
		}
		answer = CMFMenuNth(rowAnswers[i], position, found);
		return found;
	}
}

@addField(CR4Game)
var cmfMenuState : CMFMenuState;

@addMethod(CR4Game)
public function CMFMenuGetState() : CMFMenuState
{
	if (!cmfMenuState)
	{
		cmfMenuState = new CMFMenuState in this;
	}
	return cmfMenuState;
}

// Item n (from 0) of a comma-joined list; found is false past the end.
function CMFMenuNth(joined : string, n : int, out found : bool) : string
{
	var rest, left, right : string;
	var i : int;
	rest = joined;
	for (i = 0; i < n; i += 1)
	{
		if (!StrSplitFirst(rest, ",", left, right))
		{
			found = false;
			return "";
		}
		rest = right;
	}
	found = true;
	if (StrSplitFirst(rest, ",", left, right))
	{
		return left;
	}
	return rest;
}

// The page that holds a choice key's row and name var (tools/cmf_menu_addon.py PAGES); '' for an unknown key.
function CMFMenuGroupOf(key : string) : name
{
	if (StrFindFirst(key, "_") < 0)
	{
		return 'CMFMenuBasic';
	}
	if (StrBeginsWith(key, "Icons_"))
	{
		return 'CMFMenuAdvIcons';
	}
	if (StrBeginsWith(key, "Colours_"))
	{
		return 'CMFMenuAdvColours';
	}
	if (StrBeginsWith(key, "Size_") || StrBeginsWith(key, "Labels_"))
	{
		return 'CMFMenuAdvSize';
	}
	if (StrBeginsWith(key, "Legend_") || StrBeginsWith(key, "Hidden_"))
	{
		return 'CMFMenuAdvLegend';
	}
	if (StrBeginsWith(key, "Look_"))
	{
		return 'CMFMenuAdvLook';
	}
	if (StrBeginsWith(key, "Movement_"))
	{
		return 'CMFMenuAdvMovement';
	}
	if (StrBeginsWith(key, "Painting_"))
	{
		return 'CMFMenuAdvPainting';
	}
	if (StrBeginsWith(key, "Clicks_") || StrBeginsWith(key, "Drawings_"))
	{
		return 'CMFMenuAdvClicks';
	}
	return '';
}

// Every page that holds choice rows.
function CMFMenuChoiceGroups() : array<name>
{
	var groups : array<name>;
	groups.PushBack('CMFMenuBasic');
	groups.PushBack('CMFMenuAdvIcons');
	groups.PushBack('CMFMenuAdvColours');
	groups.PushBack('CMFMenuAdvSize');
	groups.PushBack('CMFMenuAdvLegend');
	groups.PushBack('CMFMenuAdvLook');
	groups.PushBack('CMFMenuAdvMovement');
	groups.PushBack('CMFMenuAdvPainting');
	groups.PushBack('CMFMenuAdvClicks');
	return groups;
}

// A var of a page by its name as text; '' when the page has none.
function CMFMenuVarNamed(groupName : name, varText : string) : name
{
	var config : CInGameConfigWrapper;
	var varName : name;
	var i, count : int;
	config = theGame.GetInGameConfigWrapper();
	count = config.GetVarsNumByGroupName(groupName);
	for (i = 0; i < count; i += 1)
	{
		varName = config.GetVarNameByGroupName(groupName, i);
		if (NameToString(varName) == varText)
		{
			return varName;
		}
	}
	return '';
}

// A heading as the menu shows it. The heading test page (probe builds only) shows styles 0 to 3, the candidates of
// the layout plan for Kyle to pick: 0 a box-drawing rule each side, 1 a dash rule each side, 2 a plain rule in the
// game's colour markup, 3 the label then a long box rule. Rules come from the string tables, because script files
// stay ASCII. Any other style is a plain ASCII rule each side. Kyle picked style 1 in menu launch 1 (2026-10-22):
// the game's menu font has no box-drawing characters, and the colour markup does not show.
function CMFMenuHeading(text : string, style : int) : string
{
	var box : string;
	box = GetLocStringByKeyExt("cmf_menu_rule_box");
	switch (style)
	{
		case 0:
			return box + "   " + StrUpper(text) + "   " + box;
		case 1:
			return CMFMenuDashHeading(text);
		case 2:
			return "<font color='#D2B48C'>------   " + StrUpper(text) + "   ------</font>";
		case 3:
			return StrUpper(text) + "   " + box + box;
	}
	return "------   " + text + "   ------";
}

// Style 1: a dash rule each side, shortened for a long heading so the line stays inside the row (launch 1: twelve
// dashes each side and about 12 capitals fill three quarters of the row at 1080p; a capital is about as wide as
// nine tenths of a dash). A heading too long for any rule is shown in capitals alone.
function CMFMenuDashHeading(text : string) : string
{
	var rule : string;
	var dashes : int;
	dashes = (800 - 18 * StrLen(text)) / 40;
	if (dashes > 12)
	{
		dashes = 12;
	}
	if (dashes < 2)
	{
		return StrUpper(text);
	}
	rule = StrLeft(GetLocStringByKeyExt("cmf_menu_rule_dash"), dashes);
	return rule + "   " + StrUpper(text) + "   " + rule;
}

function CMFMenuHeadingStyle() : int
{
	return 1;
}

// The feature names the Loaded map mods page lists, by feature index (CMFChoiceKeys 0 to 10).
function CMFMenuFeatureName(feature : int) : string
{
	switch (feature)
	{
		case 0:
			return "Icons";
		case 1:
			return "Colours";
		case 2:
			return "Size";
		case 3:
			return "Labels";
		case 4:
			return "Clicks";
		case 5:
			return "Legend";
		case 6:
			return "Hidden pins";
		case 7:
			return "Look";
		case 8:
			return "Movement";
		case 9:
			return "Painting";
		case 10:
			return "Drawings";
	}
	return "";
}

// The map mods the pages list: CMF's providers when a save is loaded, which also become the remembered list;
// otherwise (the title screen) the remembered list from last time, and true.
function CMFMenuProviders(out providers : array<string>) : bool
{
	var config : CInGameConfigWrapper;
	var varName : name;
	var value : string;
	var i, count : int;
	var changed : bool;
	config = theGame.GetInGameConfigWrapper();
	theGame.CMFGetCore().Providers(providers);
	count = config.GetVarsNumByGroupName('CMFMenuKnown');
	if (providers.Size() > 0)
	{
		changed = false;
		for (i = 0; i < count; i += 1)
		{
			varName = config.GetVarNameByGroupName('CMFMenuKnown', i);
			value = "";
			if (i < providers.Size())
			{
				value = providers[i];
			}
			if (config.GetVarValue('CMFMenuKnown', varName) != value)
			{
				config.SetVarValue('CMFMenuKnown', varName, value);
				changed = true;
			}
		}
		if (changed)
		{
			theGame.SaveUserSettings();
		}
		return false;
	}
	for (i = 0; i < count; i += 1)
	{
		value = config.GetVarValue('CMFMenuKnown', config.GetVarNameByGroupName('CMFMenuKnown', i));
		if (value != "")
		{
			providers.PushBack(value);
		}
	}
	return true;
}

// Called by the game for each Options page it builds. CMF's pages get their live rows; every other page is left
// exactly as built.
@wrapMethod function IngameMenu_FillSubMenuOptionsList(flashStorageUtility : CScriptedFlashValueStorage, groupID : int,
	groupName : name, groupRootObject : CScriptedFlashObject) : bool
{
	var result : bool;
	result = wrappedMethod(flashStorageUtility, groupID, groupName, groupRootObject);
	if (result && StrBeginsWith(NameToString(groupName), "CMFMenu"))
	{
		CMFMenuFillPage(flashStorageUtility, groupName, groupRootObject);
	}
	return result;
}

function CMFMenuFillPage(storage : CScriptedFlashValueStorage, groupName : name, groupRootObject : CScriptedFlashObject)
{
	var config : CInGameConfigWrapper;
	var rows : CScriptedFlashArray;
	var row : CScriptedFlashObject;
	var providers : array<string>;
	var remembered : bool;
	var varName : name;
	var varText : string;
	var i : int;
	config = theGame.GetInGameConfigWrapper();
	remembered = CMFMenuProviders(providers);
	rows = groupRootObject.GetMemberFlashArray("subElements");
	for (i = rows.GetLength() - 1; i >= 0; i -= 1)
	{
		row = rows.GetElementFlashObject(i);
		varName = config.GetVarNameByGroupName(groupName, StringToInt(row.GetMemberFlashString("id")));
		varText = NameToString(varName);
		if (varText == "CMFHead_Mods")
		{
			CMFMenuFillModsHeading(row, providers.Size(), remembered);
		}
		else if (StrBeginsWith(varText, "CMFHead_Test_"))
		{
			row.SetMemberFlashString("label", CMFMenuHeading("Style " + IntToString(StringToInt(StrAfterFirst(varText, "CMFHead_Test_")) + 1) +
				" pins", StringToInt(StrAfterFirst(varText, "CMFHead_Test_"))));
		}
		else if (StrBeginsWith(varText, "CMFHead_"))
		{
			row.SetMemberFlashString("label", CMFMenuHeading(row.GetMemberFlashString("label"), CMFMenuHeadingStyle()));
		}
		else if (StrBeginsWith(varText, "CMFPick_"))
		{
			CMFMenuFillPick(storage, row, groupName, varName, StrAfterFirst(varText, "CMFPick_"), providers, remembered);
		}
		else if (StrBeginsWith(varText, "CMFOrder"))
		{
			CMFMenuFillOrder(storage, row, varName, StrAfterFirst(varText, "CMFOrder"), providers);
		}
		else if (StrBeginsWith(varText, "CMFStatusMod"))
		{
			if (!CMFMenuFillMod(storage, row, StringToInt(StrAfterFirst(varText, "CMFStatusMod")) - 1, providers,
				remembered))
			{
				rows.RemoveElement(i);
			}
		}
		else if (varText == "CMFReset")
		{
			CMFMenuFillReset(row);
		}
		else if (StrBeginsWith(varText, "CMFWin_"))
		{
			CMFMenuFillWin(storage, row, StrAfterFirst(varText, "CMFWin_"), providers, remembered);
		}
	}
}

// Sets a row's choices, its current position and whether it is greyed.
function CMFMenuSetChoices(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, labels : array<string>,
	current : int, disabled : bool)
{
	var choices : CScriptedFlashArray;
	var i : int;
	choices = storage.CreateTempFlashArray();
	for (i = 0; i < labels.Size(); i += 1)
	{
		choices.PushBackFlashString(labels[i]);
	}
	row.SetMemberFlashArray("subElements", choices);
	row.SetMemberFlashString("current", IntToString(current));
	row.SetMemberFlashString("startingValue", IntToString(current));
	row.SetMemberFlashBool("disabled", disabled);
}

// Adds the stored answer when the list does not hold it, and returns its position: "(offers none)" for a loaded map
// mod that has nothing for this row (Kyle, menu launch 3), "(not loaded)" for one that is gone.
function CMFMenuPlaceStored(stored : string, out labels : array<string>, out answers : array<string>, room : int,
	providers : array<string>) : int
{
	var shown, after : string;
	var i : int;
	if (stored == "")
	{
		return 0;
	}
	for (i = 0; i < answers.Size(); i += 1)
	{
		if (StrLower(answers[i]) == StrLower(stored))
		{
			return i;
		}
	}
	if (answers.Size() >= room)
	{
		labels.PopBack();
		answers.PopBack();
	}
	shown = CMFTidyName(stored);
	after = " (not loaded)";
	for (i = 0; i < providers.Size(); i += 1)
	{
		if (StrLower(providers[i]) == StrLower(stored))
		{
			shown = theGame.CMFGetCore().ProviderName(providers[i]);
			after = " (offers none)";
		}
	}
	labels.PushBack(CMFMenuFit("", shown, after));
	answers.PushBack(stored);
	return answers.Size() - 1;
}

function CMFMenuJoin(answers : array<string>) : string
{
	var joined : string;
	var i : int;
	joined = "";
	for (i = 0; i < answers.Size(); i += 1)
	{
		if (i > 0)
		{
			joined += ",";
		}
		joined += answers[i];
	}
	return joined;
}

// A value sits in a column about 32 characters wide (menu launch 2: "Test Minimap Checks (Folder order)" lost its
// closing bracket), so a long mod name drops whole words from its end, then letters, and ends in "...".
function CMFMenuFit(before : string, modName : string, after : string) : string
{
	var shown : string;
	var room, space : int;
	shown = modName;
	room = 32 - StrLen(before) - StrLen(after);
	if (StrLen(shown) <= room || room < 6)
	{
		return before + shown + after;
	}
	while (StrLen(shown) > room - 3)
	{
		space = StrFindLast(shown, " ");
		if (space <= 0)
		{
			shown = StrLeft(shown, room - 3);
		}
		else
		{
			shown = StrLeft(shown, space);
		}
	}
	return before + shown + "..." + after;
}

// A choice row: Automatic (with who wins without this row), Vanilla, then map mods (on Basic and the leave-out slots
// only those that offer the piece; on Advanced every loaded map mod, since some offers show only after the map has
// been opened). A leave-out slot of Hidden pins or Drawings reads Nobody / each mod that offers it.
function CMFMenuFillPick(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, groupName : name,
	varName : name, key : string, providers : array<string>, remembered : bool)
{
	var core : CMFCore;
	var config : CInGameConfigWrapper;
	var labels, answers : array<string>;
	var nameVar : name;
	var choice, feature, level, skip, offered, current, i : int;
	var additive, slot, basic, offering, offeredAny, seen : bool;
	var winner, stored, automatic : string;
	core = theGame.CMFGetCore();
	config = theGame.GetInGameConfigWrapper();
	choice = core.ChoiceIndex(key);
	if (choice < 0)
	{
		return;
	}
	feature = core.ChoiceFeature(choice);
	basic = choice == feature;
	additive = feature == 6 || feature == 10;
	slot = additive && !basic;
	seen = core.MapSeen();
	offeredAny = !seen;
	for (i = 0; i < providers.Size(); i += 1)
	{
		if (core.Offers(choice, providers[i]))
		{
			offeredAny = true;
		}
	}
	if (remembered)
	{
		automatic = "Automatic";
		if (slot)
		{
			automatic = "Nobody";
		}
		offeredAny = true;
	}
	else if (slot)
	{
		automatic = "Nobody";
	}
	else if (additive)
	{
		core.AllowedCount(feature, offered);
		automatic = "Automatic";
		if (seen)
		{
			automatic = "Automatic (none loaded)";
		}
		if (offered == 1)
		{
			automatic = "Automatic (1 mod)";
		}
		else if (offered > 1)
		{
			automatic = "Automatic (all " + IntToString(offered) + " mods)";
		}
	}
	else
	{
		skip = 2;
		if (!basic)
		{
			skip = 1;
		}
		winner = core.WinnerOf(choice, skip, level);
		automatic = "Automatic";
		if (seen)
		{
			automatic = "Automatic (none loaded)";
		}
		if (winner == "vanilla")
		{
			automatic = "Automatic (Vanilla)";
		}
		else if (winner != "")
		{
			automatic = CMFMenuFit("Automatic (", core.ProviderName(winner), ")");
		}
	}
	labels.PushBack(automatic);
	answers.PushBack("");
	if (!slot)
	{
		labels.PushBack("Vanilla");
		answers.PushBack("vanilla");
	}
	for (i = 0; i < providers.Size() && answers.Size() < 25; i += 1)
	{
		offering = remembered || !seen || core.Offers(choice, providers[i]);
		if (offering || (!basic && !slot))
		{
			labels.PushBack(CMFMenuFit("", core.ProviderName(providers[i]), ""));
			answers.PushBack(providers[i]);
		}
	}
	nameVar = CMFMenuVarNamed(groupName, "CMFName_" + key);
	stored = "";
	if (nameVar != '')
	{
		stored = config.GetVarValue(groupName, nameVar);
	}
	current = CMFMenuPlaceStored(stored, labels, answers, 25, providers);
	CMFMenuSetChoices(storage, row, labels, current, !offeredAny && stored == "");
	theGame.CMFMenuGetState().Remember(varName, CMFMenuJoin(answers));
	theGame.CMFMenuGetState().RememberHelp(varName, CMFMenuHelpText(choice, providers, remembered, seen));
	if (config.GetVarValue(groupName, varName) != IntToString(current))
	{
		config.SetVarValue(groupName, varName, IntToString(current));
	}
}

// A Mod order row: Automatic, then every map mod.
function CMFMenuFillOrder(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, varName : name,
	position : string, providers : array<string>)
{
	var config : CInGameConfigWrapper;
	var labels, answers : array<string>;
	var nameVar : name;
	var stored : string;
	var current, i : int;
	config = theGame.GetInGameConfigWrapper();
	labels.PushBack("Automatic");
	answers.PushBack("");
	for (i = 0; i < providers.Size() && answers.Size() < 25; i += 1)
	{
		labels.PushBack(CMFMenuFit("", theGame.CMFGetCore().ProviderName(providers[i]), ""));
		answers.PushBack(providers[i]);
	}
	nameVar = CMFMenuVarNamed('CMFMenuOrder', "CMFOrderName" + position);
	stored = "";
	if (nameVar != '')
	{
		stored = config.GetVarValue('CMFMenuOrder', nameVar);
	}
	current = CMFMenuPlaceStored(stored, labels, answers, 25, providers);
	CMFMenuSetChoices(storage, row, labels, current, false);
	theGame.CMFMenuGetState().Remember(varName, CMFMenuJoin(answers));
	if (config.GetVarValue('CMFMenuOrder', varName) != IntToString(current))
	{
		config.SetVarValue('CMFMenuOrder', varName, IntToString(current));
	}
}

function CMFMenuFillModsHeading(row : CScriptedFlashObject, count : int, remembered : bool)
{
	var text : string;
	text = IntToString(count) + " map mods loaded";
	if (count == 1)
	{
		text = "1 map mod loaded";
	}
	if (!remembered && !theGame.CMFGetCore().MapSeen())
	{
		text = IntToString(count) + " map mods so far (open the map once to see all)";
	}
	if (remembered)
	{
		text = IntToString(count) + " map mods seen last time (load a save to refresh)";
		if (count == 1)
		{
			text = "1 map mod seen last time (load a save to refresh)";
		}
	}
	row.SetMemberFlashString("label", CMFMenuHeading(text, CMFMenuHeadingStyle()));
}

// One Loaded map mods row: the mod's name and what it offers. False for a spare row, which the page then drops.
function CMFMenuFillMod(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, index : int,
	providers : array<string>, remembered : bool) : bool
{
	var core : CMFCore;
	var labels : array<string>;
	var text : string;
	var feature : int;
	if (index < 0 || index >= providers.Size())
	{
		return false;
	}
	core = theGame.CMFGetCore();
	row.SetMemberFlashString("label", core.ProviderName(providers[index]));
	text = "";
	if (remembered)
	{
		text = "Seen last time";
	}
	else
	{
		for (feature = 0; feature <= 10; feature += 1)
		{
			if (core.Offers(feature, providers[index]))
			{
				if (text != "")
				{
					text += ", ";
				}
				text += CMFMenuFeatureName(feature);
			}
		}
		if (text == "")
		{
			text = "Nothing yet (open the map)";
		}
	}
	labels.PushBack(text);
	CMFMenuSetChoices(storage, row, labels, 0, false);
	return true;
}

// One Who wins row: the winner and the level that decided it; hides and drawings say how many mods' apply.
function CMFMenuFillWin(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, key : string,
	providers : array<string>, remembered : bool)
{
	var core : CMFCore;
	var labels : array<string>;
	var choice, level, offered, allowed : int;
	var winner, text : string;
	var greyed : bool;
	core = theGame.CMFGetCore();
	choice = core.ChoiceIndex(key);
	if (choice < 0)
	{
		return;
	}
	greyed = false;
	if (remembered)
	{
		text = "Load a save to see";
		greyed = true;
	}
	else if (choice == 6 || choice == 10)
	{
		allowed = core.AllowedCount(choice, offered);
		text = "From " + IntToString(allowed) + " of " + IntToString(offered) + " mods";
		if (offered == 0)
		{
			text = "Vanilla (none loaded)";
			greyed = true;
		}
	}
	else
	{
		winner = core.WinnerOf(choice, 0, level);
		if (winner == "" && !core.MapSeen())
		{
			text = "Open the map once to see";
			greyed = true;
		}
		else if (winner == "")
		{
			text = "Vanilla (none loaded)";
			greyed = true;
		}
		else if (winner == "vanilla")
		{
			text = "Vanilla (" + core.LevelName(level) + ")";
		}
		else
		{
			text = CMFMenuFit("", core.ProviderName(winner), " (" + core.LevelName(level) + ")");
		}
	}
	labels.PushBack(text);
	CMFMenuSetChoices(storage, row, labels, 0, greyed);
}

// 1.1.0: the help line of a choice row. It names every loaded map mod that offers the piece, in order; before the
// map has been opened some offers are not known yet, so it says so (menu launch 3: the line named one mod while more
// could be chosen).
function CMFMenuHelpText(choice : int, providers : array<string>, remembered : bool, seen : bool) : string
{
	var core : CMFCore;
	var text : string;
	var i, shown : int;
	if (remembered)
	{
		return "Load a save to see which mods offer this";
	}
	core = theGame.CMFGetCore();
	text = "";
	shown = 0;
	for (i = 0; i < providers.Size(); i += 1)
	{
		if (core.Offers(choice, providers[i]))
		{
			if (shown > 0)
			{
				text += ", ";
			}
			text += core.ProviderName(providers[i]);
			shown += 1;
		}
	}
	if (shown == 0)
	{
		if (!seen)
		{
			return "Open the map once to see which mods offer this";
		}
		return "No loaded map mod offers this";
	}
	if (!seen)
	{
		return "Offered by: " + text + " (open the map once for the rest)";
	}
	return "Offered by: " + text;
}

// 1.1.0: the game calls this each time the highlight moves to an Options row (menu launch 3). A CMF choice row shows
// its help line in the Options list's own help box (updateBardsBalladText and showBardsBalladTooltip); any other row
// hides the box again. Changing a row's label instead also renames the selected left-hand entry (night launch
// 2026-10-22), so the help line never goes into a row.
@wrapMethod(CR4IngameMenu) function OnOptionSelectionChanged(optionName : name, value : bool)
{
	var menuState : CMFMenuState;
	var text : string;
	menuState = theGame.CMFMenuGetState();
	if (StrBeginsWith(NameToString(optionName), "CMFPick_") && menuState.Help(optionName, text))
	{
		m_flashModule.GetMemberFlashFunction("updateBardsBalladText").InvokeSelfOneArg(FlashArgString(text));
		m_flashModule.GetMemberFlashFunction("showBardsBalladTooltip").InvokeSelfOneArg(FlashArgBool(true));
		menuState.SetBoxShown(true);
	}
	else if (menuState.BoxShown())
	{
		m_flashModule.GetMemberFlashFunction("updateBardsBalladText").InvokeSelfOneArg(FlashArgString(""));
		m_flashModule.GetMemberFlashFunction("showBardsBalladTooltip").InvokeSelfOneArg(FlashArgBool(false));
		menuState.SetBoxShown(false);
	}
	return wrappedMethod(optionName, value);
}

// 1.1.0: a newly shown Options page never keeps the box from the last one.
@wrapMethod(CR4IngameMenu) function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string) : void
{
	if (theGame.CMFMenuGetState().BoxShown())
	{
		m_flashModule.GetMemberFlashFunction("updateBardsBalladText").InvokeSelfOneArg(FlashArgString(""));
		m_flashModule.GetMemberFlashFunction("showBardsBalladTooltip").InvokeSelfOneArg(FlashArgBool(false));
		theGame.CMFMenuGetState().SetBoxShown(false);
	}
	wrappedMethod(actionType, menuTag, id);
}

// Called by the game after an Options row changes and its value is stored. A choice or order row stores the folder
// name its position stood for; Reset clears every row; any change tells CMF to prepare its winners again.
@wrapMethod(CR4Game) function OnConfigValueChanged(varName : name, value : string) : void
{
	wrappedMethod(varName, value);
	CMFMenuValueChanged(varName, value);
}

function CMFMenuValueChanged(varName : name, value : string)
{
	var config : CInGameConfigWrapper;
	var varText, key, answer : string;
	var groupName, nameVar : name;
	varText = NameToString(varName);
	if (!StrBeginsWith(varText, "CMF"))
	{
		return;
	}
	if (varText == "CMFReset")
	{
		CMFLog("menu change var=CMFReset value=" + value);
		if (value == "1")
		{
			CMFMenuReset();
		}
		return;
	}
	if (varText == "CMFFallthrough" || varText == "CMFReport")
	{
		CMFChoicesChanged();
		return;
	}
	if (StrBeginsWith(varText, "CMFPick_"))
	{
		key = StrAfterFirst(varText, "CMFPick_");
		groupName = CMFMenuGroupOf(key);
		nameVar = CMFMenuVarNamed(groupName, "CMFName_" + key);
	}
	else if (StrBeginsWith(varText, "CMFOrder") && StrLen(varText) == 9)
	{
		groupName = 'CMFMenuOrder';
		nameVar = CMFMenuVarNamed(groupName, "CMFOrderName" + StrRight(varText, 1));
	}
	else
	{
		return;
	}
	if (nameVar == '' || !theGame.CMFMenuGetState().Answer(varName, StringToInt(value), answer))
	{
		CMFLog("menu change var=" + varText + " position=" + value + " kept (row not built this session)");
		return;
	}
	// 1.0.1: one line per stored change, to trace stray picks seen after a visit at the title screen (Kyle
	// 2026-10-22 07:48Z).
	CMFLog("menu change var=" + varText + " position=" + value + " answer=" + answer);
	config = theGame.GetInGameConfigWrapper();
	config.SetVarValue(groupName, nameVar, answer);
	CMFChoicesChanged();
}

// Sets every choice, order and fall-through row back to its first position and clears the stored names. Nothing is
// pushed to the open Options screen: in menu launch 1 (2026-10-22) pushing the new positions made the game report the
// rows as changed again, so Reset ran 15 times and the old picks came back. The Reset row stays on "Reset now" until
// its page is next built (CMFMenuFillReset), and the other pages show the reset the next time Options opens.
function CMFMenuReset()
{
	var config : CInGameConfigWrapper;
	var groups : array<name>;
	var varName : name;
	var varText : string;
	var g, i, count : int;
	config = theGame.GetInGameConfigWrapper();
	groups = CMFMenuChoiceGroups();
	groups.PushBack('CMFMenuOrder');
	for (g = 0; g < groups.Size(); g += 1)
	{
		count = config.GetVarsNumByGroupName(groups[g]);
		for (i = 0; i < count; i += 1)
		{
			varName = config.GetVarNameByGroupName(groups[g], i);
			varText = NameToString(varName);
			if (StrBeginsWith(varText, "CMFName_") || StrBeginsWith(varText, "CMFOrderName"))
			{
				config.SetVarValue(groups[g], varName, "");
			}
			else if (StrBeginsWith(varText, "CMFPick_") || StrBeginsWith(varText, "CMFOrder"))
			{
				config.SetVarValue(groups[g], varName, "0");
			}
		}
	}
	config.SetVarValue('CMFMenuGeneral', 'CMFFallthrough', "0");
	CMFLog("menu reset");
	CMFChoicesChanged();
}

// The Reset row as its page is built: back on "Keep my choices" after a reset.
function CMFMenuFillReset(row : CScriptedFlashObject)
{
	var config : CInGameConfigWrapper;
	config = theGame.GetInGameConfigWrapper();
	if (config.GetVarValue('CMFMenuGeneral', 'CMFReset') != "0")
	{
		config.SetVarValue('CMFMenuGeneral', 'CMFReset', "0");
	}
	row.SetMemberFlashString("current", "0");
	row.SetMemberFlashString("startingValue", "0");
}

// Hands the rows to CMF each time it prepares winners. Reads settings only: asking CMF for its providers or winners
// here would prepare again from inside the preparation.
@wrapMethod(CMFCore) function ReadMenuChoices()
{
	var config : CInGameConfigWrapper;
	var groups : array<name>;
	var varName : name;
	var varText, value, order : string;
	var g, i, count : int;
	wrappedMethod();
	config = theGame.GetInGameConfigWrapper();
	groups = CMFMenuChoiceGroups();
	for (g = 0; g < groups.Size(); g += 1)
	{
		count = config.GetVarsNumByGroupName(groups[g]);
		for (i = 0; i < count; i += 1)
		{
			varName = config.GetVarNameByGroupName(groups[g], i);
			varText = NameToString(varName);
			if (StrBeginsWith(varText, "CMFName_"))
			{
				value = config.GetVarValue(groups[g], varName);
				if (value != "")
				{
					SetMenuChoice(StrAfterFirst(varText, "CMFName_"), value);
				}
			}
		}
	}
	order = "";
	count = config.GetVarsNumByGroupName('CMFMenuOrder');
	for (i = 0; i < count; i += 1)
	{
		varName = config.GetVarNameByGroupName('CMFMenuOrder', i);
		if (!StrBeginsWith(NameToString(varName), "CMFOrderName"))
		{
			continue;
		}
		value = StrReplaceAll(config.GetVarValue('CMFMenuOrder', varName), " ", "");
		if (value == "" || CMFListHas(StrLower(order), StrLower(value)))
		{
			continue;
		}
		if (order != "")
		{
			order += ",";
		}
		order += value;
	}
	SetMenuOrder(order);
	if (config.GetVarValue('CMFMenuGeneral', 'CMFFallthrough') == "1")
	{
		SetMenuFallthrough("vanilla");
	}
	else
	{
		SetMenuFallthrough("next");
	}
	SetMenuReport(config.GetVarValue('CMFMenuGeneral', 'CMFReport') == "1");
}
