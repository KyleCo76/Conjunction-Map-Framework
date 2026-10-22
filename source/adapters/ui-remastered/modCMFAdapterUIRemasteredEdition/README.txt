UI Remastered Edition adapter for Conjunction Map Framework
Version 1.0.1

Puts UI Remastered Edition's "required level" text back where it belongs on
Conjunction Map Framework's world map. UI Remastered stays exactly as its author ships
it. It writes a quest's level into the quest title behind a hidden marker, "#UHL#",
which only its own map knows how to split. Under CMF its own map file does not load, so
the marker and the level text showed inside the quest title. This adapter splits the
title the same way.

REQUIREMENTS
- Conjunction Map Framework 1.0.0 or later.
- UI Remastered Edition 1.00 (Nexus mod 14578), installed as its author describes.
- Install this adapter ONLY together with UI Remastered Edition. It calls only CMF, so
  the game starts without UI Remastered, and it then changes nothing.

WHAT YOU SEE
- Quest titles in the map's info box and under the crosshair show the quest name only,
  without "#UHL#".
- UI Remastered's level text, in UI Remastered's own colour, shows on its own line
  under the quest objective in the info box.

KNOWN LIMITS
- The rest of UI Remastered's map look (its quest icons, legend with counts, journal on
  the map, its own tooltip) is in its own map file and stays missing under CMF until its
  author ports it.
- Where the level line sits is this adapter's choice: under the objective. UI Remastered's
  own map places it in its own tooltip.
- With Map Quest Insight installed too, the extra level line can make a quest's info
  box tall enough for Map Quest Insight's tall-box rule, which then shows the box at
  the side of the screen instead of under the pin. That is Map Quest Insight's own
  rule for tall boxes.

TESTED
On Windows with keyboard and mouse, with CMF 1.1.0 and UI Remastered Edition 1.00:
quest titles in the info box showed no "#UHL#", and the suggested level showed on its
own line under the objective. The name under the crosshair reads the same title, so it
loses the marker too, but it was not checked on its own. Not tested: controllers, Steam
Deck, Proton on Linux.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterUIRemasteredEdition. No Script Merger is needed.

WHEN UI REMASTERED SHIPS ITS OWN CMF SUPPORT
Uninstall this adapter.

UNINSTALL
Remove this adapter before or together with UI Remastered Edition. Removing CMF first
stops the game at the script compile screen until this adapter is removed too. The
adapter writes nothing into saves.

CREDITS
UI Remastered Edition is by its own author; this adapter copies none of its code or art
and only uses the "#UHL#" marker its scripts already write. This adapter is not made by
UI Remastered Edition's author; questions about it go to CMF's page.
Adapter: made by Kyle with the help of AI tools (Claude and ChatGPT). Every published
file is reviewed by Kyle.
