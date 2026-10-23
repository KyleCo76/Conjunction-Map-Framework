// Conjunction Map Framework core: provider registry, prepared winners and pin fields.
// Provider API version 6 (version 2: legend rows, filter tabs, per-pin styling; version 3: hiding pins;
// version 4: pin size, labels, the info box and hiding pins in filter tabs; version 5: the map theme,
// CMFStylePart, CMFDraw, CMFDrawSet and CMFHasAbility, and the pin label colour; version 6: pin clicks,
// their hint and button, the OnPinClicked hook and the pinButton theme part, spreading stacked pins: the
// spread theme part and the SpreadRank pin property, quest rows, keeping a tab's rows out of Default, and
// map-space drawing: the mapSpace anchor, the line, text and movie kinds, CMFDrawSetList, CMFMapRefresh,
// drawing tabs, clicks and the OnDrawingClicked and OnMapListening hooks; version 7: the tall info box;
// version 8: per-feature choices (which mod wins each feature and piece, Vanilla, the order of authority),
// tidy provider names and the menu add-on's hook and calls; version 9: world overview pictures (the painting, region
// crests and the player and quest markers), controller button pictures, choice-only claims, the player marker as a
// hide target, and the map's view: the OnMapView and OnMapOpening hooks, CMFSetOpeningView and
// CMFSetOpeningWorld).
// Never remove a call once published.

function CMFGetVersion() : int { return 9; }

function CMFPropertyIcon() : int { return 1; }
function CMFPropertyLegendIcon() : int { return 2; }
function CMFPropertyTint() : int { return 3; }
function CMFPropertyBackground() : int { return 4; }
function CMFPropertyDisabled() : int { return 5; }
// Version 2 legend properties: target is a filteredType (row, label) or a category id (category).
function CMFPropertyLegendRow() : int { return 6; }
function CMFPropertyLegendLabel() : int { return 7; }
function CMFPropertyLegendCategory() : int { return 8; }
// Version 3: hide claims. Every eligible hide claim applies (hide wins over every other property);
// number = hide (1) or withdraw (0), plus the exemption flags below.
function CMFPropertyHidden() : int { return 9; }
// Version 4: pin size in percent (10), label place in tenths of a pin unit (11), label text (12) and which
// labels to hide (13), for a type, a tag or one pin; the info box's text height in px (14, every pin only);
// the filter tabs that leave a pin out (15, a hide like 9: every claim applies).
function CMFPropertyPinScale() : int { return 10; }
function CMFPropertyLabelPlace() : int { return 11; }
function CMFPropertyLabelText() : int { return 12; }
function CMFPropertyLabelHide() : int { return 13; }
function CMFPropertyInfoBoxHeight() : int { return 14; }
function CMFPropertyTabHide() : int { return 15; }
// Version 5: the colour of a pin's label text (number = 0xRRGGBB), for a type, a tag or one pin.
function CMFPropertyLabelColor() : int { return 17; }
// Version 6: pin clicks, for a type, a tag or one pin. PinClick (16) text = the inputs ("use", "doubleClick",
// "button", separated by commas or spaces) and number = any nonzero value handed back with the click (0
// withdraws); one provider wins each pin. PinClickHint (20) and PinClickButton (21) text = the words shown in
// the button bar and on the button, number nonzero (0 withdraws); CMF shows them only from the provider that
// won the pin's click. Ids 18 and 19 are kept for tooltip slots.
function CMFPropertyPinClick() : int { return 16; }
function CMFPropertyPinClickHint() : int { return 20; }
function CMFPropertyPinClickButton() : int { return 21; }
// Version 6: which pin of a stack the spread selects first (number 0-1000, higher first; 0 = no preference),
// for a type, a tag or one pin. Spreading itself is the spread theme part (CMFStylePart).
function CMFPropertySpreadRank() : int { return 22; }
// Version 6: keep the rows of a CMF tab out of Default (target = the category id, number nonzero; 0 withdraws).
// Without it a CMF tab's rows also list in Default, as General's do.
function CMFPropertyCategoryNoDefault() : int { return 23; }
// Version 9: pictures for the world overview and the button bar, all type claims (level 1) whose text is the
// picture's url; text "" withdraws. WorldPainting (24) target 'painting' only, number 0 for one picture or
// columns * 10 + rows (each 1 to 8) for a tile url holding {x} and {y}; WorldCrest (25) target = a region's
// overview name (kaer_morhen, skellige, novigrad, no_mans_land, prolog_village, wyzima_castle, bob, or a region
// another mod adds); ButtonPicture (26) target = family_button (CMFButtonTarget, for example 'xbox_gamepad_Y'), the
// family one of xbox, ps4, ps5, steam or switch, sent to the map as family:button;
// WorldMarker (27) target 'player' or 'quest'.
function CMFPropertyWorldPainting() : int { return 24; }
function CMFPropertyWorldCrest() : int { return 25; }
function CMFPropertyButtonPicture() : int { return 26; }
function CMFPropertyWorldMarker() : int { return 27; }

// Exemption flags of a hide claim, as stored in its number.
function CMFExemptTracked() : int { return 2; }
function CMFExemptQuest() : int { return 4; }
function CMFExemptFastTravel() : int { return 8; }

// Labels a LabelHide claim hides, as stored in its number and in the pin's cmfLabelHide.
function CMFLabelHidePin() : int { return 1; }
function CMFLabelHideCrosshair() : int { return 2; }

function CMFHasFlag(number : int, flag : int) : bool
{
	return (number / flag) % 2 == 1;
}

// Parses "tracked", "quest" and "fasttravel", separated by commas or spaces, ignoring case, into
// exemption flags. False for any other word, so a typo never widens a hide.
function CMFParseExemptions(text : string, out flags : int) : bool
{
	var rest : string;
	var word : string;
	flags = 0;
	rest = StrLower(StrReplaceAll(text, ",", " ")) + " ";
	while (StrLen(rest) > 0)
	{
		word = StrBeforeFirst(rest, " ");
		rest = StrAfterFirst(rest, " ");
		if (word == "tracked")
		{
			if (!CMFHasFlag(flags, CMFExemptTracked()))
			{
				flags += CMFExemptTracked();
			}
		}
		else if (word == "quest")
		{
			if (!CMFHasFlag(flags, CMFExemptQuest()))
			{
				flags += CMFExemptQuest();
			}
		}
		else if (word == "fasttravel")
		{
			if (!CMFHasFlag(flags, CMFExemptFastTravel()))
			{
				flags += CMFExemptFastTravel();
			}
		}
		else if (word != "")
		{
			return false;
		}
	}
	return true;
}

function CMFExemptionText(number : int) : string
{
	var text : string;
	text = "";
	if (CMFHasFlag(number, CMFExemptTracked()))
	{
		text += "tracked,";
	}
	if (CMFHasFlag(number, CMFExemptQuest()))
	{
		text += "quest,";
	}
	if (CMFHasFlag(number, CMFExemptFastTravel()))
	{
		text += "fasttravel,";
	}
	if (text != "")
	{
		text = StrLeft(text, StrLen(text) - 1);
	}
	return text;
}

// Parses "pin" and "crosshair", separated by commas or spaces, ignoring case, into label flags. False
// for any other word or for none.
function CMFParseLabelHide(text : string, out flags : int) : bool
{
	var rest : string;
	var word : string;
	flags = 0;
	rest = StrLower(StrReplaceAll(text, ",", " ")) + " ";
	while (StrLen(rest) > 0)
	{
		word = StrBeforeFirst(rest, " ");
		rest = StrAfterFirst(rest, " ");
		if (word == "pin")
		{
			if (!CMFHasFlag(flags, CMFLabelHidePin()))
			{
				flags += CMFLabelHidePin();
			}
		}
		else if (word == "crosshair")
		{
			if (!CMFHasFlag(flags, CMFLabelHideCrosshair()))
			{
				flags += CMFLabelHideCrosshair();
			}
		}
		else if (word != "")
		{
			return false;
		}
	}
	return flags > 0;
}

function CMFLabelHideText(flags : int) : string
{
	if (flags == CMFLabelHidePin())
	{
		return "pin";
	}
	if (flags == CMFLabelHideCrosshair())
	{
		return "crosshair";
	}
	return "pin,crosshair";
}

// Version 6. Inputs a PinClick claim takes, as flags: use (E, Enter or gamepad A on the selected pin, and a
// touch tap on it except on user pins), doubleClick (a mouse double-click on the selected pin) and button
// (a button drawn beside the pin).
function CMFClickInputUse() : int { return 1; }
function CMFClickInputDoubleClick() : int { return 2; }
function CMFClickInputButton() : int { return 4; }

// Parses "use", "doubleClick" and "button", separated by commas or spaces, ignoring case, into input flags.
// False for any other word or for none, so a typo never claims an input.
function CMFParsePinClick(text : string, out flags : int) : bool
{
	var rest : string;
	var word : string;
	flags = 0;
	rest = StrLower(StrReplaceAll(text, ",", " ")) + " ";
	while (StrLen(rest) > 0)
	{
		word = StrBeforeFirst(rest, " ");
		rest = StrAfterFirst(rest, " ");
		if (word == "use")
		{
			if (!CMFHasFlag(flags, CMFClickInputUse()))
			{
				flags += CMFClickInputUse();
			}
		}
		else if (word == "doubleclick")
		{
			if (!CMFHasFlag(flags, CMFClickInputDoubleClick()))
			{
				flags += CMFClickInputDoubleClick();
			}
		}
		else if (word == "button")
		{
			if (!CMFHasFlag(flags, CMFClickInputButton()))
			{
				flags += CMFClickInputButton();
			}
		}
		else if (word != "")
		{
			return false;
		}
	}
	return flags > 0;
}

// The inputs as the pin's cmfClick field carries them: "use", "doubleClick" and "button" joined with commas.
function CMFPinClickText(flags : int) : string
{
	var text : string;
	text = "";
	if (CMFHasFlag(flags, CMFClickInputUse()))
	{
		text += "use,";
	}
	if (CMFHasFlag(flags, CMFClickInputDoubleClick()))
	{
		text += "doubleClick,";
	}
	if (CMFHasFlag(flags, CMFClickInputButton()))
	{
		text += "button,";
	}
	if (text != "")
	{
		text = StrLeft(text, StrLen(text) - 1);
	}
	return text;
}

// Joins filter tab names (the panel's CategoryData._name, compared exactly), separated by commas or
// spaces, into one comma list without repeats. False when there is none.
function CMFParseTabs(text : string, out tabs : string) : bool
{
	var rest : string;
	var word : string;
	tabs = "";
	rest = StrReplaceAll(text, ",", " ") + " ";
	while (StrLen(rest) > 0)
	{
		word = StrBeforeFirst(rest, " ");
		rest = StrAfterFirst(rest, " ");
		if (word != "" && !CMFListHas(tabs, word))
		{
			if (tabs != "")
			{
				tabs += ",";
			}
			tabs += word;
		}
	}
	return tabs != "";
}

function CMFListHas(list : string, word : string) : bool
{
	return StrFindFirst("," + list + ",", "," + word + ",") >= 0;
}

// True for the properties whose claims carry no text.
function CMFPropertyTextFree(propertyId : int) : bool
{
	return propertyId == CMFPropertyTint() || propertyId == CMFPropertyDisabled() ||
		propertyId == CMFPropertyLegendRow() || propertyId == CMFPropertyHidden() ||
		propertyId == CMFPropertyPinScale() || propertyId == CMFPropertyLabelPlace() ||
		propertyId == CMFPropertyInfoBoxHeight() || propertyId == CMFPropertyLabelColor() ||
		propertyId == CMFPropertyCategoryNoDefault() || propertyId == CMFPropertySpreadRank();
}

// Version 6: the click properties (16, 20, 21), which reach user pins and follow the click's winner.
function CMFIsClickProperty(propertyId : int) : bool
{
	return propertyId == CMFPropertyPinClick() || propertyId == CMFPropertyPinClickHint() ||
		propertyId == CMFPropertyPinClickButton();
}

// Version 9: the picture properties (24 to 27), whose claims the map panel receives in cmf.map.world.
function CMFIsPictureProperty(propertyId : int) : bool
{
	return propertyId >= CMFPropertyWorldPainting() && propertyId <= CMFPropertyWorldMarker();
}

// Version 9: true when a picture claim's target fits its property: 'painting' for the painting, any region name for
// a crest, family_button with a known family for a button picture (CMFButtonTarget), 'player' or 'quest' for a marker.
function CMFPictureTargetOk(propertyId : int, target : string) : bool
{
	var family : string;
	switch (propertyId)
	{
		case 24:
			return target == "painting";
		case 25:
			return target != "";
		case 26:
			if (StrFindFirst(target, "_") <= 0)
			{
				return false;
			}
			family = StrBeforeFirst(target, "_");
			return StrAfterFirst(target, "_") != "" && CMFListHas("xbox,ps4,ps5,steam,switch", family);
		case 27:
			return target == "player" || target == "quest";
	}
	return false;
}

// Version 9: a painting's number, 0 for one picture or columns * 10 + rows with each 1 to 8.
function CMFPaintingTilesOk(number : int) : bool
{
	return number == 0 || (number / 10 >= 1 && number / 10 <= 8 && number % 10 >= 1 && number % 10 <= 8);
}

// The pin field that records which provider styled this property of one pin (CMFStylePin), or "" when
// the property cannot be styled per pin.
function CMFOwnerField(propertyId : int) : string
{
	switch (propertyId)
	{
		case 1:
			return "cmfIconBy";
		case 3:
			return "cmfTintBy";
		case 9:
			return "cmfHiddenBy";
		case 10:
			return "cmfScaleBy";
		case 11:
			return "cmfPlaceBy";
		case 12:
			return "cmfLabelBy";
		case 13:
			return "cmfLabelHideBy";
		case 15:
			return "cmfTabHideBy";
		case 17:
			return "cmfLabelColorBy";
		case 22:
			return "cmfSpreadRankBy";
	}
	return "";
}

// Categories the vanilla legend defines. CMF category ids may not reuse them (compared ignoring case).
function CMFIsVanillaCategory(category : string, ignoreCase : bool) : bool
{
	var lowered : string;
	if (ignoreCase)
	{
		lowered = StrLower(category);
		return lowered == "all" || lowered == "default" || lowered == "general" || lowered == "quests" ||
			lowered == "exploration" || lowered == "npcs" || lowered == "buffs";
	}
	return category == "All" || category == "Default" || category == "General" || category == "Quests" ||
		category == "Exploration" || category == "NPCs" || category == "Buffs";
}

// Version 8: per-feature choices. CMF groups what mods send it into eleven features (the menu's Basic rows) and
// splits most of them into pieces (its Advanced rows), written Feature_Piece. The menu add-on's rows and the
// [CMFSettings] file values CMFFile_<key> use these keys. Hidden and Drawings are added together (every mod's
// applies), so their pieces are three slots that each leave one mod out. CMFCore keeps the order as indices:
// 0 to 10 are the features in this order, then the pieces. Version 9 appends Painting_World (59),
// Painting_Crests (60) and Movement_View (61); every older index stays.
function CMFChoiceKeys() : string
{
	return "Icons,Colours,Size,Labels,Clicks,Legend,Hidden,Look,Movement,Painting,Drawings," +
		"Icons_General,Icons_Quests,Icons_Places,Icons_Completed,Icons_Services,Icons_Power,Icons_Other,Icons_Added," +
		"Colours_General,Colours_Quests,Colours_Places,Colours_Completed,Colours_Services,Colours_Power,Colours_Other," +
		"Colours_Added,Size_Scale,Size_Lead,Size_Spread,Labels_Text,Labels_Place,Clicks_Pins,Legend_Rows,Legend_Names," +
		"Legend_Tabs,Hidden_Ignore1,Hidden_Ignore2,Hidden_Ignore3,Look_Frames,Look_Legend,Look_InfoBox,Look_Hints," +
		"Look_PinText,Movement_Area,Movement_Pan,Movement_Opening,Painting_WhiteOrchard,Painting_WhiteOrchardWinter," +
		"Painting_Velen,Painting_Skellige,Painting_KaerMorhen,Painting_Vizima,Painting_IsleOfMists,Painting_Spiral," +
		"Painting_Toussaint,Drawings_Ignore1,Drawings_Ignore2,Drawings_Ignore3,Painting_World,Painting_Crests," +
		"Movement_View";
}

// Version 8: the pin group of a pin type for the Advanced icon and colour rows, as an offset from Icons_General:
// 0 General, 1 Quests, 2 Places, 3 Completed places (the "...Disabled" types), 4 Shops and services, 5 Places of
// power and workbenches, 6 Other (types with no legend tab of their own), 7 Pins added by mods (a type the game's
// map does not use). The groups follow the map's legend tabs (docs/authors/pin-types.md); the level variants _1
// to _3 count as their base type.
function CMFPinGroup(pinType : string) : int
{
	var stem : string;
	stem = pinType;
	if (StrLen(stem) > 2 && (StrEndsWith(stem, "_1") || StrEndsWith(stem, "_2") || StrEndsWith(stem, "_3")))
	{
		stem = StrLeft(stem, StrLen(stem) - 2);
	}
	if (StrFindFirst(stem, "Quest") >= 0 || stem == "HorseRace" || stem == "BoatRace")
	{
		return 1;
	}
	if (CMFListHas(CMFPinGroupTypes(5), stem))
	{
		return 5;
	}
	if (StrEndsWith(stem, "Disabled"))
	{
		return 3;
	}
	if (CMFListHas(CMFPinGroupTypes(0), stem))
	{
		return 0;
	}
	if (CMFListHas(CMFPinGroupTypes(4), stem))
	{
		return 4;
	}
	if (CMFListHas(CMFPinGroupTypes(2), stem))
	{
		return 2;
	}
	if (CMFListHas(CMFPinGroupTypes(6), stem))
	{
		return 6;
	}
	return 7;
}

// The game's own types of one pin group (CMFPinGroup); quests and completed places go by name instead.
function CMFPinGroupTypes(group : int) : string
{
	switch (group)
	{
		case 0:
			return "RoadSign,Harbor,NoticeBoardFull,NoticeBoard,PlayerStash,PlayerStashDiscoverable,Horse,Transport";
		case 2:
			return "Entrance,NotDiscoveredPOI,MonsterNest,TreasureHuntMappin,SpoilsOfWar,BanditCamp,BanditCampfire," +
				"BossAndTreasure,Contraband,ContrabandShip,RescuingTown,DungeonCrawl,Hideout,InfestedVineyard,Plegmund," +
				"WineContract,KnightErrant,SignalingStake,Boat";
		case 4:
			return "Shopkeeper,Archmaster,Blacksmith,Armorer,Alchemic,Herbalist,Innkeeper,Enchanter,Prostitute,Hairdresser," +
				"Torch,WineMerchant,DyeMerchant,Cammerlengo";
		case 5:
			return "PlaceOfPower,PlaceOfPowerDisabled,PlaceOfPowerStrong,Whetstone,GrindStone,ArmorRepairTable,AlchemyTable," +
				"MutagenDismantle,Bookshelf";
		case 6:
			return "Bed,BoatBuilder,Camp,Cave,Companion,Container,DwarvenFurnace,Enemy,EnemyDead,FistFight,GenericFocus,Herb," +
				"HiverNest,HorseRaceDummy,HorseRaceTarget,HorseRacingNPC,LettenStories,MagicLamp,MonsterClue,MonsterHunt," +
				"NettelStories,Player,racetrack,Rift,Stables,Teleport,User1,User2,User3,User4,User5,User6,User7,WitcherHouse";
	}
	return "";
}

// Version 8: the Advanced painting row (CMFChoiceKeys index) of a map area, as the "CMF background area=" log
// line names it, or -1 for an area with no row of its own (the Basic painting row still covers it).
function CMFPaintingChoice(area : string) : int
{
	var lowered : string;
	lowered = StrLower(area);
	if (StrFindFirst(lowered, "prolog") >= 0)
	{
		if (StrFindFirst(lowered, "winter") >= 0)
		{
			return 48;
		}
		return 47;
	}
	if (StrFindFirst(lowered, "novigrad") >= 0 || StrFindFirst(lowered, "velen") >= 0)
	{
		return 49;
	}
	if (StrFindFirst(lowered, "skellige") >= 0)
	{
		return 50;
	}
	if (StrFindFirst(lowered, "kaer") >= 0)
	{
		return 51;
	}
	if (StrFindFirst(lowered, "wyzima") >= 0 || StrFindFirst(lowered, "vizima") >= 0)
	{
		return 52;
	}
	if (StrFindFirst(lowered, "island") >= 0 || StrFindFirst(lowered, "myst") >= 0)
	{
		return 53;
	}
	if (StrFindFirst(lowered, "spiral") >= 0)
	{
		return 54;
	}
	if (StrFindFirst(lowered, "bob") >= 0)
	{
		return 55;
	}
	return -1;
}

// Version 8: a provider's name for the menu when it set none (CMFSetProviderName): the folder name without its
// "mod" prefix, then without CMF's own "CMFAdapter" or "CMF" prefix (an adapter reads as the mod it adapts), and
// without leading digits and underscores; underscores as spaces, words split where a small letter meets a capital,
// each word starting with a capital ("modExampleIconPack" reads "Example Icon Pack", "modCMFAdapterSomeMod" reads
// "Some Mod", "modsome_map_mod" reads "Some Map Mod").
function CMFTidyName(provider : string) : string
{
	var rest, result, letter, previous : string;
	var i, size : int;
	rest = provider;
	if (StrBeginsWith(StrLower(rest), "mod"))
	{
		rest = StrRight(rest, StrLen(rest) - 3);
	}
	if (StrBeginsWith(StrLower(rest), "cmfadapter") && StrLen(rest) > 10)
	{
		rest = StrRight(rest, StrLen(rest) - 10);
	}
	else if (StrBeginsWith(StrLower(rest), "cmf") && StrLen(rest) > 3)
	{
		rest = StrRight(rest, StrLen(rest) - 3);
	}
	while (StrLen(rest) > 0 && StrFindFirst("0123456789_", StrLeft(rest, 1)) >= 0)
	{
		rest = StrRight(rest, StrLen(rest) - 1);
	}
	if (rest == "")
	{
		return provider;
	}
	result = "";
	previous = "";
	size = StrLen(rest);
	for (i = 0; i < size; i += 1)
	{
		letter = StrRight(StrLeft(rest, i + 1), 1);
		if (letter == "_")
		{
			letter = " ";
		}
		else if (previous == "" || previous == " ")
		{
			letter = StrUpper(letter);
		}
		else if (StrUpper(letter) == letter && StrLower(letter) != letter &&
			StrLower(previous) == previous && StrUpper(previous) != previous)
		{
			result += " ";
		}
		result += letter;
		previous = letter;
	}
	return result;
}

// Target levels: 0 every pin (hide claims only), 1 one pin type, 2 one pin instance (tag).
// Background claims are level 1 with pinType holding the map area name (m_shownArea).
// Disabled claims carry a map context ('FastTravel', 'Boat', 'GlobalMap'; None means every context).
struct SCMFClaim
{
	var provider : string;
	var propertyId : int;
	var level : int;
	var pinType : name;
	var pinTag : name;
	var mapContext : name;
	var text : string;
	var number : int;
	var order : int;
}

// Version 9: one provider's opening view for one map area ('' = every area), as CMFSetOpeningView or
// CMFSetOpeningWorld stored it (worldPlace: x and y are world coordinates).
struct SCMFOpeningView
{
	var provider : string;
	var area : name;
	var x : float;
	var y : float;
	var zoom : float;
	var keepPlace : bool;
	var worldPlace : bool;
}

class CMFCore extends CObject
{
	private var claims : array<SCMFClaim>;
	private var winners : array<SCMFClaim>;
	private var nextOrder : int;
	private var dirty : bool;
	private var revision : int;
	private var seenPins : array<string>;
	private var failedArt : array<string>;
	private var categories : array<SCMFClaim>;
	private var hideClaims : array<SCMFClaim>;
	private var tabHideClaims : array<SCMFClaim>;
	private var listOpen : bool;
	private var themeEntries : array<SCMFThemeEntry>;
	private var themeNotes : array<string>;
	private var providerOrder : string;
	private var clickNotes : array<string>;
	private var spaceMenu : CR4MapMenu;
	private var spaceArea : name;
	private var catchArray : CScriptedFlashArray;
	private var catching : bool;
	// Version 8: per-feature choices, indexed as CMFChoiceKeys. menuChoices come from the menu add-on
	// (ReadMenuChoices), fileChoices from [CMFSettings] CMFFile_<key>; "" is Automatic. Both are read, and each
	// choice's deciding answer worked out, each time winners are prepared.
	private var choiceKeys : array<string>;
	private var choiceFeature : array<int>;
	private var menuChoices : array<string>;
	private var fileChoices : array<string>;
	private var menuOrder : string;
	private var menuPresent : bool;
	private var menuFall : string;
	private var menuReport : bool;
	private var fallVanilla : bool;
	private var choicesActive : bool;
	private var decideAnswer : array<string>;
	private var decideLevel : array<int>;
	private var offerProviders : array<string>;
	private var hiddenAsked : string;
	private var hiddenOffered : bool;
	private var offerFlags : array<bool>;
	private var styledOffers : array<string>;
	private var lastStyledOffer : string;
	private var nameProviders : array<string>;
	private var nameTexts : array<string>;
	private var groupCacheType : string;
	private var groupCacheValue : int;
	private var mapSeen : bool;
	// Version 9: choice-only registrations (CMFRegisterChoiceOnly) as a provider and a choice index each, the providers
	// of the claims they left out at the last preparation (one entry per claim), and the opening views.
	private var choiceOnlyProviders : array<string>;
	private var choiceOnlyChoices : array<int>;
	private var choiceOnlySkipped : array<string>;
	private var openingViews : array<SCMFOpeningView>;

