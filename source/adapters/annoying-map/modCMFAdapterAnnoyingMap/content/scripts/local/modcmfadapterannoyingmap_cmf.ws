// Annoying Map adapter for Conjunction Map Framework. Requires CMF 9 (API revision 9) or later and Annoying Map
// 3.1 for Remastered 5.01 (Nexus 6140, folder modAnnoyingMap), which stays unchanged. Install and remove the
// two together: this file calls Annoying Map's own functions and events, so the game stops at the script
// compile screen when that mod is missing, and it wraps CMF 9's map view hooks, which earlier CMF versions do
// not have.
//
// One of Annoying Map's features comes back here: the map remembers where you left it, and at what zoom, per
// region (Velen and Novigrad share one memory, as Annoying Map's own AM_FilterArea decides).
//
// Annoying Map's own map file reports every pan (OnPositionChanged, the map container's x and y) and every
// zoom (OnZoomChanged, its scale) to Annoying Map's script, which keeps them in the save (AMap() and
// AMapZoom(), fields on Geralt's player object). CMF's map file is the one that loads, and it sends neither, so
// nothing new is remembered. Worse, Annoying Map's script opens each region at its saved zoom by setting the
// lowest and highest zoom to that one value (AM_InitZoom in its UpdateMapSettings), and only its own map file
// puts the real limits back, on the first zoom key (OnZoomMap). Under CMF nothing does, so a region with a
// saved zoom stays at that zoom.
//
// This adapter takes CMF's general map view report (OnMapView: the shown area, the centre in the same map
// units Annoying Map stores, and the zoom, sent when the map stops moving, switches region or closes) and
// writes it into Annoying Map's own storage. At each region shown (OnMapOpening) it calls Annoying Map's own
// OnZoomMap, which sends the real zoom limits it kept, and asks CMF to open that region at Annoying Map's saved
// zoom (CMFSetOpeningView). The saved place needs nothing: Annoying Map's script still sends it through the
// game's own default-position call, which CMF's map uses as the game's does.
//
// Hiding Geralt's marker, Roach, the boat and herbs is Annoying Map's own script (its mapMenu.ws) and works
// beside CMF without help, so this adapter does nothing about it.
//
// It copies no code and ships no art. Every call uses Annoying Map's own folder name as its provider, so folder
// order between mods is the same with CMF as without it.

@addField(CMFCore)
var amAdapterLogged : int;

// Annoying Map's name in CMF's in-game menu (the Opening view row), instead of the tidied folder name.
@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	var result : bool;
	result = wrappedMethod(restored);
	CMFSetProviderName("modAnnoyingMap", "Annoying Map");
	return result;
}

// Annoying Map's saved zoom for one area, or 0 when it has none (it then opens at the game's zoom).
function AmAdapterSavedZoom(area : name) : float
{
	var kept : AM_XY;
	kept = AMapZoom().GetXY(AM_FilterArea(area));
	if (!kept)
	{
		return 0;
	}
	return kept.GetX();
}

// The map stopped moving, switched region or closed: keep the view exactly as Annoying Map's own reports would
// have (place as the map container's x and y, zoom as its scale, under Annoying Map's area name).
@wrapMethod(CMFCore)
function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, worldY : float,
	zoom : float, reason : name)
{
	wrappedMethod(menu, area, x, y, worldX, worldY, zoom, reason);
	if (area == '' || area == 'AN_Undefined')
	{
		return;
	}
	AMap().SetXY(x, y, AM_FilterArea(area));
	if (zoom > 0)
	{
		AMapZoom().SetXY(zoom, zoom, AM_FilterArea(area));
	}
	// Launch evidence: the first eight kept views of the session.
	if (amAdapterLogged < 8)
	{
		amAdapterLogged += 1;
		LogChannel('CMF', "CMF adapter provider=modAnnoyingMap kept area=" + NameToString(AM_FilterArea(area)) +
			" reason=" + NameToString(reason) + " x=" + FloatToString(x) + " y=" + FloatToString(y) + " zoom=" +
			FloatToString(zoom));
	}
}

// A region map is shown (opening or region switch), after Annoying Map's script narrowed the zoom limits to its
// saved zoom. Annoying Map's own OnZoomMap puts the real limits back (the ones it kept in am_minZoom ..
// am_zoom34); CMF then opens the region at the saved zoom inside those limits, so it can never get stuck.
@wrapMethod(CMFCore)
function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)
{
	var zoom : float;
	var limits : string;
	wrappedMethod(menu, area, mapContext);
	if (!menu || area == '' || area == 'AN_Undefined')
	{
		return;
	}
	limits = "notready";
	// am_maxZoom is 0 until Annoying Map's UpdateMapSettings has run once; sending zero limits would break the map.
	if (menu.am_maxZoom > 0)
	{
		menu.OnZoomMap();
		limits = "restored";
	}
	// 0 means no saved zoom: the game's zoom, as with Annoying Map on its own. keepPlace: Annoying Map already set
	// the place.
	zoom = AmAdapterSavedZoom(area);
	CMFSetOpeningView("modAnnoyingMap", area, 0, 0, zoom, true);
	LogChannel('CMF', "CMF adapter provider=modAnnoyingMap open area=" + NameToString(AM_FilterArea(area)) +
		" context=" + NameToString(mapContext) + " zoom=" + FloatToString(zoom) + " limits=" + limits);
}
