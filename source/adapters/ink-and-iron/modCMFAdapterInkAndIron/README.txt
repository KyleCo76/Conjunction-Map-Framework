Ink and Iron adapter for Conjunction Map Framework
Version 0.3 (script only, no art)

With Conjunction Map Framework installed, CMF's world map replaces Ink and Iron's
world map; Ink and Iron's HUD, compass and menus load as normal. This adapter brings
Ink and Iron's map back on CMF's map: its look, its quest-level tags, its key-hint
row and the way its map moves. Ink and Iron stays exactly as its author ships it.

REQUIREMENTS
- Conjunction Map Framework version 5 or later. Ink and Iron's map movement needs
  version 6; on version 5 everything else works and the map moves as the game's does.
- Ink and Iron AIO 0.8.8, with its modInkAndIronUI folder installed (0.8.7 works
  too: its map file and the parts this adapter uses are the same).
  This adapter calls Ink and Iron's own functions. Without modInkAndIronUI the game
  stops at the script compile screen.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Ink and Iron and CMF 5 are installed.
- Remove this adapter BEFORE removing Ink and Iron or Conjunction Map Framework.
  If either is removed first, the game stops at the script compile screen until this
  adapter is removed too.
- The adapter writes nothing into saves.
- When Ink and Iron ships its own Conjunction Map Framework support, uninstall this
  adapter. With both installed, the game stops at the script compile screen; removing
  this adapter fixes it.

WHAT YOU SEE
- Ink and Iron's map look: the full-height map over its ink backdrop with the soft
  edge, its framed quest tracker and legend, its region title with the gold diamond,
  its corner overview frame, gold key letters, and its legend colours.
- With Ink and Iron's option "Quest levels on world map pins" on, quest pins show
  Ink and Iron's "Lv N" tag, coloured by difficulty, on its dark plate. With the
  option off, nothing is added.
- Ink and Iron's key-hint row at the bottom of the map. It only shows the keys; the
  game's menu still handles every key.
- Ink and Iron's map movement: holding W A S D (or a stick) glides the map evenly at
  any frame rate, zoom with Z and C keeps the game's pace, and the map's animations
  run at 60 frames a second.

TWO SMALL DIFFERENCES, ON PURPOSE
- Ink and Iron's own map cuts a long region name short ("VELEN - NO"). Here the
  whole name shows ("VELEN - NO MAN'S LAND").
- The legend's frame always holds every row it shows.

KNOWN LIMITS
- If another CMF pack styles the same part of the map, the pack whose folder name
  sorts first wins. This adapter counts as Ink and Iron's folder (modInkAndIronUI).
  For the map's movement each setting is decided on its own the same way, so with
  another smooth-map mod installed, the settings Ink and Iron does not decide (for
  example how fast the map opens) can come from that mod.
- The controller crosshair has not been tried: no test so far used a controller.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterInkAndIron. No Script Merger is needed.

CREDITS
Ink and Iron is by its own author; this adapter copies none of its code or art and
only calls functions and reads values it already offers.
