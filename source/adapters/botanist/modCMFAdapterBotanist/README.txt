Botanist adapter for Conjunction Map Framework
Version 0.1 (proof of concept with placeholder art; built with tools/cmf_pack.py)

Brings Botanist's world map changes back on Conjunction Map Framework's world map.
Botanist stays exactly as its author ships it. Under CMF Botanist's own map file does
not load, because CMF's map sorts first; this adapter asks CMF for the same changes
instead.

REQUIREMENTS
- Conjunction Map Framework version 5 or later; version 6 or later to keep Botanist's
  rows out of the Default filter. Botanist's markers need a CMF build that catches
  markers added after its own pass (1.0.0 and later); on an older build they show as
  black crosses.
- Botanist - NG - Remastered (Nexus mod 8260), built for and checked against version
  3.0.0.2, with Shared Utils 4.1 (Nexus mod 12997), both installed as their authors
  describe.
- Install this adapter ONLY together with Botanist. It calls only CMF, so the game
  starts without Botanist, but it would then add an empty Botanist tab you did not
  install.

WHAT YOU SEE
- A "Botanist" filter tab after the game's tabs, holding Botanist's three marker rows,
  which are not listed under Default. Signposts and other fast-travel points are left
  out of that tab, as in Botanist's own map. The tab's name is Botanist's own text.
- Botanist's markers on the map: herbs ready to harvest in gold, herbs in a Harvesting
  Ground and the grounds themselves in blue, the ground marker about one and a half
  times the size of the other two, as in Botanist's own map. The circle around a
  ground is Botanist's own and keeps its size.
- Everything else Botanist does (3D markers, banners, the pointer, the minimap
  guidance, its menu, the herb counts in the pin texts) is Botanist's own and works
  as normal.

PIN TYPES THIS ADAPTER CHANGES
- BotanistHGHerb, BotanistHG and Botanist (Botanist's marker names): placeholder art,
  rows in the Botanist tab; BotanistHG drawn about one and a half times the size of
  the other two; gold for Botanist, blue for BotanistHGHerb and BotanistHG, on the
  markers and their legend rows.
- Every fast-travel pin: left out of the Botanist tab only.
If another CMF pack changes the same type or setting, the pack whose folder name sorts
first wins. This adapter counts as Botanist's folder (modBotanist).

KNOWN LIMITS
- Botanist's three markers use placeholder art (a leaf, and a leaf in a ring for
  BotanistHG, coloured gold or blue) until Botanist's author supplies theirs.
- On CMF 5, Botanist's rows are also listed under Default; from CMF 6 they appear
  only in the Botanist tab and under All, as in Botanist's own map.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterBotanist. No Script Merger is needed.
Botanist's own folder (Mods\modBotanist) stays installed; CMF's map loads instead of
its map.

WHEN BOTANIST SHIPS ITS OWN CMF SUPPORT
Uninstall this adapter. With both installed, the game may stop at the script compile
screen; removing the adapter fixes it.

UNINSTALL
Remove this adapter before or together with Botanist. Removing CMF first stops the
game at the script compile screen until this adapter is removed too. The adapter
writes nothing into saves.

CREDITS
Botanist and Shared Utils are by their own authors; this adapter copies none of their
code or art and only uses the marker type names, tab id, priorities and string key
Botanist's map already uses. Placeholder art drawn by CMF's own tooling
(tools/cmf_community_patch_adapter_art.py).
