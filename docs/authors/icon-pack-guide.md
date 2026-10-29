# Making an icon pack for Conjunction Map Framework

Conjunction Map Framework (CMF) is a single world map that map mods can share. CMF ships the map; other mods tell CMF what they want changed, and CMF decides and draws it. That way several map mods can be installed at once without each shipping its own copy of the map.

An **icon pack** is the simplest kind of CMF mod. It changes how existing map pins look on the full-screen world map: their icon, their legend icon and their colour. It does not add or move pins; from API version 3 any CMF mod can also hide pins, and from API version 4 resize pins and change their labels (section 5). You do not edit any map file and you do not need Script Merger, FFDec, REDkit or WolvenKit.

This guide is for someone who has made a Witcher 3 mod before but has never seen CMF. It documents API version 13 (`CMFGetVersion()` returns `13`), independently of release numbering. The map applies the registered styles and dispatches the hooks described here. Source and offline package checks are separate from engine compilation, actual loading and gameplay acceptance; features without game-launch evidence say so. Section 12 shows how existing map mods move onto CMF. A finished example is in [`examples/modCMFExampleIconPack`](../../examples/modCMFExampleIconPack/).

## 1. What you need

- Conjunction Map Framework version 1 or later, installed in the game.
- Python 3 to run the CMF pack tool, `tools/cmf_pack.py` from the CMF repository (with its neighbours `cmf_cooked_codec.py`, `cmf_cooked_cache.py`, `cmf_texture_cache.py`, `cmf_pin_types.py` and `cmf_pin_types.json`). It needs nothing beyond the standard library.
- Your icons as PNG files (section 4).

## 2. Quick start

Your pack is a source folder with this layout. The pack tool turns it into the folder players install.

```
modAcmeIcons/                                  the folder name is the pack name and provider id
  art/innkeeper.png                            one PNG per image (a tint-only pack needs none)
  content/scripts/local/modacmeicons_cmf.ws    your start-up script
  README.txt                                   for players
```

Only these belong in it, plus the optional settings files of section 9. Keep working files (layered art such as `.psd` or `.xcf`, scripts that draw your art) outside the pack folder: the tool refuses unknown files, and ignores anything in `art/` that is not a `.png`.

Commands below say `python`; use `python3` where that is the name of Python 3.

1. Copy `examples/modCMFExampleIconPack` to a new folder and rename it, for example `modAcmeIcons` (section 3).
2. Put your PNGs in `art/` and delete the example's.
3. Run `python tools/cmf_pack.py skeleton path/to/modAcmeIcons` and paste what it prints into `content/scripts/local/modacmeicons_cmf.ws` (section 5). Delete the example's script.
4. Edit `README.txt` from [`pack-readme-template.txt`](pack-readme-template.txt).
5. Run `python tools/cmf_pack.py build path/to/modAcmeIcons --out path/to/new-folder`, fix anything it reports, and copy the `Mods` folder it writes into the game folder (section 7).

## 3. Name your pack folder

Pick a folder name like `modAcmeIcons`.

- It starts with `mod` and uses only letters, digits and `_`.
- It does **not** start with `mod0000_` or `mod0001_`. Those are reserved for CMF and for Script Merger's output. Avoid `modCMF` too, which CMF uses for its own example and test packs, so players do not mistake yours for part of CMF.
- Your **provider id**, the first argument of every CMF call, is this folder name exactly, with the same capitals.
- **The folder name decides conflicts.** When two packs change the same thing on the same pin type, the pack whose folder name sorts first wins, the way the game picks between two mods that ship the same file. Name your pack earlier to win, later to be a fallback. Players can rename folders to change the order. Capital letters do not affect the order.

## 4. Make your art

One image per pin type you change. The map draws the selected pin and the legend row from the same image, so you do not need selected, highlighted or legend-sized versions.

| Rule | Why | Pack tool |
| --- | --- | --- |
| Square PNG, a multiple of 4 pixels, from 32 to 128. **96 x 96 is recommended.** | Images are stored as BC3 blocks of 4 x 4 pixels. 96 px covers the selected pin at 4K (about 92 px on screen) without upscaling; larger only adds shimmer. 64 x 64 is proven in game too. | refuses other sizes; notes sizes other than 96 |
| File name lower-case letters, digits and `_`, ending in `.png`, for example `innkeeper.png`. | The file name becomes the image's key, and keys are lower case. | refuses other names |
| Transparent background, straight (not premultiplied) alpha. | What the encoder expects. | |
| Keep the outer 4 pixels fully transparent. | Stops block edges and smoothing from bleeding. | warns |
| Centre the art on the canvas. | The canvas centre lands on the pin's map point. | |
| Use a strong silhouette or a dark outline, and flat colours. | The map behind a pin ranges from sea to parchment. CMF's encoder fits each 4 x 4 block between two colours, so gradients and painted detail shift colour; flat shapes and outlines survive. Thin 1-pixel lines shimmer when the image is drawn at a third of its size. | warns when compression changes colours noticeably |
| If you want other packs' tints to colour your art, paint the parts that should take the tint white or light. | A tint multiplies the art's colours (gold art tinted magenta turns red). | |

**How big it is drawn.** CMF fits your image into the box of the stock glyph it replaces and centres it there, so it comes out the size the original icon was. Some stock glyphs differ a little between states (a full notice board is slightly larger than an empty one), and your image follows them.

**States are separate types.** A completed place is its own type (`MonsterNestDisabled`), and an empty notice board (`NoticeBoard`) is a different type from a full one (`NoticeBoardFull`). Give each state you want to change its own registration (icon or tint); it can reuse the same image. Players usually expect a completed place to keep a look related to the open one. Level variants (`MonsterNest_1` to `_3`) are the exception: API version 1 keys them on the base name, so one `MonsterNest` icon or tint covers every level.

**You rarely need a legend image.** `CMFRegisterIcon` sets the legend row too. Register a separate legend image only when the legend should look different from the pins; the example does it for innkeepers only to show the call.

## 5. Write your script

Create one script, `content/scripts/local/<your folder in lower case>_cmf.ws`. The file name must be unique across every installed mod, so include your folder name. Use tabs, plain ASCII and LF line endings.

```
// Acme Icons for Conjunction Map Framework. Requires CMF 1 or later.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modAcmeIcons", 1))
	{
		CMFRegisterIcon("modAcmeIcons", 'Innkeeper', "img://icons/modacmeicons/innkeeper.png");
		CMFRegisterLegendIcon("modAcmeIcons", 'Innkeeper', "img://icons/modacmeicons/innkeeper_legend.png");
		CMFRegisterTint("modAcmeIcons", 'Herbalist', 4259648);
	}
	return result;
}
```

This is the same plug-in pattern Map Quest Insight and Witcher Gear Map use: a new script file with an annotation wrapper, so nothing needs merging. The game runs every mod's `OnGameStarted` wrapper on each new game and each loaded save, and it does not matter whether yours runs before or after CMF's.

### Tell CMF you are here (API version 11)

Call `CMFDeclareProvider("modAcmeIcons")` once from your `OnGameStarted` wrapper to tell CMF that your mod supplies CMF support. `CMFDeclareProvider(provider : string) : bool` returns false for an empty provider. Every other provider-naming submission counts too, even a rejected payload or a withdrawal; pure queries do not. Declare from your mod's own script, or from an adapter whose existing dependency or presence check establishes that its source mod is installed. A separate untied adapter cannot establish that simply by being installed.

`CMFPropertyPresent()` returns property id 38. Authors keeping an older minimum CMF can use the generic form, which compiles on CMF 1 and is skipped there:

```
if (CMFHasProperty(38))
{
	CMFRegister("modAcmeIcons", 38, '', '', "", 1);
}
```

The named calls require API 11. `CMFProviderPresent(provider : string) : bool` asks whether a nonempty provider has submitted anything this session, ignoring case; asking never declares it. The first spelling is retained for display, and `CMF present provider=<name>` is logged once. `CMFReleaseProvider` withdraws contributions while session presence remains.

Queries such as `CMFProviderPresent`, `CMFGetVersion` and `CMFHasProperty` never declare a provider. Use a declaration only when your mod itself is present; do not move a declaration into an untied adapter merely to quiet a warning.

Presence adds no feature offers, priority or selectable choices. The updated menu's Loaded map mods page includes declaration-only providers as "CMF support present", using separate title-screen memory. Presence records provider activity: an untied art adapter's presence does not prove that its source mod is installed. The optional CMF Adapter Check can use the declaration to recognize a mod that now supplies its own CMF support. Engine and gameplay validation of these new API 11 calls is pending.

### The CMF calls

API version 2 adds legend rows, filter tabs and per-pin styling to the API version 1 calls, API version 3 adds hiding pins, and API version 4 adds pin size, labels, the info box and hiding pins in filter tabs; nothing earlier was removed. Two generic calls take a property id, so later CMF versions can add properties without adding functions. A pack that uses only `CMFRegister`, `CMFRegisterForTag` and `CMFHasProperty` compiles against any CMF from 1 on and skips what the installed CMF lacks. A call to a function CMF does not have stops the game at the script compile screen, which `CMFRequireVersion` cannot prevent. The named calls further down are shorthand for the generic ones.

