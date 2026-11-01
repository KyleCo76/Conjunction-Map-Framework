Fog of War adapter for Conjunction Map Framework
Version 1.1.2 (script only, no art; needs CMF 1.7.0 or later)

Makes Fog of War hide every map icon under its fog on Conjunction Map Framework's world
map, including the icons other mods add, such as Witcher Gear Map's diagram markers
and Gwent Players Map's cards. Fog of War stays exactly as its author ships it. This
adapter asks Fog of War's own fog rule which icons belong under the fog, using Fog of
War's own settings, and tells CMF to hide them. The icons Fog of War chose to show
(your tracked quest, known signposts and so on) stay.

It also draws the fog itself on CMF's map, as Fog of War's "cloud textures off" look:
unexplored land is dark, with a soft edge around what you have explored. It follows
Fog of War's colour, opacity and edge settings, and disappears when Fog of War is
switched off.

WHAT CHANGED
- 1.1.2: with CMF 1.8.0 or later, the first map opening after loading a save is
  covered dark until the fog is drawn, as every later opening already was. This
  readme now lists the versions that were actually released.
- 1.1.1: draws the dark fog cover on CMF's map; hides the icons other mods add after
  Fog of War has decided (Gwent Players Map's cards); hides icons under the fog also
  when The Stable (in Ard Dhu Stable) is installed. Needs CMF 1.7.0 or later; with an
  older CMF keep 1.0.2.
- 1.0.2: writes less to the game's log: one line per map, none per icon.
- 1.0.1: tells CMF 1.5.0 or later that the adapter is installed as soon as the game
  starts, so CMF's optional adapter check can see it.

REQUIREMENTS
- Conjunction Map Framework 1.7.0 or later (API version 14).
- Fog of War 1.2.1 (Nexus mod 13627), installed as its author describes. This adapter
  calls Fog of War's own functions. Without Fog of War 1.2.1 the game stops at the
  script compile screen. Other Fog of War versions are not checked.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Fog of War 1.2.1 and Conjunction Map Framework are
  installed.
- Remove this adapter BEFORE removing Fog of War or Conjunction Map Framework. If either
  is removed first, the game stops at the script compile screen until this adapter is
  removed too.
- The adapter writes nothing into saves. Fog of War itself stores your explored areas in
  every save made while it is installed (see Fog of War's own readme).

WHAT YOU SEE
- Icons other mods add to the map follow Fog of War's fog like the game's own icons: they
  stay hidden until you explore near them.
- Everything Fog of War keeps visible stays visible: your position and your own markers,
  the tracked quest (if Fog of War's menu says so), signposts you know, and what the game
  told you about (Fog of War's "In-world hints" option).
- Hidden icons are gone from the map, the legend counts, the filter lists and the corner
  overview, as with Fog of War on its own.
- Turning Fog of War off in its menu turns this off too.

KNOWN LIMITS
- Fog of War's cloud textures do not draw on Conjunction Map Framework's map; the
  adapter draws the plain dark cover instead, as Fog of War's "cloud textures off" look.
- The round HUD minimap is not covered, as with Fog of War on its own.
- Icons a mod adds after the map has built its icon list (none known) are not covered.
- This adapter counts as Fog of War's folder (modFogOfWar) when CMF decides which
  mod's choice wins.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterFogOfWar. No Script Merger is needed.

CREDITS
Fog of War is by its own author; this adapter copies none of its code and only calls
the functions it already offers (FogOfWarEnabled, FogOfWarFilterPins).
