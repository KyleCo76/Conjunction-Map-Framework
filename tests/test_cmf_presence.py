"""Presence contracts: source-bound offline checks, not WitcherScript execution.

The small session model documents observable state; the adjacent source checks bind
its assumptions to the production entry points. Engine callback/lifetime acceptance
still requires compilation and a game launch.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import cmf_menu_addon as addon

CORE = ROOT / 'source/core/content/scripts/local/cmfCore.ws'
MENU = ROOT / 'source/menu/content/scripts/local/cmfMenu.ws'


def body(text, name):
    match = re.search(r'\bfunction ' + re.escape(name) + r'\([^{}]*\)\s*(?::\s*\w+)?\s*\{', text)
    assert match, 'missing production entry point ' + name
    start = match.end()
    depth = 1
    for pos in range(start, len(text)):
        if text[pos] == '{':
            depth += 1
        elif text[pos] == '}':
            depth -= 1
            if not depth:
                return text[start:pos]
    raise AssertionError('unclosed body ' + name)


class PresenceSession:
    """Reference contract only; no claim to execute the engine's source."""
    def __init__(self):
        self.identities, self.providers, self.logs = [], [], []
        self.offers, self.rows = [], []

    def submit(self, provider):
        if not provider:
            return False
        if provider.lower() not in self.identities:
            self.identities.append(provider.lower())
            self.providers.append(provider)
            self.logs.append('CMF present provider=' + provider)
        return True

    def query(self, provider):
        return bool(provider) and provider.lower() in self.identities

    def refresh(self):
        pass

    def release(self, provider):
        self.offers = [p for p in self.offers if p != provider]


class PresenceSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding='ascii')
        cls.menu = MENU.read_text(encoding='ascii')

    def test_property_is_generic_only_and_named_helper_uses_empty_payload(self):
        self.assertEqual(body(self.core, 'CMFPropertyPresent').strip(), 'return 38;')
        self.assertEqual(body(self.core, 'CMFGetVersion').strip(), 'return 11;')
        self.assertIn('CMFPropertyPresent()', body(self.core, 'CMFHasProperty'))
        self.assertNotIn('CMFPropertyPresent()', body(self.core, 'CMFOnePinProperty'))
        self.assertIn('CMFRegister(provider, CMFPropertyPresent(), \'\', \'\', "", 1)',
                      body(self.core, 'CMFDeclareProvider'))
        register = body(self.core, 'CMFRegister')
        self.assertLess(register.index('propertyId == CMFPropertyPresent()'), register.index('claim.provider ='))
        self.assertIn('present = theGame.CMFGetCore().NoteProviderPresent(provider);', register)
        self.assertIn('return present;', register)

    def test_cache_fast_path_and_first_add_only_work(self):
        note = body(self.core, 'NoteProviderPresent')
        self.assertLess(note.index('provider == ""'), note.index('provider == lastPresentProvider'))
        self.assertLess(note.index('provider == lastPresentProvider'), note.index('StrLower(provider)'))
        self.assertRegex(note, r'if \(provider == lastPresentProvider\)\s*\{\s*return true;\s*\}')
        self.assertEqual(note.count('StrLower('), 1)
        self.assertEqual(note.count('.FindFirst('), 1)
        self.assertRegex(note, r'if \(presentIdentities.FindFirst\(identity\) < 0\)\s*\{\s*presentIdentities.PushBack\(identity\);\s*presentProviders.PushBack\(provider\);\s*CMFLog\("present provider=" \+ provider\);\s*\}')
        self.assertIn('lastPresentProvider = provider;', note)
        self.assertEqual(note.count('CMFLog('), 1)
        for forbidden in ('GetVar', 'CMFSettings', 'claims', 'Offers(', 'Prepare(', 'dirty ='):
            self.assertNotIn(forbidden, note)

    def test_queries_and_feature_enumeration_do_not_declare_or_include_presence(self):
        for name in ('ProviderPresent', 'PresentProviders', 'Providers', 'ProviderName', 'DrawingKind',
                     'CMFProviderPresent', 'CMFRequireVersion', 'CMFGetVersion', 'CMFHasProperty'):
            with self.subTest(name=name):
                text = body(self.core, name)
                self.assertNotIn('NoteProviderPresent(', text)
                if name != 'PresentProviders' and name != 'ProviderPresent':
                    self.assertNotIn('presentProviders', text)
        self.assertIn('presentIdentities.FindFirst(StrLower(provider))', body(self.core, 'ProviderPresent'))
        self.assertIn('.ProviderPresent(provider)', body(self.core, 'CMFProviderPresent'))
        self.assertIn('offerProviders', body(self.core, 'Providers'))

    def test_presence_enumeration_copies_only_presence_without_prepare(self):
        present = body(self.core, 'PresentProviders')
        self.assertIn('providers.Clear();', present)
        self.assertIn('providers.PushBack(presentProviders[i]);', present)
        for forbidden in ('Prepare(', 'Offer', 'claims', 'dirty ='):
            self.assertNotIn(forbidden, present)

    def test_canonical_submissions_note_before_validation(self):
        # Breaking any entry below would lose rejected, withdrawn, or non-claim submissions.
        for name in ('CMFRegister', 'CMFRegisterForTag', 'CMFRegisterForPlace', 'CMFStylePart', 'CMFDraw',
                     'CMFDrawSet', 'CMFDrawSetList', 'CMFSetProviderName', 'CMFRegisterWorldPaintingTiles',
                     'CMFRegisterButtonPicture', 'ReleaseProvider', 'RegisterChoiceOnly', 'StoreOpeningView', 'StylePin'):
            with self.subTest(name=name):
                text = body(self.core, name)
                self.assertIn('NoteProviderPresent(provider)', text)
                # Early validation returns must not precede noting presence.
                self.assertLess(text.index('NoteProviderPresent(provider)'), text.index('return ') if 'return ' in text else len(text))

    def test_style_click_hint_button_and_invalid_styles_share_one_cached_note(self):
        style = body(self.core, 'StylePin')
        self.assertEqual(style.count('NoteProviderPresent(provider)'), 1)
        self.assertLess(style.index('NoteProviderPresent(provider)'), style.index('CMFIsClickProperty(propertyId)'))
        self.assertIn('return StyleClick(provider, dataObject, propertyId, text, number);', style)
        self.assertNotIn('NoteProviderPresent', body(self.core, 'StyleClick'))
        self.assertIn('CMFPropertyPinClickHint()', body(self.core, 'CMFIsClickProperty'))
        self.assertIn('CMFPropertyPinClickButton()', body(self.core, 'CMFIsClickProperty'))

    def test_forwarders_do_not_double_check_presence(self):
        for name in ('CMFStylePin', 'CMFStylePinIcon', 'CMFStylePinTint', 'CMFStylePinScale', 'CMFStylePinLabel',
                     'CMFHidePin', 'CMFReleaseProvider', 'CMFRegisterChoiceOnly', 'CMFSetOpeningView',
                     'CMFSetOpeningWorld', 'SetOpeningView', 'SetOpeningWorld', 'Upsert', 'UpsertTheme',
                     'UnsetTheme', 'SetProviderName'):
            with self.subTest(name=name):
                self.assertNotIn('NoteProviderPresent', body(self.core, name))
        # The picture convenience validators note only their rejected path; successful calls go to CMFRegister.
        for name in ('CMFRegisterWorldPaintingTiles', 'CMFRegisterButtonPicture'):
            text = body(self.core, name)
            self.assertIn('NoteProviderPresent(provider)', text)
            self.assertLess(text.index('if ('), text.index('NoteProviderPresent(provider)'))
            self.assertLess(text.index('return false;'), text.index('return CMFRegister('))

    def test_release_refresh_and_startup_preserve_session_registry(self):
        for name in ('ReleaseProvider', 'RequestRefresh', 'OnGameStarted'):
            text = body(self.core, name)
            self.assertNotRegex(text, r'present(?:Identities|Providers)\.(?:Clear|Erase|Resize)')
        startup = body(self.core, 'OnGameStarted')
        self.assertEqual(startup.count('wrappedMethod(restored)'), 1)
        self.assertNotIn('new CMFCore', startup)

    def test_status_only_union_keeps_choices_and_order_separate(self):
        status = body(self.menu, 'CMFMenuStatusProviders')
        self.assertIn('.Providers(providers)', status)
        self.assertIn('.PresentProviders(present)', status)
        self.assertIn('StrLower(', status)
        self.assertIn("'CMFMenuKnownPresent'", status)
        self.assertNotIn("'CMFMenuKnown'", status)
        self.assertIn('theGame.IsActive()', status)
        self.assertIn('return providers.Size() > 0;', status)
        page = body(self.menu, 'CMFMenuFillPage')
        self.assertRegex(page, r"if \(groupName == 'CMFMenuStatusMods'\)\s*\{\s*remembered = CMFMenuStatusProviders\(providers\);")
        self.assertRegex(page, r'else\s*\{\s*remembered = CMFMenuProviders\(providers\);')
        self.assertNotIn('PresentProviders', body(self.menu, 'CMFMenuProviders'))
        self.assertIn('GetLocStringByKeyExt("cmf_menu_support_present")', body(self.menu, 'CMFMenuFillMod'))
        self.assertNotIn('Nothing yet (open the map)', body(self.menu, 'CMFMenuFillMod'))

    def test_empty_status_memory_does_not_unlock_prebuilt_title_screen_picks_or_order(self):
        # Source-bound regression for an upgrade: old choice memory exists while the
        # new status memory is empty. A status-page build must leave stray callbacks
        # blocked even though pick/order answer mappings have already been remembered.
        for name in ('CMFMenuFillPick', 'CMFMenuFillOrder'):
            self.assertIn('theGame.CMFMenuGetState().Remember(varName, CMFMenuJoin(answers));',
                          body(self.menu, name))
        status = body(self.menu, 'CMFMenuStatusProviders')
        self.assertIn('return providers.Size() > 0;', status)
        page = body(self.menu, 'CMFMenuFillPage')
        self.assertIn('remembered = CMFMenuStatusProviders(providers);', page)
        self.assertIn('theGame.CMFMenuGetState().SetTitleScreen(!theGame.IsActive());', page)
        self.assertNotIn('SetTitleScreen(remembered)', page)
        changed = body(self.menu, 'CMFMenuValueChanged')
        guard = changed.index('if (theGame.CMFMenuGetState().TitleScreen())')
        answer = changed.index('.Answer(varName, StringToInt(value), answer)')
        write = changed.index('config.SetVarValue(groupName, nameVar, answer);')
        self.assertLess(guard, answer)
        self.assertLess(guard, write)
        self.assertRegex(changed[guard:answer], r'TitleScreen\(\)\)\s*\{[^}]*return;')

    def test_menu_generated_status_storage_and_localized_support(self):
        import xml.etree.ElementTree as ET
        xml = ET.fromstring(addon.menu_xml())
        old = xml.find("Group[@id='CMFMenuKnown']")
        new = xml.find("Group[@id='CMFMenuKnownPresent']")
        self.assertIsNotNone(old)
        self.assertIsNotNone(new)
        self.assertEqual([v.attrib['id'] for v in new.findall('./VisibleVars/Var')],
                         ['CMFKnownPresent' + str(i) for i in range(1, 25)])
        strings = {s['key']: s for s in addon.catalog()['strings']}
        self.assertEqual(strings['cmf_menu_support_present'], {'id': 2000200127, 'key': 'cmf_menu_support_present',
                                                             'text': {'en': 'CMF support present'}})
        self.assertEqual(addon.VERSION, '1.5.0')
        self.assertEqual(addon.MIN_API, 11)


