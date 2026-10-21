modZZCMFTestSmooth - TEST ONLY, not a player package

The smooth map movement check for Conjunction Map Framework (smooth map movement research 2026-10-20,
section 9 step 7). Requires CMF API version 6; on an older CMF it sends nothing.

While its "Smooth Map check" switch is on (Options > Mods > Conjunction Map Framework > CMF Smooth Map Check,
default off) it sends Smooth Map's values for the map's movement and opening under its own name, read each time
the map opens. Off, it withdraws them. Its folder sorts after modMapQuestInsight, so Map Quest Insight's values
win wherever both set one.

Install: copy the folder into Mods, its menu file into bin\config\r4game\user_config_matrix\pc and its string
tables into the folder's content, for a probe launch only. Remove: delete the folder and the menu file.
