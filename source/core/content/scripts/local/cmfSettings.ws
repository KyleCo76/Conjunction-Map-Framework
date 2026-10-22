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
	if (lowered == "" || lowered == "auto" || lowered == "automatic" || lowered == "default")
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
