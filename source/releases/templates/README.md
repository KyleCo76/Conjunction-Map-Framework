# Conjunction Map Framework <<FILL: version, e.g. 1.0.0>>

<!-- Template for dist/<version>/README.md. Copy it to source/releases/<version>/README.md and
replace every <<FILL: ...>> from the passing candidate and its final matrix records. Remove
these comment lines too. tools/cmf_preview.py promote refuses the file while any <<FILL is left. -->

The Conjunction Map Framework (CMF) is one world map for The Witcher 3: Wild Hunt Remastered that other map mods and icon packs work through, so several of them can be installed at the same time.

This folder holds the release archives exactly as they were tested: they are the same bytes as release candidate `<<FILL: candidate label, e.g. 1.0.0-preview-3>>`, with only the file names changed.

## Contents

| Archive | What it is | Install |
| --- | --- | --- |
| `mod0000_ConjunctionMapFramework-<<FILL: version>>.zip` | CMF itself | Required |
| <<FILL: one row per archive in manifest.json: name, what it is, when to install it>> | | |

Each archive mirrors the game folder and has a `README.txt` at its root with the full install, update and removal steps. Adapters contain none of the mods they adapt; install those from their authors. Nothing in these archives runs outside the game.

## Requirements

- The Witcher 3: Wild Hunt Remastered, <<FILL: game build from manifest.json gameBuild, e.g. Steam patch 5.01, build 5.0.1048522>>, on Windows.
- Each adapter needs the mod it adapts, at the version named in that adapter's `README.txt`.

## Install

1. Extract the CMF archive to a temporary folder.
2. Copy its `Mods` and `bin` folders into your game folder and let Windows merge them.
3. Install the mods you want to adapt as their authors describe, then the matching adapter archives (`Mods` only). Optionally add the minimap add-on.
4. Start the game. The first start recompiles scripts and takes a little longer.

## Check a download

In PowerShell, in the folder with the archive:

```
Get-FileHash .\mod0000_ConjunctionMapFramework-<<FILL: version>>.zip -Algorithm SHA256
```

The result must equal that file's line in `SHA256SUMS`.

## How this release was tested

See `test-notes.md`: where and how it was tested, and what was not tested.

## Removing or going back

See `rollback-notes.md`. In short: remove adapters and packs first, then the minimap add-on, then CMF.

## Known limits

<<FILL: the known limits of this release, from the candidate README and the compatibility list>>

This is an unofficial fan work and is not approved/endorsed by CD PROJEKT RED.
