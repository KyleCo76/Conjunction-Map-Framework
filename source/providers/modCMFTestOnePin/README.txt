modCMFTestOnePin - TEST ONLY, not a player package, never released

The revision 11 check for Conjunction Map Framework (API version 11, "one pin"). Requires CMF 11; on an older CMF the
game stops at the script compile screen. No art; every picture is a frame of the game's own pin icon:
- the Seven Cats Inn signpost: cyan (tag colour), info box title "CMF test: one signpost", info box 160 px tall;
- every signpost's info box: one added line "CMF test: a line added to every signpost";
- monster nests: the anvil while undiscovered ("?"), the herbalist leaf while completed; level 2 nests red, others green;
- Geralt's arrow: magenta, twice its size; the first kind of player marker (User1): the herbalist leaf;
- legend: the game's signpost row moves to the Quests tab, first, as "CMF test signposts"; the Buffs tab is hidden;
- info box: 300 px right of and 200 px above the game's place (theme keys tooltip x and y). As the first folder it
  then decides "Info box moves out of the way", so another mod's long-box placement is off while it is in;
- the pin list log is on (CMFSetLogPins): "CMF pin list", "CMF pin info add", "CMF pin legend row" lines;
- place claim: the first other signpost the map shows is remembered by its position ("CMF test onepin place x= y="
  in the log); from the next map opening it is orange at two and a half times its size.

Build: python tools/cmf_pack.py check source/providers/modCMFTestOnePin (script only, nothing to stage). Remove:
delete the modCMFTestOnePin folder.
