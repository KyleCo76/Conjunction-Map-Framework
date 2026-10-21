// Botanist adapter for Conjunction Map Framework. Requires CMF 5 or later (CMF 6 keeps Botanist's rows out of
// Default) and Botanist - NG - Remastered 3.0.0.2 (Nexus 8260) with Shared Utils 4.1 (Nexus 12997), which stay
// unchanged. This file calls only CMF, so it compiles without Botanist, but it restores Botanist's map only:
// install it only with Botanist, and remove the two together.
//
// Botanist 3.0 ships its own copy of the game's world map file. Under CMF that file does not load (CMF's map
// sorts first), so this adapter asks CMF for the same map changes with CMF's general calls, as Botanist's author
// would when porting. Its map file (HubMapPinPanel, read with FFDec 26.3.0) is the game's with:
//   - a "Botanist" filter tab, priority 8, its name the key map_category_Botanist (Botanist's own strings),
//     that shows player pins but neither fast-travel pins (signposts, harbours, ferries) nor quest pins and
//     whose rows are not listed under Default;
//   - rows BotanistHGHerb 612, BotanistHG 613 and Botanist 614 in it, and a drawing for each of the three.
// Nothing else: it is byte for byte Community Patch - World Map's movie without The Stable's Stables row and
// Smooth GUI's 60 frames per second. So every value here equals the Community Patch adapter's Botanist lines,
// and the map looks the same whichever of the two adapters is installed. Botanist's pins themselves come from
// Botanist's scripts through Shared Utils' map pins, which this adapter does not touch.
// Every claim uses Botanist's own folder name as its provider, so folder order between mods is the same with
// CMF as without it: Community Patch's folder sorts first and wins every claim the two share, as its map file
// wins over Botanist's without CMF.
//
// The herb drawings are placeholders from this adapter's own texture cache (drawn by tools/
// cmf_community_patch_adapter_art.py, the same pictures as the Community Patch adapter's): CMF ships no other
// mod's art. Drop the author's art into art/ under the same names and rebuild with tools/cmf_pack.py.
// Botanist's larger BotanistHG drawing is about 1.49 times the other two in its map file (14.7 by 13.1 px
// against 9.85 by 8.8 px), so that type claims 149 percent (CMF 4 pin size, property id 10). Its frames tell
// the three apart by an accent colour, gold or blue, which a type tint gives back (CMF 1 property 3).

@addField(CMFCore)
var botanistAdapterHidden : int;

@addField(CMFCore)
var botanistAdapterPins : int;

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modBotanist", 5))
	{
		// Its tab (property 8) and its three rows in it (property 6), with Botanist's own id, priorities and
		// string key. Rows keep the label Botanist gives its pins.
		CMFRegister("modBotanist", 8, 'Botanist', '', "[[map_category_Botanist]]", 8);
		// Its rows stayed out of Default (CMF 6 property 23, CMFRegisterCategoryNoDefault; written as the number
		// behind CMFHasProperty so the file still compiles on CMF 5, where Default also lists them).
		if (CMFHasProperty(23))
		{
			CMFRegister("modBotanist", 23, 'Botanist', '', "", 1);
		}
		CMFRegister("modBotanist", 6, 'BotanistHGHerb', '', "Botanist", 612);
		CMFRegister("modBotanist", 6, 'BotanistHG', '', "Botanist", 613);
		CMFRegister("modBotanist", 6, 'Botanist', '', "Botanist", 614);
		CMFRegisterIcon("modBotanist", 'BotanistHGHerb', "img://icons/modcmfadapterbotanist/herb.png");
		CMFRegisterIcon("modBotanist", 'BotanistHG', "img://icons/modcmfadapterbotanist/herb_ground.png");
		CMFRegisterIcon("modBotanist", 'Botanist', "img://icons/modcmfadapterbotanist/herb.png");
		CMFRegisterLegendIcon("modBotanist", 'BotanistHGHerb', "img://icons/modcmfadapterbotanist/herb.png");
		CMFRegisterLegendIcon("modBotanist", 'BotanistHG', "img://icons/modcmfadapterbotanist/herb_ground.png");
		CMFRegisterLegendIcon("modBotanist", 'Botanist', "img://icons/modcmfadapterbotanist/herb.png");
		CMFRegister("modBotanist", CMFPropertyPinScale(), 'BotanistHG', '', "", 149);
		// Botanist's meaning by colour: gold for a herb ready to harvest (Botanist), blue for a herb in a
		// Harvesting Ground and for the ground itself (BotanistHGHerb, BotanistHG); the accent colours of its
		// frames, 0xFFCC00 and 0x9BAADD, the same colours its menu and pin texts use. The white placeholders
		// take the exact colour.
		CMFRegisterTint("modBotanist", 'Botanist', 16763904);
		CMFRegisterTint("modBotanist", 'BotanistHGHerb', 10201821);
		CMFRegisterTint("modBotanist", 'BotanistHG', 10201821);
	}
	return result;
}

// Botanist's tab leaves out fast-travel pins (CategoryDefinition(8, true, false, false)); CMF's tabs show them,
// so every fast-travel pin of a map build gets a tab hide for "Botanist" (CMF 4 property 15). This is the same
// test Botanist's map makes: the pin's own isFastTravel flag, whoever pushed the pin. The adapter also counts
// Botanist's own pins, so the log shows that CMF saw the pins Shared Utils pushes for Botanist.
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var pinType : string;
	wrappedMethod(dataObject, mapContext);
	if (dataObject.GetMemberFlashBool("isFastTravel"))
	{
		if (CMFStylePin("modBotanist", dataObject, CMFPropertyTabHide(), "Botanist", 1))
		{
			botanistAdapterHidden += 1;
		}
	}
	pinType = dataObject.GetMemberFlashString("type");
	if (pinType == "Botanist" || pinType == "BotanistHGHerb" || pinType == "BotanistHG")
	{
		botanistAdapterPins += 1;
	}
}

// Launch evidence: one line per full map build.
@wrapMethod(CMFCore)
function OnMapReady(menuFlash : CScriptedFlashSprite)
{
	wrappedMethod(menuFlash);
	LogChannel('CMF', "CMF adapter provider=modBotanist botanistTabHides=" + botanistAdapterHidden +
		" botanistPins=" + botanistAdapterPins);
	botanistAdapterHidden = 0;
	botanistAdapterPins = 0;
}
