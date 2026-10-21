# Map Quest Insight adapter

`modCMFAdapterMapQuestInsight` is a separate mod that sits between Conjunction Map Framework (CMF) and Map Quest Insight 1.6.1 or later (Nexus 14219). Map Quest Insight stays unchanged. It normally talks to its own map file: it asks that file for a handshake number, then writes its values onto the map and onto each pin. CMF's map reads none of those names, so the adapter turns each value into CMF's general calls, the way Map Quest Insight's author would when porting. It is the worked example of an adapter that translates a mod's own field names through CMF's general hooks a design note kept in the private development repository. The author-facing version is [`docs/authors/map-quest-insight-adapter.md`](../../../docs/authors/map-quest-insight-adapter.md).

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

## How it works

| Step | Where | What |
|---|---|---|
| Handshake | `@wrapMethod(CR4MapMenu) OnConfigUI`, outermost | sets `QMI_swfApi = 3` and `QMI_swfApiRead = true` before Map Quest Insight's wrapper and the game's body run, so Map Quest Insight sends everything it sends its own map file 3. CMF's panel declares no `qmiApi`. |
| Faster map and zoom out | the same wrapper, after `wrappedMethod()` (settings reloaded, before CMF's map asks for its theme) | `MqiAdapterSendMotion`: when CMF has the `opening` part, sends Map Quest Insight's own values as `navigation` and `opening` keys while `QMI_OptFasterMap()` or `QMI_OptZoomOut()` is on, and `"unset"` for each key while it is off; each key only when `CMFHasAbility` answers true |
| Spreading stacked markers | the same wrapper, after the motion keys | `MqiAdapterSendSpread`: when CMF has the `spread` part, sends Map Quest Insight's own map file values as `spread` keys (`on` 1, `anyPin` 0, `enterRadius` 20, `stackDistance` 24, `maxPins` 8, `gap` 48, `openMs` 150, `closeMs` 120, `lockRadius` 24, `keepRadius` 48) while `QMI_SpreadStackedMarkers()` is on, and `"unset"` for each key while it is off |
| Signpost tabs and box height | `@wrapMethod(CR4MapMenu) UpdateDisabledMapPins`, after Map Quest Insight's (settings loaded, before the pins are sent) | asks Map Quest Insight which filter tabs hide signposts now ("Quests", and "Exploration,NPCs,Buffs") and keeps the list on `theGame` (`@addField(CR4Game) mqiAdapterNoSignTabs`); registers `CMFRegister("modMapQuestInsight", CMFPropertyInfoBoxHeight(), '', '', "", height)` with `QMI_InfoBoxMaxHeight()` rounded and held to 100-1080 (0 withdraws) |
| Spread rank | `@wrapMethod(CR4MapMenu) AddPinTypeData`, outermost | for each quest pin that is not fast travel, while the switch is on: finds the pin's quest as the game does (objective, then its quest), asks `QMI_SpreadRank(quest, QMI_GetQuestLevel(quest))` and claims a rank above 0 with `CMFStylePin(…, CMFPropertySpreadRank(), "", rank)`, so CMF's spread selects the pin Map Quest Insight's own map file would. The quest is known only here: `OnPinReady` sees the pin object, which carries no quest. |
| Each pin | `@wrapMethod(CMFCore) OnPinReady` | reads Map Quest Insight's pin fields and calls CMF's per-pin calls, below |

| Pin field | CMF call |
|---|---|
| `qmiIconScale` (not 0 or 1) | `CMFStylePinScale(…, round(value × 100))` |
| `qmiIconTop` (above 0) | `CMFStylePin(…, CMFPropertyLabelPlace(), "", round(value × 10))` |
| `qmiIconKind` on quest pins that are not fast travel | `CMFStylePinIcon`: kinds 4, 6-10 use frames of the game's pin icon (`frame:TreasureHuntMappin`, `HorseRace`, `BoatRace`, `FistFight`, `KnightErrant`, `WineContract`); kinds 1, 3 and 5 use the adapter's own placeholder icons `img://icons/modcmfadaptermapquestinsight/quest_main.png`, `quest_contract.png`, `quest_gwent.png` (its `art/`, drawn by `tools/cmf_mqi_adapter_art.py`, cooked into its own `texture.cache` by `tools/cmf_pack.py build`); kinds 0 and 2 keep the diamond |
| `qmiLevelText` on fast-travel or quest pins | `CMFStylePinLabel` with Map Quest Insight's own HTML; a signpost name of `" "` instead hides the pin label |
| `qmiNoCrosshairLabel` | `CMFStylePin(…, CMFPropertyLabelHide(), "crosshair", 1)`, or `"pin,crosshair"` with the signpost case |
| `qmiIconTint` (not 0) | `CMFStylePinTint` |
| fast-travel pins, when the tab list is not empty | `CMFStylePin(…, CMFPropertyTabHide(), tabs, 1)` |

Every claim names `modMapQuestInsight`, Map Quest Insight's own folder, as its provider (N4 spec 7.3), so folder order between mods is the same with CMF as without it.

**Pin fields.** The game builds pin objects from the map's pin class and drops any field that class does not declare. CMF's panel therefore declares Map Quest Insight's `qmi*` pin fields as compatibility names for this adapter; CMF itself reads none of them (`docs/development/pin-fields.md`).

**Wrapper order.** Wrappers nest by script file name. The file name starts with `zz_` so it sorts after `qmiSettings.ws` and `questMapInfo.ws`, so its wrappers run around Map Quest Insight's.

**Log.** For the first eight quest pins of each game session, one line:
`CMF adapter provider=modMapQuestInsight scale=<n> kind=<n> label=<text> tint=<decimal> noSignTabs=<tabs>`.

## Known differences

- **ALSO HERE stays with spreading on.** Map Quest Insight drops its "ALSO HERE" list only when its own map file answers `qmiSpreadMap`. CMF's map does not declare that name (no mod-specific names in core), and its map class is sealed, so the adapter cannot set it either: the game drops a write to a member the class does not declare. So under CMF the row spreads and the info box still lists the other quests on the spot, as Map Quest Insight does with spreading off. A port that asks `CMFHasAbility('spread', '')` can drop it.
- Main quest, contract and Gwent quest icons are the adapter's placeholder drawings (Kyle's decisions, 2026-10-20 04:34Z for stand-ins and 18:05Z that placeholder art lives in the adapter, never in CMF, so CMF needs no change when the adapter is removed). Map Quest Insight's art for them lives inside its own map file and cannot be loaded at run time. The release notes list them as Map Quest Insight's one visual difference until its author publishes a pack.

