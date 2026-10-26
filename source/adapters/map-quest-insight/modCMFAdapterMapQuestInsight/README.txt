Map Quest Insight adapter for Conjunction Map Framework
Version 2.0.0 (for Map Quest Insight 2.0; icons by Wolfer, Map Quest Insight's author)

Brings Map Quest Insight's world map features back on Conjunction Map Framework's
world map. Map Quest Insight stays exactly as its author ships it. Map Quest Insight
normally sends these features to its own map file; this adapter takes what it sends
and hands it to CMF, which draws it.

Version 2.0.0 carries Map Quest Insight 2.0's map: quest icons by type as round
badges or symbols, Sticker icons for the game's markers, the quest info box beside
its marker, Show more in quest boxes, the full-screen map with its faded edges, the
clean corner HUD, and the category panel and map overview that show only when
needed. Each follows Map Quest Insight's own menu setting. Its Quest List comes in a
later update.

It also sends where Map Quest Insight's own map puts a tall info box (beside the
legend or on the right) as its own setting, which CMF 1.6.0 keeps apart from the box
height. Version 1.1.1 tells CMF 1.5.0 or later that the adapter is installed as soon
as the game starts, so CMF's optional adapter check can see it.

REQUIREMENTS
- Conjunction Map Framework 1.6.0 (version 13) or later.
- Map Quest Insight 2.0.0 or later (Nexus mod 14219); 2.0.1 recommended. This
  adapter calls Map Quest Insight's own functions. Without Map Quest Insight, or with
  a version before 2.0, the game stops at the script compile screen.
- On an older CMF or Map Quest Insight 1.6, keep adapter 1.1.1.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Map Quest Insight 2.0 and CMF 1.6.0 are installed.
- Remove this adapter BEFORE removing Map Quest Insight or Conjunction Map Framework.
  If either is removed first, the game stops at the script compile screen until this
  adapter is removed too.
- The adapter writes nothing into saves and changes none of Map Quest Insight's
  settings.

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
- A tall info box where Map Quest Insight's own map puts it: on the right, or at the
  bottom left under the legend when the cursor is on the right half. If another mod
  moves the info box too (Ink and Iron's adapter), CMF's in-game menu decides which
  one does ("Info box moves out of the way").
- "Faster map" and "Zoom out to whole region", with a CMF that has smooth map
  movement (not yet tested in game).
- "Spread stacked quest markers": markers on one spot fan out into a row under the
  cursor and the top quest is selected.
- Quest icons by type (Map Quest Insight 2.0): with "Round quest icons" on, a round
  badge per quest type whose ring takes the level colour, with the type's symbol on
  it, gold on the quest you track; with it off, the symbol alone in the level colour.
  Both follow "Quest marker size".
- Sticker icons for the game's own markers (signposts, shops, places and more) while
  Map Quest Insight's "Map icon style" is Sticker, its default. Vanilla takes them
  away the next time the map opens.
- "Info box beside the marker": a quest marker's box sits beside the marker and never
  covers it.
- "Map category panel" (auto-hide or always shown) and "Map overview" (on, only while
  moving, or off).
- "Show more" in quest boxes: the journal text opens on request, with Show more and
  Show less in Map Quest Insight's words, on the keys you bound to Summon horse
  (keyboard) and Camera lock (controller). With "Remember Show more" on, boxes open
  the way you last left one.
- "Full-screen map": the map runs to the top and bottom of the screen, with soft or
  dark faded edges, or none (Clear).
- "Corner HUD" Clean: the tracked quest's dark boxes go, its text keeps an outline.
- Signposts hidden in the wider set of filter tabs Map Quest Insight 2.0 names.
- No spreading of stacked markers on the fast travel map, as Map Quest Insight 2.0.1.
- "Ultrawide map" and "Side panels position": on a wide screen the map fills the
  screen and the side panels sit where that setting puts them. With "Ultrawide map"
  off the map stays 16:9 with dark sides, as Map Quest Insight's own map does.

KNOWN DIFFERENCES
- With "Spread stacked quest markers" on, the info box still lists the other quests on
  the same spot under ALSO HERE. Map Quest Insight drops that list only with its own map
  file.
- Map Quest Insight 2.0's Quest List (its list of quests beside the map, opened from
  the hint row) is not here yet; it comes in a later adapter update. Its two hint row
  entries ("Quests" and "Change tracked objective") come with it.
- If another CMF pack styles the same pin one by one, the pack whose folder name sorts
  first wins. This adapter counts as Map Quest Insight's folder (modMapQuestInsight).

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterMapQuestInsight. No Script Merger is needed.

CREDITS
Map Quest Insight is by Wolfer. Map Quest Insight's 2.0 map features carried with
permission from Wolfer. The main quest, contract and Gwent quest icons, the Sticker
icons, the round badges and the type symbols are Wolfer's (Map Quest Insight), shipped
in this adapter with their permission. The adapter copies none of Map Quest Insight's
code and only calls functions and reads values it already offers.

Made by Kyle with the help of AI tools (Claude and ChatGPT).
