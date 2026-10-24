# CMF Adapter Check

Optional add-on requiring Conjunction Map Framework API 11 or newer. After loading a game, it checks known map mods using their Options groups and localization keys, then asks CMF whether any associated provider has signed in. It does not read installed adapter versions. Stale menu files alone do not count as an installed mod. The Stable uses its text key alone.

If a detected mod has no provider, one combined notice names the adapter download. Fog of War needs adapter 1.0.1 or newer; Map Quest Insight needs 1.1.1 or newer. The wording asks you to install or update; it does not claim your installed version was measured. Get adapters from the CMF page on Nexus Mods, under Miscellaneous files.

Install `Mods/modCMFAdapterCheck` into the game's `Mods` folder and merge the included `bin` directory into the game directory. Add `modCMFAdapterCheck.xml` to the applicable DX11/DX12 user config matrix file list as with other mod menus. Merge script conflicts with Script Merger if needed. The core and appropriate adapters remain separate downloads.

Options > Mods > CMF Adapter Check has one Off/On setting, default On. A changed nonempty missing-adapter set warns once; repeating the same set stays quiet. A clean enabled check clears the remembered set, so an omission that later returns warns again. Off leaves that record unchanged. The hidden `CMFAdapterCheckKnown` value lives in the same Options group. Only that value is written, and user settings are saved only when it changes.

The checker runs from a unique unsaved one-shot player timer after loading, waits through inactive/black-screen/menu states, and cancels at game end. If the player is unavailable when scheduling, the log records the reason and the first map close retries scheduling (or performs the pending check when safe). It never detects per pin or on map opening. Source-only examples and mods without reliable detectors appear only on the offline list checker.

Uninstall by removing this add-on's folder, XML and file-list entry; restore merged scripts through your usual mod-manager backup. Its own saved settings may remain harmlessly in user.settings. No save data is required.

Developer build (from the repository root):

`python -B tools/cmf_adapter_check.py write`

`python -B tools/cmf_adapter_check.py check`

`python -B tools/cmf_adapter_check.py build --out build/adapter-check/my-fresh-package`

The output must be new or empty below this clone's `build/` directory and must not traverse reparse points. It contains this script, README, 18 language tables, settings XML and a SHA-256 manifest. These are offline/static checks; engine compilation and gameplay acceptance are separate.

Draft Nexus file description (not published):

Optional CMF API 11+ add-on. After loading, warns when known map mods need CMF adapters. Remembers unchanged warnings; includes an Off/On option. Install or update the named adapter from Miscellaneous files.

Catalogue maintenance: edit `tools/cmf_adapter_list.json`, keeping each installed source folder separate from its adapter folder and recording tested versions/source evidence in `catalogue-evidence.md`. Runtime detection needs reliable Options groups or non-placeholder localization keys; page-only entries keep both lists empty. An `author` row with detectors belongs to a known source mod; `minAdapter` is guidance, never a measured installed version. Declare from the source mod itself or a dependency/presence-checked adapter, never an untied adapter that cannot establish source presence. Preserve source-only exclusions and existing adapter API floors.

Regenerate with `python -B tools/cmf_adapter_check.py write`, then `check` and `node tests/test_cmf_adapter_page.js`. Generate author-page twins only with `python -B tools/cmf_author_docs.py build`, then `check`. The standalone HTML file works locally without external scripts, fonts, requests or page loads; pasted names stay text. Review-only integrated staging is `python -B tools/cmf_adapter_check_stage.py build --out build/adapter-check/your-new-run`, followed by `verify` on that directory. Existing panel/art remain controller prerequisites; this build does not release them.