## Dependencies

- **Map Quest Insight 1.6.1 or later, a compile dependency.** The adapter uses its functions and fields, so the scripts fail to compile without it; `QMI_OptZoomOut` exists from 1.6.0. Every other name it uses is unchanged from 1.5.0 to 1.6.1 (smooth map movement record, section 10). Install and remove the two together; remove the adapter first.
- **CMF 6 with spreading.** `CMFPropertySpreadRank` (id 22) arrives with stacked-pin spreading in API version 6, so the adapter compiles only with that CMF. `CMFStylePart` and `CMFHasAbility` do not exist before CMF 5, and `OnPinReady`, ids 10-15 and `CMFStylePinScale`/`CMFStylePinLabel` not before CMF 4. The motion keys, the spread keys and `"unset"` need API version 6.

## Files

| Path | What |
|---|---|
| `modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_cmf.ws` | the four wrappers and the log line |
| `modCMFAdapterMapQuestInsight/README.txt` | for players |
| `tests/test_cmf_mqi_adapter.py` | static checks: the Map Quest Insight names it uses exist with these signatures in 1.5.0, wrapper order, every claim names `modMapQuestInsight`, it writes no pin field itself, the kind table, plus WitcherScript hygiene |

No art, so there is no `texture.cache`. Build: copy the folder. `tools/cmf_pack.py check modCMFAdapterMapQuestInsight --adapts modMapQuestInsight` reports no errors; its one warning (non-literal arguments in the box height claim) is expected.

## Status

Static checks only. Not yet compiled or run in game with CMF 4: the N4 launch proves the handshake, the conversion and the stand-in icons together. The Faster map and zoom-out keys, the spread keys and the spread rank have not yet run in game.

## Limits

- Windows only; Proton not checked.
- `QMI_OptZoomOut`'s signature is taken from the smooth map movement record (1.6.1 `qmiSettings.ws` 422), and `QMI_SpreadStackedMarkers` and `QMI_SpreadRank` from the stacked-marker research (version recheck, section 7.3); `tests/test_cmf_mqi_adapter.py` checks them, and that `QMI_GetQuestLevel` is still there, only when `CMF_MQI16_SCRIPTS` names a 1.6.1 copy.
