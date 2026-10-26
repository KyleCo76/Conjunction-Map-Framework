"""Shared actual-source execution for retained legacy contracts; no mirrored registry rules."""
from types import SimpleNamespace as Obj
from ws_contract_runner import bind, run


def theme_environment(source):
    env = {"NameToString": str, "StrFindFirst": str.find}
    for name, parameters in (
            ("CMFListHas", ("list", "word")), ("CMFThemeParts", ()),
            ("CMFThemeLayers", ()), ("CMFThemeKinds", ()), ("CMFThemeGlowKeys", ()),
            ("CMFThemeShadowKeys", ()), ("CMFThemeHoverKeys", ()), ("CMFThemeTextKeys", ()),
            ("CMFThemeNavigationKeys", ()), ("CMFThemeOpeningKeys", ()),
            ("CMFThemePartKeys", ("part",)), ("CMFThemeShapeKeys", ("kind",)),
            ("CMFThemeTextKey", ("key",)), ("PartChoice", ("part",)),
            ("PartKeyChoice", ("part", "key"))):
        env[name] = bind(source, name, env, parameters)
    return env


def check_behavior_anchors(test, source, anchors):
    """Run real CMFDraw with explicit engine boundaries and a positive screen control."""
    env = theme_environment(source)
    accepted, notes = [], []
    core = Obj(NoteProviderPresent=lambda provider: True,
               UpsertTheme=lambda entry: accepted.append(entry) or True)
    env.update(theGame=Obj(CMFGetCore=lambda: core), SCMFThemeEntry=Obj,
               IsNameValid=bool, CMFLog=notes.append, provider="modP", id="sample", kind="rect")
    for anchor in anchors:
        test.assertFalse(run(source, "CMFDraw", dict(env, anchor=anchor)), anchor)
    test.assertEqual(accepted, [])
    test.assertEqual(len(notes), len(anchors))
    test.assertTrue(all("reason=unknown" in note for note in notes))
    test.assertTrue(run(source, "CMFDraw", dict(env, anchor="screen")))
    test.assertEqual([(entry.anchor, entry.key) for entry in accepted], [("screen", "rect")])
