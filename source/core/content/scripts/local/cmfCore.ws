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
// CMFSetOpeningWorld); version 10: behaviour picked apart from art (the Behaviour feature and its pieces, choices per
// key: CMF files each theme key and property under a look piece or a behaviour piece), the wide part (the map fills
// wide and tall screens), the wideAnchor drawing key, the HoverName pin property, the opening keys readyAtFadeStart
// and revealEase, and CMFScreenWidth and CMFScreenHeight); version 11: one pin at a time (the colour of one pin by tag,
// art for one pin or one real kind while undiscovered or completed, the info box's title and text replaced or added to,
// its height per type, tag or pin, art for a level variant type, claims by place (CMFRegisterForPlace), the player marker
// and the player's own markers restyled by type, the game's own legend rows moved and whole filter tabs hidden, and the
// pin list in the log, [CMFSettings] CMFLogPins, and provider presence without feature ownership); version 12: the info box's
// place apart from its height (the tooltip keys tallMinHeight and the tall* places).
// Never remove a call once published.

function CMFGetVersion() : int { return 18; }

// API 14: frame programs and their winning provider's per-layer phase.
function CMFPropertyIconFrames() : int { return 45; }
function CMFPropertyIconUnderFrames() : int { return 46; }
function CMFPropertyFrameOffset() : int { return 47; }
// API 14: 1 makes a provider's pictures fill one fixed box instead of the game's glyph bounds; 0 or no claim keeps the glyph box.
function CMFPropertyPictureFit() : int { return 48; }
// Version 18: a provider's grid keep epoch (number = any int). Changing it revokes that provider's earlier keeps.
function CMFPropertyGridKeepEpoch() : int { return 49; }

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
// won the pin's click.
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
// Version 10: names only on hover (number = bits: 1 the pin's label line and its tag drawings show only on the hovered
// pin, 2 the hovered pin shows its name on the label line; 0 as the game shows it, so a type claim of 0 keeps that type
// out of an every-pin claim), for every pin (target ''), a type, a tag or one pin.
function CMFPropertyHoverName() : int { return 28; }
// Version 11: the info box's title (18) and text (19), HTML as the game's own, for every pin (target ''), a type, a tag, a
// place or one pin. number 0 replaces the game's words (one provider wins, as for any property); number 1 adds the text
// as lines below them (every add claim applies, the earlier folder first). The title is also the pin's name on the map.
function CMFPropertyInfoTitle() : int { return 18; }
function CMFPropertyInfoText() : int { return 19; }
// Version 11: art while the pin is undiscovered (29, the "?" pin) or completed (30, the "...Disabled" pin), text = a
// picture or "frame:<label>" as for the icon, for a type (the pin's real kind, such as 'BanditCamp', so an undiscovered
// camp can look apart from an undiscovered cave), a tag, a place or one pin.
function CMFPropertyIconUndiscovered() : int { return 29; }
function CMFPropertyIconCompleted() : int { return 30; }
// Version 11: hides a whole filter tab (target = the tab: Quests, Exploration, NPCs, Buffs, Default or a tab id; never
// All), number nonzero (0 withdraws). Every claim applies, as for hiding pins.
function CMFPropertyTabHidden() : int { return 37; }
// Version 11: provider presence only; never a feature claim.
function CMFPropertyPresent() : int { return 38; }

// Version 11: how an info box claim's text joins the game's words (its number).
function CMFInfoReplace() : int { return 0; }
function CMFInfoAdd() : int { return 1; }

// Version 11: target levels of a claim. 0 every pin, 1 a type, 2 one pin by tag, 3 one pin by place (CMFRegisterForPlace:
// the pin of that type within CMFPlaceRadius metres of a world position). Tag beats place, which beats type.
function CMFLevelPlace() : int { return 3; }
function CMFPlaceRadius() : float { return 2.0; }

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
// (a button drawn beside the pin). API 13 adds hold (8), after navigation.padHoldMs or the native delay.
function CMFClickInputUse() : int { return 1; }
function CMFClickInputDoubleClick() : int { return 2; }
function CMFClickInputButton() : int { return 4; }
function CMFClickInputHold() : int { return 8; }

// Parses "use", "doubleClick", "button" and "hold", separated by commas or spaces, ignoring case, into input flags.
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
		else if (word == "hold")
		{
			if (!CMFHasFlag(flags, CMFClickInputHold()))
			{
				flags += CMFClickInputHold();
			}
		}
		else if (word != "")
		{
			return false;
		}
	}
	return flags > 0;
}

// The pin's cmfClick field carries use, doubleClick, button and hold joined with commas.
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
	if (CMFHasFlag(flags, CMFClickInputHold()))
	{
		text += "hold,";
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
		propertyId == CMFPropertyCategoryNoDefault() || propertyId == CMFPropertySpreadRank() ||
		propertyId == CMFPropertyHoverName() || propertyId == CMFPropertyTabHidden() ||
		propertyId == 32 || propertyId == 33 || propertyId == 34 || propertyId == 39 || propertyId == 41 || propertyId == 43 ||
		propertyId == 44 || propertyId == 47 || propertyId == 48;
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
		case 28:
			return "cmfHoverNameBy";
		// Version 11.
		case 14:
			return "cmfDescMaxHBy";
		case 39:
			return "cmfDescMaxWBy";
		case 18:
			return "cmfInfoTitleBy";
		case 19:
			return "cmfInfoTextBy";
		case 29:
		case 30:
			return "cmfIconBy";
		case 31:
			return "cmfIconSelectedBy";
		case 32:
			return "cmfSelectedScaleBy";
		case 33:
			return "cmfPinAlphaBy";
		case 34:
			return "cmfPinOrderBy";
		case 35:
			return "cmfPinOffsetBy";
		case 36:
			return "cmfPinZoomBy";
		case 42:
			return "cmfIconUnderBy";
		case 43:
			return "cmfIconUnderTintBy";
		case 44:
			return "cmfPictureScaleBy";
		case 45:
			return "cmfIconFramesBy";
		case 46:
			return "cmfIconUnderFramesBy";
		case 47:
			return "cmfIconFrameOffsetBy";
		case 48:
			return "cmfPictureFitBy";

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
// Painting_Crests (60) and Movement_View (61); every older index stays. Version 10 appends the Behaviour feature (62)
// and its pieces Behaviour_InfoBoxDodge (63) and Behaviour_InfoBoxHeight (64), Movement_ZoomOut (65),
// Movement_Controller (66), Behaviour_HoverNames (67) and Movement_Wide (68); Size_Lead, Size_Spread and Labels_Place
// keep their index and name and answer the Behaviour feature (CMFChoiceParent). Version 11 keeps 69 (Reserved69, never
// offered) and appends Icons_Undiscovered (70) and Look_InfoText (71). Version 15 appends the Map feature (80), "The map":
// Movement_Area (44) keeps its index and name and answers it (CMFChoiceParent), and the map part's backdrop moves
// from Look_Frames to Movement_Area, so the map and the frames and panels are chosen apart.
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
		"Movement_View,Behaviour,Behaviour_InfoBoxDodge,Behaviour_InfoBoxHeight,Movement_ZoomOut,Movement_Controller," +
		"Behaviour_HoverNames,Movement_Wide,Reserved69,Icons_Undiscovered,Look_InfoText," +
		"Behaviour_InfoBoxMotion,Look_Sounds,Behaviour_InfoFold,Behaviour_PanelModes,Look_Badges,Look_PinLook," +
		"Size_Place,Behaviour_PinZoom,Map";
}

