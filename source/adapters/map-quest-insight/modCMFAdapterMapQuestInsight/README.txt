Map Quest Insight adapter for Conjunction Map Framework
Version 1.1.0 (quest icons by Wolfer, Map Quest Insight's author)

Brings Map Quest Insight's world map features back on Conjunction Map Framework's
world map. Map Quest Insight stays exactly as its author ships it. Map Quest Insight
normally sends these features to its own map file; this adapter takes what it sends
and hands it to CMF, which draws it.

REQUIREMENTS
- Conjunction Map Framework version 6 with stacked-pin spreading, or later.
  The Ultrawide map setting needs CMF 1.4.1 (version 10) or later.
- Map Quest Insight 1.6.1 or later (Nexus mod 14219), installed as its author
  describes. This adapter calls Map Quest Insight's own functions. Without Map Quest
  Insight, or with a version before 1.6, the game stops at the script compile screen.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Map Quest Insight 1.6.1 and CMF 6 are installed.
- Remove this adapter BEFORE removing Map Quest Insight or Conjunction Map Framework.
  If either is removed first, the game stops at the script compile screen until this
  adapter is removed too.
- The adapter writes nothing into saves.

WHAT YOU SEE
All of it follows Map Quest Insight's own menu settings:
- Quest and signpost icon sizes.
- Quest icons by type: treasure hunts, horse races, boat races, fist fights, knights
  errant and wine contracts use the game's own icons for them; main quests, contracts
  and Gwent quests use Map Quest Insight's own icons, by its author.
- The "Lv N" text above quest pins and the signpost names, in Map Quest Insight's
  colours, at its heights.
- Level colours on the icons of quests you do not track.
- The crosshair label switch, and signpost names hidden where Map Quest Insight
  hides them.
- Signposts hidden in the filter tabs Map Quest Insight's options name.
- The scrolling info box at Map Quest Insight's "Info box height".
- "Faster map" and "Zoom out to whole region", with a CMF that has smooth map
  movement (not yet tested in game).
- "Spread stacked quest markers": markers on one spot fan out into a row under the
  cursor and the top quest is selected.
- "Ultrawide map" and "Side panels position" (Map Quest Insight 1.6.2 or later): on a
  wide screen the map fills the screen and the side panels sit where that setting
  puts them. With "Ultrawide map" off the map stays 16:9 with dark sides, as Map
  Quest Insight's own map does. Needs CMF 1.4.1; with 1.6.1, which has no such
  setting, CMF fills wide screens its own way.

KNOWN DIFFERENCES
- With "Spread stacked quest markers" on, the info box still lists the other quests on
  the same spot under ALSO HERE. Map Quest Insight drops that list only with its own map
  file.
- If another CMF pack styles the same pin one by one, the pack whose folder name sorts
  first wins. This adapter counts as Map Quest Insight's folder (modMapQuestInsight).

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterMapQuestInsight. No Script Merger is needed.

CREDITS
Map Quest Insight is by Wolfer. The main quest, contract and Gwent quest icons are
Wolfer's, shipped in this adapter with their permission. The adapter copies none of
Map Quest Insight's code and only calls functions and reads values it already offers.
