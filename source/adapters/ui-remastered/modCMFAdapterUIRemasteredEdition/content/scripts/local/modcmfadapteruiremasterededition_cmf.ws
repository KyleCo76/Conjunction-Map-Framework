// UI Remastered Edition adapter for Conjunction Map Framework. Requires CMF 4 or later and UI Remastered
// Edition 1.00 (Nexus 14578), which stays unchanged. This file calls only CMF, so it compiles without UI
// Remastered, but it changes nothing unless UI Remastered's marker is on a pin: install it only with UI
// Remastered, and remove the two together.
//
// UI Remastered's AddPinTypeData wrapper (uire_worldmap.ws 174-210) writes a quest pin's label as the game's
// label, then the marker #UHL#, then a coloured "required level" line (204-205), and only UI Remastered's own
// map splits the title at that marker (its TooltipMap.as 226-241). Under CMF its map file does not load, so
// CMF's info box and crosshair label showed the marker and the level text inside the title. This adapter
// splits it as UI Remastered's map does: the title keeps the part before the marker, and the level line,
// in UI Remastered's own colour, goes on its own line under the pin's description.
//
// OnPinReady runs after every mod has added its pins (CMF 4), so UI Remastered's label is already written
// whichever script file sorts first; the file name does not matter.

@addField(CMFCore)
var uireAdapterSplit : int;

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var label : string;
	var title : string;
	var level : string;
	var description : string;
	wrappedMethod(dataObject, mapContext);
	label = dataObject.GetMemberFlashString("label");
	if (StrSplitFirst(label, "#UHL#", title, level))
	{
		dataObject.SetMemberFlashString("label", title);
		description = dataObject.GetMemberFlashString("description");
		if (description != "" && level != "")
		{
			description += "<br>";
		}
		dataObject.SetMemberFlashString("description", description + level);
		uireAdapterSplit += 1;
	}
}

// Launch evidence: one line per full map build.
@wrapMethod(CMFCore)
function OnMapReady(menuFlash : CScriptedFlashSprite)
{
	wrappedMethod(menuFlash);
	LogChannel('CMF', "CMF adapter provider=mod0000_UIRemasteredEdition levelTitlesSplit=" + uireAdapterSplit);
	uireAdapterSplit = 0;
}
