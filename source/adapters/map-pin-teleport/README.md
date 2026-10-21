# Map Pin Teleport adapter

`modCMFAdapterMapPinTeleport` is a separate mod that sits between Conjunction Map Framework (CMF) and Map Pin Teleport 1.2.2 (Nexus 13541). Map Pin Teleport lets the player teleport to a pin they placed: a "GO NOW" button beside each such pin, or E, Enter or gamepad A on the selected pin, with "Go Now" in the button bar. All of that lives in its own map file, which does not load while CMF is installed, so under CMF the teleport is gone. The adapter brings it back through CMF's pin clicks (API version 6, property ids 16, 20 and 21, the `CMFCore.OnPinClicked` hook and the `pinButton` theme part). Map Pin Teleport is unchanged. The adapter adds no feature of its own and ships no art. The design is section 5.2 of the pin click research (a launch record kept in the private development repository); the author-facing version is [`docs/authors/map-pin-teleport-adapter.md`](../../../docs/authors/map-pin-teleport-adapter.md).

## Provenance

Map Pin Teleport was not re-read for this adapter. Its interface is taken from two earlier read-only readings of the reference archive `MapPinTeleport 1.2.2(5.01) 13541 5 2026-10-10T16-44Z iNpQhXlMl.zip` (SHA-256 `f9fa95db3b3b5af7d2626b5d8618a1e72253fd68e368505de909515a1b4e63f2`) in Kyle's `source/compatability-candidates/`:

- the declaration inventory of `mods/modMapPinTeleport/content/scripts/local/modMapPinTeleport.ws` (193 lines), a launch record kept in the private development repository lines 204-214, and the source review `audit/research-2026-10-16-followup/new-map-source-review.md` ("Map Pin Teleport 1.2.2");
- the pin click research, section 3.3: its README, its script and its map file's `HubMap` (decompiled to learn the interface; nothing copied).

What the adapter relies on:

| Map Pin Teleport | Where | Used for |
|---|---|---|
| `function ModPinTP_Request( menu : CR4MapMenu, pinId : int )` | `modMapPinTeleport.ws` 47, global | the whole teleport: finds the user pin whose id matches `pinId` on its low 30 bits (58-62), applies its rules (horse or boat, Ciri, blocked fast travel, quick save and second press), closes the map, teleports and settles |
| `-2 - (id & 0x3FFFFFFF)` as `areaNameId` of `OnStaticMapPinUsed` | its map file, `HubMap` | the id it hands to `ModPinTP_Request`: the pin id's low 30 bits |
| E/Enter/A on the selected user pin, acted on key up after a key down on the map; a "GO NOW" button per user pin | its map file, `HubMap` | the inputs claimed: `use` and `button` |
| "Go Now" (button bar, through its `OnAppendGFxButton` wrapper, 20-35), "GO NOW" (button) | its map file and script | the hint (id 20) and button text (id 21), literal English as in the mod |
| button 150 x 40, corner 10, fill `#1A1410` at 0.9, 2 px line `#C8A55A`, centred `$NormalFont` 20 px `#E8D3A0`, 28 px right of and 20 px above the pin | its map file, `HubMap` | the `pinButton` look |

**Its `OnAppendGFxButton` wrapper and CMF's.** Line 20 declares `@wrapMethod(CR4MenuBase) function OnAppendGFxButton( actionId:int, gamepadNavCode:String, keyboardKeyCode:int, label:String, holdPrefix:bool, optional holdDuration:float )` with no return type: the same keyword, parameters and (absent) return type as CMF's own wrapper of that method in `cmfCore.ws`. Two wrappers of one method nest, and each passes on the labels it does not own (`modPinTP_GoNow` for Map Pin Teleport, `cmf:` for CMF), so both stay installed together. Map Pin Teleport's wrapper sits idle under CMF, because nothing sends its label any more. Its `OnStaticMapPinUsed` wrapper (lines 9-17) also sits idle: CMF never sends an area number of -2 or lower, and the game never does.

## How it works

| Step | Who |
|---|---|
| At game start the adapter claims `use,button` (id 16), the hint "Go Now" (id 20) and the button text "GO NOW" (id 21) on the seven user pin types `User1` to `User7`, and styles `pinButton` with Map Pin Teleport's look | adapter |
| CMF writes the click fields on each user pin, on the full list and on the one-pin update after placing a pin | CMF core |
| CMF's map draws the button beside each user pin and shows the hint while one is selected; a click, or E/Enter/A on key up, sends `OnCMFPinClicked` | CMF panel |
| CMF logs `click provider=modMapPinTeleport input=... type=User1 pin=... tag=... value=1` and calls `OnPinClicked` | CMF core |
| The adapter's `OnPinClicked` wrapper, for its own provider only, reduces the pin id to its low 30 bits and calls `ModPinTP_Request(menu, id)` | adapter |
| Messages, quick save, refusals, closing the map, teleport and settling | Map Pin Teleport, unchanged |

