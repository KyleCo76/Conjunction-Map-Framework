# Script-side map/Flash bindings (S02a)

S02b2 adds an offline panel namespace/signature inventory and CMF probe methods;
see the final section. The original fixture below remains a script-only snapshot,
not a runtime acceptance result.

October 18, 2026. This is a reproducible inventory of the accepted patch 5.01
script sources, not a verified full panel ABI. The authoritative machine inventory
is panel-contract.json, schemaVersion 1.

Pinned bytes:

- `content/content0/scripts/game/gui/menus/mapMenu.ws`: SHA-256 `a27a6e00f587c9361af587c7c7e30d8a2c8bf174880dbf2bb4661194356bdf27`.
- `content/content0/scripts/game/gui/flashScriptImports.ws`: SHA-256 `22aa58104e73265ea9897c33815588ddb40b881ad085a292c535d4be766395e4`.

Reproduce with `python tools/cmf_contract.py --game <explicit-reference> --check`.
The fixture holds all 203 declarations with complete parameters, modifiers and
return syntax, every captured Flash operation with full arguments and source lines,
and entry-context references. Source text is normalized only for inventory display;
raw byte hashes bind the original CRLF files. No upstream mod implementation is used.

## Script callbacks

All map events are listed, including those whose registration is inherited or
panel-owned. Presence in script is not proof the panel registers or calls the event.

| Source line | Exact event signature |
| --- | --- |
| 32 | `event OnConfigUI()` |
| 128 | `event OnSetInitialFilters()` |
| 133 | `event OnFiltersChanged(id : int)` |
| 322 | `event OnDebugEvent( id : int )` |
| 490 | `event OnUpdateNewQuestTrackerObjectives(tag:name):void` |
| 557 | `event OnShowQuestOnMap(tag:name):void` |
| 600 | `event OnShowObjectiveOnMap(questTag:name, tag:name):void` |
| 1399 | `event OnToggleMinimap( previewMode : int )` |
| 1408 | `event OnDisablePin( pinName : string, disable : bool )` |
| 1413 | `event OnPinch( value : float )` |
| 1419 | `event OnClosingMenu()` |
| 1437 | `event OnCloseMenu()` |
| 1460 | `event OnSwitchToWorldMap()` |
| 1479 | `event OnSwitchToHubMap( flashName : string )` |
| 1507 | `event OnHighlightNextObjective()` |
| 1541 | `event OnHighlightObjective( tag : name )` |
| 1555 | `event OnHighlightObjectiveWithQuestChange( questTag : name, objTag : name )` |
| 1565 | `event OnCycleObjectivesDefault()` |
| 1654 | `event OnTrackQuest( tag : name )` |
| 1669 | `event OnShowQuestInJournal( tag : name )` |
| 1679 | `event OnTrackQuestFromMappin( questTag : name, objTag : name )` |
| 1792 | `event OnEntrySelected( tag : name )` |
| 1798 | `event OnSwitchToInterior( )` |
| 1803 | `event OnUserMapPinSet( posX : float, posY : float, type : int, fromSelectionPanel : bool, insideBounds : bool )` |
| 1878 | `event OnStaticMapPinUsed( pinTag : name, areaNameId : int )` |
| 2105 | `event OnSkipPressed()` |
| 2110 | `event OnCategoryOpened( categoryName : name, opened : bool )` |
| 2161 | `event OnDebugTeleportToHighlightedMappin( posX : float , posY : float )` |
| 2171 | `event OnRequestQuestTrackerState(newState : string) : void` |

Keep `insideBounds` on `OnUserMapPinSet`; mapMenu line 1835 forwards it to
`ToggleUserMapPin(realShownArea, position, realType, fromSelectionPanel,
insideBounds, idToAdd, idToRemove)`. The final two arguments are output variables.

## Script-to-panel function bindings

These are names passed to GetMemberFlashFunction and observed script calls.
Parameter expressions below are call-site evidence, not inferred AS3 parameter
names or types. The awkward `setDefaultMapPostion` spelling is intentional.
Script fields are private; AS3 member namespace kinds are UNOBSERVED.

