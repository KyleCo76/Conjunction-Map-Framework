# Conjunction Map Framework for mod authors

Conjunction Map Framework (CMF) is one world map for The Witcher 3 (Remastered, patch 5.01) that map mods can share. Only one copy of the map file loads in the game, so before CMF two map mods that each shipped their own copy could not both work. With CMF, your mod no longer ships a map file: it tells CMF what it wants changed on the map, and CMF decides between mods and draws the result. Several map mods then work at once, with no Script Merger and no edited map files.

These pages are for anyone who has made a Witcher 3 mod before and wants to build on CMF: an icon pack, a mod that adds its own pins, a new look for the whole map, or an existing map mod moving onto CMF. Everything here is CMF 1.4.1, which is API version 10 (`CMFGetVersion()` returns `10`; that number is the version of CMF's script interface, not a release number).

New here? Start with [What do you want to change?](page:Abilities), then [Getting started](page:Getting-Started).

## How CMF is built

- **Abilities, not functions for one mod.** CMF has no call made for one particular mod or one particular item. Each ability is one general call, and what it acts on is an argument: one icon call for every pin type, one hide call for any pin, one drawing call for any shape. There is no "change the Seven Cats Inn signpost" call; there is an icon call that takes that signpost's tag.
- **Names are open.** Pin types, pin tags, legend rows, filter tabs and drawing ids are plain names. A mod can name something another mod added, even though CMF was never told about either mod.
- **Your script describes; CMF's map draws.** Scripts cannot draw into the map movie. Your script says what it wants, and CMF's map carries it out each time the map opens. A drastically different look (a neon, Cyberpunk-style map, say) needs no change to CMF: it is the same calls with different values.
- **Every change is a claim, and claims have an order.** Two mods that change the same thing on the same pin do not fight: the mod whose folder name sorts first wins, the way the game picks between two mods that ship the same file, and players can change that order in CMF's settings, or from CMF 1.2.0 choose the winner of each feature themselves ([Players' choices](page:Who-Wins-Each-Feature)). Some claims (hiding, drawings) all apply together. Each page says which kind a claim is.
- **Ask before you use.** `CMFRequireVersion`, `CMFHasProperty` and `CMFHasAbility` tell your script what the installed CMF can do, so a mod can still load on an older CMF.

## Adapters: worked examples of moving a mod onto CMF

CMF ships adapters for existing map mods. Each adapter is a teaching example for that mod's author: "you used to do this in your own map file; now you call these CMF functions like this, and get the same result plus CMF's compatibility". An adapter:

- brings back what the mod already does on the map, and adds nothing of its own;
- works only with its mod installed, because it reads the mod's own settings and values; it never gives a player the mod's features without the mod;
- claims under the adapted mod's own folder name, so folder order is the same with CMF as without it;
- carries our own placeholder pictures, or a mod author's art only with that author's permission, credited. Where a mod drew its own pictures inside its map file, the adapter uses simple placeholders of its own, in its own folder, never in CMF, until the author ships theirs or allows theirs to be used. The Gwent Players Map and Witcher Gear Map adapters carry their author MateusAnd's own art since 1.0.1, the Map Quest Insight adapter carries its author Wolfer's own quest icons since 1.0.1, and the Ink and Iron adapter carries its author WinterElfeas's own World Map overview and gold controller buttons since 1.2.0;
- is removed by the player once the mod's author ships CMF support of their own.

The pages under "Moving a map mod onto CMF" show each one.

## Reusing the examples

CMF, its adapters and its example icon pack are published under the Creative Commons Attribution-NonCommercial 4.0 licence (CC BY-NC 4.0). You may copy and change their code and examples in your own mod and share it, as long as you credit CMF and do not use it commercially.

## Contents

<!-- cmf:contents -->
