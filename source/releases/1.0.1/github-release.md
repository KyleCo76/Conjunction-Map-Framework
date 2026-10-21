Two adapter updates for Conjunction Map Framework 1.0.0, now with the art of their mods' author. CMF itself and every other adapter stay at [1.0.0](https://github.com/KyleCo76/Conjunction-Map-Framework/releases/tag/v1.0.0).

### Which files do I need?

- **`modCMFAdapterGwentPlayersMap-1.0.1.zip`**: if you play with Gwent Players Map 1.0.9. Replaces the 1.0.0 adapter.
- **`modCMFAdapterWitcherGearMap-1.0.1.zip`**: if you play with Witcher Upgrade Gear Map 1.0.1. Replaces the 1.0.0 adapter.

Both need CMF 1.0.0 (`mod0000_ConjunctionMapFramework-1.0.0.zip` from the 1.0.0 release). Each archive has a `README.txt` with install and removal steps.

### In this release

- The card art and gear art of MateusAnd, the author of Gwent Players Map and Witcher Upgrade Gear Map, shipped in the adapters with their permission and credited. It replaces CMF's own placeholder pictures.
- Witcher Gear Map markers show each school in the author's own colours in the "School colour" icon styles.
- Thanks to MateusAnd for testing the adapters on Linux with Steam and Proton.

### Tested

On Windows with keyboard and mouse, with Ink & Iron 0.8.9. MateusAnd ran the adapters on Linux (Steam with Proton). Not tested: controllers, Steam Deck. Details in `test-notes.md`; going back in `rollback-notes.md`.

### Check a download

`Get-FileHash .\<archive>.zip -Algorithm SHA256` in PowerShell must match the archive's line in `SHA256SUMS`.
