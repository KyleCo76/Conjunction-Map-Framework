# All Quest Objectives on Conjunction Map Framework: the change for its author

This note is for the authors of All Quest Objectives On Map - Remastered (Nexus 14319). It shows how the mod's difficulty icons, its own legend row and its removable cached merchant pins come back on Conjunction Map Framework's (CMF) world map. The worked example is the adapter CMF ships, [`source/adapters/all-quest-objectives/modCMFAdapterAllQuestObjectives`](../../source/adapters/all-quest-objectives/modCMFAdapterAllQuestObjectives/). The icons and the row have been run in game; the cached pin click has not been tried yet.

## Why anything is needed at all

Only one `panel_worldmap.redswf` loads, and when CMF is installed it is CMF's map. Three things in your map file are then missing:

- the 19 icon frames (`WmkQuestIcon*`, `WmkExclamationIcon*`) and the line `gotoAndStop(wmkIcon ? wmkIcon : type)` that shows them;
- the branch in `UseSelectedPin` that reports a used cached merchant pin as `OnStaticMapPinUsed(id, -(aqoomCachedPin + 999))`;
- the separate "All Quest Objectives" legend row for `QuestObjectiveOther` quest pins.

Your scripts keep running. They still write `wmkIcon`, `aqoomCachedPin` and `aqoomRowLabel` on the pins, still push the cached pins and still add the level to the descriptions. CMF's map declares those three pin fields so the values survive, but it does not read them itself. A mod tells CMF in script what to do with its pins, and CMF's map does it.

## You used to, now you call

**The difficulty icons.** Your map file used to jump the pin's icon to the frame named in `wmkIcon`. Now you style that pin from CMF's pin hook (API version 4) with an image and a colour (API version 2):

```
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var frame : string;
	wrappedMethod(dataObject, mapContext);
	frame = dataObject.GetMemberFlashString("wmkIcon");
	if (frame == "WmkQuestIconRed")
	{
		CMFStylePinIcon("modAQOOMRemastered", dataObject, "img://icons/<your folder>/badge.png");
		CMFStylePinTint("modAQOOMRemastered", dataObject, 14241872);	// 0xD95050
	}
	// ...and the other names
}
```

The adapter draws a white badge and a white exclamation mark of its own and tints them per pin with each frame's colour, so one picture per family covers all 19 names. You could equally ship one image per frame from your own art and skip the tint. The adapter's [script](../../source/adapters/all-quest-objectives/modCMFAdapterAllQuestObjectives/content/scripts/local/modcmfadapterallquestobjectives_cmf.ws) has the full colour table.

**The cached merchant pins.** Your map file used to send `OnStaticMapPinUsed(id, -(aqoomCachedPin + 999))`, and your `OnStaticMapPinUsed` wrapper turned that number into `OnCachedPinUsed`. CMF's map never sends that number. Now you claim the click on each cached pin (API version 6) and CMF calls you back:

```
// in the same OnPinReady wrapper
cached = dataObject.GetMemberFlashInt("aqoomCachedPin");
if (cached > 0)
{
	CMFStylePin("modAQOOMRemastered", dataObject, CMFPropertyPinClick(), "use, doubleClick", cached);
}

@wrapMethod(CMFCore)
function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, pinType : string,
	input : string, value : int) : bool
{
	var aqoomMap : AqoomMap;
	if (provider != "modAQOOMRemastered")
	{
		return wrappedMethod(menu, provider, pinTag, pinId, pinType, input, value);
	}
	aqoomMap = AqoomGetMap();
	if (aqoomMap && aqoomMap.IsCachedPinUse(pinTag, -(value + 999)))
	{
		aqoomMap.OnCachedPinUsed(menu, -(value + 999));
	}
	return true;
}
```

`use` is E, Enter, gamepad A and a tap on the selected pin, and `doubleClick` is the mouse double-click: the same inputs your `UseSelectedPin` branch took. There is no hold ring, as in your map file. `pinTag` arrives as your own wrapper received it, because CMF passes the pin's id into a `name` the way the game's fast-travel event does. Your messages, sound and map rebuild stay in `OnCachedPinUsed`. Inside your own script you could equally call your private code directly.

