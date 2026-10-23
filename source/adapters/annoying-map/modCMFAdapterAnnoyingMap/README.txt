Annoying Map adapter for Conjunction Map Framework
Version 1.0.0

Brings back Annoying Map's remembered map on Conjunction Map Framework's world map: the
map opens where you left it, at the zoom you left it, in each region. Annoying Map stays
exactly as its author ships it. Its own map file normally tells its script where the map
is; CMF's map does not, so this adapter passes CMF's report of the map's place and zoom
to Annoying Map's own memory, and asks CMF to open each region at Annoying Map's saved
zoom.

REQUIREMENTS
- Conjunction Map Framework 1.3.0 or later (API revision 9). With an earlier CMF the
  game stops at the script compile screen; update CMF first.
- Annoying Map 3.1 for Remastered 5.01 (Nexus mod 6140, folder modAnnoyingMap),
  installed as its author describes. This adapter calls Annoying Map's own functions.
  Without it the game stops at the script compile screen. Other Annoying Map versions
  are not checked.
- CMF must load before Annoying Map (CMF's folder name sorts first on its own; if you use
  a load order, keep CMF first). Annoying Map's own map file then stays installed and
  simply does not load.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Annoying Map 3.1 and CMF are installed.
- Remove this adapter BEFORE removing Annoying Map or Conjunction Map Framework. If either
  is removed first, the game stops at the script compile screen until this adapter is
  removed too.
- The adapter writes nothing of its own into saves. Annoying Map itself keeps the
  remembered place and zoom in every save made while it is installed, as before.

WHAT YOU SEE
- Close the map and open it again: it opens at the same place and zoom, per region, as
  with Annoying Map on its own. Velen and Novigrad share one memory, as in Annoying Map.
- The zoom keys always reach the full zoom range. Without this adapter, a region that
  already had a remembered zoom could stay stuck at that zoom under CMF.
- Geralt's marker, Roach and the boat showing only at signposts, and herbs never showing,
  are Annoying Map's own and work beside CMF without this adapter. It changes nothing
  there.
- With CMF's in-game menu add-on, Annoying Map is listed by its name on the Opening view
  row under Movement. Setting that row to Vanilla opens each region at the game's own
  zoom; Annoying Map still sets the remembered place itself.

KNOWN DIFFERENCES AND LIMITS
- The view is remembered when the map stops moving, when you switch region and when you
  close the map, not at every step of a pan. The result is the same place.
- An opening that asks for one spot, such as "show on map" from the quest list, opens at
  the game's own zoom, where Annoying Map on its own would use the remembered zoom.
- This adapter counts as Annoying Map's folder (modAnnoyingMap) when CMF decides which
  mod's opening view wins. A mod earlier in CMF's provider order that also sets an
  opening view wins over it.

CHANGES
- 1.0.0: first release.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterAnnoyingMap. No Script Merger is needed.

CREDITS
Annoying Map is by crthdr; this adapter copies none of its code or art. It only writes
the map's place and zoom into the memory Annoying Map already keeps (AMap, AMapZoom,
AM_FilterArea) and calls the event Annoying Map already has for the zoom limits
(OnZoomMap).
