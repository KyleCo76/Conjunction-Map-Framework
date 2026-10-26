// Original hook-only fixture; session state, no settings or saved state.
@addField(CR4Game) var rev13ManagedHintsDelivered : bool;
@addField(CR4Game) var rev13ManagedHintsWithdrawn : bool;
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	var game : CR4Game;
	result = wrappedMethod(restored);
	game = theGame;
	game.rev13ManagedHintsDelivered = false;
	game.rev13ManagedHintsWithdrawn = false;
	if (CMFRequireVersion("modCMFTestRev13Look", 13))
	{
		CMFStylePart("modCMFTestRev13Look", 'opening', 'waitForMap', "", 1);
		CMFStylePart("modCMFTestRev13Look", 'hints', 'list', "", 1);
	}
	return result;
}

@wrapMethod(CMFCore)
function OnMapTab(menu : CR4MapMenu, category : string)
{
	wrappedMethod(menu, category);
	LogChannel('CMF', "CMF rev13 hooks tab=" + category);
}

@wrapMethod(CMFCore)
function OnMapHints(menu : CR4MapMenu, owner : string)
{
	var storage : CScriptedFlashValueStorage;
	var list : CScriptedFlashArray;
	var metadata : CScriptedFlashObject;
	var item : CScriptedFlashObject;
	var game : CR4Game;
	wrappedMethod(menu, owner);
	if (owner != "modCMFTestRev13Look") { return; }
	storage = menu.GetMenuFlashValueStorage();
	if (!storage) { return; }
	list = storage.CreateTempFlashArray();
	metadata = storage.CreateTempFlashObject();
	metadata.SetMemberFlashString("owner", owner);
	list.PushBackFlashObject(metadata);
	item = storage.CreateTempFlashObject();
	item.SetMemberFlashInt("actionId", 1301);
	item.SetMemberFlashInt("level", 0);
	item.SetMemberFlashInt("keyboard_keyCode", 70);
	item.SetMemberFlashInt("click", 1301);
	item.SetMemberFlashString("gamepad_navEquivalent", "gamepad_R3");
	item.SetMemberFlashString("label", GetLocStringByKeyExt("cmf_rev13_hooks_hint"));
	list.PushBackFlashObject(item);
	storage.SetFlashArray("cmf.map.hints.owned", list);
	game = theGame;
	game.rev13ManagedHintsDelivered = true;
	LogChannel('CMF', "CMF rev13 hooks hints owner=" + owner + " entries=1");
}

@wrapMethod(CMFCore)
function OnInfoFold(menu : CR4MapMenu, provider : string, open : bool)
{
	wrappedMethod(menu, provider, open);
	if (open) { LogChannel('CMF', "CMF rev13 fold provider=" + provider + " open=true"); }
	else { LogChannel('CMF', "CMF rev13 fold provider=" + provider + " open=false"); }
}

@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	var rootFlash : CScriptedFlashSprite;
	rootFlash = GetMenuFlash();
	if (rootFlash)
	{
		rootFlash.SetMemberFlashNumber("rev13OwnNumber", 13);
		rootFlash.SetMemberFlashString("rev13OwnText", "original root handshake");
	}
	wrappedMethod();
	if (rootFlash)
	{
		LogChannel('CMF', "CMF rev13 rootValues number=" + rootFlash.GetMemberFlashNumber("rev13OwnNumber") + " text=" + rootFlash.GetMemberFlashString("rev13OwnText"));
	}
}

// The managed row releases its own offer through the approved hint click hook.
@wrapMethod(CMFCore)
function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, input : string, value : int) : bool
{
	var result : bool;
	var game : CR4Game;
	result = wrappedMethod(menu, provider, id, input, value);
	game = theGame;
	if (provider == "modCMFTestRev13Look" && id == 'hints' && input == "hint" && value == 1301 &&
		game.rev13ManagedHintsDelivered && !game.rev13ManagedHintsWithdrawn)
	{
		CMFStylePart("modCMFTestRev13Look", 'hints', 'list', "unset", 0);
		game.rev13ManagedHintsWithdrawn = true;
		LogChannel('CMF', "CMF rev13 hooks hints withdrawn provider=modCMFTestRev13Look");
		menu.OnCMFMapHints();
		return true;
	}
	return result;
}
