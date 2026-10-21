# Map Quest Insight on Conjunction Map Framework: the change for its author

This note is for the author of Map Quest Insight (Nexus 14219). It shows how Map Quest Insight's map features appear on Conjunction Map Framework's (CMF) world map through CMF's general calls, using the adapter CMF ships as the worked example, [`source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight`](../../source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/). CMF has no Map Quest Insight calls of its own: every call below is one any mod can use.

## Why the features disappear under CMF

Only one `panel_worldmap.redswf` loads. When CMF is installed, CMF's map loads instead of yours. Your scripts keep running: titles, the sectioned info box, "ALSO HERE", the hide switches and the tracker names all still work. But your scripts first ask your map file for its handshake number (`qmiApi`), and then write sizes, quest kinds, labels, tints and the box height under your own field names. CMF's map answers none of those names, so without the adapter nothing reaches the screen.

## What the adapter does

The adapter is one script with four wrappers. Your mod does not change.

1. **Handshake.** An outer `OnConfigUI` wrapper sets your own `QMI_swfApi = 3` and `QMI_swfApiRead = true` before your wrapper runs, so your scripts send everything they send your own map file 3.
2. **Signpost tabs and box height.** After your `UpdateDisabledMapPins` wrapper, it asks your `QMI_SignsHiddenNow` which filter tabs hide signposts now, and registers your "Info box height" (`QMI_InfoBoxMaxHeight`, held to 100-1080 px) with CMF.
3. **Each pin.** API version 4 calls `OnPinReady(dataObject, mapContext)` for every pin, after every mod has added its pins. The adapter wraps it, reads your pin fields and passes each value to CMF.

| Your pin field | CMF call |
|---|---|
| `qmiIconScale` | `CMFStylePinScale(provider, pin, percent)` |
| `qmiIconTop` | `CMFStylePin(provider, pin, CMFPropertyLabelPlace(), "", tenths)` |
| `qmiIconKind` | `CMFStylePinIcon(provider, pin, url)`: a frame of the game's pin icon (`frame:HorseRace` and so on), or your own main quest, contract and Gwent icons, which the adapter ships with your permission |
| `qmiLevelText` | `CMFStylePinLabel(provider, pin, yourHtml)`; a signpost name of `" "` hides the pin label instead |
| `qmiNoCrosshairLabel` | `CMFStylePin(provider, pin, CMFPropertyLabelHide(), "crosshair", 1)` |
| `qmiIconTint` | `CMFStylePinTint(provider, pin, rgb)` |
| signposts in hidden tabs | `CMFStylePin(provider, pin, CMFPropertyTabHide(), "Quests", 1)` (or the other tab names) |

The box height is one claim for every pin: `CMFRegister(provider, CMFPropertyInfoBoxHeight(), '', '', "", height)`.

The provider in every call is `modMapQuestInsight`, your own folder name. So when another mod styles the same pin, the folder that sorts first wins, exactly as without CMF.

Its script file name starts with `zz_` so it sorts after `qmiSettings.ws` and `questMapInfo.ws`. Wrappers nest by script file name, so its wrappers run around yours.

Because it calls your functions and reads your fields, the adapter compiles only with Map Quest Insight installed, and from its smooth map movement update only with 1.6.1 or later (it calls `QMI_OptZoomOut`, which 1.6.0 added). Players install and remove the two together.

**"Faster map" and "Zoom out to whole region"** (API version 6, not yet run in game). The adapter's `OnConfigUI` wrapper reads both switches after your settings load and sends your map file's values as CMF's `navigation` and `opening` keys, or `"unset"` for each key while a switch is off; the values are in the icon pack guide, section 12. It sends them only when CMF has the `opening` part.

**"Spread stacked quest markers"** (API version 6, not yet run in game). The same wrapper sends your map file's spreading values as CMF's `spread` keys while `QMI_SpreadStackedMarkers()` is on, or `"unset"` while it is off. An `AddPinTypeData` wrapper finds each quest pin's quest as you do, asks your `QMI_SpreadRank` and claims it with `CMFStylePin(provider, pin, CMFPropertySpreadRank(), "", rank)`, so CMF's row selects the quest your map file would. Your ALSO HERE list stays, because your script asks your map file for `qmiSpreadMap`, which CMF's map does not answer; a port can drop it when the switch is on and `CMFHasAbility('spread', '')` answers true.

**Pin fields.** The game builds pin objects from the map's pin class and drops any field that class does not declare. CMF's map declares your `qmi*` field names for the adapter, under a compatibility comment; CMF itself never reads them.

## The change for you

You can make the adapter unnecessary with an optional "CMF support" folder of your own:

```
Mods/
  modMapQuestInsightCMF/                       any folder name of yours, starting with "mod"
    README.txt
    content/scripts/local/zz_modmapquestinsightcmf_cmf.ws
```

It stays a separate folder because a CMF call fails to compile when CMF is not installed. Players without CMF install your mod as today; players with CMF add the folder.

Two ways to write it:

- **Keep your fields.** Copy the adapter's script and keep `modMapQuestInsight` as the provider (your main folder's name, so your folder order stays the same). Nothing else changes.
- **Call CMF directly.** Where your code now writes `dataObject.SetMemberFlashNumber("qmiIconScale", scale)`, call `CMFStylePinScale("modMapQuestInsight", dataObject, scale)` instead, and so on down the table above. Do it in an `OnPinReady` wrapper on `CMFCore`, or in your own `AddPinTypeData` wrapper; per-pin calls count in the same map opening either way. Then you need no handshake and no `qmi*` fields.

`tools/cmf_pack.py check <your folder> --adapts modMapQuestInsight` checks the folder with your main folder's name as the provider.

When you ship it, players drop the adapter. If both are installed, both name `modMapQuestInsight`, so the call that runs later replaces the earlier one on each pin, without a log line; with the same values, nothing changes on screen.

## What does not come back this way

- **Your art.** Your icons for main quests, contracts and Gwent quests live inside your map file and cannot be loaded at run time. The adapter ships the copies you sent (2026-10-21) in its own `texture.cache`, exactly as your own CMF support would ship them: put the pictures in your folder's `art/`, build it with `tools/cmf_pack.py`, and pass their `img://icons/<your folder>/...` paths to `CMFStylePinIcon`. CMF itself carries no quest art.
- **The quest pin draw order.** CMF has no general call for it yet.

## Status

Passed in game on 2026-10-20 with API version 4 (the N4 launch): the handshake, the converted level labels and colours, the stand-in quest icons (then stored in CMF; they moved into the adapter on 2026-10-20 and are re-checked in the next launch) and the scrolling info box. The adapter is unchanged under API version 5.
