Smooth Map adapter for Conjunction Map Framework
Version 0.1 (unreleased author template; script only, no art)

PROOF-OF-CONCEPT EXAMPLE, NOT A RELEASED ADAPTER
This adapter is not part of any Conjunction Map Framework release and is not on
Nexus. It is published as a worked example for Smooth Map's author. Its values
ran in game only together with Ink and Iron, which won the movement keys it also
sets; Smooth Map's movement on its own under CMF has not been checked in a launch.

Brings Smooth Map's map movement and faster opening back on Conjunction Map
Framework's world map. Smooth Map stays exactly as its author ships it. Smooth Map
changes only its own copy of the world map file; with CMF installed, CMF's map file
loads instead and Smooth Map's changes are lost. This adapter asks CMF's map to
move and open the way Smooth Map's does.

REQUIREMENTS
- Conjunction Map Framework with API version 6 or later (the update with smooth map
  movement). With API version 5 the adapter loads but changes nothing; with an
  older CMF the game stops at the script compile screen.
- Smooth Map 1.1 (Nexus mod 13530), installed as its author describes. The
  adapter carries Smooth Map 1.1's timing; other Smooth Map versions are not
  checked.

AUTHOR TEMPLATE ONLY
Ship this inside Smooth Map's own folder; a separate adapter folder must not declare, because it cannot tell whether Smooth Map is installed.
- This source-only example is excluded from release specifications and the in-game
  adapter table. It is not a separately distributed adapter.
- After the API version 6 gate, it declares modSmoothMap with generic property 38
  only when CMFHasProperty(38) succeeds. Older CMF retains the same behavior and
  compile floor. The declaration precedes the timing submissions.
- The template writes nothing into saves.

WHAT YOU SEE
- Holding W A S D, Z or C (or the sticks) moves and zooms the map at the same speed
  at any frame rate, without stutter at high refresh rates. The world view scrolls
  the same way.
- Snapping to a marker, centring and fades are smooth at any frame rate.
- The map opens faster: markers are ready as the map slides in, it fades in sooner,
  and the crosshair, edge arrows, legend and quest tracker fade in over 0.2 seconds.
- The map still slides up from below as the game's does; Smooth Map keeps that.
- Mouse dragging and the mouse wheel are unchanged, as with Smooth Map on its own.

WITH OTHER MAP MODS
- If another mod also sets one of these timings, the mod whose folder name sorts
  first wins that one timing. This adapter counts as Smooth Map's folder
  (modSmoothMap), so Ink and Iron and Map Quest Insight win the timings they set,
  as their own map files would; Smooth Map's other timings still apply.

AUTHOR FIXTURE
Copy the script into Mods\modSmoothMap\content\scripts\local for a controller
fixture. Keep the declaration inside Smooth Map's own folder.

CREDITS
Smooth Map is by its own author; this adapter copies none of its code or files and
only sends CMF the timing values Smooth Map uses.
