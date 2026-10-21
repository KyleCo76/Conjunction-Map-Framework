# Witcher's Path on Conjunction Map Framework: the change for its author

This note is for the author of Witcher's Path (Nexus 13423). It shows how the route, the WITCHER'S PATH tab and the four boxes above the filter selector come back on Conjunction Map Framework's (CMF) world map, using the adapter CMF ships as a worked example, [`source/adapters/witchers-path/modCMFAdapterWitchersPath`](../../source/adapters/witchers-path/modCMFAdapterWitchersPath/).

The adapter targets Witcher's Path 1.0.3 and CMF API version 6 with drawing on the map itself. It ran in game on 2026-10-20: the route, the tab, the boxes, both clicks and the first route all worked.

## Why your route needs anything at all

Only one `panel_worldmap.redswf` loads. When CMF is installed, CMF's map loads instead of yours, so everything your map file draws is missing:

- the route line in `HubMapContainer`, just above the map tiles;
- the WITCHER'S PATH filter tab, on which only Geralt shows;
- "Erase path", the distances, the "Single color" switch and the colour legend above the selector, and the two clicks that call `OnWitchersPathClearRequest` and `OnWitchersPathUseGeneralColor`.

Your scripts keep running. Your recorder records, and `WitchersPathSend` keeps writing the shown region's route to `worldmap.witcherspath`; nothing listens.

## You used to, now you call

You describe what to draw; CMF's map draws it, beside every other CMF mod's pins and drawings. All calls go in one function, called from a `CR4Game.OnGameStarted` wrapper and again from a `CR4MapMenu.OnConfigUI` wrapper before `wrappedMethod()`, so a change in your options shows at the next opening, as in your mod. It reads your options with your own `WitchersPathGetVar`/`WitchersPathGetInt` (`WPEnabled`, `WPThickness`, `WPColor*`) and your switch from `witchersPathData.useGeneralColor`, as your `WitchersPathSendConfig` does. Ask first:

```
if (!CMFRequireVersion("modWitchersPath", 6) || !CMFHasAbility('mapSpace', '') || !CMFHasAbility('line', 'listen'))
{
	return;
}
```

**The route.** You used to draw it in your map file from the object you send. Now you keep sending it exactly as you do, and tell CMF which drawing reads it. A `line` drawing on `mapSpace` takes `xs`, `ys`, `starts` and `modes` from your object's fields of the same names, and redraws whenever you send again (a region change, an erase):

```
CMFDraw("modWitchersPath", 'mapSpace', 'witchersPathRoute', 'line');
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'listen', "worldmap.witcherspath", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'layer', "under", 0);	// above the map tiles, below every pin
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'order', "", 10);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'view', "region", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'tab', "WitchersPath", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'tabLabel', "Witcher's Path", 0);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeWidth', "", (float)WitchersPathGetInt('WPThickness', 4));
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeAlpha', "", 0.9);
CMFDrawSet("modWitchersPath", 'witchersPathRoute', 'strokeZoom', "", 0);	// the same px width at every zoom
CMFDrawSetList("modWitchersPath", 'witchersPathRoute', 'colors', colors);	// foot, horse, boat, indexed by your modes
```

Ends and joints are round. The line's opacity follows the map tiles' fade-in, as yours did. Your `perf` steps are not needed: CMF draws the line its own way.

**The tab.** You used to add `WitchersPath` in your `HubMapPinPanel` with no pins. Now the drawings' `tab` key names it: a drawing with `tab` shows only while that tab is selected, and because no pin makes the tab, CMF adds it last, labelled with `tabLabel`, and shows no pins on it but Geralt. There is no legend call to make.

**The boxes.** You used to draw four boxes in your map file. Now each is a `text` drawing that paints its own box, stacked upward with `above` from `legendTab` (the filter selector), at its width:

```
CMFDraw("modWitchersPath", 'legendTab', 'witchersPathErase', 'text');	// the lowest box
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'text', WitchersPathLoc("wp_erase_path", "Erase path"), 0);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'font', "legendTab", 0);	// the tab name's font
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'size', "", 22);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'color', "", 16777215);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'fill', "", 0);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'alpha', "", 0.6);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'stroke', "", 5921370);	// 0x5A5A5A
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'strokeAlpha', "", 0.6);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'strokeWidth', "", 1);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'padding', "", 6);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'widthShare', "", 1);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'above', "", 6);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'minHeight', "", 38);	// every box
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'click', "", 1);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'strokeHover', "", 15251548);	// 0xE8B85C
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'strokeAlphaHover', "", 0.9);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'colorHover', "", 15251548);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'alphaHover', "", 0.8);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'tab', "WitchersPath", 0);
CMFDrawSet("modWitchersPath", 'witchersPathErase', 'view', "region", 0);
```

