// Conjunction Map Framework settings: hidden values stored in dx12user.settings under [CMFSettings].
// The menu group has no visible rows, so it adds no Options page. Values are read on demand;
// the core reads them when it prepares winners, which follows each map opening that changed claims.

// Provider folder names from CMFProviderOrder1 to CMFProviderOrder8, earliest first, joined with commas;
// empty means folder-name order. Each value holds one name, because the game's settings reader ends a
// value at its first comma (provider order launch, 2026-10-20). Spaces are ignored and empty slots skipped.
// The core reads it once each time it prepares winners (CMFCore.Prepare).
function CMFSettingsProviderOrder() : string
{
	var order : string;
	order = "";
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder1');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder2');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder3');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder4');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder5');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder6');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder7');
	order = CMFSettingsAddProvider(order, 'CMFProviderOrder8');
	return order;
}

function CMFSettingsAddProvider(order : string, slot : name) : string
{
	var provider : string;
	provider = StrReplaceAll(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', slot), " ", "");
	if (provider == "")
	{
		return order;
	}
	if (order == "")
	{
		return provider;
	}
	return order + "," + provider;
}

// Sort key for a provider in an order read by CMFSettingsProviderOrder (lower comes first), ignoring
// case like the game's folder order; -1 when it is not listed.
function CMFSettingsProviderRank(order : string, provider : string) : int
{
	if (order == "" || provider == "")
	{
		return -1;
	}
	return StrFindFirst("," + StrLower(order) + ",", "," + StrLower(provider) + ",");
}

// Version 8: a per-feature choice as written in a setting ([CMFSettings] CMFFile_<key>, or a menu row): spaces
// removed; "vanilla" or "off" in any case read "vanilla"; "", "auto", "automatic" and "default" read "" (Automatic);
// anything else is a folder name, kept as written. One word per value, never a comma. The core reads every
// CMFFile_ value of the group each time it prepares winners (CMFCore.ReadChoices).
function CMFSettingsChoiceValue(value : string) : string
{
	var word : string;
	var lowered : string;
	word = StrReplaceAll(value, " ", "");
	lowered = StrLower(word);
	if (lowered == "vanilla" || lowered == "off")
	{
		return "vanilla";
	}
	if (lowered == "" || lowered == "-1" || lowered == "auto" || lowered == "automatic" || lowered == "default")
	{
		return "";
	}
	return word;
}

// The who-wins report (CMFCore.ReportChoices) when true.
function CMFSettingsDebug() : bool
{
	return theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFDebug') == "true";
}

// Version 11: the pin list in the log (CMFCore.NoteListPin) when "1" or "true", read at each map build. For authors
// finding a pin's tag; a value the game never stored reads "-1", which is off.
function CMFSettingsLogPins() : bool
{
	var value : string;
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFLogPins'));
	return value == "1" || value == "true";
}

// Version 17 (hidden, no menu entry): the map panel reuses the pin clips of the last build when a full pin update (a quest
// tracked, a filter toggled) draws the same pins again. On unless "0", "false" or "off" is stored, read at each theme send;
// a value the game never stored reads "-1", which is on. For a before and after comparison in a log.
function CMFSettingsPinRecycle() : bool
{
	var value : string;
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFPinRecycle'));
	return value != "false" && value != "0" && value != "off";
}

// Version 11: warn once per session if a fully shown map closes without CMF's panel callbacks.
// Missing values (including the game's "-1") keep it on; only "false" or "0" turn it off.
function CMFSettingsMapCheck() : bool
{
	var value : string;
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFMapCheck'));
	return value != "false" && value != "0";
}

// API 14: the animation frame rate, read once per opening; 0 is Off. A stored optional menu answer (option
// position 0-3: Off, 10, 15, 30) overrides the hidden file switch (false or 0 = Off, 10/15/30, else 15).
function CMFSettingsAnimatedPins(menuPresent : bool) : int
{
	var value : string;
	if (menuPresent)
	{
		value = theGame.GetInGameConfigWrapper().GetVarValue('CMFMenuGeneral', 'CMFAnimatedPins');
		// The menu stores the option position: 0 = Off, 1 = 10, 2 = 15, 3 = 30. Each rate divides 30.
		if (value == "0") { return 0; }
		if (value == "1") { return 10; }
		if (value == "2") { return 15; }
		if (value == "3") { return 30; }
	}
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFAnimatedPins'));
	if (value == "false" || value == "0") { return 0; }
	if (value == "10" || value == "15" || value == "30") { return StringToInt(value); }
	return 15;
}

// API 14: hold moving pin pictures while the map moves, read once per opening. Menu answer 0/1 first, then the
// hidden file switch (false or 0 = Off, anything else On).
function CMFSettingsAnimationDragPause(menuPresent : bool) : bool
{
	var value : string;
	if (menuPresent)
	{
		value = theGame.GetInGameConfigWrapper().GetVarValue('CMFMenuGeneral', 'CMFAnimationDragPause');
		if (value == "0" || value == "1") { return value == "1"; }
	}
	value = StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFAnimationDragPause'));
	return value != "false" && value != "0";
}

// The animation picture cache's ceiling in MiB: the menu row stores its option position (0 = Normal 32, 1 = Large 64,
// 2 = Huge 128); the file key holds 32, 64 or 128. Anything else is 64.
function CMFSettingsAnimationMemory(menuPresent : bool) : int
{
	var value : string;
	if (menuPresent)
	{
		value = theGame.GetInGameConfigWrapper().GetVarValue('CMFMenuGeneral', 'CMFAnimationMemory');
		if (value == "0") { return 32; }
		if (value == "1") { return 64; }
		if (value == "2") { return 128; }
	}
	value = theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFAnimationMemory');
	if (value == "32") { return 32; }
	if (value == "128") { return 128; }
	return 64;
}
