# Ink and Iron on Conjunction Map Framework: the change for its author

This note is for the author of Ink and Iron. It shows how Ink and Iron's map comes back on Conjunction Map Framework's (CMF) world map through CMF's general calls. The worked example is the adapter CMF ships, [`source/adapters/ink-and-iron/modCMFAdapterInkAndIron`](../../source/adapters/ink-and-iron/modCMFAdapterInkAndIron/).

CMF has no Ink and Iron calls of its own. Every call below is one any mod can use, and a theme with a completely different look uses the same calls.

## Why the map changes under CMF

Only one `panel_worldmap.redswf` loads. When CMF is installed, CMF's map loads instead of yours. Everything else of Ink and Iron loads as normal: its HUD, compass, menus, fonts and the rest.

Your scripts keep running, but they write to your own map file's names, which CMF's map does not answer:
- the quest level: `iaiLv`/`iaiDiff`;
- the hint list: `inkiron.map.hints`.

Your look is code in your map file, so it does not load either. That code is `MapMenu.ink*`, `iiFrame`, `HubMapContainer.inkEdge` and the rest.

## What you get from CMF

Through CMF your map's look and level tags sit beside the pins, legend rows and labels of other map mods: Map Quest Insight, Witcher Gear Map, Gwent Players Map and any pack. When two mods change the same thing, a documented order decides. Today Ink and Iron cannot run with any other mod that replaces the world-map file.

## 1. Quest-level tags

**You used to** write `iaiLv` and `iaiDiff` into each quest pin in `inkironui_questlevel.ws`, and draw the tag in your map file (`StaticMapPinDescribed.iaiLvTab`).

**Now** wrap CMF's "pin is ready" hook. Give the pin its label with `CMFStylePinLabel`, and the label's colour with pin property 17 (`LabelColor`):

```
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var level : int;
	wrappedMethod(dataObject, mapContext);
	level = dataObject.GetMemberFlashInt("iaiLv");
	if (level > 0 && dataObject.GetMemberFlashBool("isQuest"))
	{
		CMFStylePinLabel("modInkAndIronUI", dataObject, "Lv " + IntToString(level));
		CMFStylePin("modInkAndIronUI", dataObject, CMFPropertyLabelColor(), "",
			InkAdapterTagColor(dataObject.GetMemberFlashInt("iaiDiff")));
	}
}
```

`InkAdapterTagColor` returns your four colours: #8A8578, #EFE6CF, #E0893A and #D0402F.

The plate, the 2 px bar and the gold border of a tracked pin are drawings on CMF's `pinLabel` part (section 3). The bar's `fill` is `label`, which means the label's own colour.

Your option "Quest levels on world map pins" works as before: with it off, `iaiLv` is 0 and nothing is added.

## 2. The key-hint row

**You used to** write the bindings to `inkiron.map.hints` and draw them in your map file, sent again when your movie called `OnInkMapHintsReady`.

**Now** write the same list to `cmf.map.hints`, and answer `OnCMFMapHintsReady` instead of `OnInkMapHintsReady`. Keep your fade of the game's row.

CMF's row already sits at your place, size and glow, so it needs no style call. If you wanted it elsewhere, `CMFStylePart(provider, 'hints', 'x', "", px)` and its `y`, `scale` and `align` keys move it.

## 3. The look

**You used to** draw your look in your copy of the world-map file.

**Now** register the same values from your `OnGameStarted` wrapper, after `CMFRequireVersion("modInkAndIronUI", 5)`. Three calls do it all:

| Call | What it does |
|---|---|
| `CMFStylePart(provider, part, key, text, number)` | styles a fixed part of the map: fonts, colours, spacing, glows, hiding the game's plates, the map area, the title's place, navigation |
| `CMFDraw(provider, anchor, id, kind)` | makes a drawing (`rect`, `ring`, `ellipse`, `polygon`, `band`) tied to a part, or to another drawing by its id |
| `CMFDrawSet(provider, id, key, text, number)` | sets one key of that drawing: its place against the anchor's box, its paint, its layer and order, and when it shows |

For example, the region title and its diamond:

