// Witcher Gear Map adapter for Conjunction Map Framework. Requires CMF 1 or later and
// Witcher Upgrade Gear Map 1.0.1 (Nexus 14157), which stays unchanged.
//
// Gear Map pushes its own pins from a CR4MapMenu.UpdateEntityPins wrapper, typed by its own
// names: WitcherGear, then Obtained once every diagram there is learned, then the school
// (Cat, Griffin, Bear, Wolf, Viper, Manticore) unless the icon style is "No colour", then Ring
// for "School colour with circle"; filteredType is always WitcherGear. Gear's own map file
// draws those names; under CMF's map the names have no frame, so this adapter gives each one
// art through CMF under the same name. Nothing of Gear Map is called in this file; the second
// file, modcmfadapterwitchergearmap_stable.ws, calls Gear Map's own functions, so install and remove
// the adapter together with Gear Map.
//
// Placeholder art only (CMF's own, drawn by tools/cmf_gear_adapter_art.py). The slot for the
// Gear Map author's art: replace the four PNGs in art/ (same names) and rebuild with
// tools/cmf_pack.py; the tints below colour light parts of the art by school.
//
// Under CMF 2 the adapter also brings back Gear Map's own "Witcher Gear" filter tab and row name,
// using Gear Map's own category id (wgm_gear) and its own string keys, which Gear Map's w3strings
// already ship. Under CMF 1 that block is skipped and the markers stay listed under All.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modWitcherGearMap", 1))
	{
		// Icon style "No colour": one type per state.
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGear', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtained', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		// Icon style "School colour without circle": the school is part of the type name.
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearCat', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearCat', 6336767);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedCat', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedCat', 6336767);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearGriffin', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearGriffin', 7393392);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedGriffin', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedGriffin', 7393392);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearBear', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearBear', 13668432);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedBear', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedBear', 13668432);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearWolf', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearWolf', 16736352);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedWolf', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedWolf', 16736352);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearViper', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearViper', 4251824);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedViper', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedViper', 4251824);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearManticore', "img://icons/modcmfadapterwitchergearmap/gear.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearManticore', 12611839);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedManticore', "img://icons/modcmfadapterwitchergearmap/gear_obtained.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedManticore', 12611839);
		// Icon style "School colour with circle": the same with "Ring" at the end.
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearCatRing', "img://icons/modcmfadapterwitchergearmap/gear_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearCatRing', 6336767);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedCatRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedCatRing', 6336767);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearGriffinRing', "img://icons/modcmfadapterwitchergearmap/gear_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearGriffinRing', 7393392);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedGriffinRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedGriffinRing', 7393392);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearBearRing', "img://icons/modcmfadapterwitchergearmap/gear_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearBearRing', 13668432);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedBearRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedBearRing', 13668432);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearWolfRing', "img://icons/modcmfadapterwitchergearmap/gear_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearWolfRing', 16736352);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedWolfRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedWolfRing', 16736352);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearViperRing', "img://icons/modcmfadapterwitchergearmap/gear_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearViperRing', 4251824);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedViperRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedViperRing', 4251824);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearManticoreRing', "img://icons/modcmfadapterwitchergearmap/gear_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearManticoreRing', 12611839);
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedManticoreRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_ring.png");
		CMFRegisterTint("modWitcherGearMap", 'WitcherGearObtainedManticoreRing', 12611839);
		// Legend: every Gear marker shares one row, keyed by its filteredType WitcherGear. Its image is
		// registered on that key itself, never left to a fallback from a marker type's art.
		CMFRegisterLegendIcon("modWitcherGearMap", 'WitcherGear', "img://icons/modcmfadapterwitchergearmap/gear.png");
		// CMF 2 legend rows and filter tabs. The CMF 2 names this adapter depends on are all in this
		// block: property ids 8 (legend category), 6 (legend row) and 7 (legend label) of the generic
		// CMFRegister call, used as literals so the file still compiles on CMF 1, which skips the block.
		// The values are Gear Map's own: its tab id wgm_gear at priority 8 and its row WitcherGear at
		// 703, as its own map file declares them, and its string keys map_category_wgm_gear and
		// wgm_label ("Witcher Gear" in Gear Map's w3strings).
		if (CMFHasProperty(8))
		{
			CMFRegister("modWitcherGearMap", 8, 'wgm_gear', '', "[[map_category_wgm_gear]]", 8);
			CMFRegister("modWitcherGearMap", 6, 'WitcherGear', '', "wgm_gear", 703);
			CMFRegister("modWitcherGearMap", 7, 'WitcherGear', '', "[[wgm_label]]", 0);
		}
	}
	return result;
}
