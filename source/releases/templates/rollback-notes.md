# Removing CMF <<FILL: version>> or going back

<!-- Template for dist/<version>/rollback-notes.md. Copy it to
source/releases/<version>/rollback-notes.md, fill every <<FILL: ...>> and remove these comment
lines. Keep a sentence only where a final matrix record or the design backs it: removing the
adapters is shown by set M5a and removing CMF by set M5b. The same steps must appear in each
package's README.txt in the candidate, because promotion never changes the archives. -->

## Removing CMF

Remove in this order. Each step leaves a game that starts.

1. **Adapters and packs first.** Delete each `Mods\modCMFAdapter<Mod>` folder you installed, and any icon pack that needs CMF. The mods they adapt keep working on their own; their map features go back to how they look without CMF, or stay hidden where that mod's own map file is not the one the game loads.
2. **The CMF Minimap Add-on**, if installed: delete `Mods\modCMFMinimapPanel`.
3. **CMF itself:** delete `Mods\mod0000_ConjunctionMapFramework` and `bin\config\r4game\user_config_matrix\pc\mod0000_ConjunctionMapFramework.xml`.
4. Start the game once; it recompiles scripts.

Deleting CMF while an adapter is still installed stops the game at the script compile screen, because the adapter calls CMF. Put CMF back, or delete the adapter, and the game starts again.

**Saves:** CMF writes nothing into your saves. A save made with CMF loads without it.

**Settings:** CMF's options, including any provider order you set (`CMFProviderOrder1` to `CMFProviderOrder8`), live in the `[CMFSettings]` section of `Documents\The Witcher 3\dx12user.settings`. They do nothing once CMF is gone. Delete that section only if you want the file clean, and only with the game closed.

## When a mod adds its own CMF support

Uninstall that mod's CMF adapter. With both installed the game stops at the script compile screen, and the error names the adapter. Deleting the adapter folder fixes it.

## Going back to an earlier CMF version

Remove the adapters and packs, then CMF (steps above), then install the older CMF and the adapters that match it. Adapters made for a newer CMF do not work with an older one: they either say so in the game log or stop the game at the script compile screen.

<<FILL: an earlier version players can go back to and where to get it, or remove this line for the first release>>
