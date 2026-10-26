All Quest Objectives adapter for Conjunction Map Framework
Version 1.2.0

Brings back three of All Quest Objectives' map features on Conjunction Map Framework's
world map: the difficulty icons on untracked quest objectives, their own legend row,
and removing cached merchant pins. All Quest Objectives stays exactly as its author
ships it. Its own map file normally draws the icons and the row and reports the click;
CMF's map does none of that by itself, so this adapter tells CMF what to draw, which
row to list and which pins take the click, and hands each click back to All Quest
Objectives.

REQUIREMENTS
- Conjunction Map Framework 1.2.0 or later. With an earlier CMF the game stops at the
  script compile screen; update CMF first, or keep adapter 1.0.0.
- All Quest Objectives On Map - Remastered 1.2.1 (Nexus mod 14319), installed as its
  author describes. This adapter calls All Quest Objectives' own functions. Without
  it the game stops at the script compile screen. Other versions are not checked.

INSTALL AND REMOVE THEM TOGETHER
- Install this adapter only while All Quest Objectives 1.2.1 and CMF 1.2.0 or later are
  installed.
- Remove this adapter BEFORE removing All Quest Objectives or Conjunction Map
  Framework. If either is removed first, the game stops at the script compile screen
  until this adapter is removed too.
- The adapter writes nothing into saves. All Quest Objectives itself keeps its list of
  merchants in every save made while it is installed (see its own readme).

WHAT YOU SEE
- Objectives of quests you do not follow show a round badge with an exclamation mark,
  coloured by the quest's suggested level against yours, as All Quest Objectives
  chooses: grey (low), green (normal), orange (high), red (deadly). Quests without a
  level and the quest you follow keep the game's icons. If you changed All Quest
  Objectives' icon settings in its script, its other colours and its bare
  exclamation marks show too.
- In the legend's Quests tab, objectives of quests you do not follow have their own
  row, "All Quest Objectives", as with All Quest Objectives on its own. Hiding it hides
  only those objectives; the quest you follow and the other quest rows stay.
- A grey "[CACHED]" merchant pin works as with All Quest Objectives on its own: select
  it and press E (or Enter, or double-click it) once and the message "Select again the
  same cached pin to remove it." appears; do it again and "Merchant pin removed." shows
  and the pin goes. Reopening the map starts over, as before.
- Signposts, quests and every other pin keep the game's own use.
- With The Stable installed too, all of the above still shows. The Stable replaces the
  part of the game's map code where All Quest Objectives adds its icons, levels and
  cached merchants, so on its own All Quest Objectives shows none of them alongside
  The Stable; this adapter asks All Quest Objectives to add them a moment later, only
  when it did not run.
- With CMF's in-game menu add-on, All Quest Objectives is listed by its name, "All Quest
  Objectives", once a save is loaded. At the title screen, before any save is loaded,
  the menu still shows its folder name tidied ("AQOOMRemastered"). The name changes
  nothing on the map.

KNOWN DIFFERENCES AND LIMITS
- The badge and the exclamation mark are this adapter's own placeholder drawings in
  All Quest Objectives' colours, not its own art, which lives inside its own map file
  and cannot be loaded by CMF.
- Gamepad A and touch taps run the same code as E and the mouse, but neither has been
  tried.
- This adapter counts as All Quest Objectives' folder (modAQOOMRemastered) when CMF
  decides which mod's choice wins. Its choices are made pin by pin, so they win over
  any mod that changes a whole pin type or one tag. If Map Quest Insight's adapter is
  installed too, this one's icons win on the pins both change.

CHANGES
- 1.2.0: All Quest Objectives' icons, levels and cached merchant pins show with The
  Stable installed too. Needs CMF 1.2.0 or later, as before.
- 1.1.0: names All Quest Objectives in CMF's in-game menu ("All Quest Objectives"
  instead of "AQOOMRemastered"). Needs CMF 1.2.0 or later. Nothing else changed.
- 1.0.0: first release.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterAllQuestObjectives. No Script Merger is needed.

CREDITS
All Quest Objectives On Map - Remastered is by its own author; this adapter copies none
of its code or art. It only reads the icon names the mod writes on its pins and calls
the functions it already offers (AqoomGetMap, UpdateEntityPins, IsCachedPinUse,
OnCachedPinUsed).
