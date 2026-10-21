CMF Example Icon Pack for Conjunction Map Framework
Version 0.2 (example for pack authors; built with tools/cmf_pack.py)

Gives innkeepers a mug icon (a purple version in the map legend), gives armorers a
shield icon, tints the stock herbalist icon lime green, and marks cleared bandit camps
and monster nests with a grey tick.

REQUIREMENTS
- Conjunction Map Framework version 1 or later.

PIN TYPES THIS PACK CHANGES
- Innkeeper: new icon, separate legend icon
- Armorer: new icon
- Herbalist: tint (0x40FF40)
- BanditCampDisabled, BanditCampfireDisabled, MonsterNestDisabled (cleared camps and nests): grey tick icon
If another CMF icon pack changes the same pin type, the pack whose folder name sorts
first alphabetically wins. Rename a pack's folder to change which one wins.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. The pack lands in Mods\modCMFExampleIconPack. No Script Merger is needed.

UNINSTALL
Remove this pack BEFORE removing Conjunction Map Framework. If CMF is removed first,
the game stops at the script compile screen until this pack is removed too.
The pack writes nothing into saves; removing it restores the original icons.

COMPATIBILITY
Works alongside any other CMF icon pack or CMF-based map mod: Conjunction Map Framework
is the single world map they all work through. When a map mod still ships its own copy
of the map, the game loads CMF's map instead, so that mod's own map-screen features do
not show until it is ported to CMF; its scripts and menus keep working. Do not give
such a mod a lower Priority than CMF in mods.settings unless you mean to switch CMF's
map off; this pack's icons would then disappear.

CREDITS
Art drawn by CMF's own tooling (tools/cmf_example_art.py).
