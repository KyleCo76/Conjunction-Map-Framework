// CMF In-Game Menu (modCMFInGameMenu): the optional Options > Mods > Conjunction Map Framework entry for CMF 1.2.0
// and later (CMFGetVersion 8). 1.2.0 adds the World overview, Region crests and markers, and Opening view rows, which
// need CMF 1.3.0 (CMFGetVersion 9); on an older CMF the page leaves out every row whose choice key that CMF does not
// know, so the add-on works there as 1.1.1. 1.3.0 (CMF 1.4.0, CMFGetVersion 10) adds the Map behaviour row and page,
// the Zoom out, Controller crosshair and Fill wide screens rows, the Who wins: map behaviour page and the Screen line
// on Loaded map mods, and renames Pin size, Pan and zoom feel and Stacked pins spread out; on CMF 1.3.0 or older the
// new rows are left out the same way, the renamed rows show their 1.2.x names (CMFMenuOldLabel) and the Screen line
// is left out. 1.4.0 (still CMF 1.4.0 and later) shows a plain description of every CMF row in the Options list's help
// box, a choice row's "Offered by" line under it. The Screen line calls CMFScreenWidth and CMFScreenHeight, which only CMF 1.4.0 declares, so this
// script compiles only beside CMF 1.4.0 or later: the two ship together. Its menu file declares every row with spare
// placeholder choices; while the game builds a page, this script replaces them with the loaded map mods and remembers
// which folder name each position stands for. A chosen row keeps the folder name in a hidden name var beside it
// (CMFName_<key>, CMFOrderName<n>), so a choice survives mods being added or removed. CMF reads the rows each time it
// prepares winners (ReadMenuChoices).
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
	private var titleScreen : bool;
	private var resetPending : bool;
	private var boxHomeY : float;
	private var boxHomeKnown : bool;

	// 1.1.0: the help line of a choice row ("Offered by: ..."), made when its page is built. 1.4.0: the whole help box
	// text of any CMF row, its description first.
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

	// 1.4.0: where the game's own help box sat before CMF moved it, put back for the game's Bard's Ballad text.
	public function SetBoxHome(y : float)
	{
		if (!boxHomeKnown)
		{
			boxHomeY = y;
			boxHomeKnown = true;
		}
	}

	public function BoxHome(out y : float) : bool
	{
		y = boxHomeY;
		return boxHomeKnown;
	}

	// 1.1.1: whether the pages were last built from the remembered list (the title screen, no save loaded).
	public function SetTitleScreen(shown : bool)
	{
		titleScreen = shown;
	}

	public function TitleScreen() : bool
	{
		return titleScreen;
	}

	// 1.3.0: a Reset ran and the open Options screen still shows the old positions, until its pages are built again.
	public function SetResetPending(pending : bool)
	{
		resetPending = pending;
	}

	public function ResetPending() : bool
	{
		return resetPending;
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
	// 1.3.0: the behaviour pieces, the three moved ones (their keys keep the Size_ and Labels_ names) first.
	if (StrBeginsWith(key, "Behaviour_") || StrBeginsWith(key, "Labels_Place"))
	{
		return 'CMFMenuAdvBehaviour';
	}
	if (StrBeginsWith(key, "Size_Spread") || StrBeginsWith(key, "Size_Lead"))
	{
		return 'CMFMenuAdvBehaviour';
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
	groups.PushBack('CMFMenuAdvBehaviour');
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

// 1.3.0: the 1.2.x name of a row renamed in 1.3.0, shown on CMF 1.3.0 or older (CMFGetVersion 9 or less), where the
// row still means what it meant then; "" for a row that kept its name.
function CMFMenuOldLabel(key : string) : string
{
	if (CMFGetVersion() >= 10)
	{
		return "";
	}
	if (key == "Size")
	{
		return "Pin size and spreading";
	}
	if (key == "Size_Spread")
	{
		return "Spreading";
	}
	if (key == "Movement_Pan")
	{
		return "Pan and zoom";
	}
	return "";
}

// The feature names the Loaded map mods page lists, by feature index (CMFChoiceKeys 0 to 10; 1.3.0: 62 Behaviour).
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
		case 62:
			return "Behaviour";
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
	if (theGame.CMFMenuGetState().ResetPending() && StrBeginsWith(NameToString(groupName), "CMFMenu"))
	{
		CMFMenuReset("pages built");
		theGame.CMFMenuGetState().SetResetPending(false);
	}
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
	theGame.CMFMenuGetState().SetTitleScreen(remembered);
	rows = groupRootObject.GetMemberFlashArray("subElements");
	for (i = rows.GetLength() - 1; i >= 0; i -= 1)
	{
		row = rows.GetElementFlashObject(i);
		varName = config.GetVarNameByGroupName(groupName, StringToInt(row.GetMemberFlashString("id")));
		varText = NameToString(varName);
		// 1.4.0: every row but a choice row (CMFMenuFillPick) shows its description alone.
		if (!StrBeginsWith(varText, "CMFPick_") && CMFMenuDescription(varName) != "")
		{
			theGame.CMFMenuGetState().RememberHelp(varName, CMFMenuDescription(varName));
		}
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
			if (!CMFMenuFillPick(storage, row, groupName, varName, StrAfterFirst(varText, "CMFPick_"), providers,
				remembered))
			{
				rows.RemoveElement(i);
			}
		}
		else if (StrBeginsWith(varText, "CMFOrder"))
		{
			CMFMenuFillOrder(storage, row, varName, StrAfterFirst(varText, "CMFOrder"), providers, remembered);
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
			if (!CMFMenuFillWin(storage, row, StrAfterFirst(varText, "CMFWin_"), providers, remembered))
			{
				rows.RemoveElement(i);
			}
		}
		else if (varText == "CMFStatusScreen")
		{
			if (!CMFMenuFillScreen(storage, row, remembered))
			{
				rows.RemoveElement(i);
			}
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
// been opened). A leave-out slot of Hidden pins or Drawings reads Nobody / each mod that offers it. 1.2.0: false for a
// key the installed CMF does not know (a row newer than that CMF), which the page then leaves out.
function CMFMenuFillPick(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, groupName : name,
	varName : name, key : string, providers : array<string>, remembered : bool) : bool
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
		return false;
	}
	if (CMFMenuOldLabel(key) != "")
	{
		row.SetMemberFlashString("label", CMFMenuOldLabel(key));
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
	// 1.1.1: greyed at the title screen, where the list is last time's and a slipped click would store a pick
	// (reviews/2026-10-23-menu-title-screen-picks.md; Kyle's "Grey out", 2026-10-23 00:41Z).
	CMFMenuSetChoices(storage, row, labels, current, remembered || (!offeredAny && stored == ""));
	theGame.CMFMenuGetState().Remember(varName, CMFMenuJoin(answers));
	theGame.CMFMenuGetState().RememberHelp(varName, CMFMenuBoxText(varName, CMFMenuHelpText(choice, providers,
		remembered, seen)));
	if (config.GetVarValue(groupName, varName) != IntToString(current))
	{
		config.SetVarValue(groupName, varName, IntToString(current));
	}
	return true;
}

// A Mod order row: Automatic, then every map mod; greyed at the title screen (1.1.1).
function CMFMenuFillOrder(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, varName : name,
	position : string, providers : array<string>, remembered : bool)
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
	CMFMenuSetChoices(storage, row, labels, current, remembered);
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
	var feature, behaviour : int;
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
		// 1.3.0: Behaviour (62) last, when the installed CMF knows it.
		behaviour = core.ChoiceIndex("Behaviour");
		if (behaviour >= 0 && core.Offers(behaviour, providers[index]))
		{
			if (text != "")
			{
				text += ", ";
			}
			text += CMFMenuFeatureName(behaviour);
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

// One Who wins row: the winner and the level that decided it; hides and drawings say how many mods' apply. 1.2.0:
// false for a key the installed CMF does not know, which the page then leaves out.
function CMFMenuFillWin(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, key : string,
	providers : array<string>, remembered : bool) : bool
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
		return false;
	}
	if (CMFMenuOldLabel(key) != "")
	{
		row.SetMemberFlashString("label", CMFMenuOldLabel(key));
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
	return true;
}

// 1.3.0: the Screen line on Loaded map mods (ultrawide spec 6.5). The label holds the screen in map units from the
// last map opening (CMFScreenWidth and CMFScreenHeight, 0 before the first); the value says who decides Fill wide
// screens (Movement_Wide): CMF's own full-width layout when no mod sends wide keys, Vanilla (the game's centred 16:9
// map), or the winning mod. False on CMF 1.3.0 or older, which the page then leaves out.
function CMFMenuFillScreen(storage : CScriptedFlashValueStorage, row : CScriptedFlashObject, remembered : bool) : bool
{
	var core : CMFCore;
	var labels : array<string>;
	var width, height : float;
	var choice, level : int;
	var winner, text : string;
	if (CMFGetVersion() < 10)
	{
		return false;
	}
	core = theGame.CMFGetCore();
	choice = core.ChoiceIndex("Movement_Wide");
	if (choice < 0)
	{
		return false;
	}
	width = CMFScreenWidth();
	height = CMFScreenHeight();
	if (width < 1 || height < 1)
	{
		row.SetMemberFlashString("label", "Screen: open the map once");
	}
	else
	{
		row.SetMemberFlashString("label", "Screen: " + IntToString(RoundF(width)) + " x " + IntToString(RoundF(height)));
	}
	if (remembered)
	{
		text = "Load a save to see";
	}
	else
	{
		winner = core.WinnerOf(choice, 0, level);
		if (winner == "vanilla" || (winner == "" && CMFMenuWideVanilla()))
		{
			text = "16:9 map (Vanilla)";
		}
		else if (winner == "")
		{
			text = "Map fills it (CMF)";
		}
		else
		{
			text = CMFMenuFit("Map fills it (", core.ProviderName(winner), ")");
		}
	}
	labels.PushBack(text);
	CMFMenuSetChoices(storage, row, labels, 0, remembered || width < 1);
	return true;
}

// 1.3.0: true when Fill wide screens is decided as Vanilla. WinnerOf answers "" while no mod sends wide keys (it has
// no candidates), but CMF still turns its own full-width layout off then (rev 10 contract section 3), so the core's own
// deciding answer is asked.
function CMFMenuWideVanilla() : bool
{
	var core : CMFCore;
	core = theGame.CMFGetCore();
	return core.DecidedAnswer(core.ChoiceIndex("Movement_Wide")) == "vanilla";
}

// 1.4.0: a choice row's help box: its description, a line break, then its help line (Kyle's "Box", 2026-10-24 03:14Z).
function CMFMenuBoxText(varName : name, helpLine : string) : string
{
	if (CMFMenuDescription(varName) == "")
	{
		return helpLine;
	}
	return CMFMenuDescription(varName) + CMFMenuLineBreak() + helpLine;
}

// 1.4.0: the line break inside the help box text.
function CMFMenuLineBreak() : string
{
	return "<br>";
}

// BEGIN row descriptions: written by tools/cmf_menu_addon.py from source/menu/descriptions.json
// 1.4.0: the plain description of a row, shown first in the help box ("" for a row without one).
function CMFMenuDescription(varName : name) : string
{
	var varText : string;
	varText = NameToString(varName);
	if (StrBeginsWith(varText, "CMFStatusMod"))
	{
		return "A map mod CMF found, and which parts of the map it changes. Some show only after the map has been opened once.";
	}
	if (StrBeginsWith(varText, "CMFWin_"))
	{
		return "Which mod's version of this part of the map you see right now, and which setting decided it. Change it on the Basic or Advanced page.";
	}
	switch (varName)
	{
		case 'CMFOrder1':
			return "This mod's map changes come first wherever a choice is left on Automatic. Only CMF's own order; the game's load order is not touched.";
		case 'CMFOrder2':
		case 'CMFOrder3':
		case 'CMFOrder4':
		case 'CMFOrder5':
		case 'CMFOrder6':
		case 'CMFOrder7':
		case 'CMFOrder8':
			return "Next in line: this mod's map changes appear wherever every mod placed above it has nothing to show.";
		case 'CMFPick_Icons':
			return "Changes the pictures on the map's pins: quest markers, signposts, shops, monster nests and every other place.";
		case 'CMFPick_Colours':
			return "Tints the map's pins, so quest types, finished places or shops stand out from each other by colour.";
		case 'CMFPick_Size':
		case 'CMFPick_Size_Scale':
			return "Makes the map's pins bigger or smaller.";
		case 'CMFPick_Labels':
			return "Adds or changes the small text above pins, such as a quest's level, and its colour.";
		case 'CMFPick_Legend':
			return "Changes the list of pin types beside the map: which rows it has, what they are called, and its filter tabs.";
		case 'CMFPick_Hidden':
			return "Hides or greys out pins to keep the map tidy. Automatic keeps every mod's hiding, Vanilla shows every pin, a mod keeps only its own.";
		case 'CMFPick_Look':
			return "Restyles the screen around the map: frames, region title, the list beside the map, the pin info box, key hints and pin text.";
		case 'CMFPick_Painting':
			return "Replaces the painted map itself: the art of each region and of the zoomed-out world view.";
		case 'CMFPick_Drawings':
			return "Shows extra shapes drawn on the map, such as borders, frames or marked areas. Automatic shows every mod's, Vanilla none.";
		case 'CMFPick_Clicks':
		case 'CMFPick_Clicks_Pins':
			return "Makes using a pin do something, such as travelling to it or opening a list, with a button beside the pin.";
		case 'CMFPick_Movement':
			return "Changes how the map scrolls, zooms and opens, how much of the screen it fills and where it is centred when it opens.";
		case 'CMFPick_Behaviour':
			return "Changes how the map reacts under the cursor: stacked pins fan out, text and the info box step aside, names appear on hover.";
		case 'CMFPick_Icons_General':
			return "Changes the pictures on the pins for signposts, harbours, notice boards, your stash and Roach.";
		case 'CMFPick_Icons_Quests':
			return "Changes the pictures on the pins for quest pins, including the quest you follow and races.";
		case 'CMFPick_Icons_Places':
			return "Changes the pictures on the pins for places not yet cleared: monster nests, bandit camps, treasure, cave entrances.";
		case 'CMFPick_Icons_Completed':
			return "Changes the pictures on the pins for places you have already cleared, which the game shows greyed out.";
		case 'CMFPick_Icons_Services':
			return "Changes the pictures on the pins for merchants, smiths, armourers, innkeepers, barbers and other services.";
		case 'CMFPick_Icons_Power':
			return "Changes the pictures on the pins for places of power, grindstones, armour tables, alchemy tables and similar.";
		case 'CMFPick_Icons_Other':
			return "Changes the pictures on the pins for beds, herbs, stables, caves, enemies and your own map markers.";
		case 'CMFPick_Icons_Added':
			return "Changes the pictures on the pins for pins that mods add to the map, which the game itself does not have.";
		case 'CMFPick_Colours_General':
			return "Tints the pins for signposts, harbours, notice boards, your stash and Roach.";
		case 'CMFPick_Colours_Quests':
			return "Tints the pins for quest pins, including the quest you follow and races.";
		case 'CMFPick_Colours_Places':
			return "Tints the pins for places not yet cleared: monster nests, bandit camps, treasure, cave entrances.";
		case 'CMFPick_Colours_Completed':
			return "Tints the pins for places you have already cleared, which the game shows greyed out.";
		case 'CMFPick_Colours_Services':
			return "Tints the pins for merchants, smiths, armourers, innkeepers, barbers and other services.";
		case 'CMFPick_Colours_Power':
			return "Tints the pins for places of power, grindstones, armour tables, alchemy tables and similar.";
		case 'CMFPick_Colours_Other':
			return "Tints the pins for beds, herbs, stables, caves, enemies and your own map markers.";
		case 'CMFPick_Colours_Added':
			return "Tints the pins for pins that mods add to the map, which the game itself does not have.";
		case 'CMFPick_Labels_Text':
			return "Changes the words above pins, such as a quest's level tag, and their colour.";
		case 'CMFPick_Legend_Rows':
			return "Adds or removes rows in the list of pin types beside the map.";
		case 'CMFPick_Legend_Names':
			return "Renames the rows in the list of pin types beside the map.";
		case 'CMFPick_Legend_Tabs':
			return "Changes the filter tabs of the list beside the map: their names and which rows each tab shows.";
		case 'CMFPick_Hidden_Ignore1':
		case 'CMFPick_Hidden_Ignore2':
		case 'CMFPick_Hidden_Ignore3':
			return "Brings back the pins one mod hides or greys out, while every other mod's hiding stays. Nobody brings none back.";
		case 'CMFPick_Look_Frames':
			return "Restyles the frame around the map, the region title, the quest tracker, the corner overview and the world view button.";
		case 'CMFPick_Look_Legend':
			return "Restyles the list of pin types beside the map: its fonts, colours and backgrounds.";
		case 'CMFPick_Look_InfoBox':
			return "Restyles the box that describes a pin when you point at it: its fonts, colours and backing.";
		case 'CMFPick_Look_Hints':
			return "Restyles the row of key hints on the map and the key pictures in it.";
		case 'CMFPick_Look_PinText':
			return "Changes the font and shadow of text on pins, of names under signposts and of buttons beside pins.";
		case 'CMFPick_Movement_Area':
			return "Changes how much of the screen the map fills from top to bottom, and how far you can scroll it.";
		case 'CMFPick_Movement_Pan':
			return "Makes scrolling and zooming smoother or faster, with keys, mouse or stick.";
		case 'CMFPick_Movement_ZoomOut':
			return "Lets you zoom out until the whole region fits on screen, and scroll a little past its edge.";
		case 'CMFPick_Movement_Controller':
			return "Changes how the controller crosshair moves near the screen's edges and how it snaps to pins.";
		case 'CMFPick_Movement_Opening':
			return "Changes how the map slides and fades in and out, and how quickly its pins appear.";
		case 'CMFPick_Movement_View':
			return "Changes where the map is centred and how far it is zoomed each time you open it.";
		case 'CMFPick_Movement_Wide':
			return "On a screen wider or taller than 16:9, the map fills the whole screen instead of a centred 16:9 picture. Vanilla keeps it centred.";
		case 'CMFPick_Size_Spread':
			return "Pins sitting on the same spot fan out into a row as the cursor reaches them, so you can pick each one.";
		case 'CMFPick_Size_Lead':
			return "Decides which pin is picked first when stacked pins fan out, such as the quest pin.";
		case 'CMFPick_Labels_Place':
			return "Moves the text above pins higher or lower, and hides it on some pins or under the crosshair.";
		case 'CMFPick_Behaviour_InfoBoxDodge':
			return "A tall pin info box moves aside so it does not cover the cursor or the map's panels.";
		case 'CMFPick_Behaviour_InfoBoxHeight':
			return "Lets the pin info box grow taller before its text starts to scroll.";
		case 'CMFPick_Behaviour_HoverNames':
			return "Keeps the map quiet: a pin's name shows only while you point at it.";
		case 'CMFPick_Painting_WhiteOrchard':
			return "Replaces the painted map of White Orchard.";
		case 'CMFPick_Painting_WhiteOrchardWinter':
			return "Replaces the painted map of the winter White Orchard of the game's last chapter.";
		case 'CMFPick_Painting_Velen':
			return "Replaces the painted map of Velen and Novigrad.";
		case 'CMFPick_Painting_Skellige':
			return "Replaces the painted map of the Skellige Isles.";
		case 'CMFPick_Painting_KaerMorhen':
			return "Replaces the painted map of Kaer Morhen.";
		case 'CMFPick_Painting_Vizima':
			return "Replaces the painted map of Vizima.";
		case 'CMFPick_Painting_IsleOfMists':
			return "Replaces the painted map of the Isle of Mists.";
		case 'CMFPick_Painting_Spiral':
			return "Replaces the painted map of the Spiral.";
		case 'CMFPick_Painting_Toussaint':
			return "Replaces the painted map of Toussaint.";
		case 'CMFPick_Painting_World':
			return "Replaces the painting of the whole world shown when you zoom out to the world view.";
		case 'CMFPick_Painting_Crests':
			return "Replaces the region crests and the you-are-here and quest markers on the world view.";
		case 'CMFPick_Drawings_Ignore1':
		case 'CMFPick_Drawings_Ignore2':
		case 'CMFPick_Drawings_Ignore3':
			return "Removes one mod's shapes drawn on the map, while every other mod's drawings stay. Nobody removes none.";
		case 'CMFFallthrough':
			return "When the mod you picked has nothing for a pin, that pin shows the next mod's version, or the game's own look.";
		case 'CMFReset':
			return "Puts every choice in this menu back to its default, the mod order included. Reopen Options to see it.";
		case 'CMFReport':
			return "For bug reports: writes which mod decides each part of the map into the game's script log.";
		case 'CMFStatusScreen':
			return "Your screen size as the map last saw it, and whether the map fills it. Open the map once to see it.";
	}
	return "";
}
// END row descriptions

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
		return "Load a save to change this";
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
// hides the box again. 1.4.0: every CMF row with a description shows the box. Changing a row's label instead also renames the selected left-hand entry (night launch
// 2026-10-22), so the help line never goes into a row.
@wrapMethod(CR4IngameMenu) function OnOptionSelectionChanged(optionName : name, value : bool)
{
	var menuState : CMFMenuState;
	var text : string;
	menuState = theGame.CMFMenuGetState();
	if (StrBeginsWith(NameToString(optionName), "CMF") && menuState.Help(optionName, text) && text != "")
	{
		m_flashModule.GetMemberFlashFunction("updateBardsBalladText").InvokeSelfOneArg(FlashArgString(text));
		m_flashModule.GetMemberFlashFunction("showBardsBalladTooltip").InvokeSelfOneArg(FlashArgBool(true));
		menuState.SetBoxShown(true);
		CMFMenuPlaceBox(m_flashModule, true);
	}
	else if (menuState.BoxShown())
	{
		m_flashModule.GetMemberFlashFunction("updateBardsBalladText").InvokeSelfOneArg(FlashArgString(""));
		m_flashModule.GetMemberFlashFunction("showBardsBalladTooltip").InvokeSelfOneArg(FlashArgBool(false));
		menuState.SetBoxShown(false);
		CMFMenuPlaceBox(m_flashModule, false);
	}
	return wrappedMethod(optionName, value);
}

// 1.4.0: the game draws its help box (the option list module's "tooltip" clip) at a fixed place near the bottom,
// over the 12th row of a page (Kyle's 1.4.1 check, 2026-10-24). While a CMF row shows it, CMF moves it to sit just
// above the list's top edge (the list clip "mcOptionList"), its height taken after the text is set; hiding it puts it
// back where the game had it, for the game's own Bard's Ballad text. Nothing happens if either clip is missing.
function CMFMenuPlaceBox(menuFlash : CScriptedFlashSprite, shown : bool)
{
	var module, box, list : CScriptedFlashSprite;
	var field : CScriptedFlashObject;
	var home : float;
	if (!menuFlash)
	{
		return;
	}
	module = menuFlash.GetChildFlashSprite("mcOptionListModule");
	if (!module)
	{
		return;
	}
	box = module.GetChildFlashSprite("tooltip");
	list = module.GetChildFlashSprite("mcOptionList");
	if (!box || !list)
	{
		return;
	}
	if (shown)
	{
		theGame.CMFMenuGetState().SetBoxHome(box.GetY());
		// The game grows the box's frame to the text, but its text field keeps room for two lines, so a third line
		// (a description that wraps, then "Offered by") was cut off (1.4.0 check, 2026-10-24). The field grows too.
		field = box.GetMemberFlashObject("textField");
		if (field)
		{
			field.SetMemberFlashNumber("height", field.GetMemberFlashNumber("textHeight") + CMFMenuFieldSpare());
		}
		box.SetY(list.GetY() - box.GetMemberFlashNumber("height") - CMFMenuBoxGap());
	}
	else if (theGame.CMFMenuGetState().BoxHome(home))
	{
		box.SetY(home);
	}
}

// 1.4.0: room under the last line of the help box's text field (Flash keeps a small gutter around its text).
function CMFMenuFieldSpare() : float
{
	return 8.0;
}

// 1.4.0: the space between the help box and the list, in the menu's own units (1080 to the screen's height).
function CMFMenuBoxGap() : float
{
	return 12.0;
}

// 1.1.0: a newly shown Options page never keeps the box from the last one.
@wrapMethod(CR4IngameMenu) function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string) : void
{
	if (theGame.CMFMenuGetState().BoxShown())
	{
		m_flashModule.GetMemberFlashFunction("updateBardsBalladText").InvokeSelfOneArg(FlashArgString(""));
		m_flashModule.GetMemberFlashFunction("showBardsBalladTooltip").InvokeSelfOneArg(FlashArgBool(false));
		theGame.CMFMenuGetState().SetBoxShown(false);
		CMFMenuPlaceBox(m_flashModule, false);
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
			CMFMenuReset("row");
			theGame.CMFMenuGetState().SetResetPending(true);
		}
		return;
	}
	// 1.3.0: after a Reset the rows still on screen keep their old positions, and in start B (2026-10-24) the picks
	// and the "has nothing" row changed earlier on that screen came back. Until the pages are built again, a change
	// to a choice, order or "has nothing" row is put straight back to its reset value.
	if (theGame.CMFMenuGetState().ResetPending() && (varText == "CMFFallthrough" || StrBeginsWith(varText, "CMFPick_")
		|| (StrBeginsWith(varText, "CMFOrder") && StrLen(varText) == 9)))
	{
		CMFLog("menu change var=" + varText + " value=" + value + " undone (reset pending)");
		CMFMenuUndoChange(varName, varText);
		CMFChoicesChanged();
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
	// 1.1.1: backstop for a change the game still reports on a greyed title-screen row; the next page build puts
	// the row back to the stored pick.
	if (theGame.CMFMenuGetState().TitleScreen())
	{
		CMFLog("menu change var=" + varText + " position=" + value + " kept (title screen)");
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
// 1.3.0: the reset then stays pending until the pages are built again: changes from the old screen are put back
// (CMFMenuValueChanged), and closing the menu and building the pages each reset once more. why names the caller.
function CMFMenuReset(why : string)
{
	var config : CInGameConfigWrapper;
	var groups : array<name>;
	var varName : name;
	var varText : string;
	var g, i, count, names, rows : int;
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
				names += 1;
			}
			else if (StrBeginsWith(varText, "CMFPick_") || StrBeginsWith(varText, "CMFOrder"))
			{
				config.SetVarValue(groups[g], varName, "0");
				rows += 1;
			}
		}
	}
	config.SetVarValue('CMFMenuGeneral', 'CMFFallthrough', "0");
	CMFLog("menu reset (" + why + ") names=" + IntToString(names) + " rows=" + IntToString(rows));
	CMFChoicesChanged();
}

