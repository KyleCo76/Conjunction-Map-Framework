// TEST ONLY: revision 11 check pack (API version 11, "one pin"), provider modCMFTestOnePin, not a player package. No
// art: every picture is a frame of the game's own pin icon.
// - the Seven Cats Inn signpost (tag seven_cats_inn) is tinted cyan by a tag claim, its info box title reads
//   "CMF test: one signpost" and its info box is 160 px tall;
// - every signpost's info box gets one added line, "CMF test: a line added to every signpost";
// - monster nests show the blacksmith's anvil while undiscovered ("?") and the herbalist's leaf while completed; level 2
//   nests are tinted red (a level variant claim), every other nest green;
// - Geralt's arrow is magenta at twice its size; the player's first marker kind (User1) shows the herbalist's leaf;
// - the game's own signpost legend row moves to the Quests tab, first, named "CMF test signposts"; the Buffs tab is
//   hidden;
// - the info box sits 300 px right of and 200 px above the game's place (tooltip x and y);
// - the pin list log is on (CMFSetLogPins), with lines on the info box and legend row changes;
// - place claim: the first signpost (other than Seven Cats Inn) the map shows is remembered by its position, and from
//   the next map opening that one signpost is orange at two and a half times its size. The log names it.

@addField(CMFCore) var cmfTestOnePinPlaced : bool;

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	if (CMFRequireVersion("modCMFTestOnePin", 11))
	{
		CMFSetProviderName("modCMFTestOnePin", "CMF Test One Pin");
		CMFSetLogPins(true);
		CMFRegisterForTag("modCMFTestOnePin", 3, 'seven_cats_inn', '', "", 65535);
		CMFRegisterForTag("modCMFTestOnePin", 18, 'seven_cats_inn', '', "CMF test: one signpost", 0);
		CMFRegisterForTag("modCMFTestOnePin", 14, 'seven_cats_inn', '', "", 160);
		CMFRegister("modCMFTestOnePin", 19, 'RoadSign', '', "<font color='#66ffcc'>CMF test: a line added to every signpost</font>", 1);
		CMFRegister("modCMFTestOnePin", 29, 'MonsterNest', '', "frame:Blacksmith", 0);
		CMFRegister("modCMFTestOnePin", 30, 'MonsterNest', '', "frame:Herbalist", 0);
		CMFRegister("modCMFTestOnePin", 3, 'MonsterNest', '', "", 4259648);
		CMFRegister("modCMFTestOnePin", 3, 'MonsterNest_2', '', "", 16711680);
		CMFRegister("modCMFTestOnePin", 3, 'Player', '', "", 16711935);
		CMFRegister("modCMFTestOnePin", 10, 'Player', '', "", 200);
		CMFRegister("modCMFTestOnePin", 1, 'User1', '', "frame:Herbalist", 0);
		CMFRegister("modCMFTestOnePin", 6, 'RoadSign', '', "Quests", 1);
		CMFRegister("modCMFTestOnePin", 7, 'RoadSign', '', "CMF test signposts", 0);
		CMFRegister("modCMFTestOnePin", 37, 'Buffs', '', "", 1);
		CMFStylePart("modCMFTestOnePin", 'tooltip', 'x', "", 300);
		CMFStylePart("modCMFTestOnePin", 'tooltip', 'y', "", -200);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var x : float;
	var y : float;
	wrappedMethod(dataObject, mapContext);
	if (!cmfTestOnePinPlaced && dataObject.GetMemberFlashString("type") == "RoadSign" &&
		dataObject.GetMemberFlashUInt("id") != NameToFlashUInt('seven_cats_inn'))
	{
		cmfTestOnePinPlaced = true;
		x = dataObject.GetMemberFlashNumber("posX");
		y = dataObject.GetMemberFlashNumber("posY");
		CMFRegisterForPlace("modCMFTestOnePin", 10, 'RoadSign', x, y, "", 250);
		CMFRegisterForPlace("modCMFTestOnePin", 3, 'RoadSign', x, y, "", 16753920);
		LogChannel('CMF', "CMF test onepin place x=" + FloatToString(x) + " y=" + FloatToString(y) + " label=" +
			dataObject.GetMemberFlashString("label"));
	}
}
