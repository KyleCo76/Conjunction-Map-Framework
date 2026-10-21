Witcher Gear Map adapter for Conjunction Map Framework
Version 0.2 (proof of concept with placeholder art; built with tools/cmf_pack.py)

Shows Witcher Upgrade Gear Map's diagram markers on Conjunction Map Framework's world
map. Gear Map stays exactly as its author ships it. This adapter only tells CMF what
to draw for the marker types Gear Map already uses.

REQUIREMENTS
- Conjunction Map Framework version 1 or later.
- Witcher Upgrade Gear Map 1.0.1 (Nexus mod 14157), installed as its author describes.
  Install and remove the adapter together with it: the adapter calls Gear Map's own
  scripts, so the game stops at the script compile screen without Gear Map.

WHAT YOU SEE
- Gear markers use placeholder art: a white diagram sheet while a diagram is missing,
  a grey one once every diagram at that spot is learned.
- With Gear Map's "School colour" icon styles the sheet is coloured by school, and
  "with circle" adds a ring.
- Tooltips, titles, location hints and Gear Map's options work as before; they come
  from Gear Map's own scripts.
- With CMF 2 or later: Gear Map's own "Witcher Gear" filter tab after the game's tabs,
  holding the Witcher Gear row, which is also listed under Default and All and is named
  "Witcher Gear". Both names are Gear Map's own text.

PIN TYPES THIS ADAPTER CHANGES
- WitcherGear and WitcherGearObtained, each also with a school name (Cat, Griffin,
  Bear, Wolf, Viper, Manticore) and with Ring at the end: 26 types in all, the names
  Gear Map gives its markers. Icons for all 26, school tints for the 24 school types.
If another CMF pack changes the same type, the pack whose folder name sorts first wins.
This adapter counts as Gear Map's folder (modWitcherGearMap).

KNOWN LIMITS
- Under CMF 1 there is no "Witcher Gear" filter tab. The markers are listed in the
  legend under All, in a row named after the first marker's title.
- The legend row shows the plain sheet whatever Gear Map's icon style is.
- The art is a placeholder until Gear Map's author supplies theirs.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterWitcherGearMap. No Script Merger is needed.
Gear Map's own folder can stay installed; CMF's map loads instead of Gear Map's map.

UNINSTALL
Remove this adapter BEFORE removing Conjunction Map Framework. If CMF is removed first,
the game stops at the script compile screen until this adapter is removed too.
The adapter writes nothing into saves.

CREDITS
Witcher Upgrade Gear Map is by its own author (CC BY-NC-SA 4.0); this adapter copies
none of its code or art and only uses the marker type names it already sends.
Placeholder art drawn by CMF's own tooling (tools/cmf_gear_adapter_art.py).
