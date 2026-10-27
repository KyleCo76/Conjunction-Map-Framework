# Map Quest Insight adapter

**Adapter version 2.1.0, for Map Quest Insight 2.0.1 or later and CMF API 13 (CMF 1.6.0).** Version 2.1.0 adds Map Quest Insight 2.0's Quest List and its two hint row entries (see "Quest List (2.1.0)" below); players on Map Quest Insight 2.0.0 keep adapter 2.0.0. Version 2.0.0 carries Map Quest Insight 2.0's map through CMF's general abilities: quest icons by type (round badges or symbols, level colours, tracked gold), the Sticker icons for the game's markers, the quest box beside its marker, the category panel and overview visibility, Show more in quest boxes, the full-screen map and its edge fades, and the clean corner HUD (see "2.0 features" below). Map Quest Insight's 2.0 map features carried with permission from Wolfer. Players on an older CMF or Map Quest Insight 1.6 keep adapter 1.2.0: this version cannot compile there (`CMFStyle` and the `OnInfoFold` hook are API 13, and the 2.0 functions are Map Quest Insight 2.0's).

Adapter 1.2.0 sends where Map Quest Insight's own map file puts a tall info box as `tooltip` `tall*` keys (CMF API 12), apart from the box height; see Known differences. Adapter 1.1.1 declares `modMapQuestInsight` at game startup with generic property 38 when `CMFHasProperty(38)` succeeds (API 11). Presence is independent of feature settings. The source-mod compile dependency and minimum CMF version remain unchanged.

`modCMFAdapterMapQuestInsight` is a separate mod that sits between Conjunction Map Framework (CMF) and Map Quest Insight 2.0.0 or later (Nexus 14219). Map Quest Insight stays unchanged. It normally talks to its own map file: it asks that file for a handshake number, then writes its values onto the map and onto each pin. CMF's map reads none of those names, so the adapter turns each value into CMF's general calls, the way Map Quest Insight's author would when porting. It is the worked example of an adapter that translates a mod's own field names through CMF's general hooks (N4 spec, [a design note kept in the private development repository](../../../a design note kept in the private development repository), section 8.4). The author-facing version is [`docs/authors/map-quest-insight-adapter.md`](../../../docs/authors/map-quest-insight-adapter.md).

It does not retire: it stays the guide for Map Quest Insight's author until a port exists.

## Provenance

Read only, for its interface: Map Quest Insight 1.5.0's `questMapInfo.ws` (SHA-256 `b1d766c6dffd465e9155127265c0f09c9ceb7dcc04de393feb7652e63a4c8ffb`) and `qmiSettings.ws`, the copies in the verified install set a launch record kept in the private development repository, which match the reference archive `MapQuestInsight-1.5.0 14219 …zip` (SHA-256 `bf65903e…0d81790`). The adapter copies none of its code.

| Map Quest Insight name | `questMapInfo.ws` | Used for |
|---|---|---|
| `QMI_swfApi`, `QMI_swfApiRead` (fields on `CR4MapMenu`) | 3196-3200 | the handshake, set to 3 by the adapter |
| `QMI_MapCanFastTravel() : bool` (method on `CR4MapMenu`) | 3491 | its fast-travel test for signpost hiding |
| `QMI_SignsHiddenNow(mode : int, canTravel : bool) : bool` | 1388 | whether signposts are hidden now |
| `QMI_SignsInQuestsFilter() : int`, `QMI_SignsInOtherFilters() : int` | 623-624 | its two signpost options |
| `QMI_InfoBoxMaxHeight() : float` | 224 | its "Info box height" in px |
| pin fields `qmiIconScale`, `qmiIconTop`, `qmiIconKind`, `qmiNoCrosshairLabel`, `qmiLevelText`, `qmiIconTint` | 3889-3968 | what it writes on each pin |
| `QMI_GetQuestLevel(journalQuest : CJournalQuest) : int` (global) | 1056 | a quest's level, as the journal computes it (its own private `QMI_GetLevelCached` caches this value) |
| `QMI_SpreadStackedMarkers() : bool`, `QMI_SpreadRank(curQuest : CJournalQuest, questLevel : int) : int` | 1.6.0 and later (not in 1.5.0) | its "Spread stacked quest markers" switch and the rank of a quest in a stack |
| `QMI_OptTypeIcons() : bool`, `QMI_OptUniformIcons() : bool` (`qmiSettings.ws` 546-547) | 2.0.0 | "Quest icons by type" and "Round quest icons" |
| `QMI_IconKind(journalQuest : CJournalQuest) : int` | 2.0.0, 2320 | a quest's kind, 1 to 10 |
| `QMI_LevelBandTint(questLevel : int) : int` | 2.0.0, 2170 | the level colour as 0xRRGGBB, 0 when icons are not coloured |
| `QMI_ColorTrackedIcon() : string` | 2.0.0, 936 | the tracked symbol's gold, `#RRGGBB` |
| `event OnQmiDescMore(isOpen : int)` (on `CR4MapMenu`) | 2.0.0, 6030 | its own map's Show more event, which saves the state |