class PresenceContractModelTests(unittest.TestCase):
    def test_case_variants_reject_empty_and_query_only_is_pure(self):
        state = PresenceSession()
        self.assertFalse(state.submit(''))
        self.assertFalse(state.query('modAbsent'))
        self.assertEqual(state.providers, [])
        for provider in ('modExample', 'MODEXAMPLE', 'modExample'):
            self.assertTrue(state.submit(provider))
        self.assertEqual(state.providers, ['modExample'])
        self.assertEqual(state.logs, ['CMF present provider=modExample'])
        self.assertTrue(state.query('ModExample'))

    def test_declaration_and_release_never_add_feature_or_order_rows(self):
        state = PresenceSession()
        state.submit('modExample')
        self.assertEqual(state.offers, [])
        self.assertEqual(state.rows, [])
        state.release('modExample')
        self.assertEqual(state.providers, ['modExample'])
        self.assertTrue(state.query('modExample'))

    def test_both_startup_wrapper_orders_retain_presence(self):
        for order in ('declare-first', 'refresh-first'):
            with self.subTest(order=order):
                state = PresenceSession()
                if order == 'declare-first':
                    state.submit('modExample')
                state.refresh()
                if order == 'refresh-first':
                    state.submit('modExample')
                self.assertEqual(state.providers, ['modExample'])


if __name__ == '__main__':
    unittest.main()
