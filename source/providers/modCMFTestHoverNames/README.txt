modCMFTestHoverNames - TEST ONLY, not a player package, never released

The revision 10 check for Conjunction Map Framework (CMF 1.4.0, API version 10). Requires CMF 10; on an older CMF the
game stops at the script compile screen. No art:
- names only on hover (property 28) claimed for every pin with value 3: labels and level tags show only on the pin
  under the cursor, which also shows its name; signposts keep the game's labels (a RoadSign type claim of 0);
- every map opening logs "CMF test hover screen=<width>x<height>" (CMFScreenWidth and CMFScreenHeight, map units).

Build: python tools/cmf_pack.py check source/providers/modCMFTestHoverNames (script only, nothing to stage). Remove:
delete the modCMFTestHoverNames folder.