| Panel name | Script invocation |
| --- | --- |
| `RemoveUserMapPin` | `InvokeSelfOneArg(FlashArgUInt( idToRemove ))` |
| `SetMapZooms` | `InvokeSelfFiveArgs(FlashArgNumber( minZoom ), FlashArgNumber( maxZoom ), FlashArgNumber( zoom12 ), FlashArgNumber( zoom23 ), FlashArgNumber( zoom34 ))` |
| `SetMapVisibilityBoundaries` | `InvokeSelfFiveArgs(FlashArgInt( vminX ), FlashArgInt( vmaxX ), FlashArgInt( vminY ), FlashArgInt( vmaxY ), FlashArgNumber( gradientScale ))` |
| `SetMapScrollingBoundaries` | `InvokeSelfFourArgs(FlashArgInt( sminX ), FlashArgInt( smaxX ), FlashArgInt( sminY ), FlashArgInt( smaxY ))` |
| `SetMapSettings` | `InvokeSelfEightArgs(FlashArgNumber( mapSize ), FlashArgInt( tileCount ), FlashArgInt( textureSize ), FlashArgInt( minLod ), FlashArgInt( maxLod ), FlashArgString( imagePath ), FlashArgBool( previewAvailable ), FlashArgInt( previewMode ))` |
| `ReinitializeMap` | `InvokeSelf()` |
| `EnableDebugMode` | `InvokeSelfOneArg(FlashArgBool( enable ))` |
| `EnableUnlimitedZoom` | `InvokeSelfOneArg(FlashArgBool( enable ))` |
| `EnableManualLod` | `InvokeSelfOneArg(FlashArgBool( enable ))` |
| `ShowBorders` | `InvokeSelfOneArg(FlashArgBool( show ))` |
| `setDefaultMapPostion` | `InvokeSelfTwoArgs(FlashArgNumber(defX), FlashArgNumber(defY))` |
| `ShowToussaint` | `InvokeSelfOneArg(FlashArgBool( theGame.GetDLCManager().IsEP2Available() ))` |
| `SetHighlightedMapPin` | `InvokeSelfOneArg(FlashArgUInt( NameToFlashUInt( highlightedMapPinTag ) ))` |

Imported invocation declarations (no value return is declared):

- `import final function InvokeSelf()`
- `import final function InvokeSelfOneArg ( arg0 : SFlashArg )`
- `import final function InvokeSelfTwoArgs ( arg0, arg1 : SFlashArg )`
- `import final function InvokeSelfThreeArgs ( arg0, arg1, arg2 : SFlashArg )`
- `import final function InvokeSelfFourArgs ( arg0, arg1, arg2, arg3 : SFlashArg )`
- `import final function InvokeSelfFiveArgs ( arg0, arg1, arg2, arg3, arg4 : SFlashArg )`
- `import final function InvokeSelfSixArgs ( arg0, arg1, arg2, arg3, arg4, arg5 : SFlashArg )`
- `import final function InvokeSelfSevenArgs ( arg0, arg1, arg2, arg3, arg4, arg5, arg6 : SFlashArg )`
- `import final function InvokeSelfEightArgs ( arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7 : SFlashArg )`
- `import final function InvokeSelfNineArgs ( arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 : SFlashArg )`

A future `CMFApplyPrepared(data:Object):void` is only a proposed CMF-authored
entrypoint. It is absent from vanilla and this slice. Status must use an observed
callback/data channel; InvokeSelf* has no declared return value.

## Published value channels

| Channel or expression | Operation(s) |
| --- | --- |
| `worldmap.global.set.index` | SetFlashInt |
| `worldmap.global.universe.area` | SetFlashString |
| `map.current.area.name` | SetFlashString |
| `map.hubs.custom` | SetFlashArray |
| `worldmap.global.universe.playerLevel` | SetFlashInt |
| `worldmap.global.universe.questareas` | SetFlashArray |
| `map.name.set` | SetFlashString |
| `map.current.area.id` | SetFlashUInt |
| `worldmap.global.pins.static` | SetFlashArray |
| `worldmap.global.pins.static.update` | SetFlashArray |
| `worldmap.global.pins.disabled` | SetFlashArray |
| `map.quest.name` | SetFlashObject |
| `map.objectives` | SetFlashArray |
| `map.quest.new.objective` | SetFlashObject |
| `map.show.pin.from.list` | SetFlashObject |
| `map.quests.new` | SetFlashArray |
| `worldmap.global.pins.dynamic` | SetFlashArray |
| `flashStr (dynamic)` | SetFlashBool |
| `map.quest.tracker.state` | SetFlashString |
| `worldmap.title.set` | SetFlashString |

The dynamic channel is built at mapMenu lines 973-974 as
`"universearea." + areaFlashName + ".active"`. Each fixture entry retains the
complete value expression and enclosing function. All 148 Flash object operations
(member names, types, constructor classes, array operations and argument expressions)
are also retained; they cover hub objects, objectives, quests, player and map pins.

## Required map contexts and limits