	public function RequestRefresh()
	{
		dirty = true;
		CMFLog("refresh requested claims=" + claims.Size());
	}

	public function Upsert(claim : SCMFClaim) : bool
	{
		var incoming : SCMFClaim;
		var i : int;
		var flags : int;
		var tabs : string;
		incoming = claim;
		if ((incoming.propertyId == CMFPropertyLegendCategory() || incoming.propertyId == CMFPropertyCategoryNoDefault()) &&
			CMFIsVanillaCategory(NameToString(incoming.pinType), true))
		{
			CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=vanilla");
			return false;
		}
		if (incoming.propertyId == CMFPropertyHidden())
		{
			if (!CMFParseExemptions(incoming.text, flags))
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=exemption");
				return false;
			}
			// The flags already sit above bit 0 (tracked 2, quest 4, fasttravel 8).
			incoming.text = CMFExemptionText(flags);
			incoming.number = 0;
			if (claim.number != 0)
			{
				incoming.number = 1 + flags;
			}
		}
		if (incoming.propertyId == CMFPropertyLabelHide())
		{
			if (!CMFParseLabelHide(incoming.text, flags))
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=text");
				return false;
			}
			incoming.text = CMFLabelHideText(flags);
			incoming.number = 0;
			if (claim.number != 0)
			{
				incoming.number = flags;
			}
		}
		if (incoming.propertyId == CMFPropertyTabHide())
		{
			if (!CMFParseTabs(incoming.text, tabs))
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=text");
				return false;
			}
			incoming.text = tabs;
			incoming.number = 0;
			if (claim.number != 0)
			{
				incoming.number = 1;
			}
		}
		// Version 6: a click claim's inputs, checked like label hide words.
		if (incoming.propertyId == CMFPropertyPinClick())
		{
			if (!CMFParsePinClick(incoming.text, flags))
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=text");
				return false;
			}
			incoming.text = CMFPinClickText(flags);
		}
		if (incoming.propertyId == CMFPropertyInfoBoxHeight() && incoming.level != 0)
		{
			CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=level");
			return false;
		}
		if ((incoming.propertyId == CMFPropertyPinScale() && (incoming.number < 25 || incoming.number > 400)) ||
			(incoming.propertyId == CMFPropertyLabelPlace() && (incoming.number < 0 || incoming.number > 10000)) ||
			(incoming.propertyId == CMFPropertyLabelColor() && (incoming.number < 0 || incoming.number > 16777215)) ||
			(incoming.propertyId == CMFPropertySpreadRank() && (incoming.number < 0 || incoming.number > 1000)) ||
			(incoming.propertyId == CMFPropertyInfoBoxHeight() && incoming.number != 0 &&
			(incoming.number < 100 || incoming.number > 1080)))
		{
			CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=range");
			return false;
		}
		// Version 9: a picture claim's target and tile count; text "" withdraws the provider's claim for that slot.
		if (CMFIsPictureProperty(incoming.propertyId))
		{
			if (incoming.level != 1 || !CMFPictureTargetOk(incoming.propertyId, NameToString(incoming.pinType)))
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=target");
				return false;
			}
			if (incoming.text == "")
			{
				for (i = claims.Size() - 1; i >= 0; i -= 1)
				{
					if (claims[i].provider == incoming.provider && SameSlot(claims[i], incoming))
					{
						claims.Erase(i);
						dirty = true;
						Report("picture withdrawn", incoming);
					}
				}
				return true;
			}
			if ((incoming.propertyId == CMFPropertyWorldPainting() && !CMFPaintingTilesOk(incoming.number)) ||
				(incoming.propertyId != CMFPropertyWorldPainting() && incoming.number != 0))
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=range");
				return false;
			}
		}
		// An empty legend row category means All only; a hide claim needs no text.
		if (incoming.provider == "" || (!CMFPropertyTextFree(incoming.propertyId) && incoming.text == "") ||
			(incoming.level == 1 && !IsNameValid(incoming.pinType)) || (incoming.level == 2 && !IsNameValid(incoming.pinTag)))
		{
			CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=empty");
			return false;
		}
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].provider == incoming.provider && SameSlot(claims[i], incoming))
			{
				incoming.order = claims[i].order;
				claims[i] = incoming;
				dirty = true;
				if ((incoming.propertyId == CMFPropertyHidden() || incoming.propertyId == CMFPropertyTabHide()) &&
					incoming.number == 0)
				{
					Report("hide withdrawn", incoming);
				}
				return true;
			}
		}
		nextOrder += 1;
		incoming.order = nextOrder;
		claims.PushBack(incoming);
		dirty = true;
		return true;
	}

	public function ReleaseProvider(provider : string)
	{
		var i, released : int;
		released = 0;
		for (i = claims.Size() - 1; i >= 0; i -= 1)
		{
			if (claims[i].provider == provider)
			{
				claims.Erase(i);
				released += 1;
				dirty = true;
			}
		}
		for (i = themeEntries.Size() - 1; i >= 0; i -= 1)
		{
			if (themeEntries[i].provider == provider)
			{
				themeEntries.Erase(i);
				released += 1;
			}
		}
		// Version 9: its opening views and choice-only registrations go too.
		for (i = openingViews.Size() - 1; i >= 0; i -= 1)
		{
			if (openingViews[i].provider == provider)
			{
				openingViews.Erase(i);
				released += 1;
				dirty = true;
			}
		}
		for (i = choiceOnlyProviders.Size() - 1; i >= 0; i -= 1)
		{
			if (choiceOnlyProviders[i] == provider)
			{
				choiceOnlyProviders.Erase(i);
				choiceOnlyChoices.Erase(i);
				dirty = true;
			}
		}
		CMFLog("released provider=" + provider + " claims=" + released);
	}

	// Version 5. Stores one theme themeEntry (part style, drawing or drawing key). A provider calling again with the
	// same part and key, the same drawing id, or the same drawing id and key replaces its own earlier value.
	// CMFDraw with kind '' withdraws the provider's drawing and its keys.
	public function UpsertTheme(themeEntry : SCMFThemeEntry) : bool
	{
		var i : int;
		if (themeEntry.kind == 2 && !IsNameValid(themeEntry.key))
		{
			for (i = themeEntries.Size() - 1; i >= 0; i -= 1)
			{
				if (themeEntries[i].provider == themeEntry.provider && themeEntries[i].kind != 1 && themeEntries[i].target == themeEntry.target)
				{
					themeEntries.Erase(i);
				}
			}
			CMFLog("theme drawing withdrawn provider=" + themeEntry.provider + " id=" + NameToString(themeEntry.target));
			return true;
		}
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].provider == themeEntry.provider && themeEntries[i].kind == themeEntry.kind &&
				themeEntries[i].target == themeEntry.target && (themeEntry.kind == 2 || themeEntries[i].key == themeEntry.key))
			{
				// Map-space drawing: an empty list (CMFDrawSetList) withdraws the provider's list key.
				if (themeEntry.kind == 4 && themeEntry.values.Size() == 0)
				{
					themeEntries.Erase(i);
					return true;
				}
				themeEntry.order = themeEntries[i].order;
				themeEntries[i] = themeEntry;
				return true;
			}
		}
		if (themeEntry.kind == 4 && themeEntry.values.Size() == 0)
		{
			return true;
		}
		nextOrder += 1;
		themeEntry.order = nextOrder;
		themeEntries.PushBack(themeEntry);
		return true;
	}

	// Smooth map movement (P6). Withdraws one provider's own value for one part and key (CMFStylePart with
	// the text "unset"), so the next folder's value, or the game's, applies from the next map opening.
	public function UnsetTheme(provider : string, part : name, key : name) : int
	{
		var i : int;
		var removed : int;
		removed = 0;
		for (i = themeEntries.Size() - 1; i >= 0; i -= 1)
		{
			if (themeEntries[i].provider == provider && themeEntries[i].kind == 1 && themeEntries[i].target == part &&
				themeEntries[i].key == key)
			{
				themeEntries.Erase(i);
				removed += 1;
			}
		}
		return removed;
	}

	// The provider that owns a part's style keys (the earliest folder that styled the part), or for the
	// behaviour parts map, navigation, opening and spread the owner of that one key.
	// Version 8: through the part's choice (PartChoice): Vanilla gives no owner, a chosen mod that styled the part
	// owns it, and otherwise the next level decides (none when the General row says Vanilla). Version 9: a provider
	// that made the part's choice choice-only (CMFRegisterChoiceOnly) owns it only when picked.
	private function ThemeStyleOwner(part : name, key : name) : string
	{
		var i, choice : int;
		var owner, answer : string;
		var perKey : bool;
		perKey = part == 'map' || part == 'navigation' || part == 'opening' || part == 'spread';
		owner = "";
		choice = -1;
		answer = "";
		if (choicesActive)
		{
			choice = PartChoice(part);
			if (choice >= 0)
			{
				answer = decideAnswer[choice];
			}
			if (answer == "vanilla")
			{
				return "";
			}
			if (answer == "@order")
			{
				answer = "";
			}
		}
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 && themeEntries[i].target == part && (!perKey || themeEntries[i].key == key) &&
				!ChoiceOnlySkips(PartChoice(part), themeEntries[i].provider))
			{
				if (answer != "" && themeEntries[i].provider == answer)
				{
					return answer;
				}
				if (owner == "" || PieceBeats(choice, themeEntries[i].provider, owner))
				{
					owner = themeEntries[i].provider;
				}
			}
		}
		if (answer != "" && fallVanilla)
		{
			return "";
		}
		return owner;
	}

	// The provider that owns a drawing id: the earliest folder that made it with CMFDraw, or "". Version 8: a
	// provider the Drawings choice leaves out owns nothing.
	private function ThemeDrawingOwner(id : name) : string
	{
		var i : int;
		var owner : string;
		owner = "";
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].target == id && AdditiveAllows(10, themeEntries[i].provider) &&
				(owner == "" || CMFProviderBeats(themeEntries[i].provider, owner)))
			{
				owner = themeEntries[i].provider;
			}
		}
		return owner;
	}

	// Map-space drawing: the kind of the drawing this provider made with this id ('' before CMFDraw).
	public function DrawingKind(provider : string, id : name) : name
	{
		var i : int;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].provider == provider && themeEntries[i].target == id)
			{
				return themeEntries[i].key;
			}
		}
		return '';
	}

	// Map-space drawing: true when the drawing's owner tied it to the mapSpace anchor. Such a drawing and its
	// keys and lists go to the map per build (SendSpace), not in the theme.
	private function IsSpaceDrawing(id : name) : bool
	{
		var i : int;
		var owner : string;
		owner = ThemeDrawingOwner(id);
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].provider == owner && themeEntries[i].target == id)
			{
				return themeEntries[i].anchor == 'mapSpace';
			}
		}
		return false;
	}

	// Map-space drawing: true when the owner's "area" key is unset, empty or names the shown area.
	private function SpaceAreaMatches(id : name, owner : string, area : name) : bool
	{
		var i : int;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 3 && themeEntries[i].provider == owner && themeEntries[i].target == id &&
				themeEntries[i].key == 'area')
			{
				return themeEntries[i].text == "" || themeEntries[i].text == NameToString(area);
			}
		}
		return true;
	}

	// Logs one theme line once per session (capped), so a loop of calls never floods the log.
	private function NoteTheme(line : string)
	{
		if (themeNotes.Size() < 64 && !themeNotes.Contains(line))
		{
			themeNotes.PushBack(line);
			CMFLog(line);
		}
	}

	// Position of a provider in folder order among the theme's providers (0 = earliest folder).
	private function ThemeFolderRank(provider : string) : int
	{
		var i, rank : int;
		var counted : array<string>;
		rank = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].provider != provider && !counted.Contains(themeEntries[i].provider) &&
				CMFProviderBeats(themeEntries[i].provider, provider))
			{
				counted.PushBack(themeEntries[i].provider);
				rank += 1;
			}
		}
		return rank;
	}

	// Sends the winning theme entries to the map once per opening, under "cmf.map.theme": one object per themeEntry
	// with k (1 style, 2 drawing, 3 drawing key), t (part or drawing id), a (anchor), y (key or kind),
	// s (text), n (number), p (folder rank of the provider) and o (registration order). Entries that lose
	// (another folder owns the part, key or drawing id) are left out and named once in the log.
	public function SendTheme(storage : CScriptedFlashValueStorage)
	{
		var flashArray : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var owner : string;
		var i, sent, ownMotion : int;
		if (!storage)
		{
			return;
		}
		flashArray = storage.CreateTempFlashArray();
		sent = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 4 || (themeEntries[i].kind != 1 && IsSpaceDrawing(themeEntries[i].target)))
			{
				continue;
			}
			if (themeEntries[i].kind == 1)
			{
				owner = ThemeStyleOwner(themeEntries[i].target, themeEntries[i].key);
				if (owner != themeEntries[i].provider)
				{
					NoteTheme("theme style shadowed provider=" + themeEntries[i].provider + " part=" +
						NameToString(themeEntries[i].target) + " by=" + owner);
					continue;
				}
			}
			else
			{
				if (!AdditiveAllows(10, themeEntries[i].provider))
				{
					NoteTheme("theme drawing left out provider=" + themeEntries[i].provider + " id=" +
						NameToString(themeEntries[i].target) + " reason=choice");
					continue;
				}
				owner = ThemeDrawingOwner(themeEntries[i].target);
				if (owner == "")
				{
					NoteTheme("theme key without drawing provider=" + themeEntries[i].provider + " id=" +
						NameToString(themeEntries[i].target));
					continue;
				}
				if (owner != themeEntries[i].provider)
				{
					NoteTheme("theme drawing refused provider=" + themeEntries[i].provider + " id=" +
						NameToString(themeEntries[i].target) + " owner=" + owner);
					continue;
				}
			}
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", themeEntries[i].kind);
			item.SetMemberFlashString("t", NameToString(themeEntries[i].target));
			item.SetMemberFlashString("a", NameToString(themeEntries[i].anchor));
			item.SetMemberFlashString("y", NameToString(themeEntries[i].key));
			item.SetMemberFlashString("s", themeEntries[i].text);
			item.SetMemberFlashNumber("n", themeEntries[i].number);
			item.SetMemberFlashInt("p", ThemeFolderRank(themeEntries[i].provider));
			item.SetMemberFlashInt("o", themeEntries[i].order);
			flashArray.PushBackFlashObject(item);
			sent += 1;
		}
		ownMotion = SendDefaultMotion(storage, flashArray);
		storage.SetFlashArray("cmf.map.theme", flashArray);
		NoteTheme("theme sent entries=" + sent + " of=" + themeEntries.Size() + " cmfMotion=" + ownMotion);
		SendWorld(storage);
	}

	// Version 9: sends the winning picture claims (24 to 27, through the choices as Find) under "cmf.map.world",
	// right after the theme: one object per winning claim with t ("painting", "crest", "marker" or "button"), y (the
	// target), s (the url), c and r (tile columns and rows, 1 and 1 for one picture) and p (the provider). An empty
	// array is sent when nothing wins, so a refresh clears old pictures.
	private function SendWorld(storage : CScriptedFlashValueStorage)
	{
		var flashArray : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var claim : SCMFClaim;
		var kind : string;
		var i, columns, rows, painting, crests, markers, buttons : int;
		if (dirty)
		{
			Prepare();
		}
		flashArray = storage.CreateTempFlashArray();
		painting = 0;
		crests = 0;
		markers = 0;
		buttons = 0;
		for (i = 0; i < winners.Size(); i += 1)
		{
			if (!CMFIsPictureProperty(winners[i].propertyId) ||
				!Find(winners[i].propertyId, NameToString(winners[i].pinType), '', 1, claim) ||
				claim.provider != winners[i].provider)
			{
				continue;
			}
			columns = 1;
			rows = 1;
			if (claim.propertyId == CMFPropertyWorldPainting())
			{
				kind = "painting";
				painting = 1;
				if (claim.number > 0)
				{
					columns = claim.number / 10;
					rows = claim.number % 10;
				}
			}
			else if (claim.propertyId == CMFPropertyWorldCrest())
			{
				kind = "crest";
				crests += 1;
			}
			else if (claim.propertyId == CMFPropertyButtonPicture())
			{
				kind = "button";
				buttons += 1;
			}
			else
			{
				kind = "marker";
				markers += 1;
			}
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("t", kind);
			if (kind == "button")
			{
				item.SetMemberFlashString("y", CMFButtonPanelKey(NameToString(claim.pinType)));
			}
			else
			{
				item.SetMemberFlashString("y", NameToString(claim.pinType));
			}
			item.SetMemberFlashString("s", claim.text);
			item.SetMemberFlashInt("c", columns);
			item.SetMemberFlashInt("r", rows);
			item.SetMemberFlashString("p", claim.provider);
			flashArray.PushBackFlashObject(item);
		}
		storage.SetFlashArray("cmf.map.world", flashArray);
		CMFLog("world sent painting=" + painting + " crests=" + crests + " markers=" + markers + " buttons=" + buttons);
	}

	// CMF's own movement (1.0.0): the map runs at 60 frames a second and moves by the time since the last
	// frame, so held keys, zoom, snaps and fades keep the game's speed and only get smoother. Each key goes to
	// the map only when no folder set it, so any mod's own value (the game's 24, for one) still wins.
	private function SendDefaultMotion(storage : CScriptedFlashValueStorage, flashArray : CScriptedFlashArray) : int
	{
		var keys : array<name>;
		var item : CScriptedFlashObject;
		var i, sent : int;
		keys.PushBack('frameRate');
		keys.PushBack('frameTimed');
		keys.PushBack('zoomTimed');
		keys.PushBack('tweenEveryFrame');
		sent = 0;
		for (i = 0; i < keys.Size(); i += 1)
		{
			if (ThemeStyleOwner('navigation', keys[i]) != "")
			{
				continue;
			}
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", 1);
			item.SetMemberFlashString("t", "navigation");
			item.SetMemberFlashString("a", "");
			item.SetMemberFlashString("y", NameToString(keys[i]));
			item.SetMemberFlashString("s", "");
			item.SetMemberFlashNumber("n", CMFDefaultNavigationValue(keys[i]));
			item.SetMemberFlashInt("p", -1);
			item.SetMemberFlashInt("o", 0);
			flashArray.PushBackFlashObject(item);
			NoteTheme("theme default part=navigation key=" + NameToString(keys[i]) + " value=" +
				FloatToString(CMFDefaultNavigationValue(keys[i])));
			sent += 1;
		}
		return sent;
	}

	// Map-space drawing. Sends the mapSpace drawings for the shown area under "cmf.map.space" on every full map
	// build (after OnMapReady), and again on CMFMapRefresh: a first object k 0 with the area name in s, then
	// the theme's objects (k 2 drawing, k 3 key) for each winning drawing whose "area" matches, and k 4 for a
	// list key, its count in c and its values in v0, v1, ... The map redraws every map-space drawing from this.
	public function SendSpace(storage : CScriptedFlashValueStorage, area : name, menu : CR4MapMenu)
	{
		var flashArray : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var owner : string;
		var i, k, sent, values : int;
		spaceMenu = menu;
		spaceArea = area;
		if (!storage)
		{
			return;
		}
		flashArray = storage.CreateTempFlashArray();
		item = storage.CreateTempFlashObject();
		item.SetMemberFlashInt("k", 0);
		item.SetMemberFlashString("s", NameToString(area));
		flashArray.PushBackFlashObject(item);
		sent = 0;
		values = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 || !IsSpaceDrawing(themeEntries[i].target))
			{
				continue;
			}
			if (!AdditiveAllows(10, themeEntries[i].provider))
			{
				NoteTheme("theme drawing left out provider=" + themeEntries[i].provider + " id=" +
					NameToString(themeEntries[i].target) + " reason=choice");
				continue;
			}
			owner = ThemeDrawingOwner(themeEntries[i].target);
			if (owner != themeEntries[i].provider)
			{
				NoteTheme("theme drawing refused provider=" + themeEntries[i].provider + " id=" +
					NameToString(themeEntries[i].target) + " owner=" + owner);
				continue;
			}
			if (!SpaceAreaMatches(themeEntries[i].target, owner, area))
			{
				continue;
			}
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", themeEntries[i].kind);
			item.SetMemberFlashString("t", NameToString(themeEntries[i].target));
			item.SetMemberFlashString("a", NameToString(themeEntries[i].anchor));
			item.SetMemberFlashString("y", NameToString(themeEntries[i].key));
			item.SetMemberFlashString("s", themeEntries[i].text);
			item.SetMemberFlashNumber("n", themeEntries[i].number);
			item.SetMemberFlashInt("p", ThemeFolderRank(themeEntries[i].provider));
			item.SetMemberFlashInt("o", themeEntries[i].order);
			if (themeEntries[i].kind == 4)
			{
				item.SetMemberFlashInt("c", themeEntries[i].values.Size());
				for (k = 0; k < themeEntries[i].values.Size(); k += 1)
				{
					item.SetMemberFlashNumber("v" + k, themeEntries[i].values[k]);
				}
				values += themeEntries[i].values.Size();
			}
			flashArray.PushBackFlashObject(item);
			sent += 1;
		}
		storage.SetFlashArray("cmf.map.space", flashArray);
		CMFLog("space sent area=" + NameToString(area) + " entries=" + sent + " values=" + values);
	}

	// Map-space drawing (CMFMapRefresh): runs OnMapReady again and re-sends the theme and the map-space drawings
	// to the open map. False when no map is open.
	public function RefreshMap() : bool
	{
		if (!spaceMenu)
		{
			return false;
		}
		spaceMenu.CMFMapSpaceSend(true);
		return true;
	}

	// The map panel asks for the map-space drawings once its listener is ready (the first build can come first).
	public function SpaceListenerReady(menu : CR4MapMenu)
	{
		if (menu && spaceMenu == menu)
		{
			menu.CMFMapSpaceSend(false);
		}
	}

	// Version 8: the choice keys (CMFChoiceKeys) and each one's feature, built once.
	private function EnsureChoices()
	{
		var rest, key : string;
		var i : int;
		if (choiceKeys.Size() > 0)
		{
			return;
		}
		rest = CMFChoiceKeys() + ",";
		while (StrLen(rest) > 0)
		{
			key = StrBeforeFirst(rest, ",");
			rest = StrAfterFirst(rest, ",");
			if (key != "")
			{
				choiceKeys.PushBack(key);
			}
		}
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			if (StrFindFirst(choiceKeys[i], "_") < 0)
			{
				choiceFeature.PushBack(i);
			}
			else
			{
				choiceFeature.PushBack(choiceKeys.FindFirst(StrBeforeFirst(choiceKeys[i], "_")));
			}
			menuChoices.PushBack("");
			fileChoices.PushBack("");
			decideAnswer.PushBack("");
			decideLevel.PushBack(7);
		}
	}

	// Version 8: reads the file choices ([CMFSettings] values named CMFFile_<key>, plus CMFFile_Fallthrough), asks
	// the menu add-on for its rows (ReadMenuChoices), and works out each choice's deciding answer once, so every
	// lookup of one preparation uses one set of choices. A folder name is matched to a provider ignoring case.
	private function ReadChoices()
	{
		var config : CInGameConfigWrapper;
		var varName : name;
		var key, value : string;
		var i, count, level : int;
		EnsureChoices();
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			menuChoices[i] = "";
			fileChoices[i] = "";
		}
		menuOrder = "";
		menuPresent = false;
		menuFall = "";
		hiddenAsked = "";
		menuReport = false;
		fallVanilla = false;
		config = theGame.GetInGameConfigWrapper();
		count = config.GetVarsNumByGroupName('CMFSettings');
		for (i = 0; i < count; i += 1)
		{
			varName = config.GetVarNameByGroupName('CMFSettings', i);
			key = NameToString(varName);
			if (!StrBeginsWith(key, "CMFFile_"))
			{
				continue;
			}
			value = CMFSettingsChoiceValue(config.GetVarValue('CMFSettings', varName));
			key = StrAfterFirst(key, "CMFFile_");
			if (key == "Fallthrough")
			{
				fallVanilla = value == "vanilla";
				continue;
			}
			level = choiceKeys.FindFirst(key);
			if (level >= 0)
			{
				fileChoices[level] = CanonicalProvider(value);
			}
		}
		ReadMenuChoices();
		if (menuFall != "")
		{
			fallVanilla = menuFall == "vanilla";
		}
		choicesActive = false;
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			if (menuChoices[i] != "" || fileChoices[i] != "")
			{
				choicesActive = true;
			}
		}
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			decideAnswer[i] = DecideChoice(i, level);
			decideLevel[i] = level;
		}
	}

	// A folder name written in a setting or the menu, as the provider spells it (matched ignoring case); "" and
	// "vanilla" stay as they are, and a name no provider has is kept as written (it then decides nothing).
	private function CanonicalProvider(value : string) : string
	{
		var lowered : string;
		var i : int;
		if (value == "" || value == "vanilla")
		{
			return value;
		}
		lowered = StrLower(value);
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (StrLower(claims[i].provider) == lowered)
			{
				return claims[i].provider;
			}
		}
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (StrLower(themeEntries[i].provider) == lowered)
			{
				return themeEntries[i].provider;
			}
		}
		for (i = 0; i < styledOffers.Size(); i += 1)
		{
			if (StrLower(StrAfterFirst(styledOffers[i], "/")) == lowered)
			{
				return StrAfterFirst(styledOffers[i], "/");
			}
		}
		return value;
	}

	// Version 8 hook, called each time winners are prepared, after the file choices are read. The menu add-on wraps
	// it (@wrapMethod(CMFCore)), calls wrappedMethod() and hands over its rows with SetMenuChoice, SetMenuOrder,
	// SetMenuFallthrough and SetMenuReport. Without the add-on nothing is set, so every in-game level reads
	// Automatic and values a removed add-on left in dx12user.settings steer nothing. It does nothing by itself.
	public function ReadMenuChoices()
	{
	}

	// Version 8, for the menu add-on inside ReadMenuChoices: one row's answer for a choice key (CMFChoiceKeys):
	// a folder name, "vanilla", or "" for Automatic. False (logged) for an unknown key.
	public function SetMenuChoice(key : string, value : string) : bool
	{
		var i : int;
		EnsureChoices();
		menuPresent = true;
		i = choiceKeys.FindFirst(key);
		if (i < 0)
		{
			CMFLog("choice rejected key=" + key + " reason=key");
			return false;
		}
		menuChoices[i] = CanonicalProvider(CMFSettingsChoiceValue(value));
		return true;
	}

	// Version 8, for the menu add-on: the in-game Mod order, folder names earliest first joined with commas.
	public function SetMenuOrder(order : string)
	{
		menuPresent = true;
		menuOrder = StrReplaceAll(order, " ", "");
	}

	// Version 8, for the menu add-on: the General row, "vanilla" (a chosen mod that lacks a piece shows the game's
	// own) or "next" (the next mod in order decides, the default).
	public function SetMenuFallthrough(value : string)
	{
		menuPresent = true;
		menuFall = StrLower(value);
	}

	// Version 8, for the menu add-on: the General row that writes the who-wins report to the log.
	public function SetMenuReport(report : bool)
	{
		menuPresent = true;
		menuReport = report;
	}

	// Kyle's order of authority for one choice: the first level whose answer is not Automatic. Returns a folder name,
	// "vanilla", or "@order" for an order level, with its level (LevelName); "" and level 7 when no level answers.
	// A feature has no Advanced levels. Added-together features read their answers in AdditiveAllows instead.
	private function DecideChoice(choice : int, out level : int) : string
	{
		var feature : int;
		feature = choiceFeature[choice];
		if (choice != feature && menuChoices[choice] != "")
		{
			level = 1;
			return menuChoices[choice];
		}
		if (menuChoices[feature] != "")
		{
			level = 2;
			return menuChoices[feature];
		}
		if (menuOrder != "")
		{
			level = 3;
			return "@order";
		}
		if (choice != feature && fileChoices[choice] != "")
		{
			level = 4;
			return fileChoices[choice];
		}
		if (fileChoices[feature] != "")
		{
			level = 5;
			return fileChoices[feature];
		}
		if (providerOrder != "")
		{
			level = 6;
			return "@order";
		}
		level = 7;
		return "";
	}

	// Version 8: the name of a level of the order of authority, for the menu's Status page and the log. The last
	// level, folder-name order, reads "Default" (Kyle 2026-10-22: the CMF default order; it also fits the column).
	public function LevelName(level : int) : string
	{
		switch (level)
		{
			case 1:
				return "Advanced";
			case 2:
				return "Basic";
			case 3:
				return "Mod order";
			case 4:
				return "Advanced file";
			case 5:
				return "Basic file";
			case 6:
				return "File order";
			case 7:
				return "Default";
		}
		return "";
	}

	// Version 8: true when provider a wins choice `choice` over b: each level in turn (Advanced in-game, Basic
	// in-game, in-game Mod order, Advanced file, Basic file, file order, folder name) decides when it names one of
	// them; a level naming another mod, Vanilla or nothing passes to the next. -1 uses the orders only.
	public function PieceBeats(choice : int, a : string, b : string) : bool
	{
		var feature : int;
		var result : bool;
		if (choicesActive && choice >= 0 && a != b)
		{
			feature = choiceFeature[choice];
			if (choice != feature && PickDecides(menuChoices[choice], a, b, result))
			{
				return result;
			}
			if (PickDecides(menuChoices[feature], a, b, result))
			{
				return result;
			}
			if (OrderDecides(menuOrder, a, b, result))
			{
				return result;
			}
			if (choice != feature && PickDecides(fileChoices[choice], a, b, result))
			{
				return result;
			}
			if (PickDecides(fileChoices[feature], a, b, result))
			{
				return result;
			}
		}
		return ProviderBeats(a, b);
	}

	private function PickDecides(pick : string, a : string, b : string, out result : bool) : bool
	{
		if (pick == "" || pick == "vanilla")
		{
			return false;
		}
		if (a == pick)
		{
			result = true;
			return true;
		}
		if (b == pick)
		{
			result = false;
			return true;
		}
		return false;
	}

	// An order decides when it lists a or b: listed before unlisted, then earlier first.
	private function OrderDecides(order : string, a : string, b : string, out result : bool) : bool
	{
		var rankA, rankB : int;
		if (order == "")
		{
			return false;
		}
		rankA = CMFSettingsProviderRank(order, a);
		rankB = CMFSettingsProviderRank(order, b);
		if (rankA == rankB)
		{
			return false;
		}
		if (rankA < 0)
		{
			result = false;
		}
		else if (rankB < 0)
		{
			result = true;
		}
		else
		{
			result = rankA < rankB;
		}
		return true;
	}

	// Version 8: the choice (CMFChoiceKeys index) one property of one pin type belongs to, or -1 when the property is
	// not chosen per feature. Hides, greyed pins and tab hides (5, 9, 15) answer the Hidden feature; a type left empty
	// (a tag or every-pin claim) answers the whole feature.
	public function PropertyChoice(propertyId : int, pinType : string) : int
	{
		var choice : int;
		switch (propertyId)
		{
			case 1:
			case 2:
				if (pinType == "")
				{
					return 0; // Icons
				}
				return 11 + PinGroupOf(pinType); // Icons_General
			case 3:
				if (pinType == "")
				{
					return 1; // Colours
				}
				return 19 + PinGroupOf(pinType); // Colours_General
			case 4:
				choice = CMFPaintingChoice(pinType);
				if (choice < 0)
				{
					return 9; // Painting
				}
				return choice;
			case 5:
			case 9:
			case 15:
				return 6; // Hidden
			case 6:
				return 33; // Legend_Rows
			case 7:
				return 34; // Legend_Names
			case 8:
			case 23:
				return 35; // Legend_Tabs
			case 10:
				return 27; // Size_Scale
			case 22:
				return 28; // Size_Lead
			case 12:
			case 17:
				return 30; // Labels_Text
			case 11:
			case 13:
				return 31; // Labels_Place
			case 14:
				return 41; // Look_InfoBox
			case 16:
			case 20:
			case 21:
				return 32; // Clicks_Pins
			case 24:
				return 59; // Painting_World
			case 25:
			case 27:
				return 60; // Painting_Crests
			case 26:
				return 42; // Look_Hints
		}
		return -1;
	}

	// Version 8: the choice a theme part belongs to (part styles; drawings answer Drawings), or -1.
	public function PartChoice(part : name) : int
	{
		switch (part)
		{
			case 'screen':
			case 'mapEdge':
			case 'title':
			case 'tracker':
			case 'preview':
			case 'worldButton':
			case 'worldHint':
			case 'markerPanel':
				return 39; // Look_Frames
			case 'legend':
			case 'legendRow':
			case 'legendTab':
				return 40; // Look_Legend
			case 'tooltip':
				return 41; // Look_InfoBox
			case 'hints':
			case 'keyCap':
				return 42; // Look_Hints
			case 'pinLabel':
			case 'pinName':
			case 'pinButton':
				return 43; // Look_PinText
			case 'map':
				return 44; // Movement_Area
			case 'navigation':
				return 45; // Movement_Pan
			case 'opening':
				return 46; // Movement_Opening
			case 'spread':
				return 29; // Size_Spread
		}
		return -1;
	}

	// The pin group of the last type asked (pin lookups ask for one pin's type several times in a row).
	private function PinGroupOf(pinType : string) : int
	{
		if (pinType != groupCacheType || groupCacheType == "")
		{
			groupCacheType = pinType;
			groupCacheValue = CMFPinGroup(pinType);
		}
		return groupCacheValue;
	}

	// Version 8: true when a provider's part of an added-together feature applies (Hidden 6: hides, greyed pins and
	// tab hides; Drawings 10). Automatic keeps every mod's, Vanilla none, a mod only that mod's, and the three Ignore
	// slots leave mods out. When any in-game row of the feature is set, the in-game rows replace the file's.
	private function AdditiveAllows(feature : int, provider : string) : bool
	{
		var slot : int;
		var basic : string;
		if (!choicesActive)
		{
			return true;
		}
		slot = 36; // Hidden_Ignore1
		if (feature == 10)
		{
			slot = 56; // Drawings_Ignore1
		}
		basic = AdditiveBasic(feature, menuChoices[feature]);
		if (basic != "" || menuChoices[slot] != "" || menuChoices[slot + 1] != "" || menuChoices[slot + 2] != "")
		{
			return ChoiceAllows(basic, menuChoices[slot], menuChoices[slot + 1], menuChoices[slot + 2], provider);
		}
		return ChoiceAllows(AdditiveBasic(feature, fileChoices[feature]), fileChoices[slot], fileChoices[slot + 1],
			fileChoices[slot + 2], provider);
	}

	// A mod named for an added-together feature counts only while it sends CMF something for that feature: a choice
	// left over from a mod since removed (or one with nothing for it) reads Automatic, so the next level decides
	// (Kyle 2026-10-22: a saved Drawings pick of a removed mod left out every Ink & Iron drawing).
	private function AdditiveBasic(feature : int, value : string) : string
	{
		var i : int;
		if (value == "" || value == "vanilla")
		{
			return value;
		}
		if (feature == 10)
		{
			for (i = 0; i < themeEntries.Size(); i += 1)
			{
				if (themeEntries[i].kind != 1 && themeEntries[i].provider == value)
				{
					return value;
				}
			}
			return "";
		}
		// Hidden pins: the answer for one name is kept until the next preparation (ReadChoices), since Prepare asks
		// once per hide claim.
		if (value != hiddenAsked)
		{
			hiddenAsked = value;
			hiddenOffered = false;
			for (i = 0; i < claims.Size() && !hiddenOffered; i += 1)
			{
				hiddenOffered = claims[i].provider == value && (claims[i].propertyId == CMFPropertyHidden() ||
					claims[i].propertyId == CMFPropertyTabHide() || claims[i].propertyId == CMFPropertyDisabled());
			}
		}
		if (hiddenOffered)
		{
			return value;
		}
		return "";
	}

	private function ChoiceAllows(basic : string, ignore1 : string, ignore2 : string, ignore3 : string,
		provider : string) : bool
	{
		if (provider == ignore1 || provider == ignore2 || provider == ignore3)
		{
			return false;
		}
		if (basic == "")
		{
			return true;
		}
		if (basic == "vanilla")
		{
			return false;
		}
		return basic == provider;
	}

	// Version 8: a per-pin style (CMFStylePin) passes the piece's choice: never under Vanilla; under a chosen mod
	// that mod's always, and another mod's only when the chosen mod has nothing for this pin and the General row
	// does not say Vanilla.
	private function StyleAllowed(choice : int, provider : string, dataObject : CScriptedFlashObject, propertyId : int,
		ownerField : string) : bool
	{
		var answer : string;
		var claim : SCMFClaim;
		if (!choicesActive || choice < 0)
		{
			return true;
		}
		answer = decideAnswer[choice];
		if (answer == "vanilla")
		{
			return false;
		}
		if (answer == "" || answer == "@order" || answer == provider)
		{
			return true;
		}
		if (CMFPinOwner(dataObject, ownerField) == answer)
		{
			return false;
		}
		if (FindOwn(propertyId, answer, dataObject.GetMemberFlashString("type"), '', 1, claim) ||
			FindOwn(propertyId, answer, dataObject.GetMemberFlashString("filteredType"), '', 1, claim))
		{
			return false;
		}
		return !fallVanilla;
	}

	// Version 8: which provider offers which choice, for the menu add-on: any claim, theme entry, or a pin the
	// provider styled itself in an earlier map build (styledOffers). Rebuilt each preparation.
	private function PrepareOffers()
	{
		var i : int;
		offerProviders.Clear();
		offerFlags.Clear();
		for (i = 0; i < claims.Size(); i += 1)
		{
			NoteOfferFor(PropertyChoice(claims[i].propertyId, NameToString(claims[i].pinType)), claims[i].provider);
		}
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1)
			{
				NoteOfferFor(PartChoice(themeEntries[i].target), themeEntries[i].provider);
			}
			else
			{
				NoteOfferFor(10, themeEntries[i].provider); // Drawings
			}
		}
		for (i = 0; i < styledOffers.Size(); i += 1)
		{
			NoteOfferFor(StringToInt(StrBeforeFirst(styledOffers[i], "/")), StrAfterFirst(styledOffers[i], "/"));
		}
		// Version 9: an opening view offers Movement_View.
		for (i = 0; i < openingViews.Size(); i += 1)
		{
			NoteOfferFor(61, openingViews[i].provider);
		}
	}

	private function NoteOfferFor(choice : int, provider : string)
	{
		var p, start, i : int;
		if (choice < 0 || provider == "")
		{
			return;
		}
		EnsureChoices();
		p = offerProviders.FindFirst(provider);
		if (p < 0)
		{
			offerProviders.PushBack(provider);
			p = offerProviders.Size() - 1;
			for (i = 0; i < choiceKeys.Size(); i += 1)
			{
				offerFlags.PushBack(false);
			}
		}
		start = p * choiceKeys.Size();
		offerFlags[start + choice] = true;
		offerFlags[start + choiceFeature[choice]] = true;
	}

	// A provider styled a pin itself (CMFStylePin): it offers that pin's choice from now on (capped).
	private function NoteStyledOffer(choice : int, provider : string)
	{
		var offerKey : string;
		if (choice < 0)
		{
			return;
		}
		offerKey = "" + choice + "/" + provider;
		if (offerKey == lastStyledOffer)
		{
			return;
		}
		lastStyledOffer = offerKey;
		if (styledOffers.Size() < 256 && !styledOffers.Contains(offerKey))
		{
			styledOffers.PushBack(offerKey);
			NoteOfferFor(choice, provider);
		}
	}

	// Version 8, for the menu add-on: the number of choices (CMFChoiceKeys), one key, and its feature's index.
	public function ChoiceCount() : int
	{
		EnsureChoices();
		return choiceKeys.Size();
	}

	public function ChoiceKey(choice : int) : string
	{
		EnsureChoices();
		if (choice < 0 || choice >= choiceKeys.Size())
		{
			return "";
		}
		return choiceKeys[choice];
	}

	public function ChoiceIndex(key : string) : int
	{
		EnsureChoices();
		return choiceKeys.FindFirst(key);
	}

	public function ChoiceFeature(choice : int) : int
	{
		EnsureChoices();
		if (choice < 0 || choice >= choiceKeys.Size())
		{
			return -1;
		}
		return choiceFeature[choice];
	}

	// Version 8, for the menu add-on: every provider CMF has met (claims, theme, styled pins), in folder order.
	public function Providers(out providers : array<string>)
	{
		var i, k : int;
		if (dirty)
		{
			Prepare();
		}
		providers.Clear();
		for (i = 0; i < offerProviders.Size(); i += 1)
		{
			k = 0;
			while (k < providers.Size() && CMFFolderBeats(providers[k], offerProviders[i]))
			{
				k += 1;
			}
			providers.Insert(k, offerProviders[i]);
		}
	}

	// Version 8, for the menu add-on: true when the provider sends CMF anything for this choice. An Ignore slot asks
	// for its feature.
	public function Offers(choice : int, provider : string) : bool
	{
		var p : int;
		EnsureChoices();
		if (choice < 0 || choice >= choiceKeys.Size())
		{
			return false;
		}
		if ((choice >= 36 && choice <= 38) || (choice >= 56 && choice <= 58))
		{
			choice = choiceFeature[choice];
		}
		p = offerProviders.FindFirst(provider);
		if (p < 0)
		{
			return false;
		}
		return offerFlags[p * choiceKeys.Size() + choice];
	}

	// Version 8, for the menu add-on's rows and the report: who wins a choice now. Returns a provider, "vanilla" (a
	// level says Vanilla, or the chosen mod offers nothing and the General row says Vanilla) or "" (no provider offers
	// it, level 0). level is the deciding level (LevelName). skipLevel leaves one level out: the asking row's own (1
	// Advanced, 2 Basic, 3 Mod order), or 0. Not for the added-together features (AllowedCount).
	public function WinnerOf(choice : int, skipLevel : int, out level : int) : string
	{
		var candidates : array<string>;
		var feature, i, l, rank, bestRank : int;
		var pick, order, best : string;
		level = 0;
		if (dirty)
		{
			Prepare();
		}
		EnsureChoices();
		if (choice < 0 || choice >= choiceKeys.Size())
		{
			return "";
		}
		for (i = 0; i < offerProviders.Size(); i += 1)
		{
			if (Offers(choice, offerProviders[i]))
			{
				candidates.PushBack(offerProviders[i]);
			}
		}
		if (candidates.Size() == 0)
		{
			return "";
		}
		feature = choiceFeature[choice];
		for (l = 1; l <= 6; l += 1)
		{
			if (l == skipLevel)
			{
				continue;
			}
			if (l == 3 || l == 6)
			{
				order = menuOrder;
				if (l == 6)
				{
					order = providerOrder;
				}
				best = "";
				bestRank = -1;
				for (i = 0; i < candidates.Size(); i += 1)
				{
					rank = CMFSettingsProviderRank(order, candidates[i]);
					if (rank >= 0 && (bestRank < 0 || rank < bestRank))
					{
						best = candidates[i];
						bestRank = rank;
					}
				}
				if (best != "")
				{
					level = l;
					return best;
				}
				continue;
			}
			pick = "";
			if (l == 1 && choice != feature)
			{
				pick = menuChoices[choice];
			}
			else if (l == 2)
			{
				pick = menuChoices[feature];
			}
			else if (l == 4 && choice != feature)
			{
				pick = fileChoices[choice];
			}
			else if (l == 5)
			{
				pick = fileChoices[feature];
			}
			if (pick == "")
			{
				continue;
			}
			level = l;
			if (pick == "vanilla" || (!candidates.Contains(pick) && fallVanilla))
			{
				return "vanilla";
			}
			if (candidates.Contains(pick))
			{
				return pick;
			}
		}
		level = 7;
		best = candidates[0];
		for (i = 1; i < candidates.Size(); i += 1)
		{
			if (CMFFolderBeats(candidates[i], best))
			{
				best = candidates[i];
			}
		}
		return best;
	}

	// Version 8, for the menu add-on: of the providers offering an added-together feature (6 Hidden, 10 Drawings),
	// how many apply now (AdditiveAllows); offered receives how many offer it.
	public function AllowedCount(feature : int, out offered : int) : int
	{
		var i, allowed : int;
		if (dirty)
		{
			Prepare();
		}
		offered = 0;
		allowed = 0;
		for (i = 0; i < offerProviders.Size(); i += 1)
		{
			if (Offers(feature, offerProviders[i]))
			{
				offered += 1;
				if (AdditiveAllows(feature, offerProviders[i]))
				{
					allowed += 1;
				}
			}
		}
		return allowed;
	}

	// Version 8: true when the menu add-on handed over its rows at the last preparation.
	public function MenuPresent() : bool
	{
		return menuPresent;
	}

	// Version 8: true once the world map has been drawn since the game started. Offers made only while pins are
	// styled (CMFStylePin) are known from then on, so the menu greys a row no mod offers only after that.
	public function MapSeen() : bool
	{
		return mapSeen;
	}

	// Version 8: a provider's display name (CMFSetProviderName), else CMFTidyName of its folder name.
	public function SetProviderName(provider : string, displayName : string)
	{
		var i : int;
		i = nameProviders.FindFirst(provider);
		if (i < 0)
		{
			nameProviders.PushBack(provider);
			nameTexts.PushBack(displayName);
		}
		else
		{
			nameTexts[i] = displayName;
		}
	}

	public function ProviderName(provider : string) : string
	{
		var i : int;
		i = nameProviders.FindFirst(provider);
		if (i >= 0 && nameTexts[i] != "")
		{
			return nameTexts[i];
		}
		return CMFTidyName(provider);
	}

	// Version 8: one line for the choices in force and one per answer that decides a choice; with CMFDebug or the
	// menu's report row, one "wins" line per choice too.
	private function ReportChoices()
	{
		var i, level, offered : int;
		var winner, fall : string;
		if (!choicesActive && menuOrder == "" && !menuPresent)
		{
			return;
		}
		fall = "next";
		if (fallVanilla)
		{
			fall = "vanilla";
		}
		CMFLog("choices menu=" + CMFYesNo(menuPresent) + " order=" + menuOrder + " fallthrough=" + fall + " active=" +
			CMFYesNo(choicesActive));
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			if (menuChoices[i] != "")
			{
				CMFLog("choice key=" + choiceKeys[i] + " value=" + menuChoices[i] + " level=in-game");
			}
			if (fileChoices[i] != "")
			{
				CMFLog("choice key=" + choiceKeys[i] + " value=" + fileChoices[i] + " level=file");
			}
		}
		if (!menuReport && !CMFSettingsDebug())
		{
			return;
		}
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			if (i == 6 || i == 10 || (i >= 36 && i <= 38) || (i >= 56 && i <= 58))
			{
				if (i == 6 || i == 10)
				{
					CMFLog("wins key=" + choiceKeys[i] + " applied=" + AllowedCount(i, offered) + " of=" + offered);
				}
				continue;
			}
			winner = WinnerOf(i, 0, level);
			if (winner != "")
			{
				CMFLog("wins key=" + choiceKeys[i] + " winner=" + winner + " level=" + LevelName(level));
			}
		}
	}

	public function Prepare()
	{
		var i, w : int;
		var found : bool;
		providerOrder = CMFSettingsProviderOrder();
		ReadChoices();
		winners.Clear();
		hideClaims.Clear();
		tabHideClaims.Clear();
		choiceOnlySkipped.Clear();
		for (i = 0; i < claims.Size(); i += 1)
		{
			// Version 9: a claim whose choice its provider made choice-only waits until that provider is picked.
			if (ChoiceOnlySkips(PropertyChoice(claims[i].propertyId, NameToString(claims[i].pinType)), claims[i].provider))
			{
				choiceOnlySkipped.PushBack(claims[i].provider);
				continue;
			}
			// Hide claims are never arbitrated: every eligible one applies (version 8: unless the Hidden pins
			// choice leaves its provider out; greyed pins follow the same choice).
			if (claims[i].propertyId == CMFPropertyHidden())
			{
				if (CMFHasFlag(claims[i].number, 1) && AdditiveAllows(6, claims[i].provider))
				{
					hideClaims.PushBack(claims[i]);
				}
				continue;
			}
			if (claims[i].propertyId == CMFPropertyTabHide())
			{
				if (claims[i].number != 0 && AdditiveAllows(6, claims[i].provider))
				{
					tabHideClaims.PushBack(claims[i]);
				}
				continue;
			}
			if (claims[i].propertyId == CMFPropertyDisabled() && !AdditiveAllows(6, claims[i].provider))
			{
				continue;
			}
			// A withdrawn label hide or info box height leaves the slot to the next folder.
			if ((claims[i].propertyId == CMFPropertyLabelHide() || claims[i].propertyId == CMFPropertyInfoBoxHeight()) &&
				claims[i].number == 0)
			{
				continue;
			}
			// Version 6: a withdrawn click, hint or button leaves the pin to the next folder. Hints and buttons are
			// never arbitrated: each one follows its own provider's click (WriteClickFields).
			if (CMFIsClickProperty(claims[i].propertyId))
			{
				if (claims[i].number == 0)
				{
					continue;
				}
				if (claims[i].propertyId != CMFPropertyPinClick())
				{
					winners.PushBack(claims[i]);
					continue;
				}
			}
			found = false;
			for (w = 0; w < winners.Size(); w += 1)
			{
				if (!found && SameSlot(winners[w], claims[i]))
				{
					found = true;
					if (Beats(claims[i], winners[w]))
					{
						Report("shadowed", winners[w]);
						ReportClickShadow(winners[w], claims[i]);
						winners[w] = claims[i];
					}
					else
					{
						Report("shadowed", claims[i]);
						ReportClickShadow(claims[i], winners[w]);
					}
				}
			}
			if (!found)
			{
				winners.PushBack(claims[i]);
			}
		}
		dirty = false;
		revision += 1;
		if (providerOrder != "")
		{
			CMFLog("provider order=" + providerOrder);
		}
		CMFLog("prepared claims=" + claims.Size() + " winners=" + winners.Size() + " revision=" + revision);
		ReportProviders();
		PrepareOffers();
		ReportChoices();
		PrepareLegend();
		for (i = 0; i < hideClaims.Size(); i += 1)
		{
			CMFLog("hide provider=" + hideClaims[i].provider + " level=" + hideClaims[i].level + " type=" +
				NameToString(hideClaims[i].pinType) + " tag=" + NameToString(hideClaims[i].pinTag) + " context=" +
				NameToString(hideClaims[i].mapContext) + " exempt=" + hideClaims[i].text);
		}
		for (i = 0; i < tabHideClaims.Size(); i += 1)
		{
			CMFLog("tab hide provider=" + tabHideClaims[i].provider + " level=" + tabHideClaims[i].level + " type=" +
				NameToString(tabHideClaims[i].pinType) + " tag=" + NameToString(tabHideClaims[i].pinTag) + " tabs=" +
				tabHideClaims[i].text);
		}
	}

	// Orders the winning category claims by (number, id ignoring case); a category's effective tab
	// priority is 1000 + its position, so the panel never sees two equal priorities. Logs every winning
	// category and row.
	private function PrepareLegend()
	{
		var i, c : int;
		var category : string;
		var reason : string;
		categories.Clear();
		for (i = 0; i < winners.Size(); i += 1)
		{
			if (winners[i].propertyId == CMFPropertyLegendCategory())
			{
				c = 0;
				while (c < categories.Size() && CMFCategoryBefore(categories[c], winners[i]))
				{
					c += 1;
				}
				categories.Insert(c, winners[i]);
			}
		}
		for (c = 0; c < categories.Size(); c += 1)
		{
			CMFLog("legend category id=" + NameToString(categories[c].pinType) + " label=" + categories[c].text +
				" priority=" + (1000 + c) + " provider=" + categories[c].provider);
		}
		for (i = 0; i < winners.Size(); i += 1)
		{
			if (winners[i].propertyId == CMFPropertyLegendRow())
			{
				category = winners[i].text;
				reason = "";
				if (category != "" && !CMFIsVanillaCategory(category, false) && CategoryIndex(category) < 0)
				{
					reason = " reason=undeclared";
				}
				CMFLog("legend row type=" + NameToString(winners[i].pinType) + " category=" + category + " priority=" +
					LegendPriority(winners[i].number) + " provider=" + winners[i].provider + reason);
			}
		}
	}

	// Position of a winning category claim in tab order, or -1.
	private function CategoryIndex(category : string) : int
	{
		var c : int;
		for (c = 0; c < categories.Size(); c += 1)
		{
			if (NameToString(categories[c].pinType) == category)
			{
				return c;
			}
		}
		return -1;
	}

	// 0 (or less) means after every vanilla row and before vanilla's unknown rows (999999).
	private function LegendPriority(number : int) : int
	{
		if (number <= 0)
		{
			return 900000;
		}
		return number;
	}

	// One line per provider: the "is my pack loaded?" answer.
	private function ReportProviders()
	{
		var providers : array<string>;
		var i, p, total, won, hides, skipped : int;
		var choiceOnly : string;
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (!providers.Contains(claims[i].provider))
			{
				providers.PushBack(claims[i].provider);
			}
		}
		for (p = 0; p < providers.Size(); p += 1)
		{
			total = 0;
			won = 0;
			hides = 0;
			for (i = 0; i < claims.Size(); i += 1)
			{
				if (claims[i].provider == providers[p] &&
					(claims[i].propertyId == CMFPropertyHidden() || claims[i].propertyId == CMFPropertyTabHide()))
				{
					hides += 1;
				}
				else if (claims[i].provider == providers[p])
				{
					total += 1;
				}
			}
			for (i = 0; i < winners.Size(); i += 1)
			{
				if (winners[i].provider == providers[p])
				{
					won += 1;
				}
			}
			// Version 9: claims left out because their choice is choice-only and the provider is not picked.
			skipped = 0;
			for (i = 0; i < choiceOnlySkipped.Size(); i += 1)
			{
				if (choiceOnlySkipped[i] == providers[p])
				{
					skipped += 1;
				}
			}
			choiceOnly = "";
			if (skipped > 0)
			{
				choiceOnly = " choiceonly=" + skipped;
			}
			if (hides > 0)
			{
				CMFLog("provider=" + providers[p] + " claims=" + total + " won=" + won + " shadowed=" + (total - won) +
					" hides=" + hides + choiceOnly);
			}
			else
			{
				CMFLog("provider=" + providers[p] + " claims=" + total + " won=" + won + " shadowed=" + (total - won) +
					choiceOnly);
			}
		}
	}

	// Called by the map panel when a registered image cannot be loaded. Logs each path once per session
	// (capped), naming every provider that registered it, so a pack author sees the broken path.
	public function ReportArtFailed(url : string)
	{
		var owners : array<string>;
		var line : string;
		var i : int;
		if (url == "" || failedArt.Contains(url) || failedArt.Size() >= 32)
		{
			return;
		}
		failedArt.PushBack(url);
		line = "art failed url=" + url;
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].text == url && !owners.Contains(claims[i].provider))
			{
				owners.PushBack(claims[i].provider);
				line += " provider=" + claims[i].provider;
			}
		}
		CMFLog(line);
	}

	// Changes whenever the prepared winners change; lets other CMF surfaces cache lookups.
	public function GetRevision() : int
	{
		if (dirty)
		{
			Prepare();
		}
		return revision;
	}

	// Type-level (or all-pin) winner for one property, for CMF surfaces other than the world map.
	public function FindTypeWinner(propertyId : int, pinType : name, out result : SCMFClaim) : bool
	{
		if (dirty)
		{
			Prepare();
		}
		return Find(propertyId, NameToString(pinType), '', 1, result);
	}

	// Image root the full-screen map uses for one area: the winning background, else vanilla's.
	// Logs the area's vanilla tile geometry, which a background pack's tiles must match.
	public function MapImageRoot(area : name, vanillaRoot : string) : string
	{
		var claim : SCMFClaim;
		var root : string;
		if (dirty)
		{
			Prepare();
		}
		root = vanillaRoot;
		if (Find(CMFPropertyBackground(), NameToString(area), '', 1, claim))
		{
			root = claim.text;
		}
		CMFLog("background area=" + NameToString(area) + " vanilla=" + vanillaRoot + " root=" + root +
			" textureSize=" + theGame.GetMiniMapTextureSize(area) + " minLod=" + theGame.GetMiniMapMinLod(area) +
			" maxLod=" + theGame.GetMiniMapMaxLod(area) + " tileCount=" + theGame.GetMiniMapTileCount(area) +
			" mapSize=" + FloatToString(theGame.GetMiniMapSize(area)));
		return root;
	}

	// Called for every engine pin from AddPinTypeData, after vanilla filled the object: lookup only.
	public function WritePinFields(dataObject : CScriptedFlashObject, pinType : name, pinTag : name, mapContext : name)
	{
		if (dirty)
		{
			Prepare();
		}
		if (!dataObject)
		{
			return;
		}
		dataObject.SetMemberFlashBool("cmfDone", true);
		if (hideClaims.Size() > 0)
		{
			MarkHidden(dataObject, HideOwner(dataObject, dataObject.GetMemberFlashString("type"), NameToString(pinType),
				pinTag, 2, mapContext));
		}
		if (tabHideClaims.Size() > 0)
		{
			WriteTabHide(dataObject, dataObject.GetMemberFlashString("type"), NameToString(pinType), pinTag, 2);
		}
		if (winners.Size() == 0)
		{
			return;
		}
		NotePin(pinType, pinTag);
		WriteFields(dataObject, NameToString(pinType), NameToString(pinType), pinTag, 2, mapContext);
	}

	// Late pass over the finished pin array: type-level fields for pins that skipped AddPinTypeData
	// (pins other mods push themselves). Player and user pins stay stock. Runs with no claims too:
	// cmfRowHide lets hiding a legend row under All hide every pin type sharing its filteredType.
	// On the full list (indexToUpdate -1) it also marks hidden pins and removes every marked pin, so the
	// map's counts, cycling, tooltips, overview and quest-list lookup never see them.
	public function FillMissingPinFields(flashArray : CScriptedFlashArray, mapContext : name, indexToUpdate : int,
		area : name)
	{
		var dataObject : CScriptedFlashObject;
		var pinType : string;
		var filtered : string;
		var pinTag : name;
		var maxLevel : int;
		var i : int;
		var fullList : bool;
		var fresh : bool;
		fullList = indexToUpdate < 0;
		if (dirty)
		{
			Prepare();
		}
		if (!flashArray)
		{
			listOpen = false;
			return;
		}
		for (i = 0; i < flashArray.GetLength(); i += 1)
		{
			dataObject = flashArray.GetElementFlashObject(i);
			fresh = false;
			if (dataObject && !dataObject.GetMemberFlashBool("cmfDone") && !dataObject.GetMemberFlashBool("isPlayer") &&
				!dataObject.GetMemberFlashBool("isUserPin"))
			{
				fresh = true;
				dataObject.SetMemberFlashBool("cmfDone", true);
				dataObject.SetMemberFlashBool("cmfRowHide", true);
				// Pin art, tint and appearance key on the pin's own type (script-pushed pins often share one
				// filteredType across several types); the legend row keys on filteredType. Each property
				// falls back to the other key when it has no claim for the first.
				pinType = dataObject.GetMemberFlashString("type");
				filtered = dataObject.GetMemberFlashString("filteredType");
				if (winners.Size() > 0)
				{
					NoteLatePin(pinType, filtered);
				}
				if (pinType == "")
				{
					pinType = filtered;
				}
				if (filtered == "")
				{
					filtered = pinType;
				}
				// A pin a mod pushes itself is reached by tag when its id is the game's id for that tag
				// (NameToFlashUInt), as the game sets it on its own pins, so one mod can style or hide a pin
				// another mod adds by naming the tag that mod gave it.
				pinTag = LateTag(dataObject);
				maxLevel = 1;
				if (IsNameValid(pinTag))
				{
					maxLevel = 2;
				}
				if (fullList && hideClaims.Size() > 0)
				{
					MarkHidden(dataObject, HideOwner(dataObject, pinType, filtered, pinTag, maxLevel, mapContext));
				}
				if (tabHideClaims.Size() > 0)
				{
					WriteTabHide(dataObject, pinType, filtered, pinTag, maxLevel);
				}
				if (winners.Size() > 0)
				{
					WriteFields(dataObject, pinType, filtered, pinTag, maxLevel, mapContext);
				}
			}
			// Version 6: clicks reach user pins (type claims on their type, then their filteredType), on the full
			// list and on the one-pin update that follows placing a pin. Other properties keep skipping them.
			if (dataObject && dataObject.GetMemberFlashBool("isUserPin") && !dataObject.GetMemberFlashBool("isPlayer") &&
				winners.Size() > 0)
			{
				WriteClickFields(dataObject, dataObject.GetMemberFlashString("type"),
					dataObject.GetMemberFlashString("filteredType"), '', 1);
			}
			// Every mod has added its pins: providers and adapters may style each one now (OnPinReady). A
			// second pass for pins pushed after the first (CatchLatePins) reaches only those.
			if (fullList && dataObject && !dataObject.GetMemberFlashBool("isPlayer") &&
				!dataObject.GetMemberFlashBool("isUserPin") && (fresh || !catching))
			{
				OnPinReady(dataObject, mapContext);
			}
		}
		if (fullList)
		{
			RemoveHiddenPins(flashArray, area, mapContext);
		}
		listOpen = false;
	}

	// The tag of a tag claim (any property) whose game id (NameToFlashUInt) is this pin's id, or None.
	private function LateTag(dataObject : CScriptedFlashObject) : name
	{
		var id : int;
		var i : int;
		id = dataObject.GetMemberFlashUInt("id");
		if (id == 0)
		{
			return '';
		}
		for (i = 0; i < winners.Size(); i += 1)
		{
			if (winners[i].level == 2 && NameToFlashUInt(winners[i].pinTag) == id)
			{
				return winners[i].pinTag;
			}
		}
		for (i = 0; i < hideClaims.Size(); i += 1)
		{
			if (hideClaims[i].level == 2 && NameToFlashUInt(hideClaims[i].pinTag) == id)
			{
				return hideClaims[i].pinTag;
			}
		}
		for (i = 0; i < tabHideClaims.Size(); i += 1)
		{
			if (tabHideClaims[i].level == 2 && NameToFlashUInt(tabHideClaims[i].pinTag) == id)
			{
				return tabHideClaims[i].pinTag;
			}
		}
		return '';
	}

	// Version 4 hook, called for every pin of a full map build (not the player marker or user pins) after
	// every mod has added its pins and CMF has written the type and tag claims, before the map draws them.
	// It does nothing: a provider or adapter wraps it (@wrapMethod(CMFCore)) to read what it or another mod
	// wrote on the pin and style it with CMFStylePin, CMFHidePin and the other per-pin calls.
	public function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
	{
	}

	// Version 4 hook, called once per full map build after OnPinReady has run for every pin and before CMF
	// writes the info box height: wrap it to read the menu (menuFlash) and register or withdraw claims for
	// this map opening, such as CMFPropertyInfoBoxHeight.
	public function OnMapReady(menuFlash : CScriptedFlashSprite)
	{
	}

	// Runs OnMapReady, then writes the info box's text height (id 14, the earliest folder among the
	// every-pin claims) to the menu as cmfDescMaxH and its owner as cmfDescMaxBy; 0 keeps the game's box.
	public function MapReady(menuFlash : CScriptedFlashSprite)
	{
		var claim : SCMFClaim;
		if (!menuFlash)
		{
			return;
		}
		OnMapReady(menuFlash);
		mapSeen = true;
		if (dirty)
		{
			Prepare();
		}
		if (Find(CMFPropertyInfoBoxHeight(), "", '', 0, claim))
		{
			menuFlash.SetMemberFlashNumber("cmfDescMaxH", claim.number);
			menuFlash.SetMemberFlashString("cmfDescMaxBy", claim.provider);
		}
		else
		{
			menuFlash.SetMemberFlashNumber("cmfDescMaxH", 0);
			menuFlash.SetMemberFlashString("cmfDescMaxBy", "");
		}
	}

	// Merges every tab hide claim covering this pin into cmfTabHide. A type claim matches the pin's own
	// type or its filteredType; tag claims apply where the tag is known. Player and user pins never.
	private function WriteTabHide(dataObject : CScriptedFlashObject, pinType : string, filtered : string, pinTag : name,
		maxLevel : int)
	{
		var i : int;
		var covers : bool;
		if (dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin"))
		{
			return;
		}
		for (i = 0; i < tabHideClaims.Size(); i += 1)
		{
			covers = tabHideClaims[i].level <= maxLevel;
			if (covers && tabHideClaims[i].level == 1)
			{
				covers = NameToString(tabHideClaims[i].pinType) == pinType || NameToString(tabHideClaims[i].pinType) == filtered;
			}
			if (covers && tabHideClaims[i].level == 2)
			{
				covers = IsNameValid(pinTag) && tabHideClaims[i].pinTag == pinTag;
			}
			if (covers)
			{
				MergeTabHide(dataObject, tabHideClaims[i].provider, tabHideClaims[i].text);
			}
		}
	}

	// Tab hides merge and never clear; the owner field keeps the earliest-sorting provider for the log.
	private function MergeTabHide(dataObject : CScriptedFlashObject, provider : string, tabs : string)
	{
		var merged : string;
		var rest : string;
		var word : string;
		var owner : string;
		merged = CMFPinOwner(dataObject, "cmfTabHide");
		rest = tabs + ",";
		while (StrLen(rest) > 0)
		{
			word = StrBeforeFirst(rest, ",");
			rest = StrAfterFirst(rest, ",");
			if (word != "" && !CMFListHas(merged, word))
			{
				if (merged != "")
				{
					merged += ",";
				}
				merged += word;
			}
		}
		dataObject.SetMemberFlashString("cmfTabHide", merged);
		owner = CMFPinOwner(dataObject, "cmfTabHideBy");
		if (owner == "" || CMFProviderBeats(provider, owner))
		{
			dataObject.SetMemberFlashString("cmfTabHideBy", provider);
		}
	}

	// Opened by CMF's UpdateEntityPins wrapper; closed by the late pass. A per-pin hide asked for while the
	// list is closed comes after the list was sent.
	public function OpenPinList()
	{
		listOpen = true;
	}

	// The full list of the build being made, kept by CMF's UpdateUserMapPins wrapper for CatchLatePins.
	public function KeepFullList(flashArray : CScriptedFlashArray)
	{
		catchArray = flashArray;
	}

	// Wrappers nest by script file name, path and precompiled blob, so a mod's UpdateUserMapPins wrapper can run
	// outside CMF's and add pins after the late pass (Shared Utils pushes Botanist's pins that way). Called from
	// CMF's UpdateData wrapper once the build has been sent: when the list holds pins the late pass never saw,
	// fills them (OnPinReady for those pins only) and returns the list to send again; otherwise NULL.
	public function CatchLatePins(mapContext : name, area : name) : CScriptedFlashArray
	{
		var flashArray : CScriptedFlashArray;
		var dataObject : CScriptedFlashObject;
		var missed : int;
		var i : int;
		flashArray = catchArray;
		catchArray = NULL;
		if (!flashArray)
		{
			return NULL;
		}
		for (i = 0; i < flashArray.GetLength(); i += 1)
		{
			dataObject = flashArray.GetElementFlashObject(i);
			if (dataObject && !dataObject.GetMemberFlashBool("cmfDone") && !dataObject.GetMemberFlashBool("isPlayer") &&
				!dataObject.GetMemberFlashBool("isUserPin"))
			{
				missed += 1;
			}
		}
		if (missed == 0)
		{
			return NULL;
		}
		CMFLog("late pins caught n=" + missed + " of " + flashArray.GetLength());
		OpenPinList();
		catching = true;
		FillMissingPinFields(flashArray, mapContext, -1, area);
		catching = false;
		return flashArray;
	}

	// The earliest provider (folder order) whose eligible hide claim covers this pin and does not exempt
	// it, or "". Never the player marker or a user pin. A type claim matches the pin's own type or its
	// filteredType; tag claims apply where the pin's tag is known (the game's pins, and pins a mod pushes with
	// the tag's game id, see LateTag).
	private function HideOwner(dataObject : CScriptedFlashObject, pinType : string, filtered : string, pinTag : name,
		maxLevel : int, mapContext : name) : string
	{
		var owner : string;
		var i : int;
		var covers : bool;
		var tracked : bool;
		var questPin : bool;
		var travel : bool;
		owner = "";
		if (dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin"))
		{
			return owner;
		}
		tracked = dataObject.GetMemberFlashBool("tracked") || dataObject.GetMemberFlashBool("highlighted");
		questPin = dataObject.GetMemberFlashBool("isQuest");
		travel = dataObject.GetMemberFlashBool("isFastTravel");
		for (i = 0; i < hideClaims.Size(); i += 1)
		{
			covers = hideClaims[i].level <= maxLevel &&
				(!IsNameValid(hideClaims[i].mapContext) || hideClaims[i].mapContext == mapContext);
			if (covers && hideClaims[i].level == 1)
			{
				covers = NameToString(hideClaims[i].pinType) == pinType || NameToString(hideClaims[i].pinType) == filtered;
			}
			if (covers && hideClaims[i].level == 2)
			{
				covers = IsNameValid(pinTag) && hideClaims[i].pinTag == pinTag;
			}
			if (covers && ((tracked && CMFHasFlag(hideClaims[i].number, CMFExemptTracked())) ||
				(questPin && CMFHasFlag(hideClaims[i].number, CMFExemptQuest())) ||
				(travel && CMFHasFlag(hideClaims[i].number, CMFExemptFastTravel()))))
			{
				covers = false;
			}
			if (covers && (owner == "" || CMFProviderBeats(hideClaims[i].provider, owner)))
			{
				owner = hideClaims[i].provider;
			}
		}
		return owner;
	}

	// Marks merge and never clear: the earlier-sorting of the existing mark and the candidate stays.
	private function MarkHidden(dataObject : CScriptedFlashObject, candidate : string)
	{
		var existing : string;
		if (candidate == "")
		{
			return;
		}
		existing = CMFPinOwner(dataObject, "cmfHiddenBy");
		if (existing == "" || CMFProviderBeats(candidate, existing))
		{
			dataObject.SetMemberFlashString("cmfHiddenBy", candidate);
		}
	}

	// Version 9: the earliest provider (folder order) whose hide claim targets exactly 'Player' in this map context,
	// or "". Exemptions do not apply to the player marker.
	private function PlayerHideOwner(mapContext : name) : string
	{
		var owner : string;
		var i : int;
		owner = "";
		for (i = 0; i < hideClaims.Size(); i += 1)
		{
			if (hideClaims[i].level == 1 && hideClaims[i].pinType == 'Player' &&
				(!IsNameValid(hideClaims[i].mapContext) || hideClaims[i].mapContext == mapContext) &&
				(owner == "" || CMFProviderBeats(hideClaims[i].provider, owner)))
			{
				owner = hideClaims[i].provider;
			}
		}
		return owner;
	}

	// Removes every marked pin from the finished list (backwards, so a removal shifts only later pins) and
	// logs per build how many pins each hiding provider removed. Version 9: a hide claim targeting 'Player' removes
	// the player marker in its contexts; every-pin and tag hides never do.
	private function RemoveHiddenPins(flashArray : CScriptedFlashArray, area : name, mapContext : name)
	{
		var dataObject : CScriptedFlashObject;
		var providers : array<string>;
		var counts : array<int>;
		var owner, playerOwner : string;
		var i, p, removed : int;
		for (i = 0; i < hideClaims.Size(); i += 1)
		{
			if (!providers.Contains(hideClaims[i].provider))
			{
				providers.PushBack(hideClaims[i].provider);
				counts.PushBack(0);
			}
		}
		playerOwner = "";
		if (hideClaims.Size() > 0)
		{
			playerOwner = PlayerHideOwner(mapContext);
		}
		removed = 0;
		for (i = flashArray.GetLength() - 1; i >= 0; i -= 1)
		{
			dataObject = flashArray.GetElementFlashObject(i);
			if (dataObject && playerOwner != "" && dataObject.GetMemberFlashBool("isPlayer") &&
				!dataObject.GetMemberFlashBool("isUserPin"))
			{
				flashArray.RemoveElement(i);
				removed += 1;
				p = providers.FindFirst(playerOwner);
				if (p >= 0)
				{
					counts[p] += 1;
				}
				CMFLog("hide player provider=" + playerOwner + " context=" + NameToString(mapContext));
				playerOwner = "";
			}
			else if (dataObject && !dataObject.GetMemberFlashBool("isPlayer") && !dataObject.GetMemberFlashBool("isUserPin"))
			{
				owner = CMFPinOwner(dataObject, "cmfHiddenBy");
				if (owner != "")
				{
					flashArray.RemoveElement(i);
					removed += 1;
					p = providers.FindFirst(owner);
					if (p < 0)
					{
						providers.PushBack(owner);
						counts.PushBack(1);
					}
					else
					{
						counts[p] += 1;
					}
				}
			}
		}
		for (p = 0; p < providers.Size(); p += 1)
		{
			CMFLog("hidden provider=" + providers[p] + " pins=" + counts[p]);
		}
		if (removed > 0 || providers.Size() > 0)
		{
			CMFLog("hidden removed=" + removed + " area=" + NameToString(area));
		}
	}

	// The one field writer every pin path uses. pinKey picks the pin's art, tint and appearance;
	// legendKey picks its legend row's art and tint; each falls back to the other key. Legend row,
	// label and category key on legendKey only. A property a provider styled on this pin with
	// CMFStylePin (owner field set) is left alone.
	private function WriteFields(dataObject : CScriptedFlashObject, pinKey : string, legendKey : string, pinTag : name,
		maxLevel : int, mapContext : name)
	{
		var claim : SCMFClaim;
		var keepGold : bool;
		var legendFromPin : bool;
		var rowHide : bool;
		var disabledAt : int;
		var categoryAt : int;
		var noDefault : SCMFClaim;
		// The followed quest keeps vanilla's gold meaning.
		keepGold = dataObject.GetMemberFlashBool("tracked") || dataObject.GetMemberFlashBool("highlighted");
		if (CMFPinOwner(dataObject, "cmfIconBy") == "" &&
			(Find(CMFPropertyIcon(), pinKey, pinTag, maxLevel, claim) || Find(CMFPropertyIcon(), legendKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashString("cmfIconPath", claim.text);
		}
		if (Find(CMFPropertyLegendIcon(), legendKey, '', 1, claim) || Find(CMFPropertyIcon(), legendKey, '', 1, claim))
		{
			dataObject.SetMemberFlashString("cmfLegendIconPath", claim.text);
		}
		else if (Find(CMFPropertyLegendIcon(), pinKey, '', 1, claim) || Find(CMFPropertyIcon(), pinKey, '', 1, claim))
		{
			dataObject.SetMemberFlashString("cmfLegendIconPath", claim.text);
			legendFromPin = true;
		}
		if (!keepGold && CMFPinOwner(dataObject, "cmfTintBy") == "" && (Find(CMFPropertyTint(), pinKey, pinTag, maxLevel, claim) ||
			Find(CMFPropertyTint(), legendKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashUInt("cmfIconTint", claim.number);
			dataObject.SetMemberFlashBool("cmfIconTintEnabled", true);
		}
		// One legend row stands for every pin type sharing its filteredType, so its tint comes from the
		// legend name; the pin's own type only when the row's art came from it too.
		if (Find(CMFPropertyTint(), legendKey, '', 1, claim) || (legendFromPin && Find(CMFPropertyTint(), pinKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashUInt("cmfLegendTint", claim.number);
			dataObject.SetMemberFlashBool("cmfLegendTintEnabled", true);
		}
		// The panel ignores row placement for the filteredTypes it defines itself; labels apply to any row
		// except the shared quest and user-pin rows. A category nobody declared leaves the row under All.
		// Version 6: a row claim on a quest pin's filteredType gives those quest pins that row instead of
		// the shared quest row (the panel reads cmfLegendPriority > 0 on a quest pin as that claim).
		if (Find(CMFPropertyLegendRow(), legendKey, '', 1, claim))
		{
			rowHide = true;
			dataObject.SetMemberFlashInt("cmfLegendPriority", LegendPriority(claim.number));
			categoryAt = CategoryIndex(claim.text);
			if (categoryAt >= 0)
			{
				dataObject.SetMemberFlashString("cmfLegendCategory", claim.text);
				dataObject.SetMemberFlashString("cmfCategoryLabel", categories[categoryAt].text);
				dataObject.SetMemberFlashInt("cmfCategoryPriority", 1000 + categoryAt);
				if (Find(CMFPropertyCategoryNoDefault(), claim.text, '', 1, noDefault) && noDefault.number != 0)
				{
					dataObject.SetMemberFlashBool("cmfCategoryNoDefault", true);
				}
			}
			else if (CMFIsVanillaCategory(claim.text, false))
			{
				dataObject.SetMemberFlashString("cmfLegendCategory", claim.text);
			}
		}
		if (Find(CMFPropertyLegendLabel(), legendKey, '', 1, claim))
		{
			rowHide = true;
			dataObject.SetMemberFlashString("cmfLegendLabel", claim.text);
		}
		if (rowHide)
		{
			dataObject.SetMemberFlashBool("cmfRowHide", true);
		}
		// Appearance only: selection, tooltip and travel stay with the game.
		disabledAt = DisabledIndex(pinKey, pinTag, maxLevel, mapContext);
		if (disabledAt < 0)
		{
			disabledAt = DisabledIndex(legendKey, '', 1, mapContext);
		}
		if (disabledAt >= 0 && winners[disabledAt].number != 0)
		{
			dataObject.SetMemberFlashBool("cmfDisabled", true);
		}
		WriteSlot(dataObject, CMFPropertyPinScale(), pinKey, legendKey, pinTag, maxLevel);
		WriteSlot(dataObject, CMFPropertyLabelPlace(), pinKey, legendKey, pinTag, maxLevel);
		WriteSlot(dataObject, CMFPropertyLabelText(), pinKey, legendKey, pinTag, maxLevel);
		WriteSlot(dataObject, CMFPropertyLabelHide(), pinKey, legendKey, pinTag, maxLevel);
		WriteSlot(dataObject, CMFPropertyLabelColor(), pinKey, legendKey, pinTag, maxLevel);
		WriteSlot(dataObject, CMFPropertySpreadRank(), pinKey, legendKey, pinTag, maxLevel);
		WriteClickFields(dataObject, pinKey, legendKey, pinTag, maxLevel);
	}

	// Size and label slots from tag and type claims (the pin's type, then its filteredType), unless a
	// per-pin claim already owns the slot on this pin.
	private function WriteSlot(dataObject : CScriptedFlashObject, propertyId : int, pinKey : string, legendKey : string,
		pinTag : name, maxLevel : int)
	{
		var claim : SCMFClaim;
		if (CMFPinOwner(dataObject, CMFOwnerField(propertyId)) != "")
		{
			return;
		}
		if (Find(propertyId, pinKey, pinTag, maxLevel, claim) || Find(propertyId, legendKey, '', 1, claim))
		{
			SetSlot(dataObject, propertyId, claim.text, claim.number);
		}
	}

	private function SetSlot(dataObject : CScriptedFlashObject, propertyId : int, text : string, number : int)
	{
		switch (propertyId)
		{
			case 10:
				dataObject.SetMemberFlashNumber("cmfIconScale", (float)number / 100);
				break;
			case 11:
				dataObject.SetMemberFlashNumber("cmfLabelPlace", (float)number / 10);
				break;
			case 12:
				dataObject.SetMemberFlashString("cmfLabelText", text);
				break;
			case 13:
				dataObject.SetMemberFlashInt("cmfLabelHide", number);
				break;
			case 17:
				dataObject.SetMemberFlashUInt("cmfLabelColor", number);
				dataObject.SetMemberFlashBool("cmfLabelColorEnabled", true);
				break;
			case 22:
				dataObject.SetMemberFlashInt("cmfSpreadRank", number);
				break;
		}
	}

	// Logs each type/filteredType pair of pins other mods push themselves once (capped), so pack and
	// adapter authors can see which names to register.
	private function NoteLatePin(pinType : string, filtered : string)
	{
		var pinKey : string;
		pinKey = "late:" + pinType + "/" + filtered;
		if (seenPins.Size() < 64 && !seenPins.Contains(pinKey))
		{
			seenPins.PushBack(pinKey);
			CMFLog("late pin type=" + pinType + " filteredType=" + filtered);
		}
	}

	// Index of the most specific disabled claim for this pin in this context, or -1; at equal level a
	// context claim beats an every-context one.
	private function DisabledIndex(pinType : string, pinTag : name, maxLevel : int, mapContext : name) : int
	{
		var i, best, score, bestScore : int;
		var matches : bool;
		best = -1;
		bestScore = -1;
		for (i = 0; i < winners.Size(); i += 1)
		{
			matches = winners[i].propertyId == CMFPropertyDisabled() && winners[i].level <= maxLevel &&
				(!IsNameValid(winners[i].mapContext) || winners[i].mapContext == mapContext);
			if (matches && winners[i].level == 1)
			{
				matches = NameToString(winners[i].pinType) == pinType;
			}
			if (matches && winners[i].level == 2)
			{
				matches = winners[i].pinTag == pinTag;
			}
			score = winners[i].level * 2;
			if (IsNameValid(winners[i].mapContext))
			{
				score += 1;
			}
			if (matches && score > bestScore)
			{
				best = i;
				bestScore = score;
			}
		}
		return best;
	}

	// Logs each distinct type/tag pair of claimed types once (capped) so authors can target single pins.
	private function NotePin(pinType : name, pinTag : name)
	{
		var pinKey : string;
		var claim : SCMFClaim;
		if (seenPins.Size() >= 64 || !Find(CMFPropertyIcon(), NameToString(pinType), pinTag, 1, claim))
		{
			return;
		}
		pinKey = NameToString(pinType) + "/" + NameToString(pinTag);
		if (!seenPins.Contains(pinKey))
		{
			seenPins.PushBack(pinKey);
			CMFLog("pin type=" + NameToString(pinType) + " tag=" + NameToString(pinTag));
		}
	}

	// Most specific prepared winner for this pin, considering levels up to maxLevel. Version 8: through the choice of
	// the pin's piece (PropertyChoice): Vanilla finds nothing; a chosen mod's claim wins at any level of detail, and
	// when it has none the most specific other claim does, or nothing when the General row says Vanilla.
	private function Find(propertyId : int, pinType : string, pinTag : name, maxLevel : int, out result : SCMFClaim) : bool
	{
		var i, best, picked, choice : int;
		var matches : bool;
		var answer : string;
		best = -1;
		picked = -1;
		answer = "";
		if (choicesActive)
		{
			choice = PropertyChoice(propertyId, pinType);
			if (choice >= 0)
			{
				answer = decideAnswer[choice];
				if (answer == "vanilla")
				{
					return false;
				}
				if (answer == "@order")
				{
					answer = "";
				}
			}
		}
		for (i = 0; i < winners.Size(); i += 1)
		{
			matches = winners[i].propertyId == propertyId && winners[i].level <= maxLevel;
			if (matches && winners[i].level == 1)
			{
				matches = NameToString(winners[i].pinType) == pinType;
			}
			if (matches && winners[i].level == 2)
			{
				// Instance claims never reveal undiscovered "?" pins or restyle completed ("Disabled") ones.
				matches = winners[i].pinTag == pinTag && pinType != "NotDiscoveredPOI" && !StrEndsWith(pinType, "Disabled");
			}
			if (matches && (best < 0 || winners[i].level > winners[best].level))
			{
				best = i;
			}
			if (matches && answer != "" && winners[i].provider == answer &&
				(picked < 0 || winners[i].level > winners[picked].level))
			{
				picked = i;
			}
		}
		if (picked >= 0)
		{
			result = winners[picked];
			return true;
		}
		if (best < 0 || (answer != "" && fallVanilla))
		{
			return false;
		}
		result = winners[best];
		return true;
	}

	private function SameSlot(a : SCMFClaim, b : SCMFClaim) : bool
	{
		return a.propertyId == b.propertyId && a.level == b.level && a.pinType == b.pinType && a.pinTag == b.pinTag &&
			a.mapContext == b.mapContext;
	}

	// Earlier provider wins (ProviderBeats; version 8: PieceBeats for the claim's choice when a choice is set); then
	// registration order.
	private function Beats(a : SCMFClaim, b : SCMFClaim) : bool
	{
		if (a.provider != b.provider)
		{
			if (choicesActive)
			{
				return PieceBeats(PropertyChoice(a.propertyId, NameToString(a.pinType)), a.provider, b.provider);
			}
			return ProviderBeats(a.provider, b.provider);
		}
		return a.order < b.order;
	}

	// True when provider a comes before b: providers listed in the CMFProviderOrder setting come first, in
	// its order, ahead of every unlisted one; otherwise folder name ignoring case, then exact. The setting is
	// read when winners are prepared, so one map opening uses one order throughout. Arbitration only.
	// Version 8: the menu add-on's in-game Mod order comes before the setting, the same way.
	public function ProviderBeats(a : string, b : string) : bool
	{
		var rankA, rankB : int;
		var result : bool;
		if (OrderDecides(menuOrder, a, b, result))
		{
			return result;
		}
		rankA = CMFSettingsProviderRank(providerOrder, a);
		rankB = CMFSettingsProviderRank(providerOrder, b);
		if (rankA != rankB)
		{
			if (rankA < 0)
			{
				return false;
			}
			if (rankB < 0)
			{
				return true;
			}
			return rankA < rankB;
		}
		return CMFFolderBeats(a, b);
	}

	// Per-pin style (CMFStylePin). The winning provider is stored on the pin in an owner field, so the
	// result does not depend on which wrapper runs first; CMF's own writers skip owned properties.
	public function StylePin(provider : string, dataObject : CScriptedFlashObject, propertyId : int, text : string,
		number : int) : bool
	{
		var ownerField : string;
		var owner : string;
		var flags : int;
		var tabs : string;
		var choice : int;
		// Version 6: clicks, hints and buttons have their own rules (StyleClick).
		if (CMFIsClickProperty(propertyId))
		{
			return StyleClick(provider, dataObject, propertyId, text, number);
		}
		ownerField = CMFOwnerField(propertyId);
		if (ownerField == "")
		{
			NoteStyleRejected(provider, propertyId, "style");
			return false;
		}
		if (provider == "" || !dataObject ||
			((propertyId == CMFPropertyIcon() || propertyId == CMFPropertyLabelText()) && text == "") ||
			((propertyId == CMFPropertyLabelHide() || propertyId == CMFPropertyTabHide()) && number == 0))
		{
			NoteStyleRejected(provider, propertyId, "empty");
			return false;
		}
		// Version 4 slots: never the player marker or a user pin.
		if (propertyId >= CMFPropertyPinScale() &&
			(dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin")))
		{
			NoteStyleRejected(provider, propertyId, "user");
			return false;
		}
		if ((propertyId == CMFPropertyPinScale() && (number < 25 || number > 400)) ||
			(propertyId == CMFPropertyLabelPlace() && (number < 0 || number > 10000)) ||
			(propertyId == CMFPropertyLabelColor() && (number < 0 || number > 16777215)) ||
			(propertyId == CMFPropertySpreadRank() && (number < 0 || number > 1000)))
		{
			NoteStyleRejected(provider, propertyId, "range");
			return false;
		}
		if ((propertyId == CMFPropertyLabelHide() && !CMFParseLabelHide(text, flags)) ||
			(propertyId == CMFPropertyTabHide() && !CMFParseTabs(text, tabs)))
		{
			NoteStyleRejected(provider, propertyId, "text");
			return false;
		}
		// Version 8: the Hidden pins choice can leave a provider's hides out.
		if ((propertyId == CMFPropertyTabHide() || propertyId == CMFPropertyHidden()) && !AdditiveAllows(6, provider))
		{
			NoteStyleRejected(provider, propertyId, "choice");
			return false;
		}
		// Tab hides merge like hides: no loser.
		if (propertyId == CMFPropertyTabHide())
		{
			MergeTabHide(dataObject, provider, tabs);
			NoteStyledOffer(6, provider);
			return true;
		}
		// Hiding one pin: every hide applies, so there is no loser; the earlier folder is recorded.
		if (propertyId == CMFPropertyHidden())
		{
			if (text != "")
			{
				NoteStyleRejected(provider, propertyId, "text");
				return false;
			}
			if (dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin"))
			{
				NoteStyleRejected(provider, propertyId, "user");
				return false;
			}
			if (!listOpen)
			{
				NoteStyleRejected(provider, propertyId, "late");
				return false;
			}
			MarkHidden(dataObject, provider);
			NoteStyledOffer(6, provider);
			return true;
		}
		// Version 8: the piece's choice (StyleAllowed), then PieceBeats between two providers styling one pin.
		choice = PropertyChoice(propertyId, dataObject.GetMemberFlashString("type"));
		NoteStyledOffer(choice, provider);
		if (!StyleAllowed(choice, provider, dataObject, propertyId, ownerField))
		{
			NoteStyleRejected(provider, propertyId, "choice");
			return false;
		}
		owner = CMFPinOwner(dataObject, ownerField);
		if (owner != "" && owner != provider)
		{
			if (PieceBeats(choice, owner, provider))
			{
				NoteStyleShadow(provider, owner, dataObject, propertyId);
				return false;
			}
			NoteStyleShadow(owner, provider, dataObject, propertyId);
		}
		if (propertyId == CMFPropertyIcon())
		{
			dataObject.SetMemberFlashString("cmfIconPath", text);
		}
		else if (propertyId == CMFPropertyTint())
		{
			dataObject.SetMemberFlashUInt("cmfIconTint", number);
			dataObject.SetMemberFlashBool("cmfIconTintEnabled", true);
		}
		else if (propertyId == CMFPropertyLabelHide())
		{
			SetSlot(dataObject, propertyId, text, flags);
		}
		else
		{
			SetSlot(dataObject, propertyId, text, number);
		}
		dataObject.SetMemberFlashString(ownerField, provider);
		return true;
	}

	// CMFStylePin runs once per pin, so each rejection is logged once per provider, property and reason.
	private function NoteStyleRejected(provider : string, propertyId : int, reason : string)
	{
		var pinKey : string;
		pinKey = "reject:" + provider + "/" + propertyId + "/" + reason;
		if (seenPins.Size() < 64 && !seenPins.Contains(pinKey))
		{
			seenPins.PushBack(pinKey);
			CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=" + reason);
		}
	}

	// Logs each (losing provider, pin type, property) once, sharing the seenPins cap.
	private function NoteStyleShadow(loser : string, owner : string, dataObject : CScriptedFlashObject, propertyId : int)
	{
		var pinKey : string;
		var pinType : string;
		pinType = dataObject.GetMemberFlashString("type");
		pinKey = "style:" + loser + "/" + pinType + "/" + propertyId;
		if (seenPins.Size() < 64 && !seenPins.Contains(pinKey))
		{
			seenPins.PushBack(pinKey);
			CMFLog("style shadowed provider=" + loser + " by=" + owner + " property=" + propertyId + " type=" + pinType);
		}
	}

	// Version 6: pin clicks. One provider wins each pin's click: a per-pin claim (CMFStylePin) beats a tag claim,
	// which beats a type claim; at the same level the earlier provider (ProviderBeats), then registration order.
	// The hint and button text shown on a pin always come from the provider that won its click.

	// Click fields from tag and type claims (the pin's type, then its filteredType): the inputs, the winner and
	// its value, then that winner's own hint and button text. A click a provider styled on this pin is left alone.
	private function WriteClickFields(dataObject : CScriptedFlashObject, pinKey : string, legendKey : string,
		pinTag : name, maxLevel : int)
	{
		var claim : SCMFClaim;
		var flags : int;
		if (dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("cmfClickPin"))
		{
			return;
		}
		if (!Find(CMFPropertyPinClick(), pinKey, pinTag, maxLevel, claim) &&
			!Find(CMFPropertyPinClick(), legendKey, '', 1, claim))
		{
			return;
		}
		if (!CMFParsePinClick(claim.text, flags))
		{
			return;
		}
		flags = GameClickInputs(dataObject, claim.provider, flags);
		if (flags == 0)
		{
			return;
		}
		SetClick(dataObject, claim.provider, flags, claim.number);
		WriteClickText(dataObject, claim.provider, pinKey, legendKey, pinTag, maxLevel);
	}

	// The game keeps its own inputs: use and doubleClick are dropped on fast-travel and quest pins (logged once
	// per provider and pin type); button stays.
	private function GameClickInputs(dataObject : CScriptedFlashObject, provider : string, flags : int) : int
	{
		if (!dataObject.GetMemberFlashBool("isFastTravel") && !dataObject.GetMemberFlashBool("isQuest"))
		{
			return flags;
		}
		if (CMFHasFlag(flags, CMFClickInputUse()) || CMFHasFlag(flags, CMFClickInputDoubleClick()))
		{
			NoteClick("click refused provider=" + provider + " type=" + dataObject.GetMemberFlashString("type") +
				" reason=game");
		}
		if (CMFHasFlag(flags, CMFClickInputButton()))
		{
			return CMFClickInputButton();
		}
		return 0;
	}

	private function SetClick(dataObject : CScriptedFlashObject, provider : string, flags : int, value : int)
	{
		dataObject.SetMemberFlashString("cmfClick", CMFPinClickText(flags));
		dataObject.SetMemberFlashString("cmfClickBy", provider);
		dataObject.SetMemberFlashInt("cmfClickValue", value);
	}

	// The click winner's own hint and button text from its tag and type claims, unless it styled them on this
	// pin already.
	private function WriteClickText(dataObject : CScriptedFlashObject, provider : string, pinKey : string,
		legendKey : string, pinTag : name, maxLevel : int)
	{
		var claim : SCMFClaim;
		if (CMFPinOwner(dataObject, "cmfClickHintBy") != provider &&
			(FindOwn(CMFPropertyPinClickHint(), provider, pinKey, pinTag, maxLevel, claim) ||
			FindOwn(CMFPropertyPinClickHint(), provider, legendKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashString("cmfClickHint", claim.text);
			dataObject.SetMemberFlashString("cmfClickHintBy", provider);
		}
		if (CMFPinOwner(dataObject, "cmfClickButtonBy") != provider &&
			(FindOwn(CMFPropertyPinClickButton(), provider, pinKey, pinTag, maxLevel, claim) ||
			FindOwn(CMFPropertyPinClickButton(), provider, legendKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashString("cmfClickButton", claim.text);
			dataObject.SetMemberFlashString("cmfClickButtonBy", provider);
		}
	}

	// Most specific claim of one provider for this pin, then the earliest registered. Hints and buttons are not
	// arbitrated, so every one that is not withdrawn sits in winners.
	private function FindOwn(propertyId : int, provider : string, pinType : string, pinTag : name, maxLevel : int,
		out result : SCMFClaim) : bool
	{
		var i, best : int;
		var matches : bool;
		best = -1;
		for (i = 0; i < winners.Size(); i += 1)
		{
			matches = winners[i].propertyId == propertyId && winners[i].provider == provider && winners[i].level <= maxLevel;
			if (matches && winners[i].level == 1)
			{
				matches = NameToString(winners[i].pinType) == pinType;
			}
			if (matches && winners[i].level == 2)
			{
				matches = winners[i].pinTag == pinTag && pinType != "NotDiscoveredPOI" && !StrEndsWith(pinType, "Disabled");
			}
			if (matches && (best < 0 || winners[i].level > winners[best].level ||
				(winners[i].level == winners[best].level && winners[i].order < winners[best].order)))
			{
				best = i;
			}
		}
		if (best < 0)
		{
			return false;
		}
		result = winners[best];
		return true;
	}

	// CMFStylePin for ids 16, 20 and 21. A click styled on one pin beats tag and type claims there; between two
	// providers styling the same pin the earlier one wins. User pins accept clicks; the player marker never.
	// Another provider cannot replace the hint or button text of the click's winner.
	private function StyleClick(provider : string, dataObject : CScriptedFlashObject, propertyId : int, text : string,
		number : int) : bool
	{
		var owner : string;
		var flags : int;
		var field : string;
		if (provider == "" || !dataObject || text == "" || number == 0)
		{
			NoteStyleRejected(provider, propertyId, "empty");
			return false;
		}
		if (dataObject.GetMemberFlashBool("isPlayer"))
		{
			NoteStyleRejected(provider, propertyId, "player");
			return false;
		}
		if (propertyId != CMFPropertyPinClick())
		{
			field = "cmfClickHint";
			if (propertyId == CMFPropertyPinClickButton())
			{
				field = "cmfClickButton";
			}
			owner = CMFPinOwner(dataObject, field + "By");
			if (owner != "" && owner != provider && owner == CMFPinOwner(dataObject, "cmfClickBy"))
			{
				NoteStyleShadow(provider, owner, dataObject, propertyId);
				return false;
			}
			dataObject.SetMemberFlashString(field, text);
			dataObject.SetMemberFlashString(field + "By", provider);
			return true;
		}
		if (!CMFParsePinClick(text, flags))
		{
			NoteStyleRejected(provider, propertyId, "text");
			return false;
		}
		// Version 8: the Pin clicks choice.
		NoteStyledOffer(32, provider);
		if (!StyleAllowed(32, provider, dataObject, propertyId, "cmfClickBy"))
		{
			NoteStyleRejected(provider, propertyId, "choice");
			return false;
		}
		owner = CMFPinOwner(dataObject, "cmfClickBy");
		if (owner != "" && owner != provider)
		{
			if (dataObject.GetMemberFlashBool("cmfClickPin") && PieceBeats(32, owner, provider))
			{
				NoteClickShadow(provider, owner);
				return false;
			}
			NoteClickShadow(owner, provider);
		}
		flags = GameClickInputs(dataObject, provider, flags);
		if (flags == 0)
		{
			NoteStyleRejected(provider, propertyId, "game");
			return false;
		}
		SetClick(dataObject, provider, flags, number);
		dataObject.SetMemberFlashBool("cmfClickPin", true);
		WriteClickText(dataObject, provider, dataObject.GetMemberFlashString("type"),
			dataObject.GetMemberFlashString("filteredType"), '', 1);
		return true;
	}

	// A click claim that lost its slot in Prepare.
	private function ReportClickShadow(loser : SCMFClaim, winner : SCMFClaim)
	{
		if (loser.propertyId == CMFPropertyPinClick())
		{
			NoteClickShadow(loser.provider, winner.provider);
		}
	}

	private function NoteClickShadow(loser : string, winner : string)
	{
		if (loser != winner)
		{
			NoteClick("click shadowed provider=" + loser + " by=" + winner);
		}
	}

	// Logs one click line once per session (capped).
	private function NoteClick(line : string)
	{
		if (clickNotes.Size() < 64 && !clickNotes.Contains(line))
		{
			clickNotes.PushBack(line);
			CMFLog(line);
		}
	}

	// Called by the map panel (OnCMFPinClicked) once per click on a pin whose click a provider won: logs it and
	// hands it to OnPinClicked. pinTag is the pin's tag for engine pins and pins pushed with
	// NameToFlashUInt(tag); pinId is the raw id (a placed pin's tag is None: its id is no name).
	public function PinClicked(menu : CR4MapMenu, pinTag : name, pinId : int, provider : string, pinType : string,
		input : string, value : int)
	{
		if (provider == "" || (input != "use" && input != "doubleClick" && input != "button"))
		{
			return;
		}
		CMFLog("click provider=" + provider + " input=" + input + " type=" + pinType + " pin=" + pinId + " tag=" +
			NameToString(pinTag) + " value=" + value);
		OnPinClicked(menu, provider, pinTag, pinId, pinType, input, value);
	}

	// Version 6 hook, called once per click a provider won (PinClick). It does nothing and logs
	// "click provider= pin= reason=nohandler": the winning provider wraps it (@wrapMethod(CMFCore)), acts when
	// provider is its own id and returns true, and otherwise returns wrappedMethod(...). Each wrapper tests its
	// own provider id, so wrapper order never matters. input is "use", "doubleClick" or "button"; value is the
	// claim's number.
	public function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string,
		input : string, value : int) : bool
	{
		CMFLog("click provider=" + provider + " pin=" + pinId + " reason=nohandler");
		return false;
	}

	// Map-space drawing: called by the map panel (OnCMFDrawingClicked) once per click on a drawing whose click
	// key is 1 or more (value). Logs it and hands it to OnDrawingClicked for the drawing's owner (the earliest
	// folder that made the id).
	public function DrawingClicked(menu : CR4MapMenu, id : string, value : int)
	{
		var i : int;
		var owner : string;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && NameToString(themeEntries[i].target) == id)
			{
				owner = ThemeDrawingOwner(themeEntries[i].target);
				if (owner == themeEntries[i].provider)
				{
					CMFLog("drawing click provider=" + owner + " id=" + id + " value=" + value);
					OnDrawingClicked(menu, owner, themeEntries[i].target, "click", value);
					return;
				}
			}
		}
	}

	// Version 6 hook (map-space drawing), the drawing half of pin clicks, in the same shape as OnPinClicked:
	// called once per click on a drawing whose key click is 1 or more, for the provider that owns the drawing
	// id, with input "click" (mouse only) and value = the drawing's click number (so one handler can tell its
	// buttons apart). It does nothing and logs "drawing click provider= id= reason=nohandler": the owner wraps
	// it (@wrapMethod(CMFCore)), acts when provider is its own id and returns true, and otherwise returns
	// wrappedMethod(...).
	public function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
	{
		CMFLog("drawing click provider=" + provider + " id=" + NameToString(id) + " value=" + value + " reason=nohandler");
		return false;
	}

	// Map-space drawing: called by the map panel (OnCMFListenReady) when it starts listening to storage keys that
	// drawings named with listen (the theme's and the map-space ones), keys joined by "|". Logs it and runs the
	// OnMapListening hook.
	public function ListenReady(menu : CR4MapMenu, keys : string)
	{
		CMFLog("listen ready keys=" + keys);
		OnMapListening(menu, keys);
	}

	// Version 6 hook (map-space drawing): the map only receives a value written to a listened key after it starts
	// listening, and it starts once per opening, after the game's own OnConfigUI and after the first map build. A
	// mod that wrote its value earlier wraps this (@wrapMethod(CMFCore)), calls wrappedMethod(menu, keys), and
	// writes the value again when keys contains its key. keys holds only the keys the map started listening to
	// in this call, joined by "|". It does nothing by itself.
	public function OnMapListening(menu : CR4MapMenu, keys : string)
	{
	}

	// Version 9 (CMFRegisterChoiceOnly): stores one provider's choice-only choice. False (logged) for an unknown key.
	public function RegisterChoiceOnly(provider : string, choiceKey : string) : bool
	{
		var i, choice : int;
		EnsureChoices();
		choice = choiceKeys.FindFirst(choiceKey);
		if (provider == "" || choice < 0)
		{
			CMFLog("choice only rejected provider=" + provider + " key=" + choiceKey + " reason=key");
			return false;
		}
		for (i = 0; i < choiceOnlyProviders.Size(); i += 1)
		{
			if (choiceOnlyProviders[i] == provider && choiceOnlyChoices[i] == choice)
			{
				CMFLog("choice only provider=" + provider + " key=" + choiceKey);
				return true;
			}
		}
		choiceOnlyProviders.PushBack(provider);
		choiceOnlyChoices.PushBack(choice);
		dirty = true;
		CMFLog("choice only provider=" + provider + " key=" + choiceKey);
		return true;
	}

	// Version 9: true when this provider's claim, part style or opening view for choice `choice` waits: the provider
	// made the choice or its feature choice-only, and no in-game or file row of the choice or its feature picks it.
	private function ChoiceOnlySkips(choice : int, provider : string) : bool
	{
		var i, feature : int;
		var listed : bool;
		if (choice < 0 || choiceOnlyProviders.Size() == 0)
		{
			return false;
		}
		EnsureChoices();
		if (choice >= choiceKeys.Size())
		{
			return false;
		}
		feature = choiceFeature[choice];
		listed = false;
		for (i = 0; i < choiceOnlyProviders.Size() && !listed; i += 1)
		{
			listed = choiceOnlyProviders[i] == provider && (choiceOnlyChoices[i] == choice || choiceOnlyChoices[i] == feature);
		}
		if (!listed)
		{
			return false;
		}
		return menuChoices[choice] != provider && menuChoices[feature] != provider && fileChoices[choice] != provider &&
			fileChoices[feature] != provider;
	}

	// Version 9 (CMFSetOpeningView): stores, replaces or withdraws one provider's opening view for one area.
	public function SetOpeningView(provider : string, area : name, x : float, y : float, zoom : float,
		keepPlace : bool) : bool
	{
		return StoreOpeningView(provider, area, x, y, zoom, keepPlace, false);
	}

	// Version 9 (CMFSetOpeningWorld): the same with the place in world coordinates; it replaces either kind.
	public function SetOpeningWorld(provider : string, area : name, worldX : float, worldY : float,
		zoom : float) : bool
	{
		return StoreOpeningView(provider, area, worldX, worldY, zoom, false, true);
	}

	private function StoreOpeningView(provider : string, area : name, x : float, y : float, zoom : float,
		keepPlace : bool, worldPlace : bool) : bool
	{
		var view : SCMFOpeningView;
		var i : int;
		var hadAny : bool;
		if (provider == "")
		{
			CMFLog("opening view rejected provider= area=" + NameToString(area) + " reason=empty");
			return false;
		}
		hadAny = HasOpeningView(provider);
		for (i = openingViews.Size() - 1; i >= 0; i -= 1)
		{
			if (openingViews[i].provider == provider && openingViews[i].area == area)
			{
				openingViews.Erase(i);
			}
		}
		if (!keepPlace || zoom > 0)
		{
			view.provider = provider;
			view.area = area;
			view.x = x;
			view.y = y;
			view.zoom = zoom;
			view.keepPlace = keepPlace;
			view.worldPlace = worldPlace;
			openingViews.PushBack(view);
		}
		// The menu's Opening view row lists the provider from the next preparation.
		if (hadAny != HasOpeningView(provider))
		{
			dirty = true;
		}
		return true;
	}

	private function HasOpeningView(provider : string) : bool
	{
		var i : int;
		for (i = 0; i < openingViews.Size(); i += 1)
		{
			if (openingViews[i].provider == provider)
			{
				return true;
			}
		}
		return false;
	}

	// Version 9: the opening view for the shown area, through Movement_View (61) as Find goes through a claim's
	// choice: Vanilla gives none; a chosen mod's view wins (its view for the area before its every-area view); else
	// a view for the area beats an every-area view, then PieceBeats decides between providers, or none when the
	// chosen mod has no view and the General row says Vanilla. Choice-only views wait until picked.
	private function OpeningViewWinner(area : name, out result : SCMFOpeningView) : bool
	{
		var i, best, picked : int;
		var answer : string;
		best = -1;
		picked = -1;
		answer = "";
		if (choicesActive)
		{
			answer = decideAnswer[61];
			if (answer == "vanilla")
			{
				return false;
			}
			if (answer == "@order")
			{
				answer = "";
			}
		}
		for (i = 0; i < openingViews.Size(); i += 1)
		{
			if ((IsNameValid(openingViews[i].area) && openingViews[i].area != area) ||
				ChoiceOnlySkips(61, openingViews[i].provider))
			{
				continue;
			}
			if (best < 0 || OpeningViewBeats(openingViews[i], openingViews[best]))
			{
				best = i;
			}
			if (answer != "" && openingViews[i].provider == answer &&
				(picked < 0 || IsNameValid(openingViews[i].area)))
			{
				picked = i;
			}
		}
		if (picked >= 0)
		{
			result = openingViews[picked];
			return true;
		}
		if (best < 0 || (answer != "" && fallVanilla))
		{
			return false;
		}
		result = openingViews[best];
		return true;
	}

	private function OpeningViewBeats(a : SCMFOpeningView, b : SCMFOpeningView) : bool
	{
		if (IsNameValid(a.area) != IsNameValid(b.area))
		{
			return IsNameValid(a.area);
		}
		return PieceBeats(61, a.provider, b.provider);
	}

	// Version 9 hook, called when CMF's map reports the region map's view: reason 'still' (the player panned or
	// zoomed and the map then stayed still), 'region' (the map is switching away from area: its last view) or
	// 'close' (the map is closing). area is the shown map area (m_shownArea, as the "CMF background area=" line
	// names it); x and y are the map's place in the units setDefaultPosition takes, worldX and worldY the centre of
	// the visible area in world metres, zoom the map's scale (the units of SetMapZooms). Only CMF's map reports. A
	// mod wraps it (@wrapMethod(CMFCore)) and calls wrappedMethod with every argument; it does nothing by itself.
	public function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float,
		zoom : float, reason : name)
	{
	}

	// Version 9 hook, called each time CMF's map shows a region map (the opening and every region switch), after the
	// game script sent that region's zoom limits. A mod may send the limits again through the game's own calls and
	// call CMFSetOpeningView here; the map applies the view after this returns. It does nothing by itself.
	public function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
	{
	}

	// Version 9: logs one view report and runs the OnMapView hook.
	public function MapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float,
		zoom : float, reason : name)
	{
		CMFLog("map view area=" + NameToString(area) + " reason=" + NameToString(reason) + " x=" + FloatToString(x) +
			" y=" + FloatToString(y) + " zoom=" + FloatToString(zoom));
		OnMapView(menu, area, x, y, worldX, worldY, zoom, reason);
	}

	// Version 9: runs the OnMapOpening hook, then writes the winning opening view for the shown area to the map as
	// "cmf.map.view": s (1 = a view, 0 = none), x, y, z (the zoom, 0 keeps the game's), k (1 = keep the map's
	// place) and w (1 = x and y are world coordinates).
	public function MapOpening(menu : CR4MapMenu, area : name, mapContext : name, storage : CScriptedFlashValueStorage)
	{
		var view : SCMFOpeningView;
		var item : CScriptedFlashObject;
		var found : bool;
		var shown, keep, inWorld : int;
		var provider : string;
		OnMapOpening(menu, area, mapContext);
		if (dirty)
		{
			Prepare();
		}
		found = OpeningViewWinner(area, view);
		shown = 0;
		keep = 0;
		inWorld = 0;
		provider = "none";
		if (found)
		{
			shown = 1;
			provider = view.provider;
			if (view.keepPlace)
			{
				keep = 1;
			}
			if (view.worldPlace)
			{
				inWorld = 1;
			}
		}
		if (storage)
		{
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("s", shown);
			item.SetMemberFlashNumber("x", view.x);
			item.SetMemberFlashNumber("y", view.y);
			item.SetMemberFlashNumber("z", view.zoom);
			item.SetMemberFlashInt("k", keep);
			item.SetMemberFlashInt("w", inWorld);
			storage.SetFlashObject("cmf.map.view", item);
		}
		CMFLog("map opening area=" + NameToString(area) + " context=" + NameToString(mapContext) + " view=" + provider +
			" x=" + FloatToString(view.x) + " y=" + FloatToString(view.y) + " zoom=" + FloatToString(view.zoom) +
			" keep=" + keep + " world=" + inWorld);
	}

	private function Report(kind : string, claim : SCMFClaim)
	{
		CMFLog(kind + " provider=" + claim.provider + " property=" + claim.propertyId + " level=" + claim.level +
			" type=" + NameToString(claim.pinType) + " tag=" + NameToString(claim.pinTag) + " context=" + NameToString(claim.mapContext));
	}
}

function CMFYesNo(value : bool) : string
{
	if (value)
	{
		return "yes";
	}
	return "no";
}

function CMFLog(message : string)
{
	LogChannel('CMF', "CMF " + message);
}

// True when provider a comes before b in CMF's provider order (CMFCore.ProviderBeats).
function CMFProviderBeats(a : string, b : string) : bool
{
	return theGame.CMFGetCore().ProviderBeats(a, b);
}

// True when provider a sorts before b by folder name: ignoring case, then exact.
function CMFFolderBeats(a : string, b : string) : bool
{
	var compared : int;
	compared = StrCmp(StrLower(a), StrLower(b));
	if (compared == 0)
	{
		compared = StrCmp(a, b);
	}
	return compared < 0;
}

// Tab order of two category claims: number, then id ignoring case, then id exactly.
function CMFCategoryBefore(a : SCMFClaim, b : SCMFClaim) : bool
{
	var compared : int;
	if (a.number != b.number)
	{
		return a.number < b.number;
	}
	compared = StrCmp(StrLower(NameToString(a.pinType)), StrLower(NameToString(b.pinType)));
	if (compared == 0)
	{
		compared = StrCmp(NameToString(a.pinType), NameToString(b.pinType));
	}
	return compared < 0;
}

// The provider that styled this property of the pin with CMFStylePin, or "".
function CMFPinOwner(dataObject : CScriptedFlashObject, ownerField : string) : string
{
	var owner : string;
	owner = dataObject.GetMemberFlashString(ownerField);
	if (owner == "undefined" || owner == "null")
	{
		return "";
	}
	return owner;
}

@addField(CR4Game)
var cmfCore : CMFCore;

@addMethod(CR4Game)
public function CMFGetCore() : CMFCore
{
	if (!cmfCore)
	{
		cmfCore = new CMFCore in this;
	}
	return cmfCore;
}

// Provider API. CMFRegister and CMFRegisterForTag are the generic entries: a property id
// (CMFProperty* above, or a literal for ids a newer CMF adds) plus target, context, text and number.
// A pack that uses only these and CMFHasProperty compiles against any CMF since 1, and skips what it
// lacks. The named calls below are conveniences over them; version 2 calls need CMFRequireVersion(p, 2).

// True when this CMF understands the property id. Test an id before registering it.
function CMFHasProperty(propertyId : int) : bool
{
	return (propertyId >= CMFPropertyIcon() && propertyId <= CMFPropertyTabHide()) || propertyId == CMFPropertyLabelColor() ||
		propertyId == CMFPropertyCategoryNoDefault() || CMFIsPictureProperty(propertyId) ||
		propertyId == CMFPropertySpreadRank() || CMFIsClickProperty(propertyId);
}

// One pin type (a map area for CMFPropertyBackground, a filteredType for the legend row and label, a
// category id for CMFPropertyLegendCategory). text: image URL, background root, row category, label or
// tab name, or for CMFPropertyHidden exemption keys; number: tint 0xRRGGBB, row or tab priority, or for
// CMFPropertyDisabled and CMFPropertyHidden nonzero to apply and 0 to withdraw. mapContext ('FastTravel',
// 'Boat', 'GlobalMap', or '' for every context) applies to CMFPropertyDisabled and CMFPropertyHidden only.
// For CMFPropertyHidden an empty target ('') means every pin. Version 4: CMFPropertyPinScale number = percent
// (25-400), CMFPropertyLabelPlace number = tenths of a pin unit from the pin centre (0 = the game's place),
// CMFPropertyLabelText text = the label (HTML as the game's labels), CMFPropertyLabelHide text = "pin",
// "crosshair" or both and number nonzero (0 withdraws), CMFPropertyInfoBoxHeight target '' and number = the
// info box's text height in px (100-1080, 0 withdraws), CMFPropertyTabHide text = filter tab names
// ("Quests", "Exploration", "NPCs", "Buffs" or a tab id) and number nonzero, target '' for every pin.
// Version 5: CMFPropertyLabelColor number = the label's colour 0xRRGGBB. Version 6: CMFPropertyPinClick text =
// the inputs ("use", "doubleClick", "button") and number = the value handed back with each click (nonzero, 0
// withdraws); CMFPropertyPinClickHint and CMFPropertyPinClickButton text = the words to show, number nonzero (0
// withdraws). A click claim on a user pin type reaches the pins the player places. CMFPropertySpreadRank number =
// the pin's rank in a spread stack (0-1000, highest selected first). CMFPropertyCategoryNoDefault target = a CMF
// category id and number nonzero: that tab's rows stay out of Default (0 withdraws). Version 9: the picture
// properties (24 to 27) take the target their property names, text = the picture's url ("" withdraws) and number 0,
// or for CMFPropertyWorldPainting columns * 10 + rows of a tile url.
// Returns false and logs when the claim is not accepted.
function CMFRegister(provider : string, propertyId : int, target : name, mapContext : name, text : string,
	number : int) : bool
{
	var claim : SCMFClaim;
	if (!CMFHasProperty(propertyId))
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=unknown");
		return false;
	}
	if (IsNameValid(mapContext) && propertyId != CMFPropertyDisabled() && propertyId != CMFPropertyHidden())
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=context");
		return false;
	}
	claim.provider = provider;
	claim.propertyId = propertyId;
	claim.level = 1;
	if ((propertyId == CMFPropertyHidden() || propertyId == CMFPropertyInfoBoxHeight() ||
		propertyId == CMFPropertyTabHide()) && !IsNameValid(target))
	{
		claim.level = 0;
	}
	claim.pinType = target;
	claim.mapContext = mapContext;
	claim.text = text;
	claim.number = number;
	if ((propertyId == CMFPropertyDisabled() || propertyId == CMFPropertyCategoryNoDefault()) && number != 0)
	{
		claim.number = 1;
	}
	return theGame.CMFGetCore().Upsert(claim);
}

// One pin instance by its map pin tag; beats type-level claims on that pin. Accepts CMFPropertyIcon,
// CMFPropertyDisabled, CMFPropertyHidden, (version 4) ids 10-13 and 15, (version 5) id 17 and (version 6) ids 16,
// 20, 21 and 22. The game's own pins carry
// their tag. A pin a mod pushes itself is reached when that mod sets the pin's id to
// NameToFlashUInt(its tag), as the game does (version 4), so any mod can target another mod's pins by tag. Icon, disabled, size and label
// instance claims never apply to undiscovered "?" pins or completed pins; a hide claim covers its pin in
// every state.
function CMFRegisterForTag(provider : string, propertyId : int, pinTag : name, mapContext : name, text : string,
	number : int) : bool
{
	var claim : SCMFClaim;
	if (propertyId != CMFPropertyIcon() && propertyId != CMFPropertyDisabled() && propertyId != CMFPropertyHidden() &&
		(propertyId < CMFPropertyPinScale() || propertyId > CMFPropertyTabHide() || propertyId == CMFPropertyInfoBoxHeight()) &&
		propertyId != CMFPropertyLabelColor() && !CMFIsClickProperty(propertyId) && propertyId != CMFPropertySpreadRank())
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=level");
		return false;
	}
	if (IsNameValid(mapContext) && propertyId != CMFPropertyDisabled() && propertyId != CMFPropertyHidden())
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=context");
		return false;
	}
	claim.provider = provider;
	claim.propertyId = propertyId;
	claim.level = 2;
	claim.pinTag = pinTag;
	claim.mapContext = mapContext;
	claim.text = text;
	claim.number = number;
	if (propertyId == CMFPropertyDisabled() && number != 0)
	{
		claim.number = 1;
	}
	return theGame.CMFGetCore().Upsert(claim);
}

function CMFRegisterIcon(provider : string, pinType : name, url : string)
{
	CMFRegister(provider, CMFPropertyIcon(), pinType, '', url, 0);
}

// Icon for one pin instance, identified by its map pin tag; beats type-level icons on that pin only.
function CMFRegisterIconForTag(provider : string, pinTag : name, url : string)
{
	CMFRegisterForTag(provider, CMFPropertyIcon(), pinTag, '', url, 0);
}

function CMFRegisterLegendIcon(provider : string, pinType : name, url : string)
{
	CMFRegister(provider, CMFPropertyLegendIcon(), pinType, '', url, 0);
}

function CMFRegisterTint(provider : string, pinType : name, rgb : int)
{
	CMFRegister(provider, CMFPropertyTint(), pinType, '', "", rgb);
}

// Replaces the full-screen map's image root for one area, named as in the "CMF background area=" log
// line (for example 'AN_NMLandNovigrad'). The pack's texture.cache holds
// gameplay\gui_new\maps\<imageRoot>\level<L>\tile<X>x<Y>.jpg for level 0 and the area's minLod..maxLod,
// each tile textureSize pixels square; that log line reports both. Map geometry and pins stay vanilla.
function CMFRegisterBackground(provider : string, area : name, imageRoot : string)
{
	CMFRegister(provider, CMFPropertyBackground(), area, '', imageRoot, 0);
}

// Shows one pin type with CMF's disabled appearance (greyed, still selectable) in one map context:
// 'FastTravel' (opened from a signpost or exit), 'Boat', 'GlobalMap', or '' for every context.
// Appearance only: CMF never changes travel rules or the game's own pin disable. Call again with
// disable=false to withdraw; the change shows the next time the map opens.
function CMFRegisterDisabled(provider : string, pinType : name, mapContext : name, disable : bool)
{
	var number : int;
	number = 0;
	if (disable)
	{
		number = 1;
	}
	CMFRegister(provider, CMFPropertyDisabled(), pinType, mapContext, "", number);
}

// The same for one pin instance (its map pin tag); beats type-level disabled claims on that pin.
function CMFRegisterDisabledForTag(provider : string, pinTag : name, mapContext : name, disable : bool)
{
	var number : int;
	number = 0;
	if (disable)
	{
		number = 1;
	}
	CMFRegisterForTag(provider, CMFPropertyDisabled(), pinTag, mapContext, "", number);
}

// Version 2. Places a legend row (every pin sharing this filteredType) in a category tab: a vanilla
// category ('General', 'Quests', 'Exploration', 'NPCs', 'Buffs'), one declared with
// CMFRegisterLegendCategory, or '' for All only. priority orders rows inside the tab; 0 puts the row
// after every vanilla row. Rows the vanilla legend defines keep their vanilla place.
function CMFRegisterLegendRow(provider : string, filteredType : name, category : name, priority : int)
{
	CMFRegister(provider, CMFPropertyLegendRow(), filteredType, '', NameToString(category), priority);
}

// Version 2. Names a legend row: "[[string_key]]" from the pack's own w3strings, or plain text.
function CMFRegisterLegendLabel(provider : string, filteredType : name, label : string)
{
	CMFRegister(provider, CMFPropertyLegendLabel(), filteredType, '', label, 0);
}

// Version 2. Declares a filter tab after the vanilla tabs. category is a new id (prefix it with your
// pack's name), never a vanilla category; label is "[[string_key]]" or plain text; priority orders
// CMF tabs (low first). A declared tab with no rows does not appear.
function CMFRegisterLegendCategory(provider : string, category : name, label : string, priority : int)
{
	CMFRegister(provider, CMFPropertyLegendCategory(), category, '', label, priority);
}

// Version 6. Keeps the rows of a CMF tab out of Default (noDefault true), or lists them there again (false).
function CMFRegisterCategoryNoDefault(provider : string, category : name, noDefault : bool)
{
	var number : int;
	number = 0;
	if (noDefault)
	{
		number = 1;
	}
	CMFRegister(provider, CMFPropertyCategoryNoDefault(), category, '', "", number);
}

// Version 2. Styles one pin for this map opening. Call it on the pin object before the map sends the
// array: in an AddPinTypeData, UpdateEntityPins or UpdateUserMapPins wrapper, or right after creating
// your own StaticMapPinData object. propertyId: CMFPropertyIcon (text = image URL, or "frame:<label>" for
// a frame of the game's pin icon), CMFPropertyTint (number = 0xRRGGBB), CMFPropertyHidden, or (version 4)
// ids 10-13 and 15, (version 5) id 17 and (version 6) ids 16, 20 and 21 with the values CMFRegister takes; a click
// styled on one pin beats tag and type claims there, and user pins accept clicks. Returns true when this provider's value is now on the pin, false when an earlier
// provider (folder order) already styled that property of this pin or the property is not accepted
// (logged). The followed-quest gold rule does not apply: read "tracked" and "highlighted" yourself.
function CMFStylePin(provider : string, dataObject : CScriptedFlashObject, propertyId : int, text : string,
	number : int) : bool
{
	return theGame.CMFGetCore().StylePin(provider, dataObject, propertyId, text, number);
}

function CMFStylePinIcon(provider : string, dataObject : CScriptedFlashObject, url : string) : bool
{
	return CMFStylePin(provider, dataObject, CMFPropertyIcon(), url, 0);
}

function CMFStylePinTint(provider : string, dataObject : CScriptedFlashObject, rgb : int) : bool
{
	return CMFStylePin(provider, dataObject, CMFPropertyTint(), "", rgb);
}

// Version 4. Size of one pin for this map opening, in percent of the game's size (25-400). Same rules as
// CMFStylePin; the player marker and user pins are never resized.
function CMFStylePinScale(provider : string, dataObject : CScriptedFlashObject, percent : int) : bool
{
	return CMFStylePin(provider, dataObject, CMFPropertyPinScale(), "", percent);
}

// Version 4. Label of one pin for this map opening (HTML as the game's labels). Same rules as CMFStylePin.
function CMFStylePinLabel(provider : string, dataObject : CScriptedFlashObject, html : string) : bool
{
	return CMFStylePin(provider, dataObject, CMFPropertyLabelText(), html, 0);
}

// Version 4. A level label as the game's journal draws quest levels: CMF's localized "Lv" (string
// cmf_map_level_prefix; the bare number when it is missing) in the journal's colour for the difficulty
// (0 or less grey, 1 white, 2 orange, 3 or more red; vanilla journalQuestMenu.ws 599-602). Pass the result
// to CMFStylePinLabel or a LabelText claim.
function CMFLevelLabel(level : int, difficulty : int) : string
{
	var color : string;
	var prefix : string;
	color = "#ffffff";
	if (difficulty <= 0)
	{
		color = "#969696";
	}
	else if (difficulty == 2)
	{
		color = "#d68f29";
	}
	else if (difficulty >= 3)
	{
		color = "#d61010";
	}
	prefix = GetLocStringByKeyExt("cmf_map_level_prefix");
	if (StrLen(prefix) > 0 && !StrBeginsWith(prefix, "#"))
	{
		return "<font color='" + color + "'>" + prefix + " " + level + "</font>";
	}
	return "<font color='" + color + "'>" + level + "</font>";
}

// Version 3. Hides every pin of one type or filteredType ('' = every pin) in one map context
// ('' = every context). exemptions: "" or any of "tracked", "quest", "fasttravel", separated by commas or
// spaces. hide=false withdraws the claim. A hide beats every other claim on the pin; the player marker
// and user pins are never hidden. Takes effect the next time the map builds its pin list. Version 9: pinType
// 'Player' hides the player marker in that context (exemptions do not apply to it); user pins stay.
function CMFRegisterHidden(provider : string, pinType : name, mapContext : name, exemptions : string, hide : bool)
{
	var number : int;
	number = 0;
	if (hide)
	{
		number = 1;
	}
	CMFRegister(provider, CMFPropertyHidden(), pinType, mapContext, exemptions, number);
}

// Version 3. The same for one pin instance, by its map pin tag.
function CMFRegisterHiddenForTag(provider : string, pinTag : name, mapContext : name, exemptions : string, hide : bool)
{
	var number : int;
	number = 0;
	if (hide)
	{
		number = 1;
	}
	CMFRegisterForTag(provider, CMFPropertyHidden(), pinTag, mapContext, exemptions, number);
}

// Version 9. The world overview's painting as one picture (an image url, as pin art takes); url "" withdraws.
function CMFRegisterWorldPainting(provider : string, url : string) : bool
{
	return CMFRegister(provider, CMFPropertyWorldPainting(), 'painting', '', url, 0);
}

// Version 9. The painting as columns x rows tiles (each 1 to 8): url holds {x} and {y}, which the map replaces
// with each tile's column and row. Anything else is logged and refused.
function CMFRegisterWorldPaintingTiles(provider : string, url : string, columns : int, rows : int) : bool
{
	if (columns < 1 || columns > 8 || rows < 1 || rows > 8)
	{
		CMFLog("rejected provider=" + provider + " property=" + CMFPropertyWorldPainting() + " reason=range");
		return false;
	}
	return CMFRegister(provider, CMFPropertyWorldPainting(), 'painting', '', url, columns * 10 + rows);
}

// Version 9. One region's crest on the world overview, by its overview name ('kaer_morhen', 'skellige',
// 'novigrad', 'no_mans_land', 'prolog_village', 'wyzima_castle', 'bob', or a region another mod adds).
function CMFRegisterWorldCrest(provider : string, region : name, url : string) : bool
{
	return CMFRegister(provider, CMFPropertyWorldCrest(), region, '', url, 0);
}

// Version 9. The world overview's player ('player') or quest ('quest') marker.
function CMFRegisterWorldMarker(provider : string, marker : name, url : string) : bool
{
	return CMFRegister(provider, CMFPropertyWorldMarker(), marker, '', url, 0);
}

// Version 9: the button picture slot for a family and the map's button name, a name literal per pair since the game
// has no text-to-name call and a name literal holds only letters, digits and _: 'xbox_gamepad_Y', and the map's
// dashed names with _ ('xbox_enter_gamepad_A'). None for a family or button the map does not have.
function CMFButtonTarget(family : name, button : string) : name
{
	switch (family)
	{
		case 'xbox':
			if (button == "gamepad_X") { return 'xbox_gamepad_X'; }
			else if (button == "enter-gamepad_A") { return 'xbox_enter_gamepad_A'; }
			else if (button == "escape-gamepad_B") { return 'xbox_escape_gamepad_B'; }
			else if (button == "gamepad_Y") { return 'xbox_gamepad_Y'; }
			else if (button == "gamepad_L1") { return 'xbox_gamepad_L1'; }
			else if (button == "gamepad_R1") { return 'xbox_gamepad_R1'; }
			else if (button == "gamepad_L2") { return 'xbox_gamepad_L2'; }
			else if (button == "gamepad_R2") { return 'xbox_gamepad_R2'; }
			else if (button == "gamepad_L3") { return 'xbox_gamepad_L3'; }
			else if (button == "gamepad_R3") { return 'xbox_gamepad_R3'; }
			else if (button == "gamepad_RTLT") { return 'xbox_gamepad_RTLT'; }
			else if (button == "gamepad_RBLB") { return 'xbox_gamepad_RBLB'; }
			else if (button == "dpad_up") { return 'xbox_dpad_up'; }
			else if (button == "double_dpad_up") { return 'xbox_double_dpad_up'; }
			else if (button == "dpad_down") { return 'xbox_dpad_down'; }
			else if (button == "dpad_right") { return 'xbox_dpad_right'; }
			else if (button == "dpad_left") { return 'xbox_dpad_left'; }
			else if (button == "gamepad_dpad_lr") { return 'xbox_gamepad_dpad_lr'; }
			else if (button == "start") { return 'xbox_start'; }
			else if (button == "back") { return 'xbox_back'; }
			else if (button == "gamepad_R_Tab") { return 'xbox_gamepad_R_Tab'; }
			else if (button == "gamepad_R_Scroll") { return 'xbox_gamepad_R_Scroll'; }
			else if (button == "gamepad_L_Hold") { return 'xbox_gamepad_L_Hold'; }
			else if (button == "gamepad_R_Hold") { return 'xbox_gamepad_R_Hold'; }
			else if (button == "gamepad_L_Tab") { return 'xbox_gamepad_L_Tab'; }
			else if (button == "gamepad_L_Scroll") { return 'xbox_gamepad_L_Scroll'; }
			else if (button == "gamepad_R_down") { return 'xbox_gamepad_R_down'; }
			else if (button == "gamepad_dpad_up_down") { return 'xbox_gamepad_dpad_up_down'; }
			else if (button == "gamepad_dpad_all") { return 'xbox_gamepad_dpad_all'; }
			break;
		case 'ps4':
			if (button == "gamepad_X") { return 'ps4_gamepad_X'; }
			else if (button == "enter-gamepad_A") { return 'ps4_enter_gamepad_A'; }
			else if (button == "escape-gamepad_B") { return 'ps4_escape_gamepad_B'; }
			else if (button == "gamepad_Y") { return 'ps4_gamepad_Y'; }
			else if (button == "gamepad_L1") { return 'ps4_gamepad_L1'; }
			else if (button == "gamepad_R1") { return 'ps4_gamepad_R1'; }
			else if (button == "gamepad_L2") { return 'ps4_gamepad_L2'; }
			else if (button == "gamepad_R2") { return 'ps4_gamepad_R2'; }
			else if (button == "gamepad_L3") { return 'ps4_gamepad_L3'; }
			else if (button == "gamepad_R3") { return 'ps4_gamepad_R3'; }
			else if (button == "gamepad_RTLT") { return 'ps4_gamepad_RTLT'; }
			else if (button == "gamepad_RBLB") { return 'ps4_gamepad_RBLB'; }
			else if (button == "dpad_up") { return 'ps4_dpad_up'; }
			else if (button == "double_dpad_up") { return 'ps4_double_dpad_up'; }
			else if (button == "dpad_down") { return 'ps4_dpad_down'; }
			else if (button == "dpad_right") { return 'ps4_dpad_right'; }
			else if (button == "dpad_left") { return 'ps4_dpad_left'; }
			else if (button == "gamepad_dpad_lr") { return 'ps4_gamepad_dpad_lr'; }
			else if (button == "start") { return 'ps4_start'; }
			else if (button == "back") { return 'ps4_back'; }
			else if (button == "gamepad_R_Tab") { return 'ps4_gamepad_R_Tab'; }
			else if (button == "gamepad_R_Scroll") { return 'ps4_gamepad_R_Scroll'; }
			else if (button == "gamepad_L_Hold") { return 'ps4_gamepad_L_Hold'; }
			else if (button == "gamepad_R_Hold") { return 'ps4_gamepad_R_Hold'; }
			else if (button == "gamepad_L_Tab") { return 'ps4_gamepad_L_Tab'; }
			else if (button == "gamepad_L_Scroll") { return 'ps4_gamepad_L_Scroll'; }
			else if (button == "gamepad_R_down") { return 'ps4_gamepad_R_down'; }
			else if (button == "gamepad_dpad_up_down") { return 'ps4_gamepad_dpad_up_down'; }
			else if (button == "gamepad_dpad_all") { return 'ps4_gamepad_dpad_all'; }
			break;
		case 'ps5':
			if (button == "gamepad_X") { return 'ps5_gamepad_X'; }
			else if (button == "enter-gamepad_A") { return 'ps5_enter_gamepad_A'; }
			else if (button == "escape-gamepad_B") { return 'ps5_escape_gamepad_B'; }
			else if (button == "gamepad_Y") { return 'ps5_gamepad_Y'; }
			else if (button == "gamepad_L1") { return 'ps5_gamepad_L1'; }
			else if (button == "gamepad_R1") { return 'ps5_gamepad_R1'; }
			else if (button == "gamepad_L2") { return 'ps5_gamepad_L2'; }
			else if (button == "gamepad_R2") { return 'ps5_gamepad_R2'; }
			else if (button == "gamepad_L3") { return 'ps5_gamepad_L3'; }
			else if (button == "gamepad_R3") { return 'ps5_gamepad_R3'; }
			else if (button == "gamepad_RTLT") { return 'ps5_gamepad_RTLT'; }
			else if (button == "gamepad_RBLB") { return 'ps5_gamepad_RBLB'; }
			else if (button == "dpad_up") { return 'ps5_dpad_up'; }
			else if (button == "double_dpad_up") { return 'ps5_double_dpad_up'; }
			else if (button == "dpad_down") { return 'ps5_dpad_down'; }
			else if (button == "dpad_right") { return 'ps5_dpad_right'; }
			else if (button == "dpad_left") { return 'ps5_dpad_left'; }
			else if (button == "gamepad_dpad_lr") { return 'ps5_gamepad_dpad_lr'; }
			else if (button == "start") { return 'ps5_start'; }
			else if (button == "back") { return 'ps5_back'; }
			else if (button == "gamepad_R_Tab") { return 'ps5_gamepad_R_Tab'; }
			else if (button == "gamepad_R_Scroll") { return 'ps5_gamepad_R_Scroll'; }
			else if (button == "gamepad_L_Hold") { return 'ps5_gamepad_L_Hold'; }
			else if (button == "gamepad_R_Hold") { return 'ps5_gamepad_R_Hold'; }
			else if (button == "gamepad_L_Tab") { return 'ps5_gamepad_L_Tab'; }
			else if (button == "gamepad_L_Scroll") { return 'ps5_gamepad_L_Scroll'; }
			else if (button == "gamepad_R_down") { return 'ps5_gamepad_R_down'; }
			else if (button == "gamepad_dpad_up_down") { return 'ps5_gamepad_dpad_up_down'; }
			else if (button == "gamepad_dpad_all") { return 'ps5_gamepad_dpad_all'; }
			break;
		case 'steam':
			if (button == "gamepad_X") { return 'steam_gamepad_X'; }
			else if (button == "enter-gamepad_A") { return 'steam_enter_gamepad_A'; }
			else if (button == "escape-gamepad_B") { return 'steam_escape_gamepad_B'; }
			else if (button == "gamepad_Y") { return 'steam_gamepad_Y'; }
			else if (button == "gamepad_L1") { return 'steam_gamepad_L1'; }
			else if (button == "gamepad_R1") { return 'steam_gamepad_R1'; }
			else if (button == "gamepad_L2") { return 'steam_gamepad_L2'; }
			else if (button == "gamepad_R2") { return 'steam_gamepad_R2'; }
			else if (button == "gamepad_L3") { return 'steam_gamepad_L3'; }
			else if (button == "gamepad_R3") { return 'steam_gamepad_R3'; }
			else if (button == "gamepad_RTLT") { return 'steam_gamepad_RTLT'; }
			else if (button == "gamepad_RBLB") { return 'steam_gamepad_RBLB'; }
			else if (button == "dpad_up") { return 'steam_dpad_up'; }
			else if (button == "double_dpad_up") { return 'steam_double_dpad_up'; }
			else if (button == "dpad_down") { return 'steam_dpad_down'; }
			else if (button == "dpad_right") { return 'steam_dpad_right'; }
			else if (button == "dpad_left") { return 'steam_dpad_left'; }
			else if (button == "gamepad_dpad_lr") { return 'steam_gamepad_dpad_lr'; }
			else if (button == "start") { return 'steam_start'; }
			else if (button == "back") { return 'steam_back'; }
			else if (button == "gamepad_R_Tab") { return 'steam_gamepad_R_Tab'; }
			else if (button == "gamepad_R_Scroll") { return 'steam_gamepad_R_Scroll'; }
			else if (button == "gamepad_L_Hold") { return 'steam_gamepad_L_Hold'; }
			else if (button == "gamepad_R_Hold") { return 'steam_gamepad_R_Hold'; }
			else if (button == "gamepad_L_Tab") { return 'steam_gamepad_L_Tab'; }
			else if (button == "gamepad_L_Scroll") { return 'steam_gamepad_L_Scroll'; }
			else if (button == "gamepad_R_down") { return 'steam_gamepad_R_down'; }
			break;
		case 'switch':
			if (button == "gamepad_X") { return 'switch_gamepad_X'; }
			else if (button == "enter-gamepad_A") { return 'switch_enter_gamepad_A'; }
			else if (button == "escape-gamepad_B") { return 'switch_escape_gamepad_B'; }
			else if (button == "gamepad_Y") { return 'switch_gamepad_Y'; }
			else if (button == "gamepad_L1") { return 'switch_gamepad_L1'; }
			else if (button == "gamepad_R1") { return 'switch_gamepad_R1'; }
			else if (button == "gamepad_L2") { return 'switch_gamepad_L2'; }
			else if (button == "gamepad_R2") { return 'switch_gamepad_R2'; }
			else if (button == "gamepad_L3") { return 'switch_gamepad_L3'; }
			else if (button == "gamepad_R3") { return 'switch_gamepad_R3'; }
			else if (button == "gamepad_RTLT") { return 'switch_gamepad_RTLT'; }
			else if (button == "gamepad_RBLB") { return 'switch_gamepad_RBLB'; }
			else if (button == "dpad_up") { return 'switch_dpad_up'; }
			else if (button == "double_dpad_up") { return 'switch_double_dpad_up'; }
			else if (button == "dpad_down") { return 'switch_dpad_down'; }
			else if (button == "dpad_right") { return 'switch_dpad_right'; }
			else if (button == "dpad_left") { return 'switch_dpad_left'; }
			else if (button == "gamepad_dpad_lr") { return 'switch_gamepad_dpad_lr'; }
			else if (button == "start") { return 'switch_start'; }
			else if (button == "back") { return 'switch_back'; }
			else if (button == "gamepad_R_Tab") { return 'switch_gamepad_R_Tab'; }
			else if (button == "gamepad_R_Scroll") { return 'switch_gamepad_R_Scroll'; }
			else if (button == "gamepad_L_Hold") { return 'switch_gamepad_L_Hold'; }
			else if (button == "gamepad_R_Hold") { return 'switch_gamepad_R_Hold'; }
			else if (button == "gamepad_L_Tab") { return 'switch_gamepad_L_Tab'; }
			else if (button == "gamepad_L_Scroll") { return 'switch_gamepad_L_Scroll'; }
			else if (button == "gamepad_R_down") { return 'switch_gamepad_R_down'; }
			else if (button == "gamepad_dpad_up_down") { return 'switch_gamepad_dpad_up_down'; }
			else if (button == "gamepad_dpad_all") { return 'switch_gamepad_dpad_all'; }
			break;
	}
	return '';
}

// Version 9: the panel's family:button text for a button picture slot ('xbox_enter_gamepad_A' -> xbox:enter-gamepad_A).
function CMFButtonPanelKey(target : string) : string
{
	var button : string;
	button = StrAfterFirst(target, "_");
	if (button == "enter_gamepad_A")
	{
		button = "enter-gamepad_A";
	}
	else if (button == "escape_gamepad_B")
	{
		button = "escape-gamepad_B";
	}
	return StrBeforeFirst(target, "_") + ":" + button;
}

// Version 9. A controller button's picture in the map's button bar: family 'xbox', 'ps4', 'ps5', 'steam' or
// 'switch', button the map's name for it as text (for example "gamepad_Y" or "enter-gamepad_A": text, since a name
// literal cannot hold a dash). A family or button the map does not have is logged and refused.
function CMFRegisterButtonPicture(provider : string, family : name, button : string, url : string) : bool
{
	var target : name;
	target = CMFButtonTarget(family, button);
	if (!IsNameValid(target))
	{
		CMFLog("button picture unknown family=" + NameToString(family) + " button=" + button + " provider=" + provider);
		return false;
	}
	return CMFRegister(provider, CMFPropertyButtonPicture(), target, '', url, 0);
}

// Version 9. Makes one choice (a CMFChoiceKeys key, such as "Painting_Crests"; a feature key covers its pieces)
// choice-only for this provider: its claims, part styles and opening views for that choice apply only while the
// in-game menu or a file setting picks it there. The menu still lists it. False (logged) for an unknown key.
function CMFRegisterChoiceOnly(provider : string, choiceKey : string) : bool
{
	return theGame.CMFGetCore().RegisterChoiceOnly(provider, choiceKey);
}

// Version 9. The view CMF's map opens a region map with: area as the "CMF background area=" line names it ('' =
// every area; a view for the area beats an every-area one), x and y the map's place in the units the game's
// setDefaultPosition takes, zoom the map's scale (clamped to the zoom limits in force; 0 or less keeps the game's),
// keepPlace true to keep the map's own place. A later call for the same area replaces the earlier one; keepPlace true
// with zoom 0 or less withdraws it. Call it in an OnMapOpening wrapper or earlier. The map applies it only when it
// opened on its usual place and the player has not moved it yet; an opening on a particular spot keeps the game's
// view. Answers the menu's Opening view row.
function CMFSetOpeningView(provider : string, area : name, x : float, y : float, zoom : float, keepPlace : bool) : bool
{
	return theGame.CMFGetCore().SetOpeningView(provider, area, x, y, zoom, keepPlace);
}

// Version 9. As CMFSetOpeningView, with the place in world coordinates (the units of a pin's position, for example
// thePlayer.GetWorldPosition().X and .Y): the region map opens centred there. zoom as for CMFSetOpeningView (0 or
// less keeps the game's). It replaces this provider's CMFSetOpeningView for the same area and the other way round;
// CMFSetOpeningView(provider, area, 0, 0, 0, true) withdraws either. Answers the menu's Opening view row.
function CMFSetOpeningWorld(provider : string, area : name, worldX : float, worldY : float, zoom : float) : bool
{
	return theGame.CMFGetCore().SetOpeningWorld(provider, area, worldX, worldY, zoom);
}

// Version 3. Hides this one pin for this map build. Call it in an AddPinTypeData or UpdateEntityPins
// wrapper, or on your own pin object before you push it. Returns false (logged) for the player marker, a
// user pin, or a call that comes after CMF has already sent the list.
function CMFHidePin(provider : string, dataObject : CScriptedFlashObject) : bool
{
	return CMFStylePin(provider, dataObject, CMFPropertyHidden(), "", 1);
}

// Returns false (and logs) when the installed CMF is older than the pack needs.
function CMFRequireVersion(provider : string, minVersion : int) : bool
{
	if (CMFGetVersion() >= minVersion)
	{
		return true;
	}
	CMFLog("version provider=" + provider + " needs=" + minVersion + " have=" + CMFGetVersion());
	return false;
}

function CMFReleaseProvider(provider : string)
{
	theGame.CMFGetCore().ReleaseProvider(provider);
}

// Version 8: the name CMF's in-game menu shows for a provider (for example "Ink and Iron"); without it the menu
// shows the folder name tidied (CMFTidyName). Call it once, where the provider registers its claims.
function CMFSetProviderName(provider : string, displayName : string) : bool
{
	if (provider == "" || displayName == "")
	{
		CMFLog("rejected provider=" + provider + " name=" + displayName + " reason=empty");
		return false;
	}
	theGame.CMFGetCore().SetProviderName(provider, displayName);
	return true;
}

// Version 8: a per-feature choice changed (the menu add-on calls it when a row changes): CMF prepares its winners
// again before the next lookup, so the map shows the new winners when it next opens and the minimap add-on
// follows on its next frame. Choices are read only while winners are prepared.
function CMFChoicesChanged()
{
	CMFLog("choices changed");
	theGame.CMFGetCore().RequestRefresh();
}

// Version 5: the map theme. Scripts cannot draw into the map: a mod describes what it wants with these calls,
// and CMF's map panel draws it with its own code once per map opening. Parts, layers and drawing kinds are the
// panel's fixed names; drawing ids are free (prefix them with your mod's name) and are anchors too, so one mod
// can tie a drawing to another mod's drawing. Every call returns false (and logs) for an unknown name or key
// or a value out of range, and CMF's map is unaffected. CMFReleaseProvider withdraws a provider's theme.
struct SCMFThemeEntry
{
	var provider : string;
	var kind : int;
	var target : name;
	var anchor : name;
	var key : name;
	var text : string;
	var number : float;
	var order : int;
	// Map-space drawing: a list key's values (kind 4, CMFDrawSetList).
	var values : array<float>;
}

// The map's parts (Stage 6b design 3.2, plus markerPanel and worldHint). pinLabel is a label above a pin
// (level tags and CMF label texts there); pinName is a name below a fast-travel pin; pinButton (version 6) is
// the button beside a pin whose click claims "button" (style keys only, no drawings). mapSpace (version 6) is
// the map itself in world coordinates: an anchor for line, text and movie drawings only (no style keys).
function CMFThemeParts() : string
{
	return "screen,map,mapEdge,title,tracker,legend,legendRow,legendTab,tooltip,preview,worldButton,worldHint,hints," +
		"keyCap,pinLabel,pinName,navigation,markerPanel,pinButton,mapSpace,opening,spread";
}

function CMFThemeLayers() : string
{
	return "under,over,belowMap,aboveMap,top";
}

function CMFThemeKinds() : string
{
	return "rect,ring,ellipse,polygon,band,line,text,movie";
}

// Map-space drawing: the hover look of a drawing that takes clicks (click 1 or more), while the pointer is over
// it; it applies to the drawing's box and its text together.
function CMFThemeHoverKeys() : string
{
	return "fillHover,alphaHover,strokeHover,strokeAlphaHover,strokeWidthHover,colorHover";
}

// Map-space drawing: the list keys a kind takes (CMFDrawSetList). A movie also takes any list key its
// author documents for the movie.
function CMFThemeListKeys(kind : name) : string
{
	if (kind == 'line')
	{
		return "xs,ys,starts,modes,colors";
	}
	return "";
}

function CMFThemeGlowKeys() : string
{
	return "glow1Color,glow1Alpha,glow1Blur,glow1Strength,glow2Color,glow2Alpha,glow2Blur,glow2Strength";
}

function CMFThemeShadowKeys() : string
{
	return "shadowDistance,shadowAngle,shadowColor,shadowAlpha,shadowBlur,shadowStrength";
}

function CMFThemeTextKeys() : string
{
	return "font,size,color,spacing,align," + CMFThemeGlowKeys();
}

// Smooth map movement (P6): the navigation keys added after version 5. If the frame-rate launch reads
// "frameRate asked=60 now=24", frameRate leaves this list and CMFHasAbility('navigation', 'frameRate') answers false.
function CMFThemeNavigationKeys() : string
{
	return "zoomTimed,padHoldMs,tweenEveryFrame,frameRate,zoomOutFit,edgeOvershoot";
}

// CMF's own movement (1.0.0): the value CMF sends for a navigation key no folder set (SendDefaultMotion).
// frameRate 60; frameTimed, zoomTimed and tweenEveryFrame 1. stepMs, worldStepMs and maxStepMs keep the game's
// 17, 24 and 100 ms, so the map moves at the game's speed.
function CMFDefaultNavigationValue(key : name) : float
{
	if (key == 'frameRate')
	{
		return 60;
	}
	return 1;
}

// Smooth map movement (P6): how the map opens and closes.
function CMFThemeOpeningKeys() : string
{
	return "slideSeconds,slideOffset,closeSeconds,pinsDuringSlide,pinStepMs,pinBatch,pinBudgetMs,showDelayMs," +
		"fadeSeconds,tileFadeSeconds,revealSeconds";
}

// Spreading stacked pins: pins on one spot fan out into a row when the cursor (or the controller crosshair)
// reaches them. on 1 turns it on; anyPin 1 lets any pin open a row (0: quest pins only); the rest are px and ms.
function CMFThemeSpreadKeys() : string
{
	return "on,anyPin,enterRadius,stackDistance,gap,maxPins,openMs,closeMs,lockRadius,keepRadius";
}

// The range of a spread key.
function CMFThemeSpreadValueOk(key : name, number : float) : bool
{
	switch (key)
	{
		case 'on':
		case 'anyPin':
			return number == 0 || number == 1;
		case 'maxPins':
			return number >= 2 && number <= 16;
		case 'openMs':
		case 'closeMs':
			return number >= 0 && number <= 2000;
		case 'gap':
			return number >= 8 && number <= 400;
	}
	return number >= 0 && number <= 400;
}

// Smooth map movement (P6): the range of a timing key on navigation or opening.
function CMFThemeMotionValueOk(key : name, number : float) : bool
{
	switch (key)
	{
		case 'zoomTimed':
		case 'tweenEveryFrame':
		case 'zoomOutFit':
		case 'pinsDuringSlide':
			return number == 0 || number == 1;
		case 'stepMs':
		case 'worldStepMs':
		case 'maxStepMs':
		case 'pinStepMs':
			return number >= 1 && number <= 1000;
		case 'padHoldMs':
		case 'pinBudgetMs':
			return number >= 0 && number <= 1000;
		case 'showDelayMs':
			return number >= 0 && number <= 5000;
		case 'frameRate':
			return number >= 24 && number <= 60;
		case 'edgeOvershoot':
			return number >= 0 && number <= 400;
		case 'slideOffset':
			return number >= -2000 && number <= 2000;
		case 'pinBatch':
			return number >= 0 && number <= 100000;
	}
	return number >= 0 && number <= 5;
}

// The style keys each part takes in this CMF (CMFStylePart). "" for a part that takes none.
function CMFThemePartKeys(part : name) : string
{
	switch (part)
	{
		case 'map':
			return "top,bottom,panLimit,centerInLimit,backdrop";
		case 'mapEdge':
			return "hide";
		case 'title':
			return CMFThemeTextKeys() + ",x,y,screenX,screenY,wrap,hide";
		case 'tracker':
			return CMFThemeGlowKeys() + ",nameFont,nameSize,nameColor,hide";
		case 'legend':
			return CMFThemeGlowKeys();
		case 'legendRow':
			return CMFThemeGlowKeys() + ",color,colorSelected,colorOff,counterColor,hide";
		case 'legendTab':
			return CMFThemeGlowKeys() + ",color,spacing,hide";
		case 'tooltip':
			// Version 7: clear* moves a tall info box clear of the cursor and the other panels.
			return CMFThemeGlowKeys() + ",titleFont,titleSize,titleColor,bodyFont,bodySize,bodyColor,hide," +
				"clearMinHeight,clearView,clearSide,clearCursor,clearLeft,clearTop,clearRight,clearBottom";
		case 'preview':
			return "hide";
		case 'worldButton':
			return CMFThemeGlowKeys() + ",hide";
		case 'worldHint':
			return CMFThemeGlowKeys() + ",hide";
		case 'hints':
			return CMFThemeGlowKeys() + ",x,y,scale,align";
		case 'keyCap':
			return CMFThemeGlowKeys() + ",color,iconColor,brackets,keyGap,labelGap,hide";
		case 'pinLabel':
			return "font,size,rise,riseTracked,riseOffset,riseOffsetTracked," + CMFThemeShadowKeys();
		case 'pinName':
			return "font,size," + CMFThemeShadowKeys();
		case 'pinButton':
			return "width,height,curve,fill,alpha,stroke,strokeWidth,offsetX,offsetY," + CMFThemeTextKeys();
		case 'navigation':
			return "frameTimed,stepMs,worldStepMs,maxStepMs,crosshairRoam,safeLeft,safeTop,safeRight,safeBottom," +
				"snapSeconds,centerSeconds," + CMFThemeNavigationKeys();
		case 'markerPanel':
			return "minLeft,maxRight,minTop,maxBottom";
		case 'opening':
			return CMFThemeOpeningKeys();
		case 'spread':
			return CMFThemeSpreadKeys();
	}
	return "";
}

// The game decorations a part's "hide" key may name.
function CMFThemeHideWords(part : name) : string
{
	switch (part)
	{
		case 'mapEdge':
			return "edgeFade";
		case 'title':
		case 'tracker':
		case 'worldButton':
		case 'worldHint':
			return "plate";
		case 'legendRow':
			return "plate,selection,arrowPlate";
		case 'legendTab':
			return "plate,selection";
		case 'tooltip':
			return "plate,trackedPlate,divider";
		case 'preview':
			return "frame";
		case 'keyCap':
			return "plate,clickRect";
	}
	return "";
}

// The keys each drawing kind takes in this CMF (CMFDrawSet). Version 6 adds tab, tabLabel, click, above and the
// hover keys to the box kinds, and the map-space kinds: line and movie on mapSpace only, text on mapSpace (placed
// at x, y metres) or on any part or drawing; line, text and movie also take listen and listenFields. A movie
// also takes any key its author documents for the movie. Version 7 adds minPartHeight to the box kinds and text:
// the drawing shows only while its part's box is at least that many pixels tall.
function CMFThemeShapeKeys(kind : name) : string
{
	var keys : string;
	var space : string;
	keys = "left,top,right,bottom,width,height,widthShare,heightShare,minWidth,minHeight,alignX,alignY,offsetX,offsetY," +
		"minLeft,maxRight,minTop,maxBottom,screenLeft,screenRight,screenTop,screenBottom,measure,fill,alpha,fill2,alpha2," +
		"gradient,angle,curve,stroke,strokeAlpha,strokeWidth,layer,order,view,when,repeat,repeatStep,alphaList," +
		CMFThemeGlowKeys() + "," + CMFThemeShadowKeys() + ",tab,tabLabel,click,above," + CMFThemeHoverKeys() + ",minPartHeight";
	space = "layer,order,alpha,view,area,preview,fadeMs,tab,tabLabel,listen,listenFields";
	switch (kind)
	{
		case 'rect':
		case 'ellipse':
			return keys;
		case 'ring':
			return keys + ",inset";
		case 'polygon':
			return keys + ",points,originX,originY";
		case 'band':
			return keys + ",side,size,sizeZoom,minSize,maxShare";
		case 'text':
			return keys + ",text,font,size,color,align,wrap,padding,x,y,sizeZoom,area,fadeMs,listen,listenFields";
		case 'line':
			return space + ",stroke,strokeAlpha,strokeWidth,strokeZoom";
		case 'movie':
			return space + ",src";
	}
	return "";
}

// Every key some drawing kind takes (CMFDrawSet checks the kind when the map opens).
function CMFThemeAllShapeKeys() : string
{
	return CMFThemeShapeKeys('polygon') + ",inset,side,size,sizeZoom,minSize,maxShare," + CMFThemeShapeKeys('text') + "," +
		CMFThemeShapeKeys('line') + "," + CMFThemeShapeKeys('movie');
}

// Keys whose value is the text argument; every other key takes the number argument.
function CMFThemeTextKey(key : name) : bool
{
	return CMFListHas("font,nameFont,titleFont,bodyFont,align,wrap,panLimit,hide,layer,when,gradient,side,measure,view," +
		"points,alphaList,area,src,tab,tabLabel,text,listen,listenFields,clearView,clearSide", NameToString(key));
}

// Map-space drawing: a word with no space or comma (area names, tab ids).
function CMFThemeWordOk(text : string) : bool
{
	return text != "" && StrReplaceAll(StrReplaceAll(text, " ", ""), ",", "") == text;
}

// True when every word of a comma or space list is in allowed (exact case), and there is at least one.
function CMFThemeWordsOk(text : string, allowed : string) : bool
{
	var rest : string;
	var word : string;
	var count : int;
	count = 0;
	rest = StrReplaceAll(text, ",", " ") + " ";
	while (StrLen(rest) > 0)
	{
		word = StrBeforeFirst(rest, " ");
		rest = StrAfterFirst(rest, " ");
		if (word != "")
		{
			if (!CMFListHas(allowed, word))
			{
				return false;
			}
			count += 1;
		}
	}
	return count > 0;
}

// Checks one value for a style or drawing key. part names the styled part ('' for a drawing key).
function CMFThemeValueOk(part : name, key : name, text : string, number : float) : bool
{
	var k : string;
	k = NameToString(key);
	if (CMFThemeTextKey(key))
	{
		switch (key)
		{
			case 'align':
				return text == "left" || text == "center" || text == "right";
			case 'wrap':
				// A text drawing also takes "wrap" (break at its box's width) and "fit" (grow its box to the line).
				return text == "keep" || text == "none" || (part == '' && (text == "wrap" || text == "fit"));
			case 'panLimit':
				return text == "map" || text == "screen";
			case 'hide':
				return CMFThemeWordsOk(text, CMFThemeHideWords(part));
			case 'layer':
				return CMFListHas(CMFThemeLayers(), text);
			case 'when':
				return text == "selected" || text == "tracked" || text == "untracked";
			case 'gradient':
				return text == "linear";
			case 'side':
				return text == "left" || text == "right" || text == "top" || text == "bottom";
			case 'measure':
				return text == "trim" || text == "field";
			case 'view':
			case 'clearView':
				return CMFThemeWordsOk(text, "region,interior,world");
			case 'clearSide':
				return text == "left" || text == "right";
			case 'area':
			case 'tab':
				return CMFThemeWordOk(text);
			case 'listen':
				// A flash storage key the drawing's own mod writes on the map menu; never CMF's or the game's map keys.
				return CMFThemeWordOk(text) && !StrBeginsWith(text, "cmf.") && !StrBeginsWith(text, "map.") &&
					!StrBeginsWith(text, "worldmap.global.") && !StrBeginsWith(text, "worldmap.title.");
			case 'src':
				// The author's own movie, by game path: swf/<folder>/<name>.swf.
				return StrBeginsWith(text, "swf/") && StrEndsWith(text, ".swf") && CMFThemeWordOk(text) &&
					StrReplaceAll(text, "..", "") == text && StrReplaceAll(text, "\\", "") == text;
		}
		return text != "";
	}
	// fill takes a colour, or the text "label" (the label's own colour) on pinLabel and pinName drawings.
	if (key == 'fill' && text == "label")
	{
		return true;
	}
	if (k == "fill" || k == "fill2" || k == "stroke" || k == "backdrop" || StrEndsWith(k, "Color") || k == "color" ||
		k == "colorSelected" || k == "colorOff")
	{
		return number >= 0 && number <= 16777215;
	}
	if (k == "fillHover" || k == "strokeHover" || k == "colorHover")
	{
		return number >= 0 && number <= 16777215;
	}
	if (k == "alpha" || k == "alpha2" || StrEndsWith(k, "Alpha") || k == "alphaHover" || k == "strokeAlphaHover")
	{
		return number >= 0 && number <= 1;
	}
	if (k == "preview" || k == "strokeZoom")
	{
		return number == 0 || number == 1;
	}
	if (k == "click")
	{
		return number >= 0 && number <= 1000 && number == (int)number;
	}
	if (k == "fadeMs")
	{
		return number >= 0 && number <= 5000;
	}
	if (k == "repeat")
	{
		return number >= 1 && number <= 64;
	}
	if (k == "minPartHeight" || k == "clearMinHeight" || k == "clearCursor")
	{
		return number >= 0 && number <= 4000;
	}
	if (part == 'spread')
	{
		return CMFThemeSpreadValueOk(key, number);
	}
	if (part == 'opening' || (part == 'navigation' && (CMFListHas(CMFThemeNavigationKeys(), k) || k == "stepMs" ||
		k == "worldStepMs" || k == "maxStepMs")))
	{
		return CMFThemeMotionValueOk(key, number);
	}
	if (k == "centerInLimit" || k == "frameTimed" || k == "crosshairRoam" || k == "brackets" || k == "sizeZoom")
	{
		return number == 0 || number == 1;
	}
	if (k == "scale" || k == "size" || k == "nameSize" || k == "titleSize" || k == "bodySize")
	{
		return number > 0 && number <= 1000;
	}
	return number >= -100000 && number <= 100000;
}

// Version 5. Asks before using an ability: CMFHasAbility(part, '') is true for every part, layer and drawing
// kind this CMF knows; CMFHasAbility(part, key) for every style key the part takes, and for a drawing kind
// every key and list key its drawings take. Version 6 adds mapSpace, line, text and movie
// (CMFHasAbility('mapSpace', ''), ('line', 'colors'), ('text', '')). Version 7 adds ('tooltip', 'clearMinHeight')
// and the other clear keys, and ('rect', 'minPartHeight') on every box kind and text. Abilities designed for later (images,
// the map hold) answer false until a CMF version adds them.
function CMFHasAbility(part : name, key : name) : bool
{
	var p : string;
	p = NameToString(part);
	if (!IsNameValid(key))
	{
		return CMFListHas(CMFThemeParts(), p) || CMFListHas(CMFThemeLayers(), p) || CMFListHas(CMFThemeKinds(), p);
	}
	if (CMFListHas(CMFThemeParts(), p))
	{
		return CMFListHas(CMFThemePartKeys(part), NameToString(key));
	}
	if (CMFListHas(CMFThemeKinds(), p))
	{
		return CMFListHas(CMFThemeShapeKeys(part) + "," + CMFThemeListKeys(part), NameToString(key));
	}
	return false;
}

// Version 5. Styles one part of the map (fonts, colours, glows, place, the game decorations to hide) or sets
// one map behaviour (parts map, navigation, opening and spread). text carries words (fonts such as "$TitleFont",
// "keep", "region,world", decoration names); number carries everything else, colours as 0xRRGGBB. The earliest
// folder that styles a part owns all of its style keys; map, navigation, opening and spread are won key by key.
// Unset keys keep the game's look.
function CMFStylePart(provider : string, part : name, key : name, text : string, number : float) : bool
{
	var themeEntry : SCMFThemeEntry;
	if (provider == "" || !CMFListHas(CMFThemeParts(), NameToString(part)) || !CMFHasAbility(part, key))
	{
		CMFLog("theme rejected provider=" + provider + " part=" + NameToString(part) + " key=" + NameToString(key) +
			" reason=unknown");
		return false;
	}
	// Smooth map movement (P6): the text "unset" withdraws this provider's own value for this key; it is never a value.
	if (text == "unset")
	{
		theGame.CMFGetCore().UnsetTheme(provider, part, key);
		CMFLog("theme unset provider=" + provider + " part=" + NameToString(part) + " key=" + NameToString(key));
		return true;
	}
	if (!CMFThemeValueOk(part, key, text, number))
	{
		CMFLog("theme rejected provider=" + provider + " part=" + NameToString(part) + " key=" + NameToString(key) +
			" reason=value");
		return false;
	}
	themeEntry.provider = provider;
	themeEntry.kind = 1;
	themeEntry.target = part;
	themeEntry.key = key;
	themeEntry.text = text;
	themeEntry.number = number;
	return theGame.CMFGetCore().UpsertTheme(themeEntry);
}

// Version 5. Makes a drawing with a free id, tied to an anchor: a part, or any drawing id any mod made. kind
// is rect, ring, ellipse, polygon or band (version 6 adds line, text and movie); '' withdraws this provider's
// drawing and its keys. The earliest folder that makes an id owns it; another folder's drawing with the same id
// is refused and logged. Set the drawing's place, paint, layer and conditions with CMFDrawSet. Version 6: the
// anchor mapSpace takes line, text and movie drawings, and line and movie drawings take only mapSpace.
function CMFDraw(provider : string, anchor : name, id : name, kind : name) : bool
{
	var themeEntry : SCMFThemeEntry;
	if (provider == "" || !IsNameValid(anchor) || !IsNameValid(id) || anchor == id ||
		CMFListHas(CMFThemeParts() + "," + CMFThemeLayers() + "," + CMFThemeKinds(), NameToString(id)) ||
		(IsNameValid(kind) && !CMFListHas(CMFThemeKinds(), NameToString(kind))) ||
		CMFListHas(CMFThemeLayers() + "," + CMFThemeKinds() + ",navigation,opening,spread", NameToString(anchor)) ||
		(anchor == 'mapSpace' && IsNameValid(kind) && kind != 'line' && kind != 'text' && kind != 'movie') ||
		(anchor != 'mapSpace' && (kind == 'line' || kind == 'movie')))
	{
		CMFLog("theme rejected provider=" + provider + " anchor=" + NameToString(anchor) + " id=" + NameToString(id) +
			" kind=" + NameToString(kind) + " reason=unknown");
		return false;
	}
	themeEntry.provider = provider;
	themeEntry.kind = 2;
	themeEntry.target = id;
	themeEntry.anchor = anchor;
	themeEntry.key = kind;
	return theGame.CMFGetCore().UpsertTheme(themeEntry);
}

// Version 5. Sets one key of a drawing this provider made with CMFDraw (any order of calls: the key is
// checked against the drawing's kind when the map opens). text carries words (layer, when, view, points,
// alphaList, "label" for fill; version 6: area, src, tab, tabLabel and a text drawing's text); number carries
// everything else. Version 6: a movie drawing also takes any other key for the author's own movie, with both
// text and number handed to it as they are; such a key needs CMFDraw first.
function CMFDrawSet(provider : string, id : name, key : name, text : string, number : float) : bool
{
	var themeEntry : SCMFThemeEntry;
	var own : bool;
	own = false;
	if (provider != "" && IsNameValid(id) && IsNameValid(key) && !CMFListHas(CMFThemeAllShapeKeys(), NameToString(key)))
	{
		own = theGame.CMFGetCore().DrawingKind(provider, id) == 'movie';
	}
	if (provider == "" || !IsNameValid(id) || (!own && !CMFListHas(CMFThemeAllShapeKeys(), NameToString(key))))
	{
		CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=" + NameToString(key) +
			" reason=unknown");
		return false;
	}
	if (!own && !CMFThemeValueOk('', key, text, number))
	{
		CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=" + NameToString(key) +
			" reason=value");
		return false;
	}
	themeEntry.provider = provider;
	themeEntry.kind = 3;
	themeEntry.target = id;
	themeEntry.key = key;
	themeEntry.text = text;
	themeEntry.number = number;
	return theGame.CMFGetCore().UpsertTheme(themeEntry);
}

// Version 6 (map-space drawing). Sets one list key of a drawing this provider made: a line's xs and ys (world
// metres), starts (the point index where each segment starts), modes (one per segment, an index into colors)
// and colors (0xRRGGBB), or any list key a movie's author documents (that needs CMFDraw first). An empty
// array withdraws the key. Same ownership and refusal rules as CMFDrawSet; at most 100000 values.
function CMFDrawSetList(provider : string, id : name, key : name, values : array<float>) : bool
{
	var themeEntry : SCMFThemeEntry;
	var i : int;
	var k : string;
	k = NameToString(key);
	if (provider == "" || !IsNameValid(id) || !IsNameValid(key) || values.Size() > 100000 ||
		(!CMFListHas(CMFThemeListKeys('line'), k) && theGame.CMFGetCore().DrawingKind(provider, id) != 'movie'))
	{
		CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=" + k + " reason=unknown");
		return false;
	}
	for (i = 0; i < values.Size(); i += 1)
	{
		if ((k == "colors" && (values[i] < 0 || values[i] > 16777215)) ||
			((k == "starts" || k == "modes") && (values[i] < 0 || values[i] != (int)values[i])))
		{
			CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=" + k + " reason=value");
			return false;
		}
	}
	themeEntry.provider = provider;
	themeEntry.kind = 4;
	themeEntry.target = id;
	themeEntry.key = key;
	themeEntry.values = values;
	return theGame.CMFGetCore().UpsertTheme(themeEntry);
}

// Version 6 (map-space drawing). For a mod whose drawings change while the map stays open: runs OnMapReady
// again and re-sends the theme and the map-space drawings to the open map. False when no map is open.
function CMFMapRefresh() : bool
{
	return theGame.CMFGetCore().RefreshMap();
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFGetCore().RequestRefresh();
	return result;
}

@wrapMethod(CR4MapMenu)
function GetShownMapName() : string
{
	var vanillaRoot : string;
	vanillaRoot = wrappedMethod();
	return theGame.CMFGetCore().MapImageRoot(m_shownArea, vanillaRoot);
}

@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	wrappedMethod(flashArray, indexToUpdate);
	theGame.CMFGetCore().FillMissingPinFields(flashArray, CMFMapContext(), indexToUpdate, m_shownArea);
	if (indexToUpdate < 0)
	{
		theGame.CMFGetCore().KeepFullList(flashArray);
		theGame.CMFGetCore().MapReady(GetMenuFlash());
		theGame.CMFGetCore().SendSpace(GetMenuFlashValueStorage(), m_shownArea, this);
	}
}

// After the build is sent: pins another mod's UpdateUserMapPins wrapper added outside CMF's are filled and the
// list goes again under the key the game used (CatchLatePins).
@wrapMethod(CR4MapMenu)
function UpdateData(optional ignoreSelectionChange : bool)
{
	var flashArray : CScriptedFlashArray;
	wrappedMethod(ignoreSelectionChange);
	flashArray = theGame.CMFGetCore().CatchLatePins(CMFMapContext(), m_shownArea);
	if (flashArray)
	{
		theGame.CMFGetCore().MapReady(GetMenuFlash());
		theGame.CMFGetCore().SendSpace(GetMenuFlashValueStorage(), m_shownArea, this);
		if (ignoreSelectionChange)
		{
			GetMenuFlashValueStorage().SetFlashArray("worldmap.global.pins.static.update", flashArray);
		}
		else
		{
			GetMenuFlashValueStorage().SetFlashArray("worldmap.global.pins.static", flashArray);
		}
	}
}

// Map-space drawing: sends the map-space drawings for the shown area; refresh (CMFMapRefresh) first runs
// OnMapReady again and re-sends the theme.
@addMethod(CR4MapMenu)
function CMFMapSpaceSend(refresh : bool)
{
	if (refresh)
	{
		theGame.CMFGetCore().MapReady(GetMenuFlash());
		theGame.CMFGetCore().SendTheme(GetMenuFlashValueStorage());
	}
	theGame.CMFGetCore().SendSpace(GetMenuFlashValueStorage(), m_shownArea, this);
}

// Opens the pin list for per-pin hides; the late pass closes it.
@wrapMethod(CR4MapMenu)
function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void
{
	theGame.CMFGetCore().OpenPinList();
	wrappedMethod(flashArray);
}

@wrapMethod(CR4MapMenu)
function AddPinTypeData(out dataObject : CScriptedFlashObject, targetPin : SCommonMapPinInstance) : void
{
	wrappedMethod(dataObject, targetPin);
	theGame.CMFGetCore().WritePinFields(dataObject, targetPin.visibleType, targetPin.tag, CMFMapContext());
}

// The map panel reports how it measured the legend each time that box changes (launch T1 diagnosis).
@addMethod(CR4MapMenu)
event OnCMFPanelNote(note : string)
{
	CMFLog("panel " + note);
}

// The map panel calls this when a registered pin or legend image fails to load (see edits.json).
@addMethod(CR4MapMenu)
event OnCMFArtFailed(url : string)
{
	theGame.CMFGetCore().ReportArtFailed(url);
}

// The map panel registered its theme listener (once per opening): send the winning theme entries.
@addMethod(CR4MapMenu)
event OnCMFMapThemeReady()
{
	theGame.CMFGetCore().SendTheme(GetMenuFlashValueStorage());
}

// Version 6: the map panel reports a click on a pin whose click a provider won (input "use", "doubleClick" or
// "button"). pinTag receives the flash id as the game's own OnStaticMapPinUsed does; None for a placed pin, whose id
// is no name.
@addMethod(CR4MapMenu)
event OnCMFPinClicked(pinTag : name, pinId : int, provider : string, pinType : string, input : string, value : int)
{
	theGame.CMFGetCore().PinClicked(this, pinTag, pinId, provider, pinType, input, value);
}

// Version 6 (map-space drawing): the map panel reports a click on a drawing, by its id and click number.
@addMethod(CR4MapMenu)
event OnCMFDrawingClicked(id : string, value : int)
{
	theGame.CMFGetCore().DrawingClicked(this, id, value);
}

// Version 6 (map-space drawing): the map panel started listening to the storage keys drawings named with listen.
@addMethod(CR4MapMenu)
event OnCMFListenReady(keys : string)
{
	theGame.CMFGetCore().ListenReady(this, keys);
}

// Version 6 (map-space drawing): the map panel registered its map-space listener.
@addMethod(CR4MapMenu)
event OnCMFMapSpaceReady()
{
	theGame.CMFGetCore().SpaceListenerReady(this);
}

// Version 9: the map panel reports how a world overview or button picture loaded (one line per slot per opening).
@addMethod(CR4MapMenu)
event OnCMFPictureNote(line : string)
{
	CMFLog(line);
}

// Version 9: the map panel reports the region map's view once it has stayed still after the player panned or
// zoomed.
@addMethod(CR4MapMenu)
event OnCMFMapView(x : float, y : float, worldX : float, worldY : float, zoom : float)
{
	theGame.CMFGetCore().MapView(this, m_shownArea, x, y, worldX, worldY, zoom, 'still');
}

// Version 9: the map panel has the region's settings (the opening and every region switch): run OnMapOpening and
// answer with the opening view.
@addMethod(CR4MapMenu)
event OnCMFMapOpening()
{
	theGame.CMFGetCore().MapOpening(this, m_shownArea, CMFMapContext(), GetMenuFlashValueStorage());
}

// Version 9: reports the shown region map's view as the panel keeps it on the menu (cmfViewOk and the cmfView
// members, set only by CMF's map once a region map is placed).
@addMethod(CR4MapMenu)
function CMFReportView(reason : name)
{
	var menuFlash : CScriptedFlashSprite;
	menuFlash = GetMenuFlash();
	if (!menuFlash || !IsNameValid(m_shownArea) || !menuFlash.GetMemberFlashBool("cmfViewOk"))
	{
		return;
	}
	theGame.CMFGetCore().MapView(this, m_shownArea, menuFlash.GetMemberFlashNumber("cmfViewX"),
		menuFlash.GetMemberFlashNumber("cmfViewY"), menuFlash.GetMemberFlashNumber("cmfViewWX"),
		menuFlash.GetMemberFlashNumber("cmfViewWY"), menuFlash.GetMemberFlashNumber("cmfViewZoom"), reason);
}

// Version 9: before the map switches to another region, the region being left reports its last view.
@wrapMethod(CR4MapMenu)
function SwitchToHubMap(area : name, onStartup : bool)
{
	var shown : name;
	shown = area;
	if (shown == 'AN_Velen')
	{
		shown = 'AN_NMLandNovigrad';
	}
	if (IsNameValid(shown) && shown != 'AN_Undefined' && shown != m_shownArea)
	{
		CMFReportView('region');
	}
	wrappedMethod(area, onStartup);
}

// Version 9: the map is closing: the shown region reports its last view.
@wrapMethod(CR4MapMenu)
function OnClosingMenu()
{
	CMFReportView('close');
	return wrappedMethod();
}

// Version 6: a button bar label that starts with "cmf:" is shown as the literal text after it (a pin's click
// hint); every other label goes to the game's method.
@wrapMethod(CR4MenuBase)
function OnAppendGFxButton(actionId : int, gamepadNavCode : String, keyboardKeyCode : int, label : String,
	holdPrefix : bool, optional holdDuration : float)
{
	var binding : SKeyBinding;
	if (!StrBeginsWith(label, "cmf:"))
	{
		return wrappedMethod(actionId, gamepadNavCode, keyboardKeyCode, label, holdPrefix, holdDuration);
	}
	RemoveGFxButtonById(actionId);
	binding.ActionID = actionId;
	binding.Gamepad_NavCode = gamepadNavCode;
	binding.Keyboard_KeyCode = keyboardKeyCode;
	binding.LocalizationKey = StrAfterFirst(label, "cmf:");
	binding.IsLocalized = true;
	m_GFxInputBindings.PushBack(binding);
	return true;
}

// How the map was opened, with the same tests vanilla uses for its fast travel tutorial (mapMenu.ws OnConfigUI).
@addMethod(CR4MapMenu)
function CMFMapContext() : name
{
	var initData : W3MapInitData;
	initData = (W3MapInitData)GetMenuInitData();
	if (initData && (initData.GetTriggeredExitEntity() || initData.GetUsedFastTravelEntity()))
	{
		return 'FastTravel';
	}
	if (thePlayer.IsOnBoat())
	{
		return 'Boat';
	}
	return 'GlobalMap';
}