The 2.0.0 lines were read on Kyle's PC (2026-10-26, declarations only; nothing copied). Wolfer named these names stable (2026-10-25). The adapter also reads these settings by their menu names and writes none: `[qmiGeneral]` `qmiMigrated200`, `qmiCatPanel`, `qmiMapOverview`, `qmiFullScreen`, `qmiSideHud`; `[qmiWide]` `qmiUwMap`, `qmiUwSidePos`; `[qmiBox]` `qmiQjBoxBeside`, `qmiJournalText`, `qmiDescOnAsk`, `qmiDescRemember`, `qmiDescMoreOpen`; `[qmiPins]` `qmiQuestIconSize`; `[qmiOther]` `qmiIconStyle`. On the map's root it sets `qmiDmApi` and `qmiDrApi` (Wolfer's Show more handshake) and reads back `qmiDmMoreW` and `qmiDmLessW`. With Full-screen map Off it also sets `qmiHubOver` (true) there: Map Quest Insight 2.0.1's menu files draw the game's menu above any map, and with Full-screen Off it keeps the menu's dark background and X, which then cover CMF's whole map (start C, 2026-10-26). `qmiHubOver` is its own opt-in for a map drawn under the menu; it is not on Wolfer's stable list yet. Adapter 2.0.0 ships with it (Kyle 2026-10-26 21:32Z) while Wolfer is asked to make it stable or to hide the background himself on a map that is not his own; the adapter follows his answer.

## How it works

| Step | Where | What |
|---|---|---|
| Handshake | `@wrapMethod(CR4MapMenu) OnConfigUI`, outermost | sets `QMI_swfApi = 3` and `QMI_swfApiRead = true` before Map Quest Insight's wrapper and the game's body run, so Map Quest Insight sends everything it sends its own map file 3. CMF's panel declares no `qmiApi`. The game declares `OnConfigUI` an event, so the wrapper returns its result (from 1.2.0). |
| Faster map and zoom out | the same wrapper, after `wrappedMethod()` (settings reloaded, before CMF's map asks for its theme) | `MqiAdapterSendMotion`: when CMF has the `opening` part, sends Map Quest Insight's own values as `navigation` and `opening` keys while `QMI_OptFasterMap()` or `QMI_OptZoomOut()` is on, and `"unset"` for each key while it is off; each key only when `CMFHasAbility` answers true |
| Spreading stacked markers | the same wrapper, after the motion keys | `MqiAdapterSendSpread`: when CMF has the `spread` part, sends Map Quest Insight's own map file values as `spread` keys (`on` 1, `anyPin` 0, `enterRadius` 20, `stackDistance` 24, `maxPins` 8, `gap` 48, `openMs` 150, `closeMs` 120, `lockRadius` 24, `keepRadius` 48) while `QMI_SpreadStackedMarkers()` is on, and `"unset"` for each key while it is off |
| Ultrawide map | the same wrapper, after the spread keys | `MqiAdapterSendWide`: when CMF has `('wide', 'fill')` (API 10) and the `qmiWide` settings group exists, sends Map Quest Insight 1.6.2's Ultrawide map switch and side panels position as `wide` keys; a value never saved (`""` or `"-1"`) is Map Quest Insight's default, On and 100 % (see Known differences) |
| Tall info box place | the same wrapper, after the wide keys | `MqiAdapterSendBox`: when CMF has `('tooltip', 'tallMinHeight')` (API 12), sends the places Map Quest Insight's own map file uses for a box taller than 330 px (see Known differences) |
| Signpost tabs and box height | `@wrapMethod(CR4MapMenu) UpdateDisabledMapPins`, after Map Quest Insight's (settings loaded, before the pins are sent) | asks Map Quest Insight which filter tabs hide signposts now ("Quests", and "Exploration,NPCs,Buffs") and keeps the list on `theGame` (`@addField(CR4Game) mqiAdapterNoSignTabs`); registers `CMFRegister("modMapQuestInsight", CMFPropertyInfoBoxHeight(), '', '', "", height)` with `QMI_InfoBoxMaxHeight()` rounded and held to 100-1080 (0 withdraws) |
| Spread rank | `@wrapMethod(CR4MapMenu) AddPinTypeData`, outermost | for each quest pin that is not fast travel, while the switch is on: finds the pin's quest as the game does (objective, then its quest), asks `QMI_SpreadRank(quest, QMI_GetQuestLevel(quest))` and claims a rank above 0 with `CMFStylePin(…, CMFPropertySpreadRank(), "", rank)`, so CMF's spread selects the pin Map Quest Insight's own map file would. The quest is known only here: `OnPinReady` sees the pin object, which carries no quest. |
| Each pin | `@wrapMethod(CMFCore) OnPinReady` | reads Map Quest Insight's pin fields and calls CMF's per-pin calls, below |

| Pin field | CMF call |
|---|---|
| `qmiIconScale` (not 0 or 1) | `CMFStylePinScale(…, round(value × 100))` |
| `qmiIconTop` (above 0) | `CMFStylePin(…, CMFPropertyLabelPlace(), "", round(value × 10))` |
| `qmiIconKind` on quest pins that are not fast travel | `CMFStylePinIcon`: kinds 4, 6-10 use frames of the game's pin icon (`frame:TreasureHuntMappin`, `HorseRace`, `BoatRace`, `FistFight`, `KnightErrant`, `WineContract`); kinds 1, 3 and 5 use Map Quest Insight's own icons `img://icons/modcmfadaptermapquestinsight/quest_main.png`, `quest_contract.png`, `quest_gwent.png` (its `art/`, cooked into its own `texture.cache` by `tools/cmf_pack.py build`); kinds 0 and 2 keep the diamond |
| `qmiLevelText` on fast-travel or quest pins | `CMFStylePinLabel` with Map Quest Insight's own HTML; a signpost name of `" "` instead hides the pin label |
| `qmiNoCrosshairLabel` | `CMFStylePin(…, CMFPropertyLabelHide(), "crosshair", 1)`, or `"pin,crosshair"` with the signpost case |
| `qmiIconTint` (not 0) | `CMFStylePinTint` |
| fast-travel pins, when the tab list is not empty | `CMFStylePin(…, CMFPropertyTabHide(), tabs, 1)` |

Every claim names `modMapQuestInsight`, Map Quest Insight's own folder, as its provider (N4 spec 7.3), so folder order between mods is the same with CMF as without it.

**Pin fields.** The game builds pin objects from the map's pin class and drops any field that class does not declare. CMF's panel therefore declares Map Quest Insight's `qmi*` pin fields as compatibility names for this adapter; CMF itself reads none of them (`docs/development/pin-fields.md`).

**Wrapper order.** Wrappers nest by script file name. The file name starts with `zz_` so it sorts after `qmiSettings.ws` and `questMapInfo.ws`, so its wrappers run around Map Quest Insight's.

**Log.** None of its own from 1.2.0 (up to 1.1.1, one line for each of the first eight quest pins of a session; a log line per pin breaks the log rule). CMF's own lines show its claims (`provider=modMapQuestInsight claims=`).

## 2.0 features

All in `zz_modcmfadaptermapquestinsight_cmf.ws` unless named, each sent only when `CMFHasAbility` answers true, and withdrawn (`"unset"`) when its setting is off.

| Map Quest Insight 2.0 setting | Adapter | CMF 13 ability |
|---|---|---|
| "Quest icons by type" + "Round quest icons" | `AddPinTypeData` wrapper, `MqiAdapterQuestIcon`: the icon = `badgesym_<kind>.png` (white, or `QMI_ColorTrackedIcon()` on the tracked quest's pins, those whose `visibleType` is not `QuestObjectiveOther`), the picture under it (42) = `badge_<kind>.png`, its tint (43) = `QMI_LevelBandTint(level)` or white; the pin's size = "Quest marker size", the picture grown 31 / 14.5 (44) so the game's glow and the tracked ring keep that size; the label's distance grows with the picture | properties 42, 43 and 44, per-pin icon, tint, size and label place |
| "Quest icons by type", round icons off | the icon = `symbol_<kind>.png` in the level colour, gold when tracked; the picture grown 18 / 14.5 (44) over "Quest marker size" | per-pin icon, tint, size, property 44 and label place |
| "Map icon style" Sticker (`[qmiOther] qmiIconStyle`) | `zz_modcmfadaptermapquestinsight_sticker.ws`: 125 type claims to 121 Sticker pictures when it turns to Sticker, withdrawn with property 40 when it turns to Vanilla, before the pins are built | `CMFRegisterIcon`, property 40 |
| "Info box beside the marker" | `MqiAdapterSendBeside`: `CMFStyle(…, 'tooltip', <quest type>, 'clearMinHeight', 1)` and `'clearAnchor' "pin"` for the 19 quest pin types | per-type tooltip keys, `clearAnchor` |
| "Map category panel", "Map overview" | `MqiAdapterSendPanels`: `legend show` auto with `autoHideMs` 3000 and `padShowFirst` 1, or always; `preview show` moving with `movingMs` 1500, always or never | panel visibility keys |
| "Show more" (`qmiJournalText` and `qmiDescOnAsk`) | `MqiAdapterAskDescMore` sets `qmiDmApi` and `qmiDrApi` on the map's root before Map Quest Insight's wrapper reads them; `MqiAdapterSendFold` sends `foldTag` "qmimore", its words, `foldKeyKb` SpawnHorse (its X), `foldKeyPad` CameraLock (its R3) and `foldOpen`; the `OnInfoFold` hook calls its `OnQmiDescMore` | `rootValues`, fold keys, `OnInfoFold` |
| "Full-screen map" Clear / Soft fade / Dark fade | `MqiAdapterSendFullScreen`: `map top` 0 and `bottom` 1080, plus two screen `band` drawings (top and bottom, 180 px, black at the edge to clear, alpha 0.55 or 0.85, under every panel) | map area keys, band drawings |
| "Corner HUD" Clean | `MqiAdapterSendCornerHud`: `tracker hide` plate and two glows (black, 1 / 2 / 6 and 0.8 / 6 / 2) | tracker keys |
| "Signposts in other filters" (2.0 widened) | `UpdateDisabledMapPins` wrapper adds All, Default and, without fast travel, General | per-pin tab hide |
| no spreading on the fast travel map (2.0.1) | `MqiAdapterSendSpread(travelMap)` and the rank claim skip it | spread keys |

One log line per opening (`CMF mqi adapter opening icons= size= sticker= beside= panel= overview= showMore= words= fullScreen= cornerHud= travelMap=`) names what the adapter follows. The quest icon settings and the travel map test are read at the opening's first quest pin (`MqiAdapterPinsInit`), because the game adds the pins inside `OnConfigUI`, after Map Quest Insight's wrapper has loaded its settings; read after the opening, the first opening's pins kept the old icons.

**Art.** `art-src/mqi_icons.py` cuts Wolfer's `MQI 2.0.1 icons for CMF.zip` (SHA-256 `2204facd…95d3`, never committed) into `art/`: `sticker_<name>.png` (a square of the game icon's longer side around the Sticker's middle, so CMF draws it at its own size), `badge_<kind>.png` (the badge's middle 31 of 32 map units), `badgesym_<kind>.png` (the symbol scaled by its "symbol on badge" factor on the badge's canvas, Wolfer's two-layer recipe) and `symbol_<kind>.png` (the middle 18 of 20 map units), all 64 × 64, and writes the Sticker table. Only cuts and resizes; no other change to the art. `--check` compares instead of writing.

## Quest List (2.1.0)

`zz_modcmfadaptermapquestinsight_questlist.ws` and the movie `movie-src/MqiAdapterQuestList.as` (the adapter's own code, written from Map Quest Insight 2.0's player-facing description and Wolfer's rundown; no Map Quest Insight code, and his map file was never decompiled). Wolfer allowed the adapter to carry the 2.0 map features if they follow Map Quest Insight's own settings (2026-10-25), and named three more names stable for it in 2.0.1.

| Map Quest Insight 2.0.1 name | Used for |
|---|---|
| `QMI_QjHomeArea() : name` | the player's journal area: where "this region" and the distances are, and where the map goes back to on close |
| `QMI_QuestHiddenByCategory(journalQuest : CJournalQuest, questLevel : int) : bool` | whether its hide switches hide a quest, until a filter row is changed in this opening |
| `QMI_OptQjClose() : int` | "Map when the list closes" (0 back to you, 1 stay) |
| `QMI_GetQuestLevel`, `QMI_IconKind`, `QMI_LevelBandTint` (2.0.0) | a quest's level, its kind (icon and filter row) and its level colour |

The quests, their order and their objectives come from the game's own map menu and journal (`CR4MapMenu.GetQuests()`, the list the game's map sends its quest tracker; phases, objectives and their map pin ids, `NameToFlashUInt(GetMapPinID())`, as the game's own `OnShowObjectiveOnMap`); names and regions are the game's journal words. Tracking, the objective pick and the journal are the game's own map events (`OnTrackQuest`, `OnHighlightObjectiveWithQuestChange`, `OnShowQuestInJournal`, `OnCycleObjectivesDefault`).

| Map Quest Insight setting (`[qmiQuest]` unless named) | In the list |
|---|---|
| `qmiQjPanel` "Quest list on the map" | the list and its [F] hint; off withdraws both |
| `qmiQjSort` | the first sort (nearest, lowest level, highest level, name, quest log); T or R2 changes it for the opening; the tracked quest always first |
| `qmiQjThisRegion` "Only this region" (declared in the hidden `qmiHide` group and read and written by that name, stored in `[qmiQuest]`) | the list's first row below the quests; toggling it writes the setting and saves, as its own list does |
| `[qmiHide] qmiHide*` | the filter rows, in its menu's order; toggling one writes that switch and saves (map markers follow at the next opening, see gaps) |
| `qmiQjTextSize` | text size, 70 to 130 % |
| `qmiQjCentre` | centring on the picked quest's marker |
| `qmiQjOtherRegions` | a quest of another region: 0 stays, 1 switches the map when picked, 2 also while browsing (about 0.6 s on a row) |
| `qmiQjClose` (via `QMI_OptQjClose`) | on close, 0 goes back to the player's region and position after the list switched |
| `qmiQjPan` | panning while the list is open (mouse only, see gaps) |
| `qmiQjDistance`, `qmiQjRegion`, `qmiQjNameCol`, `qmiQjDlcName` | distance, region, name in the journal's difficulty colour, expansion name |
| `[qmiGeneral] qmiFullScreen` | how see-through the list is (MQI's full-screen list is see-through) |
| `[qmiGeneral] qmiSideHud` Clean | the [G] Change tracked objective hint |

CMF 13 abilities used: a `screen` `movie` drawing with `focus` 1 and `listen` `mqiadapter.questlist` (`OnMapListening` sends the first value), the movie's `map` object (`pins`, `area`, `player`, `center`, `selectPin`, `highlightPin`, `noSpread`, `showArea`, `lockPan`, `focus`), `OnMovieEvent`, the managed hint list (`hints` `list`, `OnMapHints`, `OnDrawingClicked` with `'hints'`), and `OnMapAreaReady` for a log line.

Keys while the list is open (it takes the keyboard and pad; the mouse keeps working on the map): Up/Down choose, Right/Left show or hide a quest's objectives, E or Enter track (on an objective: track that objective), H journal, T sort, C fold a category, F or Esc close. Mouse: click picks, double click tracks, wheel scrolls. Pad: LT opens and closes, A tracks, X journal, R2 sort, Y fold, B closes.

Log lines: `CMF mqi adapter questlist on= home= close= other=` per opening, `questlist hints entries=`, `questlist sent seq= open= quests= objectives=`, `questlist open count=`, and one per action (`track quest=`, `objective`, `journal quest=`, `thisRegion=`, `filter <switch>=`, `open=`, `region=`, `area=`).

Words: `strings.json` (block 2000240000, 25 strings, English in all 18 tables; the block was scanned free on Kyle's PC, 2026-10-27). Build on Kyle's PC: `python -B tools/cmf_mqi_questlist.py --java <java> --ffdec <ffdec.jar> --out build/mqi21/<name>` runs the pack build above, compiles the movie into `content/blob0.bundle` and `metadata.store` at `gameplay\gui_new\swf\modcmfadaptermqi\questlist.redswf`, writes the 18 tables with the creation skill's `w3strings.py`, and writes `build.json` and `SHA256SUMS`.

### CMF ability gaps (for Kyle; CMF core and panel unchanged)

1. **One hint row owner.** The managed hint list replaces the whole row while it is offered, so another mod's legacy hint entries (Ink and Iron's row, for example) do not show while the Quest List is on. A general "add entries to the row" ability would let both show.
2. **Short click to track.** Map Quest Insight 2.0.1 tracks a quest with a short click on its marker. CMF's per-pin input claim (property 16 "hold") covers keyboard and mouse as well as the pad, so carrying it would change hold-to-track for keyboard players. Not carried; a per-input choice on that claim would carry it.
3. **Keys go to the list only.** A focused movie takes every key, so "Move the map with the list open" works with the mouse only. A way for a movie to hand chosen keys back to the map would carry it.
4. **Filters on the map.** Map Quest Insight reads its hide switches when the map opens, so a filter row changes the markers at the next opening; the list itself updates at once. A general "redraw pins now" call would show it at once.
5. **Parts over the list.** CMF draws the region title and the legend above screen drawings and can hide neither (their `hide` key removes only plates). MQI's own list covers the left column, and its legend rows auto-hide. So the list sits between the title and the legend (screen y 180 to 630, launch start A, 2026-10-27). A general ability would carry MQI's look: a focused screen drawing asks CMF to hide named parts (legend, title) while it shows.
6. **The quest you switch to by browsing** (other regions 2) has no signpost glow on the region map as Map Quest Insight's own list gives it.

## Known differences

- **Quest List under CMF.** See "CMF ability gaps" above. Whether the game's own action on F (keyboard) or LT (pad) also reacts on CMF's map is checked in the 2.1.0 launch.

- **ALSO HERE stays with spreading on.** Map Quest Insight drops its "ALSO HERE" list only when its own map file answers `qmiSpreadMap`. CMF's map does not declare that name (no mod-specific names in core), and its map class is sealed, so the adapter cannot set it either: the game drops a write to a member the class does not declare. So under CMF the row spreads and the info box still lists the other quests on the spot, as Map Quest Insight does with spreading off. A port that asks `CMFHasAbility('spread', '')` can drop it.

- **Ultrawide map (adapter 1.1.0, CMF API 10).** Map Quest Insight 1.6.2's Ultrawide map page becomes CMF's `wide` keys: `MqiAdapterSendWide` reads `GetVarValue('qmiWide', 'qmiUwMap')` and `('qmiWide', 'qmiUwSidePos')` by menu name, so the adapter still compiles with 1.6.1. Switch on: `wide fill` 1 and `panels` = side panels position / 100; switch off: `wide fill` 0 (the 16:9 map, as its own map file does) and `panels` unset; an empty answer (1.6.1, no page) sends nothing. Only when `CMFHasAbility('wide', 'fill')` answers true. The "Fill wide screens" choice decides between mods.

- **Tall info box (adapter 1.2.0, CMF API 12).** Map Quest Insight's own map file (1.6.2 and 2.0.0 read on the player's PC, 2026-10-25) moves a box taller than 330 px to x 1300 between y 130 and 906, or, while the quest tracker is not in its normal state or the mouse is right of x 960, to x 112 between y 206 and 1006 under the legend, scaled to fit. Up to CMF API 11 CMF's map did this for every box height claim, so any mod sending a height moved tall boxes too. From API 12 the height only makes the text scroll, and `MqiAdapterSendBox` sends those places as `tallMinHeight` 330, `tallX` 1300, `tallTop` 130, `tallBottom` 906, `tallAltX` 112, `tallAltTop` 206, `tallAltBottom` 1006, `tallUnderLegend` 1 and `tallClear` 1, each only when `CMFHasAbility` answers true, and withdraws them (`"unset"`) while its "Info box height" is 0, since its map file moves only the scrolling box. They answer the "Info box moves out of the way" choice, like Ink and Iron's adapter's `clear*` keys. Map Quest Insight 2.0's quest box "beside the marker" is a different box and is not carried. Its map hides its category panel and shows its overview only while moving, so those corners are free there; CMF's map keeps the legend and the overview, so `tallClear` 1 keeps the box off them (launch 2026-10-25 line 3, Kyle's pick "Both"; hiding the panels the way Map Quest Insight 2.0 does is left to the 2.0 build).

## Dependencies

- **Map Quest Insight 2.0.1 or later, a compile dependency.** The adapter uses its functions and fields, so the scripts fail to compile without it; from 2.1.0 the Quest List uses names that exist only from 2.0.1 (`QMI_QjHomeArea`, `QMI_QuestHiddenByCategory`, `QMI_OptQjClose`). Install and remove the two together; remove the adapter first.
- **CMF API 13 (CMF 1.6.0).** `CMFStyle` and the `OnInfoFold` hook arrive in API 13, so the adapter compiles only with that CMF. Earlier: `CMFPropertySpreadRank` (API 6), `CMFStylePart` and `CMFHasAbility` (5), `OnPinReady` and the per-pin calls (4).

## Files

| Path | What |
|---|---|
| `modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_cmf.ws` | the startup declaration, the map/pin wrappers, the 2.0 features and the opening log line |
| `modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_questlist.ws` | the Quest List: its drawing, data, hints and actions (2.1.0) |
| `movie-src/MqiAdapterQuestList.as` | the Quest List movie's source, compiled by `tools/cmf_mqi_questlist.py` |
| `strings.json` | the Quest List's words (2.1.0) |
| `modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_sticker.ws` | the Sticker claims (table written by `art-src/mqi_icons.py`) |
| `modCMFAdapterMapQuestInsight/art/{sticker,badge,badgesym,symbol}_*.png` | Wolfer's 2.0.1 pictures, cut by `art-src/mqi_icons.py`; shipped with their permission (2026-10-25), credited |
| `art-src/mqi_icons.py` | cuts the 2.0.1 icon set into `art/` and writes the Sticker table |
| `modCMFAdapterMapQuestInsight/art/quest_*.png` | Map Quest Insight's main quest, contract and Gwent quest icons, 96 × 96, white with its dark outline so the level tints and the tracked gold multiply them; sent by its author, Wolfer, for the adapter and shipped with their permission (2026-10-21) from `MQI icons for CMF.zip` (SHA-256 `d14cc5abbe2b376a11d76194a24cb2bbcad3aa8fdc036ffc43b14b99459cdc86`), unchanged; the zip's 128 × 128 copies are not used |
| `modCMFAdapterMapQuestInsight/README.txt` | for players |
| `tests/test_cmf_mqi_adapter.py` | static checks: the Map Quest Insight names it uses exist with these signatures in 1.5.0, wrapper order, every claim names `modMapQuestInsight`, it writes no pin field itself, the kind table, the author's three icons check clean, plus WitcherScript hygiene |

Build: `python tools/cmf_pack.py build source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight --adapts modMapQuestInsight --out <new folder>`, which cooks `art/` into `content/texture.cache`. It reports no errors. Expected warnings: non-literal arguments in the box height claim; art not used by a literal `CMFRegister` call (the Stickers go through one helper, badges and symbols are named per pin); Stickers and badge glows reaching the picture's edge; a few percent of painted pixels changing in compression; the Sticker claims sent from the map's opening instead of `OnGameStarted` (they follow a menu setting).

## Status

2.1.0: launched 2026-10-27 on Windows with keyboard and mouse, 16:9 and 21:9, with CMF 1.6.1 and Map Quest Insight 2.0.1: opening and closing the list, tracking, the journal, a quest in another region, "Only this region", a "Show on the map" row; the movie and the words are built on Kyle's PC. Not run: a controller, G with a quest of two or more objectives. 2.0.0: static checks only (`tests/test_cmf_mqi_adapter.py`, `tools/ws_lint.py`); its launch with Map Quest Insight 2.0.1 is next. Before that: static checks only. Not yet compiled or run in game with CMF 4: the N4 launch proves the handshake, the conversion and the stand-in icons together. The Faster map and zoom-out keys, the spread keys and the spread rank have not yet run in game.

## Limits

- Windows only; Proton not checked.
- `QMI_OptZoomOut`'s signature is taken from the smooth map movement record (1.6.1 `qmiSettings.ws` 422), and `QMI_SpreadStackedMarkers` and `QMI_SpreadRank` from the stacked-marker research (version recheck, section 7.3); `tests/test_cmf_mqi_adapter.py` checks them, and that `QMI_GetQuestLevel` is still there, only when `CMF_MQI16_SCRIPTS` names a 1.6.1 copy.