- User-pin placement: OnUserMapPinSet plus UpdateUserMapPins/UpdateUserMapPin and RemoveUserMapPin; keep fromSelectionPanel and insideBounds.
- Hub/universe: SwitchToHubMap, OnSwitchToHubMap, OnSwitchToWorldMap, SetCustomHubs/CreateCustomHubObject and the dynamic universearea channel; custom hubs stay vanilla-owned.
- Preview: OnToggleMinimap(previewMode : int), Hidden/WorldMapPreviewMode, UpdateMapSettings previewAvailable/previewMode arguments. A name containing minimap here controls the full-map overview.
- Filters: OnFiltersChanged(id : int), OnSetInitialFilters and worldmap.global.set.index. Vanilla maintains nge_map_menu_filter; CMF adds no persisted custom view/fact.
- Quest tracker: map.quest.tracker.state, objective/quest channels and the exact callbacks above.
- Selected entry: currentTag is restored from UISavedData.selectedTag in SetMenuState (line 294); OnEntrySelected, objective highlighting and SetHighlightedMapPin preserve selection behavior.
- Player avatar: UpdatePlayerPin (line 806) uses thePlayer position/rotation and a W3ReplacerCiri cast (line 832) to choose Ciri/Geralt description and label fields. No standalone selectedAvatar channel is declared in these two sources; panel-side avatar state is UNOBSERVED.
- Normal/FastTravel/boat paths: OnConfigUI sets GlobalMap and checks GetTriggeredExitEntity, GetUsedFastTravelEntity and IsOnBoat; OnStaticMapPinUsed retains permission checks and local/global travel calls. Entry selection/state creation outside these two files is inherited/external and is not asserted complete here.

## S02a snapshot limits

Panel callable public/private namespace kinds, embedded library symbols, timeline/state
frames, fonts/components, full callback registration, data marshalling, baseline-equivalent
panel round trip, rendered text lookup and bridge/runtime behavior require the qualified
offline panel toolchain and isolated engine probes. All corresponding fixture fields
are UNOBSERVED. This inventory cannot make the whole panel-contract suite pass.
No AS3 bridge, WitcherScript probe or panel patch manifest existed at the S02a
cutoff. S02b2 now supplies the internal probe below. No player release exists.

## S02b2 offline ABI and bridge probe

The construction audit
adds independently decoded root/inherited traits, exact parameter/return types,
raw namespace identities and matches for all 13 script-side Flash function
bindings. Every match was found in an empty public package namespace (`0x16`);
none was filled with a default missing-list value. The pinned root is class 481,
with 149 original instance traits. Original private/protected/package namespace
identities remain distinct. The earlier S02b1 inventory retains SymbolClass,
all 878 tags, sprite/frame facts, embedded symbols and the `gfxfontlib.swf`
import. These are offline facts; dependency loading and complete callback/data
behavior remain engine gates. The S02a fixture intentionally retains its original
scope and unobserved fields rather than retrospectively changing that snapshot.

The internal `object` specimen has these exact added root instance methods:

| Method | Signature | Purpose |
| --- | --- | --- |
| `CMFBridgeVersion` | `():void` | Calls inherited public `callGameEvent("OnDebugEvent", [1129137665])` |
| `CMFInstallBridge` | `():void` | Registers `cmf.prepared` with `CMFApplyPrepared`, then sends 1129137666 |
| `CMFApplyPrepared` | `(Object):void` | Requires schema 1, revision 7 and matching build `runId`, then sends 1129137667 |

The first two take no parameters, explicit `void`, one local and max stack 3;
the receiver takes exactly one public Object parameter, explicit `void`, two
locals and max stack 3. All use scope depths 13/14, no exceptions, body traits
or extra fields. The source specification and actual emitted instructions are
both retained. No helper class is inserted. These are provisional internal
probe symbols, not a published provider contract.

`source/probes/bridge/cmfBridgeProbe.ws` wraps the exact pinned implicit-bool
event targets `CR4MapMenu.OnConfigUI()`, `OnDebugEvent(id:int)` and optional
session observation `CR4Game.OnGameStarted(restored:bool)`. Each calls its
predecessor exactly once and returns the saved bool. No session/map request,
input synthesis, saved field, CMF fact or gameplay mutation is introduced.

Vanilla `MapMenu.configUI` sends OnConfigUI before its remaining registrations.
The probe therefore explicitly invokes `CMFInstallBridge`; only its ready
callback publishes through `CreateTempFlashObject`, `SetMemberFlashInt`,
`SetMemberFlashString` and `SetFlashObject`. The installed method calls inherited
`registerDataBinding` before the callback. This establishes source ordering;
native synchronous/asynchronous delivery and reentrancy still require observation.
There is no `FlashArgObject`, and no return value is assumed from `InvokeSelf`.