```
CMFStylePart("modInkAndIronUI", 'title', 'font', "$TitleFont", 0);
CMFStylePart("modInkAndIronUI", 'title', 'size', "", 27);
CMFStylePart("modInkAndIronUI", 'title', 'color', "", 14537403);	// 0xDDD2BB
CMFStylePart("modInkAndIronUI", 'title', 'spacing', "", 5);
CMFStylePart("modInkAndIronUI", 'title', 'align', "left", 0);
CMFStylePart("modInkAndIronUI", 'title', 'wrap', "none", 0);
CMFStylePart("modInkAndIronUI", 'title', 'screenX', "", 56);
CMFStylePart("modInkAndIronUI", 'title', 'screenY', "", 140);
CMFStylePart("modInkAndIronUI", 'title', 'hide', "plate", 0);
CMFDraw("modInkAndIronUI", 'title', 'inkTitleMark', 'polygon');
CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'originY', "", 0.5);
CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'points', "-14,-5 -9,0 -14,5 -19,0", 0);
CMFDrawSet("modInkAndIronUI", 'inkTitleMark', 'fill', "", 13214812);	// 0xC9A45C
```

And one ring of your frame round the tracker, here the inner gold line:

```
CMFDraw("modInkAndIronUI", 'tracker', 'inkTrackerInner', 'ring');
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'left', "", 16);	// px outside the measured box
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'top', "", 16);
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'right', "", 16);
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'bottom', "", 16);
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'inset', "", 1);
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'fill', "", 11832388);	// 0xB48C44
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'alpha', "", 0.55);
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'layer', "under", 0);
CMFDrawSet("modInkAndIronUI", 'inkTrackerInner', 'order', "", 43);
```

CMF measures each part the way your `inkTextBounds` does: visible text trimmed to its width plus 8, plus the icons and arrows. Your frames therefore fit long quest names and other languages as they do on your map.

| Your look (your member) | CMF part and calls in the adapter |
|---|---|
| Full-height map, ink backdrop, pan limit, centring (`inkEdgeFill`, `inkViewport`, `inkLim`) | `map`: `top`, `bottom`, `backdrop`, `panLimit` screen, `centerInLimit` |
| Edge fade (`HubMapContainer.inkEdge`) | `mapEdge`: `hide` edgeFade; four `band` drawings |
| Top and side fades (`inkTopFade`, `inkCreateOverlay`) | three `rect` drawings on `screen`, layer `aboveMap` |
| Frames round the tracker, the legend and, on the world view only, the tooltip (`iiFrame`) | a shadow `ring` repeated 28 times (`repeat`, `repeatStep`, `alphaList`), a fill `rect`, 12 sheen `rect`s and three `ring` lines on each part. The tooltip's have `view` world, and the tracker's are clamped at `maxRight` 1912 |
| Text glow, fonts and colours (`inkShadow`, `inkTrackerCard`, `TooltipMap`) | `glow1…`/`glow2…`, `nameFont`, `titleFont`, `bodyFont` and the colours on `tracker`, `tooltip`, `legend`, `legendRow`, `legendTab`, `worldHint`; the button glow on `worldButton` |
| Legend (`inkLegendPanel`, `setColoredText`) | `legendRow` colours and `hide`; a graded `rect` and a diamond `polygon` with `when` selected; the tab's spacing and its underline |
| Corner overview (`inkFrame3`) | `preview`: `hide` frame; two `ring` lines and four `ellipse` dots |
| Key caps (`inkSyncCap`, `KeyboardButtonIcon`) | `keyCap`: `brackets` 0, `color`, `iconColor`, `keyGap`, `labelGap`, glows |
| Level-tag plate (`iaiLvTab`) | `pinLabel`: font, `rise`/`riseOffset` and their tracked pair, group shadow; plate, bar and tracked border drawings |
| Custom-marker panel kept on screen (`enableUserPinPanel`) | `markerPanel`: `minLeft`, `maxRight`, `minTop`, `maxBottom` |
| Frame-timed pan and zoom, controller crosshair (`HubMap`, `UniverseMap`) | `navigation` keys (section 4) |

