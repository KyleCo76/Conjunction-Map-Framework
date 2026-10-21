# Gwent Players Map adapter (proof of concept)

`modCMFAdapterGwentPlayersMap` is a separate mod that sits between Conjunction Map Framework (CMF) and Gwent Players Map 1.0.9 (Nexus 13755). It lets Gwent Players Map's card markers draw on CMF's world map under that mod's own pin type names, in its own "Gwent" tab, with Gwent Players Map unchanged. It follows the Witcher Gear Map adapter's pattern and Kyle's adapter principle: it restores the adapted mod's own features and adds none. Since 1.0.1 it ships the card art of Gwent Players Map's author, MateusAnd, with their permission (2026-10-21; Kyle's rule of 15:12Z: an author's art ships in the adapter only with their explicit permission).

## Provenance

Traced on 2026-10-20 from the reference archive `Gwent Players Map (1.0.9) 13755 1.0.9 2026-10-15T20-21Z 864tMl8q0.zip` (SHA-256 `bd72b19d…`, the hash recorded in the compatibility write-up). The archive was read only.

- **Pin types and fields.** `mods/modGwentPlayersMap/content/scripts/local/gwm.ws` wraps `@wrapMethod(CR4MapMenu) UpdateEntityPins` and pushes one `StaticMapPinData` per player:
  - `type` is `GwentPlayer`, or `GwentPlayerDisabled` once the player is beaten or no longer available;
  - with the "Card size" option at 1, those become `GwentPlayerLarge` and `GwentPlayerLargeDisabled`;
  - `filteredType` is always `GwentPlayer`, and `label` is `gwm_label_gwent_player`.
