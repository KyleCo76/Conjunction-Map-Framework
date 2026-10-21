Coloured Map Markers adapter for Conjunction Map Framework
Version 1.0.0

Brings Coloured Map Markers' coloured world map icons back while Conjunction Map Framework
(CMF) draws the world map. The art is Coloured Map Markers' own, by DJ_Kovrik, used with
permission. This adapter steps aside once Coloured Map Markers ships its own CMF support.

WHOSE ART THIS IS
Every picture in this adapter is a Shape icon of Coloured Map Markers (Nexus mod 938), made
by DJ_Kovrik and maintained by LewisElementary. Coloured Map Markers shares these shapes
in its Nexus misc files ("CMM Shapes - Remastered", 1.60) and its compatibility notice
says: "You have permission as long as you credit DJ_Kovrik and the mod". The pictures
are unchanged; they were only drawn at 96 x 96 for CMF. This adapter is not made by
DJ_Kovrik or LewisElementary; questions about it go to CMF's page, not to them.
Unlike CMF's other adapters, this one also shows its icons without Coloured Map Markers
installed: that mod has no scripts for an adapter to check, and its permission covers
using the shapes on their own.
Coloured Map Markers: https://www.nexusmods.com/witcher3/mods/938

REQUIREMENTS
- Conjunction Map Framework version 1 or later.
- Coloured Map Markers (recommended, not required). Keep it installed: CMF's map is the
  world map the game loads, so this adapter shows its icons there, and Coloured Map
  Markers keeps colouring the minimap as before (unless you also use CMF's minimap
  add-on, which draws its own minimap).

PIN TYPES THIS ADAPTER CHANGES (new icon; the legend row uses the same picture)
- Merchants and services: Shopkeeper, Blacksmith, Armorer, Alchemic, Herbalist,
  Innkeeper, Enchanter, Hairdresser, Prostitute, WineMerchant, DyeMerchant, Archmaster,
  Cammerlengo
- Places: Entrance, Boat, Horse, PlayerStash, PlayerStashDiscoverable, Stables, Bed,
  MagicLamp
- Points of interest, each open and completed: MonsterNest, TreasureHuntMappin,
  SpoilsOfWar, BanditCamp, BanditCampfire, BossAndTreasure, Contraband, ContrabandShip,
  RescuingTown, DungeonCrawl, Hideout, InfestedVineyard, Plegmund, WineContract,
  SignalingStake, KnightErrant, PlaceOfPower (the level versions follow these)
- Crafting and buffs: Whetstone, GrindStone, ArmorRepairTable, AlchemyTable,
  MutagenDismantle, Bookshelf
Its claims carry Coloured Map Markers' own folder name (modcoloured_map_marker), so when
another CMF mod changes the same pin type, the same one wins as would without CMF.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. The adapter lands in Mods\modCMFAdapterColouredMapMarkers. No Script Merger is needed.

UNINSTALL
Remove this adapter BEFORE removing Conjunction Map Framework. If CMF is removed first,
the game stops at the script compile screen until this adapter is removed too.
The adapter writes nothing into saves; removing it restores the original icons.

COMPATIBILITY
Works alongside other CMF icon packs and CMF-based map mods: Conjunction Map Framework
is the single world map they all work through. Do not give a map mod that ships its own
copy of the map a lower Priority than CMF in mods.settings unless you mean to switch
CMF's map off; this adapter's icons would then disappear.

CREDITS
- Art: DJ_Kovrik, Coloured Map Markers (Nexus mod 938, maintained by LewisElementary),
  used with permission under the mod's compatibility notice.
- Adapter: Kyle, for Conjunction Map Framework.
