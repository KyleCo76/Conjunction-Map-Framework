modZZCMFTestClick - TEST ONLY, not a player package

The pin click order check for Conjunction Map Framework (pin click research 2026-10-20, section 7). Requires
CMF API version 6 (pin clicks); on an older CMF it registers nothing.

It claims "use" (E, Enter, gamepad A) on the pins the player places (type User1), as the Map Pin Teleport
adapter does. Its folder sorts after modMapPinTeleport, so it must lose. Read scriptslog.txt for
"click shadowed provider=modZZCMFTestClick by=modMapPinTeleport"; there is nothing to see on the map.

Install: copy the folder into Mods for a probe launch only. Remove: delete the modZZCMFTestClick folder.
