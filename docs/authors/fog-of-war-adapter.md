# Fog of War on Conjunction Map Framework: the change for its author

This note is for the author of Fog of War (Nexus 13627). It shows how Fog of War's pin hiding can reach every pin on Conjunction Map Framework's (CMF) world map, using the adapter CMF ships as a proof of concept, [`source/adapters/fog-of-war/modCMFAdapterFogOfWar`](../../source/adapters/fog-of-war/modCMFAdapterFogOfWar/).

## What changes under CMF

Only one `panel_worldmap.redswf` loads, and CMF's sorts first, so your clouds do not draw under CMF. CMF will not draw them for you, because they are your artwork; they stay missing until you port them. CMF 1.0.0 gives you the way to port them: move your cloud drawing code into a small movie of your own and hand it your grid and settings as a `movie` drawing on `mapSpace` ([Drawing on the map itself](icon-pack-guide.md#drawing-on-the-map-itself-api-version-6)); that use has not yet run in game. Your scripts keep running, so `FogOfWarFilterPins` still removes the pins under fog. It only sees the pins added inside your `UpdateEntityPins` wrapper, though: a mod whose script file sorts after `modFogOfWarMap.ws` and pushes pins there (Witcher Gear Map's `wgm.ws`) adds them after your filter ran, so they show through the fog. That is true without CMF too.

CMF API version 3 offers a hide that applies to every pin, decided in one place after all wrappers have run:

```
function CMFStylePin(provider : string, dataObject : CScriptedFlashObject, propertyId : int, text : string,
	number : int) : bool
```

With `propertyId` 9 (`Hidden`), `text` `""` and `number` 1, CMF marks the pin and removes it from the list before the map receives it, so counts, cycling, the overview and the quest list's "show on map" stay consistent, exactly as your removal does. `CMFHasProperty(9)` tells whether the installed CMF has it.

## What the adapter does

One `UpdateEntityPins` wrapper in a file named to sort last (`zz_modcmfadapterfogofwar_cmf.ws`). It puts every pin of the finished list into one scratch array, each followed by a shared marker your travel-point rule always keeps, calls your `FogOfWarFilterPins(scratch, 0)` once, and hides through CMF each pin your filter dropped. Your rule decides everything: explored cells, reach, the tracked quest, travel points, hints and remote discoveries, and your on/off option (`FogOfWarEnabled`).

Because it calls your functions, the adapter compiles only with Fog of War 1.2.1 installed, and players install and remove the two together.

## The quick change for you

An optional "CMF support" folder of your own can replace the adapter: the same script with the provider id `modCMFAdapterFogOfWar` replaced by your folder name. A simpler form is possible on your side, because you own the filter: in a wrapper that sorts last, call your per-pin test directly and `CMFStylePin(yourFolder, obj, 9, "", 1)` where you now call `RemoveElement`, with no scratch array. It must stay a separate folder, because a CMF call fails to compile when CMF is not installed.

## What does not come back this way

The clouds over the map and the overview, and your `OnFogOfWar*` events. They stay missing until you port them: CMF does not draw another mod's artwork.
