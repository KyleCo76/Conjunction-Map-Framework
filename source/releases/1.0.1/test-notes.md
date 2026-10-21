# How the 1.0.1 adapters were tested

- **Where:** Kyle's separate copy of the game on Windows, Steam 5.01 (build 5.0.1048522), DirectX 12, with W3LoadFix 1.0.8, on 2026-10-21. Keyboard and mouse; one game session, ended without saving.
- **What was installed:** CMF 1.0.0, Gwent Players Map 1.0.9, Witcher Upgrade Gear Map 1.0.1, these two adapters from their release candidate's own archives, and Ink and Iron 0.8.9 (All In One File) with the CMF 1.0.0 Ink and Iron adapter.
- **What was seen:** the author's cards on every Gwent marker; the author's gear pictures on the Gear markers, each school in its own colour in the "School colour" styles without and with circle, not coloured twice; Ink and Iron's look and 60 fps movement. The game log shows every picture registered and none failing to load. Passed.

The scripts that find markers when The Stable is installed are byte for byte the 1.0.0 files, tested in CMF 1.0.0's full set.

## Also tested, by someone else

MateusAnd, the author of both mods, ran the 1.0.0 adapters on Linux (CachyOS, Steam with Proton, 5.01 DirectX 12, keyboard and mouse): scripts compiled and every adapter feature worked. Only the pictures changed since.

## Not tested

- Controllers.
- Installing through Vortex or Mod Organizer 2.
- Steam Deck.
- The "No colour" icon style in this session (it uses the plain pictures, checked in the built files).