From the selector up, as your `updateWitchersPathUi` stacks them: "Erase path" (`click` 1, on `legendTab`), the distances, the switch (`click` 2), and on top the legend (game HTML, one `<font color>` per mode word, four spaces apart). The distance box reads your two texts from the same object you send: `listen` `"worldmap.witcherspath"` with `listenFields` `"text=regionText|totalText"`. While single colour is on, withdraw the legend (`CMFDraw("modWitchersPath", 'witchersPathSingle', 'witchersPathLegend', '')`); the three boxes below it stay where they are.

**The clicks.** You used to call your two events from your map file. Now CMF calls its hook `OnDrawingClicked` for every click on a drawing you own, with the map menu, and you call them yourself:

```
@wrapMethod(CMFCore)
function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
{
	if (provider != "modWitchersPath")
	{
		return wrappedMethod(menu, provider, id, input, value);
	}
	if (value == 1)
	{
		menu.OnWitchersPathClearRequest();
	}
	else if (value == 2)
	{
		// WpAdapterSingle() reads witchersPathData.useGeneralColor, where you keep the choice.
		menu.OnWitchersPathUseGeneralColor(!WpAdapterSingle());
		WpAdapterDraw(WpAdapterSingle());	// the colours, the switch text, the legend
		CMFMapRefresh();	// redraws the open map; tab, pan and zoom stay
	}
	return true;
}
```

**The first route.** Your `SwitchToHubMap` wrapper sends the first region's route while the map is still opening, before CMF's map listens, and a value written then never arrives. CMF calls its hook `OnMapListening` as soon as its map starts listening; send once more from it:

```
@wrapMethod(CMFCore)
function OnMapListening(menu : CR4MapMenu, keys : string)
{
	wrappedMethod(menu, keys);
	if (menu && StrFindFirst("|" + keys + "|", "|worldmap.witcherspath|") >= 0)
	{
		menu.WitchersPathSend(true);
	}
}
```

Your popup, erase and `WitchersPathSend(true)` stay as they are; after an erase or a region change the route and distances redraw on their own, because CMF listens to your key. The choice stays in your save data, where your event puts it. The [adapter's script](../../source/adapters/witchers-path/modCMFAdapterWitchersPath/content/scripts/local/modcmfadapterwitcherspath_cmf.ws) is the whole thing.

You get the same route, tab and boxes as with your own map file. In addition, they share the map with every other CMF mod, conflicts are settled by a documented order, and no Script Merger or map merge is needed.

## Who wins, and what stays yours

- **Ids and order.** Every call names your folder, `modWitchersPath`, as provider, so folder order between mods stays as it is without CMF. A drawing id belongs to the earliest folder that made it; another folder's calls on it are refused and logged. In map space, lower `order` draws first, then the earlier folder is on top; the route's 10 keeps it above a drawing left at 0.
- **Clicks** on a drawing go only to its owner, so no other mod's click handler sees yours.
- **Yours, unchanged:** the recorder and its save data, the region rules, the distance maths and texts, your settings, the popup, the saved colour choice.

## Shipping it yourself

Ship it as an optional "CMF support" folder next to your mod. It must stay separate, because a CMF call fails to compile when CMF is not installed:

```
Mods/
  modWitchersPathCMF/                         any folder name of yours, starting with "mod"
    README.txt
    content/scripts/local/modwitcherspathcmf_cmf.ws
```

- **Provider.** Keep `modWitchersPath` as the first argument of every call, so your folder and the adapter give the same result.
- **No art.** Everything is drawn from your numbers; there is no `texture.cache`.
- **Check.** Run `python tools/cmf_pack.py check path/to/modWitchersPathCMF --adapts modWitchersPath` from the CMF repository. It notes that the folder needs CMF 6.
- **Tell players** to uninstall CMF's adapter when they install your CMF support. The two are not meant to run together: with both installed the game may stop at the script compile screen, and removing the adapter fixes it. Both make the same drawings under the same name, so your folder alone gives the same result.

## What has not been checked

- Proton.
