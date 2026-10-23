# How CMF 1.0.0 was tested

## Where and how

- **Where:** a separate copy of the game on Windows, Steam 5.01 (build 5.0.1048522), DirectX 12, with W3LoadFix 1.0.8 installed.
- **What was installed:** the files in this release, installed from the release candidates' own archives or written byte for byte from the same source, with each adapted mod at the version named in its adapter's `README.txt`. Every file in this release ran in at least one of the sets below with this exact CMF core, except four adapter `README.txt` texts (Witcher Gear Map, The Stable, Botanist and Map Quest Insight) that were reworded after their launch.
- **How:** keyboard and mouse; each test set was one game session that ended without saving.

## The test sets

All on 2026-10-21, on Kyle's test copy:

- **Everything together (M1, rerun as M1d and then M1e with this core):** CMF with eight of the ten adapters and their mods (all but Ink and Iron and Fog of War, which have their own sets), All Quest Markers, Wild Monster Hunt, Wolf's Bearing and other map-touching mods. Gwent cards, Witcher Gear markers and The Stable's Stables row on the map together, Map Pin Teleport clicks, the Witcher's Path tab, quest badges and level labels, greyed signposts still usable; the map moves at 60 frames per second. Passed.
- **The Stable out (M1c):** found that The Stable replaces the map step Gwent Players Map and Witcher Gear Map add their markers in; the Gwent and Gear adapters now add those markers themselves, from the mods' own data, when The Stable is installed (checked in M1d). Passed.
- **Adapters removed (M5a):** CMF alone with the adapted mods; the game starts, the map opens, no empty CMF entry under Options > Mods. Passed.
- **CMF removed (M5b):** the same mods without CMF; the game starts and runs. Passed.
- **Ink and Iron (M2):** Kyle's own Ink and Iron setup with its adapter; Ink and Iron's look and movement on CMF's map, its HUD and menus unchanged. Passed.
- **Minimap and Fog of War (M3):** the minimap add-on and the sample icon pack (same icons on map and minimap), Map Quest Insight, Witcher Gear Map and Gwent Players Map, and Fog of War hiding and restoring other mods' icons. Passed.
- **A map mod not yet ported (M4):** a HUD and menu mod with its own map file, with CMF; its HUD, menus and hint row work, CMF's map opens. Passed.
- **Native plugins (M6):** Apocrypha Menu Framework 1.0.6 and HUD Position Manager 1.0.0 (an ASI loader beside W3LoadFix); both plugins load, the HUD draws, CMF's map opens. Passed.
- **An everyday game (live field test):** Kyle's own game with about 175 mods, CMF and the Ink and Iron and Map Quest Insight adapters installed from these archives through RMMR 2.5, with Map Quest Insight 1.6.1 and a mod drawing on CMF's map. Scripts compile; Ink and Iron's look, Map Quest Insight's labels and the other mod's tab and markers show; the map opens in about 2 seconds with 1,696 pins and moves at 60 frames per second. Passed.

The first run of the full set (M1) found the Gwent and Gear markers missing with The Stable installed and an empty "Conjunction Map Framework" entry under Options > Mods; both were fixed and the sets above ran on the fixed files.

## Not tested

- Proton / Linux.
- Controllers. Keyboard and mouse only.
- Installing through Vortex or Mod Organizer 2. The test copy was set up by copying folders; the everyday game used RMMR 2.5.
- Mods not named on the compatibility list.
- Smooth Map and Community Patch - World Map with CMF 1.0.0: no adapter ships for them.

## Known differences

- **All Quest Objectives:** the badge and exclamation mark are placeholder drawings in its colours; its own art lives in its own map file.
- **Botanist:** its three markers use placeholder leaf art until its author supplies theirs.
- **Fog of War:** its clouds do not draw on CMF's map; hiding the icons works. The round HUD minimap is not covered, as with Fog of War alone.
- **Gwent Players Map:** placeholder card art. With The Stable installed, the adapter adds the cards from Gwent Players Map's own data.
- **Ink and Iron:** with another map-movement mod installed, settings Ink and Iron does not decide can come from that mod. Its controller crosshair is untried.
- **Map Pin Teleport:** the "Go Now" texts are English, as in Map Pin Teleport.
- **Map Quest Insight:** main quest, contract and Gwent quest icons are placeholders; with "Spread stacked quest markers" on, the info box still lists the other quests on the spot.
- **The Stable:** none known.
- **Witcher Gear Map:** placeholder art; the legend row shows the plain sheet whatever the icon style. With The Stable installed, the adapter adds the markers from Gear Map's own data.
- **Witcher's Path:** its speed setting does nothing under CMF, and its tab comes after other mods' CMF tabs.

## Test levels (developer record)

| Level | What | Record |
| --- | --- | --- |
| Static | unit tests at the freeze commit, known failures listed and explained | 173655ade2c03bc7a326602daf83abd99048aadf: 513 tests, 43 failures and 20 errors, all from absent `build/` fixtures, Windows-only skill paths and absent specimens; none from this release's code |
| Offline | panel build movie hash and repackage check; adapter packs rebuilt with `tools/cmf_pack.py` and compared by SHA-256 with the launched files | `source/previews/1.0.0-preview-4.json` and `1.0.0-preview-5.json` with their READMEs |
| Probe launches | each ability's own launch on the probe copy | 2026-10-19 to 2026-10-21, `probes/2026-10-*-cmf-*/README.md` |
| Final matrix | the sets above | `probes/2026-10-21-cmf-final-matrix/README.md` (one section per set); the everyday game in `probes/2026-10-21-cmf-live-field-test/README.md` |
| Live acceptance | Kyle's acceptance of the release | Kyle accepted release candidate `1.0.0-preview-4` on 2026-10-21 03:42Z (PR #56, merged as 32ebbd6) and `dist/1.0.0` from it (PR #57, 04:01Z). `1.0.0-preview-5` equals it except three adapter `README.txt` texts (Botanist, The Stable, Map Quest Insight), corrected before publication; his acceptance of that cut follows its own review |

Never written as tested: Proton, controllers, Vortex or Mod Organizer 2 install, or in-game behaviour of anything only read in code.
