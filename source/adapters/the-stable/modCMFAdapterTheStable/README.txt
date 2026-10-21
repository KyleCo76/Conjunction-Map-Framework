The Stable adapter for Conjunction Map Framework
Version 0.1 (passed in game with CMF API version 6, 2026-10-21)

Brings The Stable's map change back on Conjunction Map Framework's world map. The
Stable stays exactly as its author ships it. Under CMF its own map file does not
load, because CMF's map sorts first; this adapter asks CMF for the same change
instead.

REQUIREMENTS
- Conjunction Map Framework version 2 or later.
- The Stable - Roach-Horse Customization Mod 2.2.1 (Nexus mod 6132), installed as
  its author describes (its Mods\modArdDhuStable and dlc\dlcArdDhuStable folders).
- Install and remove this adapter together with The Stable. Without The Stable it
  adds nothing: it asks for the row only when The Stable's own text is in the game.

WHAT YOU SEE
- The stable masters' horseshoe markers are listed under the NPCs filter as
  "Stables", as in The Stable's own map, so that filter shows and hides them.
  Like any merchant, a stable master's marker appears once Geralt has been near
  him.
- The markers themselves, their names and descriptions, the horses, the shop and
  the scenes are The Stable's own and work as without CMF.

PIN TYPES THIS ADAPTER CHANGES
- Stables: its row joins NPCs.
If another CMF pack changes the same row, the pack whose folder name sorts first wins.
This adapter counts as The Stable's folder (modArdDhuStable).

KNOWN LIMITS
- None known. The markers use the game's own Stables drawing, as The Stable's map does.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterTheStable. No Script Merger is needed. The
Stable's own folders stay installed; CMF's map loads instead of its map.

WHEN THE STABLE SHIPS ITS OWN CMF SUPPORT
Uninstall this adapter. With both installed, the game may stop at the script compile
screen; removing the adapter fixes it.

UNINSTALL
Remove this adapter before or together with The Stable. Removing CMF first stops the
game at the script compile screen until this adapter is removed too. The adapter
writes nothing into saves.

CREDITS
The Stable - Roach-Horse Customization Mod is by its own author; this adapter copies
none of its code or art and only uses the marker type name, filter name and priority
The Stable's map already uses.
