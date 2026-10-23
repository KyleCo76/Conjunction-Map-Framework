Ink and Iron adapter for Conjunction Map Framework
Version 1.2.0 (carries Ink and Iron's world overview and controller button art, with its
author's permission)

With Conjunction Map Framework installed, CMF's world map replaces Ink and Iron's
world map; Ink and Iron's HUD, compass and menus load as normal. This adapter brings
Ink and Iron's map back on CMF's map: its look, its quest-level tags, its key-hint
row, the way its map moves, its gold controller buttons, and the engraved world
overview of its optional World Map file. Ink and Iron stays exactly as its author ships it.

REQUIREMENTS
- Conjunction Map Framework 1.3.0 (version 9) or later. On an older CMF the game
  stops at the script compile screen: keep adapter 1.1.0 until you update CMF.
- Ink and Iron 0.8.7 to 0.9.0: the All In One file (its modInkAndIron folder) or
  the separate modInkAndIronUI folder. The parts this adapter uses are the same in
  each. This adapter calls Ink and Iron's own functions: without Ink and Iron the
  game stops at the script compile screen.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Ink and Iron and CMF 1.3.0 are installed.
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
- Ink and Iron 0.8.10's info box: framed on every map, and on the region and interior
  maps a long box (a long quest text) gets a darker backing and moves beside the
  cursor, clear of the legend, the quest card and the other panels.
- With Ink and Iron's option "Quest levels on world map pins" on, quest pins show
  Ink and Iron's "Lv N" tag, coloured by difficulty, on its dark plate. With the
  option off, nothing is added.
- Ink and Iron's key-hint row at the bottom of the map. It only shows the keys; the
  game's menu still handles every key.
- With a controller: Ink and Iron's gold-outlined button pictures in the map's
  button row, for every controller type the game supports.
- Ink and Iron's map movement: holding W A S D (or a stick) glides the map evenly at
  any frame rate, zoom with Z and C keeps the game's pace, and the map's animations
  run at 60 frames a second.

INK AND IRON'S WORLD MAP FILE (OPTIONAL)
Ink and Iron's optional World Map file repaints the world overview (press Space on
the map) as an engraving, with engraved region crests. With CMF that file cannot
load, because CMF's map takes its place, so this adapter carries the same pictures.
The game cannot tell whether you installed that optional file, so the pictures show
only when you pick them:
- With CMF's in-game menu add-on: Options > Mods > Conjunction Map Framework, set
  "World overview" and "Region crests and markers" to Ink and Iron.
- Without it: close the game, open Documents\The Witcher 3\dx12user.settings and
  add these two lines under [CMFSettings]:
    CMFFile_Painting_World=modInkAndIronUI
    CMFFile_Painting_Crests=modInkAndIronUI
If you do not use the World Map file, change nothing: you keep the game's painted
overview, exactly as Ink and Iron shows it without CMF.

TWO SMALL DIFFERENCES, ON PURPOSE
- Ink and Iron's own map cuts a long region name short ("VELEN - NO"). Here the
  whole name shows ("VELEN - NO MAN'S LAND").
- The legend's frame always holds every row it shows.

KNOWN LIMITS
- If another CMF pack styles the same part of the map, the pack whose folder name
  sorts first wins. This adapter counts as Ink and Iron's folder (modInkAndIronUI,
  for either folder name), and CMF's in-game menu lists it as "Ink and Iron".
  For the map's movement each setting is decided on its own the same way, so with
  another smooth-map mod installed, the settings Ink and Iron does not decide (for
  example how fast the map opens) can come from that mod.
- The controller crosshair and the button pictures have not been tried with a real
  controller.
- With Ink and Iron 0.8.9 or earlier the info box is framed on the region and interior
  maps too, as Ink and Iron 0.8.10 does.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterInkAndIron. No Script Merger is needed.

CREDITS
Ink and Iron is by WinterElfeas. The world overview painting and the seven region
crests (from Ink and Iron's World Map file 0.9.0) and the gold controller button
pictures (from its All In One file 0.9.0) in this adapter are WinterElfeas's art,
carried unchanged with the author's permission. The adapter copies none of
Ink and Iron's code: it calls functions and reads values Ink and Iron already offers.
