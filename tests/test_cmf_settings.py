"""Settings menus, string catalogs and the settings overlay stager.

The table build case needs the creation skill's w3strings.py (Kyle's skill path,
or CMF_W3STRINGS) and skips without it; a skipped case is not qualification.
"""
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_settings_stage as stage

MENUS = ROOT/'source/settings/menus'
CORE_MENU = MENUS/'mod0000_ConjunctionMapFramework.xml'
PACK_MENU = MENUS/'modCMFTestIconPack.xml'
CORE_CATALOG = ROOT/'source/strings.json'
PACK_CATALOG = ROOT/'source/settings/modCMFTestIconPack.strings.json'
SETTINGS_WS = ROOT/'source/core/content/scripts/local/cmfSettings.ws'
PACK_WS = ROOT/'source/providers/modCMFTestIconPack/content/scripts/local/cmfTestIconPack.ws'
DEV_BLOCK = range(2000209000, 2000210000)
TOOL = Path(os.environ.get('CMF_W3STRINGS', str(stage.DEFAULT_TOOL)))


def groups(path):
    return ET.parse(path).getroot().findall('Group')


def visible_vars(group):
    return [v for v in group.iter('Var') if v.get('visibilityCondition') != 'hideAlways']


def catalog(path):
    return json.loads(path.read_text(encoding='utf-8'))


class MenuTests(unittest.TestCase):
    def test_menus_follow_the_safe_schema(self):
        for path in (CORE_MENU, PACK_MENU):
            self.assertTrue(path.read_bytes().startswith(b'<?xml version="1.0" encoding="UTF-8"?>'))
            for group in groups(path):
                self.assertTrue(group.get('id').startswith('CMF'))
                if path == PACK_MENU:
                    self.assertTrue(group.get('displayName').startswith('Mods.cmf_menu.'))
                self.assertNotIn('..', group.get('displayName'))
                for var in group.iter('Var'):
                    self.assertIsNotNone(var.get('displayName'), var.get('id'))
                    self.assertTrue(var.get('id').startswith('CMF'))

    def test_core_menu_is_hidden_settings_only(self):
        (group,) = groups(CORE_MENU)
        self.assertEqual(group.get('id'), 'CMFSettings')
        self.assertEqual(visible_vars(group), [])
        # One segment: the game builds every missing parent node of a displayName before it drops
        # a group with no visible rows, and only the leaf is dropped, so a nested path would leave
        # an empty "Conjunction Map Framework" entry under Options > Mods.
        self.assertEqual(group.get('displayName'), 'cmf_settings')
        self.assertEqual([v.get('id') for v in group.iter('Var')], ['CMFProviderOrder%d' % i for i in range(1, 9)] + ['CMFDebug'])

    def test_every_visible_label_key_ships(self):
        core = {s['key'] for s in catalog(CORE_CATALOG)['strings']}
        pack = {s['key'] for s in catalog(PACK_CATALOG)['strings']}
        for group in groups(PACK_MENU):
            menu, page = group.get('displayName').split('.')[1:]
            self.assertIn('panel_' + menu, core)
            self.assertNotIn('panel_' + menu, pack, 'packs never ship the CMF node title')
            self.assertIn('panel_' + page, pack)
            for var in visible_vars(group):
                self.assertIn('option_' + var.get('displayName'), pack)


class CatalogTests(unittest.TestCase):
    def test_blocks_are_separate_and_append_only(self):
        core, pack = catalog(CORE_CATALOG), catalog(PACK_CATALOG)
        core_ids = [s['id'] for s in core['strings']]
        pack_ids = [s['id'] for s in pack['strings']]
        self.assertEqual(core_ids, list(range(core['idBase'] + 1, core['idBase'] + 1 + len(core_ids))))
        self.assertEqual(pack_ids, list(range(pack['idBase'] + 1, pack['idBase'] + 1 + len(pack_ids))))
        self.assertTrue(all(i in DEV_BLOCK for i in pack_ids))
        self.assertFalse(any(i in DEV_BLOCK for i in core_ids))
        self.assertTrue(all(s['key'].startswith('cmf') or s['key'].startswith('panel_cmf')
                            for s in core['strings']))
        self.assertNotIn('panel_mods', {s['key'].lower() for s in core['strings'] + pack['strings']})


class ScriptTests(unittest.TestCase):
    def test_scripts_read_the_menu_ids(self):
        pack = PACK_WS.read_text(encoding='ascii')
        settings = SETTINGS_WS.read_text(encoding='ascii')
        self.assertIn("GetVarValue('CMFTestPack', 'CMFTP_Enabled')", pack)
        self.assertIn("GetVarValue('CMFSettings', slot)", settings)
        for i in range(1, 9):
            self.assertIn("CMFSettingsAddProvider(order, 'CMFProviderOrder%d');" % i, settings)
        self.assertIn("GetVarValue('CMFSettings', 'CMFDebug')", settings)

    def test_scripts_are_ascii_lf_without_reserved_names(self):
        for path in (SETTINGS_WS, PACK_WS):
            data = path.read_bytes()
            self.assertNotIn(b'\r', data)
            self.assertTrue(all(b < 128 for b in data))
            self.assertIsNone(re.search(r'\bvar\s+(entry|state|map|set|default|name|string)\b', data.decode()))

    def test_toggle_is_read_before_the_map_builds_pins(self):
        pack = PACK_WS.read_text(encoding='ascii')
        body = pack.split('@wrapMethod(CR4MapMenu)\nfunction OnConfigUI()\n{\n', 1)[1]
        self.assertTrue(body.startswith('\tCMFTestIconPackApply();\n\treturn wrappedMethod();\n}'))


class StageTests(unittest.TestCase):
    @unittest.skipUnless(TOOL.is_file(), "creation skill's w3strings.py absent")
    def test_overlay_builds_and_decodes(self):
        with tempfile.TemporaryDirectory() as temp:
            report = stage.stage(TOOL, Path(temp)/'out')
        self.assertEqual(report['strings'][stage.CORE]['strings'], len(catalog(CORE_CATALOG)['strings']))
        self.assertEqual(report['strings'][stage.PACK]['strings'], len(catalog(PACK_CATALOG)['strings']))
        tables = [name for name in report['files'] if name.endswith('.w3strings')]
        self.assertEqual(len(tables), 36)
        self.assertEqual(len(report['files']), 40)


if __name__ == '__main__':
    unittest.main()
