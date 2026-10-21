Map Pin Teleport adapter for Conjunction Map Framework
Version 0.1 (passed in game with CMF API version 6, 2026-10-20)

Brings Map Pin Teleport's teleport back on Conjunction Map Framework's world map.
Map Pin Teleport stays exactly as its author ships it. This adapter only tells CMF
which clicks on your own map pins belong to Map Pin Teleport, and hands each click
to Map Pin Teleport's own script.

REQUIREMENTS
- Conjunction Map Framework version 6 or later.
- Map Pin Teleport 1.2.2 (Nexus mod 13541), installed as its author describes.
  This adapter calls Map Pin Teleport's own teleport function. Without Map Pin
  Teleport the game stops at the script compile screen.

WHAT YOU SEE
- A "GO NOW" button next to every map pin you place, following the map as you
  pan and zoom, drawn as Map Pin Teleport draws it. Clicking it closes the map
  and teleports Geralt to the pin.
- With one of your own pins selected, the bottom bar shows "Go Now" beside E
  (gamepad A), and E or Enter does the same as the button.
- Everything after the click is Map Pin Teleport's own: its messages when you are
  on a horse or a boat, playing as Ciri, or fast travel is blocked, its quick save
  and second press, and the teleport itself.
- Signposts, quest pins and placing or removing pins work as in the game.

PINS THIS ADAPTER CHANGES
- The player's own map pins (types User1 to User7): their click, its hint and
  the button text.
- The look of the button beside a pin. CMF draws one kind of button for every
  mod; the pack whose folder name sorts first sets its look.
If another CMF pack claims the click on the same pins, the more specific claim
wins (one pin, then a tag, then a pin type), then the pack whose folder name
sorts first. This adapter counts as Map Pin Teleport's folder (modMapPinTeleport).

KNOWN LIMITS
- Gamepad A has not been tried.
- The "Go Now" and "GO NOW" texts are English, as in Map Pin Teleport.

INSTALL
Extract the archive into your The Witcher 3 game folder, or install it with a mod
manager. It lands in Mods\modCMFAdapterMapPinTeleport. No Script Merger is needed.
Map Pin Teleport's own folder stays installed; CMF's map loads instead of its map.

UNINSTALL
Remove this adapter BEFORE removing Conjunction Map Framework or Map Pin Teleport.
If either is removed first, the game stops at the script compile screen until this
adapter is removed too.
The adapter writes nothing into saves.

WHEN MAP PIN TELEPORT SHIPS ITS OWN CMF SUPPORT
This adapter is for Map Pin Teleport 1.2.2, which has no CMF support of its own.
When Map Pin Teleport ships its own CMF support, uninstall this adapter. Do not
keep both: the two are not meant to run together, and with both installed the
game may stop at the script compile screen. Removing the adapter fixes it.

CREDITS
Map Pin Teleport is by its own author; this adapter copies none of its code or art
and only uses its teleport function, the pin types it acts on, its texts and its
button's sizes and colours.
