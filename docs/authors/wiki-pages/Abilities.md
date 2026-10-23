# What do you want to change?

Find what your mod wants to do on the map, then follow the page. Every call takes your provider id (your mod's folder name) first. "Every pin of a type" calls run once at game start; "one pin" calls run while the map builds its pins, usually from the [`OnPinReady` hook](page:Pin-Hook-OnPinReady).

## Pins

| You want to | Call | Page |
| --- | --- | --- |
| Give a pin type your own icon | `CMFRegisterIcon` (one pin by tag: `CMFRegisterIconForTag`; one pin object: `CMFStylePinIcon`) | [Writing your script](page:Writing-Your-Script) |
| Give a legend row a different icon from its pins | `CMFRegisterLegendIcon` | [Writing your script](page:Writing-Your-Script) |
| Colour pins | `CMFRegisterTint`, `CMFStylePinTint` | [Writing your script](page:Writing-Your-Script) |
| Show pins greyed (still usable) | `CMFRegisterDisabled`, `CMFRegisterDisabledForTag` | [Greying pins](page:Greying-Pins) |
| Hide pins, everywhere or in one map context | `CMFRegisterHidden`, `CMFRegisterHiddenForTag`, `CMFHidePin` | [Hiding pins](page:Hiding-Pins) |
| Hide Geralt's marker | `CMFRegisterHidden` on the type `'Player'` (API version 9) | [Hiding pins](page:Hiding-Pins) |
| Make pins bigger or smaller | property `10`, `CMFStylePinScale` | [Pin size, labels and the info box](page:Pin-Size-Labels-and-Info-Box) |
| Write a label on a pin, move it or hide it | properties `11` to `13`, `CMFStylePinLabel`, `CMFLevelLabel` | [Pin size, labels and the info box](page:Pin-Size-Labels-and-Info-Box) |
| Colour a pin's label | property `17` | [The map theme](page:Map-Theme) |
| Make the pin information box taller | property `14` | [Pin size, labels and the info box](page:Pin-Size-Labels-and-Info-Box) |
| Decide per pin, from your own values | wrap `CMFCore.OnPinReady`, then any "one pin" call | [The pin hook](page:Pin-Hook-OnPinReady) |
| Do something when the player uses a pin (E, double-click, a button beside it) | properties `16`, `20`, `21`, wrap `CMFCore.OnPinClicked` | [Pin clicks](page:Pin-Clicks) |
| Fan out pins stacked on one spot | the `spread` part, property `22` | [Spreading stacked pins](page:Spreading-Stacked-Pins) |
| Change a pin another mod added | the same calls, by its type name, or by its tag when that mod gives its pin a tag id | [Porting a map mod](page:Porting-a-Map-Mod) |

## The legend and filter tabs

| You want to | Call | Page |
| --- | --- | --- |
| Put a row in a tab, name it, order it | `CMFRegisterLegendRow`, `CMFRegisterLegendLabel` (properties `6`, `7`) | [Legend rows and filter tabs](page:Legend-Rows-and-Filter-Tabs) |
| Add your own filter tab | `CMFRegisterLegendCategory` (property `8`) | [Legend rows and filter tabs](page:Legend-Rows-and-Filter-Tabs) |
| Keep your tab's rows out of Default | `CMFRegisterCategoryNoDefault` (property `23`) | [Legend rows and filter tabs](page:Legend-Rows-and-Filter-Tabs) |
| Give some quest pins their own row | a row claim on their `filteredType` | [Legend rows and filter tabs](page:Legend-Rows-and-Filter-Tabs) |
| Leave pins out of some tabs | property `15` | [Pin size, labels and the info box](page:Pin-Size-Labels-and-Info-Box) |
| React when the player switches tab | add the event `OnCMFMapFilter` on `CR4MapMenu` | [Key hints and filter tab reports](page:Key-Hints-and-Filter-Tab-Reports) |

## The map's look and behaviour

| You want to | Call | Page |
| --- | --- | --- |
| Restyle the title, legend, tooltip, tracker or key caps (fonts, colours, glows, hiding the game's plates) | `CMFStylePart` | [The map theme](page:Map-Theme), [Theme parts and keys](page:Theme-Parts-and-Keys) |
| Draw frames, plates, bands or shapes tied to any part of the screen | `CMFDraw`, `CMFDrawSet` | [The map theme](page:Map-Theme) |
| Show your own key hints inside the map | `"cmf.map.hints"`, the event `OnCMFMapHintsReady` | [Key hints and filter tab reports](page:Key-Hints-and-Filter-Tab-Reports) |
| Replace the map image of an area | `CMFRegisterBackground` | [Writing your script](page:Writing-Your-Script) |
| Change how the map pans, zooms, opens and closes | the `navigation` and `opening` parts | [Smooth map movement](page:Map-Movement) |
| Know where the player left the region map | wrap `CMFCore.OnMapView` (API version 9) | [The map's view](page:Map-View) |
| Choose the place and zoom a region map opens with | wrap `CMFCore.OnMapOpening`, `CMFSetOpeningView`, `CMFSetOpeningWorld` (API version 9) | [The map's view](page:Map-View) |
| Give the world overview your own painting, crests or markers | `CMFRegisterWorldPainting`, `CMFRegisterWorldPaintingTiles`, `CMFRegisterWorldCrest`, `CMFRegisterWorldMarker` (API version 9) | [World overview pictures](page:World-Overview-Pictures) |
| Give the map's controller buttons your own pictures | `CMFRegisterButtonPicture` (API version 9) | [Controller button pictures](page:Controller-Button-Pictures) |
| Draw lines, text or your own movie on the map itself, in world metres | `CMFDraw` on `mapSpace`, `CMFDrawSetList`, `CMFMapRefresh` | [Drawing on the map itself](page:Drawing-on-the-Map) |
| Show drawings only in one filter tab, even one with no pins | the drawing keys `tab`, `tabLabel` | [Drawing on the map itself](page:Drawing-on-the-Map) |
| Clickable boxes on the screen | the drawing keys `click` and the hover keys, wrap `CMFCore.OnDrawingClicked` | [Drawing on the map itself](page:Drawing-on-the-Map) |
| Feed drawings from data your script already sends | the drawing keys `listen`, `listenFields`, wrap `CMFCore.OnMapListening` | [Drawing on the map itself](page:Drawing-on-the-Map) |

## Your mod itself

| You want to | Call | Page |
| --- | --- | --- |
| Check the installed CMF is new enough | `CMFRequireVersion`, `CMFHasProperty`, `CMFHasAbility`, `CMFGetVersion` | [Writing your script](page:Writing-Your-Script) |
| Switch your whole mod off from its own setting | `CMFReleaseProvider` | [Shipping your mod](page:Shipping-Your-Mod) |
| Give your mod an options page under CMF's entry | your own menu file at `Mods.cmf_menu.<your slug>` | [Shipping your mod](page:Shipping-Your-Mod) |
| Show your mod under its own name in CMF's in-game menu | `CMFSetProviderName` (API version 8) | [Players' choices](page:Who-Wins-Each-Feature) |
| Apply some claims only when the player picks your mod for them (art for an optional file a script cannot detect) | `CMFRegisterChoiceOnly` (API version 9) | [Choice-only claims](page:Choice-Only-Claims) |
| See whether it worked | the script log's `CMF ...` lines | [Install and test](page:Install-and-Test) |

## What CMF does not do yet

Some things are not in this version: new pin types of CMF's own, changes to the player arrow other than hiding it, the world overview's layout, tooltip text, images as drawings, and clicks on drawings on the map itself. [Limits](page:Limits) lists them.
