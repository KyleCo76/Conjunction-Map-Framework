Map Quest Insight adapter for Conjunction Map Framework
Version 2.5.4 (for Map Quest Insight 2.1.0 and 2.2.0; icons by Wolfer, Map Quest Insight's author)

What is new in 2.5.4: with CMF 1.12.0 (API 18) the info box beside a quest marker also moves to
the nearest clear spot when its place would cover the Quest List or a map panel. Older CMF keeps the
2.5.3 behaviour.

In 2.5.3: the Quest List now follows the tracked quest and objective when they
change any other way (a map pin, the change-objective key); it is sent once more after the
map's pin build.

In 2.5.2: in the Quest List a mouse click on a quest row's Objectives prompt shows
or hides its objectives (as Right does) and a click on a section's fold prompt folds it (as C
does). Neither click tracks the quest or swaps its objective; every other click is as before.
Only this region now saves the setting and refills the list without redrawing the map's markers,
as Map Quest Insight's own button does.

In 2.5.1: the Quest Filters rows follow Map Quest Insight's order and use
Wolfer's glyphs (Wolfer is Map Quest Insight's author; the symbols are his). Colours,
sizes and rows are read from Map Quest Insight's own file values. "[F] Quests" uses the
game's own word. Saving in the Quest List reloads Map Quest Insight's settings. On an
ultrawide screen the Quest List corner follows Map Quest Insight's own "Quest list
corner" setting (21:9 / 32:9). The adapter detects Map Quest Insight's next update.
A filter row changes the markers on the map at once, and Quests Available follows the
filters. The list's key row and its prompts use the game's own button pictures, on
keyboard and controller, and switch when you change between them (needs CMF 1.10.0;
an older CMF shows text keys such as "[F] Close"). D-pad Right (Right on the keyboard)
shows or hides a quest's objectives, as in Map Quest Insight, and the Objectives
prompt shows that button. The highlight keeps its row when a filter or the sort
changes, the legend stays hidden while the list is open, and The Heroes' Pursuits
row has its symbol.

Brings Map Quest Insight's world map features back on Conjunction Map Framework's
world map. Map Quest Insight stays exactly as its author ships it. Map Quest Insight
normally sends these features to its own map file; this adapter takes what it sends
and hands it to CMF, which draws it.

Version 2.0.0 carries Map Quest Insight 2.0's map: quest icons by type as round
badges or symbols, Sticker icons for the game's markers, the quest info box beside
its marker, Show more in quest boxes, the full-screen map with its faded edges, the
clean corner HUD, and the category panel and map overview that show only when
needed. Version 2.1.0 adds Map Quest Insight's Quest List on the map, with its
"Quests" and "Change tracked objective" key hints. Version 2.2.0 follows Map Quest
Insight 2.1.0's Quest List: a Gwent section, Quests Available, Start quest sections
folded, Show objectives on highlight, Swap Obj, Current Level and the region count.
Each follows Map Quest Insight's own menu setting.

It also sends where Map Quest Insight's own map puts a tall info box (beside the
legend or on the right) as its own setting, which CMF 1.6.0 keeps apart from the box
height. Version 1.1.1 tells CMF 1.5.0 or later that the adapter is installed as soon
as the game starts, so CMF's Status page can see it.

REQUIREMENTS
- Conjunction Map Framework 1.6.0 (version 13) or later.
- Map Quest Insight 2.1.0 or later (Nexus mod 14219). This adapter calls Map Quest
  Insight's own functions. Without Map Quest Insight, or with a version before 2.1.0,
  the game stops at the script compile screen.
- On Map Quest Insight 2.0.1 keep adapter 2.1.0, on 2.0.0 adapter 2.0.0; on an older
  CMF or Map Quest Insight 1.6, keep adapter 1.1.1.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while Map Quest Insight (2.1.0 or later) and CMF 1.6.0 or later are installed.
- Remove this adapter BEFORE removing Map Quest Insight or Conjunction Map Framework.
  If either is removed first, the game stops at the script compile screen until this
  adapter is removed too.
- The adapter writes nothing into saves. It changes Map Quest Insight's settings
  only from the Quest List's own rows ("Only this region" and the "Show on the map"
  switches), the same settings Map Quest Insight's own list changes.

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
  dark faded edges, or none (Clear). From 2.3.0, with CMF API 14 or later, no dark
  bars stay under the tabs and the button hints, and the fades look as on Map Quest
  Insight's own map.