**The legend row.** Your map file used to put quest pins whose `filteredType` is `QuestObjectiveOther` into their own row, labelled with `aqoomRowLabel`, in the Quests tab at priority 200. Now you register that row once per game start (API version 2 calls, quest-row rule in API version 6), and CMF's map lists, counts, shows and hides those quest pins in it:

```
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFRegisterLegendRow("modAQOOMRemastered", 'QuestObjectiveOther', 'Quests', 200);
	CMFRegisterLegendLabel("modAQOOMRemastered", 'QuestObjectiveOther', "All Quest Objectives");
	return result;
}
```

Pass your `FILTER_LABEL` text as the label. A won row claim on a type that quest pins carry as their `filteredType` takes those quest pins out of CMF's shared quest row, and its priority applies even though the game itself defines `QuestObjectiveOther`.

You get the same map as with your own map file. In addition, your pins share the map with every other CMF mod, conflicts are settled by folder order, and no Script Merger is needed.

## Which mod wins (claim order)

- Every call above styles or claims **one pin**, the most specific level. It beats any claim another mod makes on the pin's type (`CMFRegister`) or tag (`CMFRegisterForTag`), such as an icon pack's tint on `QuestObjectiveOther`.
- When another mod styles **the same pin** one pin at a time, the earlier folder in CMF's provider order wins: folder order, ignoring case, unless the player lists providers in `CMFProviderOrder` lines. Then the earlier call wins.
- **Map Quest Insight.** Its adapter styles quest pins one at a time too: an icon by quest kind and a colour by level. `modAQOOMRemastered` sorts before `modMapQuestInsight`, so on objectives of quests the player does not follow, your badge and its colour win, and Map Quest Insight's icon and colour stay on every other quest pin. Without CMF the two mods could not be installed together (each replaces the map file), so this order is CMF's documented rule, not a copy of an older look. A player who wants Map Quest Insight's look there lists `modMapQuestInsight` first in `CMFProviderOrder`.
- **The row** is a type-level claim. If another mod also claims a legend row on `QuestObjectiveOther`, the earlier folder in CMF's provider order wins, and the loser's row is not shown.
- Your click claims are only on your cached merchant pins, which are neither fast-travel nor quest pins, so CMF lets them take `use` and `doubleClick`. They never meet Map Pin Teleport's claims, which are on the player's own pins.

## Shipping it yourself

Ship it as an optional "CMF support" folder next to your mod. It must stay separate, because a CMF call fails to compile when CMF is not installed:

```
Mods/
  modAQOOMRemasteredCMF/                        any folder name of yours, starting with "mod"
    README.txt
    content/texture.cache                       your icon art, built by CMF's pack tool
    content/scripts/local/modaqoomremasteredcmf_cmf.ws
```

- **Provider.** Keep `modAQOOMRemastered` as the first argument of every call. A claim made in your mod's folder name counts the same as your mod, so folder order between mods stays as it is without CMF. It also means that your folder and the adapter give the same result.
- **Art.** Export your frames as square PNGs, 96 x 96 recommended, with a transparent background and the outer 4 pixels empty ([icon pack guide](icon-pack-guide.md#4-make-your-art)). Point the image paths at your folder: `img://icons/<your folder in lower case>/<name>.png`.
- **Build.** Run `python tools/cmf_pack.py build path/to/modAQOOMRemasteredCMF --adapts modAQOOMRemastered --out path/to/new-folder` from the CMF repository. It cooks your PNGs into the folder's own `texture.cache`.
- **Versions.** The click claim and the `OnPinClicked` wrapper need CMF API version 6 to compile, `OnPinReady` needs version 4, and the row's quest-row rule is part of version 6 too. Say so in your README.
- **When you ship it, players remove CMF's adapter.** With both installed, the game stops at the script compile screen. Removing the adapter fixes it.