| Property id | Named shorthand | `text` | `number` | Withdraw |
| --- | --- | --- | --- | --- |
| `1` `CMFPropertyIcon()` (widened player/user art and level variants needs `CMFGetVersion() >= 11`) | `CMFRegisterIcon`, `CMFRegisterIconForTag` | image path | unused (`0`) | 40 with this id at the same slot |
| `2` `CMFPropertyLegendIcon()` | `CMFRegisterLegendIcon` | image path | unused | 40 with this id at the same slot |
| `3` `CMFPropertyTint()` (widened tag tint, player/user art and level variants needs `CMFGetVersion() >= 11`) | `CMFRegisterTint` | unused (`""`) | colour, decimal 0xRRGGBB | 40 with this id at the same slot |
| `4` `CMFPropertyBackground()` | `CMFRegisterBackground` (target is the map area) | image root | unused | 40 with this id at the same slot |
| `5` `CMFPropertyDisabled()` | `CMFRegisterDisabled`, `CMFRegisterDisabledForTag` | unused | nonzero greys, `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `6` `CMFPropertyLegendRow()` (API version 2; target is a `filteredType`) (widened vanilla rows needs `CMFGetVersion() >= 11`) | `CMFRegisterLegendRow` | category id, or `""` for All only | row priority; `0` puts it after every vanilla row. One claim sets both coupled values. | 40 with this id at the same slot |
| `7` `CMFPropertyLegendLabel()` (API version 2; target is a `filteredType`) | `CMFRegisterLegendLabel` | the row's name, `"[[string_key]]"` or plain text | unused | 40 with this id at the same slot |
| `8` `CMFPropertyLegendCategory()` (API version 2; target is your category id) | `CMFRegisterLegendCategory` | the tab's name, `"[[string_key]]"` or plain text | tab order among CMF tabs, low first  One claim sets both coupled values. | 40 with this id at the same slot |
| `9` `CMFPropertyHidden()` (API version 3; target is a pin type or `filteredType`, or `''` for every pin) | `CMFRegisterHidden`, `CMFRegisterHiddenForTag` | exemptions: `""` or any of `tracked`, `quest`, `fasttravel` | nonzero hides, `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `10` `CMFPropertyPinScale()` (API version 4) (widened player/user size needs `CMFGetVersion() >= 11`) | `CMFStylePinScale` (one pin) | unused | percent, `25` to `400` | 40 with this id at the same slot |
| `11` `CMFPropertyLabelPlace()` (API version 4) | none | unused | tenths of a pin unit from the pin centre, `0` to `10000` (`0` = the game's place) | 40 with this id at the same slot |
| `12` `CMFPropertyLabelText()` (API version 4) | `CMFStylePinLabel` (one pin) | the label, HTML, not empty | unused | 40 with this id at the same slot |
| `13` `CMFPropertyLabelHide()` (API version 4) | none | `"pin"`, `"crosshair"` or both | nonzero hides, `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `14` `CMFPropertyInfoBoxHeight()` (API version 4; target `''`; from API version 11 also a type, a tag, a place or one pin) (widened type/tag/place height needs `CMFGetVersion() >= 11`) | none | unused | px, `100` to `1080`; `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `15` `CMFPropertyTabHide()` (API version 4; target `''` means every pin) | none | filter tab names | nonzero hides, `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `16` `CMFPropertyPinClick()` (API version 6) | none | inputs: any of `use`, `doubleClick`, `button`, `hold` | nonzero, handed back with each click; `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `18` `CMFPropertyInfoTitle()` (API version 11) | none | the info box title, HTML, not empty | `0` (`CMFInfoReplace()`) replaces the game's title, `1` (`CMFInfoAdd()`) adds a line below it | 40 with this id at the same slot |
| `19` `CMFPropertyInfoText()` (API version 11) | none | the info box text, HTML, not empty | `0` (`CMFInfoReplace()`) replaces the game's text, `1` (`CMFInfoAdd()`) adds lines below it | 40 with this id at the same slot |
| `20` `CMFPropertyPinClickHint()` (API version 6) | none | the button bar's words for the click | nonzero; `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `21` `CMFPropertyPinClickButton()` (API version 6) | none | the words on the pin's button | nonzero; `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `22` `CMFPropertySpreadRank()` (API version 6) | none | unused | which pin of a spread stack is selected first, `0` to `1000`, highest first | 40 with this id at the same slot |
| `23` `CMFPropertyCategoryNoDefault()` (API version 6; target is your category id) | `CMFRegisterCategoryNoDefault` | unused | nonzero keeps the tab's rows out of Default; `0` lists them there | 40 with this id at the same slot |
| `24` `CMFPropertyWorldPainting()` (API version 9; target `'painting'`, `CMFRegister` only) | `CMFRegisterWorldPainting`, `CMFRegisterWorldPaintingTiles` | image path, `""` withdraws | `0` for one picture, or columns x 10 + rows for tiles, each 1 to 8 | 40 with this id at the same slot; or original empty text |
| `25` `CMFPropertyWorldCrest()` (API version 9; target is a region name) | `CMFRegisterWorldCrest` | image path, `""` withdraws | unused | 40 with this id at the same slot; or original empty text |
| `26` `CMFPropertyButtonPicture()` (API version 9; target `'family_button'`, for example `'xbox_gamepad_Y'`, with a dash in the map's name written as `_`: `'xbox_enter_gamepad_A'`) | `CMFRegisterButtonPicture` | image path, `""` withdraws | unused | 40 with this id at the same slot; or original empty text |
| `27` `CMFPropertyWorldMarker()` (API version 9; target `'player'` or `'quest'`) | `CMFRegisterWorldMarker` | image path, `""` withdraws | unused | 40 with this id at the same slot; or original empty text |
| `28` `CMFPropertyHoverName()` (API version 10; target `''` means every pin) | none | unused | bits: `1` the label line only on the hovered pin, `2` the name on the hovered pin; `0` as the game shows it  One claim sets both coupled values. | 40 with this id at the same slot |
| `29` `CMFPropertyIconUndiscovered()` (API version 11; target is the pin's real type, such as `'RoadSign'`) | none | image path or `frame:<label>`, art while the pin is an undiscovered "?" | unused | 40 with this id at the same slot |
| `30` `CMFPropertyIconCompleted()` (API version 11; target is the pin's real type) | none | image path or `frame:<label>`, art while the pin is completed (greyed) | unused | 40 with this id at the same slot |
| `37` `CMFPropertyTabHidden()` (API version 11; target is a filter tab name or id, `CMFRegister` only) | none | unused | nonzero hides the whole tab, `0` withdraws | 40 with this id at the same slot; or original number 0 |
| `17` LabelColor (API version 5) | none | unused | RGB 0..16777215 | 40 with this id at the same slot |
| `31` IconSelected (API version 13) | none | img:// path or frame:label | unused | 40 with this id at the same slot |
| `32` SelectedScale (API version 13) | none | unused | 25..400 percent | 40 with this id at the same slot |
| `33` PinAlpha (API version 13) | none | unused | 0..100 percent; zero is valid | 40 with this id at the same slot |
| `34` PinOrder (API version 13) | none | unused | -1000..1000; higher draws above | 40 with this id at the same slot |
| `35` PinOffset (API version 13) | none | signed decimal x,y; each -50..50 world metres | unused | 40 with this id at the same slot |
| `36` PinZoom (API version 13) | none | signed decimal min,max; finite and ordered, no extra absolute clamp | unused | 40 with this id at the same slot |
| `38` Present (API version 11) | none | unused | presence only | not a stored claim |
| `39` InfoBoxWidth (API version 13) | none | unused | 200..1920 logical content pixels; 0 withdraws | 40 with this id at the same slot; or number 0 |
| `40` Withdraw (API version 13) | none | empty | effective property id; removes only your matching slot | not a stored claim |
| `41` LegendRowTint (API version 13) | none | unused; target is a filteredType, type level only | RGB 0..16777215; row only, ahead of id 3 | 40 with this id at the same slot |
| `42` IconUnder (API version 13) | none | img:// path or frame:label | unused | 40 with this id at the same slot |
| `43` IconUnderTint (API version 13) | none | unused | RGB 0..16777215, multiplied into the picture as id 3 is into the icon (white keeps it, black blacks it out) | 40 with this id at the same slot |
| `44` PictureScale (API version 13) | none | unused | 25..400 percent of the pin's size: grows the icon and the picture under it (42) only, not the pin's highlight ring and glow | 40 with this id at the same slot |

The map root supports arbitrary public script-set values when `CMFHasAbility('map', 'rootValues')` is true. Native `SetMemberFlash*` / `GetMemberFlash*` calls may store a mod's own number or string before `OnConfigUI` and read it back there. Existing declared fields and methods retain their meaning; use your own names.

**Revision 13 changes.** Label hides (13) now merge the union of every eligible provider's pin/crosshair hides, including direct per-pin contributions. A zero contribution never unhides another provider's labels. Row tint 41 overrides the row's tint 3 without changing its pin tint. Ids 6 and 8 still couple row/tab placement and priority; 28 still couples its two hover-name bits.

The every-pin target `''` now accepts 1,3,10,11,12,13,17,22,42,43,44, as well as ids 31 to 36 and the earlier every-pin properties. A type, tag, place or direct pin claim beats a global claim even when the player selected the global provider, including strict fallthrough. Vanilla and choice-only exclusions still apply. Every-pin styling does not remove the existing player/user/unknown/completed-pin protections.

Ids 31 to 36, 39 and 42 to 44 support type, tag, place and direct per-pin styling. Id 39 answers true from `CMFHasProperty`. Its every-pin value is the menu default; a selected pin's type, tag, place or direct width overrides it. Width measures the description field in 1920 x 1080 units, preserving native padding and staying the same width on wide screens. There are no new `CMFProperty...` helpers for numeric ids 31 to 36 and 39 to 44. `CMFRegister(p, 40, target, context, "", id)` withdraws your exact slot; tag/place calls accept 40 too, using the effective id's level/context rules. Valid absent withdrawal returns true without dirtying or logging; actual removal logs once. Presence 38 and recursive 40 cannot be withdrawn. A direct width zero releases only the calling provider's direct width.

`CMFHasAbility('claims', word)` discovers `tagTint`, `placeClaims`, `playerArt`, `levelVariants`, `vanillaRows`, `everyPinIcon`, `withdraw`, `labelHideMerge` and `everyPin`. The first six describe the API version 11 widened-claim family; the last three are revision 13 behavior. Older cores may not recognize this capability namespace, so `CMFGetVersion() >= 11` is also a guard for the API version 11 cases. The newly listed every-pin forms need API version 13. The pack checker recognizes positive enclosing version/ability guards with matching provider identity; other expressions remain an unresolved advisory, not proof.

Section "Pin size, labels and the info box" below explains 10 to 15, "Pin clicks" explains 16, 20 and 21, "Spreading stacked pins" explains 22, "Legend rows and filter tabs" explains 23, "World overview pictures" and "Controller button pictures" explain 24 to 27, and "Names only on hover" explains 28, and "Changing one pin" explains 14 for one pin, 18, 19, 29, 30 and 37.

```
if (CMFHasProperty(3))
{
	CMFRegister("modAcmeIcons", 3, 'Herbalist', '', "", 4259648);
}
```

Write a property newer than the CMF version you require as its number, not as its `CMFProperty...()` function, since an older CMF does not have that function either.

| Call | What it does |
| --- | --- |
| `CMFDeclareTag(provider : string, tag : name) : bool` | API version 13. Makes a typed tag available to item styles, drawing filters and movie controls for this game session. Repeating it changes nothing; releasing your provider removes only your registration. |
| `CMFStyle(provider : string, part : name, target : name, key : name, text : string, number : float) : bool` | API version 13. Registers a per-item style; empty target is exactly CMFStylePart. |
| `CMFAddPin(provider : string, tag : name, pinType : name, area : name, x : float, y : float, label : string, description : string) : bool` | API version 13. Adds or updates your session-only pin at world X/Y with supplied display text. |
| `CMFRemovePin(provider : string, tag : name) : bool` | API version 13. Removes only your own added pin; valid absent removal succeeds. Independent claims targeting the tag remain. |
| `CMFHasProperty(propertyId : int) : bool` | `true` when the installed CMF understands that property id. Test an id before registering it, above all an id newer than API version 1. |
| `CMFRegister(provider : string, propertyId : int, target : name, mapContext : name, text : string, number : int) : bool` | One claim for a pin type (a map area for property 4). `mapContext` is `''` except for properties 5 and 9. Returns `false` and logs `rejected ... reason=unknown`, `reason=context`, `reason=empty` or `reason=exemption` when CMF does not accept the claim. |
| `CMFRegisterForTag(provider : string, propertyId : int, pinTag : name, mapContext : name, text : string, number : int) : bool` | The same for one pin by its tag; accepts properties 1, 5, 9, (API version 4) 10 to 13 and 15, (API version 5) 17, (API version 6) 16, 20, 21 and 22, (API version 10) 28 and (API version 11) 3, 14, 18, 19, 29 and 30 (`reason=level` otherwise). The game's own pins carry their tag; from API version 4 a pin another mod pushes is reached when that mod set its id to `NameToFlashUInt(tag)` (section 6). |
| `CMFRegisterForPlace(provider : string, propertyId : int, pinType : name, x : float, y : float, text : string, number : int) : bool` | API version 11. The same for the one pin of that type within `CMFPlaceRadius()` (2 metres) of the world position `x`, `y`, for a pin with no tag; takes the properties `CMFRegisterForTag` takes. See "Changing one pin" below. |
| `CMFRegisterLegendRow(provider : string, filteredType : name, category : name, priority : int)` | API version 2. Places a legend row in a filter tab; see "Legend rows and filter tabs" below. |
| `CMFRegisterLegendLabel(provider : string, filteredType : name, label : string)` | API version 2. Names a legend row. |
| `CMFRegisterLegendCategory(provider : string, category : name, label : string, priority : int)` | API version 2. Declares a filter tab after the vanilla tabs. |
| `CMFRegisterCategoryNoDefault(provider : string, category : name, noDefault : bool)` | API version 6. Keeps the rows of your tab out of Default (`true`), or lists them there again (`false`). |
| `CMFStylePin(provider : string, dataObject : CScriptedFlashObject, propertyId : int, text : string, number : int) : bool` | API version 2. Styles one pin object for this map opening; properties 1, 3 and 9, (API version 4) 10 to 13 and 15, (API version 5) 17, (API version 6) 16, 20 and 21, (API version 10) 28 and (API version 11) 14, 18, 19, 29 and 30. See "Styling one pin" below. |
| `CMFStylePinIcon(provider : string, dataObject : CScriptedFlashObject, url : string) : bool` | API version 2. `CMFStylePin` with property 1. |
| `CMFStylePinTint(provider : string, dataObject : CScriptedFlashObject, rgb : int) : bool` | API version 2. `CMFStylePin` with property 3. |
| `CMFRegisterHidden(provider : string, pinType : name, mapContext : name, exemptions : string, hide : bool)` | API version 3. Hides every pin of a type or `filteredType` (`''` for every pin) in one map context (`''` for every context); `hide` `false` withdraws. See "Hiding pins" below. |
| `CMFRegisterHiddenForTag(provider : string, pinTag : name, mapContext : name, exemptions : string, hide : bool)` | API version 3. The same for one pin by its tag. |
| `CMFHidePin(provider : string, dataObject : CScriptedFlashObject) : bool` | API version 3. Hides one pin object for this map opening; `CMFStylePin` with property 9. |
| `CMFStylePinScale(provider : string, dataObject : CScriptedFlashObject, percent : int) : bool` | API version 4. `CMFStylePin` with property 10. |
| `CMFStylePinLabel(provider : string, dataObject : CScriptedFlashObject, html : string) : bool` | API version 4. `CMFStylePin` with property 12. |
| `CMFLevelLabel(level : int, difficulty : int) : string` | API version 4. A quest level label in the journal's colours, to pass to `CMFStylePinLabel`. |
| `CMFLabelHidePin() : int`, `CMFLabelHideCrosshair() : int` | API version 4. The two label flags (`1`, `2`). |
| `CMFRegisterIcon(provider : string, pinType : name, url : string)` | Replaces the art of every pin of that type, and its legend row art unless you register a legend icon too. |
| `CMFRegisterLegendIcon(provider : string, pinType : name, url : string)` | Sets only the legend row art for that type. |
| `CMFRegisterTint(provider : string, pinType : name, rgb : int)` | Multiplies the type's pin art by a colour. Write the colour as a decimal number: red x 65536 + green x 256 + blue. `4259648` is `0x40FF40`, lime green. White parts of the art take the exact colour; most stock pin glyphs are gold or pale, so mid to bright colours read well, and dark ones turn the icon into a dark smudge. Because the colour multiplies, the same tint looks different on gold art: magenta on a notice board with new notices (`NoticeBoardFull`, gold) shows red, seen in game on 2026-10-20. The tint applies to whatever icon the pin shows, stock or from a pack, and to the type's legend row. The pins of the quest you are following keep their gold. |
| `CMFRegisterIconForTag(provider : string, pinTag : name, url : string)` | Replaces the art of one pin, identified by its map pin tag. It beats every type-level icon on that pin. It never applies to an undiscovered "?" pin or a completed (`...Disabled`) pin, so it cannot spoil or hide either. See section 6 for finding a tag. |
| `CMFRegisterDisabled(provider : string, pinType : name, mapContext : name, disable : bool)` | Draws every pin of that type greyed (grey art at reduced opacity, tint skipped). Appearance only: the pin can still be selected, shows its tooltip and keeps fast travel. `mapContext` is `'FastTravel'` (map opened at a signpost or a world exit), `'Boat'`, `'GlobalMap'` (opened from the menu), or `''` for every context; a claim for a specific context beats an every-context one. Calling again with `disable` `false` withdraws the greying; it shows the next time the map opens. Two packs claiming the same type and context resolve like icons: the earlier folder name wins. |
| `CMFRegisterDisabledForTag(provider : string, pinTag : name, mapContext : name, disable : bool)` | The same for one pin by its tag; it beats type-level claims on that pin. |
| `CMFRegisterBackground(provider : string, area : name, imageRoot : string)` | Replaces the map image of one area, such as `'AN_NMLandNovigrad'` (Velen and Novigrad). The tiles live in your pack's texture cache at `gameplay\gui_new\maps\<imageRoot>\level<L>\tile<X>x<Y>.jpg`, with the same tile size, level range and tile count as the area's vanilla image; CMF logs those values per area (`background area=...`) the first time the map shows it. The map draws level 0 as its background layer, then the area's own levels. |
| `CMFRequireVersion(provider : string, minVersion : int) : bool` | Returns `false` and logs a line when the installed CMF is older than `minVersion`. Wrap your calls in it as above. |
| `CMFReleaseProvider(provider : string)` | Withdraws everything your pack registered. Only needed if your pack can be switched off without being uninstalled. |
| `CMFGetVersion() : int` | The installed CMF script API revision; this source returns 13. API revisions and release versions are independent. |
| `CMFSetProviderName(provider : string, displayName : string) : bool` | API version 8. The name CMF's in-game menu shows for your mod, for example `"Acme Icons"`; without it the menu shows your folder name tidied. Returns `false` and logs for an empty provider or name. See [Players' choices](icon-pack-guide.md#players-choices-who-wins-each-feature-api-version-8). |
| `CMFChoicesChanged()` | API version 8. Tells CMF that a player's choice changed, so it prepares its winners again before the next lookup. CMF's menu add-on calls it; a pack never needs to. |
| `CMFRegisterWorldPainting(provider : string, url : string) : bool` | API version 9. Your picture for the world overview's painting. See "World overview pictures" below. |
| `CMFRegisterWorldPaintingTiles(provider : string, url : string, columns : int, rows : int) : bool` | API version 9. The painting as `columns` x `rows` tiles, each 1 to 8; the path holds `{x}` and `{y}`. Out of range returns `false` and logs `reason=range`. |
| `CMFRegisterWorldCrest(provider : string, region : name, url : string) : bool` | API version 9. Your picture for one region's crest on the world overview. |
| `CMFRegisterWorldMarker(provider : string, marker : name, url : string) : bool` | API version 9. Your picture for the overview's `'player'` or `'quest'` marker. |
| `CMFRegisterButtonPicture(provider : string, family : name, button : string, url : string) : bool` | API version 9. Your picture for one controller button of one family on the map. See "Controller button pictures" below. |
| `CMFRegisterChoiceOnly(provider : string, choiceKey : string) : bool` | API version 9. Your claims for that feature or piece apply only when the player picks your mod for it. See "Choice-only claims" below. |
| `CMFSetOpeningView(provider : string, area : name, x : float, y : float, zoom : float, keepPlace : bool) : bool` | API version 9. The view a region map opens with, called from an `OnMapOpening` wrapper. See "The map's view" below. |
| `CMFSetOpeningWorld(provider : string, area : name, worldX : float, worldY : float, zoom : float) : bool` | API version 9. As `CMFSetOpeningView`, with the place given in world coordinates (for example Geralt's position): the region map opens centred there. See "The map's view" below. |
| `CMFSetLogPins(on : bool)` | API version 11. Turns the pin list log on or off for this game session, for your own test pack. See "Changing one pin" below. |
| `CMFScreenWidth() : float`, `CMFScreenHeight() : float` | API version 10. The screen the map last opened on, in map units: 1920 x 1080 on a 16:9 screen, 2580 x 1080 on a 3440 x 1440 one, 1920 x 1200 on a 16:10 one; `0` before the first opening. See "Wide and tall screens" below. |

Behaviour you can rely on:

- **Registering again replaces.** The same pack, call and target replace the earlier value, so registering on every game start is correct. Changes appear the next time the map opens.
- **Image paths.** An image in `art/innkeeper.png` of `modAcmeIcons` is `img://icons/modacmeicons/innkeeper.png`: the folder name in lower case, then the file name. The pack tool prints every path.
- **Pin types are names**, in single quotes, case-sensitive: `'Innkeeper'`. The full list is [`pin-types.md`](pin-types.md).
- **Empty targets are rejected.** An empty type, tag or image path is refused and logged as `CMF rejected ...`.

Rules:

- Do not define functions or globals whose names start with `CMF`; that prefix is CMF's. Use your own short prefix.
- Do not write CMF's pin fields (`cmfIconPath`, `cmfLegendIconPath`, `cmfIconTint`, `cmfIconBy`, `cmfTintBy`, `cmfLegend...`, `cmfCategory...`, `cmfRowHide`, `cmfHiddenBy`, and from API version 4 `cmfIconScale`, `cmfLabelText`, `cmfLabelPlace`, `cmfLabelHide`, `cmfTabHide` and their `...By` fields, from API version 6 `cmfClick...` and `cmfSpreadRank...`, and from API version 11 `cmfDescMaxH`, `cmfDescMaxHBy`, `cmfInfoTitleBy` and `cmfInfoTextBy`) yourself, and wrap `CR4MapMenu.AddPinTypeData` or `CMFCore.OnPinReady` only to call `CMFStylePin`, its shorthands or `CMFHidePin`. CMF cannot see other changes made there, so it cannot resolve them against other packs.
- Do not name a variable `entry`, `state`, `quest`, `timer` or another WitcherScript keyword; the compile fails.
- Write arguments as literals, as above, so the pack tool can check them.

### Greying pins (API version 1)

A greying claim draws pins in the game's disabled look: grey art at reduced opacity. It is appearance only. A greyed pin stays on the map, can still be selected, shows its tooltip and keeps whatever travel the game or another mod allows; CMF never changes where Geralt may go. For example, a no-fast-travel mod that wants every signpost visible but greyed when the map is opened at a signpost:

```
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modAcmeLongRoad", 1))
	{
		// Every signpost greyed when the map is opened from a signpost.
		CMFRegisterDisabled("modAcmeLongRoad", 'RoadSign', 'FastTravel', true);
		// One signpost greyed in every context, by its map pin tag.
		CMFRegisterDisabledForTag("modAcmeLongRoad", 'seven_cats_inn', '', true);
	}
	return result;
}
```

- **Map context.** `'FastTravel'` (opened at a signpost or a world exit), `'Boat'`, `'GlobalMap'` (opened from the menu), or `''` for every context. A claim for one context beats an every-context claim.
- **Type or one pin.** `CMFRegisterDisabled` greys every pin of a type; `CMFRegisterDisabledForTag` greys one pin by its tag (section 6) and beats type-level claims on it.
- **Tint is skipped** on a greyed pin, so another pack's colour never shows through the grey. Another pack's icon still applies, drawn grey.
- **Hiding wins.** A hidden pin is not drawn, greyed or not.
- **Greying keeps only what is there.** CMF never brings back a pin another mod or the game removed. A mod that removes pins and wants them greyed instead keeps them in its own script and greys them here.
- **Timing.** Claims are read when the map builds its pins. Register at game start or in a wrapper that runs before the map opens; a claim made or withdrawn while the map is open shows the next time it opens. Changing claims between openings (for example a different set greyed at each signpost) has not yet been checked in game.
- **Withdraw** with the same call and `false`, or release everything with `CMFReleaseProvider`. Two packs greying the same type in the same context resolve like icons: the earlier folder name wins.
- **The log** counts each pack's claims when the map prepares (`CMF provider=... claims=... won=... shadowed=...`), with a `CMF shadowed provider=... property=5 ...` line for each greying claim another pack beat.

### Legend rows and filter tabs (API version 2)

Pins a mod pushes itself share one legend row per `filteredType`. Under API version 1 that row sits under All only and carries the first pin's label. API version 2 lets you name the row, put it in a tab, and declare your own tab:

```
if (CMFHasProperty(8))
{
	CMFRegister("modAcmeIcons", 8, 'modAcmeIcons_finds', '', "[[acme_tab_finds]]", 1);
	CMFRegister("modAcmeIcons", 6, 'AcmeFind', '', "modAcmeIcons_finds", 701);
	CMFRegister("modAcmeIcons", 7, 'AcmeFind', '', "[[acme_row_finds]]", 0);
}
```

Written with the generic call and guarded by `CMFHasProperty(8)`, this still compiles on API version 1, which skips it. A pack that requires API version 2 can use `CMFRegisterLegendCategory`, `CMFRegisterLegendRow` and `CMFRegisterLegendLabel` instead.

- **Category ids** are names. Prefix new ones with your pack name. A carry-over id keeps the original mod's name (the Witcher Gear Map adapter uses Gear's `wgm_gear`). Two packs may share one id on purpose; both packs' rows land in that tab. A vanilla category name (`All`, `Default`, `General`, `Quests`, `Exploration`, `NPCs`, `Buffs`) is refused with `reason=vanilla`.
- **Rows** can join a vanilla category (`General`, `Quests`, `Exploration`, `NPCs`, `Buffs`), a declared CMF category, or `""` for All only. A row naming a category nobody declared stays under All, and CMF logs `reason=undeclared`. Up to API version 10, rows the vanilla legend already defines keep their vanilla tab and order. From API version 11, a row claim with a priority above `0` moves one of the game's own rows too (the shared quest row keeps its own rule), and property `37` hides a whole tab (section 5, "Changing one pin").
- **Labels** apply to any row except the shared quest row and the player-pin row, vanilla rows included. A `[[key]]` label resolves through the game's text from whichever mod ships that key.
- **Quest rows (API version 6).** Quest pins share one quest row. A row claim on a quest pin's `filteredType` takes those quest pins out of that row and into a row of their own, keyed by the `filteredType`. That row is listed, counted and shown or hidden by that key, in every tab where quest pins show and under All. Its order is your claim's `number`, even for a `filteredType` the vanilla legend defines; its tab is still the vanilla one where it defines one. Its name is your label claim, or the game's quest row name when you have none. Quest pins of other `filteredType`s, and the tracked quest's gold, tooltip and tracking, stay as they are. For example, `CMFRegisterLegendRow(p, 'QuestObjectiveOther', 'Quests', 200)` plus `CMFRegisterLegendLabel(p, 'QuestObjectiveOther', "All Quest Objectives")` gives untracked side objectives their own row, as All Quest Objectives does.
- **CMF tabs** come after the vanilla tabs, in order of their `number` and then their id. Like General, they show fast-travel and player pins but not quest pins, and their rows also appear in Default. From API version 6, `CMFRegisterCategoryNoDefault(p, 'modAcmeIcons_finds', true)` (property 23) keeps a tab's rows out of Default, so its pins show only under All and in the tab itself, as Exploration's do; a vanilla tab id is refused with `reason=vanilla`. A declared tab with no rows does not appear. The map does not reopen on a CMF tab; it reopens on the last vanilla tab used.
- **Hiding a row under All** hides every pin type that shares its `filteredType`, for pins a mod pushes itself.
- **Conflicts:** row, label and tab are separate claims; for each, the earlier folder name wins, as for icons. CMF logs every winning tab and row (`legend category ...`, `legend row ...`).

### Styling one pin (API version 2)