- "Corner HUD" Clean: as in Map Quest Insight 2.2.0 alone, the tracked quest's dark boxes, its key row and their plates go, the quest name sits level with the region title, and a small "[F] Quests" box under the title opens the Quest List when clicked; its text keeps Wolfer's outline, and with CMF API 16 or later the soft third glow is added. Game look shows none of this.
- Signposts hidden in the wider set of filter tabs Map Quest Insight 2.0 names.
- No spreading of stacked markers on the fast travel map, as Map Quest Insight 2.0.1.
- "Ultrawide map" and "Side panels position": on a wide screen the map fills the
  screen and the side panels sit where that setting puts them. With "Ultrawide map"
  off the map stays 16:9 with dark sides, as Map Quest Insight's own map does.
  From 2.4.0 this also follows Map Quest Insight 2.2.0, where both settings moved to
  its General page and "Map side panels position" became 16:9, 21:9 or 32:9: the
  panels sit at the edges of a centred area of that shape, never past the screen.
- The Quest List (2.1.0), with "Quest list on the map" on: press F (LT on a controller) or click
  "Quests" in the key hints. It lists your active quests by category, the tracked one
  first, with type icon, level, name in its difficulty colour, region and distance.
  Up/Down choose, E or Enter track, H switches "Only this region", J opens the
  journal, T sorts, C folds a section, F or Esc closes. Click to pick, double click
  to track. From 2.5.0 the list is laid out as in Map Quest Insight 2.2.0 alone: it
  takes the whole left edge of the screen (the region title, the legend and the
  game's top bar with your level, crowns and the menu tabs are hidden while it is
  open; with a CMF older than 1.9.0 they stay), its keys sit just above the game's
  key hints, and it has a title block (QUEST LIST, the
  region and your active quests, the sort, your level, "Only this region: On/Off"),
  sections with a coloured stripe (Main Quests, Secondary Quests, Quests Available and
  Quest Filters, each with its count and a fold arrow), rows 90 high with the quest's
  objectives under the highlighted one, and the keys F, E, H and T along the bottom. From 2.2.0, as in Map Quest Insight 2.1.0: Gwent quests have their own
  section after Treasure hunts; objective lines are not selected and an open list
  closes when you move to another quest; on the tracked quest, E again, a second
  click or a double click swaps to its next objective not done yet (Swap Obj); the
  top right shows "Region: n/t active quests". It follows "Start quest sections
  folded". With "Quests not started yet" on, a
  Quests Available section (folded at first) lists the quests you have not started:
  highlighting a row moves the map to its "!" marker, E or a click on it puts a custom
  map marker there, and the header shows your level. Picking a quest rings its markers and centres on them; a quest in another
  region switches the map, as "Quests in other regions" says. "Only this region" and
  the "Show on the map" rows sit in the Quest Filters section (folded at first). It follows "Sort quests
  by", "Quest list text size", "Centre the map on the picked quest", "Map when the
  list closes", "Distance", "Region under quest names", "Names in difficulty colour"
  and "DLC name after quest names".
- "Change tracked objective" (G, R2 on a controller) in the key hints while
  "Corner HUD" is Clean.

KNOWN DIFFERENCES
- With "Spread stacked quest markers" on, the info box still lists the other quests on
  the same spot under ALSO HERE. Map Quest Insight drops that list only with its own map
  file.
- With CMF 1.6.1 or 1.6.2 the two key hints are drawn over the game's own key hint
  row unless another mod (Ink and Iron) hides that row. CMF 1.6.3 adds them to the
  game's row instead.
- While the Quest List is open it takes the keyboard: with "Move the map with the
  list open" on, the map moves with the mouse only.
- A filter row ("Show on the map") changes the list and, from 2.5.1, the map markers at
  once (the game's own pin build runs again on the open map).
- A short click on a quest marker does not track it; hold to track, as in the game.
- The Quest List hides the region title, the legend and the game's top bar while it
  is open, as Map Quest Insight's own list does; with a CMF older than 1.9.0 (API 16)
  they cannot be hidden and stay on screen. Esc closes the list first, then the map,
  as in Map Quest Insight. The stripe colours of the sections are estimates.
- If another CMF pack styles the same pin one by one, the pack whose folder name sorts
  first wins. This adapter counts as Map Quest Insight's folder (modMapQuestInsight).

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterMapQuestInsight. No Script Merger is needed.

CREDITS
Map Quest Insight is by Wolfer. Map Quest Insight's 2.0 map features carried with
permission from Wolfer. The Quest List is the adapter's own code, following Map
Quest Insight's settings. The main quest, contract and Gwent quest icons, the Sticker
icons, the round badges and the type symbols are Wolfer's (Map Quest Insight), shipped
in this adapter with their permission. The adapter copies none of Map Quest Insight's
code and only calls functions and reads values it already offers.

Made by Kyle with the help of AI tools (Claude and ChatGPT).
