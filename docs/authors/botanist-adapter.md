# Botanist on Conjunction Map Framework: the change for its author

This note is for the author of Botanist - NG - Remastered (Nexus 8260). It is written against Botanist 3.0.0.2 with Shared Utils 4.1. It shows how Botanist's world map changes come back on Conjunction Map Framework's (CMF) world map, using the adapter CMF ships as a worked example, [`source/adapters/botanist/modCMFAdapterBotanist`](../../source/adapters/botanist/modCMFAdapterBotanist/).

## Why Botanist needs anything at all

Botanist 3.0 ships its own `panel_worldmap.redswf`, the game's map with Botanist's tab, rows and three frames added, and its install text already says only one copy of that file loads. CMF solves the same problem a different way: every mod tells CMF in script what it wants on the map, and CMF's one map draws all of it. When CMF is installed, CMF's map loads instead of Botanist's, so these are missing:

- the "Botanist" filter tab, its three rows, and its rule that signposts and other fast-travel points stay out of it;
- the three marker frames (the gold leaf, the blue leaf and the blue plant).

Your pins themselves still arrive: Shared Utils pushes them as it always does, and their circles, labels and herb counts are yours. CMF brings the rest back without a map file. With Botanist ported, a player can run it next to any other map mod.

## You used to, now you call

**The Botanist tab and its rows.** You used to add `"Botanist": new CategoryDefinition(8, true, false, false)` and three `PinTypeDefinition`s to `HubMapPinPanel`. Now you register them as data (API version 2, property ids 8 and 6), with the same id, priorities and string key, under your folder name:

```
CMFRegister("modBotanist", 8, 'Botanist', '', "[[map_category_Botanist]]", 8);
CMFRegister("modBotanist", 6, 'BotanistHGHerb', '', "Botanist", 612);
CMFRegister("modBotanist", 6, 'BotanistHG', '', "Botanist", 613);
CMFRegister("modBotanist", 6, 'Botanist', '', "Botanist", 614);
CMFRegisterCategoryNoDefault("modBotanist", 'Botanist', true);
```

The last line (API version 6, property 23) keeps the tab's rows out of Default, as the game's `addPinInstance` did by listing only General, Quests, NPCs, Buffs and `Entrance` there. The adapter writes it as `CMFRegister(…, 23, 'Botanist', '', "", 1)` behind `CMFHasProperty(23)` so it still compiles on API version 5. The tab's name comes from your own `map_category_Botanist` string, as before.

**Your three frames.** You used to draw them into the map's pin sprite. Now you ship PNGs in your own texture cache and name them per type (API version 1):

```
CMFRegisterIcon("modBotanist", 'Botanist', "img://icons/modbotanist/herb.png");
CMFRegisterLegendIcon("modBotanist", 'Botanist', "img://icons/modbotanist/herb.png");
// the same for BotanistHGHerb and BotanistHG
```

Your ground frame is about one and a half times the leaves (14.7 by 13.1 px against 9.85 by 8.8 px), so it asks for that size (API version 4); the circle is the pin's own radius and keeps your Map Pin Size setting:

```
CMFRegister("modBotanist", CMFPropertyPinScale(), 'BotanistHG', '', "", 149);
```

The adapter has no art of yours, so it draws one white leaf (and a leaf in a ring for the ground) and colours it per type with your accent colours, gold `0xFFCC00` for ready to harvest and blue `0x9BAADD` for a Harvesting Ground:

```
CMFRegisterTint("modBotanist", 'Botanist', 16763904);
CMFRegisterTint("modBotanist", 'BotanistHGHerb', 10201821);
CMFRegisterTint("modBotanist", 'BotanistHG', 10201821);
```

With your own coloured art you drop the tints.

**No signposts in your tab.** `CategoryDefinition(8, true, false, false)` kept fast-travel pins out of the tab. CMF's tabs show them, so an `OnPinReady` wrapper (API version 4) leaves every pin with `isFastTravel` out of your tab, the same test your map made, whoever pushed the pin:

```
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	wrappedMethod(dataObject, mapContext);
	if (dataObject.GetMemberFlashBool("isFastTravel"))
	{
		CMFStylePin("modBotanist", dataObject, CMFPropertyTabHide(), "Botanist", 1);
	}
}
```

Quest pins and player pins need nothing: CMF's tabs already leave out quest pins and show player pins, as yours did.

Register everything once from a `CR4Game.OnGameStarted` wrapper after `CMFRequireVersion("modBotanist", 5)`. Then you no longer ship `panel_worldmap.redswf`, and `blob0.bundle` holds only what else you need.

## With Community Patch - World Map

Community Patch's map carries your map part unchanged, and its CMF adapter makes the same claims with the same values. Its folder sorts first, so it wins every shared claim, as its map file wins over yours without CMF. Keep the values equal if both of you port; then the map looks the same with either installed.

## What was checked in game

Launch Build 1b, 2026-10-21: the placeholder leaves on the herbs, the Botanist tab with its rows, and no Botanist rows under Default. Your pins reach the map from Shared Utils' `UpdateUserMapPins` wrapper, which runs outside CMF's; CMF catches such late pins itself (since PR #50), so you need nothing for it. Not yet looked at closely: a Harvesting Ground marker's size next to the leaves, and the fast-travel pins left out of your tab.
