// Pre-change text (before the theme memo) of the functions the equality test compares against, from the base of the theme send speed branch.
// Copied as it was; the functions keep their plain names.

	private function ThemeStyleOwner(part : name, key : name) : string
	{
		var i, choice, keyChoice : int;
		var owner, answer : string;
		var perKey : bool;
		var ownershipKey : name;
		// Version 14: the edge frame goes with the map's top edge. While any provider sends map top, the frame keys
		// belong to top's owner (worked out among top's senders only, as before); only when nobody sends top do the
		// frame senders decide among themselves.
		if (part == 'map' && (key == 'frame' || key == 'frameTop' || key == 'frameBottom'))
		{
			for (i = 0; i < themeEntries.Size(); i += 1)
			{
				if (themeEntries[i].kind == 1 && themeEntries[i].target == 'map' && themeEntries[i].key == 'top')
				{
					return ThemeStyleOwner('map', 'top');
				}
			}
		}
		ownershipKey = ThemeOwnershipKey(part, key);
		perKey = part == 'map' || part == 'navigation' || part == 'opening' || part == 'spread' || part == 'wide' ||
			(part == 'hints' && key == 'list');
		owner = "";
		keyChoice = PartKeyChoice(part, key);
		choice = -1;
		answer = "";
		if (choicesActive)
		{
			choice = keyChoice;
			if (choice >= 0)
			{
				answer = decideAnswer[choice];
			}
			if (answer == "vanilla")
			{
				return "";
			}
			if (answer == "@order")
			{
				answer = "";
			}
		}
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 && themeEntries[i].target == part &&
				((perKey && ThemeOwnershipKey(part, themeEntries[i].key) == ownershipKey) ||
				(!perKey && themeEntries[i].key != 'list' &&
				PartKeyChoice(part, themeEntries[i].key) == keyChoice)) &&
				!ChoiceOnlySkips(keyChoice, themeEntries[i].provider))
			{
				if (answer != "" && themeEntries[i].provider == answer)
				{
					return answer;
				}
				if (owner == "" || PieceBeats(choice, themeEntries[i].provider, owner))
				{
					owner = themeEntries[i].provider;
				}
			}
		}
		if (answer != "" && fallVanilla)
		{
			return "";
		}
		return owner;
	}

	private function ThemeDrawingOwner(id : name) : string
	{
		var i : int;
		var owner : string;
		owner = "";
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].target == id && AdditiveAllows(10, themeEntries[i].provider) &&
				(owner == "" || CMFProviderBeats(themeEntries[i].provider, owner)))
			{
				owner = themeEntries[i].provider;
			}
		}
		return owner;
	}

	// Map-space drawing: the kind of the drawing this provider made with this id ('' before CMFDraw).
	public function DrawingKind(provider : string, id : name) : name
	{
		var i : int;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 2 && themeEntries[i].provider == provider && themeEntries[i].target == id)
			{
				return themeEntries[i].key;
			}
		}
		return '';
	}

	// Version 15: a provider's drawing pinned to a panel it also styles belongs to its look of that panel, so it is left
	// out while another provider (or Vanilla, owner "vanilla") wins that panel's look. A provider that only draws on a
	// panel it does not style keeps its drawing. Only look keys count: a key that answers another piece (the info box's clear* and
	// tall* places, fold keys, show) does not tie the drawing to the look. owner is the winner of the panel's look.
	private function PanelDrawingLeftOut(entryValue : SCMFThemeEntry, out owner : string) : bool
	{
		var root : name;
		var i : int;
		root = DrawingRoot(entryValue.target);
		if (!PanelPart(root)) { return false; }
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind == 1 && themeEntries[i].target == root && themeEntries[i].key != 'list' &&
				themeEntries[i].provider == entryValue.provider && PartKeyChoice(root, themeEntries[i].key) == ThemeLookChoice(root))
			{
				owner = ThemeStyleOwner(root, themeEntries[i].key);
				if (owner == entryValue.provider) { return false; }
				if (owner == "") { owner = "vanilla"; }
				return true;
			}
		}
		return false;
	}

	// Position of a provider in folder order among the theme's providers (0 = earliest folder).
	private function ThemeFolderRank(provider : string) : int
	{
		var i, rank : int;
		var counted : array<string>;
		rank = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].provider != provider && !counted.Contains(themeEntries[i].provider) &&
				CMFProviderBeats(themeEntries[i].provider, provider))
			{
				counted.PushBack(themeEntries[i].provider);
				rank += 1;
			}
		}
		return rank;
	}

	public function SendTheme(storage : CScriptedFlashValueStorage)
	{
		var flashArray : CScriptedFlashArray;
		var item : CScriptedFlashObject;
		var owner : string;
		var i, k, sent, ownMotion : int;
		if (!storage)
		{
			return;
		}
		if (dirty) { Prepare(); }
		flashArray = storage.CreateTempFlashArray();
		sent = 0;
		for (i = 0; i < themeEntries.Size(); i += 1)
		{
			if (themeEntries[i].kind != 1 && IsSpaceDrawing(themeEntries[i].target))
			{
				continue;
			}
			if (themeEntries[i].kind == 1)
			{
				owner = ThemeStyleOwner(themeEntries[i].target, themeEntries[i].key);
				if (owner != themeEntries[i].provider)
				{
					if (owner == "") { owner = "vanilla"; }
					NoteTheme("theme style shadowed provider=" + themeEntries[i].provider + " part=" +
						NameToString(themeEntries[i].target) + " piece=" +
						ChoiceKey(PartKeyChoice(themeEntries[i].target, themeEntries[i].key)) + " by=" + owner);
					continue;
				}
			}
			else
			{
				if (!AdditiveAllows(10, themeEntries[i].provider))
				{
					NoteTheme("theme drawing left out provider=" + themeEntries[i].provider + " id=" +
						NameToString(themeEntries[i].target) + " reason=choice");
					continue;
				}
				owner = ThemeDrawingOwner(themeEntries[i].target);
				if (owner == "")
				{
					NoteTheme("theme key without drawing provider=" + themeEntries[i].provider + " id=" +
						NameToString(themeEntries[i].target));
					continue;
				}
				if (owner != themeEntries[i].provider)
				{
					NoteTheme("theme drawing refused provider=" + themeEntries[i].provider + " id=" +
						NameToString(themeEntries[i].target) + " owner=" + owner);
					continue;
				}
			}
			if (themeEntries[i].kind != 1 && PanelDrawingLeftOut(themeEntries[i], owner))
			{
				NoteTheme("theme drawing left out provider=" + themeEntries[i].provider + " id=" +
					NameToString(themeEntries[i].target) + " reason=panel by=" + owner);
				continue;
			}
			if (themeEntries[i].kind != 1 && !DrawingSourceOk(themeEntries[i])) { continue; }
			item = storage.CreateTempFlashObject();
			item.SetMemberFlashInt("k", themeEntries[i].kind);
			item.SetMemberFlashString("t", NameToString(themeEntries[i].target));
			item.SetMemberFlashString("a", NameToString(themeEntries[i].anchor));
			item.SetMemberFlashString("y", NameToString(themeEntries[i].key));
			item.SetMemberFlashString("s", themeEntries[i].text);
			item.SetMemberFlashNumber("n", themeEntries[i].number);
			item.SetMemberFlashInt("p", ThemeFolderRank(themeEntries[i].provider));
			item.SetMemberFlashInt("o", themeEntries[i].order);
			WriteDrawingMetadata(item, themeEntries[i], storage);
			WriteFoldMetadata(item, themeEntries[i], storage);
			if (themeEntries[i].kind == 4)
			{
				item.SetMemberFlashInt("c", themeEntries[i].values.Size());
				for (k = 0; k < themeEntries[i].values.Size(); k += 1)
				{
					item.SetMemberFlashNumber("v" + k, themeEntries[i].values[k]);
				}
			}
			flashArray.PushBackFlashObject(item);
			sent += 1;
		}
		ownMotion = SendDefaultMotion(storage, flashArray);
		SendWideVanilla(storage, flashArray);
		SendLookOwners(storage);
		SendMovieTags(storage);
		storage.SetFlashArray("cmf.map.theme", flashArray);
		NoteTheme("theme sent entries=" + sent + " of=" + themeEntries.Size() + " cmfMotion=" + ownMotion);
		SendWorld(storage);
		SendItemStyles(storage);
		SendLegendRowArt(storage);
	}
