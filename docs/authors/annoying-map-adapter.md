# Annoying Map on Conjunction Map Framework: the change for its author

This note is for the author of Annoying Map (Nexus 6140). It describes Annoying Map 3.1 for Remastered 5.01, the version the adapter targets. It shows how Annoying Map's remembered map comes back on Conjunction Map Framework's (CMF) world map through CMF's general calls. The worked example is the adapter CMF ships, [`source/adapters/annoying-map/modCMFAdapterAnnoyingMap`](../../source/adapters/annoying-map/modCMFAdapterAnnoyingMap/).

CMF has no Annoying Map calls of its own. Every call below is one any mod can use.

## Why the map changes under CMF

Only one `panel_worldmap.redswf` loads. When CMF is installed, CMF's map loads instead of yours. Your scripts load as normal, and most of Annoying Map needs nothing: Geralt's marker, Roach and the boat only at signposts, and no herbs are done in your own `mapMenu.ws` and work beside CMF as they are.

One feature breaks, because it needs three reports that only your map file sends:

| Annoying Map on its own | Under CMF without the adapter |
|---|---|
| Your map file sends `OnPositionChanged(x, y)` on every pan and `OnZoomChanged(scaleX, scaleY)` on every zoom; your script keeps them per region in the save (`AMap()`, `AMapZoom()`, keyed by `AM_FilterArea`) | CMF's map sends neither, so nothing new is remembered |
| `UpdateDefaultPosition` sends the saved place through the game's default-position call | still works: CMF's map uses that call as the game's does |
| `AM_InitZoom` sets the lowest and highest zoom to the saved zoom, so the map opens at it; your map file sends `OnZoomMap` on the first zoom key, which puts the real limits back | nothing sends `OnZoomMap`, so a region with a saved zoom stays stuck at that zoom |

## You used to do this; now you call this

CMF 1.3.0 (API version 9) reports the map's view and lets a mod choose the view a region map opens with. The author guide's "The map's view" (section 5 of [`icon-pack-guide.md`](icon-pack-guide.md)) describes both.

| Your map file used to | Now |
|---|---|
| send `OnPositionChanged` and `OnZoomChanged` | wrap `CMFCore.OnMapView(menu, area, x, y, worldX, worldY, zoom, reason)` and store `x`, `y` and `zoom` with your own `AMap().SetXY` and `AMapZoom().SetXY` |
| send `OnZoomMap` on the first zoom key | wrap `CMFCore.OnMapOpening(menu, area, mapContext)` and call your own `menu.OnZoomMap()` there, once `menu.am_maxZoom` is above 0 |
| open the region at the zoom `AM_InitZoom` set | in the same wrapper, `CMFSetOpeningView("modAnnoyingMap", area, 0, 0, savedZoom, true)` |

```
@wrapMethod(CMFCore)
function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float,
	zoom : float, reason : name)
{
	wrappedMethod(menu, area, x, y, worldX, worldY, zoom, reason);
	if (area == '' || area == 'AN_Undefined')
	{
		return;
	}
	AMap().SetXY(x, y, AM_FilterArea(area));
	if (zoom > 0)
	{
		AMapZoom().SetXY(zoom, zoom, AM_FilterArea(area));
	}
}

@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	wrappedMethod(menu, area, mapContext);
	if (!menu || area == '' || area == 'AN_Undefined')
	{
		return;
	}
	// am_maxZoom is 0 until your UpdateMapSettings has run once; sending zero limits would break the map.
	if (menu.am_maxZoom > 0)
	{
		menu.OnZoomMap();
	}
	// 0 = no saved zoom: the game's zoom. keepPlace true: your script already sent the place.
	CMFSetOpeningView("modAnnoyingMap", area, 0, 0, AmAdapterSavedZoom(area), true);
}
```

`AmAdapterSavedZoom` is a few lines in the adapter that read `AMapZoom().GetXY(AM_FilterArea(area))` and return its first number, or 0 when the region has none, as your `AM_InitZoom` reads it.

- **Same units.** `x` and `y` are the map's place in the units your `OnPositionChanged` sent, and `zoom` the map's scale, as your `OnZoomChanged` sent it, so your storage takes them unchanged.
- **When the report comes.** `reason` is `'still'` when the map stopped moving for a quarter of a second, `'region'` when it switches region (the report is for the region being left, under its own name), and `'close'` when the map closes. So nothing runs per frame: one store per report and one call per region shown.
- **The real limits come back first.** `OnMapOpening` fires each time a region map is shown, at the opening and on every region switch, after your script has sent that region's narrowed limits. Your own `OnZoomMap` then sends the real ones, and CMF opens the region at your saved zoom inside them, so the zoom can never get stuck.
- **Your name in CMF's menu.** `CMFSetProviderName("modAnnoyingMap", "Annoying Map")` in an `OnGameStarted` wrapper shows your mod by name on the menu add-on's Opening view row (under Movement). With Vanilla on that row, your script still sets the saved place, and the zoom is the game's.

Every call names `modAnnoyingMap`, your own folder, as its provider, so folder order between mods is the same with CMF as without it. The adapter copies no code and ships no art.

## The change for you

You can make the adapter unnecessary with an optional "CMF support" folder of your own:

```
Mods/
  modAnnoyingMapCMF/                           any folder name of yours, starting with "mod"
    README.txt
    content/scripts/local/zz_modannoyingmapcmf_cmf.ws
```

It stays a separate folder, because a CMF call fails to compile when CMF is not installed. Players without CMF install Annoying Map as today; players with CMF add the folder. Copy the adapter's script: it already uses your folder name and your own functions.

`tools/cmf_pack.py check <your folder> --adapts modAnnoyingMap` checks the folder with your main folder's name as the provider.

When you ship it, players uninstall the adapter; say so in your README. With both installed the game may stop at the script compile screen (the same function names twice); removing the adapter fixes it. That is expected, not a fault of either mod.

The adapter targets Annoying Map 3.1. Check its names again when you change `AMap`, `AMapZoom`, `AM_XYs`, `AM_FilterArea`, `OnZoomMap` or `am_maxZoom`.

## Tested

The adapter ran in game in the CMF 1.3.0 launch (2026-10-23) with Annoying Map 3.1: the map reopened where it was left, at the same zoom, also after switching between regions, and both ends of the zoom range stayed reachable. The stuck zoom it prevents is read from your code, not seen in a launch, because the launch ran with the adapter installed.
