The first release of Conjunction Map Framework: one world map for The Witcher 3: Wild Hunt Remastered (Steam patch 5.01) that several map mods can share.

### Which files do I need?

- **`mod0000_ConjunctionMapFramework-1.0.0.zip`**: always.
- **An adapter** (`modCMFAdapter...`) only for the listed map mods you play with, only with that mod installed, and only until its author updates it for CMF. Many map mods need no adapter.
- **`modCMFMinimapPanel-1.0.0.zip`**: optional; not with any other mod that changes the minimap.
- **`modCMFExampleIconPack-1.0.0.zip`**: optional; an example for pack authors.

Each archive has a `README.txt` with install and removal steps. The list of supported mods and their versions is in the [README](https://github.com/KyleCo76/Conjunction-Map-Framework#supported-map-mods).

### In this release

- CMF script interface version 6: pin icons, tints, backgrounds, greying, legend rows and tabs, hiding, pin size and labels, map themes, pin clicks, smooth movement, spreading stacked pins and drawing on the map.
- Tested with Ink & Iron and the other adapted map mods as their authors ship them, and in a full, everyday modded game installed with RMMR.
- Adapters for All Quest Objectives, Botanist, Fog of War, Gwent Players Map, Ink and Iron, Map Pin Teleport, Map Quest Insight, The Stable, Witcher Upgrade Gear Map and Witcher's Path.

### Tested

On Windows with keyboard and mouse, both copied in by hand and installed with RMMR in a full, everyday game setup. Not tested: controllers, Proton / Linux. Details in `test-notes.md`; going back in `rollback-notes.md`.

### Licence

CC BY-NC 4.0: free to copy, change and share with credit, not for sale or commercial use. See `LICENSE`.

### Check a download

`Get-FileHash .\<archive>.zip -Algorithm SHA256` in PowerShell must match the archive's line in `SHA256SUMS`.
