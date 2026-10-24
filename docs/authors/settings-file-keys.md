# Settings file keys

From CMF 1.2.0 a player can choose which map mod wins each feature of the map, and each piece of most features. The easy way is CMF's optional in-game menu add-on, `modCMFInGameMenu`, under Options > Mods > Conjunction Map Framework. Without it, the same choices go into the game's settings file. This page lists every key. [Players' choices](icon-pack-guide.md#players-choices-who-wins-each-feature-api-version-8) explains which answer wins when several are set.

## Writing a choice

Close the game first. Open `Documents\The Witcher 3\dx12user.settings` in a text editor and add lines under the `[CMFSettings]` heading (add the heading if it is missing), one choice per line:

```
[CMFSettings]
CMFFile_Icons=modCMFExampleIconPack
CMFFile_Painting_Skellige=Vanilla
```

- **The value** is a map mod's folder name (capital and small letters count the same), `Vanilla` (or `Off`) for the game's own look, or `Automatic` (or `Auto`, `Default`, or nothing) to let the next level decide. Spaces are ignored.
- **One name per value, never a comma.** The game ends a value at its first comma and rewrites the file that way when it exits.
- **A Basic key** (`CMFFile_<Feature>`) chooses for a whole feature. **An Advanced key** (`CMFFile_<Feature>_<Piece>`) chooses for one piece of it and comes before the Basic key.
- **In-game choices come first.** When the menu add-on is installed, its rows and its Mod order decide before any file choice. Without it, file choices decide before the file Mod order.
- **Hidden pins and drawings add together**: every mod's applies. `CMFFile_Hidden` and `CMFFile_Drawings` keep only the named mod's (or none with `Vanilla`), and the three `_Ignore` keys of each leave one mod out each.
- A folder name no installed mod has decides nothing. Values left in the file do nothing once CMF is removed.

## Every key

<!-- cmf:settings-keys begin -->
| File key | Feature | In-game menu page | Menu row |
| --- | --- | --- | --- |
| `CMFFile_Icons` | Pin icons | Basic choices | Pin icons |
| `CMFFile_Colours` | Pin colours | Basic choices | Pin colours |
| `CMFFile_Size` | Pin size | Basic choices | Pin size |
| `CMFFile_Labels` | Pin labels | Basic choices | Pin labels |
| `CMFFile_Clicks` | Pin clicks | Basic choices | Pin clicks |
| `CMFFile_Legend` | Legend and filter tabs | Basic choices | Legend and filter tabs |
| `CMFFile_Hidden` | Hidden pins | Basic choices | Hidden pins |
| `CMFFile_Look` | Map look | Basic choices | Map look |
| `CMFFile_Movement` | Map movement | Basic choices | Map movement |
| `CMFFile_Painting` | Map painting | Basic choices | Map painting |
| `CMFFile_Drawings` | Drawings on the map | Basic choices | Drawings on the map |
| `CMFFile_Icons_General` | Pin icons | Advanced choices > Pin icons | General (signposts, boards, stash, Roach) |
| `CMFFile_Icons_Quests` | Pin icons | Advanced choices > Pin icons | Quests |
| `CMFFile_Icons_Places` | Pin icons | Advanced choices > Pin icons | Places (undiscovered and active) |
| `CMFFile_Icons_Completed` | Pin icons | Advanced choices > Pin icons | Completed places |
| `CMFFile_Icons_Services` | Pin icons | Advanced choices > Pin icons | Shops and services |
| `CMFFile_Icons_Power` | Pin icons | Advanced choices > Pin icons | Places of power and workbenches |
| `CMFFile_Icons_Other` | Pin icons | Advanced choices > Pin icons | Other (beds, herbs, stables) |
| `CMFFile_Icons_Added` | Pin icons | Advanced choices > Pin icons | Pins added by mods |
| `CMFFile_Colours_General` | Pin colours | Advanced choices > Pin colours | General (signposts, boards, stash, Roach) |
| `CMFFile_Colours_Quests` | Pin colours | Advanced choices > Pin colours | Quests |
| `CMFFile_Colours_Places` | Pin colours | Advanced choices > Pin colours | Places (undiscovered and active) |
| `CMFFile_Colours_Completed` | Pin colours | Advanced choices > Pin colours | Completed places |
| `CMFFile_Colours_Services` | Pin colours | Advanced choices > Pin colours | Shops and services |
| `CMFFile_Colours_Power` | Pin colours | Advanced choices > Pin colours | Places of power and workbenches |
| `CMFFile_Colours_Other` | Pin colours | Advanced choices > Pin colours | Other (beds, herbs, stables) |
| `CMFFile_Colours_Added` | Pin colours | Advanced choices > Pin colours | Pins added by mods |
| `CMFFile_Size_Scale` | Pin size | Advanced choices > Pin size and labels | Pin size |
| `CMFFile_Size_Lead` | Map behaviour | Advanced choices > Map behaviour | Which pin leads a spread |
| `CMFFile_Size_Spread` | Map behaviour | Advanced choices > Map behaviour | Stacked pins spread out |
| `CMFFile_Labels_Text` | Pin labels | Advanced choices > Pin size and labels | Level tags and label text |
| `CMFFile_Labels_Place` | Map behaviour | Advanced choices > Map behaviour | Label place and hiding |
| `CMFFile_Clicks_Pins` | Pin clicks | Advanced choices > Clicks and drawings | Pin clicks |
| `CMFFile_Legend_Rows` | Legend and filter tabs | Advanced choices > Legend and filters | Legend rows |
| `CMFFile_Legend_Names` | Legend and filter tabs | Advanced choices > Legend and filters | Row names |
| `CMFFile_Legend_Tabs` | Legend and filter tabs | Advanced choices > Legend and filters | Tab names |
| `CMFFile_Hidden_Ignore1` | Hidden pins | Advanced choices > Legend and filters | Ignore hidden pins from (1st) |
| `CMFFile_Hidden_Ignore2` | Hidden pins | Advanced choices > Legend and filters | Ignore hidden pins from (2nd) |
| `CMFFile_Hidden_Ignore3` | Hidden pins | Advanced choices > Legend and filters | Ignore hidden pins from (3rd) |
| `CMFFile_Look_Frames` | Map look | Advanced choices > Map look | Frames and panels |
| `CMFFile_Look_Legend` | Map look | Advanced choices > Map look | Legend |
| `CMFFile_Look_InfoBox` | Map look | Advanced choices > Map look | Info box |
| `CMFFile_Look_Hints` | Map look | Advanced choices > Map look | Key hints |
| `CMFFile_Look_PinText` | Map look | Advanced choices > Map look | Pin text style |
| `CMFFile_Movement_Area` | Map movement | Advanced choices > Map movement | Map area |
| `CMFFile_Movement_Pan` | Map movement | Advanced choices > Map movement | Pan and zoom feel |
| `CMFFile_Movement_Opening` | Map movement | Advanced choices > Map movement | Opening and closing |
| `CMFFile_Painting_WhiteOrchard` | Map painting | Advanced choices > Map painting | White Orchard |
| `CMFFile_Painting_WhiteOrchardWinter` | Map painting | Advanced choices > Map painting | White Orchard (winter) |
| `CMFFile_Painting_Velen` | Map painting | Advanced choices > Map painting | Velen and Novigrad |
| `CMFFile_Painting_Skellige` | Map painting | Advanced choices > Map painting | Skellige |
| `CMFFile_Painting_KaerMorhen` | Map painting | Advanced choices > Map painting | Kaer Morhen |
| `CMFFile_Painting_Vizima` | Map painting | Advanced choices > Map painting | Vizima |
| `CMFFile_Painting_IsleOfMists` | Map painting | Advanced choices > Map painting | Isle of Mists |
| `CMFFile_Painting_Spiral` | Map painting | Advanced choices > Map painting | The Spiral |
| `CMFFile_Painting_Toussaint` | Map painting | Advanced choices > Map painting | Toussaint |
| `CMFFile_Drawings_Ignore1` | Drawings on the map | Advanced choices > Clicks and drawings | Leave out drawings from (1st) |
| `CMFFile_Drawings_Ignore2` | Drawings on the map | Advanced choices > Clicks and drawings | Leave out drawings from (2nd) |
| `CMFFile_Drawings_Ignore3` | Drawings on the map | Advanced choices > Clicks and drawings | Leave out drawings from (3rd) |
| `CMFFile_Painting_World` | Map painting | Advanced choices > Map painting | World overview |
| `CMFFile_Painting_Crests` | Map painting | Advanced choices > Map painting | Region crests and markers |
| `CMFFile_Movement_View` | Map movement | Advanced choices > Map movement | Opening view |
| `CMFFile_Behaviour` | Map behaviour | Basic choices | Map behaviour |
| `CMFFile_Behaviour_InfoBoxDodge` | Map behaviour | Advanced choices > Map behaviour | Info box moves out of the way |
| `CMFFile_Behaviour_InfoBoxHeight` | Map behaviour | Advanced choices > Map behaviour | Info box height and scrolling |
| `CMFFile_Movement_ZoomOut` | Map movement | Advanced choices > Map movement | Zoom out to the whole region |
| `CMFFile_Movement_Controller` | Map movement | Advanced choices > Map movement | Controller crosshair |
| `CMFFile_Behaviour_HoverNames` | Map behaviour | Advanced choices > Map behaviour | Names only on hover |
| `CMFFile_Movement_Wide` | Map movement | Advanced choices > Map movement | Fill wide screens |
| `CMFFile_Fallthrough` | every feature | General | If the chosen mod has nothing for a pin |
| `CMFDebug` | the log | General | Write the who-wins report to the log |
| `CMFProviderOrder1` | the Mod order | Mod order | 1st |
| `CMFProviderOrder2` | the Mod order | Mod order | 2nd |
| `CMFProviderOrder3` | the Mod order | Mod order | 3rd |
| `CMFProviderOrder4` | the Mod order | Mod order | 4th |
| `CMFProviderOrder5` | the Mod order | Mod order | 5th |
| `CMFProviderOrder6` | the Mod order | Mod order | 6th |
| `CMFProviderOrder7` | the Mod order | Mod order | 7th |
| `CMFProviderOrder8` | the Mod order | Mod order | 8th |

`CMFFile_Fallthrough=Vanilla` makes a chosen mod that has nothing for a pin show the game's own look there, instead of the next mod's. `CMFDebug=true` writes the who-wins report to the script log. `CMFProviderOrder1` to `CMFProviderOrder8` hold one folder name each, earliest first.
<!-- cmf:settings-keys end -->
