CMF 1.12.2 (script API version 19) brings controller map movement, a "Player setting" level and pin size multipliers for mods with their own options pages, and a few info box and legend fixes. 1.12.1 was never released; its changes are in this version. With it come the in-game menu add-on 1.12.2, a new optional add-on (the CMF Customizer 1.0.0) and the Map Quest Insight adapter 2.5.5. The minimap add-on 2.2.0 and every other adapter stay as released in [1.12.0](https://github.com/KyleCo76/Conjunction-Map-Framework/releases/tag/v1.12.0) and earlier.

### Which files do I need?

- **`mod0000_ConjunctionMapFramework-1.12.2.zip`**: everyone. Replaces CMF 1.12.0; delete the old `Mods\mod0000_ConjunctionMapFramework` folder first and replace its `bin` menu file. Script API version 19.
- **`modCMFInGameMenu-1.12.2.zip`**: optional, if you use the in-game menu. Replaces 1.10.0; delete the old `Mods\modCMFInGameMenu` folder first and replace its `bin` file.
- **`modCMFCustomizer-1.0.0.zip`**: optional, new. One options page for pin sizes, icon labels and when pin groups hide. Needs CMF 1.12.2.
- **`modCMFAdapterMapQuestInsight-2.5.5.zip`**: if you play with Map Quest Insight 2.1.0 or 2.2.0. Replaces 2.5.4.

Each archive has a `README.txt` with install and removal steps.

### In this release

- **Controller (CMF 1.12.2):** with a stick the map pans first; once it stops at its edge the crosshair moves on toward that edge, and back to the centre before the map pans again. R3 shows more or less of the info box again. Mouse and keyboard are unchanged.
- **Quest List on a controller (adapter 2.5.5, CMF 1.12.2):** the D-pad moves the list one step per press, the left stick pans the map in every direction, A goes to the map when the crosshair is over a pin, and the highlighted row puts the crosshair on its pin.
- **Info box and legend (CMF 1.12.2):** the info box keeps off the key hints at the bottom of the screen; the legend's rows and tab drawings hide together with the legend.
- **CMF Customizer 1.0.0:** Options > Mods > CMF Customizer sets pin size, "Standardize icon sizes", quest marker size, undiscovered place (?) size, selected pin growth, icon labels and, per pin group, when it hides by zoom. Every row starts at Off and then sends nothing.
- **In-game menu add-on 1.12.2:** the Status pages show each row's value in its label.
- **For mod authors (script API version 19, additions only):** a mod can mark a choice as the player's own setting (property 50), which wins over other mods' choices but not over the player's picks in CMF's menu; size multipliers (properties 51 and 52) and "Standardize icon sizes" (property 53); a player-set pin zoom range is held inside the region's own range. Packs and adapters made for earlier versions work unchanged.

### Controller changes: what is confirmed

The crosshair, the R3 fix and the Quest List changes were first reported by a player. Kyle's own controller test of this version confirmed them. The player who reported them has not yet tried this public build, so their confirmation is still awaited.

### Tested

On Windows, game build 5.0.1090142 (5.01c), keyboard and mouse and a real controller, with 39 mods including the Ash & Quill icon packs, Map Quest Insight 2.2.0, Ink and Iron and the CMF Customizer. One start on these release archives, extracted as a player would, passed: 0 compile errors, 0 errors from CMF, no failed pin update and no refused refresh. Not tested: the new settings with a mod other than the CMF Customizer, Vortex and Mod Organizer 2, Steam Deck, Linux (Proton). Details in `test-notes.md`; going back in `rollback-notes.md`.

### Check a download

`Get-FileHash .\<archive>.zip -Algorithm SHA256` in PowerShell must match the archive's line in `SHA256SUMS`.

| Archive | Size | SHA-256 |
| --- | --- | --- |
| `mod0000_ConjunctionMapFramework-1.12.2.zip` | 2349037 | `a11d5d6dd8bf06465f1e8cadb625b7dc2c75467d623ee376d78fe84f9cfb7115` |
| `modCMFInGameMenu-1.12.2.zip` | 386930 | `9d70259097f73e25e92066f143c5a7cc2fcd273b7149a54cd5e99c4613bff053` |
| `modCMFCustomizer-1.0.0.zip` | 51211 | `c3fa211d4343564396b7e7e4b63a5d84bd7b6806a24bdb5cc3b7f785ec025a78` |
| `modCMFAdapterMapQuestInsight-2.5.5.zip` | 830025 | `fbf4667654f8f2338dacab08d89e3f06887ce79ff755fab56f140323d98706ff` |

Licence: CC BY-NC 4.0. This is an unofficial fan work and is not approved/endorsed by CD PROJEKT RED.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
