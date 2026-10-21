Witcher's Path adapter for Conjunction Map Framework
Version 0.1 (run in game on 2026-10-20 with Witcher's Path 1.0.3)

Brings Witcher's Path's route back on Conjunction Map Framework's world map.
Witcher's Path stays exactly as its author ships it: it keeps recording where you
travel and keeps sending the route of the region you look at. This adapter only
tells CMF how to draw what Witcher's Path sends, and hands its two buttons back to
Witcher's Path's own script.

REQUIREMENTS
- Conjunction Map Framework version 6 or later, with drawing on the map itself.
  On an older CMF the adapter draws nothing and the route stays missing.
- Witcher's Path 1.0.3 (Nexus mod 13423), installed as its author describes.
  This adapter calls Witcher's Path's own functions. Without Witcher's Path the
  game stops at the script compile screen.

WHAT YOU SEE
- The last filter tab, WITCHER'S PATH (click the arrows beside the tab name at the
  bottom left). On it the map shows no pins, only Geralt, and the route you
  travelled in this region, one colour per way of travel (on foot, horse, boat) or
  one colour for all. The line keeps the same width at every zoom.
- Above the tab name, four boxes, as Witcher's Path draws them: "Erase path", the
  distance travelled in this region and in total, the "Single color" switch and
  the colour legend (only while single colour is off).
- "Erase path" opens Witcher's Path's own question; answering yes erases this
  region's route, as without CMF. "Single color" switches the colours at once and
  Witcher's Path keeps your choice in your save. Both are mouse only, as in
  Witcher's Path.
- Line width and colours come from Witcher's Path's own settings in Options > Mods.
  A change shows the next time you open the map.

DRAWINGS THIS ADAPTER MAKES
- One route line on the map itself, above the map picture and below every pin.
- Four boxes above the filter tab name, shown only on the WITCHER'S PATH tab.
If another CMF mod draws on the map itself, the route sits above drawings with a
lower order number (the route uses 10), then the mod whose folder name sorts first
is on top. This adapter counts as Witcher's Path's folder (modWitchersPath).

KNOWN LIMITS
- Witcher's Path's speed setting (perf) does nothing under CMF; CMF draws the
  line in its own way.
- The WITCHER'S PATH tab comes after other mods' CMF tabs, and the map never
  reopens on it.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterWitchersPath. No Script Merger is needed.
Witcher's Path's own folder stays installed; CMF's map loads instead of its map.

UNINSTALL
Remove this adapter BEFORE removing Conjunction Map Framework or Witcher's Path.
If either is removed first, the game stops at the script compile screen until this
adapter is removed too.
The adapter writes nothing into saves. Your recorded routes stay in Witcher's
Path's own save data, as without CMF.

WHEN WITCHER'S PATH SHIPS ITS OWN CMF SUPPORT
This adapter is for Witcher's Path 1.0.3, which has no CMF support of its own.
When Witcher's Path ships its own CMF support, uninstall this adapter. Do not
keep both: the two are not meant to run together, and with both installed the
game may stop at the script compile screen. Removing the adapter fixes it.

CREDITS
Witcher's Path is by its own author; this adapter copies none of its code and
ships no art. It uses Witcher's Path's own functions, settings, texts, storage
key, and its boxes' sizes and colours.
