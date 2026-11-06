"""The claims the Customizer add-on really sends pass the core's acceptance rules (text, target, level, marks).

Runs the core's own CMFPropertyTextFree, CMFHasProperty, EveryPinProperty, CMFOnePinProperty and
PlayerSettingRefusal against every CMFRegister call and every mark in the add-on script. A mismatch like
"property 51 rejected: reason=empty" fails here instead of in a launch. Skipped where the add-on is not in the tree.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import re
import unittest

from ws_contract_runner import bind
from ws_text import ROOT, core_text

CORE = core_text()
ADDON = ROOT / 'source/addons/customizer/modCMFCustomizer/content/scripts/local/modcmfcustomizer.ws'


def core_rules():
    env = {}
    for name, value in re.findall(r"function (CMF\w+)\(\) : int \{ return (\d+); \}", CORE):
        env[name] = lambda value=int(value): value
    env['CMFIsPictureProperty'] = lambda p: 24 <= p <= 27
    env['CMFIsClickProperty'] = lambda p: p in (16, 20, 21)
    for name, params in (('CMFPropertyTextFree', ('propertyId',)), ('CMFHasProperty', ('propertyId',)),
                         ('CMFOnePinProperty', ('propertyId',)), ('EveryPinProperty', ('propertyId',)),
                         ('PlayerSettingRefusal', ('id',))):
        env[name] = bind(CORE, name, env, params)
    return env


@unittest.skipUnless(ADDON.exists(), 'the Customizer add-on is not in this tree')
class AddonClaims(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = ADDON.read_text(encoding='utf-8')
        cls.rules = core_rules()
        cls.calls = re.findall(r"CMFRegister\(CMFCZProvider\(\),\s*(\d+),\s*([^,]+),\s*('[^']*'),\s*([^,]+),\s*([^)]+)\)", cls.text)

    def test_the_add_on_sends_the_properties_it_says(self):
        ids = sorted({int(c[0]) for c in self.calls})
        for wanted in (9, 28, 36, 40, 50, 51, 52, 53):
            self.assertIn(wanted, ids)

    def test_every_claim_is_known_and_empty_text_is_allowed_only_where_the_core_allows_it(self):
        for prop, target, context, text, number in self.calls:
            prop = int(prop)
            if prop == 50:
                continue
            effective = int(number) if prop == 40 and number.strip().isdigit() else prop
            self.assertTrue(self.rules['CMFHasProperty'](effective), prop)
            if text.strip() == '""' and prop != 40:
                self.assertTrue(self.rules['CMFPropertyTextFree'](prop), 'property %d is sent with empty text but is not text free' % prop)
            if target.strip() != "''":
                self.assertTrue(self.rules['CMFHasProperty'](prop))

    def test_every_pin_target_only_where_the_core_takes_it(self):
        self.assertTrue(self.rules['EveryPinProperty'](53))
        for prop in (51, 52):
            self.assertTrue(self.rules['EveryPinProperty'](prop))
            self.assertTrue(self.rules['CMFOnePinProperty'](prop))
        self.assertFalse(self.rules['CMFOnePinProperty'](53))

    def test_marks_are_all_markable(self):
        marks = {int(m) for m in re.findall(r'marks\s*\+?=\s*"(\d+)"', self.text)}
        self.assertEqual(marks, {28, 36, 53})
        for mark in marks:
            self.assertEqual(self.rules['PlayerSettingRefusal'](mark), '', mark)

    def test_every_marked_property_has_a_claim_behind_it(self):
        sent = {int(c[0]) for c in self.calls}
        for mark in (28, 36, 53):
            self.assertIn(mark, sent)

    def test_size_ids_are_text_free_in_the_core(self):
        for prop in (51, 52, 53):
            self.assertTrue(self.rules['CMFPropertyTextFree'](prop))


if __name__ == '__main__':
    unittest.main()
