Gwent Players Map adapter for Conjunction Map Framework
Version 1.0.1 (card art by MateusAnd, Gwent Players Map's author; built with
tools/cmf_pack.py)

Shows Gwent Players Map's card markers on Conjunction Map Framework's world map.
Gwent Players Map stays exactly as its author ships it. This adapter only tells CMF
what to draw for the marker types Gwent Players Map already uses.

REQUIREMENTS
- Conjunction Map Framework version 2 or later.
- Gwent Players Map 1.0.9 (Nexus mod 13755), installed as its author describes.
  This adapter calls Gwent Players Map's own filter event. Without Gwent Players Map
  the game stops at the script compile screen.

WHAT YOU SEE
- Gwent player markers use the card art of Gwent Players Map's author: a white card
  while a player is not beaten yet, a grey one once beaten or no longer available.
- Gwent Players Map's own "Gwent" filter tab after the game's tabs, holding the
  "Gwent player" row, which is also listed under Default and All. Both names are
  Gwent Players Map's own text.
- In the "Gwent" tab the cards stand where the players stand; in the other tabs a
  merchant's card sits next to the shop icon. This is Gwent Players Map's own
  behaviour; this adapter passes CMF's tab report on to Gwent Players Map.
- Tooltips, beaten and not-beaten status and Gwent Players Map's options work as
  before; they come from Gwent Players Map's own scripts.
- With the "Card size" option on Large, the cards are drawn larger, at the size
  Gwent Players Map's own map uses (needs CMF 4 or later).

PIN TYPES THIS ADAPTER CHANGES
- GwentPlayer, GwentPlayerDisabled, GwentPlayerLarge and GwentPlayerLargeDisabled,
  the names Gwent Players Map gives its markers.
If another CMF pack changes the same type, the pack whose folder name sorts first wins.
This adapter counts as Gwent Players Map's folder (modGwentPlayersMap).

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterGwentPlayersMap. No Script Merger is needed.
Gwent Players Map's own folder can stay installed; CMF's map loads instead of its map.

UNINSTALL
Remove this adapter BEFORE removing Conjunction Map Framework or Gwent Players Map. If
either is removed first, the game stops at the script compile screen until this adapter
is removed too.
The adapter writes nothing into saves.

CREDITS
Gwent Players Map is by MateusAnd. The card art is MateusAnd's, shipped in this adapter
with their permission. The adapter copies none of Gwent Players Map's code and only uses
the marker type names, tab id and string keys it already ships.
Thanks to MateusAnd for testing the adapter on Linux (Steam with Proton).
