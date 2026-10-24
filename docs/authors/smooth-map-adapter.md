# Smooth Map on Conjunction Map Framework: the change for its author

> [!NOTE]
> **Proof-of-concept example, not a shipped adapter.** This adapter is not part of any CMF release and is not on Nexus. It is published here only as a worked example for Smooth Map's author. Its keys ran in game together with Ink & Iron, which won the movement keys it also sets; Smooth Map's values on their own, without Ink & Iron, have not been checked in a launch.

This note is for the author of Smooth Map (Nexus 13530). It describes Smooth Map 1.1, the version the adapter targets. It shows how Smooth Map's smoother movement and faster opening come back on Conjunction Map Framework's (CMF) world map, using CMF's example adapter as a worked example, [`source/adapters/smooth-map/modCMFAdapterSmoothMap`](../../source/adapters/smooth-map/modCMFAdapterSmoothMap/).

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

The two `Timer(1)` rows hold from CMF 1.5.0: its map replaces the running region and world timers, so `frameTimed` 1 really ticks every frame. Earlier versions set a new delay on timers that were already running, which the game's Flash player ignores, so they kept the 17 and 24 ms beat and scaled only the step.

Your `smSlideOffset` correction and your snap fix need no call: CMF's map does both whenever pins are prepared during the slide-in. Your view measured again when the slide ends (`SetMenuAnimCompleted`) needs no call either: from CMF 1.5.0 CMF's map does it with `pinsDuringSlide` 1. Send even the keys equal to the game's value (`stepMs` 17, `worldStepMs` 24, `padHoldMs` 0): they are your choices, and a mod that stays silent on a key loses it to any other mod that sets it.

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

An optional "CMF support" source variant inside Smooth Map's own mod folder can replace the adapter, because it already uses your folder name. Offer that variant separately from the ordinary source, because a CMF call fails to compile when CMF is not installed; the installed variant still belongs inside Smooth Map's folder. The example adapter was never released to players, so nobody has to uninstall it. If you later add an on/off option, send `"unset"` as the text for each key while it is off, so another mod's value or the game's applies (author guide, "Smooth map movement").

## What does not come back this way

Your map takes input and shows the legend, quest tracker, crosshair and edge pointers as soon as its fade-in starts (`handleShowTimer`); CMF's map shows them after the tiles have faded in. From CMF 1.4.1 (API version 10) the `opening` key `readyAtFadeStart` 1 does what yours does, and `revealEase` 1 makes the `revealSeconds` fade ease in. The example adapter sends both, `readyAtFadeStart` 1 and `revealEase` 1, behind `CMFHasAbility('opening', 'readyAtFadeStart')`, so the same script still runs on CMF 1.3.0; on API version 10 it sends 17 keys. In the CMF 1.4.1 launch (2026-10-24) `readyAtFadeStart` ran: the legend and tracker arrived together with the map. `revealEase` has not yet run in game.

CMF's map runs at 60 frames a second by default (with `frameTimed`, `zoomTimed` and `tweenEveryFrame` `1`), not the game's 24. Your mod does not set `frameRate`, so it gets CMF's 60; send `CMFStylePart("modSmoothMap", 'navigation', 'frameRate', "", 24)` if you want to keep 24.

The adapter has run in game alongside Ink & Iron and Map Quest Insight, where the map opened as yours does, and all its keys were accepted in the final test round (2026-10-21); your movement on its own, without Ink & Iron, has not yet been judged in a launch. The controller parts (stick zoom, the stick reading) are checked by value only, because no launch has used a controller.

## Tell CMF Smooth Map is here

Ship this inside Smooth Map's own folder; a separate adapter folder must not declare, because it cannot tell whether Smooth Map is installed.

From CMF 1.5.0 (API version 11) the example also tells CMF that Smooth Map is installed, once the game has started: `if (CMFHasProperty(38)) { CMFRegister("modSmoothMap", 38, '', '', "", 1); }`. CMF's optional adapter check and the in-game menu's Loaded map mods page then know Smooth Map is ready for CMF. Older CMF versions skip the line, so the file still works from API version 6. `CMFDeclareProvider("modSmoothMap")` does the same, but needs API version 11 to compile. Keep the line in Smooth Map's own folder: a separate adapter folder cannot tell whether Smooth Map is installed.

The optional checker can recognize that declaration. It must come from Smooth Map itself or from a source variant inside Smooth Map's own folder. An independent optional folder cannot establish that Smooth Map is installed. Smooth Map remains an author-only example, excluded from public wiki pages and release/catalogue runtime entries. The controller fixture copies this script only under `Mods/modSmoothMap/content/scripts/local/`. Its theme submissions mean it cannot demonstrate a declaration-only status row; a separate probe handles that case.
