// Gwent Players Map adapter for Conjunction Map Framework. Requires CMF 2 or later and
// Gwent Players Map 1.0.9 (Nexus 13755), which stays unchanged. Install and remove the two together:
// this file calls Gwent Players Map's own filter event, so the game stops at the script compile screen
// when Gwent Players Map is missing.
//
// Gwent Players Map pushes its own pins from a CR4MapMenu.UpdateEntityPins wrapper, typed by its
// own names: GwentPlayer, or GwentPlayerDisabled once the player is beaten or gone, each with
// "Large" after "GwentPlayer" for its large-card option; filteredType is always GwentPlayer. Its
// own map file draws those names and files them under a "Gwent" filter tab. Under CMF's map the
// names have no frame, so this adapter gives each one art through CMF under the same name and
// brings back the tab with Gwent Players Map's own id and text. Every claim uses Gwent Players Map's
// own folder name as its provider, so folder order between mods is the same with CMF as without it.
//
// Its own map file reports every filter tab it shows as OnGwmMapFilter(tab name); CMF's map reports
// the same as OnCMFMapFilter(tab name), which this adapter hands to Gwent Players Map's event. Its
// script then moves the cards onto the players' spots in the "Gwent" tab, as it does on its own map.
// That needs the tab id to be exactly "Gwent".
//
// Art by MateusAnd, Gwent Players Map's author, shipped here with their permission (2026-10-21),
// drawn from the same shapes and colours as Gwent Players Map's own map file. To change it, replace
// the two PNGs in art/ (same names) and rebuild with tools/cmf_pack.py. Large cards use the same
// images, drawn at Gwent Players Map's large size: its map file draws the GwentPlayerLarge cards about 1.19 times the GwentPlayer ones (shape bounds 17.6 px
// against 14.8 px high), so the two large types claim 119 percent (CMF 4 pin size, property id 10).

@addMethod(CR4MapMenu)
event OnCMFMapFilter(category : string)
{
	OnGwmMapFilter(category);
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modGwentPlayersMap", 2))
	{
		CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayer', "img://icons/modcmfadaptergwentplayersmap/card.png");
		CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayerDisabled', "img://icons/modcmfadaptergwentplayersmap/card_beaten.png");
		CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayerLarge', "img://icons/modcmfadaptergwentplayersmap/card.png");
		CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayerLargeDisabled', "img://icons/modcmfadaptergwentplayersmap/card_beaten.png");
		// Legend: every card shares one row, keyed by its filteredType GwentPlayer. Its image is
		// registered on that key itself, never left to a fallback from a card type's art.
		CMFRegisterLegendIcon("modGwentPlayersMap", 'GwentPlayer', "img://icons/modcmfadaptergwentplayersmap/card.png");
		// CMF 2 legend rows and filter tabs: property ids 8 (legend category), 6 (legend row) and
		// 7 (legend label). The values are Gwent Players Map's own: its tab id Gwent at priority 8
		// and its row GwentPlayer at 701, as its own map file declares them, and its string keys
		// map_category_Gwent ("Gwent") and gwm_label_gwent_player ("Gwent player") from its w3strings.
		CMFRegister("modGwentPlayersMap", 8, 'Gwent', '', "[[map_category_Gwent]]", 8);
		CMFRegister("modGwentPlayersMap", 6, 'GwentPlayer', '', "Gwent", 701);
		CMFRegister("modGwentPlayersMap", 7, 'GwentPlayer', '', "[[gwm_label_gwent_player]]", 0);
		// The "Card size" option's large cards (CMF 4; CMF 2 and 3 skip this and show the small size).
		if (CMFHasProperty(10))
		{
			CMFRegister("modGwentPlayersMap", 10, 'GwentPlayerLarge', '', "", 119);
			CMFRegister("modGwentPlayersMap", 10, 'GwentPlayerLargeDisabled', '', "", 119);
		}
	}
	return result;
}
