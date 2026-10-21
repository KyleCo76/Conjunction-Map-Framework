// Coloured Map Markers adapter for Conjunction Map Framework. Requires CMF 1 or later.
// The art is Coloured Map Markers' own recoloured Shape icons by DJ_Kovrik (Nexus mod 938, maintained by
// LewisElementary), used under the mod's compatibility notice:
// "You have permission as long as you credit DJ_Kovrik and the mod"
// One icon per pin type its world map recolours; CMF fits each into the stock glyph's box and sets the legend
// row from the same image. Level variants (_1 to _3) follow their base type. Claims name modcoloured_map_marker,
// Coloured Map Markers' own folder, so folder order between map mods is the same with CMF as without it.
// Coloured Map Markers has no scripts, so nothing can check that it is installed: by its permission, these
// icons also show without it.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modcoloured_map_marker", 1))
	{
		CMFRegisterIcon("modcoloured_map_marker", 'Boat', "img://icons/modcmfadaptercolouredmapmarkers/boat.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Horse', "img://icons/modcmfadaptercolouredmapmarkers/horse.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Shopkeeper', "img://icons/modcmfadaptercolouredmapmarkers/shopkeeper.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Blacksmith', "img://icons/modcmfadaptercolouredmapmarkers/blacksmith.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Armorer', "img://icons/modcmfadaptercolouredmapmarkers/armorer.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Hairdresser', "img://icons/modcmfadaptercolouredmapmarkers/hairdresser.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Alchemic', "img://icons/modcmfadaptercolouredmapmarkers/alchemic.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Enchanter', "img://icons/modcmfadaptercolouredmapmarkers/enchanter.png");
		CMFRegisterIcon("modcoloured_map_marker", 'PlayerStash', "img://icons/modcmfadaptercolouredmapmarkers/player_stash.png");
		CMFRegisterIcon("modcoloured_map_marker", 'PlayerStashDiscoverable', "img://icons/modcmfadaptercolouredmapmarkers/player_stash.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Entrance', "img://icons/modcmfadaptercolouredmapmarkers/entrance.png");
		CMFRegisterIcon("modcoloured_map_marker", 'MonsterNest', "img://icons/modcmfadaptercolouredmapmarkers/monster_nest.png");
		CMFRegisterIcon("modcoloured_map_marker", 'MonsterNestDisabled', "img://icons/modcmfadaptercolouredmapmarkers/monster_nest_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'PlaceOfPower', "img://icons/modcmfadaptercolouredmapmarkers/place_of_power.png");
		CMFRegisterIcon("modcoloured_map_marker", 'PlaceOfPowerDisabled', "img://icons/modcmfadaptercolouredmapmarkers/place_of_power_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'MagicLamp', "img://icons/modcmfadaptercolouredmapmarkers/magic_lamp.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Herbalist', "img://icons/modcmfadaptercolouredmapmarkers/herbalist.png");
		CMFRegisterIcon("modcoloured_map_marker", 'TreasureHuntMappin', "img://icons/modcmfadaptercolouredmapmarkers/treasure_hunt_mappin.png");
		CMFRegisterIcon("modcoloured_map_marker", 'TreasureHuntMappinDisabled', "img://icons/modcmfadaptercolouredmapmarkers/treasure_hunt_mappin_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Whetstone', "img://icons/modcmfadaptercolouredmapmarkers/whetstone.png");
		CMFRegisterIcon("modcoloured_map_marker", 'ArmorRepairTable', "img://icons/modcmfadaptercolouredmapmarkers/armor_repair_table.png");
		CMFRegisterIcon("modcoloured_map_marker", 'GrindStone', "img://icons/modcmfadaptercolouredmapmarkers/grind_stone.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Prostitute', "img://icons/modcmfadaptercolouredmapmarkers/prostitute.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Innkeeper', "img://icons/modcmfadaptercolouredmapmarkers/innkeeper.png");
		CMFRegisterIcon("modcoloured_map_marker", 'SpoilsOfWar', "img://icons/modcmfadaptercolouredmapmarkers/spoils_of_war.png");
		CMFRegisterIcon("modcoloured_map_marker", 'SpoilsOfWarDisabled', "img://icons/modcmfadaptercolouredmapmarkers/spoils_of_war_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'BanditCamp', "img://icons/modcmfadaptercolouredmapmarkers/bandit_camp.png");
		CMFRegisterIcon("modcoloured_map_marker", 'BanditCampDisabled', "img://icons/modcmfadaptercolouredmapmarkers/bandit_camp_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'BanditCampfire', "img://icons/modcmfadaptercolouredmapmarkers/bandit_campfire.png");
		CMFRegisterIcon("modcoloured_map_marker", 'BanditCampfireDisabled', "img://icons/modcmfadaptercolouredmapmarkers/bandit_campfire_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'BossAndTreasure', "img://icons/modcmfadaptercolouredmapmarkers/boss_and_treasure.png");
		CMFRegisterIcon("modcoloured_map_marker", 'BossAndTreasureDisabled', "img://icons/modcmfadaptercolouredmapmarkers/boss_and_treasure_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Contraband', "img://icons/modcmfadaptercolouredmapmarkers/contraband.png");
		CMFRegisterIcon("modcoloured_map_marker", 'ContrabandDisabled', "img://icons/modcmfadaptercolouredmapmarkers/contraband_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'ContrabandShip', "img://icons/modcmfadaptercolouredmapmarkers/contraband_ship.png");
		CMFRegisterIcon("modcoloured_map_marker", 'ContrabandShipDisabled', "img://icons/modcmfadaptercolouredmapmarkers/contraband_ship_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'RescuingTown', "img://icons/modcmfadaptercolouredmapmarkers/rescuing_town.png");
		CMFRegisterIcon("modcoloured_map_marker", 'RescuingTownDisabled', "img://icons/modcmfadaptercolouredmapmarkers/rescuing_town_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'DungeonCrawl', "img://icons/modcmfadaptercolouredmapmarkers/dungeon_crawl.png");
		CMFRegisterIcon("modcoloured_map_marker", 'DungeonCrawlDisabled', "img://icons/modcmfadaptercolouredmapmarkers/dungeon_crawl_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Hideout', "img://icons/modcmfadaptercolouredmapmarkers/hideout.png");
		CMFRegisterIcon("modcoloured_map_marker", 'HideoutDisabled', "img://icons/modcmfadaptercolouredmapmarkers/hideout_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Archmaster', "img://icons/modcmfadaptercolouredmapmarkers/archmaster.png");
		CMFRegisterIcon("modcoloured_map_marker", 'InfestedVineyard', "img://icons/modcmfadaptercolouredmapmarkers/infested_vineyard.png");
		CMFRegisterIcon("modcoloured_map_marker", 'InfestedVineyardDisabled', "img://icons/modcmfadaptercolouredmapmarkers/infested_vineyard_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'WineMerchant', "img://icons/modcmfadaptercolouredmapmarkers/wine_merchant.png");
		CMFRegisterIcon("modcoloured_map_marker", 'DyeMerchant', "img://icons/modcmfadaptercolouredmapmarkers/dye_merchant.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Plegmund', "img://icons/modcmfadaptercolouredmapmarkers/plegmund.png");
		CMFRegisterIcon("modcoloured_map_marker", 'PlegmundDisabled', "img://icons/modcmfadaptercolouredmapmarkers/plegmund_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'WineContract', "img://icons/modcmfadaptercolouredmapmarkers/wine_contract.png");
		CMFRegisterIcon("modcoloured_map_marker", 'WineContractDisabled', "img://icons/modcmfadaptercolouredmapmarkers/wine_contract_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'SignalingStake', "img://icons/modcmfadaptercolouredmapmarkers/signaling_stake.png");
		CMFRegisterIcon("modcoloured_map_marker", 'SignalingStakeDisabled', "img://icons/modcmfadaptercolouredmapmarkers/signaling_stake_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Stables', "img://icons/modcmfadaptercolouredmapmarkers/stables.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Bed', "img://icons/modcmfadaptercolouredmapmarkers/bed.png");
		CMFRegisterIcon("modcoloured_map_marker", 'MutagenDismantle', "img://icons/modcmfadaptercolouredmapmarkers/mutagen_dismantle.png");
		CMFRegisterIcon("modcoloured_map_marker", 'AlchemyTable', "img://icons/modcmfadaptercolouredmapmarkers/alchemy_table.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Bookshelf', "img://icons/modcmfadaptercolouredmapmarkers/bookshelf.png");
		CMFRegisterIcon("modcoloured_map_marker", 'KnightErrant', "img://icons/modcmfadaptercolouredmapmarkers/knight_errant.png");
		CMFRegisterIcon("modcoloured_map_marker", 'KnightErrantDisabled', "img://icons/modcmfadaptercolouredmapmarkers/knight_errant_disabled.png");
		CMFRegisterIcon("modcoloured_map_marker", 'Cammerlengo', "img://icons/modcmfadaptercolouredmapmarkers/cammerlengo.png");
	}
	return result;
}
