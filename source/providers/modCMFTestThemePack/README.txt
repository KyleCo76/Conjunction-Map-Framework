modCMFTestThemePack - TEST ONLY, not a player package

The Cyberpunk check for Conjunction Map Framework's map theme (Stage 6b design, section 6): a deliberately
different look built from CMF's public calls only, with no change to CMF. Requires CMF 5 (the map theme).

What it shows on the full-screen map:
- a near-black backdrop and neon map art for Velen and Novigrad (a dark grid in cyan and magenta);
- neon quest icons (magenta and cyan hexagons, a yellow triangle for contracts);
- the region title in magenta, widely spaced, on one line, with a cyan underline;
- cyan glowing frames round the quest tracker, the legend and the info box;
- cyan key names, magenta key icons, and a cyan glow round the map's edge;
- dark plates with a cyan outline under pin labels.

Install it without any other theme or theme adapter: the earliest folder that styles a part of the map owns
that part, so another theme in an earlier folder keeps every part both style.

Build: python tools/cmf_test_theme.py stage --out <new folder> (cooks the icons and the 341 map tiles into
the pack's own content/texture.cache). All art is CMF's own procedural geometry (tools/cmf_test_theme.py).
Remove: delete the modCMFTestThemePack folder.
