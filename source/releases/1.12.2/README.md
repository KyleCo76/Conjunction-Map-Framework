# CMF 1.12.2, the in-game menu add-on 1.12.2, the new CMF Customizer 1.0.0 and the Map Quest Insight adapter 2.5.5

CMF 1.12.2 (script API version 19) brings controller map movement, a "Player setting" level and pin size multipliers for mods with their own options pages, and a few info box and legend fixes. 1.12.1 was never released; its changes (the controller crosshair and the R3 fix) are part of 1.12.2.

It comes with the in-game menu add-on 1.12.2 (Status rows show their value in the label), a new optional add-on, the CMF Customizer 1.0.0 (pin sizes, icon labels and pin groups by zoom, from one options page), and the Map Quest Insight adapter 2.5.5 (controller fixes for the Quest List). The minimap add-on (2.2.0), the All Quest Objectives adapter (1.2.0) and every other adapter stay as released and work unchanged.

| ZIP | What it is | Install |
| --- | --- | --- |
| `mod0000_ConjunctionMapFramework-1.12.2.zip` | CMF 1.12.2 (script API version 19) | Everyone; delete the old `Mods\mod0000_ConjunctionMapFramework` folder first and replace the bin menu file |
| `modCMFInGameMenu-1.12.2.zip` | In-game menu add-on 1.12.2 | Optional; delete the old `Mods\modCMFInGameMenu` folder first and replace its bin file |
| `modCMFCustomizer-1.0.0.zip` | CMF Customizer 1.0.0 (needs CMF 1.12.2) | Optional |
| `modCMFAdapterMapQuestInsight-2.5.5.zip` | Map Quest Insight adapter 2.5.5 | With Map Quest Insight 2.1.0 or 2.2.0 |

## What changed

- **CMF 1.12.2:**
  - **Controller:** with a stick the map pans first; once it stops at its edge the crosshair moves on toward that edge, and back to the centre before the map pans again. A pin snap brings the pin under the crosshair where it is. R3 shows more or less of the info box again. Mouse and keyboard are unchanged.
  - **A screen a mod shows (the Quest List):** while it holds the controller, the left stick pans the map in every direction and A goes to the map when the crosshair is over a pin.
  - **Info box and legend:** the info box keeps off the key hints at the bottom of the screen; the legend's rows and tab drawings hide together with the legend.
  - **Player settings and size multipliers (script API version 19, additions only):**
    - A mod can say that a choice is the player's own setting (property 50, `CMFHasAbility('claims', 'playerSetting')`). It then wins over other mods' choices for the same thing; the player's own picks in CMF's menu still come first. The Status page names the level "Player setting".
    - Size multipliers (properties 51 and 52, `CMFHasAbility('claims', 'scaleFactor')`) add a percentage on top of the size the winning mod gives, for a pin type, a tag or every pin, and for a selected pin. "Standardize icon sizes" (property 53, `CMFHasAbility('claims', 'scaleStandard')`) draws every pin at the size most pins have. The game's own pins take the multipliers too.
    - A pin zoom range a player sets is held inside the region's own zoom range.
    - Packs and adapters made for earlier versions work unchanged.
- **In-game menu add-on 1.12.2:** the Status pages show each row's value in its label, because Ink and Iron's options menu redraws these rows without the text on the right.
- **CMF Customizer 1.0.0:** one options page (Options > Mods > CMF Customizer) for pin size, "Standardize icon sizes", quest marker size, undiscovered place (?) size, selected pin growth, icon labels (Always, Never, On hover) and, per pin group, when it hides by zoom. Every row starts at Off and then sends nothing.
- **Map Quest Insight adapter 2.5.5:** with a controller the Quest List takes only the D-pad and stick up and down; a D-pad press moves one step; A goes to the map when the crosshair is over a pin; the highlighted row puts the crosshair on its pin. The info box also looks up to 800 units for a clear spot (a trial). Keyboard and mouse are unchanged.

## Controller changes: what is confirmed

The crosshair, the R3 fix and the Quest List controller changes were first reported by a player and could not be tried here until Kyle had a controller. Kyle's own controller test of this version confirmed them. The player who reported them has not yet tried this public build; their confirmation is still awaited.

## Install

Each archive's `README.txt` has the steps. No Script Merger is needed.

`SHA256SUMS` covers the ZIPs and this file; `manifest.json` lists every file with its SHA-256.
