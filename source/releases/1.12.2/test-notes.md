# How 1.12.2 was tested

- **Where:** Kyle's separate copy of the game on Windows, Steam 5.01 with the 5.01c update (build 5.0.1090142), DirectX 12, 2026-11-05 and 2026-11-06, 3840x2160 (16:9). Saves loaded with Load Game. Kyle used a real controller.
- **Set:** 39 mods: CMF with the in-game menu add-on, the CMF Customizer, the Map Quest Insight adapter 2.5.5 with Map Quest Insight 2.2.0, Ink and Iron, the Ash & Quill icon packs and the rest of the probe set. CMFDebug was on and the game ran with `-debugscripts`.

## What the check start covered (passed, Kyle)

Kyle ran the steps of `source/probes/release_1_12_2_check/README.md` across the check starts, and those that ran passed. Part A (the controller steps) ran on earlier builds of this branch, not on the final archives. Part B steps 9 to 16 ran too, with the White Orchard zoom clamp on an earlier add-on build. Steps 17 (the speed comparison) and 18 (a map with no other size claims) were not run. The info box hints strip fix came after these starts and was checked in the release-archive start. Logs `release-1-12-2-check.txt`, `-3.txt` and `-4.txt`: compile errors 0, rejected claims 0 in the last two, failed pin updates 0, CMF or Customizer errors 0, and size, growth and Standardize lines right on every pin type in `-4`. What they covered:

- **Controller (Kyle's own controller test):** the Quest List, the left stick, A, the crosshair on the highlighted row, the crosshair roam and the R3 fold of the info box, with the legend hidden and shown.
- **Player setting, size multipliers and the CMF Customizer:** the add-on's page, pin, quest marker, undiscovered place and selected pin sizes, Standardize icon sizes, icon labels, the pin group zoom rows (including the White Orchard clamp), CMF's own Pin size set to Vanilla, and every row back to Off.
- **Info box, legend and Status pages:** the info box off the key hints strip, the legend's tab drawings with its auto-hide, and the Status pages with Ink and Iron active.

Not confirmed by anyone else yet: the player who reported the controller problems has not tried this public build.

## Release-archive check

- PASSED on 2026-11-06: one start on these release archives extracted as a player would, in a 39-mod set (Fog of War adapter 1.1.3, Witcher Gear Map adapter 1.0.2, no test mod) at 3840x2160 (16:9). The log showed 0 compile errors, 0 errors from CMF, no failed pin update and no refused refresh, with 2 movie serials sent and 2 completed. Kyle checked the map in Velen, the CMF Customizer page with its rows named, the Status pages, the animated Ash & Quill icons and the expanded Envoys, Wineboys info box clear of the key hints strip. Log `release-archive-check-1-12-2.txt`.

## Not tested

- The Player setting level and the size multipliers with a mod other than the CMF Customizer (only the add-on sent them). Installing through Vortex or Mod Organizer 2. Steam Deck and Proton on Linux. Ultrawide screens on the final builds (the last check starts ran at 16:9).
