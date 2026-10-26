// TEST ONLY: CMF API13 core claims. Original fixture, not a release package.
// NoticeBoardFull is a separate, unclaimed type; check only the added sample pin.
@addField(CR4Game) var rev13SampleSeeded : bool;
@addField(CR4Game) var rev13SampleLogged : bool;
@addField(CR4Game) var rev13BoatLogged : bool;

function Rev13FixtureWithdraw() : bool
{
	return false; // A/B withdrawal flag
}

// The log's variant word; the game has no function that turns a bool into text.
function Rev13FixtureVariant() : string
{
	if (Rev13FixtureWithdraw())
	{
		return "true";
	}
	return "false";
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	var game : CR4Game;
	result = wrappedMethod(restored);
	game = theGame;
	game.rev13SampleSeeded = false;
	game.rev13SampleLogged = false;
	game.rev13BoatLogged = false;
	if (CMFRequireVersion("modCMFTestRev13Claims", 13))
	{
		CMFSetProviderName("modCMFTestRev13Claims", "CMF API13 review sample");
		CMFRegister("modCMFTestRev13Claims", 1, 'NoticeBoard', '', "img://icons/modcmftestrev13claims/noticeboard_test.png", 0);
		CMFRegister("modCMFTestRev13Claims", 10, '', '', "", 120);
		CMFRegister("modCMFTestRev13Claims", 10, 'Boat', '', "", 100);
		if (Rev13FixtureWithdraw())
		{
			CMFRegister("modCMFTestRev13Claims", 40, 'NoticeBoard', '', "", 1);
		}
		LogChannel('CMF', "CMF rev13 fixture variant=" + Rev13FixtureVariant() + " api=" + CMFGetVersion());
	}
	return result;
}

// The fixture wrapper registers before the existing full-build chain; it never requests a refresh.
@wrapMethod(CR4MapMenu)
function UpdateData(optional ignoreSelectionChange : bool)
{
	var game : CR4Game;
	var player : CActor;
	var position : Vector;
	game = theGame;
	player = thePlayer;
	if (!game.rev13SampleSeeded && player && IsCurrentAreaShown() && IsNameValid(m_shownArea) &&
		m_shownArea != 'AN_Undefined' && CMFGetVersion() >= 13)
	{
		position = player.GetWorldPosition();
		game.rev13SampleSeeded = CMFAddPin("modCMFTestRev13Claims", 'modCMFTestRev13Claims.sample', 'NoticeBoard',
			m_shownArea, position.X + 200.0, position.Y, GetLocStringByKeyExt("cmf_rev13_added_pin_label"),
			GetLocStringByKeyExt("cmf_rev13_added_pin_description"));
	}
	wrappedMethod(ignoreSelectionChange);
}

// Same-class wrapper: Find reads the actual prepared claim winner, not an assumed provider.
@wrapMethod(CMFCore)
function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)
{
	var game : CR4Game;
	var claim : SCMFClaim;
	var owner : string;
	wrappedMethod(dataObject, mapContext);
	game = theGame;
	if (!dataObject) { return; }
	if (!game.rev13SampleLogged && dataObject.GetMemberFlashUInt("id") == NameToFlashUInt('modCMFTestRev13Claims.sample'))
	{
		owner = "none";
		if (Find(1, "NoticeBoard", '', 1, claim)) { owner = claim.provider; }
		if (dataObject.GetMemberFlashString("cmfIconBy") != "") { owner = dataObject.GetMemberFlashString("cmfIconBy"); }
		LogChannel('CMF', "CMF rev13 sample variant=" + Rev13FixtureVariant() + " iconOwner=" + owner +
			" sizePercent=" + FloatToString(dataObject.GetMemberFlashNumber("cmfIconScale") * 100.0) +
			" x=" + FloatToString(dataObject.GetMemberFlashNumber("posX")) +
			" y=" + FloatToString(dataObject.GetMemberFlashNumber("posY")) + " label=" + dataObject.GetMemberFlashString("label"));
		game.rev13SampleLogged = true;
	}
	if (!game.rev13BoatLogged && (dataObject.GetMemberFlashString("type") == "Boat" || dataObject.GetMemberFlashString("filteredType") == "Boat"))
	{
		LogChannel('CMF', "CMF rev13 boat variant=" + Rev13FixtureVariant() +
			" sizePercent=" + FloatToString(dataObject.GetMemberFlashNumber("cmfIconScale") * 100.0));
		game.rev13BoatLogged = true;
	}
}
