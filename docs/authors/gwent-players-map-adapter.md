# Gwent Players Map on Conjunction Map Framework: the change for its author

This note is for the author of Gwent Players Map (Nexus 13755). It shows how Gwent Players Map's cards, its "Gwent" tab and its large-card option come back on Conjunction Map Framework's (CMF) world map, using the adapter CMF ships as a worked example, [`source/adapters/gwent-players-map/modCMFAdapterGwentPlayersMap`](../../source/adapters/gwent-players-map/modCMFAdapterGwentPlayersMap/).

## Why your cards need anything at all

Only one `panel_worldmap.redswf` loads. When CMF is installed, CMF's map loads instead of yours. Four things in your map file are then missing:

- the card frames you added to the pin sprite;
- the "Gwent" filter tab and its row;
- the call to `OnGwmMapFilter` each time a tab shows;
- the bigger shapes of the large cards.

Your scripts keep running and keep pushing `GwentPlayer`, `GwentPlayerDisabled`, `GwentPlayerLarge` and `GwentPlayerLargeDisabled` pins from your `UpdateEntityPins` wrapper. CMF's map receives them but has nothing to draw them with.

CMF brings all four back without a map file. A mod tells CMF in script what to draw, and CMF's map draws it.

## You used to, now you call

**The card art.** You used to draw each card as a frame of the pin sprite. Now you name an image for each type:

```
CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayer', "img://icons/modcmfadaptergwentplayersmap/card.png");
CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayerDisabled', "img://icons/modcmfadaptergwentplayersmap/card_beaten.png");
CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayerLarge', "img://icons/modcmfadaptergwentplayersmap/card.png");
CMFRegisterIcon("modGwentPlayersMap", 'GwentPlayerLargeDisabled', "img://icons/modcmfadaptergwentplayersmap/card_beaten.png");
CMFRegisterLegendIcon("modGwentPlayersMap", 'GwentPlayer', "img://icons/modcmfadaptergwentplayersmap/card.png");
```

**The tab and its row.** You used to add the category `"Gwent"` at 8 and the four types at 701 to 791 in `HubMapPinPanel`. Now you register them as data (API version 2, property ids 8, 6 and 7), with your own tab id and your own text:

```
CMFRegister("modGwentPlayersMap", 8, 'Gwent', '', "[[map_category_Gwent]]", 8);
CMFRegister("modGwentPlayersMap", 6, 'GwentPlayer', '', "Gwent", 701);
CMFRegister("modGwentPlayersMap", 7, 'GwentPlayer', '', "[[gwm_label_gwent_player]]", 0);
```

**The tab report.** Your map file used to call `OnGwmMapFilter(tab)` first thing in `updatePinsFromCategory`. CMF's map calls `OnCMFMapFilter(tab)` at the same place, for every mod. You pass it on to your own event:

```
@addMethod(CR4MapMenu)
event OnCMFMapFilter(category : string)
{
	OnGwmMapFilter(category);
}
```

Your script then moves the cards onto the players' spots in the "Gwent" tab, as before. CMF names its tabs by their id, so the tab id must stay exactly `Gwent`.

**The large cards.** Your map file drew the large cards about 1.19 times the size of the small ones: 17.6 px high against 14.8 px, in the shapes themselves. Now you claim that size for the two large types (API version 4, property id 10, size in percent):

```
if (CMFHasProperty(10))
{
	CMFRegister("modGwentPlayersMap", 10, 'GwentPlayerLarge', '', "", 119);
	CMFRegister("modGwentPlayersMap", 10, 'GwentPlayerLargeDisabled', '', "", 119);
}
```

The `CMFHasProperty(10)` guard keeps the script compiling on API versions 2 and 3, which skip it and show the small size.

You get the same map as with your own map file. In addition, your cards share the map with every other CMF mod, conflicts are settled by folder order, and no Script Merger is needed.

All of these calls go in one `CR4Game.OnGameStarted` wrapper, after `CMFRequireVersion("modGwentPlayersMap", 2)`. The tab is the point of the change, so register nothing on API version 1. The [adapter's script](../../source/adapters/gwent-players-map/modCMFAdapterGwentPlayersMap/content/scripts/local/modcmfadaptergwentplayersmap_cmf.ws) is the whole thing.

## Shipping it yourself

Ship it as an optional "CMF support" folder next to your mod. It must stay separate, because a CMF call fails to compile when CMF is not installed:

```
Mods/
  modGwentPlayersMapCMF/                        any folder name of yours, starting with "mod"
    README.txt
    content/texture.cache                       your card art, built by CMF's pack tool
    content/scripts/local/modgwentplayersmapcmf_cmf.ws
```

- **Provider.** Keep `modGwentPlayersMap` as the first argument of every call. A claim made in your mod's folder name counts the same as your mod, so folder order between mods stays as it is without CMF. It also means that your folder and the adapter give the same result.
- **Art.** Export your two cards as square PNGs, 96 x 96 recommended, transparent background, with the outer 4 pixels empty ([icon pack guide](icon-pack-guide.md#4-make-your-art)). Name them `card.png` and `card_beaten.png`, and point the image paths at your folder: `img://icons/<your folder in lower case>/card.png`.
- **Build.** Run `python tools/cmf_pack.py build path/to/modGwentPlayersMapCMF --adapts modGwentPlayersMap --out path/to/new-folder` from the CMF repository. It cooks your PNGs into the folder's own `texture.cache`. It warns that the Gwent names are not 5.01 pin types; that is expected, because they are yours.
- **Install order.** Your support folder calls your `OnGwmMapFilter`. Players install and remove it together with your mod, and remove it first. Players who used CMF's adapter for your mod must uninstall it when they install your support folder, or the game stops at the script compile screen (both add `OnCMFMapFilter`).

## What already works

These come from your own scripts, unchanged under CMF:

- the card positions, and the merchant cards next to the shops outside the "Gwent" tab;
- the tooltips, and the beaten and unavailable status;
- your options, including "Card size".

## Status

- The cards and the tab passed in game on 2026-10-20 (launch S2-1) and ran again with API version 4 in the N4 launch.
- Adapter 0.2 passed with API version 5 the same day (launch C5): the tab report under its API version 4 name, and the large cards, about 1.2 times the small ones on screen.
- The art is your own: since adapter 1.0.1 its `texture.cache` carries your two cards, white and grey once the player is beaten, shipped with your permission (2026-10-21) and credited in its README. Up to 1.0.0 it drew placeholders of its own. CMF itself carries none. The adapter is a stand-in until you publish your own CMF support folder, which loads your art the same way.

## Can CMF do this without the author?

Yes, and that is what the adapter is. It uses only the names your mod already sends (types, tab id, string keys and the event name), copies none of your code, and loads your card art, shipped with your permission, through CMF, as your CMF support would.
