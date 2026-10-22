"""Provider order from settings: the CMFProviderOrder1-8 values read in CMFCore.Prepare decide between providers.

Static checks only. The in-game check is the provider order launch with modCMFTestOrderA and
modCMFTestOrderB (blacksmith pins red by folder order, blue when the settings list B first). The first
launch (2026-10-20) showed the game's settings reader ends a value at its first comma, so each slot holds
one name.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
SETTINGS = ROOT/'source/core/content/scripts/local/cmfSettings.ws'
PACKS = {name: ROOT/'source/providers'/name/'content/scripts/local'/script for name, script in
         (('modCMFTestOrderA', 'cmfTestOrderA.ws'), ('modCMFTestOrderB', 'cmfTestOrderB.ws'))}


def body(text, signature):
    start = text.index(signature)
    end = text.index('\n}', start) if text[start - 1] == '\n' else text.index('\n\t}', start)
    return text[start:end]


def join(slots):
    # Mirrors CMFSettingsProviderOrder and CMFSettingsAddProvider.
    return ','.join(s.replace(' ', '') for s in slots if s.replace(' ', ''))


def rank(order, provider):
    # Mirrors CMFSettingsProviderRank.
    if order == '' or provider == '':
        return -1
    return (',' + order.lower() + ',').find(',' + provider.lower() + ',')


def beats(order, a, b):
    # Mirrors CMFCore.ProviderBeats and CMFFolderBeats.
    ra, rb = rank(order, a), rank(order, b)
    if ra != rb:
        if ra < 0:
            return False
        if rb < 0:
            return True
        return ra < rb
    return (a.lower(), a) < (b.lower(), b)


class ProviderOrderTests(unittest.TestCase):
    def test_order_is_read_once_per_prepare_and_logged(self):
        core = CORE.read_text(encoding='ascii')
        prepare = body(core, '\tpublic function Prepare()')
        self.assertIn('providerOrder = CMFSettingsProviderOrder();', prepare)
        self.assertLess(prepare.index('providerOrder = '), prepare.index('winners.Clear();'))
        self.assertIn('CMFLog("provider order=" + providerOrder);', prepare)
        self.assertEqual(core.count('CMFSettingsProviderOrder()'), 1)

    def test_every_provider_comparison_goes_through_the_core(self):
        core = CORE.read_text(encoding='ascii')
        self.assertIn('function CMFProviderBeats(a : string, b : string) : bool\n{\n'
                      '\treturn theGame.CMFGetCore().ProviderBeats(a, b);\n}', core)
        beats_body = body(core, '\tpublic function ProviderBeats(a : string, b : string) : bool')
        self.assertIn('CMFSettingsProviderRank(providerOrder, a)', beats_body)
        self.assertIn('return CMFFolderBeats(a, b);', beats_body)
        self.assertIn('return ProviderBeats(a.provider, b.provider);', body(core, '\tprivate function Beats('))
        # Version 8: besides ProviderBeats, only the menu add-on's lists (Providers, WinnerOf) sort by folder name.
        self.assertEqual(core.count('CMFFolderBeats('), 4)
        self.assertIn('if (OrderDecides(menuOrder, a, b, result))', beats_body)
        self.assertLess(beats_body.index('menuOrder'), beats_body.index('providerOrder'))

    def test_settings_reader_joins_one_name_per_slot(self):
        settings = SETTINGS.read_text(encoding='ascii')
        reader = body(settings, 'function CMFSettingsProviderOrder() : string')
        slots = re.findall(r"order = CMFSettingsAddProvider\(order, '(\w+)'\);", reader)
        self.assertEqual(slots, ['CMFProviderOrder%d' % i for i in range(1, 9)])
        add = body(settings, 'function CMFSettingsAddProvider(order : string, slot : name) : string')
        self.assertIn("StrReplaceAll(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', slot), \" \", \"\")", add)
        self.assertIn('return order + "," + provider;', add)
        self.assertNotIn("'CMFProviderOrder'", settings)
        self.assertIn('StrFindFirst("," + StrLower(order) + ",", "," + StrLower(provider) + ",")', settings)
        self.assertEqual(join(['modB', '', ' modA ', '']), 'modB,modA')

    def test_listed_providers_come_first_then_folder_order(self):
        order = 'modZed,modbeta'
        self.assertTrue(beats(order, 'modZed', 'modAlpha'))
        self.assertTrue(beats(order, 'modBeta', 'modAlpha'))
        self.assertTrue(beats(order, 'modZed', 'modBeta'))
        self.assertFalse(beats(order, 'modAlpha', 'modBeta'))
        self.assertTrue(beats(order, 'modAlpha', 'modGamma'))
        self.assertTrue(beats('', 'modAlpha', 'modBeta'))
        # A name that only contains a listed name is not listed.
        self.assertEqual(rank('modBetaPlus', 'modBeta'), -1)

    def test_test_packs_disagree_on_one_slot(self):
        tints = {}
        for name, path in PACKS.items():
            data = path.read_bytes()
            self.assertNotIn(b'\r', data)
            self.assertTrue(all(b < 128 for b in data))
            tints[name] = re.findall(r'CMFRegisterTint\("(\w+)", \'(\w+)\', (\d+)\)', data.decode())
        self.assertEqual(tints['modCMFTestOrderA'], [('modCMFTestOrderA', 'Blacksmith', '16728128')])
        self.assertEqual(tints['modCMFTestOrderB'], [('modCMFTestOrderB', 'Blacksmith', '4210943')])
        self.assertTrue(beats('', 'modCMFTestOrderA', 'modCMFTestOrderB'))
        self.assertTrue(beats(join(['modCMFTestOrderB', 'modCMFTestOrderA']), 'modCMFTestOrderB', 'modCMFTestOrderA'))


if __name__ == '__main__':
    unittest.main()