// 1.3.0: puts one choice, order or "has nothing" row back to its reset value while a reset is pending.
function CMFMenuUndoChange(varName : name, varText : string)
{
	var config : CInGameConfigWrapper;
	var groupName, nameVar : name;
	config = theGame.GetInGameConfigWrapper();
	if (varText == "CMFFallthrough")
	{
		config.SetVarValue('CMFMenuGeneral', 'CMFFallthrough', "0");
		return;
	}
	if (StrBeginsWith(varText, "CMFPick_"))
	{
		groupName = CMFMenuGroupOf(StrAfterFirst(varText, "CMFPick_"));
		nameVar = CMFMenuVarNamed(groupName, "CMFName_" + StrAfterFirst(varText, "CMFPick_"));
	}
	else
	{
		groupName = 'CMFMenuOrder';
		nameVar = CMFMenuVarNamed(groupName, "CMFOrderName" + StrRight(varText, 1));
	}
	if (groupName == '')
	{
		return;
	}
	config.SetVarValue(groupName, varName, "0");
	if (nameVar != '')
	{
		config.SetVarValue(groupName, nameVar, "");
	}
}

// 1.3.0: closing the menu with a reset pending resets once more after the game's own close, then saves, so nothing
// the closing screen hands back outlives the reset.
@wrapMethod(CR4IngameMenu) function OnClosingMenu()
{
	var result : bool;
	result = wrappedMethod();
	if (theGame.CMFMenuGetState().ResetPending())
	{
		CMFMenuReset("menu closed");
		theGame.CMFMenuGetState().SetResetPending(false);
		theGame.SaveUserSettings();
	}
	return result;
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
			// 1.2.0: a row newer than the installed CMF (its key unknown there) hands over nothing.
			if (StrBeginsWith(varText, "CMFName_"))
			{
				value = config.GetVarValue(groups[g], varName);
				if (value != "" && ChoiceIndex(StrAfterFirst(varText, "CMFName_")) >= 0)
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
