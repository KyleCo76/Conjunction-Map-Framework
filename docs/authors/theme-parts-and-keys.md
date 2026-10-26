# Map theme parts and keys

This page lists every part of the map that CMF's theme calls can name, every key each part and each drawing kind takes, and what each key does. It belongs with the author guide's sections "The map theme", "Pin clicks", "Smooth map movement", "Spreading stacked pins" and "Drawing on the map itself" ([`icon-pack-guide.md`](icon-pack-guide.md#5-write-your-script)), which explain the calls themselves:

- `CMFStylePart(provider, part, key, text, number)` sets one style key of a part, or one behaviour key.
- `CMFDraw(provider, anchor, id, kind)` makes a drawing tied to a part or to another drawing; `CMFDrawSet(provider, id, key, text, number)` sets one key of it, and `CMFDrawSetList(provider, id, key, values)` one list key.
- `CMFHasAbility(part, key)` answers whether the installed CMF knows a part, layer or drawing kind (`key` `''`) or a key. It answers from the same lists as the tables at the end of this page.

Every name here is a general piece of the game's world map, not of any mod. A key not in the lists is refused and logged (`theme rejected ... reason=unknown`); the pack tool's `check` reports it before you ship. The tables at the end of this page are generated from the lists CMF and the pack tool hold, so they match the current source API revision (13). Their last column names the in-game menu row that decides each key (API version 10).

## Values

- **Words go in `text`, everything else in `number`.** The keys that take words are marked in the tables below. Pass `0` as the number for a word key and `""` as the text for a number key.
- **Colours** are decimal `0xRRGGBB` numbers, as for tints: red x 65536 + green x 256 + blue, from `0` to `16777215`.
- **Opacities** (`alpha`, `alpha2`, every key ending in `Alpha`, `alphaHover`) run from `0` to `1`.
- **Switches** (`centerInLimit`, `frameTimed`, `crosshairRoam`, `brackets`, `sizeZoom`, `preview`, `strokeZoom`) take `0` or `1`.
- **Sizes** (`size`, `scale`, `nameSize`, `titleSize`, `bodySize`) must be above `0` and at most `1000`. Other numbers run from `-100000` to `100000` unless a key's own range says otherwise.
- **`"unset"`** as the text withdraws your own value of any key (API version 6), so the next folder's value or the game's applies from the next opening.

## Who wins

- **Styles: one owner per part.** The earliest folder that styles a part owns every style key of that part, so two looks never mix inside one part's text. From API version 10 a part's behaviour keys (the tooltip's `clear` keys and the label's `rise` keys) have their own owner, decided among the mods that sent one of them, and the look's owner is decided among the mods that sent a look key. Other folders' style calls on that part are ignored and logged once.
- **Behaviour keys are won one by one.** On `map`, `navigation`, `opening`, `spread` and `wide`, each key goes to the earliest folder that sets that key, except the reveal and panel-placement shorthand families described below: each family has one provider.
- **Every mod may draw.** Drawings from several mods sit together. Within one layer they are sorted by `order`, then by folder with the earlier folder on top, then by the order the calls were made. A drawing id belongs to the folder that made it first, so prefix your ids with your mod's name.
- **Keys nobody sets keep the game's look and behaviour**, except the four movement keys CMF sets itself (see "Smooth map movement" in the guide).

## The parts

| Part | What it is |
| --- | --- |
| `screen` | the whole 1920 x 1080 screen (from API version 10, the whole screen on a wide or tall one); an anchor for drawings, with no style keys |
| `map` | the map area (region map, interior map and world view) |
| `mapEdge` | the edge of the visible map image; its drawings move and zoom with the map |
| `title` | the region title |
| `tracker` | the quest tracker and its key row |
| `legend` | the pin legend with its tab and scroll arrows |
| `legendRow` | each legend row |
| `legendTab` | the legend's tab name |
| `tooltip` | the pin information box |
| `preview` | the corner overview |
| `worldButton` | the world-view button with its key |
| `worldHint` | the "go to world view" hint beside the world-view button |
| `hints` | the key-hint row inside the map (see "Key hints and filter tab reports" in the guide) |
| `keyCap` | every key cap in the hint row, the tracker keys and the world-view button |
| `pinLabel` | the label above each pin (level tags and label texts) |
| `pinName` | the name below each fast-travel pin (signposts, harbours) |
| `navigation` | how the map pans and zooms, and the controller crosshair |
| `markerPanel` | the panel for placing your own map markers |
| `pinButton` | the button CMF draws beside a pin whose click a mod won (API version 6) |
| `mapSpace` | the map itself, in world metres: an anchor for drawings that pan and zoom with the map (API version 6) |
| `opening` | how the map opens and closes (API version 6) |
| `spread` | how stacked pins fan out into a row (API version 6) |
| `wide` | how the map fills a screen that is not 16:9 (API version 10) |
| `crosshair` | the native region-map crosshair and its description label |
| `edgePointer` | each native quest, player or user-pin arrow at the edge of the map |

Not reachable through any part: the game's top bar and its own key-hint row (they belong to the common menu, not the map), and the HUD minimap. The world overview's painting, region crests and markers, and the map's controller button pictures are not parts either: from API version 9 (CMF 1.3.0) a pack gives them pictures with their own calls, described in the author guide's "World overview pictures" and "Controller button pictures". API revision 13 adds the `world` style part for region crest and label offsets, label text/font/size/colour, and outline colour/opacity. The region itself and the overview scroll limits stay native. Keyboard and mouse prompts stay text on `keyCap`.

## Revision 13 images, pin filters, sounds and world styles

`image` drawings use `src` (`img://...`), `fit` (`stretch`, `contain`, `cover` or `tile`, default `stretch`) and `smooth` (0/1, default 1), plus box placement and opacity. They can attach to drawable parts, another drawing, or `mapSpace`. Stretch fills the box, contain centres the whole image inside it, cover clips a centred image to fill it, and tile repeats the image at its own size. An absent source, zero opacity or zero dimension allocates no loader. Loads are shared by source and provider within this map, retired when their last drawing leaves, and retried after removal/reopening if they failed.

On `mapSpace`, give `x` and `y` in world metres. Width and height are pixels; absent dimensions use the loaded image's natural size, centred at that position. `sizeZoom` 0 keeps that size on screen; 1 lets it scale with the map. Nested drawings use the parent's box. The `pin` anchor uses the icon's drawn box; `pinLabel` and `pinName` use the label box. On these three anchors, comma lists `pinType` and `pinTag` restrict a drawing (both must match when both are present). Types match exactly. Tag text resolves without case through the typed-tag table described under `CMFDeclareTag`; unknown tags never match, and id 0 never matches a tag. The filters also work on nested drawings under these anchors.

`sounds` takes text event names or `none`. Unset `open`/`close` retains the native cue and timing; a value replaces it and `none` silences it. `select`, `zoom`, `tab`, `click` and `travel` are silent until explicitly set. `select` fires when a map pin becomes selected. Description scrolling, shared list-navigation highlights, gameplay denial and quest-tracking sounds remain native. `sounds` is a style part, not a drawing anchor.

`world` takes region targets through `CMFStyle`. `crestX`/`crestY` and `nameX`/`nameY` are offsets from that region's native crest/label position, in its existing map coordinates. `text`, `font`, `size` and `color` style its label; text keeps the supplied case and the game's `[[string_key]]` processing. `outlineColor` and `outlineAlpha` style the native border; `hide` accepts `outline,names`. Unsetting restores the native state. `world` is a style part, not a drawing anchor; it does not move the region or its travel target.

`zoomIn` on `navigation` is the closest (maximum) scale and `zoomOut` the farthest (minimum), in the same absolute units as logged zoom. Both must be positive (at most 100000). Unset preserves native limits and `zoomOutFit`; explicit `zoomOut` replaces the minimum and takes precedence over `zoomOutFit`. `zoomStep` accepts 1.01 through 2.0 and changes only wheel steps, using the reciprocal for zoom-out. Held-key and pad speed stay native. Crossed bounds collapse to the upper bound and log `zoom bounds crossed` once per opening. Style arrival never pans or zooms: limits apply on the next zoom input or native reset. Debug unlimited zoom still bypasses the clamps.

`tooltip` motion keys `showSeconds` and `hideSeconds` accept 0 through 30 seconds; `slide` is the slide distance in pixels. Unset uses native motion. These keys belong to the Info box motion row.

The info box's `plateColor` and `plateAlpha` style both its background and tracked-quest plate while retaining the native colour transform's alpha. `trackColor` and `thumbColor` colour the scroll bar and its thumb/continuation arrow. `titleCase` accepts `upper` (the native default) or `keep`; keep preserves supplied HTML and localization tokens. `hideScrollBar` 1 hides only the bar; scrolling still works. `scrollStep` is an integer multiplier from 1 through 1000 on native line/page steps, default 1. Keyboard repeat and the pad's 450 ms repeat timing remain unchanged. Scroll step and bar visibility share the Info box size and scrolling row (choice 64) with height 14 and width 39; other box look keys remain under Info box.

## Panel placement, fonts and element timing

`tracker`, `legend`, `preview`, `worldButton` and `worldHint` take `x`, `y` and `scale`. Offsets use the map's logical 1920 x 1080 units and compose with the native panel's position and wide-screen movement; `scale` multiplies its native scale. Child drawings follow their panel. The corner overview keeps its native anchor as it moves and zooms. Unsetting restores the native placement and size.

`legendRow`, `legendTab`, `keyCap`, `worldButton`, `worldHint` and `hints` take `font` and `size`. On `hints` these change the hint words; key glyphs have their separate `keyCap` style. Native key/click areas measure the styled text. `pinLabel` and `pinName` also take `color`, including item styles. An existing per-pin LabelColor claim still overrides this style colour; withdrawing that claim reveals the winning item/part colour.

`crosshair` and `edgePointer` take `color`, `alpha`, `scale` and the existing glow keys, under Frames and panels. Crosshair `hide` accepts `all` or `label`; hiding its label keeps native capture and label-show/hide state. Edge-pointer `hide` accepts `all`. Arrow styling affects each glyph; it does not scale the canvas or change where the native pointer geometry places it. Both are drawing anchors.

On `opening`, `revealLegendSeconds`, `revealTrackerSeconds` and `revealCrosshairSeconds` override `revealSeconds` for their element, including an explicit zero. They use the same 0 through 5 second range. On `wide`, `panelsLegend`, `panelsTracker` and `panelsPreview` override the shorthand `panels` share (0 through 1). A shorthand and its three longhands choose one provider as a family; a missing longhand uses that provider's shorthand or the native default, never another provider's value. Other opening and wide keys retain their separate ownership.

On `tooltip`, the title and body can override each generic glow suffix independently. Title keys are `titleGlow1Color`, `titleGlow1Alpha`, `titleGlow1Blur`, `titleGlow1Strength`, `titleGlow2Color`, `titleGlow2Alpha`, `titleGlow2Blur` and `titleGlow2Strength`. Body keys are `bodyGlow1Color`, `bodyGlow1Alpha`, `bodyGlow1Blur`, `bodyGlow1Strength`, `bodyGlow2Color`, `bodyGlow2Alpha`, `bodyGlow2Blur` and `bodyGlow2Strength`. Unset suffixes inherit the corresponding generic glow value from the same winning style. These use the existing glow ranges and preserve the info box's width and plate styling.

## Style keys

**Text keys**: `font` takes any font the game has loaded, such as `$TitleFont`, `$BodyFont`, `$BoldFont` or `$NormalFont`; `size` is in px; `color` is a colour; `spacing` is letter spacing in px; `align` is `left`, `center` or `right`.

**Glow keys**: two glows, `glow1Color`, `glow1Alpha`, `glow1Blur`, `glow1Strength` and `glow2Color`, `glow2Alpha`, `glow2Blur`, `glow2Strength`. On `title` and `keyCap` they replace the text's own glow. On other parts they are added only to text that has no glow or shadow of its own, so the game's own shadows stay; on `worldButton` and `hints` they apply to the whole button.

**Shadow keys**: `shadowDistance`, `shadowAngle` (degrees), `shadowColor`, `shadowAlpha`, `shadowBlur`, `shadowStrength`.

**`hide`** takes a comma-separated list of the game's own decorations on that part, from the words listed for it in the table at the end: `plate` (the backing plate), `selection` (the highlight of the selected row or tab), `arrowPlate` (the plate behind a row's arrow), `trackedPlate` (the tooltip's plate for the followed quest), `divider` (the tooltip's divider line), `frame` (the corner overview's frame), `edgeFade` (the map's edge gradients) and `clickRect` (a key cap's click area).

The other keys, part by part:

- **`map`**: `top` and `bottom` are the map area's edges in screen px (default `0` and `1080`; the game's own area is 110 to 970), and the map draws its tiles and pins down to them. `panLimit` is `map` or `screen`: with `screen`, panning stops when the map image's edge reaches the area between `top` and `bottom` across the full width. `centerInLimit` `1` centres a map smaller than that area; `0` lets it move freely inside it. `backdrop` is a colour drawn over the area under the map image.
- **`title`**: `x`, `y` move the title by px; `screenX`, `screenY` place its left and top at screen px instead. `wrap` `keep` keeps the game's line breaks; `none` keeps the title on one line.
- **`tracker`**: `nameFont`, `nameSize`, `nameColor` style the quest name.
- **`legendRow`**: `color` (a row's text), `colorSelected` (the selected row), `colorOff` (a row whose pins are switched off), `counterColor` (the pin count).
- **`legendTab`**: `color` and `spacing` for the tab name.
- **`tooltip`**: `titleFont`, `titleSize`, `titleColor` for its title and `bodyFont`, `bodySize`, `bodyColor` for its text. From API version 7, `clearMinHeight` (px, `0` to `4000`; `0` or unset is off) moves a box at least that tall (its box as drawings measure it) clear of the cursor and of the legend, tracker, corner overview, world-view button and region title each time it opens: beside the cursor on the side `clearSide` names (`right`, the default, or `left`), else the other side, else above or below it, wherever it covers least, and above those panels. It stays inside `clearLeft`, `clearTop`, `clearRight` and `clearBottom` (screen px, default the whole screen); `clearCursor` (px, default `40`) is how far it keeps from the cursor; `clearView` (`"region,interior,world"`) limits the views. A shorter box stays where the game puts it. From API version 11, `x` and `y` (px) move the box from the game's place, as `title`'s do; a box `clearMinHeight` moves clear of the cursor is placed by that instead. `x` and `y` belong to the box's placement with the clear keys, not to its look, so a mod that only moves the box never takes over another mod's info box look. Also from API version 11, these keys widen what a moved box keeps clear of and where it may go (none set = unchanged): `clearCursorAbove` and `clearCursorBelow` (px) add a strip from that far above to that far below the cursor, as wide as the box's title when `clearCursorTitle` is `1`; `clearPadX` and `clearPadY` (px) grow the cursor's area on each side; `clearBoxPad` (px) grows the box's own outline and `clearGap` (px) keeps that far from the area; `clearPick` `1` tries the box at the right, left and unchanged x against its unchanged y, the clear limits' top and bottom and just past each panel's top and bottom (`0`, the default, tries right, left, above and below the cursor); `clearCursorWeight` (default `10`) is how much covering the cursor area counts against covering a panel. From API version 12, the info box height claim only makes a long text scroll; a tall box leaves the game's place only through these keys (none set = unchanged): a box taller than `tallMinHeight` (px, `0` to `4000`; `0` or unset is off) is scaled to fit and placed with its bottom at `tallBottom` and its top no higher than `tallTop` at x `tallX`, or at `tallAltX`, `tallAltTop` and `tallAltBottom` while the quest tracker is not in its normal state or the mouse is right of the screen's middle (screen px, defaults `1300`, `130`, `906`, `112`, `206`, `1006`, Map Quest Insight's own places); `tallUnderLegend` `1` draws it just under the legend; `tallClear` `1` keeps that place off the legend, quest tracker, corner overview, world-view button and hint, and region title a box there would cover (a panel below the place's middle lifts its bottom, one above lowers its top; less than 120 px left keeps the place), and the box is scaled to what is left. A shorter box stays where the game puts it, scaled down only if it would reach above the screen.
- **`hints`**: `x`, `y` (px), `scale` and `align` place and size the key-hint row.
- **`keyCap`**: `color` (the key's name), `iconColor` (the key's icon), `brackets` (`0` drops the game's brackets round the key name), `keyGap` (px the key name moves right), `labelGap` (extra px before the label).
- **`pinLabel`**: with `rise` set, the label's text box sits with its bottom `rise` x the pin's icon scale + `riseOffset` px above the pin's centre; `riseTracked` and `riseOffsetTracked` do the same for the followed quest's pins and fall back to the untracked values. A label place claim (property `11`) on a pin wins over `rise`. The label's colour comes from a label colour claim (property `17`).
- **`markerPanel`**: `minLeft`, `maxRight`, `minTop`, `maxBottom` keep the marker panel inside these screen px.
- **`pinButton`**: `width`, `height`, `curve` (corner rounding), `fill`, `alpha`, `stroke`, `strokeWidth`, and `offsetX`, `offsetY` (the button's top-left corner measured from the pin, in px), plus the text and glow keys. One look applies to every mod's buttons. See "Pin clicks" in the guide.
- **`navigation`**: `frameTimed`, `stepMs`, `worldStepMs`, `maxStepMs`, `zoomTimed`, `padHoldMs`, `tweenEveryFrame`, `frameRate`, `zoomOutFit` and `edgeOvershoot` are explained with their ranges in "Smooth map movement" in the guide. The controller crosshair keys: `crosshairRoam` `1` lets the crosshair move freely near the screen's edges, and pin snapping then measures from the crosshair; `safeLeft`, `safeTop`, `safeRight`, `safeBottom` are the screen px rectangle the crosshair roams in before the map pans; `snapSeconds` is the time the crosshair takes to snap to a pin, and `centerSeconds` the time the map takes to centre. No launch has used a controller, so these keys are checked by value only.
- **`opening`**: `slideSeconds`, `slideOffset`, `closeSeconds`, `pinsDuringSlide`, `pinStepMs`, `pinBatch`, `pinBudgetMs`, `showDelayMs`, `fadeSeconds`, `tileFadeSeconds`, `revealSeconds` and, from API version 10, `readyAtFadeStart` (`1`: the map takes input and shows its panels as soon as the fade-in starts) and `revealEase` (`1`: the `revealSeconds` fade eases in), with their ranges in "Smooth map movement" in the guide.
- **`spread`**: `on`, `anyPin`, `enterRadius`, `stackDistance`, `gap`, `maxPins`, `openMs`, `closeMs`, `lockRadius` and `keepRadius`, with their ranges in "Spreading stacked pins" in the guide.
- **`wide`** (API version 10): `fill` (`1` fills a screen that is not 16:9, `0` keeps the 16:9 map centred), `panels` (`0` to `1`, how far the side and bottom panels move to the screen's edge), `maxRatio` (`0`, or `1.78` to `4`, the widest shape the map fills) and `world` (`1` grows the world overview to the screen's width), explained in "Wide and tall screens" in the guide.

## Drawings

`CMFDraw(provider, anchor, id, kind)` ties a drawing to an anchor: a part, `mapSpace`, or any drawing id any mod made. A drawing tied to another drawing is placed against that drawing's box and drawn just above it; if the anchor drawing goes away, the drawings tied to it are hidden and logged once. `kind` `''` withdraws the drawing.

**Kinds.** `rect` is a rectangle. `ring` is the rectangle with a hole `inset` px in from every edge. `ellipse` fills the box. `polygon` draws `points` (`"x,y x,y ..."`, px from the point `originX`, `originY`, each `0` to `1` across the box). `band` is a strip `size` px deep along `side` of the box (`left`, `right`, `top` or `bottom`), scaled with the map's edge fade when `sizeZoom` is `1`, at least `minSize` px and at most `maxShare` of the box's smaller side; a gradient on a band runs from its inner end to the box's edge. `text` is the game's HTML text, `image` loads a PNG, and `line` draws on the map itself. A `movie` can use any screen part or map space (below).

**The box a drawing is placed against.** A part's box is its visible text, each text field trimmed to its text width plus 8 px, with its pin icons, markers and arrows, leaving out anything hidden or nearly transparent and the game's own plates. `measure` `field` uses the part's whole text field instead of its trimmed text (`trim`, the default). `screen` is 0, 0, 1920, 1080 (from API version 10, the whole screen on a wide or tall one; numbers stay in 1920 x 1080 units and CMF moves them, as "Wide and tall screens" in the guide explains, and `wideAnchor` `edges`, `panels` or `centre` chooses how one drawing moves); `map` is the map area; `mapEdge` is the visible map image; `pinLabel` and `pinName` are the label's text box (text width + 4 by text height + 4 px) in the pin's own space. A part with nothing visible draws nothing, so a hidden tracker or tooltip takes its drawings with it.

**Place**, applied in this order:

1. `left`, `top`, `right`, `bottom` push each edge of the box outward in px (negative values move it inward).
2. `screenLeft`, `screenTop`, `screenRight`, `screenBottom` fix an edge at a screen px instead.
3. `width` or `widthShare` (a share of the box's width) gives a fixed width, placed by `alignX` (`0` left to `1` right, default `0.5`); otherwise `minWidth` grows the drawing to the right. `height`, `heightShare`, `alignY` and `minHeight` work the same way downward.
4. `offsetX`, `offsetY` move the result by px.
5. `minLeft`, `maxRight`, `minTop`, `maxBottom` keep it inside these screen px without changing its size.

**Paint.** `fill` and `alpha` give a plain colour; on `pinLabel` and `pinName` drawings `fill` may be the text `"label"`, the label's own colour. `fill2`, `alpha2`, `gradient` `"linear"`, `angle` (degrees) and `curve` grade the colour and opacity from `fill`/`alpha` to `fill2`/`alpha2`. `stroke`, `strokeAlpha` and `strokeWidth` draw an outline; a drawing with only a stroke is not filled. Glow and shadow keys work as on parts. `repeat` (`1` to `64`) draws copies grown outward by `repeatStep` px each, and `alphaList` (`"a,b,c ..."`) gives each copy its own opacity, the innermost first: a soft shadow of rings is one drawing.

**Layer and conditions.** `layer` is `over` by default (just above the part), `under` (just below it), `belowMap` (under the map image), `aboveMap` (over the map image and under every panel) or `top` (over every panel). On `screen`, `under` means `aboveMap` and `over` means `top`; on `map`, `under` means `belowMap` and `over` means `aboveMap`. A drawing tied to another drawing is drawn in its anchor's layer. `order` sorts drawings within a layer, lower first. `view` (`"region,interior,world"`) limits the views it shows in, and `when` is `selected` (on `legendRow` and `legendTab`), `tracked` or `untracked` (on `pinLabel` and `pinName`). `minPartHeight` (px, API version 7) shows a drawing only while its part's box is at least that tall, for example a darker backing under a long tooltip.

**Boxes that stack, react and click** (API version 6). `above` (px) stacks a drawing that far above its anchor's top, at its own height, clearing every box, plate or frame drawn on that part by any mod. `tab` shows a drawing only while the legend tab with that id is selected; if no pin makes that tab, CMF adds it, named by `tabLabel` (your text or a `[[key]]`). `click` `1` or more on a drawing on a screen part makes it take the mouse and report a left click to `CMFCore.OnDrawingClicked` with that number; while the pointer is over it, `fillHover`, `alphaHover`, `strokeHover`, `strokeAlphaHover`, `strokeWidthHover` and `colorHover` give its hover look.

**Text** (API version 6). A `text` drawing shows `text` (the game's HTML) with `font`, `size`, `color`, `align`, and `padding` px round the words; it paints its own box with the box keys. `wrap` is `none` (one line, running past the box's edges, centred), `wrap` (break at the box's width; the box takes the wrapped height) or `fit` (one line; the box grows to it). On `mapSpace` it sits at `x`, `y` metres, the same size at every zoom unless `sizeZoom` is `1`.

**On the map itself** (`mapSpace`, API version 6). `line` draws polylines in world metres from the list keys `xs`, `ys`, `starts` (where each unjoined segment starts), `modes` (one per segment, an index into `colors`) and `colors`, with `stroke`, `strokeAlpha`, `strokeWidth` and `strokeZoom` (`0`: the same px at every zoom; `1`: scales with the map). `movie` loads your own small movie from `src` (`"swf/<your folder>/<name>.swf"`). Every map-space drawing also takes `layer` (`under`: above the map tiles and cut off at the map's edge; `over`: above the edge fade), `order`, `alpha`, `view` (only `region` shows), `area` (one area name, such as `AN_NMLandNovigrad`), `preview` (`1`: a copy in the corner overview, for `line` and `movie`), `fadeMs` (`0` to `5000`), `tab`, `tabLabel`, and `listen` with `listenFields` to read data your script already writes to the map menu's flash storage. "Drawing on the map itself" in the guide explains each.

Text targets such as `tag:my_tag` and drawing `pinTag` lists require a known typed tag. A tag claim or an added pin supplies it, or call `CMFDeclareTag("modAcmeIcons", 'my_tag')` without making another claim. CMF resolves it when sending the map data, so the declaration may follow the style. Matching ignores case; an unknown tag matches nothing and is logged once per provider/tag. Releasing your provider removes only its session registrations.


The `pin` part controls highlights, glow and the disabled look through the existing **Pin highlights and glow** choice. `highlightColor` and `glowColor` take RGB colors, including black (0); `highlightAlpha`, `glowAlpha`, `disabledAlpha` and `disabledGrey` take 0 to 1. The disabled defaults are 0.55 opacity and full greyscale. `pulse` takes 0 or 1; `hide` takes comma- or space-separated `highlight`, `glow` and `pulse`. Unset keys retain the game's look. Type and known-tag item styles may use this part too.

If an item has both a numeric tab-id style and a tab-name style for the same key, the numeric id wins. Tab names and pin types use their exact spelling; known tag text is matched without case by the core. Each key falls back from tag to type to the whole part.

## Fold, placement, visibility and screen movies

The tooltip's `foldTag` names an empty `font` marker attribute in your HTML; an empty name disables folding. Marker names use ASCII letters, digits, underscore, dash or colon. `<font fold='1'></font>` starts hidden text and `<font fold='0'></font>` ends it when `foldTag` is `fold`. A lone start folds to the end, and several pairs are allowed. Markers draw nothing. `foldMoreText` and `foldLessText` take literal text or `[[key]]`; `foldKeyKb` and `foldKeyPad` take the game's input action names, resolved to its actual bindings and glyph. `foldOpen` is 0 (initially closed) or 1. No key is intercepted unless the current visible box has folded content; pointer bindings are excluded. The winning provider owns this family through **Info box folding**. Toggling calls `CMFCore.OnInfoFold(menu, provider, open)`; wrap that hook to remember state in your own data. Withdrawal restores the full text and native input.

`clearAnchor` is `cursor` by default or `pin`; pin anchoring measures the selected pin's drawn icon, glow, ring and nonempty label, with a small tolerance. It combines with the existing `tall*` placement keys, and can target one type with `CMFStyle`. `showSeconds`, `hideSeconds` (seconds, zero means immediate), and `slide` (horizontal logical pixels) belong to **Info box motion**; unset restores native timing and position. Property 39 sets width in 200 to 1920 content pixels at 1920 x 1080 units, without wide stretching. Zero withdraws; id 40 can withdraw the same slot. A selected pin's width overrides the every-pin menu default. Width, height and scrolling use **Info box size and scrolling**.

The `tracker`, `legend`, `preview`, `worldButton` and `worldHint` use `x`/`y` offsets and positive `scale`, moving with their parent panel on wide screens. Unset offsets and scale preserve the game's layout. `legendRow`, `legendTab`, `keyCap`, `worldButton`, `worldHint` and `hints` take `font` and `size`; `pinLabel` and `pinName` take `color`. Each belongs to its existing look owner. `crosshair` and `edgePointer` accept the frame glow and hide keys under **Frames and panels**; pointer styling applies to individual glyphs, never the canvas. Tooltip `titleGlow*` and `bodyGlow*` apply the listed glow keys to title and body independently; unset title/body suffixes inherit the same owner's generic glow; with no glow claims, native filters remain.

On `opening`, `revealSeconds` and its `revealLegendSeconds`, `revealTrackerSeconds`, `revealCrosshairSeconds` longhands are one ownership family. On `wide`, `panels`, `panelsLegend`, `panelsTracker` and `panelsPreview` are likewise one family. An unspecified longhand falls back to the winning provider's shorthand, then the native default; another provider cannot fill a missing longhand inside that family. `waitForMap` 1 holds the dark background, legend, tracker, preview and managed hints until the first tile fade, then reveals them with the tiles; 0 or unset keeps native order. Reveal timers start at that fade, while input timing and `readyAtFadeStart` keep their meanings. It belongs to **Opening and closing**, and CMF sets no provider value itself.

Legend `show` is `always` (default) or `auto`; `autoHideMs` sets its idle delay and `padShowFirst` 1 makes the first pad up press reveal it without navigating. Preview `show` is `always` (default), `moving` or `never`; `movingMs` sets the delay after movement stops. These keys share **Panel visibility**. Hidden panels are click-through but remain available to native input. A hidden panel does not occupy a `tallClear` exclusion; showing it never moves an already open box, while the next box samples its current visibility. Unset restores each native child opacity and pointer state.

`image` takes `src` (`img://icons/<your folder>/<name>.png`), `fit` (`stretch`, `contain`, `cover` or `tile`, default `stretch`) and `smooth` (0/1, default 1), plus the box keys on screen or x/y and sizeZoom in map space. Unset keeps the drawing's defaults; removing the drawing releases its loader. `pinType` filters pin-rooted drawings to matching types; `pinTag` matches declared typed names through their nonzero game id. Id 0 never tag-matches. These filters use the normal drawing ownership, not a new claim piece. `withLook` 1 hides a drawing, including one nested through other drawings, while its provider loses the root part's look; 0 is the default. Withdrawal and removal release only that provider's drawing state.

Managed `hints.list` offers a list owner; `OnMapHints(menu, owner)` writes entries to `cmf.map.hints.owned`. Each entry may contain `click` (positive int); activation calls `OnDrawingClicked(menu, owner, 'hints', "hint", value)` once, guarded against key/click duplication. An owner change is checked again at activation. Legacy `cmf.map.hints` stays display-only, and CMF clears only a managed list it wrote. `OnCMFMapTab` and `OnCMFMapHints` forward to core hooks while the legacy events continue firing for older adapters.

Screen `movie` drawings use `cmfScreen(data, map)`, typed `data.text`/`data.number`, `focus` 0/1 and the normal placement keys. See [Your own movie on the screen](own-screen-movie.md) for data, controls, events and cleanup. Script-owned root fields are available through native `SetMemberFlash*` and `GetMemberFlash*`; choose your own names and never overwrite native members. `CMFHasAbility('map', 'rootValues')` discovers that support.

## Every part, kind and key

The tables below are generated by `tools/cmf_author_docs.py` from the lists in `tools/cmf_pack.py` and `cmfCore.ws`; do not edit them by hand.

Revision 13 adds replacement text with the `allText` key and a managed hint offer with the `list` key. It also adds `title.text`, `worldHint.text`, `worldButton.text` and `legend.allText` for replacement text. `hints.list` accepts number 1 to offer a managed hint list, or text `"unset"` to withdraw. `CMFStyle` targets an individual row/tab/pin/area using the grammar in the author guide. The map applies per-item values and dispatches both the new core-owned and legacy adapter events.

<!-- cmf:generated-tables begin -->
### Key groups

- **text keys**: `font` (text), `size`, `color`, `spacing`, `align` (text)
- **glow keys**: `glow1Color`, `glow1Alpha`, `glow1Blur`, `glow1Strength`, `glow2Color`, `glow2Alpha`, `glow2Blur`, `glow2Strength`
- **shadow keys**: `shadowDistance`, `shadowAngle`, `shadowColor`, `shadowAlpha`, `shadowBlur`, `shadowStrength`
- **box keys** (every kind but `line`): `left`, `top`, `right`, `bottom`, `width`, `height`, `widthShare`, `heightShare`, `minWidth`, `minHeight`, `alignX`, `alignY`, `offsetX`, `offsetY`, `minLeft`, `maxRight`, `minTop`, `maxBottom`, `screenLeft`, `screenRight`, `screenTop`, `screenBottom`, `measure` (text), `fill`, `alpha`, `fill2`, `alpha2`, `gradient` (text), `angle`, `curve`, `stroke`, `strokeAlpha`, `strokeWidth`, `layer` (text), `order`, `view` (text), `when` (text), `repeat`, `repeatStep`, `alphaList` (text), `tab` (text), `tabLabel` (text), `click`, `above`, `fillHover`, `alphaHover`, `strokeHover`, `strokeAlphaHover`, `strokeWidthHover`, `colorHover`, `minPartHeight`, `wideAnchor` (text), `pinType` (text), `pinTag` (text), `withLook`, glow keys, shadow keys
- **map-space keys** (`line` and `movie`): `layer` (text), `order`, `alpha`, `view` (text), `area` (text), `preview`, `fadeMs`, `tab` (text), `tabLabel` (text), `listen` (text), `listenFields` (text), `withLook`

"(text)" marks a key whose value goes in the `text` argument.

### Parts and their style keys

| Part | Style keys | `hide` words | Decided by (menu row) |
| --- | --- | --- | --- |
| `screen` | none | none | Map look > Frames and panels |
| `map` | `top`, `bottom`, `panLimit` (text), `centerInLimit`, `backdrop` | none | Map movement > Map area; `backdrop`: Map look > Frames and panels |
| `mapEdge` | `hide` (text) | `edgeFade` | Map look > Frames and panels |
| `title` | text keys, glow keys, `x`, `y`, `screenX`, `screenY`, `wrap` (text), `hide` (text), `text` (text) | `plate` | Map look > Frames and panels |
| `tracker` | glow keys, `nameFont` (text), `nameSize`, `nameColor`, `hide` (text), `x`, `y`, `scale` | `plate` | Map look > Frames and panels |
| `legend` | glow keys, `allText` (text), `x`, `y`, `scale`, `show` (text), `autoHideMs`, `padShowFirst` | none | Map look > Legend; `show`, `autoHideMs`, `padShowFirst`: Map behaviour > Panel visibility |
| `legendRow` | glow keys, `color`, `colorSelected`, `colorOff`, `counterColor`, `hide` (text), `font` (text), `size` | `plate`, `selection`, `arrowPlate` | Map look > Legend |
| `legendTab` | glow keys, `color`, `spacing`, `hide` (text), `font` (text), `size` | `plate`, `selection` | Map look > Legend |
| `tooltip` | glow keys, `titleFont` (text), `titleSize`, `titleColor`, `bodyFont` (text), `bodySize`, `bodyColor`, `hide` (text), `clearMinHeight`, `clearView` (text), `clearSide` (text), `clearCursor`, `clearLeft`, `clearTop`, `clearRight`, `clearBottom`, `x`, `y`, `clearCursorAbove`, `clearCursorBelow`, `clearCursorTitle`, `clearPadX`, `clearPadY`, `clearGap`, `clearBoxPad`, `clearPick`, `clearCursorWeight`, `tallMinHeight`, `tallX`, `tallTop`, `tallBottom`, `tallAltX`, `tallAltTop`, `tallAltBottom`, `tallUnderLegend`, `tallClear`, `showSeconds`, `hideSeconds`, `slide`, `plateColor`, `plateAlpha`, `thumbColor`, `trackColor`, `scrollStep`, `titleCase` (text), `hideScrollBar`, `foldTag` (text), `foldMoreText` (text), `foldLessText` (text), `foldKeyPad` (text), `foldKeyKb` (text), `foldOpen`, `clearAnchor` (text), `titleGlow1Color`, `titleGlow1Alpha`, `titleGlow1Blur`, `titleGlow1Strength`, `titleGlow2Color`, `titleGlow2Alpha`, `titleGlow2Blur`, `titleGlow2Strength`, `bodyGlow1Color`, `bodyGlow1Alpha`, `bodyGlow1Blur`, `bodyGlow1Strength`, `bodyGlow2Color`, `bodyGlow2Alpha`, `bodyGlow2Blur`, `bodyGlow2Strength` | `plate`, `trackedPlate`, `divider` | Map look > Info box; `clearMinHeight`, `clearView`, `clearSide`, `clearCursor`, `clearLeft`, `clearTop`, `clearRight`, `clearBottom`, `x`, `y`, `clearCursorAbove`, `clearCursorBelow`, `clearCursorTitle`, `clearPadX`, `clearPadY`, `clearGap`, `clearBoxPad`, `clearPick`, `clearCursorWeight`, `tallMinHeight`, `tallX`, `tallTop`, `tallBottom`, `tallAltX`, `tallAltTop`, `tallAltBottom`, `tallUnderLegend`, `tallClear`, `clearAnchor`: Map behaviour > Info box moves out of the way; `showSeconds`, `hideSeconds`, `slide`: Map behaviour > Info box motion; `scrollStep`, `hideScrollBar`: Map behaviour > Info box size and scrolling; `foldTag`, `foldMoreText`, `foldLessText`, `foldKeyPad`, `foldKeyKb`, `foldOpen`: Map behaviour > Info box folding |
| `preview` | `hide` (text), `x`, `y`, `scale`, `show` (text), `movingMs` | `frame` | Map look > Frames and panels; `show`, `movingMs`: Map behaviour > Panel visibility |
| `worldButton` | glow keys, `hide` (text), `text` (text), `x`, `y`, `scale`, `font` (text), `size` | `plate` | Map look > Frames and panels |
| `worldHint` | glow keys, `hide` (text), `text` (text), `x`, `y`, `scale`, `font` (text), `size` | `plate` | Map look > Frames and panels |
| `hints` | glow keys, `x`, `y`, `scale`, `align` (text), `list`, `font` (text), `size` | none | Map look > Key hints |
| `keyCap` | glow keys, `color`, `iconColor`, `brackets`, `keyGap`, `labelGap`, `hide` (text), `font` (text), `size` | `plate`, `clickRect` | Map look > Key hints |
| `pinLabel` | shadow keys, `font` (text), `size`, `color`, `rise`, `riseTracked`, `riseOffset`, `riseOffsetTracked` | none | Map look > Pin text style; `rise`, `riseTracked`, `riseOffset`, `riseOffsetTracked`: Map behaviour > Label place and hiding |
| `pinName` | shadow keys, `font` (text), `size`, `color` | none | Map look > Pin text style |
| `navigation` | `frameTimed`, `stepMs`, `worldStepMs`, `maxStepMs`, `crosshairRoam`, `safeLeft`, `safeTop`, `safeRight`, `safeBottom`, `snapSeconds`, `centerSeconds`, `zoomTimed`, `padHoldMs`, `tweenEveryFrame`, `frameRate`, `zoomOutFit`, `edgeOvershoot`, `zoomIn`, `zoomOut`, `zoomStep` | none | Map movement > Pan and zoom feel; `crosshairRoam`, `safeLeft`, `safeTop`, `safeRight`, `safeBottom`, `snapSeconds`, `centerSeconds`, `padHoldMs`: Map movement > Controller crosshair; `zoomOutFit`, `edgeOvershoot`: Map movement > Zoom out to the whole region |
| `markerPanel` | `minLeft`, `maxRight`, `minTop`, `maxBottom` | none | Map look > Frames and panels |
| `pinButton` | text keys, glow keys, `width`, `height`, `curve`, `fill`, `alpha`, `stroke`, `strokeWidth`, `offsetX`, `offsetY` | none | Map look > Pin text style |
| `mapSpace` | none | none | none (an anchor) |
| `opening` | `slideSeconds`, `slideOffset`, `closeSeconds`, `pinsDuringSlide`, `pinStepMs`, `pinBatch`, `pinBudgetMs`, `showDelayMs`, `fadeSeconds`, `tileFadeSeconds`, `revealSeconds`, `readyAtFadeStart`, `revealEase`, `revealLegendSeconds`, `revealTrackerSeconds`, `revealCrosshairSeconds`, `waitForMap` | none | Map movement > Opening and closing |
| `spread` | `on`, `anyPin`, `enterRadius`, `stackDistance`, `gap`, `maxPins`, `openMs`, `closeMs`, `lockRadius`, `keepRadius` | none | Map behaviour > Stacked pins spread out |
| `wide` | `fill`, `panels`, `maxRatio`, `world`, `panelsLegend`, `panelsTracker`, `panelsPreview` | none | Map movement > Fill wide screens |
| `pin` | `highlightColor`, `highlightAlpha`, `glowColor`, `glowAlpha`, `disabledAlpha`, `disabledGrey`, `pulse`, `hide` (text) | `highlight`, `glow`, `pulse` | Map look > Pin highlights and glow |
| `sounds` | `open` (text), `close` (text), `select` (text), `zoom` (text), `tab` (text), `click` (text), `travel` (text) | none | Map look > Map sounds |
| `world` | `crestX`, `crestY`, `nameX`, `nameY`, `text` (text), `font` (text), `size`, `color`, `outlineColor`, `outlineAlpha`, `hide` (text) | `outline`, `names` | Map paintings > Region crests and markers |
| `crosshair` | glow keys, `color`, `alpha`, `scale`, `hide` (text) | `all`, `label` | Map look > Frames and panels |
| `edgePointer` | glow keys, `color`, `alpha`, `scale`, `hide` (text) | `all` | Map look > Frames and panels |

### Drawing kinds and their keys

| Kind | Anchors | Keys | List keys |
| --- | --- | --- | --- |
| `rect` | any part but `mapSpace`, or a drawing | box keys | none |
| `ring` | any part but `mapSpace`, or a drawing | box keys, `inset` | none |
| `ellipse` | any part but `mapSpace`, or a drawing | box keys | none |
| `polygon` | any part but `mapSpace`, or a drawing | box keys, `points` (text), `originX`, `originY` | none |
| `band` | any part but `mapSpace`, or a drawing | box keys, `side` (text), `size`, `sizeZoom`, `minSize`, `maxShare` | none |
| `line` | `mapSpace` only | map-space keys, `stroke`, `strokeAlpha`, `strokeWidth`, `strokeZoom` | `xs`, `ys`, `starts`, `modes`, `colors` |
| `text` | any part, `mapSpace` or a drawing | box keys, `text` (text), `font` (text), `size`, `color`, `align` (text), `wrap` (text), `padding`, `x`, `y`, `sizeZoom`, `area` (text), `fadeMs`, `listen` (text), `listenFields` (text) | none |
| `movie` | any part, `mapSpace` or a drawing | box keys, `area` (text), `preview`, `fadeMs`, `listen` (text), `listenFields` (text), `src` (text), `focus` | any your movie documents |
| `image` | any part, `mapSpace` or a drawing | box keys, `src` (text), `fit` (text), `smooth`, `x`, `y`, `sizeZoom`, `area` (text), `fadeMs` | none |

### Layers

`under`, `over`, `belowMap`, `aboveMap`, `top`
<!-- cmf:generated-tables end -->
