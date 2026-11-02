# CMF In-Game Menu 1.5.0

This build requires CMF API 11. Its script calls `CMFCore.PresentProviders` directly;
installing it beside an older core causes a script compile error.

Loaded map mods includes providers that have declared CMF support even when they
supply no feature. These rows say "CMF support present". Provider presence never
adds a Basic/Advanced choice or a Mod order entry. The title screen remembers its
status list separately from the selectable provider list.

Loaded map mods also lists map mods that never tell CMF they are installed. The add-on's
`cmfMenuInventory.ws` finds them in the game's settings (a menu group, or a string) and shows
the mod's name and what it does; these rows are found again every time and never remembered.
The list and how to remove a row are in `docs/development/map-mod-inventory.md`.

Build locally with `python -B tools/cmf_menu_addon.py build --out <new-directory>`.
The build manifest records `minCmfApi: 11`, package version, and file SHA-256 hashes.
The manager owns release and installation. Previously released menu packages are
unchanged; adapter minimum versions are unchanged.