The adapter's script has every call, with the member each value came from.

## 4. Map movement

**You used to** change your map file's timers: `HubMap` and `UniverseMap` run on `Timer(1)`, `handleScrollAndZoomTimer` scales key and stick panning by the time since the last tick over 17 ms (24 ms on the world view, gaps capped at 100 ms), your zoom keeps one step per 17 ms through its own counter, and your movie's header says 60 frames a second.

**Now** describe the same choices as `navigation` keys from the same `OnGameStarted` wrapper. CMF 5 already accepts the first four; CMF 6's map acts on all of them. Ask for each key CMF 6 added with `CMFHasAbility`, so your folder still loads on CMF 5:

```
CMFStylePart("modInkAndIronUI", 'navigation', 'frameTimed', "", 1);
CMFStylePart("modInkAndIronUI", 'navigation', 'stepMs', "", 17);
CMFStylePart("modInkAndIronUI", 'navigation', 'worldStepMs', "", 24);
CMFStylePart("modInkAndIronUI", 'navigation', 'maxStepMs', "", 100);
if (CMFHasAbility('navigation', 'zoomTimed'))
{
	CMFStylePart("modInkAndIronUI", 'navigation', 'zoomTimed', "", 0);
}
if (CMFHasAbility('navigation', 'padHoldMs'))
{
	CMFStylePart("modInkAndIronUI", 'navigation', 'padHoldMs', "", 0);
}
if (CMFHasAbility('navigation', 'frameRate'))
{
	CMFStylePart("modInkAndIronUI", 'navigation', 'frameRate', "", 60);
}
```

`zoomTimed` 0 (one zoom step per `stepMs`) and `padHoldMs` 0 (each stick reading used once) are the game's values, but they are your choices too, so send them: each movement key is won on its own by the earliest folder that sets it, and a key you leave unset can be taken by a later smooth-map mod. Your controller crosshair (`inkSafe`, `inkPan`, `inkRingGo`) is the keys `crosshairRoam`, `safeLeft`, `safeTop`, `safeRight`, `safeBottom`, `snapSeconds` and `centerSeconds`.

You change nothing in how the map opens or closes and draw no button beside a pin, so you need no `opening` key and no `pinButton` style. The author guide's "Smooth map movement" (section 5 of [`icon-pack-guide.md`](icon-pack-guide.md)) lists every key.

## The change for you

You can make the adapter unnecessary with an optional "CMF support" folder of your own:

```
Mods/
  modInkAndIronCMF/                            any folder name of yours, starting with "mod"
    README.txt
    content/scripts/local/zz_modinkandironcmf_cmf.ws
```

It stays a separate folder, because a CMF call fails to compile when CMF is not installed. Players without CMF install Ink and Iron as today; players with CMF add the folder.

Two ways to write it:
- **Copy the adapter's script.** Keep `modInkAndIronUI` as the provider, so your folder order stays the same.
- **Move your own calls.** Write `cmf.map.hints` beside `inkiron.map.hints`, and call `CMFStylePinLabel` in your quest-level code where you write `iaiLv`.

`tools/cmf_pack.py check <your folder> --adapts modInkAndIronUI` checks the folder with your main folder's name as the provider.

When you ship it, players uninstall the adapter; say so in your README. If both are installed, the game stops at the script compile screen, because both add the same `OnCMFMapHintsReady` event to the map menu; removing the adapter fixes it. That is expected, not a fault of either mod.

The adapter targets Ink and Iron 0.8.8 (0.8.7 has the same map file and the same scripts it calls). Check its names again when you change `InkGatherHints`, `iaiLv` or `iaiDiff`.

## Two of your map's glitches that CMF does not copy

- **Region title.** Your title field keeps the game's line wrap, so a long region name is cut at a word ("VELEN - NO") and the diamond sits low. The adapter keeps the title on one line (`wrap` `none`). `wrap` `keep` gives the game's wrapping back if you want it.
- **Legend list.** Rows can briefly show above your legend frame after the mouse passes over it. CMF's frame always wraps every row it shows.
