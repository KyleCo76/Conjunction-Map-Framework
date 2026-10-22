# UI Remastered Edition adapter

`modCMFAdapterUIRemasteredEdition` is a separate mod that sits between Conjunction Map Framework (CMF) and UI Remastered Edition 1.00 (Nexus 14578). It fixes one thing: with UI Remastered installed, CMF's info box and crosshair label showed quest titles with UI Remastered's raw `#UHL#` marker and its level text inside the title. It restores no other part of UI Remastered's map look, which lives in UI Remastered's own map file.

## Cause

UI Remastered's `uire_worldmap.ws` (SHA-256 `2e2a3ea0…46be1`, read only, for its interface) wraps `AddPinTypeData` (lines 174-210) and writes a quest pin's `label` as the game's label + `#UHL#` + `<font color=…>` level text `</font>` (lines 204-205). Only UI Remastered's own map tooltip splits the title at the marker. Under CMF that map file does not load, so the marker reached CMF's info box as part of the title.

## How it works

| UI Remastered's map | Under CMF, through the adapter | CMF API |
|---|---|---|
| Title split at `#UHL#`; the level text shown apart from the title | `CMFCore.OnPinReady` wrapper: `StrSplitFirst(label, "#UHL#", title, level)`; `label` = the part before the marker; the level text (UI Remastered's own `<font>` markup) is added as its own line under the pin's `description` | 4 |

- **No wrapper-order dependency.** `OnPinReady` runs in CMF's late pass, after every `AddPinTypeData` wrapper, UI Remastered's included, so the file name does not matter.
- **No claims, no art, no CMF change.** It writes the pin's own `label` and `description` fields, as the Gwent Players Map and Witcher Gear Map adapters write theirs. The crosshair label and the info box both read `label`, so both lose the marker.
- **Without UI Remastered** no pin carries `#UHL#` and the wrapper changes nothing; the player README still says to install it only with UI Remastered.
- **Placement** of the level line (under the objective) is this adapter's choice.
- **Evidence line:** `CMF adapter provider=mod0000_UIRemasteredEdition levelTitlesSplit=N` once per full map build.

## For UI Remastered's author

Once UI Remastered supports CMF itself, the same split can live in UI Remastered's own scripts (or its `AddPinTypeData` wrapper can stop adding the marker while CMF is installed), and this adapter is retired.

## Tested

Passed in game on 2026-10-22 on Windows with keyboard and mouse, CMF 1.1.0 and UI Remastered Edition 1.00 (navigation mode Minimap): quest titles in the info box and under the crosshair showed no `#UHL#`, "Suggested level 32" showed on its own line under the objective, and the log read `levelTitlesSplit=8` with no compile error. Not tested: controllers, Steam Deck, Proton on Linux.