For an archive that also compiles without CMF, see [One download, with and without CMF](icon-pack-guide.md#one-download-with-and-without-cmf).

Registration calls style every pin of a type. To style one pin from a decision your mod makes while the pin exists (a level, a state), call `CMFStylePin` on the pin object before the map sends it. From API version 4 the simplest place is an `OnPinReady` wrapper, which sees every pin (below). Otherwise use an `AddPinTypeData` wrapper for the game's own pins, or an `UpdateEntityPins` or `UpdateUserMapPins` wrapper, or call it right after creating your own `StaticMapPinData` object:

```
@wrapMethod(CR4MapMenu)
function AddPinTypeData(out dataObject : CScriptedFlashObject, targetPin : SCommonMapPinInstance) : void
{
	wrappedMethod(dataObject, targetPin);
	if (targetPin.visibleType == 'NoticeBoard' && !targetPin.isHighlighted)
	{
		CMFStylePinTint("modAcmeIcons", dataObject, 4259648);
	}
}
```

- **Which properties.** Icon (1: `text` is an image path, or from API version 4 `"frame:<label>"` for a frame of the game's pin icon), tint (3: `number` is a colour), hide (9) and, from API version 4, 10 to 13 and 15 with the values in the table above. Other ids are refused with `reason=style`.
- **It beats every registered value** on that pin: tag, type and `filteredType` claims.
- **The followed quest's gold is yours to keep.** Type-level tints skip tracked and highlighted pins; a per-pin call does not, so read `tracked` or `highlighted` yourself, as above.
- **Conflicts do not depend on wrapper order.** CMF records which pack styled each property of the pin. When two packs style the same pin, the earlier folder name wins, whichever wrapper runs first. The call returns `false` for the loser, and CMF logs `style shadowed provider=... by=...` once per pack, pin type and property.
- **Nothing to clear.** Pin objects are rebuilt every time the map opens.
- Calling `CMFStylePin` or its shorthands needs API version 2 to compile. Say so in your README.

The Map Quest Insight adapter is the worked example: it reads that mod's own values on each pin and passes them to `CMFStylePinTint`, `CMFStylePinIcon`, `CMFStylePinScale` and `CMFStylePinLabel` (section 12).

### Hiding pins (API version 3)

A hide claim takes pins off the map before the map receives its list, so the legend counts, cycling through a row, tooltips, the corner overview and "show on map" all agree with what is drawn. Hiding wins over everything else: a hide from the last folder beats an icon, tint, label, greying or per-pin style from the first. There is no winner among hide claims; every one applies.

```
if (CMFHasProperty(9))
{
	// Opened from a signpost: hide everything except quest pins and travel points.
	CMFRegister("modAcmeTidyMap", 9, '', 'FastTravel', "quest,fasttravel", 1);
	// Hide herbalists everywhere, but keep them if the followed quest points at one.
	CMFRegister("modAcmeTidyMap", 9, 'Herbalist', '', "tracked", 1);
}
```

- **Three levels and one per-pin call.** Every pin (target `''`), one pin type (matches a pin's own `type` or its `filteredType`, so `'WitcherGear'` hides every Gear variant), one pin by its tag (`CMFRegisterForTag`, property 9; a game pin, or from API version 4 a pin another mod pushes with its id set to `NameToFlashUInt(tag)`), or one pin object while the map builds (`CMFHidePin`, from an `AddPinTypeData` or `UpdateEntityPins` wrapper, or on your own pin object before you push it).
- **Map context** works as for greying: `'FastTravel'`, `'Boat'`, `'GlobalMap'`, or `''` for every context.
- **Exemptions belong to each claim.** `tracked` keeps the followed quest's pins, `quest` keeps every quest pin, `fasttravel` keeps signposts, harbours and other travel points. Write them separated by commas or spaces; case does not matter. An unknown word rejects the whole claim (`reason=exemption`), so a typo never hides more than you meant. Another pack's claim is never an exemption. Use `tracked` unless hiding the followed quest is the point.
- **Geralt's marker is never hidden unless a pack names it.** From API version 9 a type claim on exactly `'Player'`, such as `CMFRegisterHidden("modAcmeTidyMap", 'Player', 'GlobalMap', "", true)`, hides it in that context, and the log shows `hide player provider= context=` once per map build; an every-pin claim, a tag claim and exemptions never touch it. The player's own pins are never hidden. A per-pin call on either returns `false` (`reason=user`).
- **Too late:** a per-pin call after CMF has sent the list (for example in an `UpdateUserMapPins` wrapper whose file sorts after CMF's) returns `false` and logs `reason=late` once; that pin stays. Make the call in `OnPinReady` instead, which also sees pins added in such a wrapper.
- **Hide with a claim, not by removing pins yourself.** A removal in your own wrapper reaches only the pins that wrapper can see. Not pushing your own pins at all is still fine and needs no claim.
- **Withdraw** by registering the same claim with `0` (or `hide` `false`); release everything with `CMFReleaseProvider`. Changes made while the map is open apply the next time it builds its list (reopen it or switch area), as for every other property.
- **The log** shows every hide claim (`hide provider= level= type= tag= context= exempt=`), and per map build how many pins each pack hid (`hidden provider= pins=`).
- On API versions 1 and 2, `CMFHasProperty(9)` is `false`, so the generic calls above compile and do nothing. `CMFRegisterHidden`, `CMFRegisterHiddenForTag`, `CMFHidePin` and `CMFPropertyHidden` need API version 3 to compile. Say so in your README.

### Pin size, labels and the info box (API version 4)

API version 4 adds six properties. Pin size, label text and the scrolling info box ran in game on 2026-10-20 (the N4 launch). Label place, label hides and tab hides are checked statically only.

| Property id | Target | `text` | `number` |
| --- | --- | --- | --- |
| `10` `CMFPropertyPinScale()` | a pin type, a tag or one pin | unused (`""`) | size in percent of the game's size, `25` to `400` |
| `11` `CMFPropertyLabelPlace()` | a pin type, a tag or one pin | unused | distance of the label from the pin centre, in tenths of a pin unit, `0` to `10000`; `0` keeps the game's place |
| `12` `CMFPropertyLabelText()` | a pin type, a tag or one pin | the label, in HTML as the game's labels; must not be empty | unused |
| `13` `CMFPropertyLabelHide()` | a pin type, a tag or one pin | `"pin"`, `"crosshair"` or both (`"pin,crosshair"`) | nonzero hides, `0` withdraws |
| `14` `CMFPropertyInfoBoxHeight()` | `''` only, through `CMFRegister` only | unused | the info box's text height in px, `100` to `1080`; `0` withdraws |
| `15` `CMFPropertyTabHide()` | a pin type, a tag, one pin, or `''` for every pin | filter tab names: `"Quests"`, `"Exploration"`, `"NPCs"`, `"Buffs"` or a tab id, separated by commas or spaces | nonzero hides, `0` withdraws |

- **Size** scales the pin's icon, its highlight ring and its glow together. The player marker and the player's own pins are never resized. To draw a larger picture without a larger ring and glow (a badge, say), keep the size and grow the picture with id 44 (API version 13): it multiplies the size for the icon and the picture under it (42) only.
- **Labels** sit below signposts and above other pins, as the game places them. A label place moves it further from the pin.
- **Which label to hide.** `"pin"` hides the label drawn on the map next to the pin; `"crosshair"` hides the name the crosshair shows when it rests on the pin. In script the two flags are `CMFLabelHidePin()` (1) and `CMFLabelHideCrosshair()` (2), so you can add them up while you decide and then pass the matching text.
- **The info box** scrolls when its text is taller than the height you give, with a scroll bar and the inputs Map Quest Insight's map uses. Only one height applies: the earliest folder among the claims wins. `0` keeps the game's box.
- **Label hides (13)** merge eligible contributions by union. Eligibility is recomputed when a selected direct-only provider first contributes, so wrapper order cannot leave an ineligible hide behind; zero never removes an eligible hide.
- **Tab hides** leave a pin out of the filter tabs you name; it stays in the others and under All. Like hide claims, every tab hide applies; there is no winner.
- **Conflicts** for 10 to 12 work as for icons: a per-pin call beats a tag claim, a tag claim beats a type claim, and within one level the earlier folder name wins.
- `CMFRegisterForTag` accepts 10 to 13 and 15. Size and label tag claims never apply to an undiscovered "?" pin or a completed pin.

The per-pin calls, all API version 4:

| Call | What it does |
| --- | --- |
| `CMFStylePinScale(provider : string, dataObject : CScriptedFlashObject, percent : int) : bool` | `CMFStylePin` with property 10. |
| `CMFStylePinLabel(provider : string, dataObject : CScriptedFlashObject, html : string) : bool` | `CMFStylePin` with property 12: your own label, in your own HTML. |
| `CMFLevelLabel(level : int, difficulty : int) : string` | Builds a quest level label as the game's journal draws it: CMF's localized "Lv" and the number, coloured by difficulty (0 or less grey `#969696`, 1 white `#ffffff`, 2 orange `#d68f29`, 3 or more red `#d61010`). Pass the result to `CMFStylePinLabel` or a LabelText claim. |
| `CMFLabelHidePin() : int`, `CMFLabelHideCrosshair() : int` | The two label flags, `1` and `2`. |

**Your own label first.** `CMFStylePinLabel` takes any HTML the game's labels take, so you decide the text, colour and size:

```
CMFStylePinLabel("modAcmeLabels", dataObject, "<font color='#80c0ff'>Well</font>");
```

**The journal's colours as a shortcut.** When you only want the level as the game's quest journal shows it, let CMF build the text:

```
CMFStylePinLabel("modAcmeLabels", dataObject, CMFLevelLabel(level, difficulty));
```

Size, place and label hides from the generic call:

```
CMFStylePinScale("modAcmeLabels", dataObject, 150);
CMFStylePin("modAcmeLabels", dataObject, CMFPropertyLabelPlace(), "", 20);
CMFStylePin("modAcmeLabels", dataObject, CMFPropertyLabelHide(), "crosshair", 1);
```

And for every pin of a type, or every pin, at game start:

```
if (CMFHasProperty(15))
{
	CMFRegister("modAcmeLabels", 10, 'RoadSign', '', "", 125);
	CMFRegister("modAcmeLabels", 15, 'RoadSign', '', "Quests", 1);
	CMFRegister("modAcmeLabels", 14, '', '', "", 600);
}
```

### The pin hook: `OnPinReady` (API version 4)

`AddPinTypeData` only sees the game's own pins, and an `UpdateEntityPins` wrapper only sees the pins pushed by wrappers inside it. API version 4 gives you one place that sees every pin after every mod has added its own:

```
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	wrappedMethod(dataObject, mapContext);
	if (dataObject.GetMemberFlashString("type") == "RoadSign")
	{
		CMFStylePinScale("modAcmeLabels", dataObject, 125);
	}
}
```

- CMF calls it once per pin on every full build of the map's pin list, for engine pins and pins other mods push alike, but never for the player marker or the player's own pins.
- Pins another mod pushes from an `UpdateUserMapPins` wrapper that runs outside CMF's (wrappers nest by script file name and path, and precompiled scripts have their own place; Shared Utils pushes Botanist's pins this way) are caught after the game's `UpdateData`: CMF writes their claims, calls `OnPinReady` for those pins only, runs `OnMapReady` again and sends the list a second time, logging `late pins caught n= of`. Ran in game on 2026-10-21: Botanist's 31 pins from Shared Utils (`late pins caught n=31 of 461`).
- It runs after CMF has written the type and tag claims onto the pin and before hidden pins are removed, so per-pin calls made here (`CMFStylePin` and its shorthands, `CMFHidePin`) count in the same map opening, and a per-pin call here beats every registered value as usual.
- `mapContext` is `'FastTravel'`, `'Boat'` or `'GlobalMap'`, as for greying.
- Always call `wrappedMethod(dataObject, mapContext)` first, so other mods' wrappers run too.
- `CMFCore` and `OnPinReady` exist from API version 4 only: a wrapper on them stops older CMF versions at the compile screen. Say so in your README.
- Ran in game on 2026-10-20: the Map Quest Insight and Ink and Iron adapters draw their level labels from it.

### Key hints and filter tab reports (API version 4)

**Revision 13 hooks**

New integrations wrap the core hooks below. They need API version 13 to compile. These hooks are available from API version 13; the map dispatches them alongside the legacy adapter events.

- Filter tabs: the core declares `OnCMFMapTab(category : string)` on `CR4MapMenu` and forwards it to `CMFCore.OnMapTab(menu, category)`.
- Key hints: offer a list with `CMFStylePart("modMyPack", 'hints', 'list', "", 1)`. `Look_Hints` selects the owner among list offers only. Withdraw the offer with text `"unset"`. The core declares `OnCMFMapHints()` and calls `CMFCore.OnMapHints(menu, owner)` only for an eligible list offer. The common menu still handles keys.

The old events `OnCMFMapFilter` and `OnCMFMapHintsReady` remain adapter-owned. Do not add either event a second time. Existing adapters keep their declarations and write their legacy list separately from managed hints.

```witcherscript
@wrapMethod(CMFCore)
function OnMapTab(menu : CR4MapMenu, category : string)
{
    wrappedMethod(menu, category);
    // React to the tab here.
}

@wrapMethod(CMFCore)
function OnMapHints(menu : CR4MapMenu, owner : string)
{
    var storage : CScriptedFlashValueStorage;
    var list : CScriptedFlashArray;
    var metadata : CScriptedFlashObject;
    wrappedMethod(menu, owner);
    if (owner != "modMyPack") { return; }
    storage = menu.GetMenuFlashValueStorage();
    if (!storage) { return; }
    list = storage.CreateTempFlashArray();
    metadata = storage.CreateTempFlashObject();
    metadata.SetMemberFlashString("owner", owner);
    list.PushBackFlashObject(metadata);
    // Append your current hint objects after the metadata.
    storage.SetFlashArray("cmf.map.hints.owned", list);
}
```

The managed channel is `cmf.map.hints.owned`: a metadata object `{owner: provider}` followed by hint objects. Each hint object takes the game's key-hint fields: `actionId`, `label` (shown as written), `keyboard_keyCode` and `gamepad_navEquivalent`, and optionally `level`, `holdDuration`, `hasHoldPrefix` and `click`. CMF's map copies a plain object (`CreateTempFlashObject()` with no class name) into the game's key-hint class, so either kind works. An empty array releases this channel. Never write or clear the legacy `cmf.map.hints` channel from this hook. With no offer and no prior managed list, the core writes nothing. A changed owner receives a fresh envelope; removing the final offer clears only the managed channel at the next new hints event. The map adds the managed entries to the game's own key hint row, after the game's own hints (CMF 1.6.3 and later; before, they replaced CMF's copy of the row and could sit on top of the game's row). A mod that hides the game's row and draws its own copy from it, such as Ink and Iron, shows them in that copy. CMF's own copy keeps showing the latest legacy list, and releasing the managed list removes its entries. The row shows each entry's label and keys; `level`, `holdDuration` and `hasHoldPrefix` are not drawn there. Flash storage has no supported array readback; providers rebuild their own list.

**Per-item styles and added pins (API version 13).** `CMFStyle` accepts: `legendRow` target = bare filteredType; `legendTab` = internal tab name or `id:<nonnegative decimal>`; `tooltip`, `pinLabel`, `pinName`, `pinButton` = bare type, `type:<type>` or `tag:<tag>`. Empty prefixes and unknown prefixes are rejected. A tag overrides a type, and a matching item key overrides the whole-part key on the map. Items arbitrate independently through the existing part/key choice, including Vanilla and strict fallthrough. Text keys are `title.text` (area target, or empty for whole title), `worldHint.text`, `worldButton.text` and `legend.allText` (empty target for the latter three). `"unset"` removes only your own item/key. Per-item data uses `cmf.map.itemStyles`; old whole-part payloads remain separate.

**Making a tag available to text targets.**

A `tag:<tag>` item target or a drawing's `pinTag` list needs a tag known to CMF. Registering a claim by tag or adding a pin supplies its typed name. To make a tag known without another claim, call `CMFDeclareTag("modAcmeIcons", 'my_tag')`. It is available for this game session; releasing that provider removes its registration while preserving other providers' registrations of the same tag.

Text matching ignores case. CMF resolves the text when it sends styles and drawing filters, so the declaration may come after the style. An unknown tag matches nothing and logs `tag unknown, declare it with CMFDeclareTag` once per provider and tag. A pin with id 0 never matches a tag. For a pin your mod pushes itself, set its id to `NameToFlashUInt('my_tag')`. CMF never reconstructs a name from an arbitrary id.

`CMFAddPin` tags use `provider.suffix` with a nonempty suffix; identifiers use letters, digits, dot, underscore or hyphen. Provider/tag ownership compares without case. Type and area must be nonempty, with area other than `AN_Undefined`; coordinates must be finite. Repeating identical data is a no-op; changing position/area/text updates the same record. The registry lasts only for the game session and retains no Flash objects. Full builds append only pins for the shown area, without duplicate ids, before ordinary claim/hide/click processing. The content is non-quest and non-travel. Releasing a provider removes its content. **A pin added while the map is open shows at the next opening.** No call forces a rebuild. These named calls require API version 13 to compile, even inside a runtime guard.

New choice keys 72 to 79 are Behaviour_InfoBoxMotion, Look_Sounds, Behaviour_InfoFold, Behaviour_PanelModes, Look_Badges, Look_PinLook, Size_Place and Behaviour_PinZoom. The piece-parent table starts empty. A future split inherits Automatic from its parent within the same menu or file tier; explicit child answers remain independent.

### The map theme (API version 5)

API version 5 lets a mod restyle the map itself and draw on it, with three general calls. Your script only describes the look; CMF's map draws it, each time the map opens. Ran in game on 2026-10-20: Ink and Iron's look through its adapter, and a drastically different test theme drawn from these calls alone.

| Call | What it does |
| --- | --- |
| `CMFStylePart(provider : string, part : name, key : name, text : string, number : float) : bool` | Sets one style key of a part of the map: fonts, colours, glows, the game's own plates to hide, or a map behaviour. |
| `CMFDraw(provider : string, anchor : name, id : name, kind : name) : bool` | Makes a drawing with your own `id`, tied to a part or to any drawing any mod made. `kind` is `rect`, `ring`, `ellipse`, `polygon` or `band`; `''` withdraws it. |
| `CMFDrawSet(provider : string, id : name, key : name, text : string, number : float) : bool` | Sets one key of your drawing: its place, paint, glow, layer and conditions. |
| `CMFHasAbility(part : name, key : name) : bool` | Asks whether this CMF knows a part, layer or kind (`key` `''`) or a key, before you use it. |

- **Parts** are the game map's own pieces: `screen`, `map`, `mapEdge`, `title`, `tracker`, `legend`, `legendRow`, `legendTab`, `tooltip`, `preview`, `worldButton`, `worldHint`, `hints`, `keyCap`, `pinLabel` (labels above pins), `pinName` (names below fast-travel pins), `navigation`, `markerPanel` and, from API version 6, `opening`. Which keys each takes, what each key does, and the words its `hide` key accepts, are in [`theme-parts-and-keys.md`](theme-parts-and-keys.md); the pack tool's check reports any key a part does not take.
- **Words go in `text`, everything else in `number`.** Fonts (`"$TitleFont"`), `hide` lists (`"plate,divider"`), layers, views and `"label"` are text; colours are decimal `0xRRGGBB` numbers, as for tints.
- **A drawing is placed against its anchor's box**: the part's visible text trimmed to its width plus 8 px, or the box of the drawing it is tied to. `left`, `top`, `right`, `bottom` push each edge outward in px (negative moves inward); `width`/`height` with `alignX`/`alignY` give a fixed size; `minLeft`, `maxRight`, `minTop`, `maxBottom` keep it on screen; `screenLeft` and the others fix an edge to the screen. On `pinLabel` and `pinName` the box is the label's text box (text width + 4 by text height + 4 px).
- **Paint** with `fill`/`alpha`, a linear gradient with `fill2`, `alpha2`, `gradient` `"linear"`, `angle` and `curve`, an outline with `stroke`, and glows and shadows with the same keys as parts. `repeat` and `repeatStep` draw grown copies (a soft shadow of rings), `alphaList` gives each copy its own opacity.
- **Layers.** `layer` is `over` by default (just above the part); `under` is just below it, `belowMap` under the map image, `aboveMap` over the map image and under every panel, `top` over every panel. `order` sorts within a layer. `view` (`"region,interior,world"`) and `when` (`"selected"`, `"tracked"`, `"untracked"`) limit when it shows.
- **Who wins.** The earliest folder that styles a part owns all of that part's style keys; `map`, `navigation`, `opening`, `spread` and (API version 10) `wide` keys are won one by one. From API version 10 a part's behaviour keys (the tooltip's `clear` keys, the label's `rise` keys) have an owner of their own, apart from its look ("Players' choices" below). Every mod may draw: drawings from several mods sit together, the earlier folder on top within the same `order`. An id belongs to the folder that made it first, so prefix ids with your mod's name.
- **Pin label colour.** Property `17`, `CMFPropertyLabelColor()`, colours a pin's label (`0xRRGGBB`) by type, tag or one pin, like any pin property; a `pinLabel` drawing with `fill` `"label"` takes that colour.
- `navigation` and `opening` keys change how the map moves and opens; see "Smooth map movement" below.

A frame round the quest tracker, with a glow, and the title on one line in your colour:

```
if (CMFRequireVersion("modAcmeTheme", 5))
{
	CMFStylePart("modAcmeTheme", 'tracker', 'hide', "plate", 0);
	CMFDraw("modAcmeTheme", 'tracker', 'acmeTrackerFrame', 'ring');
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'left', "", 12);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'top', "", 12);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'right', "", 12);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'bottom', "", 12);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'inset', "", 2);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'fill', "", 61695);	// 0x00F0FF
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'glow1Color', "", 61695);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'glow1Blur', "", 16);
	CMFDrawSet("modAcmeTheme", 'acmeTrackerFrame', 'layer', "under", 0);
	CMFStylePart("modAcmeTheme", 'title', 'color', "", 16722902);	// 0xFF2BD6
	CMFStylePart("modAcmeTheme", 'title', 'wrap', "none", 0);
}
```

Two complete themes use only these calls: the Ink and Iron adapter (section 12) and CMF's test theme `source/providers/modCMFTestThemePack`, a neon look with its own map art and quest icons.

### Pin clicks (API version 6)

Ran in game on 2026-10-20 through the Map Pin Teleport adapter: the button, the E key and a long-distance teleport. API version 6 lets a mod do something when the player uses a pin on the map: teleport to a placed pin, open a shop list, forget a remembered pin. You claim inputs on pins the way you claim any pin property. CMF's map sends each click to the one mod that won it, and that mod does the work in its own script.

| Property | `text` | `number` |
| --- | --- | --- |
| `16` `CMFPropertyPinClick()` | the inputs: any of `use`, `doubleClick`, `button`, `hold`, separated by commas or spaces | any nonzero value, handed back with each click; `0` withdraws |
| `20` `CMFPropertyPinClickHint()` | the words the button bar shows beside E (gamepad A) while the pin is selected | nonzero; `0` withdraws |
| `21` `CMFPropertyPinClickButton()` | the words on the button drawn beside the pin | nonzero; `0` withdraws |

Claim a click, its hint and a button for every pin of your own type, and answer the click by wrapping the hook `OnPinClicked`:

```
if (CMFRequireVersion("modAcmeWells", 6))
{
	CMFRegister("modAcmeWells", CMFPropertyPinClick(), 'AcmeWell', '', "use, button", 1);
	CMFRegister("modAcmeWells", CMFPropertyPinClickHint(), 'AcmeWell', '', "Draw water", 1);
	CMFRegister("modAcmeWells", CMFPropertyPinClickButton(), 'AcmeWell', '', "DRAW WATER", 1);
}
```

```
@wrapMethod(CMFCore)
function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string,
	input : string, value : int) : bool
{
	if (provider != "modAcmeWells")
	{
		return wrappedMethod(menu, provider, pinTag, pinId, pinType, input, value);
	}
	AcmeDrawWater(pinTag);
	return true;
}
```

The wrapper acts only when `provider` is your own folder name and passes every other click on unchanged. Because each wrapper tests its own name, the order the game runs wrappers in never matters. Your wrapper is called once per click you won; a click is never sent to every mod.

- **The inputs.** `use` is E, Enter or gamepad A on the selected pin, acted on when the key comes up and only when it went down on the map, so a key carried in from another menu does nothing. It is also a touch tap on the selected pin, except on a placed pin, where the tap still removes the pin as the game does. `doubleClick` is a mouse double-click on the selected pin. `button` draws a button beside the pin that follows pan and zoom and hides with the pin, off screen, and while the world map is not showing or the quest list is open; clicking it sends the click, and the map never sees the press.
- **Which pins.** The usual three calls: `CMFRegister` for every pin of a type (its own `type`, then its `filteredType`), `CMFRegisterForTag` for one pin by its tag, and `CMFStylePin` for one pin object while the map builds. Click claims also reach the pins the player places (`User1` and the other user types), including a pin just placed; no other property does.
- **One winner per pin.** A per-pin claim beats a tag claim, which beats a type claim. At the same level the earlier provider in CMF's provider order wins (folder order unless the player set one), then the earlier registration. The loser is logged once, for example `CMF click shadowed provider=modZZOther by=modAcmeWells`, and never hears the click.
- **The hint and button follow the winner.** CMF shows a hint or button only from the mod that won the pin's click, so the words always name the action that runs. Text is shown as you give it; for a translation pass `GetLocStringByKeyExt("your_key")`.
- **Hold (API version 13).** `hold` uses bit `8` (`CMFClickInputHold()`), alongside use `1`, double-click `2` and button `4`. Hold E, Enter, gamepad A or the left mouse button on the selected pin. It sends one `"hold"` event after `navigation.padHoldMs` (milliseconds); zero keeps the game's half-second delay. Repeated down/hold events and release send no second click. A short key or pad press keeps native quest tracking or travel; a pin that also claims `use` keeps its short use click. Short pointer presses and mouse dragging keep their game behavior. Selection, area, focus, fold input, close or removal cancels a pending hold. Hint and button words come from that same click winner.
- **The game keeps its own inputs.** `use` and `doubleClick` are refused on fast-travel and quest pins (`CMF click refused provider=... reason=game`), so signposts still travel and quests still track; `button` and `hold` work on these pins too. A claimed hold replaces the native hold action, while a short key or pad press preserves the native action. The player arrow takes no click, and claimed holds do not draw the native hold-to-use ring.
- **What the hook receives.** `input` is `"use"`, `"doubleClick"`, `"button"` or `"hold"`; `value` is your claim's number, so one wrapper can tell its claims apart; `pinType` is the pin's type; `pinId` is the pin's own id as the script's whole number (an id above 2147483647 arrives negative, the same 32 bits the game's own script holds for a placed pin); `pinTag` is the pin's tag for the game's pins and for pins pushed with their id set to `NameToFlashUInt(tag)` (a placed pin's tag is always `None`, because its id is no name; use `pinId` there); `menu` is the open map, for closing it or showing a message. Each click logs `CMF panel click sent input=use pin=...` from the map, then `CMF click provider=modAcmeWells input=use type=AcmeWell pin=... tag=... value=1` from the script. A click nobody answers logs `reason=nohandler`.
- **The button's look** is the theme part `pinButton`, styled with `CMFStylePart`: `width`, `height`, `curve`, `fill`, `alpha`, `stroke`, `strokeWidth`, `offsetX`, `offsetY` (the button's top-left corner measured from the pin, in px) and the text keys `font`, `size`, `color`, `spacing`, `align` and the glow keys. CMF's own button is plain: 140 x 36 px, a black fill at 0.7, a thin light grey outline and near-white `$NormalFont` text at 18 px, 24 px right of the pin and centred on it. As with every part, the earliest folder that styles `pinButton` owns its look for every button. It takes no drawings.
- `CMFPropertyPinClick`, `CMFPropertyPinClickHint`, `CMFPropertyPinClickButton` and a wrapper on `OnPinClicked` need API version 6 to compile. Written as the numbers 16, 20 and 21 behind `CMFHasProperty(16)`, the claims alone compile on any CMF. Say so in your README.
- Gamepad A and touch taps run the same code as E and the mouse, but neither has been tried.

### Smooth map movement (API version 6)

Ran in game on 2026-10-20 through the Smooth Map and Map Quest Insight adapters (frame rate, pan and zoom timing, the opening slide, `zoomOutFit`). API version 6 makes the map's movement and opening themeable through the same `CMFStylePart` call: the `navigation` part gains keys and a new `opening` part arrives. They are behaviours, not looks, so each key is won on its own by the earliest folder that sets it, like `map` keys. A key nobody sets keeps the game's behaviour, except four that CMF sets itself: since 1.0.0 CMF's map runs at `frameRate` `60` with `frameTimed`, `zoomTimed` and `tweenEveryFrame` `1`, so it pans, zooms and fades at the game's speed but smoother. Before CMF 1.5.0 the pan distance was right but the map still moved in about 59 steps a second on the region map and 42 on the world view (see `frameTimed` below). Any folder's own value for one of these keys wins over CMF's; send `frameRate` `24` and the other three as `0` to keep the game's movement exactly. The log names each key CMF set itself (`theme default part=navigation key=frameRate value=60`). The map reads the keys once per opening.

`navigation` (how the map moves). API version 5 already accepts `frameTimed`, `stepMs`, `worldStepMs`, `maxStepMs` and the controller crosshair keys; CMF's map now acts on the first four.

| Key | Game | Range | What it does |
| --- | --- | --- | --- |
| `frameTimed` | `0` | `0`/`1` | `1` moves held-key and stick panning, key and stick zoom and the world view by the time since the last frame instead of a fixed step per timer tick; from CMF 1.5.0 the step timers then run every frame. Earlier versions kept the 17 and 24 ms beat and scaled only the step. |
| `stepMs` | `17` | `1` to `1000` | the region map's step: the game's speed is 15 px per `stepMs`. |
| `worldStepMs` | `24` | `1` to `1000` | the same for the world view (10 px per step). |
| `maxStepMs` | `100` | `1` to `1000` | the longest gap one frame counts, so a hitch does not throw the map. |
| `zoomTimed` | `0` | `0`/`1` | with `frameTimed` `1`, `1` scales zoom by elapsed time; `0` keeps one zoom step per `stepMs`. |
| `padHoldMs` | `0` | `0` to `1000` | a stick reading stays in effect this long; `0` uses each reading once. |
| `tweenEveryFrame` | `0` | `0`/`1` | `1` advances snaps, centring, fades and the menu's slide on every drawn frame. |
| `frameRate` | `24` | `24` to `60` | the map movie's frame rate (its looping animations, and its tweens without `tweenEveryFrame`). |
| `zoomOutFit` | `0` | `0`/`1` | `1` lets the region map zoom out until the whole region fits the map area, never less far than the game. The map still opens at the game's zoom. |
| `edgeOvershoot` | `0` | `0` to `400` px | below the game's own zoom limit, how far past the region's edge the crosshair may pan, blending in towards the `zoomOutFit` limit. |

`opening` (how the map opens and closes):

| Key | Game | Range | What it does |
| --- | --- | --- | --- |
| `slideSeconds`, `slideOffset` | `0.8`, `500` | `0` to `5`, `-2000` to `2000` px | the menu's slide-in time and distance; `0` px fades only. |
| `closeSeconds` | `0.3` | `0` to `5` | the close time. |
| `pinsDuringSlide` | `0` | `0`/`1` | `1` prepares pins while the menu slides in. |
| `pinStepMs`, `pinBatch`, `pinBudgetMs` | `20`, `30`, `0` | `1` to `1000`, `0` to `100000`, `0` to `1000` | the pin preparation tick, pins per tick (`0` = no count limit) and the ms a tick may take (`0` = no limit). Both `0` means 30 000 pins per tick. |
| `showDelayMs` | `200` | `0` to `5000` | the wait between prepared pins and the fade-in. |
| `fadeSeconds`, `tileFadeSeconds` | `0.33`, `0.66` | `0` to `5` | the edge gradient and pin fade-in, and the map tiles' fade-in. |
| `revealSeconds` | `0` | `0` to `5` | the crosshair, edge pointers, legend and quest tracker fade in over this time; `0` shows them at once. |
| `readyAtFadeStart` (API version 10; ran in game on 2026-10-24) | `0` | `0`/`1` | `1`: the map takes input, and the legend, quest tracker, crosshair and edge pointers appear (or begin their `revealSeconds` fade), as soon as the fade-in starts after `showDelayMs`, instead of after the tiles have faded in. |
| `revealEase` (API version 10) | `0` | `0`/`1` | the curve of the `revealSeconds` fade: `0` even, `1` ease-in. Not yet run in game. |

- **Send every key your mod decides**, even one equal to the game's value, so a quieter mod does not take it from you.
- **`"unset"` withdraws one key** (API version 6, any part and key): `CMFStylePart(provider, part, key, "unset", 0)` removes your own value, so the next folder's value or the game's applies from the next opening. Use it for an on/off option.
- **Frame rate** ran in game on 2026-10-21: the log showed `frameRate asked=60 now=60`. If the game could not change the rate, CMF would answer `false` and the map would stay at 24; `tweenEveryFrame` `1` still makes tweens smooth.
- **Controller keys** (`padHoldMs`, the crosshair keys) are checked by value only; no launch has used a controller.
- **Log.** Each opening writes `opening ms=N` (from the map's start to its first full pin build) and, with any key set, a line such as `nav frameTimed=1 step=17 world=24 max=100 zoomTimed=0 pad=0 tweens=frame frameRate asked=60 now=60 opening=slide:0.2/0 pins:120@1 ready=420ms`. Each held-key pan writes a line such as `nav pan ms=<held time> ticks=<steps> px=<distance>`; with `zoomOutFit` the map writes `nav zoomOutFit min=0.66 game=1.6`.

An on/off option, checked key by key so the pack still loads on an older CMF:

```
if (CMFHasAbility('navigation', 'zoomTimed'))
{
	text = "unset";
	if (acmeSmoothOn)
	{
		text = "";
	}
	CMFStylePart("modAcmeSmooth", 'navigation', 'frameTimed', text, 1);
	CMFStylePart("modAcmeSmooth", 'navigation', 'zoomTimed', text, 1);
	CMFStylePart("modAcmeSmooth", 'opening', 'pinsDuringSlide', text, 1);
}
```

### Spreading stacked pins (API version 6)

Ran in game on 2026-10-20 with the mouse, through the Map Quest Insight adapter; the controller crosshair has not been checked. Pins that sit on one spot can fan out into a row when the cursor (or, with a controller, the crosshair) reaches them, so each one can be picked. It is a behaviour part, `spread`, set with `CMFStylePart` like `navigation` and `opening`: each key is won on its own by the earliest folder that sets it, and `"unset"` withdraws your own value. With nobody setting `on`, the map behaves exactly as before. Ask first with `CMFHasAbility('spread', '')`.

| Key | Default | Range | What it does |
| --- | --- | --- | --- |
| `on` | `0` | `0`/`1` | `1` turns spreading on. |
| `anyPin` | `0` | `0`/`1` | `0`: only a quest pin opens a row; `1`: any pin does. Any pin on the spot can join either way. |
| `enterRadius` | `20` | `0` to `400` px | how close the cursor must come to a pin's own place to open its row. |
| `stackDistance` | `24` | `0` to `400` px | pins this close to that pin, or to another pin that joins, join it, at the closest zoom; the distance shrinks with zoom, so only pins on the same spot join when zoomed out. The same pins join whichever of them the cursor reaches first. |
| `gap` | `48` | `8` to `400` px | the distance between pins in the row. |
| `maxPins` | `8` | `2` to `16` | the most pins in one row (the ones nearest the stack's middle); a row needs two. |
| `openMs`, `closeMs` | `150`, `120` | `0` to `2000` | how long the row takes to open and to close. |
| `lockRadius` | `24` | `0` to `400` px | the first pick stays selected, also while zooming, until the cursor moves this far against the row. |
| `keepRadius` | `48` | `0` to `400` px | the row stays open while the cursor is within this distance of it. |

When a row opens, CMF selects the pin with the highest `CMFPropertySpreadRank` (id 22, `0` to `1000`, `0` = no preference), and the pin nearest the cursor among equals. The rank is a pin property like ids 10 to 17: `CMFRegister` for a type, `CMFRegisterForTag` for a tag, or `CMFStylePin(provider, dataObject, CMFPropertySpreadRank(), "", rank)` for one pin, where the earliest folder wins. Pins move by an offset from their own place, so their real position, travel and tooltips do not change. The row closes and pins go back on every pin rebuild and filter change. Each opened row writes one log line, such as `panel spread open n=3 rank=7`, and each closing one another, such as `panel spread close n=3 why=cursor drift=0` (`why` is `cursor` when the cursor left the row, `pins` when one of its pins went away or hid; `drift` is how far, in pixels, the furthest pin's own place is from where its world position puts it at the current zoom). While a pin of a row is selected, its larger copy sits on the pin's slot in the row. If an open row's middle moves more than 2 pixels without a zoom, `panel spread moved n= dx= dy=` says by how much.

```
if (CMFHasAbility('spread', ''))
{
	text = "unset";
	if (acmeSpreadOn)
	{
		text = "";
	}
	CMFStylePart("modAcmeSpread", 'spread', 'on', text, 1);
	CMFStylePart("modAcmeSpread", 'spread', 'gap', text, 56);
}
```

### Names only on hover (API version 10)

Some map mods keep the map quiet by showing a pin's name only while the cursor or crosshair is on it. Property `28`, `CMFPropertyHoverName()`, does this for any pin, by every pin, by type, by tag or on one pin, like any pin property. The number holds bits:

- `1`: the pin's label line (a signpost's name, or a pack's level tag) and its tag drawings show only on the pin under the cursor or crosshair.
- `2`: the pin under the cursor or crosshair shows its name on the label line, above its level tag when it has one; pins with no label line today, such as merchants, get one while hovered.
- `3` is both; `0` keeps the pin as the game shows it.

```
if (CMFRequireVersion("modAcmeQuietMap", 10))
{
	CMFRegister("modAcmeQuietMap", CMFPropertyHoverName(), '', '', "", 3);			// every pin
	CMFRegister("modAcmeQuietMap", CMFPropertyHoverName(), 'RoadSign', '', "", 0);	// signposts as the game shows them
}
```

- **Levels.** Target `''` is an every-pin claim; a type claim and a tag claim beat it on their pins, so a type claim of `0` keeps that type as the game shows it. `CMFRegisterForTag` and `CMFStylePin` take property 28 too. The player's marker and the player's own pins are never changed.
- **Who wins.** Names only on hover is its own row under Map behaviour (`Behaviour_HoverNames`).
- **No extra work per frame.** The hovered pin's copy is rebuilt only when the selection changes, as the game already does.
- Ran in game in the CMF 1.4.1 launch (2026-10-24): quest level tags and their plates showed only on the hovered pin, signposts kept their names through a type claim of `0`, and the hovered name stayed inside the screen's edge.

### Drawing on the map itself (API version 6)

Not yet run in game. Drawings so far are tied to screen parts. API version 6 adds the anchor `mapSpace`: the map itself, in world metres, the same numbers pins carry. A drawing on it pans and zooms with the map and always sits below every pin, because the game keeps its pins in their own layer above the map. Ask first with `CMFHasAbility('mapSpace', '')` (and, for a kind or key, `CMFHasAbility('line', 'colors')`, `CMFHasAbility('text', 'listen')`, `CMFHasAbility('rect', 'click')`).

`mapSpace` takes three kinds, and `line` and `movie` take no other anchor:

| Kind | What it draws | Its own keys |
| --- | --- | --- |
| `line` | polylines in world metres, one colour per segment | lists `xs`, `ys` (metres), `starts` (the point where each segment starts; segments are not joined), `modes` (one per segment, an index into `colors`), `colors` (`0xRRGGBB`; a segment without one uses `stroke`); keys `stroke`, `strokeAlpha`, `strokeWidth`, `strokeZoom` (`0`: the same px at every zoom, `1`: scales with the map). Ends and joints are round. |
| `text` | the game's HTML text at `x`, `y` metres, the same size at every zoom (`sizeZoom` `1` scales it with the map) | `text`, `font`, `size`, `color`, `align`, `wrap`, `padding`, and the box keys `fill`, `alpha`, `stroke`, `offsetX`, `offsetY` (screen px) |
| `movie` | anything your own small movie draws | `src`, and any key or list key you document for your movie |

Every `mapSpace` drawing also takes `layer` (`under`: just above the map tiles, below the edge fade, cut off at the map's edge; `over`: above the edge fade and not cut off at the map's edge), `order`, `alpha`, `view` (only `region` shows: the world view and interiors have no world coordinates), `area` (the area name as CMF logs it, such as `AN_NMLandNovigrad`; empty or unset = every area), `preview` (`1`: a copy in the corner overview; `line` and `movie` only), `fadeMs` (fade in over that many ms once per opening, `0` to `5000`), `tab` and `tabLabel` (below), and `listen` and `listenFields` (below). Map-space drawings fade in with the map tiles on their own.

Lists are set with `CMFDrawSetList(provider, id, key, values)` (at most 100000 values; an empty array withdraws the key). CMF sends your map-space drawings to the map on every full map build, after `OnMapReady`, so an `OnMapReady` wrapper is the place to set positions that change. When your drawings change while the map stays open, `CMFMapRefresh()` runs `OnMapReady` again and redraws every drawing without rebuilding the pins, so the selected tab, pan and zoom stay.

```
if (CMFHasAbility('mapSpace', '') && CMFHasAbility('line', 'colors'))
{
	CMFDraw("modAcmeRoute", 'mapSpace', 'acmeRoute', 'line');
	CMFDrawSet("modAcmeRoute", 'acmeRoute', 'layer', "under", 0);
	CMFDrawSet("modAcmeRoute", 'acmeRoute', 'strokeWidth', "", 4);
	CMFDrawSet("modAcmeRoute", 'acmeRoute', 'strokeAlpha', "", 0.9);
	CMFDrawSetList("modAcmeRoute", 'acmeRoute', 'xs', xs);
	CMFDrawSetList("modAcmeRoute", 'acmeRoute', 'ys', ys);
	CMFDrawSetList("modAcmeRoute", 'acmeRoute', 'colors', colors);
}
```

**Data your script already sends (`listen`).** If your script already writes your numbers to a key of the map menu's flash storage (`GetMenuFlashValueStorage().SetFlashObject("acme.route", object)`), keep doing so and tell CMF which drawing reads it: `listen` = that key, and the drawing takes `xs`, `ys`, `starts`, `modes`, `colors` (arrays) and `text` (strings) from the object's fields of the same names. `listenFields` maps other names, `"xs=pointsX,ys=pointsY"`, and joins several text fields with line breaks, `"text=regionText|totalText"`. Every new value redraws the drawing at once; a movie gets the whole object as `data.listen`. Keys starting with `cmf.`, `map.`, `worldmap.global.` or `worldmap.title.` are CMF's and the game's own and are refused, and the map listens to at most 16 keys per opening (the rest log `panel listen refused key= reason=slots`). A value written before the map panel listens never arrives (launch D1, 2026-10-20), and the map starts listening once per opening, after the game's own `OnConfigUI` and after the first map build. So write your value again from an `OnMapListening` wrapper (API version 6): CMF calls it as soon as the map starts listening, with the keys it now listens to joined by `|`:

```
@wrapMethod(CMFCore)
function OnMapListening(menu : CR4MapMenu, keys : string)
{
	wrappedMethod(menu, keys);
	if (menu && StrFindFirst(keys, "acme.route") >= 0)
	{
		AcmeSendRoute(menu);	// your own code that writes "acme.route" again
	}
}
```

A value you write while the map is open arrives at once.

**Your own movie (`movie`).** For a layer you drew with your own code in your own copy of the map file, move that code into a small movie of your own: one AS3 class whose root has a public function `cmfMapSpace(data : Object, map : Object) : Boolean`. Ship it in your own bundle at a path no other mod uses, such as `gameplay\gui_new\swf\acmefog\acmefog_layer.redswf`, and set `src` to `"swf/acmefog/acmefog_layer.swf"`. CMF loads it once per map opening, places it on `mapSpace` with world (0,0) at the movie's origin and one unit per map pixel, and calls `cmfMapSpace` after it loads and again on every map build. `data` holds `id`, `keys`, `text` and `number` (every key you set, as text and as number), `list` (your list keys) and `listen`; `map` holds `mapSize`, `textureSize`, `scale` (map px per metre, `2 x textureSize / mapSize`; y is negated), `area`, `zoom` and, with `preview` `1`, `preview`: a sprite in the corner overview, in map px too. Return `true` when you drew. A movie that fails to load, has no `cmfMapSpace` or throws is dropped for that opening and logged once (`panel movie failed`); the map is unaffected. Your classes load beside CMF's map, and a class name CMF's map also uses resolves to CMF's, so keep your names your own. CMF's own test movie (`source/panel/test-movie/CMFTestMapSpace.as`) is a complete example.

```
// Your script: the movie gets your grid and your settings.
CMFDraw("modAcmeFog", 'mapSpace', 'acmeFogLayer', 'movie');
CMFDrawSet("modAcmeFog", 'acmeFogLayer', 'src', "swf/acmefog/acmefog_layer.swf", 0);
CMFDrawSet("modAcmeFog", 'acmeFogLayer', 'preview', "", 1);
CMFDrawSet("modAcmeFog", 'acmeFogLayer', 'fadeMs', "", 250);
CMFDrawSet("modAcmeFog", 'acmeFogLayer', 'cellSize', "", 6.7);
CMFDrawSetList("modAcmeFog", 'acmeFogLayer', 'grid', grid);
```

**A drawing for one filter tab (`tab`, `tabLabel`).** Any drawing (on `mapSpace` or on a part) with `tab` shows only while the legend tab of that id is selected. If no pin makes that tab, CMF adds it last, labelled with `tabLabel` (your own text, or a `[[key]]` from your strings), and while it is selected the map shows no pins but Geralt's marker. A tab that pins already make keeps its pins and its own label.

**Text boxes, hover and clicks.** `text` drawings also go on any part or drawing, sized to their text plus `padding`, with the box keys painting their own box behind the words. `wrap` says what a line wider than its box does: `none` keeps one line, which runs past both edges of the box, centred; `wrap` breaks the words at the box's width (any box, `widthShare` too) and the box takes the wrapped height; `fit` keeps one line and grows the box to it. Unset, a box with a pixel `width` wraps and any other box keeps one line. `above` (px) stacks a drawing that far above its anchor's top, at its own height, so boxes can stack upward from `legendTab`. On a part, `above` measures from the top of the part together with every box, plate or frame drawn on it that does not stack itself, from any pack or theme, and on `legendTab` and `legendRow` also every box drawn on the `legend` around them, so a stack clears a theme's frame around the tab without knowing the theme. A drawing on a screen part (not `mapEdge`, `pinLabel` or `pinName`) with `click` `1` or more takes the mouse (every other drawing stays transparent to it), shows its hover look while the pointer is over it (`fillHover`, `alphaHover`, `strokeHover`, `strokeAlphaHover`, `strokeWidthHover` for its box, `colorHover` for its words) and reports a left click to the drawing's owner through the hook `CMFCore.OnDrawingClicked`, in the same shape as `OnPinClicked`, with `input` `"click"` and `value` = your `click` number. Mouse only; clicks on `mapSpace` drawings are not taken in this version.

```
@wrapMethod(CMFCore)
function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
{
	if (provider != "modAcmeRoute")
	{
		return wrappedMethod(menu, provider, id, input, value);
	}
	if (value == 1)
	{
		menu.AcmeRouteErase();
	}
	return true;
}
```

Log lines: `space sent area= entries= values=`, `panel space drawn area= drawings= lines= points= texts= movies= ms=`, `panel movie loaded`, `panel movie drawn id= ok=`, `listen ready keys=`, `panel listen arrived key=`, `panel listen refused key=`, `panel space check ...` (about a second after each draw: the layers' colour and visibility, each drawing's box on screen, a line's colours, a text's width, a movie's state), `panel drawing click id= value=`, `drawing click provider= id= value=` (and `reason=nohandler` when nobody answers). Not in this version: the map waiting for a drawing before its fade-in (`holdMap`), simplifying long lines by zoom, clicks on `mapSpace` drawings, and children tied to a `mapSpace` drawing.

### Players' choices: who wins each feature (API version 8)

From CMF 1.2.0 a player can choose which mod wins each feature of the map, and each piece of most features: pin icons from one mod, pin colours from another, the map painting of one region from a third. The player chooses in CMF's optional in-game menu add-on (`modCMFInGameMenu`, under Options > Mods > Conjunction Map Framework) or in the settings file; [Settings file keys](settings-file-keys.md) lists every feature and piece with its file key and its menu row. Each choice is a mod, Vanilla (the game's own look for that piece) or Automatic.

Your script does not change. Keep registering as before: the player's choices decide between the claims mods have sent, they never add or change a claim. With nothing chosen, CMF 1.2.0 picks the winners exactly as 1.1.0 did, and packs made for earlier versions need no change.

**The order of authority.** For each piece CMF asks these levels in turn. The first one that is not Automatic decides; the menu's Status page and the log name each level as shown in brackets:

1. the Advanced in-game choice for the piece (Advanced),
2. the Basic in-game choice for its feature (Basic),
3. the in-game Mod order (Mod order),
4. the Advanced file choice, `CMFFile_<Feature>_<Piece>` (Advanced file),
5. the Basic file choice, `CMFFile_<Feature>` (Basic file),
6. the file Mod order, `CMFProviderOrder1` to `CMFProviderOrder8` (File order),
7. CMF's default order, folder names sorted (Default).

When two mods claim the same thing, a level decides between them only when it names one of them; a level that names another mod, Vanilla or nothing passes the question to the next level. A mod chosen for a piece wins every pin it has something for. On a pin where it has nothing, the next mod in order decides, or the game's own look shows when the player sets the General row "If the chosen mod has nothing for a pin" (or `CMFFile_Fallthrough`) to Vanilla. In-game choices come only from the menu add-on: without it every in-game level reads Automatic, and values a removed add-on left behind steer nothing.

**Looks and behaviours are separate choices (API version 10).** From CMF 1.4.1 a player can take one mod's look and another mod's behaviour: pin icons from one mod and the way stacked pins spread out from another. Your script does not change: send behaviours with the same calls as before, and CMF files each key under a look row or a behaviour row by itself. The Basic page gains the row **Map behaviour**, and "Pin size and spreading" becomes **Pin size**. Advanced > Map movement now has Map area, **Pan and zoom feel**, **Zoom out to the whole region**, **Controller crosshair**, Opening and closing, Opening view and **Fill wide screens**, and the new Advanced page **Map behaviour** has Stacked pins spread out, Which pin leads a spread, Label place and hiding, Info box moves out of the way, Info box size and scrolling, and Names only on hover. What moved:

- the `spread` part and property `22` (spreading and which pin leads) answer Map behaviour, not Pin size;
- properties `11` and `13` and the `pinLabel` keys `rise`, `riseOffset`, `riseTracked`, `riseOffsetTracked` answer Label place and hiding, and the label's font stays with its look;
- the tooltip's `clear` keys, and from API version 11 its `x` and `y`, answer Info box moves out of the way, and property `14` answers Info box size and scrolling; the box's fonts, colours and plates stay on the Map look's Info box row;
- the `navigation` keys `zoomOutFit` and `edgeOvershoot` answer Zoom out to the whole region, and the controller crosshair keys (`crosshairRoam`, the `safe` keys, `snapSeconds`, `centerSeconds`, `padHoldMs`) answer Controller crosshair;
- the `map` part's `backdrop` colour is paint, so it answers the Map look's frames row.

On a look part, the look and the behaviour each have one owner, decided among the mods that sent a key of that kind: a mod that sends only the tooltip's `clear` keys never takes the tooltip's fonts from another mod. A saved `CMFFile_Size` choice keeps choosing pin size and no longer chooses spreading. [Settings file keys](settings-file-keys.md) lists every row, and the theme page's tables say which row decides each key. `python tools/cmf_pack.py check` prints the row for each key your pack sends.

**Added together: hidden pins and drawings.** Hide claims (with greyed pins and filter-tab hides) and drawings are never decided between mods: every mod's applies. Their choices work differently. Automatic keeps every mod's, Vanilla keeps none, a chosen mod keeps only that mod's, and three Ignore slots (`Hidden_Ignore1` to `3`, `Drawings_Ignore1` to `3`) each leave one mod out. When any in-game row of one of these two features is set, the in-game rows replace the file's for that feature; they are not added to them.

**Your mod's name in the menu.** The menu lists mods by name. Without a name of your own it tidies your folder name: it drops the `mod` prefix, then CMF's own `CMFAdapter` or `CMF` prefix (so an adapter reads as the mod it adapts), then leading digits and underscores; underscores become spaces, words split where a small letter meets a capital, and each word starts with a capital. `modExampleIconPack` reads "Example Icon Pack", `modCMFAdapterSomeMod` reads "Some Mod". To choose the name yourself, call `CMFSetProviderName` once, where you register your claims:

```
if (CMFRequireVersion("modAcmeIcons", 8))
{
	CMFSetProviderName("modAcmeIcons", "Acme Icons");
}
```

A call to a function CMF does not have stops the game at the script compile screen, which `CMFRequireVersion` cannot prevent, so calling `CMFSetProviderName` means your pack needs CMF 1.2.0 or later. If your pack must also load on an older CMF, leave the call out and let the menu tidy your folder name.

**When choices are read.** CMF reads the choices each time it prepares its winners. `CMFChoicesChanged()` makes it prepare them again before the next lookup, so the world map shows the new winners the next time it opens and the minimap add-on follows on its next frame. The menu add-on calls it when a row changes; a pack does not need it. Some offers are known only after the world map has been opened once in a session, because CMF learns them as the pins are drawn.

Settings values hold one word each and never a comma: the game ends a value at its first comma.

### World overview pictures (API version 9)

API version 9 is CMF 1.3.0. Everything in this section and the three after it ran in game in the CMF 1.3.0 launch (2026-10-23), with test packs and the Ink and Iron and Annoying Map adapters, except the overview's quest marker, which no pack drew there. Controller button pictures were seen only through a test copy of the map, never with a real controller.

The world overview (Space on the region map) shows a painting of the whole world, a crest on each region, and a player and quest marker on the regions they apply to. From API version 9 a pack can give its own picture for each of these slots. CMF's map draws the pack's picture over the game's at run time, in the game's place and size, and keeps the game's animation; the game's picture stays until the pack's has loaded, so a slow or failed load never shows a blank.

| Slot | Call | Property id, target | The game's picture |
| --- | --- | --- | --- |
| The painting | `CMFRegisterWorldPainting(provider, url)`, or `CMFRegisterWorldPaintingTiles(provider, url, columns, rows)` | `24` `CMFPropertyWorldPainting()`, `'painting'` | 2100 x 1380 px; any size with the same 105:69 shape works |
| One region's crest | `CMFRegisterWorldCrest(provider, region, url)` | `25` `CMFPropertyWorldCrest()`, the region's name (below) | the sizes below |
| The player or quest marker | `CMFRegisterWorldMarker(provider, marker, url)` | `27` `CMFPropertyWorldMarker()`, `'player'` or `'quest'` | |

```
if (CMFRequireVersion("modAcmeWorld", 9))
{
	CMFRegisterWorldPainting("modAcmeWorld", "img://icons/modacmeworld/world/painting.png");
	CMFRegisterWorldCrest("modAcmeWorld", 'skellige', "img://icons/modacmeworld/world/crest_skellige.png");
	CMFRegisterWorldMarker("modAcmeWorld", 'player', "img://icons/modacmeworld/world/marker_player.png");
}
```

The crests, by the names the overview itself uses:

| Region (name to use) | Crest | Size in the game, px |
| --- | --- | --- |
| `kaer_morhen` | the wolf medallion | 135 x 130 |
| `skellige` | the longship | 135 x 116 |
| `novigrad` | the city arms | 135 x 116 |
| `no_mans_land` | Velen's tree and lily | 135 x 116 |
| `prolog_village` | White Orchard's tree | 135 x 116 |
| `wyzima_castle` | the Nilfgaardian sun | 135 x 116 |
| `bob` | Toussaint's knight | 135 x 116 |

A region another mod adds goes by its area name; CMF keeps such a claim, because that mod may load later.

- **Art.** Put these pictures in your pack's `art/world/` folder. Unlike pin icons they may have any shape, each side a multiple of 4 up to 4096 px (BC3 stores 4 x 4 blocks), so draw a 135 x 130 crest as 136 x 132: the map stretches every picture to the game's own rectangle. Keep transparency in crests and markers. The pack tool cooks them into your `texture.cache`; an image in `art/world/crest_skellige.png` of `modAcmeWorld` is `img://icons/modacmeworld/world/crest_skellige.png`.
- **Tiles.** A painting larger than one texture goes in `columns` x `rows` tiles, each 1 to 8; the path holds `{x}` and `{y}`, which the map replaces with each tile's column and row counted from 0: `CMFRegisterWorldPaintingTiles("modAcmeWorld", "img://icons/modacmeworld/world/tile{x}x{y}.png", 2, 2)` uses `tile0x0.png` to `tile1x1.png`. The map shows the painting once every tile has loaded. Generic form: property 24 with `number` = columns x 10 + rows (`0` for one picture).
- **The hover copy too.** Moving onto a region lights it up by drawing a second copy of the painting inside its outline; CMF draws your painting there as well. Crests and markers keep the game's grow and brighten animation.
- **Who wins.** One winner per slot: the painting, and each region's crest and each marker on its own. The order is the one every claim follows (section "Players' choices"): the in-game menu's **World overview** row (`Painting_World`) for the painting and its **Region crests and markers** row (`Painting_Crests`) for crests and markers, then the Painting row, the Mod order, the settings file and folder order. A mod chosen on a row that has nothing for a slot passes that slot to the next mod. **Vanilla** on either row (or on Painting) shows the game's own pictures. Adapters claim under the adapted mod's folder name, as always.
- **Withdraw** with an empty path (`""`), or everything with `CMFReleaseProvider`.
- **The log** shows `world sent painting= crests= markers= buttons=` once per map opening, then per slot `world picture slot=painting provider= size=WxH` (or `slot=crest:skellige`, `slot=marker:player`), or `world picture failed slot= provider= url=` when the map could not load it.
- **What a pack cannot change** (each needs a change to the map file itself): the places of regions, crests and labels; the overview's scroll limits; the region outlines that light up on hover, so a painting must keep the game's geography and layout; the thin gradient strip; the region names' font. A region the game hides or disables stays hidden. CMF never swaps the textures inside its own map file; it covers the game's pictures with yours.

### Controller button pictures (API version 9)

With a controller, every button prompt on the map (the hint row at the bottom, the custom marker panel and the other button spots) shows a picture of the button. From API version 9 a pack can give its own picture per button, per controller family. The map draws it in the game's picture's place and size; the hold ring and the prompt's width stay the game's, so the text after the button does not move. Buttons you give no picture keep the game's.

```
if (CMFRequireVersion("modAcmeButtons", 9))
{
	CMFRegisterButtonPicture("modAcmeButtons", 'xbox', "gamepad_Y", "img://icons/modacmebuttons/buttons/xbox_gamepad_y.png");
}
```

- **Families:** `xbox`, `ps4` (PlayStation 4), `ps5`, `steam` (Steam Deck) and `switch`. The map uses the family of the controller in use.
- **Button names** (the map's own names, written in Xbox terms; each family draws its own picture for the same name; pass the button as text in double quotes, since a name literal in single quotes cannot hold a dash): `gamepad_X`, `enter-gamepad_A`, `escape-gamepad_B`, `gamepad_Y`, `gamepad_L1`, `gamepad_R1`, `gamepad_L2`, `gamepad_R2`, `gamepad_L3`, `gamepad_R3`, `gamepad_RTLT`, `gamepad_RBLB`, `dpad_up`, `double_dpad_up`, `dpad_down`, `dpad_right`, `dpad_left`, `gamepad_dpad_lr`, `start`, `back`, `gamepad_R_Tab`, `gamepad_R_Scroll`, `gamepad_L_Hold`, `gamepad_R_Hold`, `gamepad_L_Tab`, `gamepad_L_Scroll`, `gamepad_R_down`, `gamepad_dpad_up_down`, `gamepad_dpad_all`. `steam` has all but the last two. The game's "swap accept and cancel" option is applied before the picture is chosen, so a pack never handles it. A family or name the map has no picture for is refused and logged (`button picture unknown family= button= provider=`).
- **Sizes.** 64 x 64 px is the game's button box, 128 x 128 the cap. Two pictures are wider: `gamepad_RTLT` and `gamepad_RBLB` show two buttons side by side, about 100 x 64. Button pictures go in `art/buttons/`, where any shape up to 128 px is allowed; the map stretches each to the rectangle the game's picture covers.
- **Who wins.** Each button of each family on its own. Button pictures belong to the existing **Hints** row under Look (`Look_Hints`), so a player who picks a mod's hints gets its buttons too, and Vanilla there shows the game's.
- **The log:** `button picture family= button= provider= size=WxH`, or `button picture failed family= button= provider= url=`.
- **From two sheets: the sheet cutter.** The map draws its button pictures from cut-outs of two texture sheets in its own file, `_i49` (988 x 544) and the lower rows of `_i1` (1024 x 1020). If your art is a re-drawn copy of those sheets, `tools/cmf_button_sheet.py` cuts it into one picture per button with the matching lines:

  ```
  python tools/cmf_button_sheet.py cut --i49 my_i49.png --i1 my_i1.png --pack modAcmeButtons --out cut
  ```

  It writes `cut/art/buttons/<family>_<button>.png` for every family (or only those named with `--family xbox`) and `cut/register.ws` with one `CMFRegisterButtonPicture` line per picture. Copy the `buttons` folder into your pack's `art/` and the lines into your start-up wrapper. The cut-out places come from `tools/cmf_button_sheets.json`, which records geometry only, read once from the game's map file (`python tools/cmf_button_sheet.py map` on its FFDec XML); the tool never ships any art itself, it only cuts what you give it.
- **Cannot change:** keyboard and mouse prompts (keys are text with a plate, styled by the `keyCap` theme part), button pictures outside the map, and which button does what or the hint texts.

### The map's view (API version 9)

CMF's map can tell your script where the player left the region map, and lets you choose the view a region map opens with. Both work only with CMF's map, so they never run when another map file loaded instead.

**Where the player left it: `OnMapView`.** Wrap this `CMFCore` hook and always call `wrappedMethod` with every argument:

```
@wrapMethod(CMFCore)
function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float, zoom : float, reason : name)
{
	wrappedMethod(menu, area, x, y, worldX, worldY, zoom, reason);
	// keep x, y and zoom for area
}
```

- `area` is the map area shown, the name the `CMF background area=` line logs (for example `'AN_NMLandNovigrad'`).
- `x`, `y` are the map's place in the units the game's `setDefaultPosition` takes; `worldX`, `worldY` the centre of the visible area in world metres (the units map-space drawings use); `zoom` the map's scale, in the units of the game's `SetMapZooms`.
- `reason` is `'still'` when the player panned or zoomed and the map then stayed still for a quarter of a second, `'region'` when the map switches to another region (it reports the region being left, with that region's name and last view, so a pan just before the switch is not lost), and `'close'` when the map closes. CMF logs each report: `map view area= reason= x= y= zoom=`.

**The view a region opens with: `OnMapOpening` and `CMFSetOpeningView`.** CMF calls the hook `OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)` each time its map shows a region map, at the opening and on every region switch, after the game's script has sent that region's zoom limits. Inside it you may send the limits again through the game's own calls, and call `CMFSetOpeningView`:

```
@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	wrappedMethod(menu, area, mapContext);
	CMFSetOpeningView("modAcmeView", area, keptX, keptY, keptZoom, false);
}
```

- `CMFSetOpeningView(provider : string, area : name, x : float, y : float, zoom : float, keepPlace : bool) : bool` sets your view for one area, or for every area with `''`. `zoom` is clamped to the zoom limits in force when the map applies it (so limits you send inside `OnMapOpening` count); `keepPlace` `true` keeps the map's own place and sets only the zoom.
- `CMFSetOpeningWorld(provider : string, area : name, worldX : float, worldY : float, zoom : float) : bool` sets the same view with its place in world coordinates, the units of a pin's position (for example `thePlayer.GetWorldPosition()`'s `X` and `Y`): the map opens centred on that spot. `zoom` works as above; `0` or less keeps the game's zoom. Use it to open on Geralt when a mod hides his marker (the game then falls back to the region's default spot), or on any place of your own:

```
@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	var spot : Vector;
	wrappedMethod(menu, area, mapContext);
	if (menu && menu.IsCurrentAreaShown())
	{
		spot = thePlayer.GetWorldPosition();
		CMFSetOpeningWorld("modAcmeView", area, spot.X, spot.Y, 0);
	}
	else
	{
		CMFSetOpeningView("modAcmeView", area, 0, 0, 0, true);
	}
}
```

- **Replace and withdraw.** A later call by the same provider for the same area replaces the earlier one. `keepPlace` `true` with a zoom of `0` or less withdraws your view for that area, since nothing is left to set. `CMFSetOpeningWorld` and `CMFSetOpeningView` replace each other, so `CMFSetOpeningView(provider, area, 0, 0, 0, true)` withdraws either.
- **Who wins.** For the area shown, a view for that area beats an every-area view; between mods the menu's **Opening view** row (`Movement_View`, under the Movement feature) decides, then the Mod order, the settings file and folder order. Vanilla on the row (or on Movement) keeps the game's view.
- **When it applies.** Only when the map opened on its usual place (the player, the default position or the middle) and the player has not moved it yet. An opening on a particular spot, such as a lonely fast-travel pin or "show on map" from the quest list, keeps the game's whole view, zoom included; a pack cannot change that in API version 9. Nothing waits for the view: the map opens as fast as before.
- **The log** shows one line per region shown: `map opening area= context= view=<provider or none> x= y= zoom= keep= world=` (`world=1` for a `CMFSetOpeningWorld` view).

### Wide and tall screens (API version 10)

From CMF 1.4.1 the map fills a screen that is not 16:9: wider (21:9, 32:9) or taller (16:10, 4:3). Nothing is scaled: pins, labels, icons and panels keep their size, and a wider screen shows more map. The top edge never moves, because the game's menu bar sits above the map; the map grows left, right and down. On a 16:9 screen nothing changes at all.

**Send numbers in 1920 x 1080 units; CMF moves them on wide and tall screens.** Every place, edge and bound your pack sends today stays right without a second set of numbers. CMF moves an x number below 960 with the left side and one of 960 or more with the right side, and a y number above 540 with the bottom:

| Number | Moves with |
| --- | --- |
| `screenLeft`, `screenRight`, `screenTop`, `screenBottom` on a drawing tied to `screen` | the screen's edges, so a frame or fade still runs edge to edge |
| the same keys on a drawing tied to a part or another drawing | that part's panel, so the drawing stays with it |
| bounds: `minLeft`, `maxRight`, `minTop`, `maxBottom`, the tooltip's `clearLeft`, `clearTop`, `clearRight`, `clearBottom`, the navigation `safe` keys | the screen's edges |
| the `title`'s `screenX`, `screenY`, `x`, `y` and the `hints`' `x`, `y` | that part's panel |
| the `map`'s `top` | nothing |
| the `map`'s `bottom` of 1080 or more | the bottom edge |
| drawings on `mapSpace`, pin labels and pin buttons | nothing; they live on the map or on pins |

The drawing key `wideAnchor` overrides this for one drawing: `edges` (move with the screen's edges), `panels` (move with the panels) or `centre` (stay in the middle 16:9 area, for a frame meant to surround it). `CMFHasAbility('rect', 'wideAnchor')` tells you whether the installed CMF has it.

**The `wide` part** holds the layout's own choices, won key by key like `navigation`:

| Key | Values | Without any mod | What it does |
| --- | --- | --- | --- |
| `fill` | `0`/`1` | `1` | `1`: the map fills the whole screen. `0`: the 16:9 map, centred, with dark sides |
| `panels` | `0` to `1` | `1` | how far the side panels (and on a taller screen the bottom panels) move from their 16:9 place to the screen's edge |
| `maxRatio` | `0`, or `1.78` to `4` | `0` (no limit) | the widest shape the map fills; on a wider screen the rest shows the backing, so a 32:9 player can keep a 21:9 map |
| `world` | `0`/`1` | `0` | `1`: the world overview grows to the screen's width, cropping top and bottom; `0` keeps it centred at its size |

```
if (CMFHasAbility('wide', 'fill'))
{
	CMFStylePart("modAcmeLayout", 'wide', 'panels', "", 0.5);	// side panels halfway to the edges
}
```

- **Who wins.** Fill wide screens (`Movement_Wide`, under Map movement). Vanilla there shows the game's centred 16:9 map. `fill` `1` without any mod is CMF's own layout, not a claim, so Automatic with no `wide` keys fills the screen.
- **The screen's shape.** `CMFScreenWidth()` and `CMFScreenHeight()` give the screen the map last opened on, in map units (`2580` x `1080` on a 3440 x 1440 monitor), and `0` before the first opening, for example to send `wide` keys only on very wide screens. No pack needs them for a correct layout.
- **The log** shows `wide screen=WxH window=WxH left= right= bottom= unstretch= panels= maxRatio= world=` once per opening on a wide or tall screen, or `wide off (16:9)` and `wide off (fill 0)`.
- **Speed.** The layout runs once when the map opens; nothing runs per frame, and the map opens as fast as before.
- **Tested** in the CMF 1.4.1 launch (2026-10-24) at 16:9, at 16:10 (1920 x 1200) and at 21:9 (3440 x 1440, `wide screen=2580x1080`): the map filled the screen with square pixels, the panels sat at the edges, `fill` `0` and Vanilla gave the centred 16:9 map, the overview stayed centred, and the info box and hovered names stayed on screen. Not yet run in game: 32:9 and 4:3 screens, `maxRatio` and `world` `1`.
- CMF changes only its own map; other menus and the HUD are not part of this.

### Changing one pin (API version 11)

API version 11 lets a pack change one pin, such as a single signpost, as fully as a pack that ships its own map file. Every claim below is new in API version 11, is checked statically, and has not run in game yet.

**Finding the pin.** Put `CMFLogPins=true` under `[CMFSettings]` in `dx12user.settings` and open the map. For every pin the map shows, once per map area, the script log gets a line such as `CMF pin list area=novigrad type=RoadSign kind=RoadSign filteredType=RoadSign tag=<the pin's tag> id=123456 label=... x=... y=...`. `tag` is what `CMFRegisterForTag` takes; `x` and `y` are what `CMFRegisterForPlace` takes. `kind` is the pin's real type when the map shows it as a "?" or greyed. Turn the key off again when you are done. A test pack of your own can call `CMFSetLogPins(true)` at game start instead, which needs no settings line; never ship a pack with it on. With the log on, CMF also writes up to 200 lines per area on what it changed in info boxes (`CMF pin info add`) and legend rows (`CMF pin legend row`).

**Which claim wins on a pin.** The most specific level: one pin object (`CMFStylePin`), then a tag (`CMFRegisterForTag`), then a place (`CMFRegisterForPlace`), then the exact level variant type (`'RoadSign_2'`), then the type (`'RoadSign'`), then every pin (`''`). Within one level the earlier folder wins, as everywhere else.

What a single pin can now take:

- **Colour by tag.** `CMFRegisterForTag` takes property `3`, so one signpost can be tinted.
- **Frames at every level.** An icon claim can be `"frame:<label>"` for a type, a tag, a place or one pin.
- **Art while undiscovered or completed.** Property `29` is the art a pin shows while it is an undiscovered "?", and `30` while it is completed and greyed. Target the pin's real type (`'RoadSign'`, not `'NotDiscoveredPOI'`), a tag, a place or one pin. Property `1` still never applies to those two states, so an ordinary icon pack cannot spoil a "?".
- **The info box title and text.** Property `18` is the title and `19` the text, in HTML. Number `0` (`CMFInfoReplace()`) replaces the game's words; the earliest folder wins. Number `1` (`CMFInfoAdd()`) adds lines below them; every add applies, earlier folder first. The player's Info box text row (Map look) decides: Automatic applies them all, and picking one mod applies only that mod's.
- **The info box height** (`14`) for a type, a tag, a place or one pin; the every-pin claim stays the fallback.
- **Level variants.** A claim on `'RoadSign_2'` beats a claim on `'RoadSign'` for those pins only.
- **A pin with no tag.** `CMFRegisterForPlace` reaches the pin of that type within 2 metres of the place, in every map context. Use it for pins other mods push with plain numbers. Its claims sit at level `CMFLevelPlace()` (`3`); a tag claim still beats them, and they beat a type claim.
- **Geralt's arrow and the player's own markers.** Icon (`1`), colour (`3`) and size (`10`) claims on exactly `'Player'` or `'User1'` to `'User7'` restyle them. Every-pin and tag claims still never touch them.
- **The game's own legend rows.** Legend row (`6`) and row name (`7`) claims now move and rename the game's own rows too; quest rows keep their own rule. Property `37` with a tab's name hides that whole filter tab; All is never hidden.

```
if (CMFRequireVersion("modAcmeIcons", 11))
{
	CMFRegisterForTag("modAcmeIcons", 3, 'your_signpost_tag', '', "", 16744448);
	CMFRegisterForTag("modAcmeIcons", 29, 'your_signpost_tag', '', "img://icons/modacmeicons/gate_unknown.png", 0);
	CMFRegister("modAcmeIcons", 19, 'RoadSign', '', "<font color='#9fd'>Acme: travel from here</font>", 1);
	CMFRegister("modAcmeIcons", 1, 'Player', '', "img://icons/modacmeicons/arrow.png", 0);
}
```

### Choice-only claims (API version 9)

Some pictures should show only when the player asks for them, for example art that matches an optional file of your mod that a script cannot detect. `CMFRegisterChoiceOnly(provider : string, choiceKey : string) : bool` makes one choice choice-only for your mod: your claims, theme part styles and opening views for that piece (or for every piece of a feature, when you give a feature key) are skipped unless the player picks your mod for that piece or its feature, on the in-game menu or in the settings file.

```
if (CMFRequireVersion("modAcmeWorld", 9))
{
	CMFRegisterChoiceOnly("modAcmeWorld", "Painting_Crests");
	CMFRegisterWorldCrest("modAcmeWorld", 'skellige', "img://icons/modacmeworld/world/crest_skellige.png");
}
```

- The key is a feature or piece key from [Settings file keys](settings-file-keys.md), such as `"Painting"` or `"Painting_Crests"`. An unknown key returns `false` and logs `choice only rejected provider= key= reason=key`; a known one logs `choice only provider= key=` once.
- **Picked means** the Advanced or Basic in-game row, or `CMFFile_<Feature>_<Piece>` or `CMFFile_<Feature>` in the settings file, names your mod. Automatic, the Mod order and folder order never pick a choice-only claim.
- The menu still lists your mod on that row, so players can pick it. Your provider line in the log adds `choiceonly=<n>` with the number of claims it skipped.

## 6. Choosing pin types

[`pin-types.md`](pin-types.md) lists every name the 5.01 world map uses, generated from the map itself, with a column saying whether a claim on it does anything in API version 1. Things worth knowing before you choose:

- **Good first targets:** notice boards, signposts, merchants and crafting stations, Places of Power and the points-of-interest family.
- **Quest pins share one legend row.** Every quest pin is listed in a single "quest" row, so if you give quest types different icons, the row shows whichever quest pin the map adds first. Give every quest type you change the same legend image with `CMFRegisterLegendIcon`. The pins of the quest you are following stay gold whatever tint you register, because gold means "the quest you are following"; `QuestObjectiveOther` (untracked objectives) is the usual target for quest tints.
- **`NotDiscoveredPOI`** is the "?" on every undiscovered place. A claim on it changes all of them.
- **`Herb`** has no legend row, and its tag is the herb kind, so a tag claim changes every pin of that herb.
- **Pins other mods add themselves** take type-level icons, legend icons and tints by their type name too. From API version 4, tag claims reach such a pin when the mod that pushes it sets the pin's `id` to `NameToFlashUInt(tag)`, as the game does for its own pins; section 12 shows both sides. Witcher Gear Map and Gwent Players Map give their pins plain numeric ids, so their pins are reachable by type, or one by one in an `OnPinReady` wrapper, but not by tag. Not yet run in game.
- **Not reachable in API version 1:** the player arrow (`Player`) and player-placed pins (`User1` to `User7`). From API version 6, click claims reach player-placed pins (section 5, "Pin clicks"). From API version 9, a hide claim that names `'Player'` hides the player arrow (section 5, "Hiding pins"). From API version 11, icon, colour and size claims on exactly those types restyle them (section 5, "Changing one pin").
- **Finding a tag** for `CMFRegisterIconForTag`: register a type-level icon on that type first, open the map, and read the `CMF pin type=<type> tag=<tag>` lines in the script log (section 8). CMF logs up to 64 distinct type and tag pairs, and only for types that have a type-level icon. From API version 11, `CMFLogPins=true` under `[CMFSettings]` logs every pin the map shows instead, with no limit (section 5, "Changing one pin").

**Claim diagnostics.** Existing author-facing log lines retain their format. Actual withdrawal adds `CMF withdrawn provider=... property=... level=... type=... tag=... context=...` through the existing claim reporter; an absent slot emits no withdrawal line. Inspect compile errors, `rejected`, the provider `claims=` counts and the withdrawal line separately.

## 7. Check and build

```
python tools/cmf_pack.py check path/to/modAcmeIcons
python tools/cmf_pack.py build path/to/modAcmeIcons --out path/to/new-folder
python tools/cmf_pack.py skeleton path/to/modAcmeIcons
```

`check` reports problems and builds nothing. `build` runs the same checks and, if there are no errors, writes:

```
new-folder/
  pack-build.json                     SHA-256 of every file, the image paths and every claim
  Mods/modAcmeIcons/
    README.txt
    content/texture.cache             your images, cooked
    content/scripts/local/modacmeicons_cmf.ws
```

`skeleton` prints a starter script: an image named after a pin type becomes a `CMFRegisterIcon` line for that type, `<type>_legend.png` becomes a `CMFRegisterLegendIcon` line, and other images become commented lines for you to finish. Names match when they are equal ignoring capitals and `_` (`notice_board_full.png` matches `NoticeBoardFull`). It always ends with one commented `CMFRegisterTint` line to copy for each type you want to tint.

**Errors** stop the build: a folder name or provider id that breaks section 3, an image that breaks the size or name rules, an image path with no image in `art/`, a tint written in hexadecimal or out of range, an unknown `CMF...` call, a `CMF`-prefixed function, a keyword used as a variable, CRLF or non-ASCII text, writing CMF's pin fields, and any file that does not belong in an icon pack (a `blob0.bundle`, a map panel, a `texture.cache` of your own).

**Warnings** do not stop it, but read them: a pin type that is not in the list or does nothing in API version 1, quest types with different legend images, the same claim made twice, an image no call uses, an image path outside your own cache, non-transparent edges, and colours the encoder could not keep.

## 8. Install and test

1. Copy the `Mods` folder from your build into the game folder (next to `bin` and `content`).
2. Start the game. The first start after any script change recompiles scripts.
   - If the compile screen names `CMFRegisterIcon` or another `CMF...` call as unknown, CMF is not installed, or is older than your pack needs.
3. Load a save and open the world map. Your pins and legend rows show your art.
4. Read the script log. When script logging is on, the game writes it to `Documents\The Witcher 3\scriptslog.txt`. CMF's lines:

| Line | Meaning |
| --- | --- |
| `CMF provider=modAcmeIcons claims=3 won=3 shadowed=0` | Your pack is loaded; every claim won. Each register call is one claim. This is the "is my pack working?" line. |
| `CMF shadowed provider=modAcmeIcons ...` | Another pack won that type (its folder name sorts first). |
| `CMF rejected provider=modAcmeIcons ... reason=empty` | An empty type, tag or image path. `reason=unknown`: a property id this CMF does not have; `reason=context`: a map context on a property other than 5 and 9; `reason=range` (API version 4): a size, label place or box height out of range; `reason=text` (API version 4): a label hide or tab list CMF cannot read; `reason=level`: a tag claim for a property that has none. |
| `CMF art failed url=img://icons/modacmeicons/x.png provider=modAcmeIcons` | The map could not load that image, so the pin or legend row kept its stock icon. Logged once per path per session. |
| `CMF version provider=modAcmeIcons needs=2 have=1` | Your `CMFRequireVersion` asked for a newer CMF. |
| `CMF pin type=Innkeeper tag=...` | A pin of a type you gave an icon, with its tag (section 6). |

| What you see | Likely cause |
| --- | --- |
| A pin keeps its stock icon | The image path does not match an image in your cache (spelling, capitals, folder name): look for `CMF art failed`. Or another pack won (`shadowed`). |
| Pins changed but the legend row did not, or the reverse | You registered only a legend icon, or the row is shared (quest pins). |
| Nothing changed and no `CMF provider=` line | The script did not run: check the wrapper, and that the folder is in `Mods`. |
| The tint looks wrong | Tint multiplies: dark art stays dark, and coloured art mixes with the tint. |

## 9. Ship it

Archive layout, the same as Map Quest Insight, Witcher Gear Map and Fog of War:

```
Mods/
  modAcmeIcons/
    README.txt
    content/texture.cache
    content/scripts/local/modacmeicons_cmf.ws
```

Ship nothing else in `content/`: no `blob0.bundle`, no map panel and no copy of any CMF file. Start your README from [`pack-readme-template.txt`](pack-readme-template.txt). The tool only warns when it is missing, but players need it. Keep the template's sections, give each release a new version number there, and state:

- **Requires Conjunction Map Framework version 1 or later.**
- **Install:** extract into the game folder, or install with a mod manager.
- **Uninstall: remove this pack before removing CMF.** If CMF is removed first, the game stops at the script compile screen until the pack is removed too.
- Which pin types the pack changes, so players can predict conflicts with other packs.
- That the pack writes nothing into saves; removing it restores the stock icons.

### Packs with settings or text

A plain icon pack has no menu and no text, because it only re-skins types whose names come from the game. If yours has an options page:

- Put your page under CMF's shared node, `Mods.cmf_menu.<your pack slug>`, in your own `bin/config/r4game/user_config_matrix/pc/<your folder>.xml`. CMF provides the title of the "Conjunction Map Framework" entry under Options > Mods, which appears once a pack puts a page in it; never ship `panel_cmf_menu` or `panel_Mods`.
- Ship your page and row names in your own `content/<lang>.w3strings`, in your own block of 10,000 string IDs, with every key prefixed by your slug. Never use CMF's block (2000200000 to 2000209999).
- Read your setting in your `OnGameStarted` wrapper and again in a `CR4MapMenu.OnConfigUI` wrapper before calling the wrapped method, then register or `CMFReleaseProvider`. Registering is idempotent, so this is safe on every map opening.

The pack tool carries `content/*.w3strings` and the menu XML into the build. CMF's test pack is a complete example of one toggle: its menu [`source/settings/menus/modCMFTestIconPack.xml`](../../source/settings/menus/modCMFTestIconPack.xml), its strings [`source/settings/modCMFTestIconPack.strings.json`](../../source/settings/modCMFTestIconPack.strings.json) and its script [`cmfTestIconPack.ws`](../../source/providers/modCMFTestIconPack/content/scripts/local/cmfTestIconPack.ws), which reads the toggle at game start and at each map opening and then registers its icons or releases them.

### Names CMF answers

CMF's own script functions all start with `CMF`. Its map uses CMF's pin fields and names: `OnCMFArtFailed`, `OnCMFMapFilter`, `OnCMFMapHintsReady`, `OnCMFMapTab`, `OnCMFMapHints`, `OnCMFInfoFold`, `OnCMFMovieEvent`, `OnCMFMapThemeReady`, `OnCMFPinClicked`, `OnCMFMapView`, `OnCMFMapOpening` and `OnCMFPictureNote`; its data channels include `"cmf.map.hints"`, `"cmf.map.hints.owned"`, `"cmf.map.itemStyles"`, `"cmf.map.theme"`, `"cmf.map.world"` and `"cmf.map.view"`. CMF answers no other mod's names. The general calls let a mod keep its own data while sharing the map.

<!-- API hook reference names used by the generated reference. -->
From API version 13, `CMFCore.OnInfoFold(menu, provider, open)` reports a visible folded box toggle; `CMFCore.OnMovieEvent(menu, provider, id, eventName, value)` receives a live owned movie event and returns whether it handled it; `CMFCore.OnMapAreaReady(menu, area)` reports a completed shown-area pin list. Wrap these with their exact published signatures and preserve other wrappers. See [Your own movie on the screen](own-screen-movie.md).


One exception keeps existing mods' values readable for their adapters: the game builds pin objects from the map's pin class and drops any field that class does not declare, so CMF's map declares these pin fields of other mods as compatibility names. CMF itself reads none of them; only the named adapters do.

| Pin fields | From | Read by |
| --- | --- | --- |
| `qmiLevelText`, `qmiIconScale`, `qmiIconTop`, `qmiIconKind`, `qmiNoCrosshairLabel`, `qmiIconTint` | Map Quest Insight 1.5.0 | its adapter |
| `iaiLv`, `iaiDiff` | Ink and Iron 0.8.7 and 0.8.8 | its adapter |

CMF itself ships no art from other mods. An adapter carries its own placeholder pictures, or a mod author's art only with that author's permission, credited: the Gwent Players Map and Witcher Gear Map adapters carry their author MateusAnd's art since 1.0.1, and the Map Quest Insight adapter carries its author Wolfer's quest icons since 1.0.1. Authors supply their own art and effects through the calls above.

## 10. What CMF does not do yet

- **Hiding is one-way.** A hide claim cannot be overruled by another pack's "show" claim, and the HUD minimap still shows hidden pins, except a type hidden everywhere when the player has the minimap add-on 2.1.0 (below). Text another mod writes into a tooltip (such as Map Quest Insight's "Also here") can still name a hidden pin.

- **Conflicts follow folder names, or CMF's own order setting.** The load order a player sets in a mod manager or `mods.settings` does not change which pack wins inside CMF. Names are compared ignoring capital letters, like the game's own folder order. A player can put packs first by name in CMF's settings (section 11). This ran in game on 2026-10-20.
- **CMF does not watch the options menu.** When a mod's own setting changes, the mod registers again at the next map opening, as section 9 shows under "Packs with settings or text". CMF prepares its winners again only when a registration actually changed. A change made while the map is open applies at the next opening. The settings launch (2026-10-19) ran this: the test pack's toggle followed at the next map opening.
- **A shared legend row takes the first pin's icon.** Quest pins share one row; give them one legend image (section 6).
- **A bad image path falls back to the stock icon.** CMF logs `art failed` for it; the pack tool's check catches paths into your own cache before you ship.
- **A legend row shared by several types** (quest pins) takes the first pin's tint, as it does the first pin's icon.
- **Pins other mods push** (no `AddPinTypeData`) take their legend tint from the legend name (`filteredType`) only, unless the row's image came from the pin's own type.
- **Level variants** (`_1` to `_3`) take the base type's claims unless a claim names the variant itself (API version 11).
- **No new pin types** (legend rows, row names and tabs come with API version 2, and pin labels with API version 4, section 5). The player arrow and player-placed pins take icons, colours and sizes from API version 11 and nothing else, and the world overview takes new pictures but keeps its layout (API version 9, section 5, "World overview pictures"). The rest comes with later CMF stages. The HUD minimap shows your type-level icons and tints only when the player installs CMF's optional minimap add-on (section 11); tag claims stay off the minimap.

## 11. For players: installing CMF, icon packs and other map mods

- **CMF is the single map.** Install CMF once; icon packs and other map mods work through it. Packs need no particular load order relative to CMF, and they do not need Script Merger.
- **Two packs, same pin type:** the pack whose folder name sorts first wins. To change that without renaming folders, close the game and add these lines to `dx12user.settings` in `Documents\The Witcher 3`, one pack folder name per line, earliest first (up to eight, `CMFProviderOrder1` to `CMFProviderOrder8`):

  ```
  [CMFSettings]
  CMFProviderOrder1=modMyFavouritePack
  CMFProviderOrder2=modOtherPack
  ```

  Listed packs win over every pack not listed, in the order given; the rest keep folder order. It changes only which pack's look CMF uses, never what a mod is allowed to do. Put one name on each line: the game reads a value only up to its first comma, and rewrites the file that way when it exits. The game also moves the section within the file when it saves settings; that is harmless. This form ran in game on 2026-10-20: both names were read in order and kept when the game exited.
- **Choose who wins, feature by feature (CMF 1.2.0).** The optional in-game menu add-on, `modCMFInGameMenu`, lets you pick a mod, Vanilla or Automatic for each feature (pin icons, colours, size, labels, clicks, the legend, hidden pins, the map look, movement, painting and drawings) and for most of their pieces, under Options > Mods > Conjunction Map Framework. Without it, write the same choices into `dx12user.settings` under `[CMFSettings]`, one per line, for example `CMFFile_Icons=modCMFExampleIconPack` or `CMFFile_Painting_Skellige=Vanilla`. [Settings file keys](settings-file-keys.md) lists every key, and [Players' choices](icon-pack-guide.md#players-choices-who-wins-each-feature-api-version-8) explains which answer wins when several are set.
- **A map mod not yet ported to CMF** ships its own copy of the map. CMF's map loads first, so that mod's own map-screen features (new pins or filter rows, colours, fog, faster scrolling) will not show until the mod is ported to CMF. Its scripts and menus keep working.
- **Do not give another map mod a lower `Priority` than CMF in `mods.settings`** unless you mean to switch CMF's map off. If you do, CMF packs' icons disappear and nothing else breaks.
- **Minimap icons are optional.** CMF's main folder leaves the HUD minimap stock. The separate `modCMFMinimapPanel` folder (2.1.0) adds its own HUD part on top of whichever minimap is installed and never moves or resizes that minimap, so it replaces no game file. It changes minimap pins by type only: type claims (an icon or tint per pin type) show on it, and a claim on one particular pin shows on the world map only. A pin type a pack hides everywhere is hidden on the minimap too: that takes a type hide (`CMFRegisterHidden`, not `CMFRegisterHiddenForTag`) on the exact pin type, for every map context (`mapContext` left empty), with no exemption a pin of that type could meet (the quest and tracked exemptions on quest types, the fast-travel exemption on `RoadSign`, `Harbor` and `Transport`). The add-on then masks that pin's icon, though a quest ring or glow the minimap draws round it can still show; as on the world map, a hide beats an icon or tint. Hides of single pins (tags), filtered types or map contexts, and hides with such an exemption, stay world-map only, and unclaimed pins look as the installed minimap draws them. Without the add-on the minimap shows every pin as before. It uses the HUD's unused `hud_pickeditemsinfo` slot, so a mod that fills that slot too would clash; none is known. It was tested with the game's own minimap, HUD Position Manager 1.0.0, Ink & Iron 0.8.10, Map Remastered 2.4.2 and Coloured Map Markers 1.60 with its adapter; moving the minimap with HUD Position Manager, controllers and Proton are not yet tested.
- **When a mod ships its own CMF support, uninstall CMF's adapter for it.** With both installed, the game stops at the script compile screen. Removing the adapter fixes it.
- **Uninstall packs before CMF.** CMF and its packs write nothing into saves; removing them restores the stock map.

## 12. Teaching examples: moving a map mod onto CMF

CMF has no calls made for one mod. Each ability is one general call that takes its target as an argument, and names (pin types, tags, tab ids, providers) are open, so a mod can name what another mod added. The adapters CMF ships are worked examples of that: each one shows how a map mod's own way of changing the map becomes CMF calls. Read each block as "you used to do this; now you call these CMF functions like this, and get the same result plus CMF's compatibility": several map mods on one map, conflicts settled by folder order, and no Script Merger. Match what the mod meant to show, not its glitches.

Blocks marked API version 4 or 5 ran in game on 2026-10-20 unless they say otherwise.

### One download, with and without CMF

From API version 13, your script can ask for art on a pin without calling any CMF function or naming any CMF class. The same archive compiles with CMF absent. The game and older CMF versions ignore these fields and retain the game's icon. Put the art in your own mod's `texture.cache`, built with the pack tool; it stays unused when no reader handles the asks. Use your mod's actual folder name everywhere below.

Write the fields on the full pin list in a `CR4MapMenu.UpdateUserMapPins` wrapper, before it calls `wrappedMethod(flashArray, indexToUpdate)`, and only when `indexToUpdate` is below 0 (the full list; 0 or more is one user pin). The game's pins and every pin pushed in an `UpdateEntityPins` wrapper are already in the list there, and CMF reads the asks after that call returns, whatever your script file's name. For a pin your mod pushes itself, you can instead write the fields on the object before you push it.

Do not write them in an `UpdateEntityPins` wrapper. A mod compiled with REDkit, such as Ard Dhu Stable, can carry its own compiled `CR4MapMenu.UpdateEntityPins`, and while it is installed no loose wrapper of that method runs (launch of 2026-10-26: the asks never arrived and CMF logged `entity step skipped`). `UpdateUserMapPins` still runs. In the list, find a pin your mod owns or intentionally styles and append your name once, preserving every other name:

```witcherscript
var providers : string;
// dataObject is the pin you pushed or found; declare locals at function start.
providers = dataObject.GetMemberFlashString("cmfAskBy");
if (StrFindFirst("," + StrLower(providers) + ",", ",modacmeicons,") < 0)
{
    if (providers != "") { providers += ","; }
    providers += "modAcmeIcons";
    dataObject.SetMemberFlashString("cmfAskBy", providers);
}
dataObject.SetMemberFlashString("cmfAskIcon_modAcmeIcons", "img://icons/modacmeicons/chest.png");
dataObject.SetMemberFlashString("cmfAskTint_modAcmeIcons", IntToString(16777215));
```

| Field | Value and withdrawal |
| --- | --- |
| `cmfAskBy` | Comma-separated folder names. Empty names are skipped, spaces are trimmed and duplicates are read once. Never remove another mod's name. |
| `cmfAskIcon_<folder>` | Image URL; nonempty text submits property 1. Empty text makes no request. |
| `cmfAskTint_<folder>` | Decimal RGB text, property 3; `"0"` is black. Empty text makes no request. |
| `cmfAskScale_<folder>` | Decimal scale text, 25 to 400, property 10. Empty text makes no request. |
| `cmfAskLabel_<folder>` | HTML label, property 12. Empty text makes no request. |
| `cmfAskIds_<folder>` | Comma-separated ids accepted by `CMFStylePin`. |
| `cmfAskText<id>_<folder>` | The property's text value; absent text is `""`. |
| `cmfAskNumber<id>_<folder>` | Decimal number text; absent text is zero. |

CMF reads `cmfAskBy` once per eligible pin, before `OnPinReady`, then submits each nonempty ask exactly as the corresponding `CMFStylePin` call. Full and late pins share validation, owner fields, rejection logs, player choices and folder order. Default order compares folder names ignoring case; wrapper append order does not decide the winner. No asks are read when `cmfAskBy` is absent or empty. The usual property withdrawal rules apply through `cmfAskIds`, including id 40; an empty dedicated field simply submits nothing. There is no ability query for this protocol because its scripts name no CMF functions. CMF reports `asks pins=<n>` once per build when any pin asks.

For packaged sources, keep catalogs and procedural art builders outside the clean pack input. Copy only scripts, built tables, README and PNG inputs there, then run `cmf_pack.py check` and `build`. The generated archive contains cooked art in your own cache and excludes the PNG/catalog working inputs. Check every script symbol against the game's actual bindings; a runtime guard cannot make a missing function compile.

## One mod, with and without CMF

You keep one mod for players with and without CMF, plus one small optional folder:

- **Your map file stays in your mod, unchanged.** Only one `panel_worldmap.redswf` loads, and the folder that sorts first wins. With CMF installed, CMF's folder sorts first and its map loads; without CMF, your own map loads and shows your look as it does today. Fields your scripts write for your own map are dropped quietly by CMF's map, which does no harm.
- **Your CMF calls go in a separate "CMF support" folder**, such as `modAcmeMapCMF`, that players install only together with CMF. A script that calls a CMF function, or wraps `CMFCore.OnPinReady` or another CMF hook, stops the game at the script compile screen when CMF is not installed, and WitcherScript has no way to call a function only if it exists. So these calls cannot live in your main mod.
- **That folder claims under your mod's own folder name** as its provider, exactly as CMF's adapter for your mod does (below). Players remove CMF's adapter for your mod and add your support folder, and the map looks the same. Check and build it with the pack tool's `--adapts` and your mod's folder name, as below.
- **Do not write CMF's pin fields (`cmfIconPath` and the others) or CMF's own flash storage keys (`cmf.map.theme`, `cmf.map.space`) yourself** to keep one folder that compiles without CMF. That skips CMF's claims and winners, overwrites other mods' drawings, cannot reach CMF's hooks, and depends on CMF's internal wiring, which may change in any release; only CMF's functions are kept from 1.0.0 on. Use the support folder.

### The adapter identity rule

An adapter's provider is the **adapted mod's folder name**, not the adapter's own: the Map Quest Insight adapter registers as `modMapQuestInsight`, the Gear adapter as `modWitcherGearMap`. So folder order between mods is the same with CMF as without it, and when the mod's author later ships CMF support under that same name, the two give the same result. The image paths stay under the adapter's own folder (`img://icons/modcmfadapterwitchergearmap/...`), because the texture cache is the adapter's.

Check and build an adapter with the adapted folder named:

```
python tools/cmf_pack.py check path/to/modCMFAdapterWitcherGearMap --adapts modWitcherGearMap
python tools/cmf_pack.py build path/to/modCMFAdapterWitcherGearMap --adapts modWitcherGearMap --out path/to/new-folder
```

With `--adapts`, every claim must name that folder as its provider; without it, every claim must name the pack's own folder. A leading `zz_` on the script file name (to sort after the adapted mod's files, so your wrappers run around theirs) gives no warning.

### A general icon pack

You used to ship your art inside your own copy of the map file (`panel_worldmap.redswf`), and only one copy loads, so two icon mods could not be installed together. Now you ship PNGs in your pack and call:

```
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modAcmeIcons", 1))
	{
		CMFRegisterIcon("modAcmeIcons", 'RoadSign', "img://icons/modacmeicons/roadsign.png");
		CMFRegisterTint("modAcmeIcons", 'Herbalist', 4259648);
	}
	return result;
}
```

### A mod's own signpost, reached by tag from another mod

Mod A adds its own pin, a well. You used to give it any id; now give it the id the game would give a pin with that tag, `NameToFlashUInt(tag)`, and choose a tag other mods can name. Shortened; set the other fields as the game's own pins carry them:

```
// Mod A, in its UpdateUserMapPins wrapper, when indexToUpdate is below 0 (an UpdateEntityPins
// wrapper does not run while a REDkit-compiled mod such as Ard Dhu Stable replaces that method)
pin = m_flashValueStorage.CreateTempFlashObject("red.game.witcher3.data.StaticMapPinData");
pin.SetMemberFlashUInt("id", NameToFlashUInt('modA_well'));
pin.SetMemberFlashString("type", "modA_Well");
pin.SetMemberFlashString("filteredType", "modA_Well");
flashArray.PushBackFlashObject(pin);
```

Mod B restyles that one well without knowing anything else about mod A:

```
// Mod B, in its OnGameStarted wrapper
CMFRegisterForTag("modB", 1, 'modA_well', '', "img://icons/modb/well.png", 0);
CMFRegisterForTag("modB", 10, 'modA_well', '', "", 150);
```

CMF matches a tag claim to a pushed pin when the pin's `id` equals `NameToFlashUInt` of the claim's tag (API version 4). Mod B can also hide it (property 9) or keep it out of a tab (15) the same way. Not yet run in game.

### Map Quest Insight (API version 4)

You used to write your values on each pin for your own map file to read:

```
dataObject.SetMemberFlashNumber("qmiIconScale", scale);
dataObject.SetMemberFlashString("qmiLevelText", levelHtml);
dataObject.SetMemberFlashUInt("qmiIconTint", rgb);
```

Now you call CMF on the same pin, in an `OnPinReady` wrapper:

```
CMFStylePinScale("modMapQuestInsight", dataObject, (int)(scale * 100 + 0.5));
CMFStylePinLabel("modMapQuestInsight", dataObject, levelHtml);
CMFStylePinTint("modMapQuestInsight", dataObject, rgb);
```

Your "Info box height" becomes `CMFRegister("modMapQuestInsight", CMFPropertyInfoBoxHeight(), '', '', "", height)`, and hiding signposts per filter tab becomes `CMFStylePin("modMapQuestInsight", dataObject, CMFPropertyTabHide(), "Quests", 1)`. The adapter (`source/adapters/map-quest-insight`) reads Map Quest Insight's fields back and makes exactly these calls; [`map-quest-insight-adapter.md`](map-quest-insight-adapter.md) has the full table.

Your "Faster map" and "Zoom out to whole region" switches used to change your own map file's timers and zoom limit. Under API version 6 they become `navigation` and `opening` keys sent from your `OnConfigUI` wrapper after your settings load: while "Faster map" is on, `frameTimed` 1, `stepMs` 17, `worldStepMs` 24, `maxStepMs` 50, `zoomTimed` 1, `padHoldMs` 60, `tweenEveryFrame` 1, `slideSeconds` 0.2, `slideOffset` 0, `closeSeconds` 0.1, `pinsDuringSlide` 1, `pinStepMs` 1, `pinBatch` 120, `showDelayMs` 1, `fadeSeconds` 0.1 and `tileFadeSeconds` 0.2; while "Zoom out" is on, `zoomOutFit` 1 and `edgeOvershoot` 48. A switch that is off sends `"unset"` for its keys. Both switches ran in game on 2026-10-20, on and off.

Your "Spread stacked quest markers" switch becomes the `spread` keys, sent from the same wrapper with your own map file's values (`on` 1, `anyPin` 0, `enterRadius` 20, `stackDistance` 24, `maxPins` 8, `gap` 48, `openMs` 150, `closeMs` 120, `lockRadius` 24, `keepRadius` 48), and your `QMI_SpreadRank` becomes `CMFStylePin("modMapQuestInsight", dataObject, CMFPropertySpreadRank(), "", rank)` on each quest pin. Your script decides whether to drop ALSO HERE by asking your own map file (`qmiSpreadMap`); a port drops it when the switch is on and `CMFHasAbility('spread', '')` answers true. The spread ran in game on 2026-10-20; the adapter still shows ALSO HERE.

### Ink and Iron (API versions 4 and 5)

You used to write the quest level on each pin for your own map file, and send your key hints to your own storage name:

```
dataObject.SetMemberFlashInt("iaiLv", level);
dataObject.SetMemberFlashInt("iaiDiff", difficulty);
st.SetFlashArray("inkiron.map.hints", arr);
```

Now the level is a label, and the hints go to CMF's name:

```
CMFStylePinLabel("modInkAndIronUI", dataObject, CMFLevelLabel(level, difficulty));
st.SetFlashArray("cmf.map.hints", arr);
```

and you answer `OnCMFMapHintsReady()` (on `CR4MapMenu`) by sending the list again. `CMFLevelLabel` gives the journal's colours; to keep your own tag colours, build your own HTML and pass it to `CMFStylePinLabel`. The adapter is `source/adapters/ink-and-iron`.

**Your map's look (API version 5).** You used to draw your frames, fades, tag plates and key caps with code in your own map file (`MapMenu.iiFrame`, `HubMapContainer.inkEdge`, `StaticMapPinDescribed.iaiLvTab` and the others). Now the same values are `CMFStylePart`, `CMFDraw` and `CMFDrawSet` calls (section 5), and your tag colours are a `LabelColor` claim (property 17) per pin, so your level tag keeps its difficulty colour while the label text stays plain `"Lv "` and the level. The theme adapter lists every value with the member it came from.

**Your gold buttons and World Map overview (API version 9).** Your map file re-drew the controller button sheets in gold, and your optional World Map file replaced the overview's painting and crests. Now they are pictures: `CMFRegisterButtonPicture` for each button of each controller family, and `CMFRegisterWorldPainting` and `CMFRegisterWorldCrest` for the overview, made choice-only with `CMFRegisterChoiceOnly("modInkAndIronUI", "Painting_World")` and `"Painting_Crests"` because a script cannot tell whether the World Map file is installed. Since adapter 1.2.0 the adapter carries your own art for both, with your permission and credited: the painting, the seven crests and all 143 buttons. The buttons show by default; the overview shows only when a player picks Ink and Iron for it.

### Witcher Gear Map

You used to push your markers with your own types (`WitcherGearWolf` and the rest) and draw them in your own map file. Your script keeps pushing the same pins; the art and tab come from calls:

```
CMFRegisterIcon("modWitcherGearMap", 'WitcherGearWolf', "img://icons/modcmfadapterwitchergearmap/gear_wolf.png");
CMFRegister("modWitcherGearMap", 8, 'wgm_gear', '', "[[map_category_wgm_gear]]", 8);
CMFRegister("modWitcherGearMap", 6, 'WitcherGear', '', "wgm_gear", 703);
```

One picture per type, each school in its own colour, so no tint is needed. Since adapter 1.0.1 those pictures are your own, shipped with your permission and credited. Gear's pins use numeric ids (from 1464287232), so another mod reaches them by type or in `OnPinReady`, not by tag. The adapter is `source/adapters/witcher-gear-map`.

### Gwent Players Map

You used to draw the player cards and the "Gwent" tab in your own map file, which also called your event `OnGwmMapFilter(tab)` each time a tab showed. Now:

```
CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayer', "img://icons/modcmfadaptergwentplayersmap/card.png");
CMFRegister("modGwentPlayersMap", 8, 'Gwent', '', "[[map_category_Gwent]]", 8);
CMFRegister("modGwentPlayersMap", 6, 'GwentPlayer', '', "Gwent", 701);
CMFRegister("modGwentPlayersMap", 10, 'GwentPlayerLarge', '', "", 119);

@addMethod(CR4MapMenu)
event OnCMFMapFilter(category : string)
{
	OnGwmMapFilter(category);
}
```

The event passes CMF's tab report on to your own, so your script moves the cards exactly as before. Your large cards were drawn bigger in your map file; a size claim (API version 4) gives them the same 119 percent (seen in game on 2026-10-20). Since adapter 1.0.1 the two cards are your own art, shipped with your permission and credited. The adapter is `source/adapters/gwent-players-map`, and [its author page](gwent-players-map-adapter.md) has the whole change.

### Fog of War

You used to remove the pins under the fog from the list inside your own `UpdateEntityPins` wrapper, so pins a later wrapper pushed (Gear's markers) escaped it. Now you mark them and CMF removes them after every mod has added its pins:

```
CMFStylePin("modFogOfWar", pin, 9, "", 1);
```

`CMFHidePin("modFogOfWar", pin)` is the same call by name (API version 3). The adapter (`source/adapters/fog-of-war`) asks Fog of War's own filter once per build from an outermost wrapper and makes this call for each pin it drops; it passed in game with API version 3. A port of your own could instead decide per pin in an `OnPinReady` wrapper (API version 4; the hook has run in game, this use of it has not):

```
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	wrappedMethod(dataObject, mapContext);
	if (YourPinIsUnderFog(dataObject))
	{
		CMFHidePin("modFogOfWar", dataObject);
	}
}
```

Hidden pins leave the legend counts, cycling, the overview and "show on map" too, and the player marker and the player's own pins are never hidden.

Your clouds are not drawn under CMF 1.0.0. To bring them back yourself, move your cloud drawing code into a small movie of your own and hand it your grid and settings as a `movie` drawing on `mapSpace` ("Drawing on the map itself", section 5). Not yet run in game.

### All Quest Objectives (API version 6)

Your map file used to send `OnStaticMapPinUsed(id, -(aqoomCachedPin + 999))` when a grey "[CACHED]" merchant pin was used, and your `OnStaticMapPinUsed` wrapper turned that into `OnCachedPinUsed`. CMF's map never sends that number. Now you claim the click on each cached pin and CMF calls you back:

```
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	wrappedMethod(dataObject, mapContext);
	// for each pin your script pushed with aqoomCachedPin > 0:
	CMFStylePin("modAQOOMRemastered", dataObject, CMFPropertyPinClick(), "use, doubleClick", aqoomCachedPin);
}
```

An `OnPinClicked` wrapper then rebuilds `-(value + 999)` from the claim's value and makes your same two calls, `IsCachedPinUse` and `OnCachedPinUsed`, with the map menu CMF passes; every other provider's click goes on through `wrappedMethod`. A claim on one pin beats any type or tag claim on it, and your claims never meet Map Pin Teleport's, which are on the player's own pins. The adapter is `modCMFAdapterAllQuestObjectives`.

Your difficulty frames (`wmkIcon` on untracked objectives) were drawings inside your map file, which CMF's map replaces. In the same `OnPinReady` wrapper you read `wmkIcon` and call `CMFStylePinIcon` with your own picture, then `CMFStylePinTint` with that frame's colour. The adapter does this with two white placeholder pictures of its own, one badge and one mark, until you ship yours. Your own legend row for those objectives is a quest row claim (above, "Quest rows"): `CMFRegisterLegendRow("modAQOOMRemastered", 'QuestObjectiveOther', 'Quests', 200)` and `CMFRegisterLegendLabel("modAQOOMRemastered", 'QuestObjectiveOther', "All Quest Objectives")`. Where Map Quest Insight's adapter also styles an untracked objective, your badge wins by folder order. The badges, the legend row and hiding it ran in game on 2026-10-20.

### Map Pin Teleport (API version 6)

Your map file used to draw a "GO NOW" button beside every pin the player placed, and to send `OnStaticMapPinUsed(0, -2 - (id & 0x3FFFFFFF))` when that button was clicked or E, Enter or gamepad A was pressed on the selected pin. Your `OnStaticMapPinUsed` wrapper then passed the id to `ModPinTP_Request`. CMF's map never sends that number. Now you claim those two inputs on the player's own pin types, give CMF your hint, your button text and your button's look, and CMF calls you back:

```
CMFRegister("modMapPinTeleport", CMFPropertyPinClick(), 'User1', '', "use,button", 1);
CMFRegister("modMapPinTeleport", CMFPropertyPinClickHint(), 'User1', '', "Go Now", 1);
CMFRegister("modMapPinTeleport", CMFPropertyPinClickButton(), 'User1', '', "GO NOW", 1);
// the same for User2 to User7, then your button's look:
CMFStylePart("modMapPinTeleport", 'pinButton', 'width', "", 150);
CMFStylePart("modMapPinTeleport", 'pinButton', 'fill', "", 1709072);	// 0x1A1410
```

An `OnPinClicked` wrapper then reduces `pinId` to its low 30 bits, the number your map file sent, and calls your `ModPinTP_Request` with the map menu CMF passes. Every other provider's click goes on through `wrappedMethod`. Your messages, quick save, refusals and teleport stay in your script, and your `OnStaticMapPinUsed` and `OnAppendGFxButton` wrappers can stay installed: nothing sends their number or label any more. Your claims are type claims, so a mod that claims one placed pin beats them on that pin, and the hint and button text always come from whichever mod won the click. They never meet All Quest Objectives' claims, which are on its cached merchant pins. `pinButton` is one part shared by every mod's buttons, and the earliest folder that styles it sets the look for all of them. The adapter is `modCMFAdapterMapPinTeleport`. It ran in game on 2026-10-20: the GO NOW button, the E key and a long-distance teleport.

### Smooth Map (API version 6)

Smooth Map supports CMF itself: its author's "Conjunction Map Framework Version" (folder `modSmoothMap_CMF`, on Smooth Map's Nexus page) sends Smooth Map's timing as `navigation` and `opening` keys and has its own settings menu for the opening speed. The example adapter `modCMFAdapterSmoothMap` that once stood here is retired. "Smooth map movement" above lists every key.

### Community Patch - World Map (API version 6)

Your patch merges Botanist, The Stable and Smooth GUI into one copy of the world map file, which CMF's map replaces. Its changes: the movie runs at 60 frames per second; a "Botanist" tab at 8 that leaves out fast-travel pins (`CategoryDefinition(8, true, false, false)`), with Botanist's three types at 612 to 614 and their frames in the pin sprite; and `Stables` under NPCs at 516. Now you ask CMF for each, under your folder name:

```
if (CMFHasAbility('navigation', 'frameRate'))
{
	CMFStylePart("mod000CommunityPatch_WorldMap", 'navigation', 'frameRate', "", 60);
}
CMFRegister("mod000CommunityPatch_WorldMap", 8, 'Botanist', '', "[[map_category_Botanist]]", 8);
CMFRegisterCategoryNoDefault("mod000CommunityPatch_WorldMap", 'Botanist', true);	// your tab's rows stayed out of Default
CMFRegister("mod000CommunityPatch_WorldMap", 6, 'BotanistHGHerb', '', "Botanist", 612);
// the same for BotanistHG at 613 and Botanist at 614, an image for each with CMFRegisterIcon, then:
CMFRegister("mod000CommunityPatch_WorldMap", CMFPropertyPinScale(), 'BotanistHG', '', "", 149);
CMFRegisterTint("mod000CommunityPatch_WorldMap", 'Botanist', 16763904);	// gold 0xFFCC00; BotanistHGHerb and BotanistHG blue 0x9BAADD
CMFRegister("mod000CommunityPatch_WorldMap", 6, 'Stables', '', "NPCs", 516);
```

CMF's tabs show fast-travel pins, so an `OnPinReady` wrapper (API version 4) leaves every pin with `isFastTravel` out of your tab, the same test your map file made: `CMFStylePin("mod000CommunityPatch_WorldMap", dataObject, CMFPropertyTabHide(), "Botanist", 1)`. Smooth GUI changes nothing but the frame rate, so you send no other `navigation` key; if the game cannot change the rate while running, CMF answers `false` and the map stays at 24. The adapter is `source/adapters/community-patch`; its herb pictures are placeholders in its own texture cache, and its author page has the whole change. In game on 2026-10-20, without Botanist installed, the log showed the 60 fps map, the Botanist tab and its rows, and the Stables row. The herb art and tints and keeping Botanist's rows out of Default were seen on 2026-10-21 through the Botanist adapter, which makes the same claims (Community Patch was out for that launch).

### Botanist (API version 6)

Your map file is the game's with a "Botanist" tab at 8 that leaves out fast-travel pins (`CategoryDefinition(8, true, false, false)`), your three types at 612 to 614 in it, kept out of Default, and their three frames in the pin sprite; it is Community Patch's map without the Stables row and the 60 fps. CMF's map loads instead of yours, so the tab, rows and frames are missing while Shared Utils still pushes your pins. Now you ask CMF for each, under your folder name:

```
CMFRegister("modBotanist", 8, 'Botanist', '', "[[map_category_Botanist]]", 8);
CMFRegisterCategoryNoDefault("modBotanist", 'Botanist', true);	// your tab's rows stayed out of Default
CMFRegister("modBotanist", 6, 'BotanistHGHerb', '', "Botanist", 612);
// the same for BotanistHG at 613 and Botanist at 614, an image for each with CMFRegisterIcon, then:
CMFRegister("modBotanist", CMFPropertyPinScale(), 'BotanistHG', '', "", 149);
CMFRegisterTint("modBotanist", 'Botanist', 16763904);	// gold 0xFFCC00; BotanistHGHerb and BotanistHG blue 0x9BAADD
```

An `OnPinReady` wrapper (API version 4) leaves every pin with `isFastTravel` out of your tab, the same test your map made: `CMFStylePin("modBotanist", dataObject, CMFPropertyTabHide(), "Botanist", 1)`. These are exactly the Community Patch adapter's Botanist lines; with both installed, Community Patch's folder sorts first and wins each shared claim with the same value, as its map wins over yours without CMF. Your pins' circles, labels and herb counts stay yours, and the circle keeps your Map Pin Size because CMF's pin size scales only the icon. The adapter is `source/adapters/botanist`; its herb pictures are the Community Patch adapter's placeholders in its own texture cache, and [its author page](botanist-adapter.md) has the whole change. In game on 2026-10-21 the leaves, the tab and the Default exclusion showed; your pins reach the map from Shared Utils' wrapper outside CMF's, which CMF's late-pin catch handles for you.

### The Stable (API version 2)

Your map file is the game's with one line added to `HubMapPinPanel`, `"Stables": new PinTypeDefinition("NPCs", 516)`, which gives the stable masters' horseshoe markers a row under NPCs. CMF's map replaces your map file, so the markers still draw (the game's own Stables drawing) but that row is missing. Now you ask CMF for it, under your folder name:

```
CMFRegister("modArdDhuStable", 6, 'Stables', '', "NPCs", 516);
```

That is the whole port: `Stables` is a game pin type, so it needs no art call, and your scripts' names and descriptions on the pins stay yours. Community Patch - World Map's adapter claims the same row with the same value and sorts first, as its map file loads over yours without CMF. The adapter is `source/adapters/the-stable` and [its author page](the-stable-adapter.md) has the whole change. In game on 2026-10-21 the horseshoe showed on the map and minimap with your name for it, the Stables row hid and showed it, and the log showed the row under your folder name with nothing rejected.

### Witcher's Path (API version 6)

Your map file used to draw your route from the object you send to `worldmap.witcherspath`, add the WITCHER'S PATH tab with no pins, and draw four boxes above the filter selector whose clicks called `OnWitchersPathClearRequest` and `OnWitchersPathUseGeneralColor`. CMF's map loads instead of yours, so none of it shows. Now you keep sending your object exactly as you do and describe the drawings ("Drawing on the map itself", section 5): the route is one `line` drawing on `mapSpace` that listens to your key, and the tab comes from the drawings' `tab` key, so there is no legend call:

```
CMFDraw("modWitchersPath", 'mapSpace', 'witchersPathRoute', 'line');
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'listen', "worldmap.witcherspath", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'layer', "under", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'tab', "WitchersPath", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'tabLabel', tabLabel, 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeZoom', "", 0);
CMFDrawSetList("modWitchersPath", 'witchersPathRoute', 'colors', colors);	// foot, horse, boat
```

Your boxes are `text` drawings that paint their own box, stacked upward from `legendTab` with `above` 6 and `widthShare` 1; "Erase path" and "Single color" take `click` 1 and 2 and the hover keys, and the distance box reads your two texts with `listen` and `listenFields` `"text=regionText|totalText"`. An `OnDrawingClicked` wrapper calls your two events on the map menu CMF passes, and after the switch redescribes the drawings and calls `CMFMapRefresh()`, which keeps the tab, pan and zoom. Your first send comes while the map is still opening, before CMF's map listens, and never arrives, so an `OnMapListening` wrapper calls your own `menu.WitchersPathSend(true)` once `keys` include `worldmap.witcherspath`. Your recorder, save data, region rules, distances, popup and saved choice stay yours, and after an erase or a region change the route redraws on its own because CMF listens to your key. Every call uses your folder name, so folder order stays as without CMF; the route's `order` 10 keeps it above a map-space drawing left at 0. The adapter is `modCMFAdapterWitchersPath` and its author page is [`witchers-path-adapter.md`](witchers-path-adapter.md). It ran in game on 2026-10-20 (launches D3 to D6): the route, the tab, the four boxes, their clicks and the legend.

### Annoying Map (API version 9)

Your map file used to report every pan (`OnPositionChanged(x, y)`) and every zoom (`OnZoomChanged`) to your script, which keeps them per region in the save, and to send `OnZoomMap` on the first zoom key, which puts back the real zoom limits that `AM_InitZoom` narrowed to the saved zoom. CMF's map loads instead of yours and sends none of them, so nothing new is remembered and a region with a saved zoom stays stuck at it. Now CMF's map reports the view and lets you choose the view a region opens with ("The map's view", section 5):

```
@wrapMethod(CMFCore)
function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float,
	zoom : float, reason : name)
{
	wrappedMethod(menu, area, x, y, worldX, worldY, zoom, reason);
	AMap().SetXY(x, y, AM_FilterArea(area));
	AMapZoom().SetXY(zoom, zoom, AM_FilterArea(area));
}

@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	wrappedMethod(menu, area, mapContext);
	if (menu.am_maxZoom > 0)
	{
		menu.OnZoomMap();
	}
	CMFSetOpeningView("modAnnoyingMap", area, 0, 0, AmAdapterSavedZoom(area), true);
}
```

`OnMapView`'s `x`, `y` and `zoom` are in the units your own reports used, so your storage takes them unchanged. Your saved place needs no call: your script still sends it through the game's own default-position call, which CMF's map uses, so `keepPlace` is `true`. Your other features (Geralt's marker, Roach and the boat only at signposts, no herbs) are in your own `mapMenu.ws` and work beside CMF without help. Every call uses your folder name. The adapter is `modCMFAdapterAnnoyingMap` and its author page is [`annoying-map-adapter.md`](annoying-map-adapter.md). It ran in game on 2026-10-23 (the CMF 1.3.0 launch): the map reopened at the place and zoom the player left, also after switching regions, and the whole zoom range stayed reachable.
