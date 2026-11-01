"""Author parser parity and real animated asset cooking (offline checks only)."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import cmf_pack
import cmf_texture_cache as cache
from rev14_animation_contracts import actual_parse, parser_environment
from test_cmf_pack import WRAP, make_pack, flat_icon


class AnimationParserTests(unittest.TestCase):
    def parser(self):
        self.assertIsNotNone(importlib.util.find_spec("cmf_animation"), "shipping animation parser is missing")
        import cmf_animation
        return cmf_animation

    def test_shipping_parser_matches_shared_vectors_and_executed_core(self):
        parser = self.parser()
        vectors = json.loads((ROOT / "tests/fixtures/animated_pins_cases.json").read_text(encoding="utf-8"))
        env = parser_environment()
        self.assertEqual(len(vectors), 69)
        for case in vectors:
            with self.subTest(case=case["name"]):
                core = actual_parse(case["text"], case["fps"], env)
                expected = {key: case[key] for key in ("ok", "canonical", "poster", "reason")}
                self.assertEqual(core, expected)
                if case["ok"]:
                    parsed = parser.parse_animation(case["text"], case["fps"])
                    self.assertEqual(parsed["canonical"], core["canonical"])
                    self.assertEqual(parsed["poster"], core["poster"])
                else:
                    with self.assertRaises(ValueError) as caught:
                        parser.parse_animation(case["text"], case["fps"])
                    self.assertEqual(str(caught.exception), core["reason"])

    def test_paths_are_poster_first_then_authored_positions_with_deduplication(self):
        parser = self.parser()
        program = parser.parse_animation("program:v1|poster=img://icons/modp/p.png|"
            "stage=a;frames=img://icons/modp/a.png,frame:Shopkeeper;plays=1|"
            "stage=b;frames=img://icons/modp/b.png,img://icons/modp/a.png;plays=forever", 8)
        self.assertEqual(parser.animation_paths(program), ("img://icons/modp/p.png",
            "img://icons/modp/a.png", "frame:Shopkeeper", "img://icons/modp/b.png"))
        self.assertEqual((program["delay"], program["finish"], program["repeat"], program["repeatFrom"]),
                         ("0", "restore", "1", "a"))
        self.assertEqual(len(program["stages"]), 2)


class AnimatedPackTests(unittest.TestCase):
    def script(self, text, prop=45, number=8, call="CMFRegister"):
        args = '\'MonsterNest\', 0, 0' if call == "CMFRegisterForPlace" else "'MonsterNest', ''"
        return WRAP % ('\tif (CMFHasProperty(%d)) { %s("modAcmeIcons", %d, %s, %s, %d); }\n'
                       % (prop, call, prop, args, text, number))

    def art(self, names, size=64, transparent=False):
        return {name: cmf_pack.write_png(size, size, bytes(size*size*4) if transparent else flat_icon(size))
                for name in names}

    def check(self, script, art=None):
        with tempfile.TemporaryDirectory(dir=ROOT / "build") as root:
            return cmf_pack.check_pack(make_pack(root, "modAcmeIcons", script, art))

    def test_plain_sixteen_frames_are_used_and_cooked_once(self):
        names = ["f%d.png" % i for i in range(16)]
        text = ','.join("img://icons/modacmeicons/" + name for name in names)
        report, plan = self.check(self.script('"' + text + '"'), self.art(names))
        self.assertEqual(report.errors, [])
        self.assertFalse(any("not used" in w for w in report.warnings), report.warnings)
        keys = [e[0] for e in cache.read_entries(plan["files"]["content/texture.cache"])]
        self.assertEqual(set(keys), {"gameplay\\gui_new\\icons\\modacmeicons\\" + name for name in names})

    def test_intro_tail_poster_and_literal_concatenation_are_all_validated(self):
        names = ["intro%d.png" % i for i in range(12)] + ["tail%d.png" % i for i in range(16)] + ["poster.png"]
        url = lambda name: "img://icons/modacmeicons/" + name
        text = ('"program:v1|poster=' + url("poster.png") + '|" +\n'
                '"stage=intro;frames=' + ','.join(map(url, names[:12])) + '|" +\n'
                '"stage=tail;frames=' + ','.join(map(url, names[12:28])) + ',' + url("intro0.png") + ';plays=forever"')
        # Keep the tail at 16 authored positions while repeating one path from the intro.
        text = text.replace(url("tail15.png") + ',', '')
        report, plan = self.check(self.script(text, prop=46), self.art(names))
        self.assertEqual(report.errors, [])
        self.assertEqual(len(cache.read_entries(plan["files"]["content/texture.cache"])), len(names))
        self.assertFalse(any("not used" in w and "tail15.png" not in w for w in report.warnings), report.warnings)
        missing = self.art(names)
        del missing["tail14.png"]
        report, _ = self.check(self.script(text), missing)
        self.assertTrue(any("tail14.png has no image" in e for e in report.errors), report.errors)
        self.assertFalse(any(";frames=" in e for e in report.errors), report.errors)

    def test_stock_frames_need_no_png_and_place_claim_discovers_assets(self):
        report, _ = self.check(self.script('"frame:Shopkeeper,frame:Herbalist"'))
        self.assertEqual(report.errors, [])
        report, _ = self.check(self.script('"img://icons/modacmeicons/a.png,frame:Shopkeeper"', call="CMFRegisterForPlace"))
        self.assertTrue(any("a.png has no image" in e for e in report.errors), report.errors)

    def test_transparent_animation_is_valid_and_canvas_difference_warns(self):
        art = self.art(["blank.png"], transparent=True) | self.art(["b.png"], size=96)
        report, _ = self.check(self.script('"img://icons/modacmeicons/blank.png,img://icons/modacmeicons/b.png"'), art)
        self.assertEqual(report.errors, [])
        self.assertFalse(any("fully transparent" in w for w in report.warnings), report.warnings)
        self.assertTrue(any("canvas" in w for w in report.warnings), report.warnings)
        report, _ = self.check(self.script('"img://icons/modacmeicons/blank.png"', prop=1, number=0), art)
        self.assertTrue(any("fully transparent" in w for w in report.warnings))

    def test_dynamic_text_reports_limitation_and_still_cooks_all_art(self):
        script = self.script('"program:v1|" + stages')
        report, plan = self.check(script, self.art(["a.png"]))
        self.assertEqual(report.errors, [])
        self.assertTrue(any("non-literal" in w and "cannot check" in w for w in report.warnings), report.warnings)
        self.assertIn("content/texture.cache", plan["files"])

    def test_static_delimiter_url_is_one_unchanged_image(self):
        for text in ('img://other/a,b.png', 'img://other/a;b.png'):
            report, plan = self.check(self.script('"' + text + '"', prop=1, number=0))
            self.assertEqual(report.errors, [])
            self.assertEqual(plan["claims"][0]["url"], text)

    def test_animation_withdrawal_and_offset_zero_are_distinct(self):
        report, _ = self.check(self.script('"not an animation"', number=0))
        self.assertEqual(report.errors, [])
        report, _ = self.check(self.script('""', prop=47, number=0))
        self.assertEqual(report.errors, [])
        for offset in (-1, 16):
            report, _ = self.check(self.script('""', prop=47, number=offset))
            self.assertTrue(any("offset range" in e for e in report.errors), report.errors)

    def test_all_supported_zero_spellings_withdraw_without_scanning_assets(self):
        targets = {
            "CMFRegister": "'MonsterNest', ''",
            "CMFRegisterForTag": "'sample_tag', ''",
            "CMFRegisterForPlace": "'MonsterNest', 0, 0",
            "CMFStylePin": "pin",
        }
        for call, target in targets.items():
            for prop in (45, 46):
                for number in ("0", "-0", "00", "-000", "0x0", "0x00", "0X0", "0X000"):
                    for text in ('"img://icons/modacmeicons/missing.png," + tail',
                                 '"img://icons/modacmeicons/missing.png,frame:a"'):
                        with self.subTest(call=call, prop=prop, number=number, dynamic="+" in text):
                            args = ('"modAcmeIcons", pin, %d' % prop if call == "CMFStylePin"
                                    else '"modAcmeIcons", %d, %s' % (prop, target))
                            script = WRAP % ('\t%s(%s, %s, %s);\n' % (call, args, text, number))
                            report, plan = self.check(script)
                            self.assertEqual(report.errors, [])
                            self.assertEqual(plan["claims"], [])

    def test_invalid_program_reports_core_reason_without_filename_error(self):
        report, _ = self.check(self.script('"program:v1|auto=off|stage=a;frames=frame:a,frame:b"'))
        self.assertTrue(any("program options" in e for e in report.errors), report.errors)
        self.assertFalse(any("has no image" in e for e in report.errors))

    def test_withdrawn_or_refused_constant_text_never_becomes_asset_names(self):
        for number, text, errors in ((0, "img://icons/modacmeicons/missing.png,frame:a", False),
                                      (8, "img://icons/modacmeicons/missing.png", True)):
            report, _ = self.check(self.script('"' + text + '"', number=number))
            self.assertEqual(bool(report.errors), errors, report.errors)
            self.assertFalse(any("has no image" in e for e in report.errors), report.errors)

    def test_dynamic_animation_discovers_complete_literal_assets_conservatively(self):
        report, _ = self.check(self.script('"img://icons/modacmeicons/a.png," + next_frame'))
        self.assertTrue(any("non-literal" in w for w in report.warnings), report.warnings)
        self.assertTrue(any("a.png has no image" in e for e in report.errors), report.errors)
        self.assertFalse(any("a.png, has no image" in e for e in report.errors), report.errors)

    def test_direct_pin_animation_parses_the_complete_descriptor(self):
        script = WRAP % ('\tCMFStylePin("modAcmeIcons", pin, 45, '
            '"program:v1|stage=a;frames=img://icons/modacmeicons/a.png,frame:Shopkeeper", 8);\n')
        report, _ = self.check(script, self.art(["a.png"]))
        self.assertEqual(report.errors, [])
        self.assertFalse(any("not used" in w for w in report.warnings), report.warnings)
        report, _ = self.check(script)
        self.assertTrue(any("a.png has no image" in e for e in report.errors), report.errors)
        report, _ = self.check(script.replace(', 8);', ', 0);'))
        self.assertEqual(report.errors, [])
        report, _ = self.check(script.replace('"program:v1|stage=a;frames=img://icons/modacmeicons/a.png,frame:Shopkeeper"', '"frame:a"'))
        self.assertTrue(any("frame paths" in e for e in report.errors), report.errors)

    def test_transparency_warning_is_retained_for_shared_static_usage(self):
        script = self.script('"img://icons/modacmeicons/blank.png,frame:Shopkeeper"')
        script += '\nfunction DrawStill() { CMFStylePinIcon("modAcmeIcons", pin, "img://icons/modacmeicons/blank.png"); }\n'
        report, _ = self.check(script, self.art(["blank.png"], transparent=True))
        self.assertEqual(report.errors, [])
        self.assertTrue(any("fully transparent" in w for w in report.warnings), report.warnings)

    def test_matching_property_guard_satisfies_api14_advisory(self):
        report, _ = self.check(self.script('"frame:a,frame:b"'))
        self.assertFalse(any("needs API 14" in n for n in report.notes), report.notes)
        report, _ = self.check(self.script('"frame:a,frame:b"').replace('CMFHasProperty(45)', 'CMFHasProperty(1)'))
        self.assertTrue(any("needs API 14" in n for n in report.notes), report.notes)

    def test_static_dynamic_url_prefixes_keep_legacy_asset_discovery(self):
        script = WRAP % ('\tCMFStylePinIcon("modAcmeIcons", pin, "img://icons/modacmeicons/" + "badge_" + kind + ".png");\n')
        report, _ = self.check(script)
        self.assertEqual(report.errors, [])
        script = WRAP % ('\tCMFStylePinIcon("modAcmeIcons", pin, "img://icons/modacmeicons/");\n')
        report, _ = self.check(script)
        self.assertEqual(report.errors, [])

    def test_api14_named_properties_and_readme_advisory(self):
        script = WRAP % ('\tCMFRegister("modAcmeIcons", CMFPropertyIconFrames(), \'MonsterNest\', \'\', "frame:a,frame:b", 8);\n')
        report, _ = self.check(script)
        self.assertEqual(report.errors, [])
        self.assertTrue(any("API 14" in n and "compiles" in n for n in report.notes), report.notes)
        self.assertEqual(cmf_pack.PROPERTY_IDS["CMFPropertyIconUnderFrames"], 46)
        self.assertEqual(cmf_pack.PROPERTY_IDS["CMFPropertyFrameOffset"], 47)

    def test_static_build_manifest_keeps_legacy_shape(self):
        with tempfile.TemporaryDirectory(dir=ROOT / "build") as root:
            pack = make_pack(root, "modAcmeIcons", self.script('"frame:Shopkeeper"', prop=1, number=0))
            report, manifest = cmf_pack.build_pack(pack, Path(root)/"out")
            self.assertEqual(report.errors, [])
            self.assertEqual(manifest["schema"], "cmf-pack-build-1")
            self.assertEqual(manifest["claims"], [{"call": "CMFRegister", "target": "MonsterNest", "value": "frame:Shopkeeper"}])


class AnimationAuthorDocsTests(unittest.TestCase):
    def test_generated_reference_places_new_properties_at_api14(self):
        import cmf_author_docs
        build = cmf_author_docs.Build()
        pages, _ = build.run()
        self.assertEqual(build.errors, [])
        for prop, function in ((45, "CMFPropertyIconFrames"), (46, "CMFPropertyIconUnderFrames"), (47, "CMFPropertyFrameOffset")):
            self.assertIn('| `%d` | `%s()` | 14 |' % (prop, function), pages["API-Reference.md"])
        self.assertIn("Animated-Pictures.md", pages)