**The id.** Map Pin Teleport's map file sent `id & 0x3FFFFFFF`. The adapter computes the same number as the remainder of the id modulo 2^30, made positive, which is the low 30 bits of the id for any int, negative ones included (a pin id of 2^31 or more arrives as a negative int). It is written with `%` because CMF's own code tests flags arithmetically too; no bitwise operator is relied on.

**Claim order (documented rule).** One mod wins the click on each pin: a claim on one pin (`CMFStylePin`) beats a tag claim, which beats a type claim; at the same level the provider earlier in CMF's provider order wins (folder order unless the player set `CMFProviderOrder1..8`), then the earlier registration. The adapter's claims are type claims on `User1` to `User7` only, under the provider `modMapPinTeleport`. So:

- a type claim on a user pin type from a folder that sorts after `modMapPinTeleport` loses (the test pack `modZZCMFTestClick` checks this: `click shadowed provider=modZZCMFTestClick by=modMapPinTeleport`);
- a mod that claims one placed pin, or sorts earlier, wins that pin, and its own hint and button show there instead;
- the hint and button text follow the winner, so "Go Now" and "GO NOW" never show on a pin whose click goes elsewhere.

The adapter claims nothing but the player's own pins. All Quest Objectives' cached merchant pins, signposts and quest pins are untouched; signposts and quest pins keep the game's E and double-click, because CMF refuses `use` there.

**The button's look.** `pinButton` is one theme part for every mod's buttons: the earliest folder that styles it owns all its keys. With this adapter and no earlier styler, every button on the map has Map Pin Teleport's look; today no other map mod draws a button.

**Wrapper order.** Not relevant. Each `OnPinClicked` wrapper tests its own provider, and the adapter wraps no method Map Pin Teleport wraps, so the script file name needs no `zz_`.

## Dependencies

- **Map Pin Teleport 1.2.2, a compile dependency.** The adapter calls `ModPinTP_Request`, so the scripts fail to compile without it. Install and remove the two together, the adapter first.
- **CMF API version 6** (`CMFGetVersion()` 6): the adapter wraps `CMFCore.OnPinClicked` and uses `CMFPropertyPinClick`, `CMFPropertyPinClickHint` and `CMFPropertyPinClickButton`, so it does not compile on earlier versions.
- **Map Pin Teleport's own CMF support replaces the adapter.** The adapter targets 1.2.2, which has none. When Map Pin Teleport ships its own, the player uninstalls the adapter; a compile error with both installed is accepted (guide section 11), and the player README and author page say so.
- **Saves.** The adapter writes nothing into saves. Map Pin Teleport's own player fields (`modPinTP_settleTries`, `modPinTP_warnedPin`, `modPinTP_warnedTime`) are its own, as without CMF.

## Files

| Path | What |
|---|---|
| `modCMFAdapterMapPinTeleport/content/scripts/local/modcmfadaptermappinteleport_cmf.ws` | the claims and button look (`OnGameStarted` wrapper) and the click hook (`OnPinClicked` wrapper) |
| `modCMFAdapterMapPinTeleport/README.txt` | for players |
| `tests/test_cmf_map_pin_teleport_adapter.py` | static checks: the 21 claims on `User1` to `User7` and nothing else, the button look and every key and value CMF accepts for `pinButton`, the hook's provider test and its only call `ModPinTP_Request` with the low 30 bits, the wrapped methods, pack check and build, WitcherScript hygiene |

No art, so there is no `texture.cache`. Build: copy the folder, or `tools/cmf_pack.py build modCMFAdapterMapPinTeleport --adapts modMapPinTeleport --out <folder>`. `tools/cmf_pack.py check ... --adapts modMapPinTeleport` reports no errors and no warnings, and notes that the pack needs CMF 6.

## Status

Passed in game with CMF API version 6 (merged as a9ff811), Map Pin Teleport 1.2.2 (`modMapPinTeleport.ws` SHA-256 `a3b09867...`, recorded by the launch) and this script (`da4929bd...`), pack staged at a launch record kept in the private development repository:

- Launch P6+C (2026-10-20 18:25Z, a launch record kept in the private development repository): GO NOW drawn beside the pin and following it (screenshot), claim order `click shadowed provider=modZZCMFTestClick by=modMapPinTeleport`, first teleport by E (`click provider=modMapPinTeleport input=use type=User1 pin=9863450`). The second teleport crashed the game inside CMF core: its map passed the placed pin's id as the click's tag name. Fixed in core (the tag is 0 for placed pins, as Map Pin Teleport's own map sends); nothing in the adapter changed.
- Launch P6+C run 2 (2026-10-20 ~20:05Z, a launch record kept in the private development repository): all three teleports (GO NOW, E, and Novigrad to southern Velen) reached Map Pin Teleport, each logged as `click provider=modMapPinTeleport ... tag=None value=1`, and a signpost still fast travelled normally.

## Limits

- Gamepad A and touch taps run CMF's code paths for `use`, which have not been tried (no controller or touch screen on the test PC).
- Placed pins are identified by `pinId` (the pin's raw id); `pinTag` is `None` for them, so the adapter never reads it.
- Windows only; Proton not checked.
