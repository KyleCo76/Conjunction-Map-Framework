# Smooth Map on Conjunction Map Framework: the change for its author

> [!NOTE]
> **Proof-of-concept example, not a shipped adapter.** This adapter is not part of any CMF release and is not on Nexus. It is published here only as a worked example for Smooth Map's author. Its keys ran in game together with Ink & Iron, which won the movement keys it also sets; Smooth Map's values on their own, without Ink & Iron, have not been checked in a launch.

This note is for the author of Smooth Map (Nexus 13530). It describes Smooth Map 1.1, the version the adapter targets. It shows how Smooth Map's smoother movement and faster opening come back on Conjunction Map Framework's (CMF) world map, using the proof-of-concept adapter published here as a worked example (it is not part of any CMF release), [`source/adapters/smooth-map/modCMFAdapterSmoothMap`](../../source/adapters/smooth-map/modCMFAdapterSmoothMap/).

## What changes under CMF

Only one `panel_worldmap.redswf` loads, and CMF's sorts first, so your map file does not load under CMF and its timing is lost. Every other map mod that ships its own map file has the same problem with yours today: only one of them works.

CMF API version 6 makes the map's movement and opening settings you describe in script, and CMF's own map carries them out. You no longer edit the map file; you call:

```
function CMFStylePart(provider : string, part : name, key : name, text : string, number : float) : bool
```

with the part `navigation` (how the map moves) or `opening` (how it opens), a key, `""` as the text and the value as the number. Each key is won on its own by the earliest mod folder that sets it, so your values and another mod's mix key by key instead of one map file replacing the other.

## You used to do this; now you call this

| In your map file | Now |
|---|---|
| `Timer(1)` for the region map, pan scaled by elapsed / 17 ms | `CMFStylePart("modSmoothMap", 'navigation', 'frameTimed', "", 1)` and `'stepMs'` 17 |
| `Timer(1)` for the world view, scroll by elapsed / 24 ms | `'worldStepMs'` 24 |
| elapsed time capped at 100 ms | `'maxStepMs'` 100 |
| zoom as a power of elapsed time | `'zoomTimed'` 1 |
| each stick reading used once | `'padHoldMs'` 0 |
| `Timer(1)` in `GTween.staticInit` | `'tweenEveryFrame'` 1 |
| pins prepared during the slide-in on a 1 ms timer | `'opening'`, `'pinsDuringSlide'` 1 and `'pinStepMs'` 1 |
| as many pins as fit in 8 ms per tick | `'pinBatch'` 0 and `'pinBudgetMs'` 8 |
| show delay 1 ms, fades 0.2 s and 0.2 s | `'showDelayMs'` 1, `'fadeSeconds'` 0.2, `'tileFadeSeconds'` 0.2 |
| crosshair, edge pointers, legend and tracker fade in over 0.2 s | `'revealSeconds'` 0.2 |

Your `smSlideOffset` correction and your snap fix need no call: CMF's map does both whenever pins are prepared during the slide-in. Send even the keys equal to the game's value (`stepMs` 17, `worldStepMs` 24, `padHoldMs` 0): they are your choices, and a mod that stays silent on a key loses it to any other mod that sets it.

The whole adapter is one block, run once per game session:

```
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modSmoothMap", 6))
	{
		CMFStylePart("modSmoothMap", 'navigation', 'frameTimed', "", 1);
		CMFStylePart("modSmoothMap", 'navigation', 'stepMs', "", 17);
		// ... and the other 13 keys of the table above
	}
	return result;
}
```

The provider is your own folder name, `modSmoothMap`, so folder order between mods is the same with CMF as without it. On a key that Ink & Iron (`modInkAndIronUI`) or Map Quest Insight (`modMapQuestInsight`) also sets, they win, as their map files would have replaced yours; your other keys still apply.

## The quick change for you

An optional "CMF support" folder of your own can replace the adapter: the same script, unchanged, because it already uses your folder name. It must stay a separate folder, because a CMF call fails to compile when CMF is not installed. Anyone who installed this example adapter uninstalls it when they install your support folder: with both installed the game may stop at the script compile screen (the same function names twice), and removing the adapter fixes it. If you later add an on/off option, send `"unset"` as the text for each key while it is off, so another mod's value or the game's applies (author guide, "Smooth map movement").

## What does not come back this way

Nothing that Smooth Map does is left out. The adapter has run in game alongside Ink & Iron and Map Quest Insight, where the map opened as yours does; your movement on its own, without Ink & Iron, has not been checked in a launch. The controller parts (stick zoom, the stick reading) are checked by value only, because no launch has used a controller.
