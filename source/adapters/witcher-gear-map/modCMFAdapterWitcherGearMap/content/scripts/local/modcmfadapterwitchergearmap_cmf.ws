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
// Art by MateusAnd, Gear Map's author, shipped here with their permission (2026-10-21): one
// picture per type, drawn from the same shapes and colours as Gear Map's own map file. To change
// it, replace the PNGs in art/ (same names) and rebuild with tools/cmf_pack.py.
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
		// Icon style "School colour without circle": the school is part of the type name. The author's
		// art is coloured per school already, so no tint is registered.
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearCat', "img://icons/modcmfadapterwitchergearmap/gear_cat.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedCat', "img://icons/modcmfadapterwitchergearmap/gear_obtained_cat.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearGriffin', "img://icons/modcmfadapterwitchergearmap/gear_griffin.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedGriffin', "img://icons/modcmfadapterwitchergearmap/gear_obtained_griffin.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearBear', "img://icons/modcmfadapterwitchergearmap/gear_bear.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedBear', "img://icons/modcmfadapterwitchergearmap/gear_obtained_bear.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearWolf', "img://icons/modcmfadapterwitchergearmap/gear_wolf.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedWolf', "img://icons/modcmfadapterwitchergearmap/gear_obtained_wolf.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearViper', "img://icons/modcmfadapterwitchergearmap/gear_viper.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedViper', "img://icons/modcmfadapterwitchergearmap/gear_obtained_viper.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearManticore', "img://icons/modcmfadapterwitchergearmap/gear_manticore.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedManticore', "img://icons/modcmfadapterwitchergearmap/gear_obtained_manticore.png");
		// Icon style "School colour with circle": the same with "Ring" at the end.
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearCatRing', "img://icons/modcmfadapterwitchergearmap/gear_cat_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedCatRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_cat_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearGriffinRing', "img://icons/modcmfadapterwitchergearmap/gear_griffin_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedGriffinRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_griffin_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearBearRing', "img://icons/modcmfadapterwitchergearmap/gear_bear_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedBearRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_bear_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearWolfRing', "img://icons/modcmfadapterwitchergearmap/gear_wolf_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedWolfRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_wolf_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearViperRing', "img://icons/modcmfadapterwitchergearmap/gear_viper_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedViperRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_viper_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearManticoreRing', "img://icons/modcmfadapterwitchergearmap/gear_manticore_ring.png");
		CMFRegisterIcon("modWitcherGearMap", 'WitcherGearObtainedManticoreRing', "img://icons/modcmfadapterwitchergearmap/gear_obtained_manticore_ring.png");
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