// Version 10: the feature of the three pieces that moved under Behaviour (62) without a new name, or -1 when the key's
// prefix names its feature. Version 15: Movement_Area (44) answers the Map feature (80).
// Piece-parent inheritance is separate: CMFCore.PieceParentTable (empty in revision 13).
function CMFChoiceParent(choice : int) : int
{
	if (choice == 28 || choice == 29 || choice == 31)
	{
		return 62; // Behaviour
	}
	if (choice == 44)
	{
		return 80; // Map: Movement_Area
	}
	return -1;
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

// Target levels: 0 every pin (hide claims only), 1 one pin type, 2 one pin instance (tag), 3 (version 11) one pin by
// place: pinType and the world position placeX, placeY (CMFLevelPlace).
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
	var placeX : float;
	var placeY : float;
	var valueX : float;
	var valueY : float;
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

// Revision 13: session-only provider data. Never retain Flash objects or write save data.
struct SCMFAddedPin
{
	var provider : string;
	var tag : name;
	var pinType : name;
	var area : name;
	var x : float;
	var y : float;
	var label : string;
	var description : string;
	var order : int;
}

// Version 18: one pin type that mods add to the map (session only; strings, names and ints, never a Flash object).
struct SCMFAddedPinType
{
	var provider : string;
	var pinType : string;
	var filteredType : string;
	var count : int;
	var declared : bool;
}

struct SCMFLabelHideState
{
	var pin : CScriptedFlashObject;
	var providers : array<string>;
	var flags : array<int>;
	var next : int;
}

struct SCMFAnimationStage
{
	var stageName, frames, fps, plays, direction, holdFirst, holdLast, offset, delay : string;
}

struct SCMFAnimationCache
{
	var text, canonical, poster, reason : string;
	var fps, stageCount, frameCount : int;
	var valid : bool;
}

struct SCMFAnimationBinding
{
	var pinKey, text : string;
	var propertyId, fps : int;
}

struct SCMFAnimationDirect
{
	var pin : CScriptedFlashObject;
	var pinKey, provider : string;
	var offset : int;
}

class CMFCore extends CObject
{
	// Session presence is independent of claims, offers and provider priority.
	private var presentIdentities : array<string>;
	private var presentProviders : array<string>;
	private var lastPresentProvider : string;
	private var claims : array<SCMFClaim>;
	private var animationClaimIndices : array<int>;
	private var animationCache : array<SCMFAnimationCache>;
	private var animationTextClean : bool;
	private var animationBlanks : string;
	private var animationDirect : array<SCMFAnimationDirect>;
	private var animationBindings : array<SCMFAnimationBinding>;
	// 1.10.1: animationBindingKeys[i] is animationBindings[i]'s pin key and property, so a pin's binding is found by a
	// native search instead of a script loop over every binding (that loop made the late pass grow with the square of
	// the pins that carry animated art).
	private var animationBindingKeys : array<string>;
	private var animationPins : array<CScriptedFlashObject>;
	private var animationMenu : CR4MapMenu;
	private var animationEnabled, animationOptionsRead : bool;
	private var animationCap : int;
	private var animationDragPause : bool;
	private var animationMemory : int;
	private var animationNotes : array<string>;
	private var animationCounts : array<int>;
	private var winners : array<SCMFClaim>;
	private var nextOrder : int;
	private var dirty : bool;
	private var revision : int;
	private var seenPins : array<string>;
	// 1.8.0: legend log notes keep their own cap, so a full seenPins never hides them.
	private var seenLegend : array<string>;
	private var failedArt : array<string>;
	private var categories : array<SCMFClaim>;
	private var hideClaims : array<SCMFClaim>;
	private var tabHideClaims : array<SCMFClaim>;
	private var labelHideClaims : array<SCMFClaim>;
	private var labelHidePins : array<SCMFLabelHideState>;
	private var labelHideBuckets : array<int>;
	private var labelHideOffers : array<string>;
	private var listOpen : bool;
	private var inBuild : bool;
	private var entityStepRan : bool;
	private var entitySkipLogged : bool;
	private var fieldsStepCount : int;
	private var themeEntries : array<SCMFThemeEntry>;
	private var itemStyles : array<SCMFThemeEntry>;
	private var itemStyleOwners : array<string>;
	private var itemStylesSent : bool;
	private var addedPins : array<SCMFAddedPin>;
	private var addedTypes : array<SCMFAddedPinType>;
	private var declaredAddedTypes : int;
	private var addedLastType : string;
	private var addedLastIndex : int;
	private var keepEpochProviders : array<string>;
	private var keepEpochValues : array<int>;
	private var keepRevoked : int;
	private var hintListOwnerSent : string;
	private var hintListPreparedOwner : string;
	private var themeNotes : array<string>;
	// Memo for one SendTheme call (themeMemoOn); cleared at both ends of the call.
	private var themeMemoOn : bool;
	private var styleMemoKeys : array<string>;
	private var styleMemoOwners : array<string>;
	private var drawingMemoIds : array<name>;
	private var drawingMemoOwners : array<string>;
	private var kindMemoKeys : array<string>;
	private var kindMemoValues : array<name>;
	private var leftOutMemoKeys : array<string>;
	private var leftOutMemoFlags : array<bool>;
	private var leftOutMemoOwners : array<string>;
	private var rankMemoProviders : array<string>;
	private var rankMemoValues : array<int>;
	private var providerOrder : string;
	private var clickNotes : array<string>;
	private var spaceMenu : CR4MapMenu;
	private var refreshBusy : int;
	private var marksThisBuild : int;
	private var lateStepRan : bool;
	private var lateStepLogged : bool;
	private var nonUserOneLogged : bool;
	private var refuseLogged : bool;
	private var spaceEarlyMenu : CR4MapMenu;
	private var spaceEarlyOk : bool;
	// The first grid sent by the last full build: its fill colour and alpha, for the cover shown before the map's first frame.
	private var coverKnown : bool;
	private var coverFill : int;
	private var coverAlpha : float;
	private var coverArea : name;
	// 1.8.0: set by the first full build of the session. Before it no grid is kept, so a grid drawing a provider declared
	// ahead (CMFDraw with its fill and alpha, before the first opening) gives the first opening its cover.
	private var spaceBuiltOnce : bool;
	private var spaceArea : name;
	private var catchArray : CScriptedFlashArray;
	private var catching : bool;
	private var askedPins : array<CScriptedFlashObject>;
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
	// The info box keys of the pin whose OnPinReady runs, once WritePinInfo wrote it (a replace there re-adds the lines).
	private var infoWritten : bool;
	// Version 12: the game's own pin is being written (its legend row is one of the game's), and the game rows a
	// legend row claim left in their own tab, logged once per preparation.
	private var gamePinNow : bool;
	private var rowsKept : array<string>;
	private var infoKey : string;
	private var infoLegend : string;
	private var infoTag : name;
	private var nameProviders : array<string>;
	private var nameTexts : array<string>;
	private var groupCacheType : string;
	private var groupCacheValue : int;
	private var mapSeen : bool;
	// Version 11: shared across map instances and save reloads for this core session.
	private var mapCheckWarned : bool;
	// Version 9: choice-only registrations (CMFRegisterChoiceOnly) as a provider and a choice index each, the providers
	// of the claims they left out at the last preparation (one entry per claim), and the opening views.
	private var choiceOnlyProviders : array<string>;
	private var choiceOnlyChoices : array<int>;
	private var choiceOnlySkipped : array<string>;
	private var openingViews : array<SCMFOpeningView>;
	// Version 10: the visible screen in map units from the last map opening (0 before the first).
	private var screenWidth : float;
	private var screenHeight : float;
	// Version 11: the info box add claims (number 1, every one applies, folder order) and the whole-tab hides of the
	// last preparation; the pin being written (SetPinContext): the pin key its claims were asked with, its own type when
	// that is a level variant of the key, and its world position; the pin list log's area and the pins it named there.
	private var infoAdds : array<SCMFClaim>;
	private var tabsHidden : array<SCMFClaim>;
	private var pinKeyNow : string;
	private var variantNow : string;
	private var placeOk : bool;
	private var placeX : float;
	private var placeY : float;
	private var listArea : name;
	private var listedPins : array<string>;
	// Version 11, opening speed: which properties have a winner, how many claims name a place, and the tag claims' game
	// ids, worked out once per preparation so a pin's lookups skip what no provider asked for.
	private var drawingRootIds : array<name>;
	private var drawingRootParts : array<name>;
	private var declaredTagProviders : array<string>;
	private var declaredTagNames : array<name>;
	private var unknownTagProviders : array<string>;
	private var unknownTagTexts : array<string>;
	private var propertyWon : array<bool>;
	// Revision 13: prepared indices preserve candidate order and avoid unrelated per-pin scans.
	// A single global winner is reusable; its pin-group choice is still checked by Find.
	private var globalWinner : array<int>;
	private var specificWon : array<bool>;
	private var propertyFirst : array<int>;
	private var propertyNext : array<int>;
	// Opening speed (1.10.1): the winners indexed by what a pin can match, built once per preparation (BuildLookupIndex),
	// so Find looks at the few winners that can cover a pin instead of every winner of the property. Heads and next
	// links hold a winner index plus one (0 = none). typeHead and tagHead are indexed slot * 64 + property.
	private var indexBuilt : bool;
	private var typeKeys : array<string>;
	private var tagKeys : array<name>;
	private var typeHead : array<int>;
	private var typeTail : array<int>;
	private var typeNext : array<int>;
	private var tagHead : array<int>;
	private var tagTail : array<int>;
	private var tagNext : array<int>;
	private var globalHead : array<int>;
	private var globalTail : array<int>;
	private var globalNext : array<int>;
	// The answer of a Find for a pin type with no tag, variant or place: 0 unknown, 1 nothing, winner index plus two.
	private var memoState : array<int>;
	private var candidates : array<int>;
	// CMFDebug timing and counts, read once per preparation and per build; nothing is timed or counted without it.
	private var debugTiming : bool;
	private var timingPins : int;
	private var timingCovered : int;
	private var timingFinds : int;
	private var timingCandidates : int;
	private var timingMemoHits : int;
	private var activeWriteSlots : array<int>;
	private var placeClaims : int;
	private var tagIds : array<int>;
	private var tagNames : array<name>;
	// Version 11, opening speed: the types the winners name (type claims), whether any winner covers every pin, so a pin
	// no claim can reach skips the field writing (PinCovered).
	private var claimedTypes : array<string>;
	private var everyPinClaims : int;
	// The same for the info box title and text claims (18, 19, replace and add): the types and tags they name, and
	// whether one reaches every pin or names a place.
	private var infoTypes : array<string>;
	private var infoTags : array<name>;
	private var infoEveryOrPlace : bool;
	private var logPins : bool;
	private var logPinsAsked : bool;
	private var logPinsLines : int;

	// Called only after a fully shown map closes without any CMF readiness callback. The box waits for the menus to
	// finish closing (CMFMapCheckLater): a box asked for while the map's menus close can be cleared with them.
	public function MapCheckWarnOnce() : bool
	{
		if (mapCheckWarned)
		{
			return false;
		}
		mapCheckWarned = true;
		CMFLog("map check: CMF's map did not load; another mod's map file is loading first");
		CMFMapCheckSchedule();
		return true;
	}

	// Exact spelling is the common per-pin path; case folding and one lookup happen only on a cache miss.
	public function NoteProviderPresent(provider : string) : bool
	{
		var identity : string;
		if (provider == "")
		{
			return false;
		}
		if (provider == lastPresentProvider)
		{
			return true;
		}
		identity = StrLower(provider);
		if (presentIdentities.FindFirst(identity) < 0)
		{
			presentIdentities.PushBack(identity);
			presentProviders.PushBack(provider);
			CMFLog("present provider=" + provider);
		}
		lastPresentProvider = provider;
		return true;
	}


	// Session-long typed names for text targets. No string-to-name conversion or hash reconstruction.
	public function DeclareTag(provider : string, tag : name) : bool
	{
		var i : int;
		NoteProviderPresent(provider);
		if (provider == "" || !IsNameValid(tag)) { return false; }
		for (i = 0; i < declaredTagNames.Size(); i += 1)
		{
			if (StrLower(declaredTagProviders[i]) == StrLower(provider) &&
				StrLower(NameToString(declaredTagNames[i])) == StrLower(NameToString(tag))) { return true; }
		}
		declaredTagProviders.PushBack(provider);
		declaredTagNames.PushBack(tag);
		dirty = true;
		return true;
	}

	private function ResolveKnownTag(provider : string, text : string) : int
	{
		var i : int;
		var lowered : string;
		lowered = StrLower(text);
		for (i = 0; i < declaredTagNames.Size(); i += 1)
		{
			if (StrLower(NameToString(declaredTagNames[i])) == lowered)
			{
				return NameToFlashUInt(declaredTagNames[i]);
			}
		}
		for (i = 0; i < unknownTagTexts.Size(); i += 1)
		{
			if (StrLower(unknownTagProviders[i]) == StrLower(provider) && unknownTagTexts[i] == lowered) { return 0; }
		}
		unknownTagProviders.PushBack(provider);
		unknownTagTexts.PushBack(lowered);
		CMFLog("tag unknown, declare it with CMFDeclareTag provider=" + provider + " tag=" + text);
		return 0;
	}

	public function ProviderPresent(provider : string) : bool
	{
		return provider != "" && presentIdentities.FindFirst(StrLower(provider)) >= 0;
	}

	public function PresentProviders(out providers : array<string>)
	{
		var i : int;
		providers.Clear();
		for (i = 0; i < presentProviders.Size(); i += 1)
		{
			providers.PushBack(presentProviders[i]);
		}
	}

	// API 14: authored descriptors are parsed once per exact text and FPS. The panel sees only this wire form.
	public function AnimationFpsCap() : int { return 30; }

	private function AnimationSpace(ch : string) : bool
	{
		if (animationBlanks == "")
		{
			animationBlanks = " " + StrChar(9) + StrChar(10) + StrChar(11) + StrChar(12) + StrChar(13);
		}
		return ch != "" && StrFindFirst(animationBlanks, ch) >= 0;
	}

	// Linear in the length: find both ends by position, then copy the middle once (no copy per stripped character).
	private function AnimationTrim(text : string) : string
	{
		var start, finish : int;
		finish = StrLen(text);
		while (start < finish && AnimationSpace(StrMid(text, start, 1))) { start += 1; }
		while (finish > start && AnimationSpace(StrMid(text, finish - 1, 1))) { finish -= 1; }
		if (start == 0 && finish == StrLen(text)) { return text; }
		return StrMid(text, start, finish - start);
	}

	// The piece of text that starts at pos and ends before the next separator (one character), and the position after
	// it; StrLen(text) + 1 when there is no separator left. A text with k separators gives k + 1 pieces, the last
	// possibly empty. It reads the text in windows that double, so each character is copied about twice in all instead
	// of the whole remainder once per piece.
	private function AnimationNextPiece(text : string, pos : int, separator : string, out piece : string) : int
	{
		var window, length, at : int;
		var chunk : string;
		piece = "";
		length = StrLen(text);
		window = 64;
		while (pos < length)
		{
			if (window > length - pos) { window = length - pos; }
			chunk = StrMid(text, pos, window);
			at = StrFindFirst(chunk, separator);
			if (at >= 0)
			{
				piece += StrLeft(chunk, at);
				return pos + at + 1;
			}
			piece += chunk;
			pos += window;
			if (window < 2048) { window = window * 2; }
		}
		return length + 1;
	}

	// True when the text holds no control character (0-31, 127-159).
	private function AnimationScan(text : string) : bool
	{
		var i : int;
		for (i = 0; i < 32; i += 1)
		{
			if (StrFindFirst(text, StrChar(i)) >= 0) { return false; }
		}
		for (i = 127; i < 160; i += 1)
		{
			if (StrFindFirst(text, StrChar(i)) >= 0) { return false; }
		}
		return true;
	}

	private function AnimationToken(text : string) : bool
	{
		var i : int;
		// Every token is a piece of the text AnimationDecode already scanned once; when that was clean, so is the piece.
		if (animationTextClean) { return true; }
		for (i = 0; i < 32; i += 1)
		{
			if (StrFindFirst(text, StrChar(i)) >= 0) { return false; }
		}
		for (i = 127; i < 160; i += 1)
		{
			if (StrFindFirst(text, StrChar(i)) >= 0) { return false; }
		}
		return true;
	}

	private function AnimationPath(text : string) : bool
	{
		return AnimationToken(text) && StrLen(text) > 6 &&
			(StrBeginsWith(text, "img://") || StrBeginsWith(text, "frame:")) &&
			StrFindFirst(text, ",") < 0 && StrFindFirst(text, ";") < 0 &&
			StrFindFirst(text, "|") < 0 && StrFindFirst(text, "=") < 0;
	}

	private function AnimationName(text : string) : bool
	{
		var i : int;
		if (text == "") { return false; }
		for (i = 0; i < StrLen(text); i += 1)
		{
			if (StrFindFirst("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", StrMid(text, i, 1)) < 0)
			{
				return false;
			}
		}
		return true;
	}

	// Validate decimal spelling before conversion; normalization never rounds authored seconds through a float.
	private function AnimationNumber(text : string, maximum : int, integer : bool, out normalized : string) : bool
	{
		var i, dots, digits : int;
		var ch, whole, fraction : string;
		var value : float;
		var negative : bool;
		normalized = "";
		negative = StrBeginsWith(text, "-");
		if (negative || StrBeginsWith(text, "+")) { text = StrRight(text, StrLen(text) - 1); }
		if (text == "") { return false; }
		for (i = 0; i < StrLen(text); i += 1)
		{
			ch = StrMid(text, i, 1);
			if (ch == "." && !integer) { dots += 1; }
			else if (StrFindFirst("0123456789", ch) >= 0) { digits += 1; }
			else { return false; }
		}
		if (dots > 1 || digits == 0) { return false; }
		whole = text;
		if (dots == 1)
		{
			whole = StrBeforeFirst(text, ".");
			fraction = StrAfterFirst(text, ".");
		}
		while (StrBeginsWith(whole, "0")) { whole = StrRight(whole, StrLen(whole) - 1); }
		while (StrEndsWith(fraction, "0")) { fraction = StrLeft(fraction, StrLen(fraction) - 1); }
		if (whole == "") { whole = "0"; }
		// Short bounded integer parts make conversion safe even for a very long author token.
		if (negative && (whole != "0" || fraction != "")) { return false; }
		if (StrLen(whole) > 7) { return false; }
		value = StringToFloat(whole);
		if (value > maximum || (value == maximum && fraction != "")) { return false; }
		normalized = whole;
		if (fraction != "") { normalized += "." + fraction; }
		return true;
	}

	private function AnimationFrames(text : string, out frames : string, out first : string) : bool
	{
		var path, piece : string;
		var count, pos, length : int;
		frames = "";
		first = "";
		length = StrLen(text);
		while (pos <= length)
		{
			pos = AnimationNextPiece(text, pos, ",", piece);
			path = AnimationTrim(piece);
			if (!AnimationPath(path)) { return false; }
			count += 1;
			if (count > 16) { return false; }
			if (count == 1) { first = path; }
			else { frames += ","; }
			frames += path;
		}
		return count >= 2;
	}

	private function AnimationStage(text : string, fps : int, out result : SCMFAnimationStage, out poster : string,
		out reason : string) : bool
	{
		var keys : array<string>;
		var token, key, value, normalized : string;
		var hasOffset : bool;
		var pos, length : int;
		result.stageName = "";
		result.frames = "";
		result.fps = IntToString(fps);
		result.plays = "1";
		result.direction = "forward";
		result.holdFirst = "0";
		result.holdLast = "0";
		result.offset = "0";
		result.delay = "0";
		length = StrLen(text);
		reason = "stage options";
		while (pos <= length)
		{
			pos = AnimationNextPiece(text, pos, ";", token);
			token = AnimationTrim(token);
			if (StrFindFirst(token, "=") < 0) { return false; }
			key = AnimationTrim(StrBeforeFirst(token, "="));
			value = AnimationTrim(StrAfterFirst(token, "="));
			if (keys.Contains(key) || (key != "frames" && !AnimationToken(value))) { return false; }
			keys.PushBack(key);
			switch (key)
			{
				case "stage":
					if (!AnimationName(value)) { return false; }
					result.stageName = value;
					break;
				case "frames":
					if (!AnimationFrames(value, result.frames, poster)) { reason = "frame paths"; return false; }
					break;
				case "fps":
					if (!AnimationNumber(value, 30, true, normalized) || normalized == "0") { reason = "fps range"; return false; }
					result.fps = normalized;
					break;
				case "plays":
					if (value != "forever")
					{
						if (!AnimationNumber(value, 1000000, true, normalized) || normalized == "0") { reason = "plays range"; return false; }
						value = normalized;
					}
					result.plays = value;
					break;
				case "direction":
					if (value != "forward" && value != "reverse" && value != "pingpong") { return false; }
					result.direction = value;
					break;
				case "holdFirst":
				case "holdLast":
				case "delay":
					if (!AnimationNumber(value, 3600, false, normalized)) { reason = "time range"; return false; }
					if (key == "holdFirst") { result.holdFirst = normalized; }
					else if (key == "holdLast") { result.holdLast = normalized; }
					else { result.delay = normalized; }
					break;
				case "offset":
					hasOffset = true;
					if (value != "inherit")
					{
						if (!AnimationNumber(value, 15, true, normalized)) { reason = "offset range"; return false; }
						value = normalized;
					}
					result.offset = value;
					break;
				default:
					return false;
			}
		}
		if (result.plays == "forever" && !hasOffset) { result.offset = "inherit"; }
		return result.stageName != "" && result.frames != "";
	}

	// Scans the whole text for control characters once (64 searches) instead of once per token (64 per token); a text
	// with one still checks each token, so the refusals are the same.
	private function AnimationDecode(text : string, fps : int, out canonical : string, out poster : string,
		out reason : string) : bool
	{
		var ok : bool;
		animationTextClean = StrLen(text) <= 8192 && AnimationScan(AnimationTrim(text));
		ok = AnimationDecodeText(text, fps, canonical, poster, reason);
		animationTextClean = false;
		return ok;
	}

	private function AnimationDecodeText(text : string, fps : int, out canonical : string, out poster : string,
		out reason : string) : bool
	{
		var stages : array<SCMFAnimationStage>;
		var names, keys : array<string>;
		var stageData : SCMFAnimationStage;
		var token, key, value, first, stagePoster, delay, finish, repeat, repeatFrom, normalized : string;
		var i, pos, length : int;
		var explicitRepeat : bool;
		canonical = "";
		poster = "";
		reason = "author length";
		if (StrLen(text) > 8192) { return false; }
		reason = "fps range";
		if (fps < 1 || fps > 30) { return false; }
		text = AnimationTrim(text);
		delay = "0";
		finish = "restore";
		repeat = "1";
		if (!StrBeginsWith(text, "program:v1|"))
		{
			reason = "frame paths";
			if (!AnimationFrames(text, stageData.frames, poster)) { return false; }
			stageData.stageName = "loop";
			stageData.fps = IntToString(fps);
			stageData.plays = "forever";
			stageData.direction = "forward";
			stageData.holdFirst = "0";
			stageData.holdLast = "0";
			stageData.offset = "inherit";
			stageData.delay = "0";
			stages.PushBack(stageData);
			names.PushBack("loop");
		}
		else
		{
			pos = StrFindFirst(text, "|") + 1;
			length = StrLen(text);
			while (pos <= length)
			{
				pos = AnimationNextPiece(text, pos, "|", token);
				token = AnimationTrim(token);
				reason = "program options";
				if (StrFindFirst(token, "=") < 0) { return false; }
				key = AnimationTrim(StrBeforeFirst(token, "="));
				value = AnimationTrim(StrAfterFirst(token, "="));
				if (key == "stage")
				{
					if (stages.Size() >= 8 || !AnimationStage(token, fps, stageData, stagePoster, reason)) { return false; }
					if (names.Contains(stageData.stageName)) { reason = "duplicate stage"; return false; }
					if (stages.Size() > 0 && stages[stages.Size() - 1].plays == "forever") { reason = "unreachable stage"; return false; }
					if (stages.Size() == 0) { first = stagePoster; }
					stages.PushBack(stageData);
					names.PushBack(stageData.stageName);
					continue;
				}
				if (keys.Contains(key) || !AnimationToken(value)) { return false; }
				keys.PushBack(key);
				switch (key)
				{
					case "delay":
						if (!AnimationNumber(value, 3600, false, delay)) { reason = "time range"; return false; }
						break;
					case "finish":
						if (value != "restore" && value != "hold") { return false; }
						finish = value;
						break;
					case "poster":
						if (value != "first" && !AnimationPath(value)) { reason = "poster path"; return false; }
						poster = value;
						break;
					case "join":
						if (value != "shared") { return false; }
						break;
					case "repeat":
						explicitRepeat = true;
						if (value != "forever")
						{
							if (!AnimationNumber(value, 1000000, true, normalized) || normalized == "0") { reason = "repeat range"; return false; }
							value = normalized;
						}
						repeat = value;
						break;
					case "repeatFrom":
						if (!AnimationName(value)) { return false; }
						repeatFrom = value;
						break;
					default:
						return false;
				}
			}
			if (poster == "" || poster == "first") { poster = first; }
		}
		reason = "stages required";
		if (stages.Size() == 0) { return false; }
		reason = "clashing options";
		if (explicitRepeat && stages[stages.Size() - 1].plays == "forever") { return false; }
		if (repeatFrom == "") { repeatFrom = names[0]; }
		reason = "repeat stage";
		if (!names.Contains(repeatFrom)) { return false; }
		canonical = "cmfanim:v1|delay=" + delay + "|finish=" + finish + "|poster=" + poster +
			"|join=shared|repeat=" + repeat + "|repeatFrom=" + repeatFrom;
		for (i = 0; i < stages.Size(); i += 1)
		{
			stageData = stages[i];
			canonical += "|stage=" + stageData.stageName + ";frames=" + stageData.frames + ";fps=" + stageData.fps +
				";plays=" + stageData.plays + ";direction=" + stageData.direction + ";holdFirst=" + stageData.holdFirst +
				";holdLast=" + stageData.holdLast + ";offset=" + stageData.offset + ";delay=" + stageData.delay;
		}
		reason = "";
		return true;
	}

	public function ParseAnimation(text : string, fps : int, out canonical : string, out poster : string,
		out reason : string) : bool
	{
		var i, refused : int;
		var cached : SCMFAnimationCache;
		if (StrLen(text) > 8192) { canonical = ""; poster = ""; reason = "author length"; return false; }
		for (i = 0; i < animationCache.Size(); i += 1)
		{
			if (animationCache[i].text == text && animationCache[i].fps == fps)
			{
				canonical = animationCache[i].canonical;
				poster = animationCache[i].poster;
				reason = animationCache[i].reason;
				return animationCache[i].valid;
			}
		}
		cached.text = text;
		cached.fps = fps;
		cached.valid = AnimationDecode(text, fps, cached.canonical, cached.poster, cached.reason);
		if (!cached.valid) { cached.canonical = ""; cached.poster = ""; }
		else
		{
			cached.stageCount = AnimationStageCount(cached.canonical);
			cached.frameCount = AnimationCount(cached.canonical, ",") + cached.stageCount;
		}
		if (!cached.valid)
		{
			for (i = 0; i < animationCache.Size(); i += 1)
			{
				if (!animationCache[i].valid) { refused += 1; }
			}
			if (refused >= 64)
			{
				for (i = 0; i < animationCache.Size(); i += 1)
				{
					if (!animationCache[i].valid) { animationCache.Erase(i); break; }
				}
			}
		}
		animationCache.PushBack(cached);
		canonical = cached.canonical;
		poster = cached.poster;
		reason = cached.reason;
		return cached.valid;
	}

	public function AnimationPoster(text : string, fps : int) : string
	{
		var canonical, poster, reason : string;
		if (ParseAnimation(text, fps, canonical, poster, reason)) { return poster; }
		return "";
	}

	private function AnimationLegend(dataObject : CScriptedFlashObject, pinKey : string, legendKey : string)
	{
		var claim : SCMFClaim;
		var poster : string;
		if (!PropertyWon(45) && !PropertyWon(46)) { return; }
		if (PropertyWon(45) && !(Find(2, legendKey, '', 1, claim) || Find(2, pinKey, '', 1, claim)))
		{
			if (Find(45, legendKey, '', 1, claim) || Find(45, pinKey, '', 1, claim))
			{
				poster = AnimationPoster(claim.text, claim.number);
				if (StrBeginsWith(poster, "img://")) { dataObject.SetMemberFlashString("cmfLegendIconPath", poster); }
			}
		}
		if (PropertyWon(46) && (Find(46, legendKey, '', 1, claim) || Find(46, pinKey, '', 1, claim)))
		{
			poster = AnimationPoster(claim.text, claim.number);
			if (StrBeginsWith(poster, "img://"))
			{
				dataObject.SetMemberFlashString("cmfLegendUnderPath", poster);
				if (Find(43, legendKey, '', 1, claim) || Find(43, pinKey, '', 1, claim))
				{
					dataObject.SetMemberFlashUInt("cmfLegendUnderTint", claim.number);
					dataObject.SetMemberFlashBool("cmfLegendUnderTintEnabled", true);
				}
			}
		}
	}

	private function AnimationSlotKey(claim : SCMFClaim) : string
	{
		return claim.provider + "/" + claim.propertyId + "/" + claim.level + "/" + NameToString(claim.pinType) +
			"/" + NameToString(claim.pinTag) + "/" + NameToString(claim.mapContext) + "/" +
			FloatToString(claim.placeX) + "/" + FloatToString(claim.placeY);
	}

	// Stable ids identify direct bindings across list rebuilds. Anonymous pins use an opening-local ordinal.
	private function AnimationPinKey(dataObject : CScriptedFlashObject) : string
	{
		var tag : name;
		var id, i : int;
		tag = LateTag(dataObject);
		if (IsNameValid(tag)) { return "tag/" + NameToString(tag); }
		id = dataObject.GetMemberFlashUInt("id");
		if (id != 0) { return "id/" + id + "/" + dataObject.GetMemberFlashString("type"); }
		i = animationPins.FindFirst(dataObject);
		if (i >= 0) { return "object/" + i; }
		animationPins.PushBack(dataObject);
		return "object/" + (animationPins.Size() - 1);
	}

	private function AnimationDirectOffset(provider : string, dataObject : CScriptedFlashObject, number : int,
		withdraw : bool) : bool
	{
		var offer : SCMFAnimationDirect;
		var pinKey : string;
		var i : int;
		if (number < 0 || number > 15 || dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin")) { return false; }
		pinKey = AnimationPinKey(dataObject);
		for (i = 0; i < animationDirect.Size(); i += 1)
		{
			if (animationDirect[i].pinKey == pinKey && animationDirect[i].provider == provider)
			{
				if (withdraw) { animationDirect.Erase(i); }
				else { animationDirect[i].offset = number; }
				AnimationOffsets(dataObject, dataObject.GetMemberFlashString("type"), dataObject.GetMemberFlashString("filteredType"), LateTag(dataObject), CMFLevelPlace());
				return true;
			}
		}
		if (!withdraw)
		{
			offer.pin = dataObject;
			offer.pinKey = pinKey;
			offer.provider = provider;
			offer.offset = number;
			animationDirect.PushBack(offer);
			AnimationOffsets(dataObject, dataObject.GetMemberFlashString("type"), dataObject.GetMemberFlashString("filteredType"), LateTag(dataObject), CMFLevelPlace());
		}
		return true;
	}

	private function AnimationOffset(provider : string, dataObject : CScriptedFlashObject, pinKey : string,
		legendKey : string, pinTag : name, maxLevel : int, out owner : string) : int
	{
		var i, next, best, rank, bestRank : int;
		var ownKey : string;
		var matches, secondary : bool;
		owner = "";
		if (provider == "") { return 0; }
		ownKey = AnimationPinKey(dataObject);
		for (i = 0; i < animationDirect.Size(); i += 1)
		{
			if (animationDirect[i].provider == provider && animationDirect[i].pinKey == ownKey)
			{
				owner = provider;
				return animationDirect[i].offset;
			}
		}
		best = -1;
		bestRank = -1;
		if (!PropertyWon(47)) { return 0; }
		next = propertyFirst[47];
		while (next >= 0)
		{
			i = next;
			next = propertyNext[i];
			if (winners[i].provider != provider) { continue; }
			matches = Covers(winners[i], pinKey, pinTag, maxLevel);
			secondary = !matches && Covers(winners[i], legendKey, '', 1);
			if ((!matches && !secondary) || ((winners[i].level == 2 || winners[i].level == CMFLevelPlace()) && CMFKindHidden(pinKey))) { continue; }
			rank = Specific(winners[i]) * 2;
			if (matches) { rank += 1; }
			if (best < 0 || rank > bestRank) { best = i; bestRank = rank; }
		}
		if (best < 0) { return 0; }
		owner = provider;
		return winners[best].number;
	}

	private function AnimationOffsets(dataObject : CScriptedFlashObject, pinKey : string, legendKey : string,
		pinTag : name, maxLevel : int)
	{
		var owner, provider : string;
		var offset : int;
		var oldPinKey, oldVariant : string;
		var oldPlaceOk : bool;
		var oldX, oldY : float;
		oldPinKey = pinKeyNow;
		oldVariant = variantNow;
		oldPlaceOk = placeOk;
		oldX = placeX;
		oldY = placeY;
		SetPinContext(dataObject, pinKey);
		provider = CMFPinOwner(dataObject, "cmfIconFramesSourceBy");
		if (provider != "")
		{
			offset = AnimationOffset(provider, dataObject, pinKey, legendKey, pinTag, maxLevel, owner);
			dataObject.SetMemberFlashInt("cmfIconFrameOffset", offset);
			dataObject.SetMemberFlashString("cmfIconFrameOffsetBy", owner);
		}
		provider = CMFPinOwner(dataObject, "cmfIconUnderFramesSourceBy");
		if (provider != "")
		{
			offset = AnimationOffset(provider, dataObject, pinKey, legendKey, pinTag, maxLevel, owner);
			dataObject.SetMemberFlashInt("cmfIconUnderFrameOffset", offset);
			dataObject.SetMemberFlashString("cmfIconUnderFrameOffsetBy", owner);
		}
		pinKeyNow = oldPinKey;
		variantNow = oldVariant;
		placeOk = oldPlaceOk;
		placeX = oldX;
		placeY = oldY;
	}

	// Release the current direct layer; delivered panel snapshots own their art independently.
	private function AnimationWithdraw(provider : string, dataObject : CScriptedFlashObject, propertyId : int) : bool
	{
		var prefix, offset, owner, pinKey : string;
		var i : int;
		if (provider == "" || !dataObject || (propertyId != 45 && propertyId != 46)) { return false; }
		prefix = "cmfIconFrames";
		offset = "cmfIconFrameOffset";
		if (propertyId == 46) { prefix = "cmfIconUnderFrames"; offset = "cmfIconUnderFrameOffset"; }
		owner = CMFPinOwner(dataObject, prefix + "By");
		if (owner == "") { return true; }
		if (owner != provider) { return false; }
		dataObject.SetMemberFlashString(prefix, "");
		dataObject.SetMemberFlashInt(prefix + "Fps", 0);
		dataObject.SetMemberFlashString(prefix + "Key", "");
		dataObject.SetMemberFlashString(prefix + "SourceBy", "");
		dataObject.SetMemberFlashString(prefix + "By", "");
		dataObject.SetMemberFlashInt(offset, 0);
		dataObject.SetMemberFlashString(offset + "By", "");
		pinKey = AnimationPinKey(dataObject);
		for (i = animationBindings.Size() - 1; i >= 0; i -= 1)
		{
			if (animationBindings[i].pinKey == pinKey && animationBindings[i].propertyId == propertyId)
			{
				animationBindings.Erase(i);
				animationBindingKeys.Erase(i);
			}
		}
		AnimationPrune();
		return true;
	}

	private function AnimationReference(dataObject : CScriptedFlashObject, propertyId : int, text : string, fps : int)
	{
		var binding : SCMFAnimationBinding;
		var pinKey : string;
		var i : int;
		pinKey = AnimationPinKey(dataObject);
		i = animationBindingKeys.FindFirst(pinKey + "#" + propertyId);
		if (i >= 0)
		{
			if (animationBindings[i].text == text && animationBindings[i].fps == fps) { return; }
			animationBindings[i].text = text;
			animationBindings[i].fps = fps;
			AnimationPrune();
			return;
		}
		binding.pinKey = pinKey;
		binding.propertyId = propertyId;
		binding.text = text;
		binding.fps = fps;
		animationBindings.PushBack(binding);
		animationBindingKeys.PushBack(pinKey + "#" + propertyId);
	}

	// Pins without a tag or an id are keyed by their data object, and every build makes new objects, so the previous
	// build's object keys can never match again. They are dropped when a build starts (they grew by one set per rebuild).
	private function AnimationForgetObjects()
	{
		var i : int;
		for (i = animationBindings.Size() - 1; i >= 0; i -= 1)
		{
			if (StrBeginsWith(animationBindings[i].pinKey, "object/"))
			{
				animationBindings.Erase(i);
				animationBindingKeys.Erase(i);
			}
		}
		for (i = animationDirect.Size() - 1; i >= 0; i -= 1)
		{
			if (StrBeginsWith(animationDirect[i].pinKey, "object/"))
			{
				animationDirect.Erase(i);
			}
		}
		animationPins.Clear();
	}

	private function AnimationPrune()
	{
		var i, j : int;
		var referenced : bool;
		for (i = animationCache.Size() - 1; i >= 0; i -= 1)
		{
			referenced = false;
			for (j = 0; j < animationBindings.Size() && !referenced; j += 1)
			{
				referenced = animationBindings[j].text == animationCache[i].text && animationBindings[j].fps == animationCache[i].fps;
			}
			for (j = 0; j < claims.Size() && !referenced; j += 1)
			{
				referenced = (claims[j].propertyId == 45 || claims[j].propertyId == 46) &&
					claims[j].text == animationCache[i].text && claims[j].number == animationCache[i].fps;
			}
			if (animationCache[i].valid && !referenced) { animationCache.Erase(i); }
		}
	}

	// How many times a one-character delimiter occurs, by pieces (linear; no copy of the remainder per hit).
	private function AnimationCount(text : string, delimiter : string) : int
	{
		var pos, length, count : int;
		var piece : string;
		length = StrLen(text);
		while (pos <= length)
		{
			pos = AnimationNextPiece(text, pos, delimiter, piece);
			count += 1;
		}
		return count - 1;
	}

	// The stages of a canonical program: its pieces between "|" that start with "stage=".
	private function AnimationStageCount(canonical : string) : int
	{
		var pos, length, count : int;
		var piece : string;
		length = StrLen(canonical);
		while (pos <= length)
		{
			pos = AnimationNextPiece(canonical, pos, "|", piece);
			if (StrBeginsWith(piece, "stage=")) { count += 1; }
		}
		return count;
	}

	private function AnimationAccepted(provider : string, propertyId : int, text : string, fps : int)
	{
		var i : int;
		for (i = 0; i < animationCache.Size(); i += 1)
		{
			if (animationCache[i].text == text && animationCache[i].fps == fps && animationCache[i].valid)
			{
				AnimationNote(provider, propertyId, "accepted stages=" + animationCache[i].stageCount +
					" frames=" + animationCache[i].frameCount + " fps=" + fps);
				return;
			}
		}
	}

	private function AnimationNote(provider : string, propertyId : int, reason : string)
	{
		var key : string;
		var i : int;
		key = "provider=" + provider + " layer=" + propertyId + " reason=" + reason;
		i = animationNotes.FindFirst(key);
		if (i < 0) { animationNotes.PushBack(key); animationCounts.PushBack(1); }
		else { animationCounts[i] += 1; }
	}

	public function SendAnimationOptions(menu : CR4MapMenu)
	{
		var storage : CScriptedFlashValueStorage;
		var item : CScriptedFlashObject;
		var i, claimIndex : int;
		if (!menu) { return; }
		// A distinct menu owns a fresh opening even if the old shown/close callbacks lag.
		if (animationOptionsRead && animationMenu != menu) { CloseAnimations(); }
		if (!animationOptionsRead)
		{
			if (dirty) { Prepare(); }
			for (i = 0; i < animationClaimIndices.Size(); i += 1)
			{
				claimIndex = animationClaimIndices[i];
				AnimationAccepted(claims[claimIndex].provider, claims[claimIndex].propertyId, claims[claimIndex].text, claims[claimIndex].number);
			}
			// The player's rate (0 = Off) never exceeds the core's ceiling; Off still sends the ceiling.
			animationCap = CMFSettingsAnimatedPins(menuPresent);
			animationEnabled = animationCap > 0;
			if (animationCap <= 0 || animationCap > AnimationFpsCap()) { animationCap = AnimationFpsCap(); }
			animationDragPause = CMFSettingsAnimationDragPause(menuPresent);
			animationMemory = CMFSettingsAnimationMemory(menuPresent);
			animationOptionsRead = true;
			animationMenu = menu;
			CMFLog("animations options enabled=" + CMFYesNo(animationEnabled) + " fpsCap=" + animationCap + " dragPause=" + CMFYesNo(animationDragPause) + " cacheMb=" + animationMemory);
		}
		storage = menu.GetMenuFlashValueStorage();
		if (!storage) { return; }
		item = storage.CreateTempFlashObject();
		item.SetMemberFlashBool("enabled", animationEnabled);
		item.SetMemberFlashInt("fpsCap", animationCap);
		item.SetMemberFlashBool("dragPause", animationDragPause);
		item.SetMemberFlashInt("cacheMb", animationMemory);
		storage.SetFlashObject("cmf.map.animations", item);
	}

	// Animation readiness can precede OnMenuShown; navigation is not its lifetime owner.
	public function CloseAnimationMenu(menu : CR4MapMenu)
	{
		if (menu && animationMenu == menu) { CloseAnimations(); }
	}

	public function CloseAnimations()
	{
		var i : int;
		for (i = 0; i < animationNotes.Size(); i += 1)
		{
			CMFLog("animations claims " + animationNotes[i] + " count=" + animationCounts[i]);
		}
		animationNotes.Clear();
		animationCounts.Clear();
		animationOptionsRead = false;
		animationMenu = NULL;
		animationDirect.Clear();
		animationPins.Clear();
		animationBindings.Clear();
		animationBindingKeys.Clear();
		for (i = animationCache.Size() - 1; i >= 0; i -= 1)
		{
			if (!animationCache[i].valid) { animationCache.Erase(i); }
		}
		AnimationPrune();
	}

	public function RequestRefresh()
	{
		dirty = true;
		CMFLog("refresh requested claims=" + claims.Size());
	}


	// Revision 13: target validation shared by stored claims and withdrawal commands.
	public function EveryPinProperty(propertyId : int) : bool
	{
		return propertyId == 1 || propertyId == 3 || propertyId == 9 ||
			(propertyId >= 10 && propertyId <= 15) || propertyId == 17 || propertyId == 18 ||
			propertyId == 19 || propertyId == 22 || (propertyId >= 28 && propertyId <= 36) ||
			propertyId == 39 || (propertyId >= 42 && propertyId <= 48);
	}

	private function ClaimTargetOk(claim : SCMFClaim) : bool
	{
		if (claim.provider == "" || !CMFHasProperty(claim.propertyId) ||
			claim.propertyId == 38 || claim.propertyId == 40)
		{
			return false;
		}
		if (IsNameValid(claim.mapContext) && claim.propertyId != 5 && claim.propertyId != 9)
		{
			return false;
		}
		if (claim.level == 0)
		{
			return EveryPinProperty(claim.propertyId) && !IsNameValid(claim.pinType) && !IsNameValid(claim.pinTag);
		}
		if (claim.level == 2)
		{
			return CMFOnePinProperty(claim.propertyId) && IsNameValid(claim.pinTag);
		}
		if (claim.level == CMFLevelPlace())
		{
			return CMFOnePinProperty(claim.propertyId) && IsNameValid(claim.pinType) &&
				claim.placeX - claim.placeX == 0.0 && claim.placeY - claim.placeY == 0.0;
		}
		if (claim.level != 1 || !IsNameValid(claim.pinType))
		{
			return false;
		}
		if (CMFIsPictureProperty(claim.propertyId))
		{
			return CMFPictureTargetOk(claim.propertyId, NameToString(claim.pinType));
		}
		return claim.propertyId != 37 || StrLower(NameToString(claim.pinType)) != "all";
	}

	// Keep the public rejection words stable. Value parsing remains a single registration step.
	private function ClaimRejectReason(claim : SCMFClaim) : string
	{
		if (claim.provider == "" ||
			((claim.level == 1 || claim.level == CMFLevelPlace()) && !IsNameValid(claim.pinType)) ||
			(claim.level == 2 && !IsNameValid(claim.pinTag))) { return "empty"; }
		if (!CMFHasProperty(claim.propertyId) || claim.propertyId == 38 ||
			claim.propertyId == 40) { return "unknown"; }
		if ((claim.level == 2 || claim.level == CMFLevelPlace()) && !CMFOnePinProperty(claim.propertyId))
		{
			return "level";
		}
		if (IsNameValid(claim.mapContext) && claim.propertyId != 5 && claim.propertyId != 9) { return "context"; }
		if (claim.level == 0)
		{
			if (!EveryPinProperty(claim.propertyId)) { return "level"; }
			if (IsNameValid(claim.pinType) || IsNameValid(claim.pinTag)) { return "target"; }
		}
		else if (claim.level == 1)
		{
			if ((CMFIsPictureProperty(claim.propertyId) &&
				!CMFPictureTargetOk(claim.propertyId, NameToString(claim.pinType))) ||
				(claim.propertyId == 37 && StrLower(NameToString(claim.pinType)) == "all")) { return "target"; }
		}
		else if (claim.level == CMFLevelPlace())
		{
			if (claim.placeX - claim.placeX != 0.0 || claim.placeY - claim.placeY != 0.0) { return "range"; }
		}
		else if (claim.level != 2) { return "level"; }
		return "";
	}

	private function WithdrawClaim(command : SCMFClaim) : bool
	{
		var incoming : SCMFClaim;
		var i : int;
		incoming = command;
		incoming.propertyId = command.number;
		if (command.text != "" || !ClaimTargetOk(incoming))
		{
			CMFLog("rejected provider=" + command.provider + " property=40 reason=withdraw");
			return false;
		}
		for (i = claims.Size() - 1; i >= 0; i -= 1)
		{
			if (claims[i].provider == incoming.provider && SameSlot(claims[i], incoming))
			{
				claims.Erase(i);
				dirty = true;
				Report("withdrawn", incoming);
			}
		}
		if (incoming.propertyId == 45 || incoming.propertyId == 46) { AnimationPrune(); }
		return true;
	}

	// Signed decimal grammar; conversion only after validation. Pairs are cached at registration.
	private function ClaimNumber(text : string, out value : float) : bool
	{
		var i, digits, dots : int;
		var ch : string;
		while (StrBeginsWith(text, " ")) { text = StrRight(text, StrLen(text) - 1); }
		while (StrEndsWith(text, " ")) { text = StrLeft(text, StrLen(text) - 1); }
		if (text == "") { return false; }
		for (i = 0; i < StrLen(text); i += 1)
		{
			ch = StrMid(text, i, 1);
			if (i == 0 && (ch == "-" || ch == "+")) { continue; }
			if (ch == ".")
			{
				dots += 1;
				if (dots > 1) { return false; }
			}
			else if (StrFindFirst("0123456789", ch) >= 0) { digits += 1; }
			else { return false; }
		}
		if (digits == 0) { return false; }
		value = StringToFloat(text);
		return value - value == 0.0;
	}

	private function NewPinValueOk(propertyId : int, text : string, number : int, out x : float, out y : float) : bool
	{
		x = 0.0;
		y = 0.0;
		if (propertyId == 31 || propertyId == 42)
		{
			return (StrBeginsWith(text, "img://") && StrLen(text) > 6) ||
				(StrBeginsWith(text, "frame:") && StrLen(text) > 6);
		}
		if (propertyId == 3) { return number >= 0 && number <= 16777215; }
		if (propertyId == 47) { return number >= 0 && number <= 15; }
		if (propertyId == 48) { return number == 0 || number == 1; }
		if (propertyId == 39) { return number == 0 || (number >= 200 && number <= 1920); }
		if (propertyId == 32 || propertyId == 44) { return number >= 25 && number <= 400; }
		if (propertyId == 33) { return number >= 0 && number <= 100; }
		if (propertyId == 34) { return number >= -1000 && number <= 1000; }
		if (propertyId == 41 || propertyId == 43) { return number >= 0 && number <= 16777215; }
		if (propertyId == 35 || propertyId == 36)
		{
			if (StrFindFirst(text, ",") < 0 || !ClaimNumber(StrBeforeFirst(text, ","), x) ||
				!ClaimNumber(StrAfterFirst(text, ","), y)) { return false; }
			if (propertyId == 35) { return x >= -50.0 && x <= 50.0 && y >= -50.0 && y <= 50.0; }
			return x <= y;
		}
		return true;
	}

	public function Upsert(claim : SCMFClaim) : bool
	{
		var incoming : SCMFClaim;
		var i : int;
		var flags : int;
		var tabs, reason, canonical, poster : string;
		incoming = claim;
		if (incoming.propertyId == 40)
		{
			return WithdrawClaim(incoming);
		}
		reason = ClaimRejectReason(incoming);
		if (reason == "" && (incoming.propertyId == 45 || incoming.propertyId == 46))
		{
			if (incoming.number == 0)
			{
				incoming.number = incoming.propertyId;
				incoming.propertyId = 40;
				incoming.text = "";
				return WithdrawClaim(incoming);
			}
			if (!ParseAnimation(incoming.text, incoming.number, canonical, poster, reason))
			{
				AnimationNote(incoming.provider, incoming.propertyId, reason);
				AnimationPrune();
				return false;
			}
		}
		if (reason == "" && !NewPinValueOk(incoming.propertyId, incoming.text, incoming.number, incoming.valueX, incoming.valueY))
		{
			reason = "range";
		}
		if (reason != "")
		{
			CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=" + reason);
			return false;
		}
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
		// Version 11: a whole filter tab is hidden by a type claim on the tab's name, never All.
		if (incoming.propertyId == CMFPropertyTabHidden())
		{
			if (incoming.level != 1 || StrLower(NameToString(incoming.pinType)) == "all")
			{
				CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=target");
				return false;
			}
			if (incoming.number != 0)
			{
				incoming.number = 1;
			}
		}
		if ((incoming.propertyId == CMFPropertyPinScale() && (incoming.number < 25 || incoming.number > 400)) ||
			(incoming.propertyId == CMFPropertyLabelPlace() && (incoming.number < 0 || incoming.number > 10000)) ||
			(incoming.propertyId == CMFPropertyLabelColor() && (incoming.number < 0 || incoming.number > 16777215)) ||
			(incoming.propertyId == 3 && (incoming.number < 0 || incoming.number > 16777215)) ||
			(incoming.propertyId == CMFPropertySpreadRank() && (incoming.number < 0 || incoming.number > 1000)) ||
			(incoming.propertyId == CMFPropertyHoverName() && (incoming.number < 0 || incoming.number > 3)) ||
			((incoming.propertyId == CMFPropertyInfoTitle() || incoming.propertyId == CMFPropertyInfoText()) &&
			incoming.number != CMFInfoReplace() && incoming.number != CMFInfoAdd()) ||
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
			((incoming.level == 1 || incoming.level == CMFLevelPlace()) && !IsNameValid(incoming.pinType)) ||
			(incoming.level == 2 && !IsNameValid(incoming.pinTag)))
		{
			CMFLog("rejected provider=" + incoming.provider + " property=" + incoming.propertyId + " reason=empty");
			return false;
		}
		if (incoming.level == 2) { DeclareTag(incoming.provider, incoming.pinTag); }
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].provider == incoming.provider && SameSlot(claims[i], incoming))
			{
				// Version 12: the same claim again changes nothing, so the winners are not prepared again.
				if (claims[i].text == incoming.text && claims[i].number == incoming.number)
				{
					return true;
				}
				incoming.order = claims[i].order;
				claims[i] = incoming;
				dirty = true;
				if (incoming.propertyId == 45 || incoming.propertyId == 46) { AnimationPrune(); }
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
		if (incoming.propertyId == 45 || incoming.propertyId == 46) { AnimationPrune(); }
		return true;
	}

	public function ReleaseProvider(provider : string)
	{
		var i, released : int;
		var animationReleased : bool;
		NoteProviderPresent(provider);
		released = 0;
		for (i = claims.Size() - 1; i >= 0; i -= 1)
		{
			if (claims[i].provider == provider)
			{
				if (claims[i].propertyId == 45 || claims[i].propertyId == 46) { animationReleased = true; }
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
				dirty = true;
			}
		}
		for (i = itemStyles.Size() - 1; i >= 0; i -= 1)
		{
			if (itemStyles[i].provider == provider) { itemStyles.Erase(i); released += 1; dirty = true; }
		}
		for (i = addedPins.Size() - 1; i >= 0; i -= 1)
		{
			if (StrLower(addedPins[i].provider) == StrLower(provider)) { addedPins.Erase(i); released += 1; }
		}
		for (i = declaredTagProviders.Size() - 1; i >= 0; i -= 1)
		{
			if (StrLower(declaredTagProviders[i]) == StrLower(provider))
			{
				declaredTagProviders.Erase(i);
				declaredTagNames.Erase(i);
				dirty = true;
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
		for (i = labelHideOffers.Size() - 1; i >= 0; i -= 1)
		{
			if (labelHideOffers[i] == provider) { labelHideOffers.Erase(i); }
		}
		if (animationReleased) { AnimationPrune(); }
		CMFLog("released provider=" + provider + " claims=" + released);
	}

	private function AddedPinWordOk(text : string) : bool
	{
		var i : int;
		if (text == "") { return false; }
		for (i = 0; i < StrLen(text); i += 1)
		{
			if (StrFindFirst("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-", StrMid(text, i, 1)) < 0)
			{
				return false;
			}
		}
		return true;
	}

	private function AddedPinTagOk(provider : string, tag : name) : bool
	{
		var text : string;
		text = NameToString(tag);
		return AddedPinWordOk(provider) && IsNameValid(tag) && AddedPinWordOk(text) &&
			StrBeginsWith(StrLower(text), StrLower(provider) + ".") && StrLen(text) > StrLen(provider) + 1;
	}

	public function UpsertAddedPin(pin : SCMFAddedPin) : bool
	{
		var i : int;
		if (!AddedPinTagOk(pin.provider, pin.tag) || !IsNameValid(pin.pinType) || !IsNameValid(pin.area) ||
			pin.area == 'AN_Undefined' || !AddedPinWordOk(NameToString(pin.pinType)) ||
			!AddedPinWordOk(NameToString(pin.area)) || pin.x - pin.x != 0.0 || pin.y - pin.y != 0.0)
		{
			CMFLog("added pin rejected provider=" + pin.provider + " tag=" + NameToString(pin.tag));
			return false;
		}
		if (pin.area == 'AN_Velen') { pin.area = 'AN_NMLandNovigrad'; }
		DeclareTag(pin.provider, pin.tag);
		for (i = 0; i < addedPins.Size(); i += 1)
		{
			if (StrLower(addedPins[i].provider) == StrLower(pin.provider) &&
				StrLower(NameToString(addedPins[i].tag)) == StrLower(NameToString(pin.tag)))
			{
				if (addedPins[i].pinType == pin.pinType && addedPins[i].area == pin.area && addedPins[i].x == pin.x &&
					addedPins[i].y == pin.y && addedPins[i].label == pin.label && addedPins[i].description == pin.description)
				{
					return true;
				}
				pin.provider = addedPins[i].provider;
				pin.tag = addedPins[i].tag;
				pin.order = addedPins[i].order;
				addedPins[i] = pin;
				return true;
			}
		}
		nextOrder += 1;
		pin.order = nextOrder;
		addedPins.PushBack(pin);
		return true;
	}

	public function RemoveAddedPin(provider : string, tag : name) : bool
	{
		var i : int;
		if (!AddedPinTagOk(provider, tag)) { return false; }
		for (i = addedPins.Size() - 1; i >= 0; i -= 1)
		{
			if (StrLower(addedPins[i].provider) == StrLower(provider) &&
				StrLower(NameToString(addedPins[i].tag)) == StrLower(NameToString(tag)))
			{
				addedPins.Erase(i);
			}
		}
		return true;
	}

	private function AddedPinDistance(currentArea : bool, position : Vector, playerPosition : Vector) : float
	{
		if (currentArea) { return VecDistanceSquared2D(playerPosition, position); }
		return 0.0;
	}

	public function AppendAddedPins(menu : CR4MapMenu, out pins : CScriptedFlashArray, area : name)
	{
		var storage : CScriptedFlashValueStorage;
		var item : CScriptedFlashObject;
		var ids : array<int>;
		var position, playerPosition : Vector;
		var currentArea : bool;
		var i, id : int;
		if (addedPins.Size() == 0 || !menu || !pins) { return; }
		storage = menu.GetMenuFlashValueStorage();
		if (!storage) { return; }
		currentArea = menu.IsCurrentAreaShown();
		if (thePlayer) { playerPosition = thePlayer.GetWorldPosition(); }
		else { currentArea = false; }
		// Conditional on registry content; never overwrite an existing pin sharing an id.
		for (i = 0; i < pins.GetLength(); i += 1)
		{
			item = pins.GetElementFlashObject(i);
			if (item) { ids.PushBack(item.GetMemberFlashUInt("id")); }
		}
		for (i = 0; i < addedPins.Size(); i += 1)
		{
			if (addedPins[i].area != area) { continue; }
			id = NameToFlashUInt(addedPins[i].tag);
			if (ids.Contains(id)) { continue; }
			position.X = addedPins[i].x;
			position.Y = addedPins[i].y;
			position.Z = 0.0;
			item = storage.CreateTempFlashObject("red.game.witcher3.data.StaticMapPinData");
			item.SetMemberFlashUInt("id", id);
			item.SetMemberFlashUInt("areaId", NameToFlashUInt(area));
			item.SetMemberFlashUInt("journalAreaId", NameToFlashUInt(theGame.GetCommonMapManager().GetJournalAreaByPosition(area, position)));
			item.SetMemberFlashNumber("posX", addedPins[i].x);
			item.SetMemberFlashNumber("posY", addedPins[i].y);
			item.SetMemberFlashNumber("distance", AddedPinDistance(currentArea, position, playerPosition));
			item.SetMemberFlashString("type", NameToString(addedPins[i].pinType));
			item.SetMemberFlashString("filteredType", NameToString(addedPins[i].pinType));
			item.SetMemberFlashString("label", addedPins[i].label);
			item.SetMemberFlashString("description", addedPins[i].description);
			item.SetMemberFlashBool("isPlayer", false);
			item.SetMemberFlashBool("isUserPin", false);
			item.SetMemberFlashBool("isQuest", false);
			item.SetMemberFlashBool("isFastTravel", false);
			item.SetMemberFlashNumber("radius", 0);
			pins.PushBackFlashObject(item);
			ids.PushBack(id);
		}
	}

	// Revision 13: normalize the explicit item grammar once, without guessing prefixes.
	public function ItemTarget(part : name, key : name, target : string, out item : string, out kind : string) : bool
	{
		var i : int;
		item = target;
		kind = "";
		if (target == "") { return false; }
		if (part == 'legendRow') { kind = "type"; return StrFindFirst(target, ":") < 0; }
		if (part == 'legendTab')
		{
			kind = "tabName";
			if (StrFindFirst(target, ":") < 0) { return true; }
			if (!StrBeginsWith(target, "id:")) { return false; }
			item = StrAfterFirst(target, ":");
			if (item == "") { return false; }
			for (i = 0; i < StrLen(item); i += 1)
			{
				if (StrFindFirst("0123456789", StrMid(item, i, 1)) < 0) { return false; }
			}
			while (StrLen(item) > 1 && StrBeginsWith(item, "0")) { item = StrRight(item, StrLen(item) - 1); }
			kind = "tabId";
			return true;
		}
		if ((part == 'title' && key == 'text') || part == 'world') { kind = "area"; return StrFindFirst(target, ":") < 0; }
		if (part != 'tooltip' && part != 'pinLabel' && part != 'pinName' && part != 'pinButton' && part != 'pin') { return false; }
		kind = "type";
		if (StrFindFirst(target, ":") < 0) { return true; }
		if (!StrBeginsWith(target, "type:") && !StrBeginsWith(target, "tag:")) { return false; }
		kind = StrBeforeFirst(target, ":");
		item = StrAfterFirst(target, ":");
		return item != "" && StrFindFirst(item, ":") < 0;
	}

	public function UpsertItemStyle(styleEntry : SCMFThemeEntry) : bool
	{
		var i : int;
		for (i = 0; i < itemStyles.Size(); i += 1)
		{
			if (itemStyles[i].provider == styleEntry.provider && itemStyles[i].target == styleEntry.target &&
				itemStyles[i].item == styleEntry.item && itemStyles[i].itemKind == styleEntry.itemKind && itemStyles[i].key == styleEntry.key)
			{
				if (styleEntry.text == "unset") { itemStyles.Erase(i); dirty = true; return true; }
				if (itemStyles[i].text == styleEntry.text && itemStyles[i].number == styleEntry.number) { return true; }
				styleEntry.order = itemStyles[i].order;
				itemStyles[i] = styleEntry;
				dirty = true;
				return true;
			}
		}
		if (styleEntry.text == "unset") { return true; }
		nextOrder += 1;
		styleEntry.order = nextOrder;
		itemStyles.PushBack(styleEntry);
		dirty = true;
		return true;
	}

	private function ItemStyleOwner(styleEntry : SCMFThemeEntry) : string
	{
		var i, choice : int;
		var owner, answer : string;
		choice = PartKeyChoice(styleEntry.target, styleEntry.key);
		if (choicesActive && choice >= 0) { answer = decideAnswer[choice]; }
		if (answer == "vanilla") { return ""; }
		if (answer == "@order") { answer = ""; }
		for (i = 0; i < itemStyles.Size(); i += 1)
		{
			if (itemStyles[i].target == styleEntry.target && itemStyles[i].item == styleEntry.item &&
				itemStyles[i].itemKind == styleEntry.itemKind && PartKeyChoice(styleEntry.target, itemStyles[i].key) == choice &&
				!ChoiceOnlySkips(choice, itemStyles[i].provider))
			{
				if (answer != "" && itemStyles[i].provider == answer) { return answer; }
				if (owner == "" || PieceBeats(choice, itemStyles[i].provider, owner)) { owner = itemStyles[i].provider; }
			}
		}
		if (answer != "" && fallVanilla) { return ""; }
		return owner;
	}

	private function PrepareItemStyles()
	{
		var i : int;
		hintListPreparedOwner = ThemeStyleOwner('hints', 'list');
		itemStyleOwners.Clear();
		for (i = 0; i < itemStyles.Size(); i += 1) { itemStyleOwners.PushBack(ItemStyleOwner(itemStyles[i])); }
	}

	// Native binding codes and localized prompts travel with the winning style payload.
	private function WriteFoldMetadata(item : CScriptedFlashObject, styleEntry : SCMFThemeEntry, storage : CScriptedFlashValueStorage)
	{
		var keys : array<EInputKey>;
		var codes : CScriptedFlashArray;
		var words : string;
		var i : int;
		if (styleEntry.target != 'tooltip') { return; }
		if (styleEntry.key == 'foldKeyKb' || styleEntry.key == 'foldKeyPad')
		{
			if (styleEntry.key == 'foldKeyPad') { theInput.GetPadKeysForActionStr(styleEntry.text, keys); }
			else { theInput.GetPCKeysForActionStr(styleEntry.text, keys); }
			codes = storage.CreateTempFlashArray();
			words = "";
			for (i = 0; i < keys.Size(); i += 1)
			{
				// Keyboard folds never capture pointer buttons or wheel/axis events used by native dragging.
				if (styleEntry.key == 'foldKeyKb' && ((int)keys[i] <= 7 || (int)keys[i] >= 1000)) { continue; }
				codes.PushBackFlashInt((int)keys[i]);
				if (words == "") { words = GetIconForKey(keys[i], true); }
			}
			item.SetMemberFlashArray("fk", codes);
			item.SetMemberFlashString("fg", words);
		}
		else if (styleEntry.key == 'foldMoreText' || styleEntry.key == 'foldLessText')
		{
			words = styleEntry.text;
			if (StrBeginsWith(words, "[[") && StrEndsWith(words, "]]"))
			{
				words = GetLocStringByKeyExt(StrMid(words, 2, StrLen(words) - 4));
			}
			item.SetMemberFlashString("fl", words);
		}
	}

	// Same precedence as cmfPartFor: whole part, filtered type, own type, typed tag.
	private function InfoFoldOwner(pin : CScriptedFlashObject) : string
	{
		var owner, ownType, filtered : string;
		var i, rank, bestRank, pinId : int;
		if (!pin) { return ""; }
		if (dirty) { Prepare(); }
		owner = ThemeStyleOwner('tooltip', 'foldTag');
		ownType = pin.GetMemberFlashString("type");
		filtered = pin.GetMemberFlashString("filteredType");
		pinId = pin.GetMemberFlashUInt("id");
		bestRank = 0;
		for (i = 0; i < itemStyles.Size(); i += 1)
		{
			if (itemStyles[i].target != 'tooltip' || itemStyles[i].key != 'foldTag' ||
				itemStyleOwners[i] != itemStyles[i].provider) { continue; }
			rank = 0;
			if (itemStyles[i].itemKind == "type" && itemStyles[i].item == filtered) { rank = 1; }
			if (itemStyles[i].itemKind == "type" && itemStyles[i].item == ownType) { rank = 2; }
			if (pinId != 0 && itemStyles[i].itemKind == "tag" &&
				ResolveKnownTag(itemStyles[i].provider, itemStyles[i].item) == pinId) { rank = 3; }
			if (rank > bestRank) { bestRank = rank; owner = itemStyles[i].provider; }
		}
		return owner;
	}

	public function InfoFold(menu : CR4MapMenu, provider : string, open : bool)
	{
		var rootFlash, box, pin : CScriptedFlashObject;
		if (!menu || provider == "") { return; }
		rootFlash = menu.GetMenuFlash();
		if (!rootFlash) { return; }
		box = rootFlash.GetMemberFlashObject("tooltipInstance");
		if (!box || !box.GetMemberFlashBool("visible") || !box.GetMemberFlashBool("cmfFoldHas") ||
			box.GetMemberFlashString("cmfFoldOwner") != provider || box.GetMemberFlashBool("cmfFoldOpen") != open) { return; }
		pin = box.GetMemberFlashObject("cmfPinContext");
		if (InfoFoldOwner(pin) != provider) { return; }
		OnInfoFold(menu, provider, open);
	}

	// Chainable provider hook; the default has no map behaviour.
	public function OnInfoFold(menu : CR4MapMenu, provider : string, open : bool)
	{
	}

	private function SendItemStyles(storage : CScriptedFlashValueStorage)
	{
		var list : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var i : int;
		if (itemStyles.Size() == 0 && !itemStylesSent) { return; }
		list = storage.CreateTempFlashArray();
		for (i = 0; i < itemStyles.Size(); i += 1)
		{
			if (itemStyleOwners[i] != itemStyles[i].provider) { continue; }
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("p", NameToString(itemStyles[i].target));
			item.SetMemberFlashString("q", itemStyles[i].itemKind);
			if (itemStyles[i].itemKind == "tag")
			{
				item.SetMemberFlashUInt("u", ResolveKnownTag(itemStyles[i].provider, itemStyles[i].item));
			}
			item.SetMemberFlashString("t", itemStyles[i].item);
			item.SetMemberFlashString("y", NameToString(itemStyles[i].key));
			item.SetMemberFlashString("s", itemStyles[i].text);
			item.SetMemberFlashNumber("n", itemStyles[i].number);
			item.SetMemberFlashString("o", itemStyles[i].provider);
			WriteFoldMetadata(item, itemStyles[i], storage);
			item.SetMemberFlashInt("c", PartKeyChoice(itemStyles[i].target, itemStyles[i].key));
			list.PushBackFlashObject(item);
		}
		storage.SetFlashArray("cmf.map.itemStyles", list);
		itemStylesSent = itemStyles.Size() > 0;
	}

	private function HintListOwner() : string
	{
		return hintListPreparedOwner;
	}

	// Version 5. Stores one theme themeEntry (part style, drawing or drawing key). A provider calling again with the
	// same part and key, the same drawing id, or the same drawing id and key replaces its own earlier value.
	// CMFDraw with kind '' withdraws the provider's drawing and its keys.
	private function ThemeEntryEqual(a : SCMFThemeEntry, b : SCMFThemeEntry) : bool
	{
		var i : int;
		if (a.kind != b.kind || a.anchor != b.anchor || a.key != b.key || a.text != b.text ||
			a.number != b.number || a.values.Size() != b.values.Size() || a.ints.Size() != b.ints.Size()) { return false; }
		for (i = 0; i < a.values.Size(); i += 1)
		{
			if (a.values[i] != b.values[i]) { return false; }
		}
		for (i = 0; i < a.ints.Size(); i += 1)
		{
			if (a.ints[i] != b.ints[i]) { return false; }
		}
		return true;
	}

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
					dirty = true;
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
				// Map-space drawing: an empty list (CMFDrawSetList) or empty bits (CMFDrawSetBits) withdraws the key.
				if ((themeEntry.kind == 4 && themeEntry.values.Size() == 0) || (themeEntry.kind == 6 && themeEntry.ints.Size() == 0))
				{
					themeEntries.Erase(i);
					dirty = true;
					return true;
				}
				if (ThemeEntryEqual(themeEntries[i], themeEntry)) { return true; }
				themeEntry.order = themeEntries[i].order;
				themeEntries[i] = themeEntry;
				dirty = true;
				return true;
			}
		}
		if ((themeEntry.kind == 4 && themeEntry.values.Size() == 0) || (themeEntry.kind == 6 && themeEntry.ints.Size() == 0))
		{
			return true;
		}
		nextOrder += 1;
		themeEntry.order = nextOrder;
		themeEntries.PushBack(themeEntry);
		dirty = true;
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
					dirty = true;
				removed += 1;
			}
		}
		return removed;
	}

	// The provider that owns a part's style keys (the earliest folder that styled the part), or for the
	// behaviour parts map, navigation, opening, spread and wide the owner of that one key.
	// Version 8: through the part's choice (PartChoice): Vanilla gives no owner, a chosen mod that styled the part
	// owns it, and otherwise the next level decides (none when the General row says Vanilla). Version 9: a provider
	// that made the part's choice choice-only (CMFRegisterChoiceOnly) owns it only when picked. Version 10: through the
	// key's choice (PartKeyChoice); on a look part one provider owns each piece, worked out among the providers that
	// sent a key of that piece, so a mod sending only the info box's clear keys never owns its look.
	// Shorthand and element longhands select one provider before any element falls back to its shorthand.
	private function ThemeOwnershipKey(part : name, key : name) : name
	{
		if (part == 'opening' && (key == 'revealSeconds' || key == 'revealLegendSeconds' ||
			key == 'revealTrackerSeconds' || key == 'revealCrosshairSeconds')) { return 'revealSeconds'; }
		if (part == 'wide' && (key == 'panels' || key == 'panelsLegend' || key == 'panelsTracker' ||
			key == 'panelsPreview')) { return 'panels'; }
		return key;
	}

	private function ClearThemeMemo()
	{
		styleMemoKeys.Clear();
		styleMemoOwners.Clear();
		drawingMemoIds.Clear();
		drawingMemoOwners.Clear();
		kindMemoKeys.Clear();
		kindMemoValues.Clear();
		leftOutMemoKeys.Clear();
		leftOutMemoFlags.Clear();
		leftOutMemoOwners.Clear();
		rankMemoProviders.Clear();
		rankMemoValues.Clear();
	}

	// Inside SendTheme the answer is remembered per (part, key) group; see the plan for what each key holds.
	private function ThemeStyleOwner(part : name, key : name) : string
	{
		var at : int;
		var memoKey, owner : string;
		if (!themeMemoOn) { return ComputeThemeStyleOwner(part, key); }
		if (part == 'map' && (key == 'frame' || key == 'frameTop' || key == 'frameBottom'))
		{
			memoKey = NameToString(part) + "/" + NameToString(key);
		}
		else if (part == 'map' || part == 'navigation' || part == 'opening' || part == 'spread' || part == 'wide' ||
			(part == 'hints' && key == 'list'))
		{
			memoKey = NameToString(part) + "/" + NameToString(ThemeOwnershipKey(part, key));
		}
		else
		{
			memoKey = NameToString(part) + "#" + PartKeyChoice(part, key);
		}
		at = styleMemoKeys.FindFirst(memoKey);
		if (at >= 0) { return styleMemoOwners[at]; }
		owner = ComputeThemeStyleOwner(part, key);
		styleMemoKeys.PushBack(memoKey);
		styleMemoOwners.PushBack(owner);
		return owner;
	}

	private function ComputeThemeStyleOwner(part : name, key : name) : string
	{
		var i, choice, keyChoice : int;
		var owner, answer : string;
		var perKey : bool;
		var ownershipKey : name;
		// Version 14: the edge frame goes with the map's top edge. While any provider sends map top, the frame keys
		// belong to top's owner (worked out among top's senders only, as before); only when nobody sends top do the
		// frame senders decide among themselves.
		if (part == 'map' && (key == 'frame' || key == 'frameTop' || key == 'frameBottom'))
		{
			for (i = 0; i < themeEntries.Size(); i += 1)
			{
				if (themeEntries[i].kind == 1 && themeEntries[i].target == 'map' && themeEntries[i].key == 'top')
				{
					return ThemeStyleOwner('map', 'top');
				}
			}
		}
		ownershipKey = ThemeOwnershipKey(part, key);
		perKey = part == 'map' || part == 'navigation' || part == 'opening' || part == 'spread' || part == 'wide' ||
			(part == 'hints' && key == 'list');
		owner = "";
		keyChoice = PartKeyChoice(part, key);
		choice = -1;
		answer = "";
		if (choicesActive)
		{
			choice = keyChoice;
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
			if (themeEntries[i].kind == 1 && themeEntries[i].target == part &&
				((perKey && ThemeOwnershipKey(part, themeEntries[i].key) == ownershipKey) ||
				(!perKey && themeEntries[i].key != 'list' &&
				PartKeyChoice(part, themeEntries[i].key) == keyChoice)) &&
				!ChoiceOnlySkips(keyChoice, themeEntries[i].provider))
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
	// A part's look piece is independent from its motion, placement and input pieces.
	private function ThemeLookChoice(part : name) : int
	{
		// Version 15: the map part (backdrop included) is decided by Movement_Area, the crosshair and edge pointers by Look_Frames.
		if (part == 'map') { return 44; }
		if (part == 'crosshair' || part == 'edgePointer') { return 39; }
		if (part == 'mapSpace' || part == 'navigation' || part == 'opening' || part == 'spread' || part == 'wide' || part == 'sounds') { return -1; }
		return PartChoice(part);
	}

	private function PreparedLookOwner(part : name) : string
	{
		var i, choice : int;
		choice = ThemeLookChoice(part);
		if (choice < 0) { return ""; }
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 && themeEntries[i].target == part && themeEntries[i].key != 'list' &&
				PartKeyChoice(part, themeEntries[i].key) == choice)
			{
				return ThemeStyleOwner(part, themeEntries[i].key);
			}
		}
		return "";
	}

	private function SendLookOwners(storage : CScriptedFlashValueStorage)
	{
		var list : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var parts : array<name>;
		var i : int;
		list = storage.CreateTempFlashArray();
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind != 1 || parts.Contains(themeEntries[i].target)) { continue; }
			parts.PushBack(themeEntries[i].target);
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("p", NameToString(themeEntries[i].target));
			item.SetMemberFlashString("o", PreparedLookOwner(themeEntries[i].target));
			list.PushBackFlashObject(item);
		}
		storage.SetFlashArray("cmf.map.lookOwners", list);
	}

	private function ThemeDrawingOwner(id : name) : string
	{
		var at : int;
		var owner : string;
		if (!themeMemoOn) { return ComputeThemeDrawingOwner(id); }
		at = drawingMemoIds.FindFirst(id);
		if (at >= 0) { return drawingMemoOwners[at]; }
		owner = ComputeThemeDrawingOwner(id);
		drawingMemoIds.PushBack(id);
		drawingMemoOwners.PushBack(owner);
		return owner;
	}

	private function ComputeThemeDrawingOwner(id : name) : string
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
		var at : int;
		var memoKey : string;
		var kind : name;
		if (!themeMemoOn) { return ComputeDrawingKind(provider, id); }
		memoKey = provider + "|" + NameToString(id);
		at = kindMemoKeys.FindFirst(memoKey);
		if (at >= 0) { return kindMemoValues[at]; }
		kind = ComputeDrawingKind(provider, id);
		kindMemoKeys.PushBack(memoKey);
		kindMemoValues.PushBack(kind);
		return kind;
	}

	private function ComputeDrawingKind(provider : string, id : name) : name
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

	// Version 15: the panels whose look is chosen as Frames and panels, Legend, Info box or Key hints. A drawing pinned to
	// one of them is part of its owner's look of that panel.
	private function PanelPart(part : name) : bool
	{
		return part == 'screen' || part == 'mapEdge' || part == 'title' || part == 'tracker' || part == 'preview' ||
			part == 'worldButton' || part == 'worldHint' || part == 'markerPanel' || part == 'legend' ||
			part == 'legendRow' || part == 'legendTab' || part == 'tooltip' || part == 'hints';
	}

	// Version 15: a provider's drawing pinned to a panel it also styles belongs to its look of that panel, so it is left
	// out while another provider (or Vanilla, owner "vanilla") wins that panel's look. A provider that only draws on a
	// panel it does not style keeps its drawing. Only look keys count: a key that answers another piece (the info box's clear* and
	// tall* places, fold keys, show) does not tie the drawing to the look. owner is the winner of the panel's look.
	private function PanelDrawingLeftOut(entryValue : SCMFThemeEntry, out owner : string) : bool
	{
		var at : int;
		var memoKey, found : string;
		var result : bool;
		if (!themeMemoOn) { return ComputePanelDrawingLeftOut(entryValue, owner); }
		memoKey = NameToString(DrawingRoot(entryValue.target)) + "|" + entryValue.provider;
		at = leftOutMemoKeys.FindFirst(memoKey);
		if (at >= 0)
		{
			if (leftOutMemoFlags[at]) { owner = leftOutMemoOwners[at]; }
			return leftOutMemoFlags[at];
		}
		found = "";
		result = ComputePanelDrawingLeftOut(entryValue, found);
		leftOutMemoKeys.PushBack(memoKey);
		leftOutMemoFlags.PushBack(result);
		leftOutMemoOwners.PushBack(found);
		if (result) { owner = found; }
		return result;
	}

	private function ComputePanelDrawingLeftOut(entryValue : SCMFThemeEntry, out owner : string) : bool
	{
		var root : name;
		var i : int;
		root = DrawingRoot(entryValue.target);
		if (!PanelPart(root)) { return false; }
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 && themeEntries[i].target == root && themeEntries[i].key != 'list' &&
				themeEntries[i].provider == entryValue.provider && PartKeyChoice(root, themeEntries[i].key) == ThemeLookChoice(root))
			{
				owner = ThemeStyleOwner(root, themeEntries[i].key);
				if (owner == entryValue.provider) { return false; }
				if (owner == "") { owner = "vanilla"; }
				return true;
			}
		}
		return false;
	}

	// Map-space drawing: true when the drawing's owner tied it to the mapSpace anchor. Such a drawing and its
	// keys and lists go to the map per build (SendSpace), not in the theme.

	private function ResolveDrawingRoot(id : name) : name
	{
		var cursor : name;
		var owner : string;
		var seen : array<name>;
		var depth, i : int;
		var found : bool;
		cursor = id;
		for (depth = 0; depth < 9; depth += 1)
		{
			if (CMFListHas(CMFThemeParts(), NameToString(cursor))) { return cursor; }
			if (seen.Contains(cursor)) { return ''; }
			seen.PushBack(cursor);
			owner = ThemeDrawingOwner(cursor);
			if (owner == "") { return ''; }
			found = false;
			for (i = 0; i < themeEntries.Size(); i += 1)
			{
				if (themeEntries[i].kind == 2 && themeEntries[i].target == cursor && themeEntries[i].provider == owner)
				{
					cursor = themeEntries[i].anchor;
					found = true;
					break;
				}
			}
			if (!found) { return ''; }
		}
		return '';
	}

	private function PrepareDrawingRoots()
	{
		var i : int;
		drawingRootIds.Clear();
		drawingRootParts.Clear();
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && !drawingRootIds.Contains(themeEntries[i].target))
			{
				drawingRootIds.PushBack(themeEntries[i].target);
				drawingRootParts.PushBack(ResolveDrawingRoot(themeEntries[i].target));
			}
		}
	}

	private function DrawingRoot(id : name) : name
	{
		var at : int;
		if (dirty) { return ResolveDrawingRoot(id); }
		at = drawingRootIds.FindFirst(id);
		if (at >= 0) { return drawingRootParts[at]; }
		return ResolveDrawingRoot(id);
	}

	private function TrimFilterWord(text : string) : string
	{
		while (StrLen(text) > 0 && (StrBeginsWith(text, " ") || StrBeginsWith(text, "	")))
		{
			text = StrRight(text, StrLen(text) - 1);
		}
		while (StrLen(text) > 0 && (StrEndsWith(text, " ") || StrEndsWith(text, "	")))
		{
			text = StrLeft(text, StrLen(text) - 1);
		}
		return text;
	}

	private function PinTagFilters(provider : string, text : string, storage : CScriptedFlashValueStorage) : CScriptedFlashArray
	{
		var list : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var rest, word, identity : string;
		var seen : array<string>;
		list = storage.CreateTempFlashArray();
		rest = text + ",";
		while (StrLen(rest) > 0)
		{
			word = TrimFilterWord(StrBeforeFirst(rest, ","));
			rest = StrAfterFirst(rest, ",");
			identity = StrLower(word);
			if (word == "" || seen.Contains(identity)) { continue; }
			seen.PushBack(identity);
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("t", word);
			item.SetMemberFlashUInt("u", ResolveKnownTag(provider, word));
			list.PushBackFlashObject(item);
		}
		return list;
	}

	private function IsSpaceDrawing(id : name) : bool
	{
		return DrawingRoot(id) == 'mapSpace';
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
		var at, rank : int;
		if (!themeMemoOn) { return ComputeThemeFolderRank(provider); }
		at = rankMemoProviders.FindFirst(provider);
		if (at >= 0) { return rankMemoValues[at]; }
		rank = ComputeThemeFolderRank(provider);
		rankMemoProviders.PushBack(provider);
		rankMemoValues.PushBack(rank);
		return rank;
	}

	private function ComputeThemeFolderRank(provider : string) : int
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
	private function WriteDrawingMetadata(item : CScriptedFlashObject, entryValue : SCMFThemeEntry, storage : CScriptedFlashValueStorage)
	{
		var rootPart : name;
		item.SetMemberFlashString("b", entryValue.provider);
		if (entryValue.kind != 3 || entryValue.key != 'pinTag') { return; }
		rootPart = DrawingRoot(entryValue.target);
		if (rootPart == 'pin' || rootPart == 'pinLabel' || rootPart == 'pinName')
		{
			item.SetMemberFlashArray("f", PinTagFilters(entryValue.provider, entryValue.text, storage));
		}
	}

	private function DrawingSourceOk(entryValue : SCMFThemeEntry) : bool
	{
		var kind : name;
		if (entryValue.kind != 3 || entryValue.key != 'src') { return true; }
		kind = DrawingKind(entryValue.provider, entryValue.target);
		if ((kind == 'image' && StrBeginsWith(entryValue.text, "img://")) ||
			(kind == 'movie' && StrBeginsWith(entryValue.text, "swf/"))) { return true; }
		NoteTheme("theme source refused provider=" + entryValue.provider + " id=" + NameToString(entryValue.target));
		return false;
	}

	public function SendTheme(storage : CScriptedFlashValueStorage)
	{
		var flashArray : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var owner : string;
		var i, k, sent, ownMotion : int;
		debugTiming = CMFSettingsDebug();
		if (!storage)
		{
			return;
		}
		if (dirty) { Prepare(); }
		ClearThemeMemo();
		themeMemoOn = true;
		flashArray = storage.CreateTempFlashArray();
		sent = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind != 1 && IsSpaceDrawing(themeEntries[i].target))
			{
				continue;
			}
			if (themeEntries[i].kind == 1)
			{
				owner = ThemeStyleOwner(themeEntries[i].target, themeEntries[i].key);
				if (owner != themeEntries[i].provider)
				{
					if (owner == "") { owner = "vanilla"; }
					NoteTheme("theme style shadowed provider=" + themeEntries[i].provider + " part=" +
						NameToString(themeEntries[i].target) + " piece=" +
						ChoiceKey(PartKeyChoice(themeEntries[i].target, themeEntries[i].key)) + " by=" + owner);
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
			if (themeEntries[i].kind != 1 && PanelDrawingLeftOut(themeEntries[i], owner))
			{
				NoteTheme("theme drawing left out provider=" + themeEntries[i].provider + " id=" +
					NameToString(themeEntries[i].target) + " reason=panel by=" + owner);
				continue;
			}
			if (themeEntries[i].kind != 1 && !DrawingSourceOk(themeEntries[i])) { continue; }
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", themeEntries[i].kind);
			item.SetMemberFlashString("t", NameToString(themeEntries[i].target));
			item.SetMemberFlashString("a", NameToString(themeEntries[i].anchor));
			item.SetMemberFlashString("y", NameToString(themeEntries[i].key));
			item.SetMemberFlashString("s", themeEntries[i].text);
			item.SetMemberFlashNumber("n", themeEntries[i].number);
			item.SetMemberFlashInt("p", ThemeFolderRank(themeEntries[i].provider));
			item.SetMemberFlashInt("o", themeEntries[i].order);
			WriteDrawingMetadata(item, themeEntries[i], storage);
			WriteFoldMetadata(item, themeEntries[i], storage);
			if (themeEntries[i].kind == 4)
			{
				item.SetMemberFlashInt("c", themeEntries[i].values.Size());
				for (k = 0; k < themeEntries[i].values.Size(); k += 1)
				{
					item.SetMemberFlashNumber("v" + k, themeEntries[i].values[k]);
				}
			}
			flashArray.PushBackFlashObject(item);
			sent += 1;
		}
		ownMotion = SendDefaultMotion(storage, flashArray);
		SendWideVanilla(storage, flashArray);
		SendPinRecycle(flashArray, storage);
		SendLookOwners(storage);
		themeMemoOn = false;
		ClearThemeMemo();
		SendMovieTags(storage);
		storage.SetFlashArray("cmf.map.theme", flashArray);
		NoteTheme("theme sent entries=" + sent + " of=" + themeEntries.Size() + " cmfMotion=" + ownMotion);
		SendWorld(storage);
		SendItemStyles(storage);
		SendLegendRowArt(storage);
		if (debugTiming)
		{
			CMFLog("timing theme entries=" + themeEntries.Size() + " sent=" + sent);
		}
	}

	// Legend rows with no pins: the legend's "Custom marker" row (User1) and the shared Quest row (StoryQuest) can list no pin
	// to carry a pack's art, so the art goes to the panel by row name, once per map opening under "cmf.map.rowart": one object
	// per row with n (row name), p (picture), t and te (tint and whether set), f and fe (picture fit and whether set). The same
	// claims as a marker's row (legend claim 2, else icon claim 1, skipping "frame:"; tint 41 else 3; fit 48) are read on the
	// row's name. A row with art from a pin keeps it unless the row has a legend claim of its own. Logs "legend row art row= art= tint=" once per row.
	private function SendLegendRowArt(storage : CScriptedFlashValueStorage)
	{
		var list : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var claim : SCMFClaim;
		var rows : array<string>;
		var row, note : string;
		var art, tint : bool;
		var i : int;
		if (!storage) { return; }
		list = storage.CreateTempFlashArray();
		rows.PushBack("User1");
		rows.PushBack("StoryQuest");
		for (i = 0; i < rows.Size(); i += 1)
		{
			row = rows[i];
			art = false;
			tint = false;
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("n", row);
			// A legend claim names the row itself, so it also replaces art a pin carried in; an icon claim only fills a row
			// with none.
			if (Find(CMFPropertyLegendIcon(), row, '', 1, claim) && !StrBeginsWith(claim.text, "frame:"))
			{
				item.SetMemberFlashString("p", claim.text);
				item.SetMemberFlashBool("l", true);
				art = true;
			}
			else if (Find(CMFPropertyIcon(), row, '', 1, claim) && !StrBeginsWith(claim.text, "frame:"))
			{
				item.SetMemberFlashString("p", claim.text);
				art = true;
			}
			if (Find(41, row, '', 1, claim) || Find(CMFPropertyTint(), row, '', 1, claim))
			{
				item.SetMemberFlashUInt("t", claim.number);
				item.SetMemberFlashBool("te", true);
				tint = true;
			}
			if (PropertyWon(48) && Find(48, row, '', 1, claim))
			{
				item.SetMemberFlashInt("f", claim.number);
				item.SetMemberFlashBool("fe", true);
			}
			if (art || tint)
			{
				list.PushBackFlashObject(item);
			}
			note = "legend row art:" + row + ":" + CMFYesNo(art) + CMFYesNo(tint);
			if (seenLegend.Size() < 64 && !seenLegend.Contains(note))
			{
				seenLegend.PushBack(note);
				CMFLog("legend row art row=" + row + " art=" + CMFYesNo(art) + " tint=" + CMFYesNo(tint));
			}
		}
		storage.SetFlashArray("cmf.map.rowart", list);
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

	// Version 10: the map fills a wide or tall screen unless the Fill wide screens row (Movement_Wide) says Vanilla.
	// Filling is CMF's base layout, not a behaviour value: the map does it with no wide entry, so CMF sends an entry of
	// its own (fill 0, p -1) only for Vanilla. Logs who decides the layout once per opening.
	// Version 17 (hidden): the panel recycles pin clips in a full pin update unless the file setting CMFPinRecycle is off.
	// Only the off answer is sent, as the opening key pinRecycle 0; the panel reads no key as on. Logs "pin recycle off".
	private function SendPinRecycle(flashArray : CScriptedFlashArray, storage : CScriptedFlashValueStorage)
	{
		var item : CScriptedFlashObject;
		if (CMFSettingsPinRecycle())
		{
			return;
		}
		item = storage.CreateTempFlashObject();
		item.SetMemberFlashInt("k", 1);
		item.SetMemberFlashString("t", "opening");
		item.SetMemberFlashString("a", "");
		item.SetMemberFlashString("y", "pinRecycle");
		item.SetMemberFlashString("s", "");
		item.SetMemberFlashNumber("n", 0);
		item.SetMemberFlashInt("p", -1);
		item.SetMemberFlashInt("o", 0);
		flashArray.PushBackFlashObject(item);
		NoteTheme("theme default part=opening key=pinRecycle value=0");
		CMFLog("pin recycle off");
	}

	private function SendWideVanilla(storage : CScriptedFlashValueStorage, flashArray : CScriptedFlashArray)
	{
		var item : CScriptedFlashObject;
		var owner : string;
		if (choicesActive && decideAnswer[68] == "vanilla")
		{
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", 1);
			item.SetMemberFlashString("t", "wide");
			item.SetMemberFlashString("a", "");
			item.SetMemberFlashString("y", "fill");
			item.SetMemberFlashString("s", "");
			item.SetMemberFlashNumber("n", 0);
			item.SetMemberFlashInt("p", -1);
			item.SetMemberFlashInt("o", 0);
			flashArray.PushBackFlashObject(item);
			NoteTheme("theme default part=wide key=fill value=0");
			CMFLog("wide owner=vanilla");
			return;
		}
		owner = ThemeStyleOwner('wide', 'fill');
		if (owner == "")
		{
			owner = "CMF";
		}
		CMFLog("wide owner=" + owner);
	}

	// Version 10: sends the game window's size in pixels under "cmf.map.screen" (w and h, 0 when the game answers
	// nothing), right before the theme, so the map can tell a stretched picture from a wide one.
	public function SendScreen(storage : CScriptedFlashValueStorage)
	{
		var item : CScriptedFlashObject;
		var w, h : int;
		if (!storage)
		{
			return;
		}
		theGame.GetCurrentViewportResolution(w, h);
		if (w <= 0 || h <= 0)
		{
			w = 0;
			h = 0;
		}
		item = storage.CreateTempFlashObject();
		item.SetMemberFlashInt("w", w);
		item.SetMemberFlashInt("h", h);
		storage.SetFlashObject("cmf.map.screen", item);
	}

	// Version 10: the visible screen in map units from the last map opening (OnCMFScreen), 0 before the first.
	public function ScreenSeen(width : float, height : float)
	{
		screenWidth = width;
		screenHeight = height;
	}

	public function ScreenWidth() : float
	{
		return screenWidth;
	}

	public function ScreenHeight() : float
	{
		return screenHeight;
	}

	// Map-space drawing. Sends the mapSpace drawings for the shown area under "cmf.map.space" on every full map
	// build (after OnMapReady), and again on CMFMapRefresh: a first object k 0 with the area name in s, then
	// the theme's objects (k 2 drawing, k 3 key) for each winning drawing whose "area" matches, and k 4 for a
	// list key, its count in c and its values in v0, v1, ... The map redraws every map-space drawing from this.
	public function SendSpace(storage : CScriptedFlashValueStorage, area : name, menu : CR4MapMenu)
	{
		SendSpaceMode(storage, area, menu, false, false);
	}

	// Early send (the start of a map build): the grid drawings the core kept from the previous opening of this area (the
	// theme is not cleared between openings), so the map draws its fog in the first frame instead of after the pin build.
	// The late send after OnMapReady follows as always; the panel keeps an identical grid and redraws only a changed one.
	// Once per map menu; logs "space early id=<id> kept" for each grid sent.
	public function SendSpaceEarly(storage : CScriptedFlashValueStorage, area : name, menu : CR4MapMenu)
	{
		if (!menu || spaceEarlyMenu == menu)
		{
			return;
		}
		spaceEarlyMenu = menu;
		// Only drawings the last full build sent and nothing has changed since: a game setting changed, the provider
		// withdrew or replaced a drawing (the theme is dirty), or CMFMapRefresh ran. Then the old fog is never drawn.
		if (!spaceEarlyOk || dirty)
		{
			CMFLog("space early skipped dirty=" + dirty + " kept=" + spaceEarlyOk);
			return;
		}
		SendSpaceMode(storage, area, menu, false, true);
	}

	// After a full send: the first grid drawing of this area gives the cover its fill (default 0) and alpha (default 1).
	private function RememberCover(area : name)
	{
		var i, k : int;
		var target : name;
		coverKnown = false;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && DrawingKind(themeEntries[i].provider, themeEntries[i].target) == 'grid' &&
				IsSpaceDrawing(themeEntries[i].target) && SpaceAreaMatches(themeEntries[i].target, themeEntries[i].provider, area))
			{
				target = themeEntries[i].target;
				coverFill = 0;
				coverAlpha = 1;
				for (k = 0; k < themeEntries.Size(); k += 1)
				{
					if (themeEntries[k].kind == 3 && themeEntries[k].target == target && themeEntries[k].provider == themeEntries[i].provider)
					{
						if (themeEntries[k].key == 'fill') { coverFill = (int)themeEntries[k].number; }
						if (themeEntries[k].key == 'alpha') { coverAlpha = themeEntries[k].number; }
					}
				}
				coverArea = area;
				coverKnown = true;
				return;
			}
		}
	}

	// The earliest point the core knows the shown area (the game asks for the map's picture name): when the last full
	// build left a grid for this area and nothing has changed since, the menu gets cmfCoverFill and cmfCoverAlpha, and the
	// panel covers the tiles from its first frame until the first grid is drawn. Logs "cover set" or "cover skipped reason=".
	// 1.8.0: before the session's first full build nothing is kept, so a grid drawing already declared for this area
	// (a provider's CMFDraw before the first opening, with its fill and alpha) gives the cover ("cover set ... declared").
	public function SendCover(menuFlash : CScriptedFlashSprite, area : name, place : string)
	{
		if (!menuFlash) { CMFLog("cover skipped reason=no menu flash at=" + place); return; }
		if (!spaceBuiltOnce)
		{
			RememberCover(area);
			if (coverKnown)
			{
				menuFlash.SetMemberFlashNumber("cmfCoverAlpha", coverAlpha);
				menuFlash.SetMemberFlashNumber("cmfCoverFill", coverFill);
				CMFLog("cover set area=" + NameToString(area) + " fill=" + coverFill + " alpha=" + coverAlpha + " declared at=" + place);
				return;
			}
		}
		// No cover: say so, so the panel returns the painting it has been holding since its first frame.
		if (!coverKnown || coverArea != area)
		{
			menuFlash.SetMemberFlashNumber("cmfCoverFill", -1);
			CMFLog("cover skipped reason=no kept grid for area=" + NameToString(area) + " at=" + place);
			return;
		}
		if (!spaceEarlyOk || dirty)
		{
			menuFlash.SetMemberFlashNumber("cmfCoverFill", -1);
			CMFLog("cover skipped reason=changed dirty=" + dirty + " kept=" + spaceEarlyOk + " at=" + place);
			return;
		}
		menuFlash.SetMemberFlashNumber("cmfCoverAlpha", coverAlpha);
		menuFlash.SetMemberFlashNumber("cmfCoverFill", coverFill);
		CMFLog("cover set area=" + NameToString(area) + " fill=" + coverFill + " alpha=" + coverAlpha + " at=" + place);
	}

	// A game setting changed (any in-game option, including a mod's own): the kept drawings may no longer be right.
	public function DropEarlySpace()
	{
		spaceEarlyOk = false;
	}

	// refresh: a CMFMapRefresh send, where a drawing may fade in (fadeMs); a full build shows its drawings at once.
	// gridsOnly: only grid drawings (the early send).
	public function SendSpaceMode(storage : CScriptedFlashValueStorage, area : name, menu : CR4MapMenu, refresh : bool,
		gridsOnly : bool)
	{
		var flashArray : CScriptedFlashArray;
		var bits : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var owner : string;
		var i, k, sent, values : int;
		spaceMenu = menu;
		spaceArea = area;
		SendAnimationOptions(menu);
		if (!storage)
		{
			return;
		}
		flashArray = storage.CreateTempFlashArray();
		item = storage.CreateTempFlashObject();
		item.SetMemberFlashInt("k", 0);
		item.SetMemberFlashString("s", NameToString(area));
		item.SetMemberFlashBool("r", refresh);
		flashArray.PushBackFlashObject(item);
		sent = 0;
		values = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 || !IsSpaceDrawing(themeEntries[i].target))
			{
				continue;
			}
			if (gridsOnly && DrawingKind(ThemeDrawingOwner(themeEntries[i].target), themeEntries[i].target) != 'grid')
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
			if (themeEntries[i].kind != 1 && !DrawingSourceOk(themeEntries[i])) { continue; }
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", themeEntries[i].kind);
			item.SetMemberFlashString("t", NameToString(themeEntries[i].target));
			item.SetMemberFlashString("a", NameToString(themeEntries[i].anchor));
			item.SetMemberFlashString("y", NameToString(themeEntries[i].key));
			item.SetMemberFlashString("s", themeEntries[i].text);
			item.SetMemberFlashNumber("n", themeEntries[i].number);
			item.SetMemberFlashInt("p", ThemeFolderRank(themeEntries[i].provider));
			item.SetMemberFlashInt("o", themeEntries[i].order);
			WriteDrawingMetadata(item, themeEntries[i], storage);
			if (themeEntries[i].kind == 4)
			{
				item.SetMemberFlashInt("c", themeEntries[i].values.Size());
				for (k = 0; k < themeEntries[i].values.Size(); k += 1)
				{
					item.SetMemberFlashNumber("v" + k, themeEntries[i].values[k]);
				}
				values += themeEntries[i].values.Size();
			}
			if (themeEntries[i].kind == 6)
			{
				// A grid's bits (CMFDrawSetBits): index, word, index, word ... as exact ints.
				bits = storage.CreateTempFlashArray();
				for (k = 0; k < themeEntries[i].ints.Size(); k += 1)
				{
					bits.PushBackFlashInt(themeEntries[i].ints[k]);
				}
				item.SetMemberFlashInt("c", themeEntries[i].ints.Size() / 2);
				item.SetMemberFlashArray("w", bits);
				values += themeEntries[i].ints.Size() / 2;
			}
			flashArray.PushBackFlashObject(item);
			sent += 1;
			if (gridsOnly && themeEntries[i].kind == 2)
			{
				CMFLog("space early id=" + NameToString(themeEntries[i].target) + " kept");
			}
		}
		if (!gridsOnly && !refresh)
		{
			spaceEarlyOk = true;
			spaceBuiltOnce = true;
			RememberCover(area);
		}
		if (gridsOnly && sent == 0)
		{
			return;
		}
		storage.SetFlashArray("cmf.map.space", flashArray);
		if (gridsOnly) { CMFLog("space early area=" + NameToString(area) + " entries=" + sent + " values=" + values); }
		else { CMFLog("space sent area=" + NameToString(area) + " entries=" + sent + " values=" + values); }
	}

	// API 18: a build (the whole UpdateData wrapper, late send included, and a map refresh's own send) counts in
	// refreshBusy; a refresh asked meanwhile, or after the map closed, is refused (false, nothing done).
	public function BuildBusy(on : bool)
	{
		if (on)
		{
			if (refreshBusy == 0)
			{
				refuseLogged = false;
			}
			refreshBusy += 1;
		}
		else if (refreshBusy > 0)
		{
			refreshBusy -= 1;
		}
	}

	public function ForgetSpaceMenu(menu : CR4MapMenu)
	{
		if (menu && spaceMenu == menu)
		{
			spaceMenu = NULL;
		}
	}

	private function NoteRefused(kind : string)
	{
		var why : string;
		why = "closed";
		if (refreshBusy > 0)
		{
			why = "build";
		}
		if (CMFSettingsDebug() && !refuseLogged)
		{
			refuseLogged = true;
			CMFLog("refresh refused kind=" + kind + " reason=" + why);
		}
	}

	// Map-space drawing (CMFMapRefresh): runs OnMapReady again and re-sends the theme and the map-space drawings
	// to the open map. False when no map is open.
	public function RefreshMap() : bool
	{
		if (refreshBusy > 0 || !spaceMenu)
		{
			NoteRefused("map");
			return false;
		}
		spaceEarlyOk = false;
		spaceMenu.CMFMapSpaceSend(true);
		return true;
	}

	// API 17: rebuilds the open map's pins (the game's full pin build, which CMF's wrapper also re-sends the covers and
	// the space after). False when no map is open.
	public function RefreshPins() : bool
	{
		if (refreshBusy > 0 || !spaceMenu)
		{
			NoteRefused("pins");
			return false;
		}
		spaceMenu.CMFRefreshPins();
		return true;
	}

	// The map panel asks for the map-space drawings once its listener is ready (the first build can come first).
	public function SpaceListenerReady(menu : CR4MapMenu)
	{
		if (menu && spaceMenu == menu)
		{
			SendAnimationOptions(menu);
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
			else if (CMFChoiceParent(i) >= 0)
			{
				choiceFeature.PushBack(CMFChoiceParent(i));
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
	// Version 13: child:parent piece keys. No piece is split in this revision.
	private function PieceParentTable() : string
	{
		return "";
	}

	private function ResolvePieceParents()
	{
		var table, rest, pair : string;
		var parents, seen : array<int>;
		var rawMenu, rawFile : array<string>;
		var i, childIndex, parentIndex, cursor : int;
		table = PieceParentTable();
		if (table == "")
		{
			return;
		}
		for (i = 0; i < choiceKeys.Size(); i += 1)
		{
			parents.PushBack(-1);
			rawMenu.PushBack(menuChoices[i]);
			rawFile.PushBack(fileChoices[i]);
		}
		rest = table + ",";
		while (rest != "")
		{
			pair = StrBeforeFirst(rest, ",");
			rest = StrAfterFirst(rest, ",");
			childIndex = choiceKeys.FindFirst(StrBeforeFirst(pair, ":"));
			parentIndex = choiceKeys.FindFirst(StrAfterFirst(pair, ":"));
			if (childIndex < 0 || parentIndex < 0 || childIndex == parentIndex)
			{
				return;
			}
			if (parents[childIndex] >= 0 || choiceFeature[childIndex] == childIndex ||
				choiceFeature[parentIndex] == parentIndex)
			{
				return;
			}
			parents[childIndex] = parentIndex;
		}
		// Validate the whole table before changing either tier.
		for (i = 0; i < parents.Size(); i += 1)
		{
			seen.Clear();
			cursor = i;
			while (cursor >= 0)
			{
				if (seen.Contains(cursor))
				{
					return;
				}
				seen.PushBack(cursor);
				cursor = parents[cursor];
			}
		}
		for (i = 0; i < parents.Size(); i += 1)
		{
			cursor = parents[i];
			while (cursor >= 0)
			{
				if (menuChoices[i] == "")
				{
					menuChoices[i] = rawMenu[cursor];
				}
				if (fileChoices[i] == "")
				{
					fileChoices[i] = rawFile[cursor];
				}
				cursor = parents[cursor];
			}
		}
	}

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
		ResolvePieceParents();
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
		for (i = 0; i < itemStyles.Size(); i += 1)
		{
			if (StrLower(itemStyles[i].provider) == lowered) { return itemStyles[i].provider; }
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
			case 31:
			case 45:
				if (pinType == "")
				{
					return 0; // Icons
				}
				return 11 + PinGroupOf(pinType); // Icons_General
			case 3:
			case 41:
				if (pinType == "")
				{
					return 1; // Colours
				}
				return 19 + PinGroupOf(pinType); // Colours_General
			case 33:
				return PropertyChoice(3, pinType);
			case 34:
			case 35:
				return 78; // Size_Place
			case 36:
				return 79; // Behaviour_PinZoom
			case 42:
			case 43:
			case 46:
				return 76; // Look_Badges
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
			case 32:
			case 44:
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
			case 39:
				return 64; // Behaviour_InfoBoxHeight (version 10; Look_InfoBox before)
			case 28:
				return 67; // Behaviour_HoverNames
			// Version 11.
			case 29:
				return 70; // Icons_Undiscovered
			case 30:
				return 14; // Icons_Completed
			case 18:
			case 19:
				return 71; // Look_InfoText
			case 37:
				return 35; // Legend_Tabs
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
			case 'crosshair':
			case 'edgePointer':
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
			case 'world':
				return 60; // Painting_Crests
			case 'sounds':
				return 73; // Look_Sounds
			case 'pin':
				return 77; // Look_PinLook
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
			case 'wide':
				return 68; // Movement_Wide
		}
		return -1;
	}

	// Version 10: the choice one theme key belongs to. Behaviour keys on a look part, and a look key on a behaviour
	// part, answer their own piece; every other key answers its part's choice (PartChoice).
	public function PartKeyChoice(part : name, key : name) : int
	{
		switch (part)
		{
			case 'tooltip':
				if (CMFListHas("foldTag,foldMoreText,foldLessText,foldKeyPad,foldKeyKb,foldOpen", NameToString(key))) { return 74; }
				if (key == 'clearAnchor') { return 63; }
				if (CMFListHas("stretch,stretchMax,stretchDirs,stretchFlip", NameToString(key))) { return 63; }
				if (key == 'scrollStep' || key == 'hideScrollBar') { return 64; }
				if (key == 'showSeconds' || key == 'hideSeconds' || key == 'slide') { return 72; }
				// Version 11: x and y place the box too, so a mod that only moves the box never owns its look.
				if (CMFListHas("clearMinHeight,clearSide,clearCursor,clearLeft,clearTop,clearRight,clearBottom,clearView," +
					"clearCursorAbove,clearCursorBelow,clearCursorTitle,clearPadX,clearPadY,clearGap,clearBoxPad,clearPick," +
					"clearCursorWeight,x,y", NameToString(key)))
				{
					return 63; // Behaviour_InfoBoxDodge
				}
				// Version 12: the tall-box place is placement too, apart from the box height (scrolling).
				if (CMFListHas("tallMinHeight,tallX,tallTop,tallBottom,tallAltX,tallAltTop,tallAltBottom,tallUnderLegend,tallClear",
					NameToString(key)))
				{
					return 63; // Behaviour_InfoBoxDodge
				}
				break;
			case 'legend':
				if (key == 'show' || key == 'autoHideMs' || key == 'padShowFirst') { return 75; }
				break;
			case 'preview':
				if (key == 'show' || key == 'movingMs') { return 75; }
				break;
			case 'tracker':
			case 'title':
			case 'worldButton':
			case 'worldHint':
			case 'crosshair':
			case 'edgePointer':
				// Version 15: whether the panel shows is behaviour (Panel visibility), apart from its look (Frames and panels).
				if (key == 'show') { return 75; }
				break;
			case 'pinLabel':
				if (CMFListHas("rise,riseOffset,riseTracked,riseOffsetTracked", NameToString(key)))
				{
					return 31; // Labels_Place
				}
				break;
			case 'navigation':
				if (key == 'zoomOutFit' || key == 'edgeOvershoot')
				{
					return 65; // Movement_ZoomOut
				}
				if (CMFListHas("crosshairRoam,safeLeft,safeTop,safeRight,safeBottom,snapSeconds,centerSeconds,padHoldMs",
					NameToString(key)))
				{
					return 66; // Movement_Controller
				}
				break;
		}
		return PartChoice(part);
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
		if ((FindOwn(propertyId, answer, dataObject.GetMemberFlashString("type"), '', 1, claim) && claim.level > 0) ||
			(FindOwn(propertyId, answer, dataObject.GetMemberFlashString("filteredType"), '', 1, claim) && claim.level > 0))
		{
			return false;
		}
		if (FindOwn(propertyId, answer, "", '', 0, claim)) { return true; }
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
			if (claims[i].propertyId != 47)
			{
				NoteOfferFor(PropertyChoice(claims[i].propertyId, NameToString(claims[i].pinType)), claims[i].provider);
			}
		}
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1)
			{
				NoteOfferFor(PartKeyChoice(themeEntries[i].target, themeEntries[i].key), themeEntries[i].provider);
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
		for (i = 0; i < itemStyles.Size(); i += 1)
		{
			NoteOfferFor(PartKeyChoice(itemStyles[i].target, itemStyles[i].key), itemStyles[i].provider);
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

	// Version 10, for the menu add-on: the answer that decides one choice in the current preparation ("vanilla", a
	// provider, or "" when no level picks one), the same answer the map's lookups use.
	public function DecidedAnswer(choice : int) : string
	{
		if (dirty)
		{
			Prepare();
		}
		if (!choicesActive || choice < 0 || choice >= decideAnswer.Size())
		{
			return "";
		}
		return decideAnswer[choice];
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
		debugTiming = CMFSettingsDebug();
		if (inBuild && debugTiming)
		{
			CMFLog("prepare during build pins=" + timingPins);
		}
		providerOrder = CMFSettingsProviderOrder();
		ReadChoices();
		animationClaimIndices.Clear();
		winners.Clear();
		hideClaims.Clear();
		tabHideClaims.Clear();
		labelHideClaims.Clear();
		choiceOnlySkipped.Clear();
		infoAdds.Clear();
		tabsHidden.Clear();
		rowsKept.Clear();
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].propertyId == 45 || claims[i].propertyId == 46) { animationClaimIndices.PushBack(i); }
			// Version 9: a claim whose choice its provider made choice-only waits until that provider is picked.
			if (ChoiceOnlySkips(PropertyChoice(claims[i].propertyId, NameToString(claims[i].pinType)), claims[i].provider))
			{
				choiceOnlySkipped.PushBack(claims[i].provider);
				continue;
			}
			if (claims[i].propertyId == 47) { winners.PushBack(claims[i]); continue; }
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
			if (claims[i].propertyId == CMFPropertyLabelHide())
			{
				if (claims[i].number != 0) { labelHideClaims.PushBack(claims[i]); }
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
			// Version 11: info box lines added below the game's words are never arbitrated (every one applies, the
			// earlier folder first), and every whole-tab hide applies, as hides do.
			if ((claims[i].propertyId == CMFPropertyInfoTitle() || claims[i].propertyId == CMFPropertyInfoText()) &&
				claims[i].number == CMFInfoAdd())
			{
				AddInfoLine(claims[i]);
				continue;
			}
			if (claims[i].propertyId == CMFPropertyTabHidden())
			{
				if (claims[i].number != 0)
				{
					tabsHidden.PushBack(claims[i]);
				}
				continue;
			}
			// A withdrawn label hide or info box height leaves the slot to the next folder.
			if ((claims[i].propertyId == CMFPropertyLabelHide() || claims[i].propertyId == CMFPropertyInfoBoxHeight() || claims[i].propertyId == 39) &&
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
			// Version 12: every provider's tag claim stays a candidate (not for greyed pins or clicks); Find decides
			// between them by the pin's own piece, so the player's pick for that pin's group wins there.
			if (claims[i].level == 2 && claims[i].propertyId != CMFPropertyDisabled() &&
				!CMFIsClickProperty(claims[i].propertyId))
			{
				winners.PushBack(claims[i]);
				continue;
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
		NoteLookups();
		PrepareItemStyles();
		PrepareDrawingRoots();
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
		for (i = 0; i < tabsHidden.Size(); i += 1)
		{
			CMFLog("tab hidden provider=" + tabsHidden[i].provider + " tab=" + NameToString(tabsHidden[i].pinType));
		}
		for (i = 0; i < infoAdds.Size(); i += 1)
		{
			CMFLog("info add provider=" + infoAdds[i].provider + " property=" + infoAdds[i].propertyId + " level=" +
				infoAdds[i].level + " type=" + NameToString(infoAdds[i].pinType) + " tag=" + NameToString(infoAdds[i].pinTag));
		}
		if (debugTiming)
		{
			ReportIndex();
		}
	}

	// CMFDebug only: the size of the prepared lookup index, one line per preparation, so a log shows whether almost
	// every pin is covered (every-pin and place claims) and how many winners each property holds.
	private function ReportIndex()
	{
		var i, n : int;
		var counts : array<int>;
		var perProperty : string;
		for (i = 0; i < 64; i += 1) { counts.PushBack(0); }
		for (i = 0; i < winners.Size(); i += 1)
		{
			if (winners[i].propertyId >= 0 && winners[i].propertyId < 64) { counts[winners[i].propertyId] += 1; }
		}
		perProperty = "";
		for (n = 0; n < 64; n += 1)
		{
			if (counts[n] > 0) { perProperty += " p" + n + "=" + counts[n]; }
		}
		CMFLog("timing prepare claims=" + claims.Size() + " winners=" + winners.Size() + " types=" +
			typeKeys.Size() + " tags=" + tagKeys.Size() + " everyPinClaims=" + everyPinClaims + " placeClaims=" + placeClaims +
			" claimedTypes=" + claimedTypes.Size() + " tagNames=" + tagNames.Size() + " hides=" + hideClaims.Size() +
			" perProperty:" + perProperty);
	}

	// CMFDebug only: the per-pin totals of one map build, logged once when the build ends (UpdateData).
	public function ReportTiming()
	{
		if (!debugTiming) { return; }
		CMFLog("timing build pins=" + timingPins + " covered=" + timingCovered +
			" finds=" + timingFinds + " candidates=" + timingCandidates +
			" memoHits=" + timingMemoHits + " animPins=" + animationPins.Size() + " animBindings=" + animationBindings.Size());
		timingPins = 0;
		timingCovered = 0;
		timingFinds = 0;
		timingCandidates = 0;
		timingMemoHits = 0;
	}

	// Version 11, opening speed: the per-preparation lookup aids (propertyWon, placeClaims, tagIds and tagNames, the
	// tags in LateTag's order: winners, hides, tab hides, info adds).
	private function NoteLookups()
	{
		var i, propertyId : int;
		var tails : array<int>;
		propertyWon.Clear();
		globalWinner.Clear();
		specificWon.Clear();
		propertyFirst.Clear();
		propertyNext.Clear();
		activeWriteSlots.Clear();
		for (i = 0; i < 64; i += 1)
		{
			propertyWon.PushBack(false);
			globalWinner.PushBack(-1);
			specificWon.PushBack(false);
			propertyFirst.PushBack(-1);
			tails.PushBack(-1);
		}
		placeClaims = 0;
		tagIds.Clear();
		tagNames.Clear();
		claimedTypes.Clear();
		everyPinClaims = 0;
		infoTypes.Clear();
		infoTags.Clear();
		infoEveryOrPlace = false;
		for (i = 0; i < winners.Size(); i += 1)
		{
			propertyId = winners[i].propertyId;
			propertyNext.PushBack(-1);
			if (propertyId >= 0 && propertyId < 64)
			{
				propertyWon[propertyId] = true;
				if (tails[propertyId] < 0) { propertyFirst[propertyId] = i; }
				else { propertyNext[tails[propertyId]] = i; }
				tails[propertyId] = i;
				if (winners[i].level == 0)
				{
					if (globalWinner[propertyId] == -1) { globalWinner[propertyId] = i; }
					else { globalWinner[propertyId] = -2; }
				}
				else { specificWon[propertyId] = true; }
			}
			NoteLookupClaim(winners[i]);
			NoteInfoClaim(winners[i]);
			// The every-pin info box height is the menu's (WriteFields takes only a type, tag or place height).
			if (winners[i].level == 0 && winners[i].propertyId != CMFPropertyInfoBoxHeight() && winners[i].propertyId != 39)
			{
				everyPinClaims += 1;
			}
			if (winners[i].level == 1 && !claimedTypes.Contains(NameToString(winners[i].pinType)))
			{
				claimedTypes.PushBack(NameToString(winners[i].pinType));
			}
		}
		for (i = 0; i < 64; i += 1)
		{
			if (propertyWon[i] && (i == 10 || i == 11 || i == 12 || i == 17 || i == 22 || i == 28 ||
				(i >= 31 && i <= 36) || i == 42 || i == 43 || i == 44 || i == 45 || i == 46 || i == 48)) { activeWriteSlots.PushBack(i); }
		}
		for (i = 0; i < hideClaims.Size(); i += 1)
		{
			NoteLookupClaim(hideClaims[i]);
		}
		for (i = 0; i < tabHideClaims.Size(); i += 1)
		{
			NoteLookupClaim(tabHideClaims[i]);
		}
		for (i = 0; i < labelHideClaims.Size(); i += 1)
		{
			NoteLookupClaim(labelHideClaims[i]);
		}
		for (i = 0; i < infoAdds.Size(); i += 1)
		{
			NoteLookupClaim(infoAdds[i]);
			NoteInfoClaim(infoAdds[i]);
		}
		BuildLookupIndex();
	}

	// Opening speed (1.10.1): indexes the winners for Find. Every winner that is not a hide or an info add sits in one
	// list: the every-pin winners of its property, the winners of its property naming a type (levels 1 and 3, by type),
	// or the winners of its property naming a tag (level 2, by tag). Each list keeps the order of winners, so Find
	// examines the same candidates in the same order as the chain of the property, only without the ones that cannot
	// cover the pin.
	private function BuildLookupIndex()
	{
		var i, p, slot, key, last : int;
		var typeName : string;
		var winnerType, winnerTag : array<int>;
		indexBuilt = false;
		typeKeys.Clear();
		tagKeys.Clear();
		typeHead.Clear();
		typeTail.Clear();
		typeNext.Clear();
		tagHead.Clear();
		tagTail.Clear();
		tagNext.Clear();
		globalHead.Clear();
		globalTail.Clear();
		globalNext.Clear();
		memoState.Clear();
		for (i = 0; i < winners.Size(); i += 1)
		{
			typeNext.PushBack(0);
			tagNext.PushBack(0);
			globalNext.PushBack(0);
			winnerType.PushBack(-1);
			winnerTag.PushBack(-1);
			if (winners[i].level == 1 || winners[i].level == CMFLevelPlace())
			{
				typeName = NameToString(winners[i].pinType);
				slot = typeKeys.FindFirst(typeName);
				if (slot < 0)
				{
					slot = typeKeys.Size();
					typeKeys.PushBack(typeName);
				}
				winnerType[i] = slot;
			}
			else if (winners[i].level == 2)
			{
				slot = tagKeys.FindFirst(winners[i].pinTag);
				if (slot < 0)
				{
					slot = tagKeys.Size();
					tagKeys.PushBack(winners[i].pinTag);
				}
				winnerTag[i] = slot;
			}
		}
		globalHead.Resize(64);
		globalTail.Resize(64);
		typeHead.Resize(typeKeys.Size() * 64 + 1);
		typeTail.Resize(typeKeys.Size() * 64 + 1);
		tagHead.Resize(tagKeys.Size() * 64 + 1);
		tagTail.Resize(tagKeys.Size() * 64 + 1);
		memoState.Resize(4 * typeKeys.Size() * 64 + 1);
		for (i = 0; i < winners.Size(); i += 1)
		{
			p = winners[i].propertyId;
			if (p < 0 || p >= 64)
			{
				continue;
			}
			if (winners[i].level == 0)
			{
				last = globalTail[p] - 1;
				if (last < 0) { globalHead[p] = i + 1; }
				else { globalNext[last] = i + 1; }
				globalTail[p] = i + 1;
			}
			else if (winnerType[i] >= 0)
			{
				key = winnerType[i] * 64 + p;
				last = typeTail[key] - 1;
				if (last < 0) { typeHead[key] = i + 1; }
				else { typeNext[last] = i + 1; }
				typeTail[key] = i + 1;
			}
			else if (winnerTag[i] >= 0)
			{
				key = winnerTag[i] * 64 + p;
				last = tagTail[key] - 1;
				if (last < 0) { tagHead[key] = i + 1; }
				else { tagNext[last] = i + 1; }
				tagTail[key] = i + 1;
			}
		}
		indexBuilt = true;
	}

	private function NoteInfoClaim(claim : SCMFClaim)
	{
		if (claim.propertyId != CMFPropertyInfoTitle() && claim.propertyId != CMFPropertyInfoText())
		{
			return;
		}
		if (claim.level == 0 || claim.level == CMFLevelPlace())
		{
			infoEveryOrPlace = true;
		}
		else if (claim.level == 1 && !infoTypes.Contains(NameToString(claim.pinType)))
		{
			infoTypes.PushBack(NameToString(claim.pinType));
		}
		else if (claim.level == 2)
		{
			infoTags.PushBack(claim.pinTag);
		}
	}

	// Version 11, opening speed: whether an info box claim can reach this pin (its type, legend name or own type, its tag).
	private function InfoCovered(pinType : string, filtered : string, own : string, pinTag : name) : bool
	{
		var i : int;
		if (infoEveryOrPlace || infoTypes.Contains(pinType) || infoTypes.Contains(filtered) || infoTypes.Contains(own))
		{
			return true;
		}
		if (!IsNameValid(pinTag))
		{
			return false;
		}
		for (i = 0; i < infoTags.Size(); i += 1)
		{
			if (infoTags[i] == pinTag)
			{
				return true;
			}
		}
		return false;
	}

	// Version 11, opening speed: whether any winner can reach this pin in WriteFields: an every-pin claim, a type claim on
	// its type, legend name or level variant, a tag claim on its tag, or any place claim (checked by Covers there).
	private function PinCovered(pinKey : string, legendKey : string, pinTag : name) : bool
	{
		if (everyPinClaims > 0 || placeClaims > 0 || claimedTypes.Contains(pinKey) || claimedTypes.Contains(legendKey) ||
			(variantNow != "" && claimedTypes.Contains(variantNow)))
		{
			return true;
		}
		if (!IsNameValid(pinTag))
		{
			return false;
		}
		return tagNames.FindFirst(pinTag) >= 0;
	}

	private function PropertyWon(propertyId : int) : bool
	{
		return propertyId >= 0 && propertyId < propertyWon.Size() && propertyWon[propertyId];
	}

	private function NoteLookupClaim(claim : SCMFClaim)
	{
		if (claim.level == CMFLevelPlace())
		{
			placeClaims += 1;
		}
		if (claim.level == 2)
		{
			tagIds.PushBack(NameToFlashUInt(claim.pinTag));
			tagNames.PushBack(claim.pinTag);
		}
	}

	// Version 11: keeps the info box add claims in the order they apply: earlier provider first, then registration.
	private function AddInfoLine(claim : SCMFClaim)
	{
		var i : int;
		for (i = 0; i < infoAdds.Size(); i += 1)
		{
			if (ProviderBeats(claim.provider, infoAdds[i].provider) ||
				(claim.provider == infoAdds[i].provider && claim.order < infoAdds[i].order))
			{
				infoAdds.Insert(i, claim);
				return;
			}
		}
		infoAdds.PushBack(claim);
	}

	// Version 11: whether a provider's never-arbitrated claim of one choice applies: Vanilla none, a picked mod only its
	// own, Automatic every one. Version 12: a picked mod counts only while it sends something of that kind (added info
	// box lines for 71, whole-tab hides for 35); otherwise the pick reads Automatic, as for the added-together features.
	private function AnswerAllows(choice : int, provider : string) : bool
	{
		var answer : string;
		if (!choicesActive || choice < 0)
		{
			return true;
		}
		answer = decideAnswer[choice];
		if (answer == "vanilla")
		{
			return false;
		}
		return answer == "" || answer == "@order" || answer == provider || !AnswerSends(choice, answer);
	}

	// Version 12: whether a picked mod sends lines added to the info box (71) or hides a whole tab (35).
	private function AnswerSends(choice : int, provider : string) : bool
	{
		var i : int;
		if (choice == 31)
		{
			for (i = 0; i < labelHideClaims.Size(); i += 1)
			{
				if (labelHideClaims[i].provider == provider) { return true; }
			}
			return labelHideOffers.Contains(provider);
		}
		if (choice == 71)
		{
			for (i = 0; i < infoAdds.Size(); i += 1)
			{
				if (infoAdds[i].provider == provider)
				{
					return true;
				}
			}
			return styledOffers.Contains("71/" + provider);
		}
		if (choice == 35)
		{
			for (i = 0; i < tabsHidden.Size(); i += 1)
			{
				if (tabsHidden[i].provider == provider)
				{
					return true;
				}
			}
			return false;
		}
		return true;
	}

	// Version 11: the filter tabs hidden whole (CMFPropertyTabHidden), joined with commas.
	private function HiddenTabs() : string
	{
		var tabs, tab : string;
		var i : int;
		tabs = "";
		for (i = 0; i < tabsHidden.Size(); i += 1)
		{
			tab = NameToString(tabsHidden[i].pinType);
			if (AnswerAllows(35, tabsHidden[i].provider) && !CMFListHas(tabs, tab))
			{
				if (tabs != "")
				{
					tabs += ",";
				}
				tabs += tab;
			}
		}
		return tabs;
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
		// The area's visible (v) and scroll (s) limits and zoom range, in map units, as the game's map menu sends them to
		// the panel. A world limit in metres is the value / (2 * textureSize / mapSize), y negated. Logging only.
		CMFLog("background limits area=" + NameToString(area) +
			" vMinX=" + FloatToString(theGame.GetMiniMapVminX(area)) + " vMaxX=" + FloatToString(theGame.GetMiniMapVmaxX(area)) +
			" vMinY=" + FloatToString(theGame.GetMiniMapVminY(area)) + " vMaxY=" + FloatToString(theGame.GetMiniMapVmaxY(area)) +
			" sMinX=" + FloatToString(theGame.GetMiniMapSminX(area)) + " sMaxX=" + FloatToString(theGame.GetMiniMapSmaxX(area)) +
			" sMinY=" + FloatToString(theGame.GetMiniMapSminY(area)) + " sMaxY=" + FloatToString(theGame.GetMiniMapSmaxY(area)) +
			" minZoom=" + FloatToString(theGame.GetMiniMapMinZoom(area)) + " maxZoom=" + FloatToString(theGame.GetMiniMapMaxZoom(area)));
		return root;
	}

	// Called for every engine pin from AddPinTypeData, after vanilla filled the object: lookup only. pinType is the
	// pin's visible type; realType (version 11) its real kind, which an undiscovered "?" or completed pin keeps.
	public function WritePinFields(dataObject : CScriptedFlashObject, pinType : name, pinTag : name, mapContext : name,
		optional realType : name)
	{
		var pinKey : string;
		if (dirty)
		{
			Prepare();
		}
		if (!dataObject)
		{
			return;
		}
		if (debugTiming) { timingPins += 1; }
		dataObject.SetMemberFlashBool("cmfDone", true);
		pinKey = NameToString(pinType);
		NoteListPin(dataObject, pinKey, pinTag, NameToString(realType));
		SetPinContext(dataObject, pinKey);
		if (hideClaims.Size() > 0)
		{
			MarkHidden(dataObject, HideOwner(dataObject, dataObject.GetMemberFlashString("type"), pinKey,
				pinTag, CMFLevelPlace(), mapContext));
		}
		if (labelHideClaims.Size() > 0)
		{
			WriteLabelHides(dataObject, dataObject.GetMemberFlashString("type"), pinKey, pinTag, CMFLevelPlace());
		}
		if (tabHideClaims.Size() > 0)
		{
			WriteTabHide(dataObject, dataObject.GetMemberFlashString("type"), pinKey, pinTag, CMFLevelPlace());
		}
		if (winners.Size() > 0)
		{
			if (PinCovered(pinKey, pinKey, pinTag))
			{
				NotePin(pinType, pinTag);
				if (debugTiming) { timingCovered += 1; }
				gamePinNow = true;
				WriteFields(dataObject, pinKey, pinKey, pinTag, CMFLevelPlace(), mapContext);
				gamePinNow = false;
			}
			WriteStateIcon(dataObject, pinKey, NameToString(realType), pinTag);
		}
		ClearPinContext();
	}

	// Version 11: the undiscovered (29) or completed (30) art of a pin in that state, from its real kind, its tag, its
	// place or every pin; a completed pin's visible type ("...Disabled") counts as its kind too. Not on a pin a provider
	// styled itself.
	private function WriteStateIcon(dataObject : CScriptedFlashObject, pinKey : string, kind : string, pinTag : name)
	{
		var claim : SCMFClaim;
		var propertyId : int;
		if (StrBeginsWith(pinKey, "NotDiscoveredPOI"))
		{
			propertyId = CMFPropertyIconUndiscovered();
		}
		else if (StrEndsWith(pinKey, "Disabled"))
		{
			propertyId = CMFPropertyIconCompleted();
		}
		else
		{
			return;
		}
		if (!PropertyWon(propertyId) || CMFPinOwner(dataObject, "cmfIconBy") != "")
		{
			return;
		}
		if (kind == "")
		{
			kind = pinKey;
		}
		if (Find(propertyId, kind, pinTag, CMFLevelPlace(), claim) ||
			(kind != pinKey && Find(propertyId, pinKey, pinTag, CMFLevelPlace(), claim)))
		{
			dataObject.SetMemberFlashString("cmfIconPath", claim.text);
			dataObject.SetMemberFlashString("cmfIconSourceBy", claim.provider);
			dataObject.SetMemberFlashBool("cmfIconFramesMasked", true);
		}
	}

	// Version 11: the info box's title and text claims on one pin, once every mod has added its pins: replace claims
	// (number 0, one winner), then every add claim's lines (number 1) below, the earlier folder first. A pin a provider
	// styled itself keeps that title or text.
	private function WriteInfo(dataObject : CScriptedFlashObject, pinKey : string, legendKey : string, pinTag : name)
	{
		var claim : SCMFClaim;
		if (CMFPinOwner(dataObject, "cmfInfoTitleBy") == "" &&
			(Find(CMFPropertyInfoTitle(), pinKey, pinTag, CMFLevelPlace(), claim) ||
			Find(CMFPropertyInfoTitle(), legendKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashString("label", claim.text);
		}
		if (CMFPinOwner(dataObject, "cmfInfoTextBy") == "" &&
			(Find(CMFPropertyInfoText(), pinKey, pinTag, CMFLevelPlace(), claim) ||
			Find(CMFPropertyInfoText(), legendKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashString("description", claim.text);
		}
		AppendInfoAdds(dataObject, pinKey, legendKey, pinTag, "");
	}

	// Every add claim's line (number 1) on one pin, for one field ("label" or "description") or both ("").
	private function AppendInfoAdds(dataObject : CScriptedFlashObject, pinKey : string, legendKey : string, pinTag : name,
		only : string)
	{
		var field : string;
		var i : int;
		for (i = 0; i < infoAdds.Size(); i += 1)
		{
			if (!AnswerAllows(71, infoAdds[i].provider) ||
				(!Covers(infoAdds[i], pinKey, pinTag, CMFLevelPlace()) &&
				!(infoAdds[i].level == 1 && NameToString(infoAdds[i].pinType) == legendKey)) ||
				((infoAdds[i].level == 2 || infoAdds[i].level == CMFLevelPlace()) && CMFKindHidden(pinKey)))
			{
				continue;
			}
			field = "description";
			if (infoAdds[i].propertyId == CMFPropertyInfoTitle())
			{
				field = "label";
			}
			if (only == "" || only == field)
			{
				AddInfoText(dataObject, field, infoAdds[i].text);
			}
		}
	}

	// Version 11: one more line below a pin's title or text. The game wraps a description in its own paragraph
	// (<font size='19'><p align='left'>...</p></font>); the line goes inside that paragraph, so it takes the same
	// size and alignment instead of starting a centred paragraph of its own.
	private function AddInfoText(dataObject : CScriptedFlashObject, field : string, text : string)
	{
		var current : string;
		var paragraphEnd : int;
		current = CMFPinOwner(dataObject, field);
		LogPinDetail("pin info add type=" + dataObject.GetMemberFlashString("type") + " field=" + field + " before=" + current);
		if (current == "")
		{
			dataObject.SetMemberFlashString(field, text);
		}
		else
		{
			paragraphEnd = StrFindLast(current, "</p>");
			if (paragraphEnd >= 0)
			{
				dataObject.SetMemberFlashString(field, StrLeft(current, paragraphEnd) + "<br>" + text + StrRight(current, StrLen(current) - paragraphEnd));
			}
			else
			{
				dataObject.SetMemberFlashString(field, current + "<br>" + text);
			}
		}
	}

	// Version 11: the player marker (type 'Player') and the player's own markers ('User1' to 'User7') take type claims on
	// exactly their type for their art, colour and size. Every-pin and tag claims never reach them.
	private function WriteMarkerFields(dataObject : CScriptedFlashObject)
	{
		var claim : SCMFClaim;
		var pinType : string;
		pinType = dataObject.GetMemberFlashString("type");
		if (pinType != "Player" && !(StrBeginsWith(pinType, "User") && StrLen(pinType) == 5))
		{
			return;
		}
		if (Find(CMFPropertyIcon(), pinType, '', 1, claim) && claim.level == 1)
		{
			dataObject.SetMemberFlashString("cmfIconPath", claim.text);
			dataObject.SetMemberFlashString("cmfIconSourceBy", claim.provider);
		}
		if (Find(CMFPropertyTint(), pinType, '', 1, claim) && claim.level == 1)
		{
			dataObject.SetMemberFlashUInt("cmfIconTint", claim.number);
			dataObject.SetMemberFlashBool("cmfIconTintEnabled", true);
		}
		if (Find(CMFPropertyPinScale(), pinType, '', 1, claim) && claim.level == 1)
		{
			SetSlot(dataObject, CMFPropertyPinScale(), claim.text, claim.number);
		}
		if (pinType != "Player")
		{
			WriteMarkerLegend(dataObject, pinType);
		}
	}

	// The legend's "Custom marker" row takes its picture from the first of the player's marker pins the panel lists, so the
	// markers carry the row's art like any other pin: a legend claim (id 2) or an icon claim (id 1) on the row's filteredType,
	// else the icon claim on this marker's own type; tint (ids 41, 3) and picture fit (48) the same way. A pack that already
	// themes User1 to User7 with type claims therefore themes the row with no new call. Logs "marker legend type= ..." once per type.
	private function WriteMarkerLegend(dataObject : CScriptedFlashObject, pinType : string)
	{
		var claim : SCMFClaim;
		var legendKey, note : string;
		var art, fromPin, tint : bool;
		legendKey = dataObject.GetMemberFlashString("filteredType");
		if (legendKey == "")
		{
			legendKey = pinType;
		}
		if ((Find(CMFPropertyLegendIcon(), legendKey, '', 1, claim) || Find(CMFPropertyIcon(), legendKey, '', 1, claim)) &&
			!StrBeginsWith(claim.text, "frame:"))
		{
			dataObject.SetMemberFlashString("cmfLegendIconPath", claim.text);
			art = true;
		}
		else if (Find(CMFPropertyIcon(), pinType, '', 1, claim) && claim.level == 1 && !StrBeginsWith(claim.text, "frame:"))
		{
			dataObject.SetMemberFlashString("cmfLegendIconPath", claim.text);
			art = true;
			fromPin = true;
		}
		// An animated marker shows its first picture in the row, as other animated rows do.
		if (PropertyWon(45) || PropertyWon(46)) { AnimationLegend(dataObject, pinType, legendKey); }
		if (Find(41, legendKey, '', 1, claim) || Find(CMFPropertyTint(), legendKey, '', 1, claim) ||
			(fromPin && Find(CMFPropertyTint(), pinType, '', 1, claim) && claim.level == 1))
		{
			dataObject.SetMemberFlashUInt("cmfLegendTint", claim.number);
			dataObject.SetMemberFlashBool("cmfLegendTintEnabled", true);
			tint = true;
		}
		if (PropertyWon(48) && (Find(48, legendKey, '', 1, claim) || Find(48, pinType, '', 1, claim)))
		{
			dataObject.SetMemberFlashInt("cmfLegendFit", claim.number);
			dataObject.SetMemberFlashBool("cmfLegendFitEnabled", true);
		}
		note = "marker legend:" + pinType;
		if (seenLegend.Size() < 64 && !seenLegend.Contains(note))
		{
			seenLegend.PushBack(note);
			CMFLog("marker legend type=" + pinType + " filteredType=" + legendKey + " art=" + CMFYesNo(art) + " tint=" +
				CMFYesNo(tint));
		}
	}

	// Version 11: with [CMFSettings] CMFLogPins on, logs every pin of an area once (no cap), so an author can find any
	// pin's tag, type, name and place: "pin list area= type= kind= filteredType= tag= id= label= x= y=".
	public function NoteListArea(area : name)
	{
		logPins = logPinsAsked || CMFSettingsLogPins();
		if (area != listArea)
		{
			listArea = area;
			listedPins.Clear();
			logPinsLines = 0;
		}
	}

	// Version 11: CMFSetLogPins, for an author's own test pack (the settings file key needs a line in the player's
	// settings).
	public function SetLogPins(on : bool)
	{
		logPinsAsked = on;
		logPins = on || CMFSettingsLogPins();
	}

	// Version 11: with the pin list on, up to 200 lines per area for the game session (the count restarts only when
	// the area changes) on how CMF changed a pin's info box and legend row.
	private function LogPinDetail(line : string)
	{
		if (logPins && logPinsLines < 200)
		{
			logPinsLines += 1;
			CMFLog(line);
		}
	}

	private function NoteListPin(dataObject : CScriptedFlashObject, pinKey : string, pinTag : name, kind : string)
	{
		var pinKeyName : string;
		if (!logPins)
		{
			return;
		}
		pinKeyName = NameToString(pinTag);
		if (pinKeyName == "")
		{
			pinKeyName = "#" + dataObject.GetMemberFlashUInt("id") + "/" + dataObject.GetMemberFlashString("type");
			// Version 12: many game pins have no id, so an untagged pin without one is told apart by its place.
			if (dataObject.GetMemberFlashUInt("id") == 0)
			{
				pinKeyName += "@" + FloatToString(dataObject.GetMemberFlashNumber("posX")) + "," +
					FloatToString(dataObject.GetMemberFlashNumber("posY"));
			}
		}
		if (listedPins.Contains(pinKeyName))
		{
			return;
		}
		listedPins.PushBack(pinKeyName);
		CMFLog("pin list area=" + NameToString(listArea) + " type=" + dataObject.GetMemberFlashString("type") + " kind=" +
			kind + " filteredType=" + dataObject.GetMemberFlashString("filteredType") + " tag=" + NameToString(pinTag) +
			" id=" + dataObject.GetMemberFlashUInt("id") + " label=" + dataObject.GetMemberFlashString("label") + " x=" +
			FloatToString(dataObject.GetMemberFlashNumber("posX")) + " y=" + FloatToString(dataObject.GetMemberFlashNumber("posY")));
	}

	// Late pass over the finished pin array: type-level fields for pins that skipped AddPinTypeData
	// (pins other mods push themselves). Player and user pins stay stock. Runs with no claims too:
	// cmfRowHide lets hiding a legend row under All hide every pin type sharing its filteredType.
	// On the full list (indexToUpdate -1) it also marks hidden pins and removes every marked pin, so the
	// map's counts, cycling, tooltips, overview and quest-list lookup never see them.
	// Version 18: the table of pin types mods add to the map. Filled in the late pass of each full build; a row stays for
	// the session, its count is the last full build's.
	private function AddedTypeIndex(pinType : string) : int
	{
		var i : int;
		if (addedLastType != "" && pinType == addedLastType)
		{
			return addedLastIndex;
		}
		for (i = 0; i < addedTypes.Size(); i += 1)
		{
			if (addedTypes[i].pinType == pinType)
			{
				addedLastType = pinType;
				addedLastIndex = i;
				return i;
			}
		}
		return -1;
	}

	private function IsDeclaredAddedType(pinType : string) : bool
	{
		var at : int;
		if (declaredAddedTypes == 0)
		{
			return false;
		}
		at = AddedTypeIndex(pinType);
		return at >= 0 && addedTypes[at].declared;
	}

	// Owner of a type: a declared row, then a CMFAddPin pin of that type, then a type claim on the type, then a type claim
	// on its legend row, else "".
	private function AddedTypeOwner(pinType : string, filtered : string) : string
	{
		var i, at : int;
		at = AddedTypeIndex(pinType);
		if (at >= 0 && addedTypes[at].declared && addedTypes[at].provider != "")
		{
			return addedTypes[at].provider;
		}
		for (i = 0; i < addedPins.Size(); i += 1)
		{
			if (NameToString(addedPins[i].pinType) == pinType)
			{
				return addedPins[i].provider;
			}
		}
		// A mod that defines the legend row of the type (property 6) is the one that adds it; an icon pack only styles it.
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].level == 1 && claims[i].propertyId == CMFPropertyLegendRow() &&
				(NameToString(claims[i].pinType) == filtered || NameToString(claims[i].pinType) == pinType))
			{
				return claims[i].provider;
			}
		}
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].level == 1 && NameToString(claims[i].pinType) == pinType)
			{
				return claims[i].provider;
			}
		}
		for (i = 0; i < claims.Size(); i += 1)
		{
			if (claims[i].level == 1 && NameToString(claims[i].pinType) == filtered)
			{
				return claims[i].provider;
			}
		}
		return "";
	}

	private function NoteAddedPinType(pinType : string, filtered : string)
	{
		var at : int;
		var first : bool;
		var row : SCMFAddedPinType;
		at = AddedTypeIndex(pinType);
		if (at < 0)
		{
			row.pinType = pinType;
			row.filteredType = filtered;
			row.provider = AddedTypeOwner(pinType, filtered);
			row.count = 1;
			addedTypes.PushBack(row);
			return;
		}
		first = addedTypes[at].count == 0;
		addedTypes[at].count += 1;
		if (addedTypes[at].filteredType == "")
		{
			addedTypes[at].filteredType = filtered;
		}
		// An unowned row looks for its owner once per build (the first pin of the type), not once per pin.
		if (first && addedTypes[at].provider == "")
		{
			addedTypes[at].provider = AddedTypeOwner(pinType, filtered);
		}
	}

	private function ResetAddedPinCounts()
	{
		var i : int;
		for (i = 0; i < addedTypes.Size(); i += 1)
		{
			addedTypes[i].count = 0;
		}
	}

	public function AddedPinMods(out mods : array<string>) : int
	{
		var i : int;
		var unowned : bool;
		mods.Clear();
		for (i = 0; i < addedTypes.Size(); i += 1)
		{
			if (addedTypes[i].provider == "")
			{
				unowned = true;
			}
			else if (!mods.Contains(addedTypes[i].provider))
			{
				mods.PushBack(addedTypes[i].provider);
			}
		}
		if (unowned)
		{
			mods.PushBack("");
		}
		return mods.Size();
	}

	public function AddedPinTypesOf(mod : string, out types : array<string>, out rows : array<string>, out counts : array<int>) : int
	{
		var i : int;
		types.Clear();
		rows.Clear();
		counts.Clear();
		for (i = 0; i < addedTypes.Size(); i += 1)
		{
			if (addedTypes[i].provider == mod)
			{
				types.PushBack(addedTypes[i].pinType);
				rows.PushBack(addedTypes[i].filteredType);
				counts.PushBack(addedTypes[i].count);
			}
		}
		return types.Size();
	}

	public function DeclareAddedPinType(provider : string, pinType : name, filteredType : name) : bool
	{
		var at : int;
		var row : SCMFAddedPinType;
		if (provider == "" || !IsNameValid(pinType))
		{
			return false;
		}
		NoteProviderPresent(provider);
		at = AddedTypeIndex(NameToString(pinType));
		if (at < 0)
		{
			row.pinType = NameToString(pinType);
			addedTypes.PushBack(row);
			at = addedTypes.Size() - 1;
		}
		if (!addedTypes[at].declared)
		{
			declaredAddedTypes += 1;
		}
		addedTypes[at].declared = true;
		addedTypes[at].provider = provider;
		if (IsNameValid(filteredType))
		{
			addedTypes[at].filteredType = NameToString(filteredType);
		}
		return true;
	}

	// Debug only: what the tally found in this full build.
	private function LogAddedPins()
	{
		var mods, types, rows : array<string>;
		var counts : array<int>;
		var i, j, k, sum, total : int;
		var list : string;
		AddedPinMods(mods);
		total = 0;
		for (i = 0; i < mods.Size(); i += 1)
		{
			total += AddedPinTypesOf(mods[i], types, rows, counts);
		}
		CMFLog("added pins mods=" + mods.Size() + " types=" + total);
		for (i = 0; i < mods.Size() && i < 10; i += 1)
		{
			k = AddedPinTypesOf(mods[i], types, rows, counts);
			sum = 0;
			list = "";
			for (j = 0; j < k; j += 1)
			{
				sum += counts[j];
				if (j < 8)
				{
					if (j > 0) { list += ","; }
					list += rows[j];
				}
			}
			CMFLog("added pins mod=" + mods[i] + " types=" + k + " rows=" + list + " count=" + sum);
		}
	}

	// A one-pin update carries only the player's own placed pin; log once per session if anything else arrives.
	private function NoteOnePinType(dataObject : CScriptedFlashObject)
	{
		if (dataObject && !dataObject.GetMemberFlashBool("isPlayer") && !dataObject.GetMemberFlashBool("isUserPin"))
		{
			nonUserOneLogged = true;
			CMFLog("one-pin update carries a non-user pin type=" + dataObject.GetMemberFlashString("type"));
		}
	}

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
		var isPlayer, isUser : bool;
		fullList = indexToUpdate < 0;
		if (dirty)
		{
			Prepare();
		}
		if (!fullList && !nonUserOneLogged && flashArray && indexToUpdate < flashArray.GetLength())
		{
			NoteOnePinType(flashArray.GetElementFlashObject(indexToUpdate));
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
			if (!dataObject)
			{
				continue;
			}
			// Each read crosses into the map panel, so the pin's two kind flags are read once (a mod with many
			// pins).
			isPlayer = dataObject.GetMemberFlashBool("isPlayer");
			isUser = dataObject.GetMemberFlashBool("isUserPin");
			if (!isPlayer && !isUser && !dataObject.GetMemberFlashBool("cmfDone"))
			{
				fresh = true;
				if (debugTiming) { timingPins += 1; }
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
				// Version 18: pins of types mods add are tallied before any hide removes them.
				if (fullList && (PinGroupOf(pinType) == 7 || IsDeclaredAddedType(pinType)))
				{
					NoteAddedPinType(pinType, filtered);
				}
				// A pin a mod pushes itself is reached by tag when its id is the game's id for that tag
				// (NameToFlashUInt), as the game sets it on its own pins, so one mod can style or hide a pin
				// another mod adds by naming the tag that mod gave it.
				pinTag = LateTag(dataObject);
				// Version 11: every lookup for the pin itself also reaches place claims (level 3).
				maxLevel = CMFLevelPlace();
				NoteListPin(dataObject, pinType, pinTag, "");
				SetPinContext(dataObject, pinType);
				if (fullList && hideClaims.Size() > 0)
				{
					MarkHidden(dataObject, HideOwner(dataObject, pinType, filtered, pinTag, maxLevel, mapContext));
				}
				if (labelHideClaims.Size() > 0)
				{
					WriteLabelHides(dataObject, pinType, filtered, pinTag, maxLevel);
				}
				if (tabHideClaims.Size() > 0)
				{
					WriteTabHide(dataObject, pinType, filtered, pinTag, maxLevel);
				}
				if (winners.Size() > 0)
				{
					if (PinCovered(pinType, filtered, pinTag))
					{
						if (debugTiming) { timingCovered += 1; }
						WriteFields(dataObject, pinType, filtered, pinTag, maxLevel, mapContext);
					}
					WriteStateIcon(dataObject, pinType, "", pinTag);
				}
				ClearPinContext();
			}
			// Version 11: the player marker and the player's own markers take type claims on exactly their type.
			if ((isPlayer || isUser) && winners.Size() > 0)
			{
				WriteMarkerFields(dataObject);
			}
			// Version 11: the info box's title and text, after every mod's AddPinTypeData wrapper wrote its own.
			infoWritten = false;
			if (fullList && !isPlayer && !isUser && (fresh || !catching) &&
				(PropertyWon(CMFPropertyInfoTitle()) || PropertyWon(CMFPropertyInfoText()) || infoAdds.Size() > 0))
			{
				WritePinInfo(dataObject, fresh);
			}
			// Version 6: clicks reach user pins (type claims on their type, then their filteredType), on the full
			// list and on the one-pin update that follows placing a pin. Other properties keep skipping them.
			if (isUser && !isPlayer && winners.Size() > 0)
			{
				WriteClickFields(dataObject, dataObject.GetMemberFlashString("type"),
					dataObject.GetMemberFlashString("filteredType"), '', 1);
			}
			// Every mod has added its pins: providers and adapters may style each one now (OnPinReady). A
			// second pass for pins pushed after the first (CatchLatePins) reaches only those.
			if (fullList && !isPlayer && !isUser && (fresh || !catching))
			{
				if (ProcessPinAsks(dataObject) && !askedPins.Contains(dataObject))
				{
					askedPins.PushBack(dataObject);
				}
				OnPinReady(dataObject, mapContext);
			}
			infoWritten = false;
		}
		if (fullList)
		{
			RemoveHiddenPins(flashArray, area, mapContext);
			if (debugTiming && addedTypes.Size() > 0)
			{
				LogAddedPins();
			}
		}
		listOpen = false;
	}

	// Version 11: the info box claims of one pin of the full list. A pushed pin keys on its own type, then its legend name;
	// a game pin on its visible type (its legend name) with its own type as the level variant. The tag is found by id.
	private function WritePinInfo(dataObject : CScriptedFlashObject, fresh : bool)
	{
		var pinType, filtered, own : string;
		var pinTag : name;
		pinType = dataObject.GetMemberFlashString("type");
		filtered = dataObject.GetMemberFlashString("filteredType");
		own = pinType;
		if (!fresh && filtered != "")
		{
			pinType = filtered;
		}
		if (pinType == "")
		{
			pinType = filtered;
		}
		if (filtered == "")
		{
			filtered = pinType;
		}
		pinTag = LateTag(dataObject);
		if (!InfoCovered(pinType, filtered, own, pinTag))
		{
			return;
		}
		SetPinContext(dataObject, pinType);
		WriteInfo(dataObject, pinType, filtered, pinTag);
		ClearPinContext();
		infoWritten = true;
		infoKey = pinType;
		infoLegend = filtered;
		infoTag = pinTag;
	}

	// The tag of a tag claim (any property) whose game id (NameToFlashUInt) is this pin's id, or None.
	private function LateTag(dataObject : CScriptedFlashObject) : name
	{
		var id : int;
		var i : int;
		if (tagIds.Size() == 0)
		{
			return '';
		}
		id = dataObject.GetMemberFlashUInt("id");
		if (id == 0)
		{
			return '';
		}
		i = tagIds.FindFirst(id);
		if (i >= 0)
		{
			return tagNames[i];
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
	// Revision 13 hooks: dispatched only by the new panel event names (part 2).
	public function OnMapTab(menu : CR4MapMenu, category : string)
	{
	}

	public function OnMapHints(menu : CR4MapMenu, owner : string)
	{
	}

	public function MapHintsReady(menu : CR4MapMenu)
	{
		var storage : CScriptedFlashValueStorage;
		var list : CScriptedFlashArray;
		var metadata : CScriptedFlashObject;
		var owner : string;
		if (!menu) { return; }
		if (dirty) { Prepare(); }
		owner = HintListOwner();
		if (owner == "" && hintListOwnerSent == "") { return; }
		storage = menu.GetMenuFlashValueStorage();
		if (!storage) { return; }
		list = storage.CreateTempFlashArray();
		if (owner != "")
		{
			metadata = storage.CreateTempFlashObject();
			metadata.SetMemberFlashString("owner", owner);
			list.PushBackFlashObject(metadata);
		}
		// Empty releases only the owned channel. Legacy writers remain independent.
		storage.SetFlashArray("cmf.map.hints.owned", list);
		hintListOwnerSent = owner;
		if (owner != "") { OnMapHints(menu, owner); }
	}

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
		// Version 11: cmfDescMaxAll keeps the every-pin height while a pin with its own height (cmfDescMaxH on the pin)
		// is selected.
		if (Find(CMFPropertyInfoBoxHeight(), "", '', 0, claim))
		{
			menuFlash.SetMemberFlashNumber("cmfDescMaxH", claim.number);
			menuFlash.SetMemberFlashNumber("cmfDescMaxAll", claim.number);
			menuFlash.SetMemberFlashString("cmfDescMaxBy", claim.provider);
		}
		else
		{
			menuFlash.SetMemberFlashNumber("cmfDescMaxH", 0);
			menuFlash.SetMemberFlashNumber("cmfDescMaxAll", 0);
			menuFlash.SetMemberFlashString("cmfDescMaxBy", "");
		}
		if (Find(39, "", '', 0, claim))
		{
			menuFlash.SetMemberFlashNumber("cmfDescMaxWAll", claim.number);
		}
		else { menuFlash.SetMemberFlashNumber("cmfDescMaxWAll", 0); }
		SendHiddenTabs(menuFlash);
	}

	// Version 11: the filter tabs hidden whole go to the legend box (its cmfHiddenTabs), each opening.
	private function SendHiddenTabs(menuFlash : CScriptedFlashSprite)
	{
		var pinPanel : CScriptedFlashSprite;
		var tabs : string;
		tabs = HiddenTabs();
		pinPanel = menuFlash.GetChildFlashSprite("mcHubMapPinPanel");
		if (!pinPanel)
		{
			if (tabs != "")
			{
				CMFLog("tabs hidden=" + tabs + " panel=none");
			}
			return;
		}
		pinPanel.SetMemberFlashString("cmfHiddenTabs", tabs);
		if (tabs != "")
		{
			CMFLog("tabs hidden=" + tabs);
		}
	}

	// Merges every tab hide claim covering this pin into cmfTabHide. A type claim matches the pin's own
	// type or its filteredType; tag claims apply where the tag is known. Player and user pins never.
	private function WriteLabelHides(dataObject : CScriptedFlashObject, pinType : string, filtered : string,
		pinTag : name, maxLevel : int)
	{
		var i : int;
		var matches : bool;
		if (dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin")) { return; }
		for (i = 0; i < labelHideClaims.Size(); i += 1)
		{
			matches = Covers(labelHideClaims[i], pinType, pinTag, maxLevel) ||
				(labelHideClaims[i].level == 1 && NameToString(labelHideClaims[i].pinType) == filtered);
			if ((labelHideClaims[i].level == 2 || labelHideClaims[i].level == CMFLevelPlace()) &&
				(CMFKindHidden(pinType) || CMFKindHidden(filtered))) { matches = false; }
			if (matches)
			{
				MergeLabelHide(dataObject, labelHideClaims[i].provider, labelHideClaims[i].number);
			}
		}
	}

	// Recompute from contributions when a newly seen selected provider changes eligibility.
	// Hash buckets avoid a walk over unrelated pins; storage lasts only through this full build.
	private function MergeLabelHide(dataObject : CScriptedFlashObject, provider : string, flags : int)
	{
		var bucket, index, i, merged : int;
		var hideState : SCMFLabelHideState;
		if (labelHideBuckets.Size() == 0)
		{
			for (i = 0; i < 256; i += 1) { labelHideBuckets.PushBack(-1); }
		}
		bucket = (int)dataObject.GetMemberFlashUInt("id") % 256;
		if (bucket < 0) { bucket += 256; }
		index = labelHideBuckets[bucket];
		while (index >= 0 && labelHidePins[index].pin != dataObject) { index = labelHidePins[index].next; }
		if (index < 0)
		{
			hideState.pin = dataObject;
			hideState.next = labelHideBuckets[bucket];
			index = labelHidePins.Size();
			labelHidePins.PushBack(hideState);
			labelHideBuckets[bucket] = index;
		}
		hideState = labelHidePins[index];
		i = hideState.providers.FindFirst(provider);
		if (i < 0)
		{
			hideState.providers.PushBack(provider);
			hideState.flags.PushBack(flags);
		}
		else
		{
			merged = hideState.flags[i];
			if (CMFHasFlag(flags, 1) && !CMFHasFlag(merged, 1)) { merged += 1; }
			if (CMFHasFlag(flags, 2) && !CMFHasFlag(merged, 2)) { merged += 2; }
			hideState.flags[i] = merged;
		}
		labelHidePins[index] = hideState;
		ApplyLabelHideState(index);
	}

	private function ApplyLabelHideState(index : int)
	{
		var i, merged, flags : int;
		var owner, provider : string;
		var dataObject : CScriptedFlashObject;
		dataObject = labelHidePins[index].pin;
		for (i = 0; i < labelHidePins[index].providers.Size(); i += 1)
		{
			provider = labelHidePins[index].providers[i];
			if (!AnswerAllows(31, provider)) { continue; }
			flags = labelHidePins[index].flags[i];
			if (CMFHasFlag(flags, 1) && !CMFHasFlag(merged, 1)) { merged += 1; }
			if (CMFHasFlag(flags, 2) && !CMFHasFlag(merged, 2)) { merged += 2; }
			if (owner == "" || CMFProviderBeats(provider, owner)) { owner = provider; }
		}
		dataObject.SetMemberFlashInt("cmfLabelHide", merged);
		dataObject.SetMemberFlashString("cmfLabelHideBy", owner);
	}

	private function NoteLabelHideOffer(provider : string)
	{
		var i : int;
		if (labelHideOffers.Contains(provider)) { return; }
		labelHideOffers.PushBack(provider);
		if (!choicesActive || decideAnswer[31] != provider) { return; }
		// At most once when this selected direct-only provider first offers a hide.
		for (i = 0; i < labelHidePins.Size(); i += 1) { ApplyLabelHideState(i); }
	}

	public function ClearLabelHideState()
	{
		labelHidePins.Clear();
		labelHideBuckets.Clear();
	}


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
			covers = Covers(tabHideClaims[i], pinType, pinTag, maxLevel) ||
				(tabHideClaims[i].level == 1 && NameToString(tabHideClaims[i].pinType) == filtered);
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

	// Opened by CMF's UpdateData and UpdateEntityPins wrappers; closed by the late pass. A per-pin hide asked for while
	// the list is closed comes after the list was sent.
	public function OpenPinList()
	{
		listOpen = true;
	}

	// A precompiled CR4MapMenu.UpdateEntityPins of another mod (The Stable 2.2.1) skips every loose wrapper on that
	// method, so CMF's UpdateData wrapper opens the pin list for the whole build (BeginBuild, EndBuild) and CMF's
	// UpdateEntityPins wrapper records that it ran (NoteEntityStep). The first full build of a session without it logs
	// one line (CheckEntityStep).
	public function BeginBuild(area : name)
	{
		askedPins.Clear();
		AnimationForgetObjects();
		ClearLabelHideState();
		debugTiming = CMFSettingsDebug();
		timingPins = 0;
		timingCovered = 0;
		timingFinds = 0;
		timingCandidates = 0;
		timingMemoHits = 0;
		ResetAddedPinCounts();
		marksThisBuild = 0;
		lateStepRan = false;
		inBuild = true;
		entityStepRan = false;
		fieldsStepCount = 0;
		OpenPinList();
		NoteListArea(area);
	}

	public function EndBuild()
	{
		inBuild = false;
		listOpen = false;
	}

	public function NoteLateStep()
	{
		lateStepRan = true;
	}

	// One line per session when a full build ended without CMF's UpdateUserMapPins wrapper running.
	public function CheckLateStep()
	{
		if (!lateStepRan && !lateStepLogged)
		{
			lateStepLogged = true;
			CMFLog("late pin step skipped: another mod replaced UpdateUserMapPins; hides, added pins and drawings may be missing");
		}
	}

	public function NoteEntityStep()
	{
		entityStepRan = true;
	}

	// Version 13: CMF's AddPinTypeData wrapper counts the game pins it saw this build. When the entity step was
	// skipped, CheckEntityStep logs the count, so a launch shows whether AddPinTypeData wrappers still run.
	public function NoteFieldsStep()
	{
		fieldsStepCount += 1;
	}

	public function CheckEntityStep()
	{
		if (inBuild && !entityStepRan && !entitySkipLogged)
		{
			entitySkipLogged = true;
			CMFLog("entity step skipped: another mod replaced CR4MapMenu.UpdateEntityPins; pin list opened by UpdateData");
		}
		if (inBuild && !entityStepRan)
		{
			CMFLog("entity fields step ran n=" + fieldsStepCount);
		}
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
		marksThisBuild = 0;
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
			covers = (Covers(hideClaims[i], pinType, pinTag, maxLevel) ||
				(hideClaims[i].level == 1 && NameToString(hideClaims[i].pinType) == filtered)) &&
				(!IsNameValid(hideClaims[i].mapContext) || hideClaims[i].mapContext == mapContext);
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
			marksThisBuild += 1;
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
		keepRevoked = 0;
		HideGridPins(flashArray, area);
		if (keepRevoked > 0 && CMFSettingsDebug())
		{
			CMFLog("grid keep revoked n=" + keepRevoked);
		}
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
		// Nothing was marked and no claim could mark: the sweep would only read every pin's hidden mark.
		if (marksThisBuild == 0 && hideClaims.Size() == 0 && playerOwner == "")
		{
			return;
		}
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

	// Version 14 (grid): one number key of a grid drawing, or fallback when its owner did not set it.
	private function GridNumber(owner : string, id : name, key : name, fallback : float) : float
	{
		var i : int;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 3 && themeEntries[i].provider == owner && themeEntries[i].target == id &&
				themeEntries[i].key == key)
			{
				return themeEntries[i].number;
			}
		}
		return fallback;
	}

	// Version 14 (grid): a grid drawing whose owner set hidePins to 1 hides, in this late pass, every pin standing on one
	// of its covered cells in the shown area (launch fog5: another mod's pins, pushed after the owner's own filter ran,
	// showed over the fog). The player marker, user pins, pins already hidden and pins the owner kept (CMFGridKeepPin)
	// stay. Positions are the pins' posX and posY in world metres; a pin outside the grid's square is left alone.
	// Version 18: a grid keep is stored on the pin as one record per provider, ";provider=epoch;" repeated, and is valid
	// while the record's epoch equals that provider's current epoch (a provider with no row is at epoch 0).
	public function SetGridKeepEpoch(provider : string, epoch : int)
	{
		var at : int;
		at = keepEpochProviders.FindFirst(provider);
		if (at < 0)
		{
			keepEpochProviders.PushBack(provider);
			keepEpochValues.PushBack(epoch);
		}
		else
		{
			keepEpochValues[at] = epoch;
		}
		if (CMFSettingsDebug())
		{
			CMFLog("grid keep epoch provider=" + provider + " epoch=" + epoch);
		}
	}

	public function GridKeepEpoch(provider : string) : int
	{
		var at : int;
		at = keepEpochProviders.FindFirst(provider);
		if (at < 0)
		{
			return 0;
		}
		return keepEpochValues[at];
	}

	public function GridKeepValid(keepBy : string) : bool
	{
		var rest, part : string;
		var eq : int;
		rest = keepBy + ";";
		while (StrLen(rest) > 0)
		{
			part = StrBeforeFirst(rest, ";");
			rest = StrAfterFirst(rest, ";");
			eq = StrFindFirst(part, "=");
			if (eq > 0 && StringToInt(StrMid(part, eq + 1), 0) == GridKeepEpoch(StrLeft(part, eq)))
			{
				return true;
			}
		}
		return false;
	}

	// The records of keepBy without the one of this provider, in the same format.
	private function GridKeepWithout(keepBy : string, provider : string) : string
	{
		var rest, part, result : string;
		var eq : int;
		rest = keepBy + ";";
		while (StrLen(rest) > 0)
		{
			part = StrBeforeFirst(rest, ";");
			rest = StrAfterFirst(rest, ";");
			eq = StrFindFirst(part, "=");
			if (eq > 0 && StrLeft(part, eq) != provider)
			{
				result += ";" + part;
			}
		}
		if (result != "")
		{
			result += ";";
		}
		return result;
	}

	public function GridKeepAdd(provider : string, dataObject : CScriptedFlashObject) : bool
	{
		var records : string;
		if (provider == "" || !dataObject || StrFindFirst(provider, ";") >= 0 || StrFindFirst(provider, "=") >= 0)
		{
			return false;
		}
		records = GridKeepWithout(dataObject.GetMemberFlashString("cmfGridKeepBy"), provider);
		if (records == "")
		{
			records = ";";
		}
		dataObject.SetMemberFlashString("cmfGridKeepBy", records + provider + "=" + GridKeepEpoch(provider) + ";");
		dataObject.SetMemberFlashBool("cmfGridKeep", true);
		return true;
	}

	public function GridKeepRemove(provider : string, dataObject : CScriptedFlashObject) : bool
	{
		var records : string;
		if (provider == "" || !dataObject)
		{
			return false;
		}
		records = GridKeepWithout(dataObject.GetMemberFlashString("cmfGridKeepBy"), provider);
		dataObject.SetMemberFlashString("cmfGridKeepBy", records);
		dataObject.SetMemberFlashBool("cmfGridKeep", records != "" && GridKeepValid(records));
		return true;
	}

	// The late pass reads the bool first: false is not kept; true with no records is an old writer (kept); otherwise the
	// pin is kept while one record is valid, and the bool is written false when none is.
	private function GridPinKept(dataObject : CScriptedFlashObject) : bool
	{
		var keepBy : string;
		if (!dataObject.GetMemberFlashBool("cmfGridKeep"))
		{
			return false;
		}
		keepBy = dataObject.GetMemberFlashString("cmfGridKeepBy");
		if (keepBy == "" || GridKeepValid(keepBy))
		{
			return true;
		}
		dataObject.SetMemberFlashBool("cmfGridKeep", false);
		keepRevoked += 1;
		return false;
	}

	private function HideGridPins(flashArray : CScriptedFlashArray, area : name)
	{
		var dataObject : CScriptedFlashObject;
		var words, pow2 : array<int>;
		var owner : string;
		var id : name;
		var i, k, p, n, col, row, cell, count : int;
		var left, top, size, x, y : float;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind != 3 || themeEntries[i].key != 'hidePins' || themeEntries[i].number != 1)
			{
				continue;
			}
			id = themeEntries[i].target;
			owner = themeEntries[i].provider;
			if (ThemeDrawingOwner(id) != owner || DrawingKind(owner, id) != 'grid' || !IsSpaceDrawing(id) ||
				!SpaceAreaMatches(id, owner, area))
			{
				continue;
			}
			n = (int)GridNumber(owner, id, 'n', 0);
			size = GridNumber(owner, id, 'span', 0);
			if (n <= 0 || size <= 0)
			{
				continue;
			}
			left = GridNumber(owner, id, 'left', -size / 2);
			top = GridNumber(owner, id, 'top', size / 2);
			size = size / n;
			if (pow2.Size() == 0)
			{
				pow2.PushBack(1);
				for (k = 1; k < 30; k += 1)
				{
					pow2.PushBack(pow2[k - 1] * 2);
				}
			}
			// Bit b of word k is cell k * 30 + b (CMFDrawSetBits); a set bit is a clear cell.
			words.Clear();
			words.Resize((n * n + 29) / 30);
			for (k = 0; k < themeEntries.Size(); k += 1)
			{
				if (themeEntries[k].kind == 6 && themeEntries[k].provider == owner && themeEntries[k].target == id)
				{
					for (p = 0; p + 1 < themeEntries[k].ints.Size(); p += 2)
					{
						if (themeEntries[k].ints[p] >= 0 && themeEntries[k].ints[p] < words.Size())
						{
							words[themeEntries[k].ints[p]] = themeEntries[k].ints[p + 1];
						}
					}
				}
			}
			count = 0;
			for (p = 0; p < flashArray.GetLength(); p += 1)
			{
				dataObject = flashArray.GetElementFlashObject(p);
				if (!dataObject || dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin") ||
					GridPinKept(dataObject) || CMFPinOwner(dataObject, "cmfHiddenBy") != "")
				{
					continue;
				}
				x = dataObject.GetMemberFlashNumber("posX");
				y = dataObject.GetMemberFlashNumber("posY");
				col = FloorF((x - left) / size);
				row = FloorF((top - y) / size);
				if ((x == 0 && y == 0) || col < 0 || row < 0 || col >= n || row >= n)
				{
					continue;
				}
				cell = row * n + col;
				if ((words[cell / 30] / pow2[cell - (cell / 30) * 30]) % 2 == 0)
				{
					MarkHidden(dataObject, owner);
					count += 1;
				}
			}
			CMFLog("grid hid provider=" + owner + " id=" + NameToString(id) + " pins=" + count + " area=" + NameToString(area));
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
		var disabledAt, slot : int;
		var categoryAt : int;
		var noDefault : SCMFClaim;
		// The followed quest keeps vanilla's gold meaning.
		if (PropertyWon(CMFPropertyTint()))
		{
			keepGold = dataObject.GetMemberFlashBool("tracked") || dataObject.GetMemberFlashBool("highlighted");
		}
		if (PropertyWon(CMFPropertyIcon()) && CMFPinOwner(dataObject, "cmfIconBy") == "" &&
			(FindPinClaim(CMFPropertyIcon(), pinKey, legendKey, pinTag, maxLevel, claim)))
		{
			dataObject.SetMemberFlashString("cmfIconPath", claim.text);
			dataObject.SetMemberFlashString("cmfIconSourceBy", claim.provider);
		}
		// Version 11: a "frame:<label>" icon names a frame of the pin's own art, which the legend row cannot show, so the
		// row keeps its picture.
		if (Find(CMFPropertyLegendIcon(), legendKey, '', 1, claim) || Find(CMFPropertyIcon(), legendKey, '', 1, claim))
		{
			if (!StrBeginsWith(claim.text, "frame:"))
			{
				dataObject.SetMemberFlashString("cmfLegendIconPath", claim.text);
			}
		}
		else if (Find(CMFPropertyLegendIcon(), pinKey, '', 1, claim) || Find(CMFPropertyIcon(), pinKey, '', 1, claim))
		{
			if (!StrBeginsWith(claim.text, "frame:"))
			{
				dataObject.SetMemberFlashString("cmfLegendIconPath", claim.text);
				legendFromPin = true;
			}
		}
		if (PropertyWon(45) || PropertyWon(46)) { AnimationLegend(dataObject, pinKey, legendKey); }
		// API 14 picture fit: the legend row's picture follows the same claim (the panel scales its box to the row's glyph).
		if (PropertyWon(48) && (Find(48, legendKey, '', 1, claim) || Find(48, pinKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashInt("cmfLegendFit", claim.number);
			dataObject.SetMemberFlashBool("cmfLegendFitEnabled", true);
		}
		if (PropertyWon(CMFPropertyTint()) && !keepGold && CMFPinOwner(dataObject, "cmfTintBy") == "" && (FindPinClaim(CMFPropertyTint(), pinKey, legendKey, pinTag, maxLevel, claim)))
		{
			dataObject.SetMemberFlashUInt("cmfIconTint", claim.number);
			dataObject.SetMemberFlashBool("cmfIconTintEnabled", true);
		}
		// One legend row stands for every pin type sharing its filteredType, so its tint comes from the
		// legend name; the pin's own type only when the row's art came from it too.
		if (Find(41, legendKey, '', 1, claim) ||
			Find(CMFPropertyTint(), legendKey, '', 1, claim) || (legendFromPin && Find(CMFPropertyTint(), pinKey, '', 1, claim)))
		{
			dataObject.SetMemberFlashUInt("cmfLegendTint", claim.number);
			dataObject.SetMemberFlashBool("cmfLegendTintEnabled", true);
		}
		// Every won row claim moves its row, the game's own rows too (every claim reaches the panel with a priority of
		// at least 1); labels apply to any row except the shared quest and user-pin rows. A category nobody declared
		// leaves a mod's row under All. Version 6: a row claim on a quest pin's filteredType gives those quest pins that
		// row instead of the shared quest row (the panel reads cmfLegendPriority > 0 on a quest pin as that claim).
		// Version 12: a claim on one of the game's own rows whose tab is empty or nobody declared keeps the row in its
		// own tab (Kyle 2026-10-25: a misspelt tab never pulls a game row out of its tab).
		if (Find(CMFPropertyLegendRow(), legendKey, '', 1, claim) && gamePinNow && !CMFIsVanillaCategory(claim.text, false) &&
			CategoryIndex(claim.text) < 0)
		{
			if (!rowsKept.Contains(legendKey))
			{
				rowsKept.PushBack(legendKey);
				CMFLog("legend row kept type=" + legendKey + " category=" + claim.text + " provider=" + claim.provider +
					" reason=category");
			}
		}
		else if (Find(CMFPropertyLegendRow(), legendKey, '', 1, claim))
		{
			rowHide = true;
			LogPinDetail("pin legend row type=" + dataObject.GetMemberFlashString("type") + " filteredType=" + legendKey +
				" category=" + claim.text + " priority=" + LegendPriority(claim.number));
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
		for (slot = 0; slot < activeWriteSlots.Size(); slot += 1)
		{
			WriteSlot(dataObject, activeWriteSlots[slot], pinKey, legendKey, pinTag, maxLevel);
		}

		// Version 11: the info box height of this pin's type, tag or place; an every-pin height stays the menu's. Version
		// 12: each key is asked on its own, so an every-pin height never hides a height on a pushed pin's legend name.
		if (PropertyWon(CMFPropertyInfoBoxHeight()) && specificWon[CMFPropertyInfoBoxHeight()] &&
			CMFPinOwner(dataObject, "cmfDescMaxHBy") == "" &&
			((Find(CMFPropertyInfoBoxHeight(), pinKey, pinTag, maxLevel, claim) && claim.level > 0) ||
			(Find(CMFPropertyInfoBoxHeight(), legendKey, '', 1, claim) && claim.level > 0)))
		{
			SetSlot(dataObject, CMFPropertyInfoBoxHeight(), claim.text, claim.number);
		}
		if (PropertyWon(39) && specificWon[39] && CMFPinOwner(dataObject, "cmfDescMaxWBy") == "" &&
			((Find(39, pinKey, pinTag, maxLevel, claim) && claim.level > 0) ||
			(Find(39, legendKey, '', 1, claim) && claim.level > 0)))
		{
			SetSlot(dataObject, 39, claim.text, claim.number);
		}
		if (PropertyWon(45) || PropertyWon(46)) { AnimationOffsets(dataObject, pinKey, legendKey, pinTag, maxLevel); }
		WriteClickFields(dataObject, pinKey, legendKey, pinTag, maxLevel);
	}

	// Size and label slots from tag and type claims (the pin's type, then its filteredType), unless a
	// per-pin claim already owns the slot on this pin.
	// Preserve the historical own-type preference, except a global cannot mask a specific filtered type.
	private function FindPinClaim(propertyId : int, pinKey : string, legendKey : string, pinTag : name,
		maxLevel : int, out result : SCMFClaim) : bool
	{
		var primary, secondary : SCMFClaim;
		if (Find(propertyId, pinKey, pinTag, maxLevel, primary))
		{
			if (primary.level == 0 && specificWon[propertyId] && pinKey != legendKey && Find(propertyId, legendKey, '', 1, secondary) &&
				secondary.level > 0)
			{
				result = secondary;
			}
			else { result = primary; }
			return true;
		}
		return Find(propertyId, legendKey, '', 1, result);
	}

	private function WriteSlot(dataObject : CScriptedFlashObject, propertyId : int, pinKey : string, legendKey : string,
		pinTag : name, maxLevel : int)
	{
		var claim : SCMFClaim;
		if (!PropertyWon(propertyId)) { return; }
		if (CMFPinOwner(dataObject, CMFOwnerField(propertyId)) != "")
		{
			return;
		}
		if (FindPinClaim(propertyId, pinKey, legendKey, pinTag, maxLevel, claim))
		{
			SetSlot(dataObject, propertyId, claim.text, claim.number);
			SetNewPinFields(dataObject, propertyId, claim.text, claim.number, claim.valueX, claim.valueY, claim.provider);
			if (propertyId == 45) { dataObject.SetMemberFlashString("cmfIconFramesKey", AnimationSlotKey(claim)); }
			if (propertyId == 46) { dataObject.SetMemberFlashString("cmfIconUnderFramesKey", AnimationSlotKey(claim)); }
		}
	}

	private function SetNewPinFields(dataObject : CScriptedFlashObject, propertyId : int, text : string,
		number : int, x : float, y : float, provider : string)
	{
		var canonical, poster, reason, prefix : string;
		if (propertyId == 45 || propertyId == 46)
		{
			if (!ParseAnimation(text, number, canonical, poster, reason)) { return; }
			prefix = "cmfIconFrames";
			if (propertyId == 46) { prefix = "cmfIconUnderFrames"; }
			dataObject.SetMemberFlashString(prefix, canonical);
			dataObject.SetMemberFlashInt(prefix + "Fps", number);
			dataObject.SetMemberFlashString(prefix + "SourceBy", provider);
			AnimationReference(dataObject, propertyId, text, number);
			return;
		}
		switch (propertyId)
		{
			case 31:
				dataObject.SetMemberFlashString("cmfIconSelectedPath", text);
				dataObject.SetMemberFlashString("cmfIconSelectedSourceBy", provider);
				break;
			case 32:
				dataObject.SetMemberFlashNumber("cmfSelectedScale", (float)number / 100);
				dataObject.SetMemberFlashBool("cmfSelectedScaleEnabled", true);
				break;
			case 33:
				dataObject.SetMemberFlashNumber("cmfPinAlpha", (float)number / 100);
				dataObject.SetMemberFlashBool("cmfPinAlphaEnabled", true);
				break;
			case 34:
				dataObject.SetMemberFlashInt("cmfPinOrder", number);
				dataObject.SetMemberFlashBool("cmfPinOrderEnabled", true);
				break;
			case 42:
				dataObject.SetMemberFlashString("cmfIconUnderPath", text);
				dataObject.SetMemberFlashString("cmfIconUnderSourceBy", provider);
				break;
			case 43:
				dataObject.SetMemberFlashUInt("cmfIconUnderTint", number);
				dataObject.SetMemberFlashBool("cmfIconUnderTintEnabled", true);
				break;
			case 44:
				dataObject.SetMemberFlashNumber("cmfPictureScale", (float)number / 100);
				dataObject.SetMemberFlashBool("cmfPictureScaleEnabled", true);
				break;
			case 48:
				dataObject.SetMemberFlashInt("cmfPictureFit", number);
				dataObject.SetMemberFlashBool("cmfPictureFitEnabled", true);
				break;
			case 35:
				dataObject.SetMemberFlashNumber("cmfPinOffsetX", x);
				dataObject.SetMemberFlashNumber("cmfPinOffsetY", y);
				dataObject.SetMemberFlashBool("cmfPinOffsetEnabled", true);
				break;
			case 36:
				dataObject.SetMemberFlashNumber("cmfPinZoomMin", x);
				dataObject.SetMemberFlashNumber("cmfPinZoomMax", y);
				dataObject.SetMemberFlashBool("cmfPinZoomEnabled", true);
				break;
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
			case 28:
				dataObject.SetMemberFlashInt("cmfHoverName", number);
				break;
			case 14:
				dataObject.SetMemberFlashNumber("cmfDescMaxH", number);
				break;
			case 39:
				dataObject.SetMemberFlashNumber("cmfDescMaxW", number);
				dataObject.SetMemberFlashBool("cmfDescMaxWEnabled", number > 0);
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
		if (!PropertyWon(CMFPropertyDisabled()))
		{
			return -1;
		}
		for (i = 0; i < winners.Size(); i += 1)
		{
			matches = winners[i].propertyId == CMFPropertyDisabled() && Covers(winners[i], pinType, pinTag, maxLevel) &&
				(!IsNameValid(winners[i].mapContext) || winners[i].mapContext == mapContext);
			if (!matches)
			{
				continue;
			}
			score = Specific(winners[i]) * 2;
			if (IsNameValid(winners[i].mapContext))
			{
				score += 1;
			}
			if (score > bestScore)
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
		var i, a, b, c, next, best, picked, chosen, choice, rank, bestRank, pickedRank, t, tv, g, memoAt : int;
		var matches : bool;
		var answer : string;
		if (propertyId < 0 || propertyId >= propertyWon.Size() || !propertyWon[propertyId])
		{
			return false;
		}
		best = -1;
		picked = -1;
		bestRank = -1;
		pickedRank = -1;
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
		// Only the candidate is cached. A group's Vanilla or strict explicit choice still applies above/below.
		if (!specificWon[propertyId] && globalWinner[propertyId] >= 0)
		{
			i = globalWinner[propertyId];
			if (maxLevel < 0 || (answer != "" && answer != winners[i].provider && fallVanilla)) { return false; }
			result = winners[i];
			return true;
		}
		// Opening speed (1.10.1): the candidates are the winners of this property that can cover the pin (every pin,
		// its type, its level variant type, its tag), in the order of the property's chain. Covers decides each one as
		// before, so the answer is the one the whole chain gave. A pin type with no tag, variant or place asks the
		// same thing every time in a preparation, so its answer is remembered.
		candidates.Clear();
		memoAt = -1;
		if (indexBuilt)
		{
			t = typeKeys.FindFirst(pinType);
			tv = -1;
			if (variantNow != "" && variantNow != pinType)
			{
				tv = typeKeys.FindFirst(variantNow);
			}
			g = -1;
			if (IsNameValid(pinTag))
			{
				g = tagKeys.FindFirst(pinTag);
			}
			if (t >= 0 && tv < 0 && g < 0 && !placeOk && maxLevel >= 0 && maxLevel <= 3 && (variantNow == "" || variantNow != pinType))
			{
				memoAt = (maxLevel * typeKeys.Size() + t) * 64 + propertyId;
				if (memoState[memoAt] == 1)
				{
					if (debugTiming) { timingMemoHits += 1; }
					return false;
				}
				if (memoState[memoAt] >= 2)
				{
					if (debugTiming) { timingMemoHits += 1; }
					result = winners[memoState[memoAt] - 2];
					return true;
				}
			}
			next = globalHead[propertyId] - 1;
			while (next >= 0)
			{
				candidates.PushBack(next);
				next = globalNext[next] - 1;
			}
			if (t >= 0)
			{
				next = typeHead[t * 64 + propertyId] - 1;
				while (next >= 0)
				{
					candidates.PushBack(next);
					next = typeNext[next] - 1;
				}
			}
			if (tv >= 0)
			{
				next = typeHead[tv * 64 + propertyId] - 1;
				while (next >= 0)
				{
					candidates.PushBack(next);
					next = typeNext[next] - 1;
				}
			}
			if (g >= 0)
			{
				next = tagHead[g * 64 + propertyId] - 1;
				while (next >= 0)
				{
					candidates.PushBack(next);
					next = tagNext[next] - 1;
				}
			}
			// Each list is in chain order; one ordered pass keeps ties going to the earlier winner.
			for (a = 1; a < candidates.Size(); a += 1)
			{
				c = candidates[a];
				b = a - 1;
				while (b >= 0 && candidates[b] > c)
				{
					i = b + 1;
					candidates[i] = candidates[b];
					b -= 1;
				}
				i = b + 1;
				candidates[i] = c;
			}
		}
		else
		{
			next = propertyFirst[propertyId];
			while (next >= 0)
			{
				candidates.PushBack(next);
				next = propertyNext[next];
			}
		}
		if (debugTiming)
		{
			timingFinds += 1;
			timingCandidates += candidates.Size();
		}
		for (a = 0; a < candidates.Size(); a += 1)
		{
			i = candidates[a];
			matches = winners[i].propertyId == propertyId && Covers(winners[i], pinType, pinTag, maxLevel);
			if (matches && (winners[i].level == 2 || winners[i].level == CMFLevelPlace()))
			{
				// Instance claims never reveal undiscovered "?" pins or restyle completed ("Disabled") ones; version 11:
				// the undiscovered and completed art (29, 30) is for exactly those.
				matches = !CMFKindHidden(pinType) || propertyId == CMFPropertyIconUndiscovered() ||
					propertyId == CMFPropertyIconCompleted();
			}
			if (!matches)
			{
				continue;
			}
			rank = Specific(winners[i]);
			if (best < 0 || rank > bestRank || (rank == bestRank && TagBeats(choice, winners[i], winners[best])))
			{
				best = i;
				bestRank = rank;
			}
			if (answer != "" && winners[i].provider == answer && (picked < 0 || rank > pickedRank))
			{
				picked = i;
				pickedRank = rank;
			}
		}
		// A selected global offer is a fallback; any eligible specific claim still wins.
		chosen = -1;
		if (picked >= 0 && pickedRank == 0 && bestRank > 0)
		{
			chosen = best;
		}
		else if (picked >= 0)
		{
			chosen = picked;
		}
		else if (!(best < 0 || (answer != "" && fallVanilla)))
		{
			chosen = best;
		}
		if (memoAt >= 0)
		{
			memoState[memoAt] = chosen + 2;
			if (chosen < 0) { memoState[memoAt] = 1; }
		}
		if (chosen < 0)
		{
			return false;
		}
		result = winners[chosen];
		return true;
	}

	// Version 12: between two providers' tag claims on one tag, the one whose provider wins the pin's piece (choice).
	private function TagBeats(choice : int, a : SCMFClaim, b : SCMFClaim) : bool
	{
		if (a.level != 2 || b.level != 2 || a.provider == b.provider)
		{
			return false;
		}
		if (choicesActive && choice >= 0)
		{
			return PieceBeats(choice, a.provider, b.provider);
		}
		return ProviderBeats(a.provider, b.provider);
	}

	// Version 11: whether a claim covers the pin asked about (its type, tag, and while a pin is being written its level
	// variant type and its place), considering levels up to maxLevel. Lookups for a pin pass CMFLevelPlace(); legend
	// rows and other surfaces pass 1, so place and variant claims never reach them.
	private function Covers(claim : SCMFClaim, pinType : string, pinTag : name, maxLevel : int) : bool
	{
		var dx, dy : float;
		if (claim.level > maxLevel)
		{
			return false;
		}
		switch (claim.level)
		{
			case 0:
				return true;
			case 1:
				if (NameToString(claim.pinType) == pinType)
				{
					return true;
				}
				return maxLevel >= CMFLevelPlace() && variantNow != "" && pinType == pinKeyNow &&
					NameToString(claim.pinType) == variantNow;
			case 2:
				return IsNameValid(pinTag) && claim.pinTag == pinTag;
			case 3:
				if (!placeOk || (NameToString(claim.pinType) != pinType && NameToString(claim.pinType) != variantNow))
				{
					return false;
				}
				dx = claim.placeX - placeX;
				dy = claim.placeY - placeY;
				return dx * dx + dy * dy <= CMFPlaceRadius() * CMFPlaceRadius();
		}
		return false;
	}

	// Version 11: how specific a claim is for the pin being written: every pin, type, level variant type, place, tag.
	private function Specific(claim : SCMFClaim) : int
	{
		switch (claim.level)
		{
			case 1:
				if (variantNow != "" && NameToString(claim.pinType) == variantNow)
				{
					return 3;
				}
				return 2;
			case 2:
				return 6;
			case 3:
				return 4;
		}
		return 0;
	}

	// Version 11: the pin about to be written. pinKey is the key its claims are asked with (the game's visible type, or a
	// pushed pin's own type); its own type counts as a level variant when it differs; posX and posY place it.
	private function SetPinContext(dataObject : CScriptedFlashObject, pinKey : string)
	{
		var own : string;
		pinKeyNow = pinKey;
		own = dataObject.GetMemberFlashString("type");
		variantNow = "";
		if (own != pinKey && StrBeginsWith(own, pinKey))
		{
			variantNow = own;
		}
		placeOk = placeClaims > 0;
		if (placeOk)
		{
			placeX = dataObject.GetMemberFlashNumber("posX");
			placeY = dataObject.GetMemberFlashNumber("posY");
		}
	}

	private function ClearPinContext()
	{
		pinKeyNow = "";
		variantNow = "";
		placeOk = false;
	}

	private function SameSlot(a : SCMFClaim, b : SCMFClaim) : bool
	{
		return a.propertyId == b.propertyId && a.level == b.level && a.pinType == b.pinType && a.pinTag == b.pinTag &&
			a.mapContext == b.mapContext && a.placeX == b.placeX && a.placeY == b.placeY;
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

	// Decimal text only. Accumulate negatively so INT_MIN never overflows while it is parsed.
	private function ParseAskInt(text : string, out number : int) : bool
	{
		var negative : bool;
		var digit, lastDigit, i : int;
		number = 0;
		negative = StrBeginsWith(text, "-");
		if (negative || StrBeginsWith(text, "+")) { text = StrRight(text, StrLen(text) - 1); }
		if (text == "") { return false; }
		lastDigit = 7;
		if (negative) { lastDigit = 8; }
		for (i = 0; i < StrLen(text); i += 1)
		{
			digit = StrFindFirst("0123456789", StrMid(text, i, 1));
			if (digit < 0 || number < -214748364 || (number == -214748364 && digit > lastDigit))
			{
				return false;
			}
			number = number * 10 - digit;
		}
		if (!negative) { number = -number; }
		return true;
	}

	// A CMF-free provider appends its folder, and owns only the payload carrying that exact suffix.
	// Parsing is the only work here: StylePin keeps every value, choice, ownership and diagnostic rule.
	private function ProcessPinAsks(dataObject : CScriptedFlashObject) : bool
	{
		var rest, provider, identity, suffix, text, ids, idText, numberText : string;
		var seen : array<string>;
		var propertyId, number : int;
		var asked : bool;
		rest = dataObject.GetMemberFlashString("cmfAskBy");
		if (rest == "") { return false; }
		rest += ",";
		while (StrLen(rest) > 0)
		{
			provider = TrimFilterWord(StrBeforeFirst(rest, ","));
			rest = StrAfterFirst(rest, ",");
			identity = StrLower(provider);
			if (provider == "" || seen.Contains(identity)) { continue; }
			seen.PushBack(identity);
			asked = true;
			suffix = "_" + provider;
			text = dataObject.GetMemberFlashString("cmfAskIcon" + suffix);
			if (text != "") { StylePin(provider, dataObject, CMFPropertyIcon(), text, 0); }
			text = dataObject.GetMemberFlashString("cmfAskTint" + suffix);
			if (text != "")
			{
				if (ParseAskInt(text, number)) { StylePin(provider, dataObject, CMFPropertyTint(), "", number); }
				else { NoteProviderPresent(provider); NoteStyleRejected(provider, CMFPropertyTint(), "range"); }
			}
			text = dataObject.GetMemberFlashString("cmfAskScale" + suffix);
			if (text != "")
			{
				if (ParseAskInt(text, number)) { StylePin(provider, dataObject, CMFPropertyPinScale(), "", number); }
				else { NoteProviderPresent(provider); NoteStyleRejected(provider, CMFPropertyPinScale(), "range"); }
			}
			text = dataObject.GetMemberFlashString("cmfAskLabel" + suffix);
			if (text != "") { StylePin(provider, dataObject, CMFPropertyLabelText(), text, 0); }
			ids = dataObject.GetMemberFlashString("cmfAskIds" + suffix);
			if (ids == "") { continue; }
			ids += ",";
			while (StrLen(ids) > 0)
			{
				idText = TrimFilterWord(StrBeforeFirst(ids, ","));
				ids = StrAfterFirst(ids, ",");
				if (idText == "") { continue; }
				if (!ParseAskInt(idText, propertyId))
				{
					NoteProviderPresent(provider);
					NoteStyleRejected(provider, 0, "range");
					continue;
				}
				text = dataObject.GetMemberFlashString("cmfAskText" + idText + suffix);
				numberText = dataObject.GetMemberFlashString("cmfAskNumber" + idText + suffix);
				number = 0;
				if (numberText != "" && !ParseAskInt(numberText, number))
				{
					NoteProviderPresent(provider);
					NoteStyleRejected(provider, propertyId, "range");
					continue;
				}
				StylePin(provider, dataObject, propertyId, text, number);
			}
		}
		return asked;
	}

	// UpdateData calls after CatchLatePins so the one build total includes its late pass.
	public function ReportPinAsks()
	{
		if (askedPins.Size() > 0) { CMFLog("asks pins=" + askedPins.Size()); }
		askedPins.Clear();
	}

	// Per-pin style (CMFStylePin). The winning provider is stored on the pin in an owner field, so the
	// result does not depend on which wrapper runs first; CMF's own writers skip owned properties.
	public function StylePin(provider : string, dataObject : CScriptedFlashObject, propertyId : int, text : string,
		number : int) : bool
	{
		var ownerField : string;
		var owner : string;
		var flags : int;
		var tabs, canonical, poster, reason, prefix : string;
		var choice : int;
		var valueX, valueY : float;
		NoteProviderPresent(provider);
		// Version 6: clicks, hints and buttons have their own rules (StyleClick).
		if (CMFIsClickProperty(propertyId))
		{
			return StyleClick(provider, dataObject, propertyId, text, number);
		}
		if (propertyId == 40 && text == "" && provider != "" && dataObject)
		{
			if (number == 45 || number == 46) { return AnimationWithdraw(provider, dataObject, number); }
			if (number == 47) { return AnimationDirectOffset(provider, dataObject, 0, true); }
		}
		ownerField = CMFOwnerField(propertyId);
		if (ownerField == "")
		{
			NoteStyleRejected(provider, propertyId, "style");
			return false;
		}
		if (provider == "" || !dataObject ||
			((propertyId == CMFPropertyIcon() || propertyId == CMFPropertyLabelText() || propertyId == CMFPropertyInfoTitle() ||
			propertyId == CMFPropertyInfoText() || propertyId == CMFPropertyIconUndiscovered() ||
			propertyId == CMFPropertyIconCompleted()) && text == "") ||
			((propertyId == CMFPropertyLabelHide() || propertyId == CMFPropertyTabHide()) && number == 0))
		{
			NoteStyleRejected(provider, propertyId, "empty");
			return false;
		}
		if ((propertyId == 45 || propertyId == 46) && number == 0)
		{
			return AnimationWithdraw(provider, dataObject, propertyId);
		}
		// Width zero releases only this provider's direct width; another owner is untouched.
		if (propertyId == 39 && number == 0)
		{
			owner = CMFPinOwner(dataObject, ownerField);
			if (owner == "") { return true; }
			if (owner != provider) { return false; }
			SetSlot(dataObject, 39, "", 0);
			dataObject.SetMemberFlashString(ownerField, "");
			return true;
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
			(propertyId == CMFPropertySpreadRank() && (number < 0 || number > 1000)) ||
			(propertyId == CMFPropertyHoverName() && (number < 0 || number > 3)) ||
			(propertyId == CMFPropertyInfoBoxHeight() && (number < 100 || number > 1080)) ||
			((propertyId == CMFPropertyInfoTitle() || propertyId == CMFPropertyInfoText()) &&
			number != CMFInfoReplace() && number != CMFInfoAdd()))
		{
			NoteStyleRejected(provider, propertyId, "range");
			return false;
		}
		if (!NewPinValueOk(propertyId, text, number, valueX, valueY))
		{
			NoteStyleRejected(provider, propertyId, "range");
			return false;
		}
		if (propertyId == 47) { return AnimationDirectOffset(provider, dataObject, number, false); }
		if (propertyId == 45 || propertyId == 46)
		{
			if (!ParseAnimation(text, number, canonical, poster, reason))
			{
				AnimationNote(provider, propertyId, reason);
				AnimationPrune();
				return false;
			}
		}
		// Version 11: undiscovered and completed art only on a pin in that state.
		if ((propertyId == CMFPropertyIconUndiscovered() &&
			!StrBeginsWith(dataObject.GetMemberFlashString("filteredType"), "NotDiscoveredPOI")) ||
			(propertyId == CMFPropertyIconCompleted() && !StrEndsWith(dataObject.GetMemberFlashString("filteredType"), "Disabled")))
		{
			NoteStyleRejected(provider, propertyId, "state");
			return false;
		}
		// Version 11: lines added to the info box: every provider's apply, so there is no loser.
		if ((propertyId == CMFPropertyInfoTitle() || propertyId == CMFPropertyInfoText()) && number == CMFInfoAdd())
		{
			NoteStyledOffer(71, provider);
			if (!AnswerAllows(71, provider))
			{
				NoteStyleRejected(provider, propertyId, "choice");
				return false;
			}
			if (propertyId == CMFPropertyInfoTitle())
			{
				AddInfoText(dataObject, "label", text);
			}
			else
			{
				AddInfoText(dataObject, "description", text);
			}
			return true;
		}
		if ((propertyId == CMFPropertyLabelHide() && !CMFParseLabelHide(text, flags)) ||
			(propertyId == CMFPropertyTabHide() && !CMFParseTabs(text, tabs)))
		{
			NoteStyleRejected(provider, propertyId, "text");
			return false;
		}
		if (propertyId == CMFPropertyLabelHide())
		{
			if (ChoiceOnlySkips(31, provider)) { return false; }
			NoteStyledOffer(31, provider);
			NoteLabelHideOffer(provider);
			MergeLabelHide(dataObject, provider, flags);
			return AnswerAllows(31, provider);
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
			if (propertyId == 45 || propertyId == 46) { AnimationNote(provider, propertyId, "choice"); AnimationPrune(); }
			return false;
		}
		owner = CMFPinOwner(dataObject, ownerField);
		if (owner != "" && owner != provider)
		{
			if (PieceBeats(choice, owner, provider))
			{
				NoteStyleShadow(provider, owner, dataObject, propertyId);
				if (propertyId == 45 || propertyId == 46) { AnimationNote(provider, propertyId, "shadowed"); AnimationPrune(); }
				return false;
			}
			NoteStyleShadow(owner, provider, dataObject, propertyId);
		}
		if (propertyId == CMFPropertyIcon() || propertyId == CMFPropertyIconUndiscovered() ||
			propertyId == CMFPropertyIconCompleted())
		{
			dataObject.SetMemberFlashString("cmfIconPath", text);
			dataObject.SetMemberFlashString("cmfIconSourceBy", provider);
			dataObject.SetMemberFlashBool("cmfIconFramesMasked", propertyId == 29 || propertyId == 30);
		}
		else if (propertyId == CMFPropertyInfoTitle())
		{
			dataObject.SetMemberFlashString("label", text);
			// In OnPinReady, after the add claims' lines were written: they stay below the new title.
			if (infoWritten)
			{
				AppendInfoAdds(dataObject, infoKey, infoLegend, infoTag, "label");
			}
		}
		else if (propertyId == CMFPropertyInfoText())
		{
			dataObject.SetMemberFlashString("description", text);
			if (infoWritten)
			{
				AppendInfoAdds(dataObject, infoKey, infoLegend, infoTag, "description");
			}
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
		SetNewPinFields(dataObject, propertyId, text, number, valueX, valueY, provider);
		dataObject.SetMemberFlashString(ownerField, provider);
		if (propertyId == 45 || propertyId == 46)
		{
			AnimationAccepted(provider, propertyId, text, number);
			prefix = "cmfIconFrames";
			if (propertyId == 46) { prefix = "cmfIconUnderFrames"; }
			dataObject.SetMemberFlashString(prefix + "Key", provider + "/" + propertyId + "/direct/" + AnimationPinKey(dataObject));
			AnimationOffsets(dataObject, dataObject.GetMemberFlashString("type"), dataObject.GetMemberFlashString("filteredType"), LateTag(dataObject), CMFLevelPlace());
		}
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
		if (!PropertyWon(CMFPropertyPinClick())) { return; }
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
	// per provider and pin type); button and hold stay. A short hold press keeps the game action.
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
		if (CMFHasFlag(flags, CMFClickInputHold()))
		{
			if (CMFHasFlag(flags, CMFClickInputButton()))
			{
				return CMFClickInputButton() + CMFClickInputHold();
			}
			return CMFClickInputHold();
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
		var i, best, rank, bestRank : int;
		var matches : bool;
		if (!PropertyWon(propertyId))
		{
			return false;
		}
		best = -1;
		bestRank = -1;
		for (i = 0; i < winners.Size(); i += 1)
		{
			matches = winners[i].propertyId == propertyId && winners[i].provider == provider &&
				Covers(winners[i], pinType, pinTag, maxLevel);
			if (matches && (winners[i].level == 2 || winners[i].level == CMFLevelPlace()))
			{
				matches = !CMFKindHidden(pinType);
			}
			if (!matches)
			{
				continue;
			}
			rank = Specific(winners[i]);
			if (best < 0 || rank > bestRank || (rank == bestRank && winners[i].order < winners[best].order))
			{
				best = i;
				bestRank = rank;
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
		if (provider == "" || (input != "use" && input != "doubleClick" && input != "button" && input != "hold"))
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
	// own provider id, so wrapper order never matters. input is "use", "doubleClick", "button" or "hold"; value is the
	// claim's number.
	public function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string,
		input : string, value : int) : bool
	{
		CMFLog("click provider=" + provider + " pin=" + pinId + " reason=nohandler");
		return false;
	}

	// Managed hints are not drawing ids. Recheck both the prepared list and its current winner.
	public function HintClicked(menu : CR4MapMenu, owner : string, value : int)
	{
		if (value <= 0 || owner == "" || owner != hintListPreparedOwner || owner != ThemeStyleOwner('hints', 'list'))
		{
			return;
		}
		OnDrawingClicked(menu, owner, 'hints', "hint", value);
	}

	// Map-space drawing: called by the map panel (OnCMFDrawingClicked) once per click on a drawing whose click
	// key is 1 or more (value). Logs it and hands it to OnDrawingClicked for the drawing's owner (the earliest
	// folder that made the id).
	// Resolve the current drawing owner from its string id; never convert an arbitrary string to a name.
	// Typed-name metadata only; the panel walks pins only when a live movie reads map.pins.
	public function MovieControlsWanted() : bool
	{
		var i : int;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].key == 'movie' && !IsSpaceDrawing(themeEntries[i].target) &&
				ThemeDrawingOwner(themeEntries[i].target) == themeEntries[i].provider) { return true; }
		}
		return false;
	}

	private function SendMovieTags(storage : CScriptedFlashValueStorage)
	{
		var tags : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var areas : array<SAreaMapPinInfo>;
		var i : int;
		if (!MovieControlsWanted()) { return; }
		tags = storage.CreateTempFlashArray();
		for (i = 0; i < declaredTagNames.Size(); i += 1)
		{
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("k", "tag");
			item.SetMemberFlashUInt("id", NameToFlashUInt(declaredTagNames[i]));
			item.SetMemberFlashString("text", NameToString(declaredTagNames[i]));
			tags.PushBackFlashObject(item);
		}
		areas = theGame.GetCommonMapManager().GetAreaMapPins();
		for (i = 0; i < areas.Size(); i += 1)
		{
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashString("k", "area");
			item.SetMemberFlashUInt("id", NameToFlashUInt(areas[i].areaName));
			item.SetMemberFlashString("text", NameToString(areas[i].areaName));
			tags.PushBackFlashObject(item);
		}
		storage.SetFlashArray("cmf.map.movieTags", tags);
	}

	// Unknown movie text shares the session-long provider/tag diagnostic table.
	public function MovieTagUnknown(id : string, text : string)
	{
		var i : int;
		var owner : string;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].key == 'movie' && NameToString(themeEntries[i].target) == id)
			{
				owner = ThemeDrawingOwner(themeEntries[i].target);
				if (owner != "" && owner == themeEntries[i].provider) { ResolveKnownTag(owner, text); return; }
			}
		}
	}

	public function OnMapAreaReady(menu : CR4MapMenu, area : name)
	{
	}

	public function MovieEvent(menu : CR4MapMenu, id : string, eventName : string, value : string)
	{
		var i : int;
		var owner : string;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].key == 'movie' && NameToString(themeEntries[i].target) == id)
			{
				owner = ThemeDrawingOwner(themeEntries[i].target);
				if (owner != "" && owner == themeEntries[i].provider)
				{
					OnMovieEvent(menu, owner, id, eventName, value);
					return;
				}
			}
		}
	}

	public function OnMovieEvent(menu : CR4MapMenu, provider : string, id : string, eventName : string, value : string) : bool
	{
		return false;
	}

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
		NoteProviderPresent(provider);
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
		NoteProviderPresent(provider);
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
// True for a pin type that hides its kind: the undiscovered "?" pin and completed ("...Disabled") places.
function CMFKindHidden(pinType : string) : bool
{
	return StrBeginsWith(pinType, "NotDiscoveredPOI") || StrEndsWith(pinType, "Disabled");
}

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
		propertyId == CMFPropertySpreadRank() || CMFIsClickProperty(propertyId) || propertyId == CMFPropertyHoverName() ||
		propertyId == CMFPropertyInfoTitle() || propertyId == CMFPropertyInfoText() ||
		propertyId == CMFPropertyIconUndiscovered() || propertyId == CMFPropertyIconCompleted() ||
		propertyId == CMFPropertyTabHidden() || propertyId == CMFPropertyPresent() ||
		(propertyId >= 31 && propertyId <= 36) || (propertyId >= 39 && propertyId <= 49);
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
// or for CMFPropertyWorldPainting columns * 10 + rows of a tile url. Version 10: CMFPropertyHoverName number = bits (1 the
// label line only on the hovered pin, 2 the hovered pin's name on its label line, 0 as the game shows it), target '' for
// every pin. Version 11: CMFPropertyInfoBoxHeight also for a type; CMFPropertyInfoTitle and CMFPropertyInfoText text = the
// words (HTML), number 0 to replace the game's or 1 to add them as lines below, target '' for every pin;
// CMFPropertyIconUndiscovered and CMFPropertyIconCompleted text = the art, target = the pin's real kind ('' every pin);
// CMFPropertyTabHidden target = the tab and number nonzero (0 withdraws). A type claim on a level variant type
// ('MonsterNest_2') beats the base type's claim on those pins, and type claims on exactly 'Player' (the player marker)
// or 'User1' to 'User7' (the player's own markers) restyle them with ids 1, 3 and 10.
// Returns false and logs when the claim is not accepted.
function CMFRegister(provider : string, propertyId : int, target : name, mapContext : name, text : string,
	number : int) : bool
{
	var claim : SCMFClaim;
	var effectiveId : int;
	var present : bool;
	effectiveId = propertyId;
	if (propertyId == 40) { effectiveId = number; }
	present = theGame.CMFGetCore().NoteProviderPresent(provider);
	if (propertyId == CMFPropertyPresent())
	{
		if (!present)
		{
			CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=empty");
		}
		return present;
	}
	if (propertyId == CMFPropertyGridKeepEpoch())
	{
		if (!present)
		{
			CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=empty");
			return false;
		}
		theGame.CMFGetCore().SetGridKeepEpoch(provider, number);
		return true;
	}
	if (!CMFHasProperty(propertyId))
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=unknown");
		return false;
	}
	if (IsNameValid(mapContext) && effectiveId != CMFPropertyDisabled() && effectiveId != CMFPropertyHidden())
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=context");
		return false;
	}
	claim.provider = provider;
	claim.propertyId = propertyId;
	claim.level = 1;
	if (theGame.CMFGetCore().EveryPinProperty(effectiveId) && !IsNameValid(target))
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

// Version 11: a declaration names an installed provider without offering or selecting any map feature.
function CMFDeclareProvider(provider : string) : bool
{
	return CMFRegister(provider, CMFPropertyPresent(), '', '', "", 1);
}

// Query only: asking about an absent provider never declares it.
// Revision 13: make a typed tag available to item styles, drawing filters and movie controls for this session.
// Idempotent per provider and tag; CMFReleaseProvider removes only this provider's registrations.
function CMFDeclareTag(provider : string, tag : name) : bool
{
	return theGame.CMFGetCore().DeclareTag(provider, tag);
}

function CMFProviderPresent(provider : string) : bool
{
	return theGame.CMFGetCore().ProviderPresent(provider);
}

// One pin instance by its map pin tag; beats type-level claims on that pin. Accepts CMFPropertyIcon,
// CMFPropertyDisabled, CMFPropertyHidden, (version 4) ids 10-13 and 15, (version 5) id 17, (version 6) ids 16,
// 20, 21 and 22, (version 10) id 28 and (version 11) the colour (3), the info box height (14), title and text (18, 19)
// and the undiscovered and completed art (29, 30). The game's own pins carry
// their tag. A pin a mod pushes itself is reached when that mod sets the pin's id to
// NameToFlashUInt(its tag), as the game does (version 4), so any mod can target another mod's pins by tag. Icon, disabled, size and label
// instance claims never apply to undiscovered "?" pins or completed pins (version 11: ids 29 and 30 are for exactly
// those); a hide claim covers its pin in every state.
function CMFRegisterForTag(provider : string, propertyId : int, pinTag : name, mapContext : name, text : string,
	number : int) : bool
{
	var claim : SCMFClaim;
	var effectiveId : int;
	effectiveId = propertyId;
	if (propertyId == 40) { effectiveId = number; }
	theGame.CMFGetCore().NoteProviderPresent(provider);
	if (!CMFOnePinProperty(effectiveId))
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=level");
		return false;
	}
	if (IsNameValid(mapContext) && effectiveId != CMFPropertyDisabled() && effectiveId != CMFPropertyHidden())
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

// The properties a tag (CMFRegisterForTag) or place (CMFRegisterForPlace) claim takes.
function CMFOnePinProperty(propertyId : int) : bool
{
	return propertyId == CMFPropertyIcon() || propertyId == CMFPropertyTint() || propertyId == CMFPropertyDisabled() ||
		propertyId == CMFPropertyHidden() || (propertyId >= CMFPropertyPinScale() && propertyId <= CMFPropertyTabHide()) ||
		propertyId == CMFPropertyLabelColor() || CMFIsClickProperty(propertyId) || propertyId == CMFPropertySpreadRank() ||
		propertyId == CMFPropertyHoverName() || propertyId == CMFPropertyInfoTitle() || propertyId == CMFPropertyInfoText() ||
		propertyId == CMFPropertyIconUndiscovered() || propertyId == CMFPropertyIconCompleted() ||
		(propertyId >= 31 && propertyId <= 36) || propertyId == 39 || propertyId == 42 || propertyId == 43 ||
		propertyId == 44 || propertyId == 45 || propertyId == 46 || propertyId == 47 || propertyId == 48;
}

// Version 11: one pin by place, for a pin with no tag (pins a mod pushes with plain numbers) or with a tag nobody knows:
// the pin of pinType (a pin a mod pushes: its own type; a game pin: its own type or its legend name) within CMFPlaceRadius metres of the world position x, y. Takes
// what CMFRegisterForTag takes and sits between them: a tag claim beats it on that pin, and it beats a type claim.
// It covers every map context. Calling again with the same type and position replaces the provider's claim.
function CMFRegisterForPlace(provider : string, propertyId : int, pinType : name, x : float, y : float, text : string,
	number : int) : bool
{
	var claim : SCMFClaim;
	var effectiveId : int;
	effectiveId = propertyId;
	if (propertyId == 40) { effectiveId = number; }
	theGame.CMFGetCore().NoteProviderPresent(provider);
	if (!CMFOnePinProperty(effectiveId))
	{
		CMFLog("rejected provider=" + provider + " property=" + propertyId + " reason=level");
		return false;
	}
	claim.provider = provider;
	claim.propertyId = propertyId;
	claim.level = CMFLevelPlace();
	claim.pinType = pinType;
	claim.placeX = x;
	claim.placeY = y;
	claim.text = text;
	claim.number = number;
	if (propertyId == CMFPropertyDisabled() && number != 0)
	{
		claim.number = 1;
	}
	return theGame.CMFGetCore().Upsert(claim);
}

// Version 11: turns the pin list log on (or off) for this game session, as [CMFSettings] CMFLogPins=true does, for an
// author's own test pack. Never ship it switched on.
function CMFSetLogPins(on : bool)
{
	theGame.CMFGetCore().SetLogPins(on);
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
		theGame.CMFGetCore().NoteProviderPresent(provider);
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
		theGame.CMFGetCore().NoteProviderPresent(provider);
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
	// Version 12: asking counts as talking to CMF, so a provider that stops here because this CMF is older is present.
	theGame.CMFGetCore().NoteProviderPresent(provider);
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

// Version 8: the name CMF's in-game menu shows for a provider (for example a tidy display name); without it the menu
// shows the folder name tidied (CMFTidyName). Call it once, where the provider registers its claims.
function CMFSetProviderName(provider : string, displayName : string) : bool
{
	theGame.CMFGetCore().NoteProviderPresent(provider);
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
	// Revision 13 item styles use kind 5 in a separate collection and payload.
	var item : string;
	var itemKind : string;
	// Map-space drawing: a list key's values (kind 4, CMFDrawSetList).
	var values : array<float>;
	// Version 14 (grid): a grid drawing's bits as index, word pairs (kind 6, CMFDrawSetBits).
	var ints : array<int>;
}

// The map's parts (Stage 6b design 3.2, plus markerPanel and worldHint). pinLabel is a label above a pin
// (level tags and CMF label texts there); pinName is a name below a fast-travel pin; pinButton (version 6) is
// the button beside a pin whose click claims "button" (style keys only, no drawings). mapSpace (version 6) is
// the map itself in world coordinates: an anchor for line, text and movie drawings only (no style keys). wide (version
// 10) is how the map fills a screen that is not 16:9 (style keys only, won key by key).
function CMFThemeParts() : string
{
	return "screen,map,mapEdge,title,tracker,legend,legendRow,legendTab,tooltip,preview,worldButton,worldHint,hints," +
		"keyCap,pinLabel,pinName,navigation,markerPanel,pinButton,mapSpace,opening,spread,wide,pin,sounds,world,crosshair,edgePointer";
}

function CMFThemeLayers() : string
{
	return "under,over,belowMap,aboveMap,top";
}

function CMFThemeKinds() : string
{
	return "rect,ring,ellipse,polygon,band,line,text,movie,image,grid";
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
	if (kind == 'grid')
	{
		return "bits";
	}
	return "";
}

function CMFThemeGlowKeys() : string
{
	return "glow1Color,glow1Alpha,glow1Blur,glow1Strength,glow2Color,glow2Alpha,glow2Blur,glow2Strength,glow3Color,glow3Alpha,glow3Blur,glow3Strength";
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
	return "zoomTimed,padHoldMs,tweenEveryFrame,frameRate,zoomOutFit,edgeOvershoot,zoomIn,zoomOut,zoomStep";
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

// Smooth map movement (P6): how the map opens and closes. Version 10 adds readyAtFadeStart (1: the map takes input
// and shows its panels when its fade-in starts, not when it ends) and revealEase (1: the panels' reveal eases in).
function CMFThemeOpeningKeys() : string
{
	return "slideSeconds,slideOffset,closeSeconds,pinsDuringSlide,pinStepMs,pinBatch,pinBudgetMs,pinBudgetAfterSlideMs,showDelayMs," +
		"fadeSeconds,tileFadeSeconds,revealSeconds,readyAtFadeStart,revealEase,revealLegendSeconds,revealTrackerSeconds,revealCrosshairSeconds,waitForMap";
}

// Version 10: the map on a screen that is not 16:9. fill 1 fills the screen (the default with no provider), 0 keeps
// the 16:9 map with dark sides; panels (0 to 1) is how far the side and bottom panels move to the screen's edges;
// maxRatio (0, or 1.78 to 4) caps the shape the map fills; world 1 scales the world overview to the screen's width.
function CMFThemeWideKeys() : string
{
	return "fill,panels,maxRatio,world,panelsLegend,panelsTracker,panelsPreview";
}

// Version 10: the range of a wide key.
function CMFThemeWideValueOk(key : name, number : float) : bool
{
	switch (key)
	{
		case 'fill':
		case 'world':
			return number == 0 || number == 1;
		case 'panels':
		case 'panelsLegend':
		case 'panelsTracker':
		case 'panelsPreview':
			return number >= 0 && number <= 1;
		case 'maxRatio':
			return number == 0 || (number >= 1.78 && number <= 4);
	}
	return false;
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
		case 'waitForMap':
		case 'readyAtFadeStart':
		case 'revealEase':
			return number == 0 || number == 1;
		case 'stepMs':
		case 'worldStepMs':
		case 'maxStepMs':
		case 'pinStepMs':
			return number >= 1 && number <= 1000;
		case 'padHoldMs':
		case 'pinBudgetMs':
		case 'pinBudgetAfterSlideMs':
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
		case 'world':
			return "crestX,crestY,nameX,nameY,text,font,size,color,outlineColor,outlineAlpha,hide";
		case 'sounds':
			return "open,close,select,zoom,tab,click,travel";
		case 'pin':
			return "highlightColor,highlightAlpha,glowColor,glowAlpha,disabledAlpha,disabledGrey,pulse,hide";
		case 'map':
			// Version 14: frame, frameTop and frameBottom place the movie's edge frame (Full-screen maps).
			return "top,bottom,panLimit,centerInLimit,backdrop,frame,frameTop,frameBottom";
		case 'mapEdge':
			return "hide";
		case 'title':
			return CMFThemeTextKeys() + ",x,y,screenX,screenY,wrap,hide,text,show";
		case 'tracker':
			// Version 15: show (always, nokeys or never) is the panel's visibility, apart from its look (Panel visibility).
			return CMFThemeGlowKeys() + ",nameFont,nameSize,nameColor,hide,x,y,scale,show";
		case 'legend':
			return CMFThemeGlowKeys() + ",allText,x,y,scale,show,autoHideMs,padShowFirst";
		case 'legendRow':
			return CMFThemeGlowKeys() + ",color,colorSelected,colorOff,counterColor,hide,font,size";
		case 'legendTab':
			return CMFThemeGlowKeys() + ",color,spacing,hide,font,size";
		case 'tooltip':
			// Version 7: clear* moves a tall info box clear of the cursor and the other panels. Version 11: x and y move
			// the box from the game's place by px, and clearCursorAbove and the keys after it widen the area kept clear
			// and the places tried. Version 12: tallMinHeight and the tall* places put a taller box beside the panels (the
			// layout a map file may give its scrolling box), apart from the box height (property 14).
			return CMFThemeGlowKeys() + ",titleFont,titleSize,titleColor,bodyFont,bodySize,bodyColor,hide," +
				"clearMinHeight,clearView,clearSide,clearCursor,clearLeft,clearTop,clearRight,clearBottom,x,y," +
				"clearCursorAbove,clearCursorBelow,clearCursorTitle,clearPadX,clearPadY,clearGap,clearBoxPad,clearPick,clearCursorWeight," +
				"tallMinHeight,tallX,tallTop,tallBottom,tallAltX,tallAltTop,tallAltBottom,tallUnderLegend,tallClear,showSeconds,hideSeconds,slide," +
				"plateColor,plateAlpha,thumbColor,trackColor,scrollStep,titleCase,hideScrollBar," +
				"foldTag,foldMoreText,foldLessText,foldKeyPad,foldKeyKb,foldOpen,clearAnchor,stretch,stretchMax,stretchDirs,stretchFlip," +
				"titleGlow1Color,titleGlow1Alpha,titleGlow1Blur,titleGlow1Strength,titleGlow2Color,titleGlow2Alpha,titleGlow2Blur,titleGlow2Strength," +
				"bodyGlow1Color,bodyGlow1Alpha,bodyGlow1Blur,bodyGlow1Strength,bodyGlow2Color,bodyGlow2Alpha,bodyGlow2Blur,bodyGlow2Strength";
		case 'preview':
			return "hide,x,y,scale,show,movingMs";
		case 'worldButton':
			return CMFThemeGlowKeys() + ",hide,text,x,y,scale,font,size,show";
		case 'worldHint':
			return CMFThemeGlowKeys() + ",hide,text,x,y,scale,font,size,show";
		case 'hints':
			return CMFThemeGlowKeys() + ",x,y,scale,align,list,font,size";
		case 'keyCap':
			return CMFThemeGlowKeys() + ",color,iconColor,brackets,keyGap,labelGap,hide,font,size";
		case 'pinLabel':
			return "font,size,color,rise,riseTracked,riseOffset,riseOffsetTracked," + CMFThemeShadowKeys();
		case 'pinName':
			return "font,size,color," + CMFThemeShadowKeys();
		case 'pinButton':
			return "width,height,curve,fill,alpha,stroke,strokeWidth,offsetX,offsetY," + CMFThemeTextKeys();
		case 'crosshair':
		case 'edgePointer':
			return CMFThemeGlowKeys() + ",color,alpha,scale,hide,show";
		case 'navigation':
			return "frameTimed,stepMs,worldStepMs,maxStepMs,crosshairRoam,safeLeft,safeTop,safeRight,safeBottom," +
				"snapSeconds,centerSeconds," + CMFThemeNavigationKeys();
		case 'markerPanel':
			return "minLeft,maxRight,minTop,maxBottom";
		case 'opening':
			return CMFThemeOpeningKeys();
		case 'spread':
			return CMFThemeSpreadKeys();
		case 'wide':
			return CMFThemeWideKeys();
	}
	return "";
}

// The game decorations a part's "hide" key may name.
function CMFThemeHideWords(part : name) : string
{
	switch (part)
	{
		case 'crosshair':
			return "all,label";
		case 'edgePointer':
			return "all";
		case 'world':
			return "outline,names";
		case 'pin':
			return "highlight,glow,pulse";
		case 'mapEdge':
			return "edgeFade";
		case 'tracker':
			return "plate,questPlate";
		case 'title':
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
// hover keys to the box kinds, and the map-space kinds: line on mapSpace only and movie on any drawable part, text on mapSpace (placed
// at x, y metres) or on any part or drawing; line, text and movie also take listen and listenFields. A movie
// also takes any key its author documents for the movie. Version 7 adds minPartHeight to the box kinds and text:
// the drawing shows only while its part's box is at least that many pixels tall. Version 10 adds wideAnchor to the box
// kinds and text: on a wide or tall screen the drawing's screen numbers move with the screen's edges ("edges"), with
// its part's panel ("panels") or stay in the 16:9 middle ("centre"); unset, CMF picks by what the drawing is tied to.
function CMFThemeShapeKeys(kind : name) : string
{
	var keys : string;
	var space : string;
	keys = "left,top,right,bottom,width,height,widthShare,heightShare,minWidth,minHeight,alignX,alignY,offsetX,offsetY," +
		"minLeft,maxRight,minTop,maxBottom,screenLeft,screenRight,screenTop,screenBottom,measure,fill,alpha,fill2,alpha2," +
		"gradient,angle,curve,stroke,strokeAlpha,strokeWidth,layer,order,view,when,repeat,repeatStep,alphaList," +
		CMFThemeGlowKeys() + "," + CMFThemeShadowKeys() + ",tab,tabLabel,click,above," + CMFThemeHoverKeys() + ",minPartHeight,wideAnchor,pinType,pinTag,withLook";
	space = "layer,order,alpha,view,area,preview,fadeMs,tab,tabLabel,listen,listenFields,withLook";
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
		case 'image':
			return keys + ",src,fit,smooth,x,y,sizeZoom,area,fadeMs";
		case 'text':
			return keys + ",text,font,size,color,align,wrap,padding,x,y,sizeZoom,area,fadeMs,listen,listenFields";
		case 'line':
			return space + ",stroke,strokeAlpha,strokeWidth,strokeZoom";
		case 'movie':
			return keys + ",area,preview,fadeMs,listen,listenFields,src,focus";
		case 'grid':
			// Version 14: a mask over a square of the map in cells, mapSpace only, its bits by CMFDrawSetBits.
			return "layer,order,alpha,view,area,fadeMs,withLook,n,left,top,span,fill,soft,steps,hidePins";
	}
	return "";
}

// Every key some drawing kind takes (CMFDrawSet checks the kind when the map opens).
function CMFThemeAllShapeKeys() : string
{
	return CMFThemeShapeKeys('polygon') + ",inset,side,size,sizeZoom,minSize,maxShare," + CMFThemeShapeKeys('text') + "," +
		CMFThemeShapeKeys('line') + "," + CMFThemeShapeKeys('movie') + "," + CMFThemeShapeKeys('image') + "," +
		CMFThemeShapeKeys('grid');
}

// Keys whose value is the text argument; every other key takes the number argument.
function CMFThemeTextKey(key : name) : bool
{
	return CMFListHas("font,nameFont,titleFont,bodyFont,align,wrap,panLimit,frame,hide,layer,when,gradient,side,measure,view," +
		"points,alphaList,area,src,tab,tabLabel,text,allText,listen,listenFields,clearView,clearSide,wideAnchor,fit,pinType,pinTag,titleCase,show," +
		"foldTag,foldMoreText,foldLessText,foldKeyPad,foldKeyKb,clearAnchor,stretchDirs", NameToString(key));
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
	var i : int;
	k = NameToString(key);
	if (part == 'tooltip' && key == 'foldOpen') { return number == 0 || number == 1; }
	if (part == 'tooltip' && key == 'clearAnchor') { return text == "cursor" || text == "pin"; }
	if (part == 'tooltip' && key == 'stretchDirs') { return CMFThemeWordsOk(text, "left,right,up,down"); }
	if (part == 'tooltip' && key == 'foldTag')
	{
		// Match the panel marker scanner's attribute-name grammar; empty disables folding.
		for (i = 0; i < StrLen(text); i += 1)
		{
			if (StrFindFirst("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-:", StrMid(text, i, 1)) < 0) { return false; }
		}
		return true;
	}
	if (part == 'tooltip' && (key == 'foldMoreText' || key == 'foldLessText' || key == 'foldKeyPad' || key == 'foldKeyKb'))
	{
		// Prompts may be literal HTML or [[key]]; empty removes a prompt or native input binding.
		return true;
	}
	if (part == 'map' && key == 'frame') { return text == "area" || text == "hide"; }
	if (part == 'map' && (key == 'frameTop' || key == 'frameBottom')) { return number >= 0 && number <= 1; }
	if (part == 'legend' && key == 'show') { return text == "always" || text == "auto"; }
	if (part == 'preview' && key == 'show') { return text == "always" || text == "moving" || text == "never"; }
	if (part == 'tracker' && key == 'show') { return text == "always" || text == "nokeys" || text == "never"; }
	if ((part == 'title' || part == 'worldButton' || part == 'worldHint' || part == 'crosshair' || part == 'edgePointer') &&
		key == 'show')
	{
		return text == "always" || text == "never";
	}
	if (key == 'autoHideMs' || key == 'movingMs') { return number >= 0 && number <= 600000; }
	if (key == 'padShowFirst') { return number == 0 || number == 1; }
	if (part == 'tooltip' && key == 'titleCase') { return text == "upper" || text == "keep"; }
	if (part == 'tooltip' && key == 'hideScrollBar') { return number == 0 || number == 1; }
	if (part == 'tooltip' && key == 'scrollStep') { return number >= 1 && number <= 1000 && number == (int)number; }
	if (part == 'navigation' && key == 'zoomStep') { return number >= 1.01 && number <= 2; }
	if (part == 'navigation' && (key == 'zoomIn' || key == 'zoomOut')) { return number > 0 && number <= 100000; }
	if (part == 'world' && key == 'text') { return true; }
	if (part == 'tooltip' && (key == 'showSeconds' || key == 'hideSeconds')) { return number >= 0 && number <= 30; }
	if (part == 'sounds') { return CMFThemeWordOk(text); }
	if (key == 'fit') { return text == "stretch" || text == "contain" || text == "cover" || text == "tile"; }
	if (key == 'focus' || key == 'withLook') { return number == 0 || number == 1; }
	if (key == 'smooth') { return number == 0 || number == 1; }
	if (key == 'pinType' || key == 'pinTag') { return true; }
	if (part == 'pin' && key == 'disabledGrey') { return number >= 0 && number <= 1; }
	if (part == 'pin' && key == 'pulse') { return number == 0 || number == 1; }
	if (part == 'hints' && key == 'list') { return text == "" && number == 1; }
	if ((part == 'title' || part == 'worldHint' || part == 'worldButton') && key == 'text') { return true; }
	if (part == 'legend' && key == 'allText') { return true; }
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
			case 'wideAnchor':
				return text == "edges" || text == "panels" || text == "centre";
			case 'area':
			case 'tab':
				return CMFThemeWordOk(text);
			case 'listen':
				// A flash storage key the drawing's own mod writes on the map menu; never CMF's or the game's map keys.
				return CMFThemeWordOk(text) && !StrBeginsWith(text, "cmf.") && !StrBeginsWith(text, "map.") &&
					!StrBeginsWith(text, "worldmap.global.") && !StrBeginsWith(text, "worldmap.title.");
			case 'src':
				// The author's own movie, by game path: swf/<folder>/<name>.swf.
				return ((StrBeginsWith(text, "swf/") && StrEndsWith(text, ".swf")) ||
					(StrBeginsWith(text, "img://") && StrLen(text) > 6)) && CMFThemeWordOk(text) &&
					StrReplaceAll(text, "..", "") == text && StrReplaceAll(text, "\\", "") == text;
		}
		return text != "";
	}
	// Version 10: wide's fill is a switch, not a colour.
	if (part == 'wide')
	{
		return CMFThemeWideValueOk(key, number);
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
	if (k == "clearCursorTitle" || k == "clearPick")
	{
		return number == 0 || number == 1;
	}
	if (k == "stretch" || k == "stretchFlip")
	{
		return number == 0 || number == 1;
	}
	if (k == "stretchMax")
	{
		return number >= 0 && number <= 4000;
	}
	if (k == "tallUnderLegend" || k == "tallClear")
	{
		return number == 0 || number == 1;
	}
	if (k == "tallMinHeight" || k == "tallX" || k == "tallTop" || k == "tallBottom" || k == "tallAltX" || k == "tallAltTop" ||
		k == "tallAltBottom")
	{
		return number >= 0 && number <= 4000;
	}
	if (k == "clearCursorAbove" || k == "clearCursorBelow" || k == "clearPadX" || k == "clearPadY" || k == "clearGap" ||
		k == "clearBoxPad" || k == "clearCursorWeight")
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
// and the other clear keys, and ('rect', 'minPartHeight') on every box kind and text. Version 10 adds ('wide', '') and its
// keys, ('rect', 'wideAnchor') on every box kind and text, and ('opening', 'readyAtFadeStart') and ('opening',
// 'revealEase'). Version 11 adds ('tooltip', 'x') and ('tooltip', 'y'), and ('tooltip', 'clearCursorAbove') and the
// other new clear keys (clearCursorBelow, clearCursorTitle, clearPadX, clearPadY, clearGap, clearBoxPad, clearPick,
// clearCursorWeight). Version 12 adds ('tooltip', 'tallMinHeight') and the other tall keys (tallX, tallTop, tallBottom,
// tallAltX, tallAltTop, tallAltBottom, tallUnderLegend, tallClear). Version 17 adds ('screen', 'button'): a screen
// movie's map.cmfMakeButton(navCode, keyCode, label) gives it one of the game's key buttons, and ('map', 'refreshPins')
// says CMFMapRefreshPins() exists (it rebuilds the open map's pins), and ('screen', 'keyDecline') says a focused screen
// movie's handleInput can return false to decline a key. Version 18 adds ('tooltip', 'stretch') and stretchMax,
// stretchDirs and stretchFlip: a box moved clear goes to the nearest clear spot to its first place. Abilities designed for later
// (images, the map hold) answer false until a CMF version adds them.
function CMFHasAbility(part : name, key : name) : bool
{
	var p : string;
	p = NameToString(part);
	if (part == 'map' && key == 'rootValues') { return true; }
	if (part == 'screen' && key == 'button') { return true; }
	if (part == 'map' && key == 'refreshPins') { return true; }
	if (part == 'grid' && key == 'keepRevoke') { return true; }
	if (part == 'pins' && key == 'addedList') { return true; }
	if (part == 'map' && key == 'partialUpdate') { return true; }
	if (part == 'screen' && key == 'keyDecline') { return true; }
	if (part == 'claims')
	{
		return CMFListHas("tagTint,placeClaims,playerArt,levelVariants,vanillaRows,everyPinIcon,withdraw,labelHideMerge,everyPin,iconFrames,iconPrograms,pictureFit",
			NameToString(key));
	}
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

// Version 10. The visible screen in map units from the last map opening: 1920 x 1080 on a 16:9 screen, 2580 x 1080 on
// a 3440 x 1440 one, 1920 x 1200 on a 16:10 one; 0 before the first opening. For mods that want the screen's shape (for
// example to send wide keys only on very wide screens); no pack needs it for a correct layout, because CMF moves
// numbers sent in 1920 x 1080 units by itself.
function CMFScreenWidth() : float
{
	return theGame.CMFGetCore().ScreenWidth();
}

function CMFScreenHeight() : float
{
	return theGame.CMFGetCore().ScreenHeight();
}

// Version 5. Styles one part of the map (fonts, colours, glows, place, the game decorations to hide) or sets
// one map behaviour (parts map, navigation, opening, spread and, version 10, wide). text carries words (fonts such as "$TitleFont",
// "keep", "region,world", decoration names); number carries everything else, colours as 0xRRGGBB. The earliest
// folder that styles a part owns all of its style keys; map, navigation, opening, spread and wide are won key by key.
// Version 10: on a look part, a key that is a behaviour (the info box's clear keys, the label's rise keys) is owned
// apart from the look (CMFCore.PartKeyChoice).
// Unset keys keep the game's look.
// Revision 13: session-only content. A pin added while the map is open shows at the next opening.
function CMFAddPin(provider : string, tag : name, pinType : name, area : name, x : float, y : float,
	label : string, description : string) : bool
{
	var pin : SCMFAddedPin;
	theGame.CMFGetCore().NoteProviderPresent(provider);
	pin.provider = provider;
	pin.tag = tag;
	pin.pinType = pinType;
	pin.area = area;
	pin.x = x;
	pin.y = y;
	pin.label = label;
	pin.description = description;
	return theGame.CMFGetCore().UpsertAddedPin(pin);
}

function CMFRemovePin(provider : string, tag : name) : bool
{
	theGame.CMFGetCore().NoteProviderPresent(provider);
	return theGame.CMFGetCore().RemoveAddedPin(provider, tag);
}

// Revision 13: per-item overrides. An empty target is exactly CMFStylePart.
function CMFStyle(provider : string, part : name, target : name, key : name, text : string, number : float) : bool
{
	var styleEntry : SCMFThemeEntry;
	if (!IsNameValid(target)) { return CMFStylePart(provider, part, key, text, number); }
	theGame.CMFGetCore().NoteProviderPresent(provider);
	if (provider == "" || !CMFHasAbility(part, key) ||
		!theGame.CMFGetCore().ItemTarget(part, key, NameToString(target), styleEntry.item, styleEntry.itemKind) ||
		(text != "unset" && !CMFThemeValueOk(part, key, text, number)))
	{
		CMFLog("theme item rejected provider=" + provider + " part=" + NameToString(part) + " target=" +
			NameToString(target) + " key=" + NameToString(key));
		return false;
	}
	styleEntry.provider = provider;
	styleEntry.kind = 5;
	styleEntry.target = part;
	styleEntry.key = key;
	styleEntry.text = text;
	styleEntry.number = number;
	return theGame.CMFGetCore().UpsertItemStyle(styleEntry);
}

function CMFStylePart(provider : string, part : name, key : name, text : string, number : float) : bool
{
	var themeEntry : SCMFThemeEntry;
	theGame.CMFGetCore().NoteProviderPresent(provider);
	if (provider == "" || !CMFListHas(CMFThemeParts(), NameToString(part)) || !CMFHasAbility(part, key))
	{
		CMFLog("theme rejected provider=" + provider + " part=" + NameToString(part) + " key=" + NameToString(key) +
			" reason=unknown");
		return false;
	}
	// Smooth map movement (P6): the text "unset" withdraws this provider's own value for this key; it is never a value.
	// Version 12: logged only when a value was there to withdraw.
	if (text == "unset")
	{
		if (theGame.CMFGetCore().UnsetTheme(provider, part, key) > 0)
		{
			CMFLog("theme unset provider=" + provider + " part=" + NameToString(part) + " key=" + NameToString(key));
		}
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
// anchor mapSpace takes line, text, movie and image drawings; line takes only mapSpace.
function CMFDraw(provider : string, anchor : name, id : name, kind : name) : bool
{
	var themeEntry : SCMFThemeEntry;
	theGame.CMFGetCore().NoteProviderPresent(provider);
	if (provider == "" || !IsNameValid(anchor) || !IsNameValid(id) || anchor == id ||
		CMFListHas(CMFThemeParts() + "," + CMFThemeLayers() + "," + CMFThemeKinds(), NameToString(id)) ||
		(IsNameValid(kind) && !CMFListHas(CMFThemeKinds(), NameToString(kind))) ||
		CMFListHas(CMFThemeLayers() + "," + CMFThemeKinds() + ",navigation,opening,spread,wide,sounds,world", NameToString(anchor)) ||
		(anchor == 'mapSpace' && IsNameValid(kind) && kind != 'line' && kind != 'text' && kind != 'movie' && kind != 'image' &&
		kind != 'grid') ||
		(anchor != 'mapSpace' && (kind == 'line' || kind == 'grid')))
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
	var kind : name;
	theGame.CMFGetCore().NoteProviderPresent(provider);
	kind = theGame.CMFGetCore().DrawingKind(provider, id);
	// A movie's own keys remain opaque even if a different drawing kind gains a key with that spelling.
	own = kind == 'movie' && !CMFListHas(CMFThemeShapeKeys('movie'), NameToString(key));
	if (provider == "" || !IsNameValid(id) || !IsNameValid(key) || (!own && !CMFListHas(CMFThemeAllShapeKeys(), NameToString(key))))
	{
		CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=" + NameToString(key) +
			" reason=unknown");
		return false;
	}
	if ((!own && !CMFThemeValueOk('', key, text, number)) || (kind == 'grid' && !CMFThemeGridValueOk(key, number)) ||
		(key == 'src' && ((kind == 'image' && !StrBeginsWith(text, "img://")) ||
		(kind == 'movie' && !StrBeginsWith(text, "swf/")))))
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
	theGame.CMFGetCore().NoteProviderPresent(provider);
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

// Version 14 (grid). The grid keys' ranges: n (cells per side) 1 to 2048, span (the square's side in world metres)
// above 0, soft (edge width in cells) 0 to 32, steps (edge bands) 1 to 16.
function CMFThemeGridValueOk(key : name, number : float) : bool
{
	switch (key)
	{
		case 'n':
			return number >= 1 && number <= 2048 && number == (int)number;
		case 'span':
			return number > 0 && number <= 100000;
		case 'soft':
			return number >= 0 && number <= 32;
		case 'steps':
			return number >= 1 && number <= 16 && number == (int)number;
		case 'hidePins':
			return number == 0 || number == 1;
	}
	return true;
}

// Version 14 (grid), API 18 rules. Keeps one pin out of the hidePins rule of every grid drawing in this map build: the
// provider's own filter already decided to show it (a fog mod's tracked quest, known signposts and so on). Any
// provider's valid keep exempts the pin from every grid. Each provider revokes only its own keeps: one pin with
// CMFGridUnkeepPin, or all of them at once by sending a new epoch with CMFRegister(provider, 49, '', '', "", epoch)
// (CMFHasAbility('grid', 'keepRevoke')). Call it from a pin wrapper before CMF's late pass; false without a pin or
// provider, or for a provider name holding ; or =. The pin's bool member cmfGridKeep is true while a keep stands (CMF's
// late pass rewrites it false when every keep is revoked); never write it.
function CMFGridKeepPin(provider : string, dataObject : CScriptedFlashObject) : bool
{
	return theGame.CMFGetCore().GridKeepAdd(provider, dataObject);
}

// Version 18. Withdraws this provider's keep on one pin; other providers' keeps stay. True also when there was nothing
// to withdraw; false without a pin or provider.
function CMFGridUnkeepPin(provider : string, dataObject : CScriptedFlashObject) : bool
{
	return theGame.CMFGetCore().GridKeepRemove(provider, dataObject);
}

// Version 18 (additive). The mods that add pins of their own to the map, by provider (the mod's folder, as on the Status
// page), and "" last when some added pin type has no owner. Filled in CMF's late pass from the full map builds of this
// game session; nothing is saved. Returns the count. CMFHasAbility('pins', 'addedList') says the calls exist.
function CMFAddedPinMods(out mods : array<string>) : int
{
	return theGame.CMFGetCore().AddedPinMods(mods);
}

// Version 18. That mod's added pin types with their legend row and how many were on the map in the last full build
// ("" asks for the types no mod owns). The three arrays are parallel. Returns the count.
function CMFAddedPinTypes(mod : string, out types : array<string>, out rows : array<string>, out counts : array<int>) : int
{
	return theGame.CMFGetCore().AddedPinTypesOf(mod, types, rows, counts);
}

// Version 18. A mod names a pin type as its own, for a type that uses a name the game also uses, or before the first map
// build. False for an empty provider or an invalid type. filteredType is the legend row when the pins send none.
function CMFDeclareAddedPinType(provider : string, pinType : name, filteredType : name) : bool
{
	return theGame.CMFGetCore().DeclareAddedPinType(provider, pinType, filteredType);
}

// Version 14 (grid). The cells a grid drawing leaves clear, as index and word pairs: bit b (0 to 29) of word k is
// cell k * 30 + b, counted row by row from the grid's north-west corner; send only words with a set bit. Exact
// ints, unlike CMFDrawSetList's floats. Needs CMFDraw(provider, 'mapSpace', id, 'grid') first; empty arrays
// withdraw the bits. At most 100000 words; each word 0 to 2^30 - 1.
function CMFDrawSetBits(provider : string, id : name, idx : array<int>, words : array<int>) : bool
{
	var themeEntry : SCMFThemeEntry;
	var i : int;
	theGame.CMFGetCore().NoteProviderPresent(provider);
	if (provider == "" || !IsNameValid(id) || idx.Size() != words.Size() || idx.Size() > 100000 ||
		theGame.CMFGetCore().DrawingKind(provider, id) != 'grid')
	{
		CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=bits reason=unknown");
		return false;
	}
	for (i = 0; i < idx.Size(); i += 1)
	{
		if (idx[i] < 0 || words[i] < 0 || words[i] > 1073741823)
		{
			CMFLog("theme rejected provider=" + provider + " id=" + NameToString(id) + " key=bits reason=value");
			return false;
		}
		themeEntry.ints.PushBack(idx[i]);
		themeEntry.ints.PushBack(words[i]);
	}
	themeEntry.provider = provider;
	themeEntry.kind = 6;
	themeEntry.target = id;
	themeEntry.key = 'bits';
	return theGame.CMFGetCore().UpsertTheme(themeEntry);
}

// Version 6 (map-space drawing). For a mod whose drawings change while the map stays open: runs OnMapReady
// again and re-sends the theme and the map-space drawings to the open map. API 18: false, and nothing done, during a
// build (for example from OnPinReady or OnMapReady) and when no map is open.
function CMFMapRefresh() : bool
{
	return theGame.CMFGetCore().RefreshMap();
}

// Version 17 (additive, same API 17). For a mod whose pin settings change while the map stays open (a filter that
// hides some markers): runs the game's full pin build again on the open map. API 18: false, and nothing done, during a
// build (for example from OnPinReady or OnMapReady) and when no map is open; ask again after the build.
// CMFHasAbility('map', 'refreshPins') says the function exists.
function CMFMapRefreshPins() : bool
{
	return theGame.CMFGetCore().RefreshPins();
}

// Any in-game option changing (Fog of War's own switch included) drops the grids kept for the early send, so turning a
// drawing Off never shows the old one for a frame.
@wrapMethod(CR4Game)
function OnConfigValueChanged(varName : name, value : string) : void
{
	wrappedMethod(varName, value);
	theGame.CMFGetCore().DropEarlySpace();
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
	theGame.CMFGetCore().SendCover(GetMenuFlash(), m_shownArea, "picture");
	return theGame.CMFGetCore().MapImageRoot(m_shownArea, vanillaRoot);
}

@wrapMethod(CR4MapMenu)
function UpdateUserMapPins(out flashArray : CScriptedFlashArray, indexToUpdate : int) : void
{
	wrappedMethod(flashArray, indexToUpdate);
	if (indexToUpdate < 0)
	{
		theGame.CMFGetCore().NoteLateStep();
		CMFStamp("late");
		theGame.CMFGetCore().CheckEntityStep();
		theGame.CMFGetCore().AppendAddedPins(this, flashArray, m_shownArea);
	}
	theGame.CMFGetCore().FillMissingPinFields(flashArray, CMFMapContext(), indexToUpdate, m_shownArea);
	if (indexToUpdate < 0)
	{
		if (flashArray)
		{
			CMFStamp("lateEnd:" + flashArray.GetLength());
		}
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
	var debugOn : bool;
	cmfMovieBuild += 1;
	theGame.CMFGetCore().BuildBusy(true);
	CMFStamp("data");
	theGame.CMFGetCore().SendCover(GetMenuFlash(), m_shownArea, "data");
	theGame.CMFGetCore().SendSpaceEarly(GetMenuFlashValueStorage(), m_shownArea, this);
	theGame.CMFGetCore().BeginBuild(m_shownArea);
	wrappedMethod(ignoreSelectionChange);
	theGame.CMFGetCore().EndBuild();
	theGame.CMFGetCore().CheckLateStep();
	CMFStamp("sent");
	debugOn = CMFSettingsDebug();
	flashArray = theGame.CMFGetCore().CatchLatePins(CMFMapContext(), m_shownArea);
	if (flashArray)
	{
		CMFStamp("caught");
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
		if (debugOn)
		{
			CMFLog("late send n=" + flashArray.GetLength());
		}
	}
	CMFMovieBuildSent();
	theGame.CMFGetCore().ReportPinAsks();
	theGame.CMFGetCore().ReportTiming();
	theGame.CMFGetCore().ClearLabelHideState();
	CMFStamp("end");
	theGame.CMFGetCore().BuildBusy(false);
}

// API 17: the full pin build again on the open map (CMFMapRefreshPins); CMF's UpdateData wrapper re-sends covers and space.
@addMethod(CR4MapMenu)
function CMFRefreshPins()
{
	UpdateData(true);
}

// Map-space drawing: sends the map-space drawings for the shown area; refresh (CMFMapRefresh) first runs
// OnMapReady again and re-sends the theme.
@addMethod(CR4MapMenu)
function CMFMapSpaceSend(refresh : bool)
{
	if (refresh)
	{
		theGame.CMFGetCore().BuildBusy(true);
		theGame.CMFGetCore().MapReady(GetMenuFlash());
		theGame.CMFGetCore().SendTheme(GetMenuFlashValueStorage());
	}
	theGame.CMFGetCore().SendSpaceMode(GetMenuFlashValueStorage(), m_shownArea, this, refresh, false);
	if (refresh)
	{
		theGame.CMFGetCore().BuildBusy(false);
	}
}

// Version 11: a step of the pin build, timed by the map panel (MapMenu.cmfStamp) for the log line "build ...".
@addMethod(CR4MapMenu)
function CMFStamp(step : string)
{
	var menuFlash : CScriptedFlashSprite;
	var stamp : CScriptedFlashFunction;
	menuFlash = GetMenuFlash();
	if (!menuFlash)
	{
		return;
	}
	stamp = menuFlash.GetMemberFlashFunction("cmfStamp");
	if (stamp)
	{
		stamp.InvokeSelfOneArg(FlashArgString(step));
	}
}

// Opens the pin list for per-pin hides; the late pass closes it. CMF's UpdateData wrapper opens it too, for when
// another mod's precompiled UpdateEntityPins skips this wrapper.
@wrapMethod(CR4MapMenu)
function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void
{
	theGame.CMFGetCore().NoteEntityStep();
	theGame.CMFGetCore().OpenPinList();
	theGame.CMFGetCore().NoteListArea(m_shownArea);
	wrappedMethod(flashArray);
}

@wrapMethod(CR4MapMenu)
function AddPinTypeData(out dataObject : CScriptedFlashObject, targetPin : SCommonMapPinInstance) : void
{
	wrappedMethod(dataObject, targetPin);
	theGame.CMFGetCore().NoteFieldsStep();
	theGame.CMFGetCore().WritePinFields(dataObject, targetPin.visibleType, targetPin.tag, CMFMapContext(), targetPin.type);
}

// The map panel reports how it measured the legend each time that box changes (launch T1 diagnosis).
@addMethod(CR4MapMenu)
event OnCMFPanelNote(note : string)
{
	if ((StrBeginsWith(note, "movie serials") || StrBeginsWith(note, "info box stretch")) && !CMFSettingsDebug())
	{
		return false;
	}
	CMFLog("panel " + note);
}

// The map panel saw a mod call its own function in the map file (a presence listener, see edits.json): that mod is installed.
@addMethod(CR4MapMenu)
event OnCMFPresenceSeen(folder : string)
{
	CMFDeclareProvider(folder);
	CMFLog("presence seen folder=" + folder);
}

// API 16 (map.hidePanels, part hubBar): the common menu's top bar (level, crowns, weight, tab strip) lives in the hub
// movie, not the map movie, so the map panel asks script and script calls the hub movie's own function.
@addMethod(CR4CommonMenu)
function CMFSetHubBarVisible(value : bool)
{
	var hubFlash : CScriptedFlashSprite;
	var setBar : CScriptedFlashFunction;
	hubFlash = GetMenuFlash();
	if (!hubFlash)
	{
		return;
	}
	setBar = hubFlash.GetMemberFlashFunction("setPlayerDetailsVisible");
	if (setBar)
	{
		setBar.InvokeSelfOneArg(FlashArgBool(value));
	}
}

@addMethod(CR4MapMenu)
function CMFFindHubMenu() : CR4CommonMenu
{
	var hubMenu : CR4CommonMenu;
	hubMenu = (CR4CommonMenu)m_parentMenu;
	if (!hubMenu)
	{
		hubMenu = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	}
	return hubMenu;
}

// True while a movie has the common menu's top bar hidden; the close wrap only restores it then.
@addField(CR4MapMenu)
var cmfHubBarHidden : bool;

// The map panel hides (false) or shows (true) the common menu's top bar for a movie that asked for the hubBar part.
@addMethod(CR4MapMenu)
event OnCMFHubBar(visible : bool)
{
	var hubMenu : CR4CommonMenu;
	cmfHubBarHidden = !visible;
	hubMenu = CMFFindHubMenu();
	if (hubMenu)
	{
		hubMenu.CMFSetHubBarVisible(visible);
	}
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
	CMFMapCheckReady();
	theGame.CMFGetCore().SendScreen(GetMenuFlashValueStorage());
	theGame.CMFGetCore().SendTheme(GetMenuFlashValueStorage());
}

// API 14: registered after the animation channel listener, independently of map-space drawing readiness.
@addMethod(CR4MapMenu)
event OnCMFAnimationsReady()
{
	theGame.CMFGetCore().SendAnimationOptions(this);
}

// Version 10: the map panel reports the visible screen in map units (1920 x 1080 on a 16:9 screen) once per opening.
@addMethod(CR4MapMenu)
event OnCMFScreen(width : float, height : float)
{
	theGame.CMFGetCore().ScreenSeen(width, height);
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

// Managed hint list click, validated against the current list owner by the core.
@addMethod(CR4MapMenu)
event OnCMFHintClicked(owner : string, value : int)
{
	theGame.CMFGetCore().HintClicked(this, owner, value);
}

// Version 6 (map-space drawing): the map panel started listening to the storage keys drawings named with listen.
@addMethod(CR4MapMenu)
event OnCMFListenReady(keys : string)
{
	CMFMapCheckReady();
	theGame.CMFGetCore().ListenReady(this, keys);
}

// Version 6 (map-space drawing): the map panel registered its map-space listener.
@addMethod(CR4MapMenu)
event OnCMFMapSpaceReady()
{
	CMFMapCheckReady();
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

// Version 11: readiness belongs to one menu opening, including callbacks before OnConfigUI.
// Only the actual close resets it; a region/world overview round trip keeps the same panel.
@addField(CR4MapMenu)
var cmfMapCheckReady : bool;

@addField(CR4MapMenu)
var cmfMapCheckShown : bool;

@addMethod(CR4MapMenu)
function CMFMapCheckReady()
{
	cmfMapCheckReady = true;
}

@addMethod(CR4MapMenu)
function CMFMapCheckShown()
{
	cmfMapCheckShown = true;
}

// The inherited callback follows the menu's show animation; configuring alone is not a completed opening.
@wrapMethod(CR4MenuBase)
function OnMenuShown()
{
	var mapMenu : CR4MapMenu;
	var result : bool;
	// The game declares OnMenuShown an event (menuBase.ws), so its result is passed on.
	result = wrappedMethod();
	mapMenu = (CR4MapMenu)this;
	if (mapMenu)
	{
		mapMenu.CMFMapCheckShown();
		theGame.CMFSetOpenMap(mapMenu);
	}
	return result;
}

@addMethod(CR4MapMenu)
function CMFMapCheckClose()
{
	var warn : bool;
	CMFLog("map check close shown=" + CMFYesNo(cmfMapCheckShown) + " ready=" + CMFYesNo(cmfMapCheckReady));
	warn = cmfMapCheckShown && !cmfMapCheckReady;
	cmfMapCheckReady = false;
	cmfMapCheckShown = false;
	if (warn && CMFSettingsMapCheck())
	{
		theGame.CMFGetCore().MapCheckWarnOnce();
	}
}

// Version 11: the map check's box, once no menu, message box, black screen or scene is up.
function CMFMapCheckBusy() : bool
{
	if (theGame.GetGuiManager().GetPopup('MessagePopup'))
	{
		return true;
	}
	return !theGame.IsActive() || theGame.IsBlackscreen() || theGame.GetGuiManager().IsAnyMenu() ||
		theGame.IsDialogOrCutscenePlaying();
}

function CMFMapCheckSchedule()
{
	if (thePlayer)
	{
		thePlayer.AddTimer('CMFMapCheckLater', 0.2, false, , , false, true);
	}
}

@addMethod(CR4Player)
timer function CMFMapCheckLater(dt : float, id : int)
{
	if (CMFMapCheckBusy())
	{
		CMFMapCheckSchedule();
		return;
	}
	theGame.GetGuiManager().ShowUserDialogAdv(0, GetLocStringByKeyExt("cmf_popup_title"),
		GetLocStringByKeyExt("cmf_map_check_warning"), false, UDB_Ok);
}

// Version 9: the map is closing: the shown region reports its last view.
@wrapMethod(CR4MapMenu)
function OnClosingMenu()
{
	var result : bool;
	CMFReportView('close');
	theGame.CMFGetCore().ForgetSpaceMenu(this);
	if (cmfHubBarHidden)
	{
		OnCMFHubBar(true);
	}
	result = wrappedMethod();
	CMFMapCheckClose();
	theGame.CMFMapClosed(this);
	return result;
}

// Map blur fix (1.6.1). The map panel keeps a movement key held until it gets that key's release. A screenshot tool or
// Alt+Tab takes the release away from the game, and the game reports the switch only as an input device change, so CMF
// then tells the open map to clear its held movement keys (see cmfNavClear in edits.json).
@addField(CR4Game)
var cmfOpenMap : CR4MapMenu;

@addMethod(CR4Game)
public function CMFSetOpenMap(menu : CR4MapMenu)
{
	cmfOpenMap = menu;
}

@addMethod(CR4Game)
public function CMFMapClosed(menu : CR4MapMenu)
{
	if (cmfOpenMap == menu)
	{
		cmfOpenMap = NULL;
	}
	CMFGetCore().CloseAnimationMenu(menu);
	CMFGetCore().ForgetSpaceMenu(menu);
}

@addMethod(CR4Game)
public function CMFOpenMap() : CR4MapMenu
{
	return cmfOpenMap;
}

@addMethod(CR4MapMenu)
function CMFNavClear(reason : string)
{
	var menuFlash : CScriptedFlashSprite;
	var clear : CScriptedFlashFunction;
	menuFlash = GetMenuFlash();
	if (!menuFlash)
	{
		return;
	}
	clear = menuFlash.GetMemberFlashFunction("cmfNavClear");
	if (clear)
	{
		clear.InvokeSelfOneArg(FlashArgString(reason));
	}
}

// The game declares OnInputDeviceChanged an event (inputManager.ws), so its result is passed on.
@wrapMethod(CInputManager)
function OnInputDeviceChanged()
{
	var result : bool;
	var mapMenu : CR4MapMenu;
	result = wrappedMethod();
	if (theGame)
	{
		mapMenu = theGame.CMFOpenMap();
		if (mapMenu)
		{
			mapMenu.CMFNavClear("device");
		}
	}
	return result;
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


// Revision 13: these event names coexist with the adapter-owned legacy events.
// They remain inactive until the part 2 panel dispatches them.
@addMethod(CR4MapMenu)
event OnCMFMapTab(category : string)
{
	theGame.CMFGetCore().OnMapTab(this, category);
}

@addMethod(CR4MapMenu)
event OnCMFMapHints()
{
	theGame.CMFGetCore().MapHintsReady(this);
}


@addMethod(CR4MapMenu)
event OnCMFInfoFold(provider : string, open : bool)
{
	theGame.CMFGetCore().InfoFold(this, provider, open);
}

// Revision 13: a live movie sends a string event to its current drawing owner.
@addMethod(CR4MapMenu)
event OnCMFMovieEvent(id : string, eventName : string, value : string)
{
	theGame.CMFGetCore().MovieEvent(this, id, eventName, value);
}

// The end-of-build marker follows the late pass. The panel reports only after drawing finishes.
@addField(CR4MapMenu)
var cmfMovieBuild : int;

@addMethod(CR4MapMenu)
function CMFMovieBuildSent()
{
	var data : CScriptedFlashObject;
	data = GetMenuFlashValueStorage().CreateTempFlashObject();
	data.SetMemberFlashString("area", NameToString(m_shownArea));
	data.SetMemberFlashInt("build", cmfMovieBuild);
	GetMenuFlashValueStorage().SetFlashObject("cmf.map.movieBuild", data);
}

@addMethod(CR4MapMenu)
event OnCMFMovieAreaReady(areaText : string, build : int)
{
	if (build != cmfMovieBuild || areaText != NameToString(m_shownArea)) { return false; }
	theGame.CMFGetCore().OnMapAreaReady(this, m_shownArea);
}

@addMethod(CR4MapMenu)
event OnCMFMovieShowArea(areaText : string)
{
	CMFMovieShowArea(areaText);
}

@addMethod(CR4MapMenu)
function CMFMovieShowArea(areaText : string)
{
	var manager : CCommonMapManager;
	var areas : array<SAreaMapPinInfo>;
	var area, shown, requested : name;
	var i : int;
	var menuFlash : CScriptedFlashSprite;
	var entered : CScriptedFlashFunction;
	manager = theGame.GetCommonMapManager();
	area = manager.GetAreaFromFlashName(areaText);
	if (!IsNameValid(area))
	{
		areas = manager.GetAreaMapPins();
		for (i = 0; i < areas.Size(); i += 1)
		{
			if (NameToString(areas[i].areaName) == areaText) { area = areas[i].areaName; break; }
		}
	}
	if (!IsNameValid(area) || area == 'AN_Undefined')
	{
		// Version 13 fix round 1: say why nothing happens, so an author can fix the name.
		CMFLog("movie showArea unknown area=" + areaText);
		return;
	}
	requested = area;
	shown = m_shownArea;
	if (area == 'AN_Velen') { area = 'AN_NMLandNovigrad'; }
	if (shown == 'AN_Velen') { shown = 'AN_NMLandNovigrad'; }
	if (area == shown) { return; }
	SwitchToHubMap(requested, false);
	// Version 13 fix round 1: the panel enters the hub again, as the world view's region pick does, so the new
	// region's pins are drawn.
	menuFlash = GetMenuFlash();
	if (menuFlash)
	{
		entered = menuFlash.GetMemberFlashFunction("cmfMovieAreaEntered");
		if (entered)
		{
			entered.InvokeSelf();
		}
	}
}

@addMethod(CR4MapMenu)
event OnCMFMovieTagUnknown(id : string, tagText : string)
{
	theGame.CMFGetCore().MovieTagUnknown(id, tagText);
}