- **Filter callback.** `@addMethod(CR4MapMenu) event OnGwmMapFilter(category : string)` sets `gwentFilter` when `category == "Gwent"` and rebuilds the map. With that filter set, the cards stand on the players' own spots; otherwise a merchant's card sits next to the shop icon.
- **Its map file.** Its `panel_worldmap.redswf`, exported with FFDec 26.3.0 and diffed against vanilla, changes `HubMapPinPanel` only:
  - adds category `"Gwent": CategoryDefinition(8, true, true, false)`;
  - adds the four types under `"Gwent"` at 701, 702, 790 and 791;
  - lists the `Gwent` category under Default;
  - calls `dispatchEvent(new GameEvent(GameEvent.CALL, "OnGwmMapFilter", [param1._name]))` first thing in `updatePinsFromCategory` (CMF's panel calls `OnCMFMapFilter` at the same place).
- **Card size.** Its menu var `GwmCardSize` (group `GwentPlayersMap`, options `0` small and `1` large) switches `gwm.ws` to the Large names. In its map file (pin sprite `PinIcon_122`, DefineSprite 588, frames 1474-1504) each card is two vector shapes placed at identity scale; the large shapes are 14.70 × 17.60 and 13.90 × 17.10 px against 12.30 × 14.80 and 11.65 × 14.40, about 1.19 times in each direction. Measured on 2026-10-20 by Remote Control from the probe copy's `modGwentPlayersMap` (movie SHA-256 `5103aaca…`, exported with FFDec 26.3.0).
- **Strings.** Its `en.w3strings` carries `map_category_Gwent` = "Gwent" and `gwm_label_gwent_player` = "Gwent player". These were matched by key hash: `0xBC2BE4BD` and `0xE26C7B12`.

Nothing is copied. The adapter holds only the type names, the tab id and the string keys, which are facts about the interface, plus the author's card art, given for the adapter (never stored in CMF itself).

## How it works

| Piece | Who | Detail |
|---|---|---|
| Art for the four types and the legend row | adapter, CMF 1 named calls | `CMFRegisterIcon` ×4, `CMFRegisterLegendIcon` on `GwentPlayer` |
| Large cards | adapter, CMF 4 id 10 | `CMFRegister(…, 10, 'GwentPlayerLarge', '', "", 119)` and the same for `GwentPlayerLargeDisabled`, under `CMFHasProperty(10)` |
| The "Gwent" tab, its row and the row name | adapter, CMF 2 ids 8, 6, 7 | `CMFRegister(…, 8, 'Gwent', '', "[[map_category_Gwent]]", 8)`, `(…, 6, 'GwentPlayer', '', "Gwent", 701)`, `(…, 7, 'GwentPlayer', '', "[[gwm_label_gwent_player]]", 0)` |
| The tab report | CMF's panel and the adapter | CMF's `updatePinsFromCategory` reports every shown tab as `OnCMFMapFilter(tab name)`; the adapter's `@addMethod(CR4MapMenu) event OnCMFMapFilter(category : string)` calls Gwent Players Map's `OnGwmMapFilter(category)`. CMF tabs are named by their id, so the tab must be `Gwent` |
| Pins and positions | Gwent Players Map, unchanged | its `UpdateEntityPins` wrapper and `OnGwmMapFilter` event |

**No wrapper-order dependency.** The adapter's registrations wrap only `CR4Game.OnGameStarted`. CMF's late pass styles the pins after every `UpdateEntityPins` wrapper, whatever the file names.

**When another mod replaces `UpdateEntityPins`.** The Stable 2.2.1 ships a precompiled `CR4MapMenu.UpdateEntityPins`, and while it is installed Gwent Players Map's wrapper on that method never runs: no card reached the map in final matrix launch M1, and every card came back in M1c with The Stable out (2026-10-21). `modcmfadaptergwentplayersmap_stable.ws` wraps `UpdateUserMapPins`, which vanilla `UpdateData` calls right after `UpdateEntityPins` on the same list and which The Stable leaves alone. Before the user pins it looks for a pin with `filteredType` `GwentPlayer`; only when there is none does it build the cards by calling Gwent Players Map: `GwmGetData()` (its players, their states and its filter mode), `GwmConfigBool` and the `GwmCardSize` option, `GwmWorldKey`, `GwmIsShopPinType` and `GwmSideOffset` for the card beside a shop icon, `GwmRoleText`, `GwmStatusText`, `GwmNoteText`, `GwmSellerText` and `GwmLoc` for the texts, and its id offset. It holds no player, position or text of its own, so without Gwent Players Map it does not compile, and when Gwent Players Map's own wrapper runs it adds nothing. It names no other mod. Not yet launched.

**Install and remove it together with Gwent Players Map.** Its `OnCMFMapFilter` event calls Gwent Players Map's `OnGwmMapFilter`, so the scripts fail to compile without Gwent Players Map. Remove the adapter first. CMF's panel names no mod (Kyle, 2026-10-20 05:02Z); before N4 it called `OnGwmMapFilter` itself.

**Provider.** Every claim names `modGwentPlayersMap`, Gwent Players Map's own folder (N4 spec 7.3), so folder order between mods is the same with CMF as without it. The art stays in the adapter's own cache under `img://icons/modcmfadaptergwentplayersmap/`.

**Requires CMF 2.** The tab is the point of the adapter, so it calls `CMFRequireVersion(…, 2)` and registers nothing on CMF 1.

## Known limits


## Files

| Path | What |
|---|---|
| `modCMFAdapterGwentPlayersMap/content/scripts/local/modcmfadaptergwentplayersmap_cmf.ws` | 4 `CMFRegisterIcon`, 1 `CMFRegisterLegendIcon` and 5 `CMFRegister` calls |
| `modCMFAdapterGwentPlayersMap/content/scripts/local/modcmfadaptergwentplayersmap_stable.ws` | the cards from Gwent Players Map's own functions when its `UpdateEntityPins` wrapper did not run |
| `modCMFAdapterGwentPlayersMap/art/card*.png` | MateusAnd's two 96 × 96 cards, white and grey (beaten), from `CMF_adapter_art_GwentPlayersMap_WitcherGearMap.zip` (SHA-256 `3b287729e1ccc77dc595484767b57ca5de4852693be0e545e9feb5b3dfb5ed0f`), unchanged |
| `modCMFAdapterGwentPlayersMap/README.txt` | For players |
| `tests/test_cmf_gwent_adapter.py` | Static checks: the art is the author's two cards and checks clean, the names match Gwent Players Map's, every claim names `modGwentPlayersMap`, the tab report reaches `OnGwmMapFilter`, the pack builds |

Build: `python tools/cmf_pack.py build source/adapters/gwent-players-map/modCMFAdapterGwentPlayersMap --adapts modGwentPlayersMap --out <new folder>`. Five warnings, one per claim, say the Gwent names are not 5.01 pin types; that is expected.
