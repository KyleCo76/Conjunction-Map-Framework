# Fog of War adapter (proof of concept)

**Adapter version 1.0.1.** Tells CMF the adapter is installed when the game starts (property 38, behind `CMFHasProperty(38)`, API 11), so CMF's adapter check can see it. Nothing else changes.

`modCMFAdapterFogOfWar` is a separate mod that sits between Conjunction Map Framework (CMF) and Fog of War 1.2.1 (Nexus 13627). Fog of War hides map pins under its fog, but its script cannot reach pins other mods push from a later wrapper, so Witcher Gear Map's markers show through the fog. The adapter asks Fog of War's own filter about every pin in the finished entity list and passes each pin the filter drops to CMF as a hide, through property 9 `Hidden` of CMF API version 3 (Stage 1 spec, sections 7.1 and 10.2; the spec is PR #17). Fog of War is unchanged. The adapter adds no rule of its own and ships no art. The author-facing version is [`docs/authors/fog-of-war-adapter.md`](../../../docs/authors/fog-of-war-adapter.md).

## Provenance

Read only, on 2026-10-20, for its interface: the reference archive `FogOfWar (5.01) 13627 1.2.1 2026-10-08T22-58Z LKqTerUTH.zip` (SHA-256 `96ff2022a7a0cdcb56121386f0b6a38ce9ca534bd152ccf7306d0051908e5d79`, 14 988 651 bytes) in Kyle's `source/compatability-candidates/`. Its scripts:

| File | SHA-256 |
|---|---|
| `modFogOfWarMap.ws` | `142244e3f8314b865f34250a5777b0e2edd7a84a0d8718b004980b577a198f5a` |
| `modFogOfWarConfig.ws` | `c75fe84d3afae18f27c81dc9553983376a062bfa9315f313eaae163383e071ca` |
| `modFogOfWar.ws` | `36d4651d7443feae0860ea2b73706258acb4bbabd9ae71248d2f0ed020ad7a82` |

The verified install set is staged at a launch record kept in the private development repository. Vanilla `mapMenu.ws` (SHA-256 `a27a6e00…bdf27`) was read for `UpdateEntityPins` (line 979, called once, from `UpdateData` at 338) and `GetShownMapType` (2095).

The adapter calls two of Fog of War's functions and copies none of its code:

| Function | Where | Used for |
|---|---|---|
| `FogOfWarEnabled() : bool` | `modFogOfWarConfig.ws` 56, global | Fog of War's "Enable Fog of War" option; off means no hiding, as in Fog of War |
| `FogOfWarFilterPins(flashArray : CScriptedFlashArray, start : int)` | `modFogOfWarMap.ws` 160, `@addMethod(CR4MapMenu)` | the whole under-fog decision: it removes from `flashArray`, from index `start` on, every pin Fog of War hides |

## Can the filter be asked per pin? (spec 10.2, first build step)

Yes, but not one call per pin. `FogOfWarFilterPins` reads each pin only through its own fields (`filteredType`, `isQuest`, `isFastTravel`, `id`, `posX`, `posY`, `radius`) and removes the ones it hides, so the answer for a pin does not depend on the other pins in the list. Each call, though, also runs fixed work before its loop (lines 174-204): `ProcessRemoteDiscoveries()`, a forced `Tick(true)` of its exploration recorder when the map shows the player's area, the area lookup, a 31-entry power table, the remote-pin id list, and one `FogOfWar` log line. Called once per pin, a map build would tick the recorder and log hundreds of times.

So the adapter asks once per build. It builds one scratch array per build (`CreateTempFlashArray`, as the main thread's review asked: never one per pin) holding every candidate pin followed by one shared marker object, and calls `FogOfWarFilterPins(scratch, 0)` once. The marker carries `isFastTravel = true` and an empty `filteredType`, which Fog of War always keeps (line 224: known travel points stay). A marker with no pin right before it after the call means Fog of War dropped that pin. The scratch array holds references to the same pin objects; the filter only reads them and removes entries from the scratch array, never from the real list.

The side effects are Fog of War's own and happen in its own wrapper on every build anyway: the recorder tick (it re-records the cells around Geralt, already recorded by Fog of War's own call a moment earlier) and the remote-discovery queue (already emptied by that call). Fog of War logs `pins escondidos pela nevoa: N` once for its own call and once for the adapter's.

## How it works

| Step | Who |
|---|---|
| Vanilla `UpdateEntityPins` adds the engine's pins; CMF's own wrapper (`cmfCore.ws`, innermost) opens the build for per-pin calls | vanilla, CMF core |
| Fog of War's wrapper (`modFogOfWarMap.ws`) removes the pins under fog among those added inside it | Fog of War, unchanged |
| Map Quest Insight and Witcher Gear Map wrappers (`questMapInfo.ws`, `wgm.ws`) remove and push their pins | other mods, unchanged |
| The adapter's wrapper (`zz_modcmfadapterfogofwar_cmf.ws`, outermost) asks `FogOfWarFilterPins` about every pin in the list and calls `CMFStylePin("modFogOfWar", pin, 9, "", 1)` on each dropped pin | adapter |
| CMF marks the pin (`cmfHiddenBy`) and removes it in its late pass, so counts, cycling, the overview and "show on map" stay consistent | CMF core |

Pins Fog of War already removed are gone before the adapter runs. Pins inside Fog of War's window that it kept are asked again and kept again (explored cells and remote discoveries only grow). So the pins the adapter hides are exactly the ones Fog of War's own wrapper could not see. Nothing is counted twice.

**Wrapper order.** Wrappers nest by script file name (MQI case, section 7). `zz_modcmfadapterfogofwar_cmf.ws` sorts after `cmfCore.ws`, `gwm.ws`, `modFogOfWarMap.ws`, `questMapInfo.ws` and `wgm.ws`, so it is outermost and sees every pin pushed in an `UpdateEntityPins` wrapper. A pin pushed by a wrapper whose file sorts after this one would escape; none is known. The pack tool reads the file name without its leading `zz_`, so the prefix gives no warning.

**Provider.** Every hide names `modFogOfWar`, Fog of War's own folder, as its provider (N4 spec 7.3; before N4 it was `modCMFAdapterFogOfWar`), so folder order between mods is the same with CMF as without it.

**Never hidden.** The player marker and user pins are added after `UpdateEntityPins`, so they are never in the list the adapter sees; the adapter skips `isPlayer` and `isUserPin` anyway, and CMF refuses them (spec 7.4).

**CMF API versions.** `CMFStylePin` exists since API version 2, so the file compiles against API versions 2 and 3. Everything is behind `CMFHasProperty(9)`: under API version 2 the adapter does nothing.

**Log.** Per build, one line: `CMF adapter provider=modFogOfWar area=<area> asked=<pins> hidden=<dropped by Fog of War> marked=<accepted by CMF>`. For the first eight dropped pins of each build: `CMF adapter provider=modFogOfWar type=<pin type> hidden=1 result=marked|refused`.

## Dependencies

- **Fog of War 1.2.1, a compile dependency.** The adapter calls Fog of War's functions, so the scripts fail to compile without it. The adapter is installed and removed together with Fog of War, and is removed first.
- **CMF API version 3 to hide anything** (`CMFGetVersion()` 3, property 9). Compiles against API version 2 and does nothing there.
- **Saves.** The adapter writes nothing into saves. Fog of War stores its exploration grid in every save made while it is installed (`saved var fogOfWarData`, `modFogOfWar.ws` 532), so probe launches end without saving.

## Files

| Path | What |
|---|---|
| `modCMFAdapterFogOfWar/content/scripts/local/zz_modcmfadapterfogofwar_cmf.ws` | the `UpdateEntityPins` wrapper and its log lines |
| `modCMFAdapterFogOfWar/README.txt` | for players |
| `tests/test_cmf_fog_of_war_adapter.py` | static checks: the Fog of War functions it calls exist with these signatures in 1.2.1 and the marker keeps passing Fog of War's travel-point rule, the file sorts after every `UpdateEntityPins` wrapper in the inventory, it hides only through `CMFStylePin` id 9 behind `CMFHasProperty(9)` and writes no pin field, one scratch array per build, plus WitcherScript hygiene |

No art, so there is no `texture.cache`. Build: copy the folder. `tools/cmf_pack.py check modCMFAdapterFogOfWar --adapts modFogOfWar` gives one expected warning: the missing `OnGameStarted` wrapper (the adapter registers nothing; it hides per pin).

## Status

Passed in game at launch S1-1 (2026-10-20, record a launch record kept in the private development repository), compiled with the Stage 1 core (API version 3). Its log lines then read `provider=modCMFAdapterFogOfWar`. It passed again under its new provider name `modFogOfWar` with API version 5 at launch OF (2026-10-20, record a launch record kept in the private development repository): Novigrad `asked=90 hidden=36 marked=36`, White Orchard `asked=9 hidden=2 marked=2`, Gear's markers gone with fog on and back with fog off. On a fresh Hearts of Stone save with Fog of War on: Novigrad `asked=89 hidden=36 marked=36`, all eight logged pins Witcher Gear types, after Fog of War's own call hid 92; White Orchard `asked=9 hidden=2 marked=2`, Gear's two markers gone with fog on and back with fog off. No `CMF rejected` line for the adapter. On the complete save Fog of War was switched off in its menu for every map build, so the adapter correctly did nothing there.

## Limits

- Only pin hiding comes back. Fog of War's clouds over the map and the overview stay missing until Fog of War's author ports them: CMF does not draw another mod's artwork (Kyle, 2026-10-20).
- Fog of War's own map file (in its `blob0.bundle`) does not load while CMF is installed, because `mod0000_ConjunctionMapFramework` sorts first.
- HUD minimap not covered (engine-native, as in Fog of War).
- Windows only; Proton not checked.
