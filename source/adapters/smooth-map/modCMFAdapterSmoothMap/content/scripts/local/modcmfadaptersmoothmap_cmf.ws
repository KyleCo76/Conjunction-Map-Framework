// Proof-of-concept example for Smooth Map's author, not a released adapter; Smooth Map's values alone are not launch-checked.
// Smooth Map adapter for Conjunction Map Framework. Requires CMF API version 6 (smooth map movement); with API
// version 5 it sends nothing, and before 5 it does not compile (CMFStylePart). Smooth Map 1.1 (Nexus 13530) stays unchanged and has no script, so this file calls
// none of its code and compiles with or without it: install it only together with Smooth Map.
//
// Smooth Map changes only its own copy of the map file, and only one copy loads; CMF's sorts first, so under
// CMF its timing is lost. Its map moves on every drawn frame by the time since the last one instead of a fixed
// step per 17 ms (region map) or 24 ms (world view) tick, counting at most 100 ms, and zooms the same way; it
// advances snaps, centring and fades on every drawn frame; and it opens faster: pins are prepared while the
// menu slides in, as many as fit in 8 ms per 1 ms tick, after a 1 ms wait, with 0.2 s fades, and the crosshair,
// edge pointers, legend and quest tracker fade in over 0.2 s. Those are CMF's general navigation and opening
// keys, so this adapter sends Smooth Map's values once per game session, as Smooth Map's author would when
// porting (smooth map movement research 2026-10-20, section 5.2, Smooth Map's column). It sends only the keys
// Smooth Map's map file decides, including the ones equal to the game's value (stepMs 17, worldStepMs 24,
// padHoldMs 0), so an earlier folder that set them otherwise does not win them by default; it sends none of the
// keys Smooth Map leaves as the game's (the menu's slide and close, the frame rate, the zoom limit).
//
// Every key names Smooth Map's own folder, modSmoothMap, as its provider, so folder order between mods is the
// same with CMF as without it: on a key that an earlier folder also sets (modInkAndIronUI, modMapQuestInsight)
// the earlier folder wins. It wraps no function of another mod, so its file name needs no zz_.

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modSmoothMap", 6))
	{
		SmoothMapAdapterSend();
	}
	return result;
}

function SmoothMapAdapterSend()
{
	var accepted : int;
	accepted = 0;
	// How the map moves: by elapsed time on every drawn frame, zoom included; tweens every drawn frame.
	accepted += SmoothMapAdapterKey('navigation', 'frameTimed', 1);
	accepted += SmoothMapAdapterKey('navigation', 'stepMs', 17);
	accepted += SmoothMapAdapterKey('navigation', 'worldStepMs', 24);
	accepted += SmoothMapAdapterKey('navigation', 'maxStepMs', 100);
	accepted += SmoothMapAdapterKey('navigation', 'zoomTimed', 1);
	accepted += SmoothMapAdapterKey('navigation', 'padHoldMs', 0);
	accepted += SmoothMapAdapterKey('navigation', 'tweenEveryFrame', 1);
	// How the map opens: pins during the slide-in, 8 ms per 1 ms tick with no count limit, quick fades, reveal.
	accepted += SmoothMapAdapterKey('opening', 'pinsDuringSlide', 1);
	accepted += SmoothMapAdapterKey('opening', 'pinStepMs', 1);
	accepted += SmoothMapAdapterKey('opening', 'pinBatch', 0);
	accepted += SmoothMapAdapterKey('opening', 'pinBudgetMs', 8);
	accepted += SmoothMapAdapterKey('opening', 'showDelayMs', 1);
	accepted += SmoothMapAdapterKey('opening', 'fadeSeconds', 0.2);
	accepted += SmoothMapAdapterKey('opening', 'tileFadeSeconds', 0.2);
	accepted += SmoothMapAdapterKey('opening', 'revealSeconds', 0.2);
	LogChannel('CMF', "CMF adapter provider=modSmoothMap keys=15 accepted=" + accepted);
}

// One key under Smooth Map's folder name; 1 when CMF took it (CMF logs every refusal with its reason).
function SmoothMapAdapterKey(part : name, key : name, number : float) : int
{
	if (CMFStylePart("modSmoothMap", part, key, "", number))
	{
		return 1;
	}
	return 0;
}
