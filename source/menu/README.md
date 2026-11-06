# CMF In-Game Menu 1.5.2

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

1.5.1: with a save loaded and no map mod found, the Status page's "Who wins" rows and its Screen row now show
their live texts ("Vanilla (none loaded)", "Open the map once to see") instead of "Load a save to see".
An empty live list was taken for the title screen and read the remembered list.

1.5.2: Status rows show their value in the row's label ("Map size, position and backdrop: Ink and Iron (Default)") and leave the
value column empty, because Ink and Iron's options menu redraws BUTTON rows without the text on the right. A label is kept to
70 characters: the row name stays whole and the value part gives way (a trailing " (level)" is kept). The Screen row, whose
label already holds a colon, reads "Screen: 21:9 - Map fills it (CMF)".

Build locally with `python -B tools/cmf_menu_addon.py build --out <new-directory>`.
The build manifest records `minCmfApi: 11`, package version, and file SHA-256 hashes.
The manager owns release and installation. Previously released menu packages are
unchanged; adapter minimum versions are unchanged.