Expected same-token log markers are `phase=session restored=false`,
`phase=invoke method=CMFBridgeVersion`, `phase=callback bridgeVersion=1`,
`phase=callback registration=ready`, `phase=publish channel=cmf.prepared schema=1 revision=7`,
and `phase=callback objectTransport=1 schema=1 revision=7`.
Version-only success cannot satisfy object transport. A main menu is not the
session marker; absent logs/compilation/callbacks remain UNOBSERVED. Require the
vanilla no-op/WS negative control and ordinary map behavior as well. Root/user
owns all launches, exits and in-game actions. No runtime observation was made by
this construction slice, and the production verification suite cannot pass from
these offline artifacts alone.

## S02c bounded qualification probe

The qualification variant also wraps `CR4MapMenu.OnCloseMenu()` with the pinned
implicit-bool event signature. All four wrappers call `wrappedMethod` once,
save its result, and return it. `OnConfigUI` records `m_menuState` and the
read-only `W3MapInitData` getters `getDefaultState`,
`GetTriggeredExitEntity`, `GetUsedFastTravelEntity`, and `GetIsSailing`, plus
`thePlayer.IsOnBoat()` when available. These are exact declarations in the
pinned 5.01 scripts. `m_menuState` is reset to `GlobalMap` inside vanilla
`OnConfigUI`, so one record cannot prove how the player opened the map.
Overlapping or absent context signals remain unknown. A configuration count
is not a map-opening count.

After vanilla `OnCloseMenu`, the probe looks up reserved string ID 2000200001
with `GetLocStringById`, logs the returned value, and requests a bounded
`CR4GuiManager.ShowNotification(label, 5000, false)` when the GUI manager
exists. The pinned declaration takes `(string, optional float, optional bool)`;
vanilla forwards the duration to `OverlayPopup`. This is a transient resource
lookup/display probe, not a new menu or persistent setting. English text is
`Conjunction Map Framework`. Actual lookup, displayed text, duration and map
behavior require Kyle's engine observation. The source and payload contain
only the safe specimen token and compile-time qualification flag; no saved
instance field is added.

The earlier expected `restored=false` was too specific for Hearts of Stone-only
New Game. A session marker with `restored=true` is valid for that route, and
neither value proves the input path on its own. The historical positive and
no-op captures are retained with their own build tokens; they cannot qualify
the new string and context probe.

## S02c close-path diagnostic follow-up

Two separate user observations with the S02c specimen reported no visible
notification. The quiet repeat used the same unchanged payload and produced
four exact string lookups and four display-request markers; those markers do
not prove OverlayPopup rendered the text. The log contains no event ordering
or popup-presence markers for menu teardown. Pinned vanilla
`CR4CommonMenu.OnClosingMenu` calls `m_guiManager.ClearNotificationsQueue()`;
that forwards to OverlayPopup if it exists. Its native timing relative to the
post-`CR4MapMenu.OnCloseMenu` request is not established by the old capture.

The new **diagnostic-only** internal specimen retains the same lookup and
`ShowNotification(label, 5000, false)` call. It wraps the exact implicit-bool
`CR4MapMenu.OnClosingMenu()` and `CR4CommonMenu.OnClosingMenu()` events and
records enter/return markers around each predecessor. The map close wrapper
records enter/return around its predecessor and a return marker after the
unchanged notification request. Each marker includes whether the read-only
`GetPopup('OverlayPopup')` lookup currently returns a popup. These markers
can establish script callback order and object presence; they cannot prove
native delivery, queue contents, animation, layering or visible text. No
menu/session, input, fact, saved field, or timing delay is introduced.

## S02c direct-map notification candidate

The saved-session diagnostic ordered `display-return` before the map and
common parent `OnClosingMenu` callbacks. OverlayPopup was present at every
marker. Vanilla `CR4CommonMenu.OnClosingMenu` clears notifications inside its
predecessor. Pinned `popup_overlay.redswf` ActionScript confirms
`clearNotificationsQueue` hides an active notice and empties pending notices;
the module's active notice starts at alpha zero and fades in over 0.3 seconds.
These source and trace facts strongly explain the missing text, though no
rendered frame was captured.

The next internal specimen removes the request from map `OnCloseMenu` and
places the same resource lookup and `ShowNotification(label, 5000, false)`
after the `CR4CommonMenu.OnClosingMenu` predecessor returns. Before calling
that predecessor, the wrapper snapshots vanilla's `m_lastMenuName` and
`m_hubEnabled`. It requests text only when the last requested submenu is
`MapMenu` and the common menu is not hub-backed. The existing
`CR4CommonMenu.OnRequestMenu` source sets `m_lastMenuName` when requesting
a submenu; `ChildRequestCloseMenu` closes the non-hub parent on child close.
The specimen logs both predicate inputs and the decision as `display-scope`.
Hub-backed and unrelated menu closes are excluded. No new field, timer,
input, menu request or gameplay mutation is introduced. Script callback
order and visible text for this new specimen remain engine gates.
