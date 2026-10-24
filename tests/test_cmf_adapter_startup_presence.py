"""Static startup call-chain contracts; these do not execute WitcherScript."""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import cmf_pack


def source(slug):
    files = list((ROOT / "source/adapters" / slug).glob("*/content/scripts/local/*_cmf.ws"))
    assert len(files) == 1, files
    return cmf_pack.strip_comments(files[0].read_text(encoding="ascii"))


def body(text, name):
    match = re.search(r"\bfunction\s+" + name + r"\s*\([^)]*\)[^{]*\{", text)
    assert match, name
    start = match.end()
    depth = 1
    for index in range(start, len(text)):
        depth += {"{": 1, "}": -1}.get(text[index], 0)
        if depth == 0:
            return text[start:index]
    raise AssertionError("Unclosed function: " + name)


def reachable(text, name, seen=None):
    """Follow only locally defined helpers; CMF version queries are never mutations."""
    seen = set() if seen is None else seen
    if name in seen:
        return ""
    seen.add(name)
    current = body(text, name)
    result = current
    for called in re.findall(r"\b(\w+)\s*\(", current):
        if re.search(r"\bfunction\s+" + called + r"\s*\(", text):
            result += reachable(text, called, seen)
    return result


class AdapterStartupPresenceTests(unittest.TestCase):
    def assert_declaration(self, slug, provider):
        text = source(slug)
        startup = body(text, "OnGameStarted")
        call = f'CMFRegister("{provider}", 38, \'\', \'\', "", 1);'
        self.assertEqual(text.count(call), 1)
        self.assertRegex(startup, r"if \(CMFHasProperty\(38\)\)\s*\{\s*" + re.escape(call) + r"\s*\}")
        self.assertEqual(startup.count("wrappedMethod(restored)"), 1)
        self.assertLess(startup.index("wrappedMethod(restored)"), startup.index(call))
        self.assertIn("return result;", startup)
        self.assertNotIn("CMFDeclareProvider", text)
        return startup

    def test_fog_declares_without_hiding_or_feature_settings(self):
        startup = self.assert_declaration("fog-of-war", "modFogOfWar")
        self.assertNotIn("FogOfWarEnabled", startup)
        self.assertNotIn("FogOfWarFilterPins", startup)
        self.assertNotIn("CMFRequireVersion", startup)

    def test_mqi_declares_without_reading_source_mod_settings(self):
        startup = self.assert_declaration("map-quest-insight", "modMapQuestInsight")
        self.assertNotRegex(startup, r"QMI_|MqiAdapterSend|CMFRequireVersion")

    def test_smooth_author_template_declares_after_existing_gate_before_sending(self):
        startup = self.assert_declaration("smooth-map", "modSmoothMap")
        self.assertLess(startup.index('CMFRequireVersion("modSmoothMap", 6)'), startup.index("CMFHasProperty(38)"))
        self.assertLess(startup.index("CMFHasProperty(38)"), startup.index("SmoothMapAdapterSend()"))
        raw = next((ROOT / "source/adapters/smooth-map").glob("*/content/scripts/local/*_cmf.ws")).read_text()
        self.assertIn("Ship this inside Smooth Map's own folder; a separate adapter folder must not declare, because it cannot tell whether Smooth Map is installed.", raw)

    def test_eleven_existing_startup_paths_submit_provider_names(self):
        cases = [
            ("all-quest-objectives", "modAQOOMRemastered", "CMFRegisterLegendRow"),
            ("annoying-map", "modAnnoyingMap", "CMFSetProviderName"),
            ("botanist", "modBotanist", "CMFRegister"),
            ("coloured-map-markers", "modcoloured_map_marker", "CMFRegisterIcon"),
            ("community-patch", "mod000CommunityPatch_WorldMap", "CMFRegister"),
            ("gwent-players-map", "modGwentPlayersMap", "CMFRegisterIcon"),
            ("ink-and-iron", "modInkAndIronUI", "CMFStylePart"),
            ("map-pin-teleport", "modMapPinTeleport", "CMFRegister"),
            ("the-stable", "modArdDhuStable", "CMFRegister"),
            ("witcher-gear-map", "modWitcherGearMap", "CMFRegisterIcon"),
            ("witchers-path", "modWitchersPath", "CMFDraw"),
        ]
        for slug, provider, mutation in cases:
            if not (ROOT / "source/adapters" / slug).is_dir():
                continue  # source-only examples kept in the private development repository
            with self.subTest(adapter=slug):
                text = source(slug)
                chain = reachable(text, "OnGameStarted")
                self.assertRegex(chain, mutation + r'\(\s*"' + provider + r'"\s*,')
                self.assertNotRegex(text, r"CMFHasProperty\(38\)", "existing adapters need no new declaration")
        # Ink's provider-naming style is in a helper; a detached helper does not qualify.
        ink = source("ink-and-iron")
        self.assertIn("InkAdapterLookMap();", body(ink, "OnGameStarted"))
        self.assertIn('CMFStylePart("modInkAndIronUI",', body(ink, "InkAdapterLookMap"))

    def test_path_off_withdrawal_still_records_presence(self):
        text = source("witchers-path")
        self.assertIn("WpAdapterSetUp();", body(text, "OnGameStarted"))
        setup = body(text, "WpAdapterSetUp")
        self.assertRegex(setup, r"if \(WitchersPathGetVar\('WPEnabled'\) == \"false\" \|\| WitchersPathGetVar\('WPEnabled'\) == \"0\"\)\s*\{\s*CMFReleaseProvider\(\"modWitchersPath\"\);\s*return;")
        self.assertIn("WpAdapterDraw(WpAdapterSingle());", setup)
        self.assertIn('CMFDraw("modWitchersPath",', body(text, "WpAdapterDraw"))
        core = cmf_pack.strip_comments((ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text())
        self.assertIn("CMFGetCore().ReleaseProvider(provider);", body(core, "CMFReleaseProvider"))
        self.assertIn("NoteProviderPresent(provider);", body(core, "ReleaseProvider"))
        self.assertNotIn("NoteProviderPresent", body(core, "CMFRequireVersion"))

    def test_startup_submission_helpers_reach_core_presence_recording(self):
        core = cmf_pack.strip_comments((ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text())
        for helper in ("CMFRegisterLegendRow", "CMFRegisterIcon"):
            with self.subTest(helper=helper):
                self.assertIn("CMFRegister(provider,", body(core, helper))
        for mutation in ("CMFRegister", "CMFSetProviderName", "CMFStylePart", "CMFDraw"):
            with self.subTest(mutation=mutation):
                self.assertIn("NoteProviderPresent(provider);", body(core, mutation))
        # Neither a version-only adapter nor a capability query can declare presence.
        for query in ("CMFRequireVersion", "CMFHasProperty", "CMFHasAbility"):
            self.assertNotIn("NoteProviderPresent", body(core, query))

    def test_stable_missing_localization_key_stays_inert(self):
        text = source("the-stable")
        self.assertRegex(body(text, "OnGameStarted"), r"if \(StableAdapterModPresent\(\) && CMFRequireVersion\(\"modArdDhuStable\", 2\)\)\s*\{\s*CMFRegister")
        predicate = body(text, "StableAdapterModPresent")
        self.assertIn('GetLocStringByKeyExt("map_location_arddhustable")', predicate)
        self.assertIn('return StrLen(text) > 0 && !StrBeginsWith(text, "#");', predicate)


if __name__ == "__main__":
    unittest.main()
