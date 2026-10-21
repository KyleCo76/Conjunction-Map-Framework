modCMFTestMapSpace - TEST ONLY, not a player package

The map-space drawing check for Conjunction Map Framework (map-space drawing research 2026-10-20, section
5.2). Requires CMF API version 6 with map-space drawing (CMFHasAbility('mapSpace', '')); on an older CMF it
draws nothing and logs "CMF_TEST_MAPSPACE skipped reason=noability".

The built folder (tools/cmf_test_movie.py) holds this script and content/blob0.bundle with metadata.store:
CMF's own small test movie, swf/cmftestmapspace/cmftestmapspace.swf. It is no other mod's art and draws only
plain shapes.

What to look for on the region map (open the map with M):
- a coloured square on Geralt (orange, drawn half see-through), a white cross 100 m east and 100 m west of
  him, and an orange dot on him in the corner overview; the square fades in and stays after the button click;
- the words CMF MAP SPACE just above Geralt, the same size at every zoom (scroll the mouse wheel);
- at the top left, below the region name, two lines: "EARLY: received after listen ready" (written again
  from the OnMapListening hook once the map listens), and "LATE: waiting", which becomes "LATE: click 1",
  "LATE: click 2", ... with each button click;
- the last filter tab, named CMF TEST (click the arrows beside the tab name): no pins except Geralt, a ring around
  him (half green, half blue) and a "Swap colours" button above the tab name; the button turns gold under the
  mouse, and a click swaps the ring's colours while the map stays on CMF TEST.

scriptslog.txt lines: "CMF_TEST_MAPSPACE registered", "CMF space sent", "CMF panel space drawn",
"CMF panel movie loaded", "CMF panel movie drawn id=cmfTestMapSpaceMovie ok=1", "CMF listen ready keys=",
"CMF panel listen arrived", "CMF panel drawing click", "CMF drawing click provider=modCMFTestMapSpace",
"CMF_TEST_MAPSPACE swap" and the "CMF panel space check" lines (layer colours, each drawing's box on screen,
the line's colours, the text's width and the movie's state, about a second after each draw).

Install: copy the built folder into Mods for a probe launch only. Remove: delete the modCMFTestMapSpace folder.
