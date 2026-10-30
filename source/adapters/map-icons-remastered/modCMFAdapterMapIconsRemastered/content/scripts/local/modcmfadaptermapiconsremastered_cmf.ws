// Map Icons - Remastered pack 1.0.0 for Conjunction Map Framework.
// World-map artwork by kandy422 (Nexus 14490), used with explicit permission 2026-10-30.
// Shows with or without the original map-file-only mod. No presence declaration or detection.
// Icon API 1; exact level/player/user art API 11; seven crests use generic API 9 property 25.
// Every completed-state image is the original artist bitmap, not a disabled tint override.
// Made by Kyle with the help of AI tools (Claude and ChatGPT)

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("mod000MapIconsRemastered", 1))
	{
		CMFRegisterIcon("mod000MapIconsRemastered", 'RoadSign', "img://icons/modcmfadaptermapiconsremastered/road_sign.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Quest', "img://icons/modcmfadaptermapiconsremastered/quest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Boat', "img://icons/modcmfadaptermapiconsremastered/boat.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Horse', "img://icons/modcmfadaptermapiconsremastered/horse.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Shopkeeper', "img://icons/modcmfadaptermapiconsremastered/shopkeeper.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Blacksmith', "img://icons/modcmfadaptermapiconsremastered/blacksmith.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Armorer', "img://icons/modcmfadaptermapiconsremastered/armorer.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BoatBuilder', "img://icons/modcmfadaptermapiconsremastered/boat_builder.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Hairdresser', "img://icons/modcmfadaptermapiconsremastered/hairdresser.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Alchemic', "img://icons/modcmfadaptermapiconsremastered/alchemic.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Enchanter', "img://icons/modcmfadaptermapiconsremastered/enchanter.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Container', "img://icons/modcmfadaptermapiconsremastered/container.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'NoticeBoardFull', "img://icons/modcmfadaptermapiconsremastered/notice_board_full.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'NoticeBoard', "img://icons/modcmfadaptermapiconsremastered/notice_board.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'PlayerStash', "img://icons/modcmfadaptermapiconsremastered/player_stash.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'PlayerStashDiscoverable', "img://icons/modcmfadaptermapiconsremastered/player_stash_discoverable.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Entrance', "img://icons/modcmfadaptermapiconsremastered/entrance.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterNest', "img://icons/modcmfadaptermapiconsremastered/monster_nest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterNestDisabled', "img://icons/modcmfadaptermapiconsremastered/monster_nest_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterHunt', "img://icons/modcmfadaptermapiconsremastered/monster_hunt.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'PlaceOfPower', "img://icons/modcmfadaptermapiconsremastered/place_of_power.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'PlaceOfPowerDisabled', "img://icons/modcmfadaptermapiconsremastered/place_of_power_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Harbor', "img://icons/modcmfadaptermapiconsremastered/harbor.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MagicLamp', "img://icons/modcmfadaptermapiconsremastered/magic_lamp.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Herbalist', "img://icons/modcmfadaptermapiconsremastered/herbalist.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'racetrack', "img://icons/modcmfadaptermapiconsremastered/racetrack.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestAvailable', "img://icons/modcmfadaptermapiconsremastered/quest_available.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestAvailableHoS', "img://icons/modcmfadaptermapiconsremastered/quest_available_ho_s.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestAvailableBaW', "img://icons/modcmfadaptermapiconsremastered/quest_available_ba_w.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'StoryQuest', "img://icons/modcmfadaptermapiconsremastered/story_quest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'ChapterQuest', "img://icons/modcmfadaptermapiconsremastered/chapter_quest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'SideQuest', "img://icons/modcmfadaptermapiconsremastered/side_quest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterQuest', "img://icons/modcmfadaptermapiconsremastered/monster_quest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'TreasureQuest', "img://icons/modcmfadaptermapiconsremastered/treasure_quest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'TreasureHuntMappin', "img://icons/modcmfadaptermapiconsremastered/treasure_hunt_mappin.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'TreasureHuntMappinDisabled', "img://icons/modcmfadaptermapiconsremastered/treasure_hunt_mappin_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterClue', "img://icons/modcmfadaptermapiconsremastered/monster_clue.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Camp', "img://icons/modcmfadaptermapiconsremastered/camp.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'DwarvenFurnace', "img://icons/modcmfadaptermapiconsremastered/dwarven_furnace.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Whetstone', "img://icons/modcmfadaptermapiconsremastered/whetstone.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'ArmorRepairTable', "img://icons/modcmfadaptermapiconsremastered/armor_repair_table.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BoatRace', "img://icons/modcmfadaptermapiconsremastered/boat_race.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'GrindStone', "img://icons/modcmfadaptermapiconsremastered/grind_stone.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'PlaceOfPowerStrong', "img://icons/modcmfadaptermapiconsremastered/place_of_power_strong.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'FistFight', "img://icons/modcmfadaptermapiconsremastered/fist_fight.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Companion', "img://icons/modcmfadaptermapiconsremastered/companion.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Prostitute', "img://icons/modcmfadaptermapiconsremastered/prostitute.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestGiverStory', "img://icons/modcmfadaptermapiconsremastered/quest_giver_story.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestGiverChapter', "img://icons/modcmfadaptermapiconsremastered/quest_giver_chapter.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestGiverSide', "img://icons/modcmfadaptermapiconsremastered/quest_giver_side.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'HorseRacingNPC', "img://icons/modcmfadaptermapiconsremastered/horse_racing_npc.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'HorseRace', "img://icons/modcmfadaptermapiconsremastered/horse_race.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'NonQuestHorseRace', "img://icons/modcmfadaptermapiconsremastered/non_quest_horse_race.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestBelgard', "img://icons/modcmfadaptermapiconsremastered/quest_belgard.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestCoronata', "img://icons/modcmfadaptermapiconsremastered/quest_coronata.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestVermentino', "img://icons/modcmfadaptermapiconsremastered/quest_vermentino.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Herb', "img://icons/modcmfadaptermapiconsremastered/herb.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Innkeeper', "img://icons/modcmfadaptermapiconsremastered/innkeeper.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Cave', "img://icons/modcmfadaptermapiconsremastered/cave.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'NotDiscoveredPOI', "img://icons/modcmfadaptermapiconsremastered/not_discovered_poi.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'SpoilsOfWar', "img://icons/modcmfadaptermapiconsremastered/spoils_of_war.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'SpoilsOfWarDisabled', "img://icons/modcmfadaptermapiconsremastered/spoils_of_war_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCamp', "img://icons/modcmfadaptermapiconsremastered/bandit_camp.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCampDisabled', "img://icons/modcmfadaptermapiconsremastered/bandit_camp_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCampfire', "img://icons/modcmfadaptermapiconsremastered/bandit_campfire.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCampfireDisabled', "img://icons/modcmfadaptermapiconsremastered/bandit_campfire_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BossAndTreasure', "img://icons/modcmfadaptermapiconsremastered/boss_and_treasure.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'BossAndTreasureDisabled', "img://icons/modcmfadaptermapiconsremastered/boss_and_treasure_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Contraband', "img://icons/modcmfadaptermapiconsremastered/contraband.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'ContrabandDisabled', "img://icons/modcmfadaptermapiconsremastered/contraband_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'ContrabandShip', "img://icons/modcmfadaptermapiconsremastered/contraband_ship.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'ContrabandShipDisabled', "img://icons/modcmfadaptermapiconsremastered/contraband_ship_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'RescuingTown', "img://icons/modcmfadaptermapiconsremastered/rescuing_town.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'RescuingTownDisabled', "img://icons/modcmfadaptermapiconsremastered/rescuing_town_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'DungeonCrawl', "img://icons/modcmfadaptermapiconsremastered/dungeon_crawl.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'DungeonCrawlDisabled', "img://icons/modcmfadaptermapiconsremastered/dungeon_crawl_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Hideout', "img://icons/modcmfadaptermapiconsremastered/hideout.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'HideoutDisabled', "img://icons/modcmfadaptermapiconsremastered/hideout_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Torch', "img://icons/modcmfadaptermapiconsremastered/torch.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Archmaster', "img://icons/modcmfadaptermapiconsremastered/archmaster.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'InfestedVineyard', "img://icons/modcmfadaptermapiconsremastered/infested_vineyard.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'InfestedVineyardDisabled', "img://icons/modcmfadaptermapiconsremastered/infested_vineyard_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'WineMerchant', "img://icons/modcmfadaptermapiconsremastered/wine_merchant.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'DyeMerchant', "img://icons/modcmfadaptermapiconsremastered/dye_merchant.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Plegmund', "img://icons/modcmfadaptermapiconsremastered/plegmund.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'PlegmundDisabled', "img://icons/modcmfadaptermapiconsremastered/plegmund_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'WineContract', "img://icons/modcmfadaptermapiconsremastered/wine_contract.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'WineContractDisabled', "img://icons/modcmfadaptermapiconsremastered/wine_contract_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'SignalingStake', "img://icons/modcmfadaptermapiconsremastered/signaling_stake.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'SignalingStakeDisabled', "img://icons/modcmfadaptermapiconsremastered/signaling_stake_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Stables', "img://icons/modcmfadaptermapiconsremastered/stables.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Bed', "img://icons/modcmfadaptermapiconsremastered/bed.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'MutagenDismantle', "img://icons/modcmfadaptermapiconsremastered/mutagen_dismantle.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'AlchemyTable', "img://icons/modcmfadaptermapiconsremastered/alchemy_table.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Bookshelf', "img://icons/modcmfadaptermapiconsremastered/bookshelf.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'KnightErrant', "img://icons/modcmfadaptermapiconsremastered/knight_errant.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'KnightErrantDisabled', "img://icons/modcmfadaptermapiconsremastered/knight_errant_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Cammerlengo', "img://icons/modcmfadaptermapiconsremastered/cammerlengo.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'WitcherHouse', "img://icons/modcmfadaptermapiconsremastered/witcher_house.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'LettenStories', "img://icons/modcmfadaptermapiconsremastered/letten_stories.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'NettelStories', "img://icons/modcmfadaptermapiconsremastered/nettel_stories.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'LettenStoriesDisabled', "img://icons/modcmfadaptermapiconsremastered/letten_stories_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'NettelStoriesDisabled', "img://icons/modcmfadaptermapiconsremastered/nettel_stories_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'Transport', "img://icons/modcmfadaptermapiconsremastered/transport.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'HiverNest', "img://icons/modcmfadaptermapiconsremastered/hiver_nest.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'HiverNestDisabled', "img://icons/modcmfadaptermapiconsremastered/hiver_nest_disabled.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestAvailableLy', "img://icons/modcmfadaptermapiconsremastered/quest_available_ly.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestObjective', "img://icons/modcmfadaptermapiconsremastered/quest_objective.png");
		CMFRegisterIcon("mod000MapIconsRemastered", 'QuestObjectiveOther', "img://icons/modcmfadaptermapiconsremastered/quest_objective_other.png");
		if (CMFGetVersion() >= 11)
		{
			CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterNest_1', "img://icons/modcmfadaptermapiconsremastered/monster_nest_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterNest_2', "img://icons/modcmfadaptermapiconsremastered/monster_nest_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'MonsterNest_3', "img://icons/modcmfadaptermapiconsremastered/monster_nest_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'Player', "img://icons/modcmfadaptermapiconsremastered/player.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'TreasureHuntMappin_1', "img://icons/modcmfadaptermapiconsremastered/treasure_hunt_mappin_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'TreasureHuntMappin_2', "img://icons/modcmfadaptermapiconsremastered/treasure_hunt_mappin_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'TreasureHuntMappin_3', "img://icons/modcmfadaptermapiconsremastered/treasure_hunt_mappin_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User1', "img://icons/modcmfadaptermapiconsremastered/user1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User2', "img://icons/modcmfadaptermapiconsremastered/user2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User3', "img://icons/modcmfadaptermapiconsremastered/user3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User4', "img://icons/modcmfadaptermapiconsremastered/user4.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'NotDiscoveredPOI_1', "img://icons/modcmfadaptermapiconsremastered/not_discovered_poi_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'NotDiscoveredPOI_2', "img://icons/modcmfadaptermapiconsremastered/not_discovered_poi_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'NotDiscoveredPOI_3', "img://icons/modcmfadaptermapiconsremastered/not_discovered_poi_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCamp_1', "img://icons/modcmfadaptermapiconsremastered/bandit_camp_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCamp_2', "img://icons/modcmfadaptermapiconsremastered/bandit_camp_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'BanditCamp_3', "img://icons/modcmfadaptermapiconsremastered/bandit_camp_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'BossAndTreasure_1', "img://icons/modcmfadaptermapiconsremastered/boss_and_treasure_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'BossAndTreasure_2', "img://icons/modcmfadaptermapiconsremastered/boss_and_treasure_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'BossAndTreasure_3', "img://icons/modcmfadaptermapiconsremastered/boss_and_treasure_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'RescuingTown_1', "img://icons/modcmfadaptermapiconsremastered/rescuing_town_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'RescuingTown_2', "img://icons/modcmfadaptermapiconsremastered/rescuing_town_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'RescuingTown_3', "img://icons/modcmfadaptermapiconsremastered/rescuing_town_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'InfestedVineyard_1', "img://icons/modcmfadaptermapiconsremastered/infested_vineyard_1.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'InfestedVineyard_2', "img://icons/modcmfadaptermapiconsremastered/infested_vineyard_2.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'InfestedVineyard_3', "img://icons/modcmfadaptermapiconsremastered/infested_vineyard_3.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User5', "img://icons/modcmfadaptermapiconsremastered/user5.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User6', "img://icons/modcmfadaptermapiconsremastered/user6.png");
			CMFRegisterIcon("mod000MapIconsRemastered", 'User7', "img://icons/modcmfadaptermapiconsremastered/user7.png");
		}
		if (CMFGetVersion() >= 9)
		{
			CMFRegister("mod000MapIconsRemastered", 25, 'bob', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_bob.png", 0);
			CMFRegister("mod000MapIconsRemastered", 25, 'prolog_village', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_prolog_village.png", 0);
			CMFRegister("mod000MapIconsRemastered", 25, 'skellige', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_skellige.png", 0);
			CMFRegister("mod000MapIconsRemastered", 25, 'kaer_morhen', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_kaer_morhen.png", 0);
			CMFRegister("mod000MapIconsRemastered", 25, 'novigrad', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_novigrad.png", 0);
			CMFRegister("mod000MapIconsRemastered", 25, 'no_mans_land', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_no_mans_land.png", 0);
			CMFRegister("mod000MapIconsRemastered", 25, 'wyzima_castle', '', "img://icons/modcmfadaptermapiconsremastered/world/crest_wyzima_castle.png", 0);
		}
	}
	return result;
}
