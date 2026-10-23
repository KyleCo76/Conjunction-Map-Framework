modCMFTestWorldA - TEST ONLY, not a player package, never released

The revision 9 check for Conjunction Map Framework (CMF 1.3.0, API version 9), pack A. Requires CMF 9; on an older
CMF the game stops at the script compile screen. Our own placeholder art, every picture marked "A":
- the world overview's painting, one 2100 x 1380 picture;
- crests for Kaer Morhen, Skellige, Novigrad, Velen (no_mans_land), Vizima (wyzima_castle) and Toussaint (bob);
  not White Orchard (prolog_village);
- the overview's player marker;
- a picture for every Xbox controller button, numbered 1 to 29;
- the player's marker hidden on the region map when the map is opened from the menus (GlobalMap) only;
- the map's view: logs "test world A view area= reason= x= y= zoom=" for every report and opens each region at the
  view it last reported in this session (CMFSetOpeningView, place and zoom).

Build: python tools/cmf_test_world.py art (draws art/), then python tools/cmf_test_world.py stage --out <new folder>
(builds both test world packs with tools/cmf_pack.py). Remove: delete the modCMFTestWorldA folder.
