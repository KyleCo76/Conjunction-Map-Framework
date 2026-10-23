modCMFTestWorldB - TEST ONLY, not a player package, never released

The revision 9 check for Conjunction Map Framework (CMF 1.3.0, API version 9), pack B. Requires CMF 9; on an older
CMF the game stops at the script compile screen. Our own placeholder art, every picture marked "B":
- the world overview's painting as 2 x 2 tiles (each tile also shows its column and row), so a seam would show;
- crests for Skellige, Novigrad, Toussaint (bob) and White Orchard (prolog_village), all choice-only: they show
  only when "CMF Test World B" is picked on the "Region crests and markers" row of CMF's in-game menu (or the
  Painting row, or CMFFile_Painting_Crests in the settings file);
- a picture for every Xbox controller button whose name starts with gamepad_ (numbered as in pack A);
- an opening view on Geralt's place for the region he is in (CMFSetOpeningWorld, keeping the game's zoom), so the
  map opens on him even while pack A hides his marker; it wins when no other mod has a view for that region, or
  when "CMF Test World B" is picked on the "Opening view" row.

Build: python tools/cmf_test_world.py art (draws art/), then python tools/cmf_test_world.py stage --out <new folder>
(builds both test world packs with tools/cmf_pack.py). Remove: delete the modCMFTestWorldB folder.
