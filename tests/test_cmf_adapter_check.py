"""Catalogue boundary and fresh-output tests for adapter guidance (offline only)."""
import copy
import importlib.util
import os
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = 'source/adapter-check/content/scripts/local/cmfAdapterCheck.ws'
PAGE = 'source/adapter-check/page/index.html'
CATALOG = 'tools/cmf_adapter_list.json'


class AdapterCheckTests(unittest.TestCase):
    def tool(self):
        path = ROOT / 'tools/cmf_adapter_check.py'
        self.assertTrue(path.is_file(), 'adapter catalogue generator is missing')
        spec = importlib.util.spec_from_file_location('cmf_adapter_check', path)
        tool = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(tool)
        return tool

    def rows(self):
        return self.tool().load_catalog(ROOT / CATALOG)

    def load(self, rows):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'catalog.json'
            path.write_text(json.dumps(rows), encoding='utf-8')
            return self.tool().load_catalog(path)

    def test_bad_schema_rejected_before_generation(self):
        rows = self.rows()
        for key, value in [('typo', 'x'), ('status', 'guess'), ('folders', ['../modBad']),
                           ('folders', ['modBad/path']), ('providers', 'modName'),
                           ('adapter', None), ('nexus', True), ('groups', ['bad-name'])]:
            changed = copy.deepcopy(rows)
            changed[0][key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                self.load(changed)

    def test_missing_required_fields_rejected(self):
        for key in ['name', 'nexus', 'folders', 'providers', 'groups', 'textKeys', 'adapter', 'status', 'note']:
            rows = self.rows()
            del rows[0][key]
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.load(rows)

    def test_duplicate_identities_and_aliases_rejected(self):
        for field, value in [('name', lambda r: r[0]['name'].upper()),
                             ('folders', lambda r: [r[0]['folders'][0].upper()]),
                             ('providers', lambda r: [r[0]['providers'][0].upper()]),
                             ('adapter', lambda r: {**r[1]['adapter'], 'folder': r[0]['adapter']['folder'].upper()}),
                             ('adapter', lambda r: {**r[1]['adapter'], 'file': r[0]['adapter']['file'].upper()})]:
            rows = self.rows()
            rows[1][field] = value(rows)
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.load(rows)

    def test_minimum_version_validation(self):
        for value in ['', None, 0.2, '1.x', ' 1.2', '1', '1.2.']:
            rows = self.rows()
            rows[0]['minAdapter'] = value
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.load(rows)
        rows = self.rows()
        row = next(r for r in rows if r['status'] == 'works')
        row['minAdapter'] = '1.2'
        with self.assertRaises(ValueError):
            self.load(rows)

    def test_external_tool_without_evidenced_link_or_folder_is_name_only(self):
        row = {'name': 'External Tool', 'nexus': None, 'folders': [], 'providers': [], 'groups': [],
               'textKeys': [], 'adapter': None, 'status': 'incompatible', 'note': 'External tool.'}
        self.assertEqual(self.load([row]), [row])
        row['status'] = 'adapter'
        with self.assertRaises(ValueError):
            self.load([row])

    def test_game_table_contains_only_eight_detectable_adapters(self):
        tool = self.tool()
        outputs = tool.render_outputs(self.rows(), (ROOT / SCRIPT).read_text(encoding='ascii'))
        source = outputs[SCRIPT].decode('ascii')
        game_names = __import__('re').findall(r'rowValue.modName = "([^"]+)";', source)
        self.assertEqual(game_names, ['Map Quest Insight', 'Gwent Players Map', 'Witcher Gear Map', 'Fog of War',
                                      "Witcher's Path", 'Botanist', 'Ink and Iron', 'The Stable'])
        self.assertEqual([name for name in game_names if name in
                          ('Smooth Map', 'Community Patch - World Map', 'Coloured Map Markers')], [])
        self.assertIn("rowValue.groups.PushBack('qmiWide');", source)
        self.assertIn('rowValue.textKeys.PushBack("map_location_arddhustable");', source)

    def test_minimum_guidance_agrees_in_page_and_localization(self):
        tool = self.tool()
        outputs = tool.render_outputs(self.rows(), (ROOT / SCRIPT).read_text(encoding='ascii'))
        strings = json.loads(outputs['source/adapter-check/strings.json'])['strings']
        texts = [r['text']['en'] for r in strings]
        for name, file, version in [('Fog of War', 'CMF Adapter - Fog of War', '1.0.1'),
                                     ('Map Quest Insight', 'CMF Adapter - Map Quest Insight', '1.1.1')]:
            fragment = f'{name}: install or update {file} (version {version} or newer).'
            self.assertTrue(any(t.startswith(fragment) for t in texts))
            self.assertIn(fragment, outputs[PAGE].decode())
        ordinary = next(t for t in texts if t.startswith('Gwent Players Map:'))
        self.assertIn('install CMF Adapter - Gwent Players Map', ordinary)
        self.assertNotIn('install or update', ordinary)

    def test_localization_ids_languages_and_xml_contract(self):
        tool = self.tool()
        outputs = tool.render_outputs(self.rows(), (ROOT / SCRIPT).read_text(encoding='ascii'))
        strings = json.loads(outputs['source/adapter-check/strings.json'])['strings']
        ids = [r['id'] for r in strings]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(2000200900 <= n <= 2000200999 for n in ids))
        self.assertEqual(len(strings[0]['text']), 18)
        self.assertTrue(all(len(r['text']) == 18 and len(set(r['text'].values())) == 1 for r in strings))
        menu = ET.fromstring(outputs['source/adapter-check/modCMFAdapterCheck.xml'])
        enabled = menu.find("./Group[@id='CMFAdapterCheck']/VisibleVars/Var[@id='CMFAdapterCheckEnabled']")
        title_path = menu.find("./Group[@id='CMFAdapterCheck']").get('displayName')
        self.assertIn('panel_' + title_path.split('.')[-1], [r['key'] for r in strings])
        self.assertIsNotNone(enabled)
        self.assertEqual(enabled.get('value'), '1')
        self.assertEqual(enabled.get('displayType'), 'OPTIONS')
        self.assertEqual([(o.get('displayName'), o.find('Entry').get('value')) for o in enabled.findall('./OptionsArray/Option')], [('Off', '0'), ('On', '1')])
        self.assertIsNotNone(menu.find("./Group[@id='CMFAdapterCheck']/VisibleVars/Var[@id='CMFAdapterCheckKnown']"))
        for i, row in enumerate(self.rows()):
            self.assertEqual(strings[4 + i]['id'], 2000200904 + i)

    def test_overflow_and_duplicate_localization_ids_rejected(self):
        tool = self.tool()
        rows = []
        for i in range(97):
            rows.append({'name': f'Tool {i}', 'nexus': None, 'folders': [], 'providers': [], 'groups': [],
                         'textKeys': [], 'adapter': None, 'status': 'incompatible', 'note': 'External tool.'})
        with self.assertRaises(ValueError):
            tool.render_outputs(rows, (ROOT / SCRIPT).read_text())
        duplicate = {'mod': 'x', 'idBase': 2000200900, 'strings': [
            {'id': 2000200900, 'key': 'a', 'text': {'en': 'a'}},
            {'id': 2000200900, 'key': 'b', 'text': {'en': 'b'}}]}
        with self.assertRaises(ValueError):
            tool.validate_strings(duplicate)

    def test_generation_escapes_contexts_and_preserves_handwritten_bytes(self):
        tool = self.tool()
        rows = self.rows()
        rows[0]['name'] = 'A "quote" & <tag> \\ end'
        rows[0]['note'] = '</script><script>alert(1)</script>'
        source = '/* handwritten prefix */\r\n' + tool.TABLE_BEGIN + '\nold\n' + tool.TABLE_END + '\r\n// runtime tail\r\n'
        output = tool.render_outputs(rows, source)
        script = output[SCRIPT]
        self.assertTrue(script.startswith(b'/* handwritten prefix */\r\n'))
        self.assertTrue(script.endswith(b'\r\n// runtime tail\r\n'))
        self.assertIn(b'A \\"quote\\" & <tag> \\\\ end', script)
        self.assertNotIn('</script><script>alert(1)', output[PAGE].decode())
        ET.fromstring(output['source/adapter-check/modCMFAdapterCheck.xml'])
        for broken in ['', tool.TABLE_BEGIN + '\n', tool.TABLE_BEGIN + tool.TABLE_END + tool.TABLE_END]:
            with self.assertRaises(ValueError):
                tool.render_outputs(rows, broken)

    def test_fresh_independent_writes_are_identical_and_check_detects_stale(self):
        tool = self.tool()
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            roots = [Path(first), Path(second)]
            for root in roots:
                (root / CATALOG).parent.mkdir(parents=True)
                (root / CATALOG).write_bytes((ROOT / CATALOG).read_bytes())
                (root / SCRIPT).parent.mkdir(parents=True)
                skeleton = (ROOT / SCRIPT).read_bytes()
                start = skeleton.index(tool.TABLE_BEGIN.encode())
                end = skeleton.index(tool.TABLE_END.encode())
                skeleton = skeleton[:start] + tool.TABLE_BEGIN.encode() + b'\n// stale input\n' + skeleton[end:]
                (root / SCRIPT).write_bytes(skeleton)
                tool.write(root)
                self.assertTrue(tool.check(root))
            for relative in (SCRIPT, PAGE, 'source/adapter-check/strings.json', 'source/adapter-check/modCMFAdapterCheck.xml'):
                self.assertEqual((roots[0] / relative).read_bytes(), (roots[1] / relative).read_bytes())
                before = (roots[0] / relative).read_bytes()
                stale = before.replace(b'rowValue.modName =', b'rowValue.modNameStale =', 1) if relative == SCRIPT else before + b' stale'
                (roots[0] / relative).write_bytes(stale)
                self.assertFalse(tool.check(roots[0]), relative)
                (roots[0] / relative).write_bytes(before)
            rows = json.loads((roots[0] / CATALOG).read_text())
            rows[0]['note'] += ' changed'
            (roots[0] / CATALOG).write_text(json.dumps(rows))
            self.assertFalse(tool.check(roots[0]))
            outfile = roots[0] / 'standalone.html'
            run = subprocess.run([sys.executable, '-B', str(ROOT / 'tools/cmf_adapter_check.py'),
                                  'page', '--out', str(outfile)], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            self.assertEqual(outfile.read_bytes(), (roots[1] / PAGE).read_bytes())

    def test_public_works_list_and_source_only_exclusions(self):
        rows = self.rows()
        self.assertEqual([(r['name'], r['nexus']) for r in rows if r['status'] == 'works'], [
            ('Smooth Map', 13530), ('Map Remastered', 13347), ('All Quest Markers', 13087), ('Quest Levels on Map', 13691),
            ('Useful Place of Power Map Pin', 11300), ('True Map POIs', 13213), ('RevealMapPOI', 13140),
            ('Reveal Map Icons - Remastered', 13516), ("Wolf's Bearing", 14546), ('Wild Monster Hunt', 9426),
            ('Apocrypha Menu Framework', 13656), ('HUD Position Manager', 14337)])
        row = next(r for r in rows if r['name'] == 'Community Patch - World Map')
        self.assertEqual((row['status'], row['adapter'], row['groups'], row['textKeys']), ('author', None, [], []))
        # Smooth Map's author released its own CMF version (2026-10-25); the example adapter retired.
        smooth = next(r for r in rows if r['name'] == 'Smooth Map')
        self.assertEqual((smooth['adapter'], smooth['groups'], smooth['textKeys']), (None, [], []))
        self.assertEqual((smooth['folders'], smooth['providers']), (['modSmoothMap_CMF', 'modSmoothMap'], ['mod000SmoothMap']))
        self.assertIn('modSmoothMap_CMF', smooth['note'])



# Runtime models are paired with source contracts below: these are offline branch/state
# checks, not execution in REDengine or timing/gameplay acceptance.
class DeferredState:
    def __init__(self, known=''):
        self.known, self.notices, self.writes = known, [], 0
        self.pending = self.checked = self.fallback = False
        self.timer = False

    def start(self, player=True):
        self.pending, self.checked = True, False
        self.timer, self.fallback = player, not player

    def end(self):
        self.pending = self.timer = self.fallback = False

    def run(self, signature, enabled=True, active=True, black=False, menu=False, dialogue=False, message_popup=False):
        if not self.pending or self.checked or not active or black or menu or dialogue or message_popup:
            return
        self.pending, self.checked = False, True
        if not enabled:
            return
        if self.known != signature:
            self.known = signature
            self.writes += 1
            if signature:
                self.notices.append(signature)


def method(source, name):
    import re
    match = re.search(r'\bfunction\s+' + name + r'\([^)]*\)[^{]*\{', source)
    if not match:
        raise AssertionError('missing runtime method: ' + name)
    depth, start = 1, match.end()
    for i in range(start, len(source)):
        depth += (source[i] == '{') - (source[i] == '}')
        if not depth:
            return source[start:i]
    raise AssertionError('unclosed method ' + name)


class AdapterRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT / SCRIPT).read_text(encoding='ascii')

    def test_runtime_passes_native_aware_lint(self):
        lint = Path(os.environ.get('CMF_WS_LINT', 'ws_lint.py'))
        game = ROOT.parent / 'The Witcher 3'
        if not lint.is_file() or not (game / 'content/content0/scripts').is_dir():
            self.skipTest('native lint tool or pinned vanilla scripts unavailable')
        run = subprocess.run([sys.executable, '-B', str(lint), '--game', str(game),
                              str(ROOT / SCRIPT)], capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_detection_requires_each_populated_category_but_accepts_alternatives(self):
        installed = method(self.source, 'CMFAdapterCheckInstalled')
        self.assertIn('rowValue.groups.Size() > 0 && !groupFound', installed)
        self.assertIn('rowValue.textKeys.Size() > 0 && !textFound', installed)
        self.assertIn('config.GetGroupsNum()', installed)
        self.assertIn('config.GetGroupName(j) == rowValue.groups[i]', installed)
        self.assertIn('text != "" && !StrBeginsWith(text, "#")', installed)
        # Independent detector fixtures, including stale XML and The Stable's text-only case.
        for groups, keys, present_groups, text, want in [
                (['a', 'b'], ['k'], ['a'], '', False),
                (['a', 'b'], ['k'], ['b'], 'Found', True),
                (['a'], ['k'], [], 'Found', False),
                ([], ['k'], [], 'Found', True),
                ([], ['k'], [], '#k', False)]:
            got = (not groups or bool(set(groups) & set(present_groups))) and (not keys or bool(text) and not text.startswith('#'))
            self.assertEqual(got, want)

    def test_any_provider_presence_suppresses_finding_without_version_queries(self):
        missing = method(self.source, 'CMFAdapterCheckMissing')
        self.assertIn('CMFProviderPresent(entries[i].providers[j])', missing)
        self.assertIn('!present && CMFAdapterCheckInstalled(entries[i])', missing)
        self.assertNotIn('CMFVersion', missing)
        self.assertNotIn('minAdapter', missing)
        self.assertIn('CMFAdapterCheckEntries(entries);', missing)
        for answers, want in [([False, False], True), ([False, True], False), ([True], False)]:
            self.assertEqual(not any(answers), want)

    def test_enabled_missing_values_default_on_and_only_own_group_is_written(self):
        enabled = method(self.source, 'CMFAdapterCheckEnabled')
        self.assertIn("StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFAdapterCheck', 'CMFAdapterCheckEnabled'))", enabled)
        self.assertIn('return value != "0" && value != "false";', enabled)
        for value, want in [('', True), ('-1', True), ('1', True), ('0', False), ('FALSE', False)]:
            self.assertEqual(value.lower() not in ('0', 'false'), want)
        writes = __import__('re').findall(r"SetVarValue\(([^;]+)\);", self.source)
        self.assertEqual(writes, ["'CMFAdapterCheck', 'CMFAdapterCheckKnown', signature"])

    def test_box_paragraphs_use_the_games_line_break(self):
        # WitcherScript strings have no escapes: "\n" reaches the box as a backslash and an n (start A).
        run = method(self.source, 'CMFAdapterCheckRun')
        self.assertNotIn('\\n', self.source)
        self.assertEqual(run.count('"<br><br>"'), 2)

    def test_missing_clear_missing_warns_twice_and_disabled_preserves_known(self):
        run = method(self.source, 'CMFAdapterCheckRun')
        self.assertIn('if (!CMFAdapterCheckEnabled())', run)
        self.assertIn('if (known == signature)', run)
        self.assertLess(run.index('CMFAdapterCheckEnabled()'), run.index('CMFAdapterCheckMissing(missing);'))
        self.assertLess(run.index('CMFAdapterCheckConsume();'), run.index('ShowUserDialogAdv'))
        self.assertIn('cmfAdapterCheckChecked = true;', method(self.source, 'CMFAdapterCheckConsume'))
        self.assertLess(run.index('SetVarValue('), run.index('SaveUserSettings();'))
        self.assertEqual(run.count('SaveUserSettings();'), 1)
        self.assertIn('if (signature == "")', run)
        state = DeferredState()
        for signature in ['mqi', 'mqi', '', 'mqi']:
            state.start()
            state.run(signature)
        self.assertEqual(state.notices, ['mqi', 'mqi'])
        self.assertEqual(state.writes, 3)
        state.start()
        state.run('', enabled=False)
        self.assertEqual(state.known, 'mqi')
        self.assertEqual(state.writes, 3)

    def test_signature_is_sorted_unique_lowercase_with_pipe(self):
        signature = method(self.source, 'CMFAdapterCheckSignature')
        self.assertIn('StrLower(entries[i].adapterFolder)', signature)
        self.assertIn('names.FindFirst(folder) < 0', signature)
        self.assertIn('ArraySortStrings(names);', signature)
        self.assertIn('signature += "|";', signature)
        self.assertEqual('|'.join(sorted(set(s.lower() for s in ['B', 'a', 'a']))), 'a|b')

    def test_start_end_and_timer_forward_once_and_defer(self):
        start = method(self.source, 'OnGameStarted')
        self.assertEqual(start.count('wrappedMethod(restored);'), 1)
        self.assertLess(start.index('wrappedMethod(restored);'), start.index('CMFAdapterCheckSchedule();'))
        schedule = method(self.source, 'CMFAdapterCheckSchedule')
        self.assertIn("AddTimer('CMFAdapterCheckAfterLoad', 0.1, false, , , false, true)", schedule)
        timer = method(self.source, 'CMFAdapterCheckAfterLoad')
        self.assertIn('CMFAdapterCheckBusy()', timer)
        self.assertIn('CMFAdapterCheckSchedule();', timer)
        self.assertIn('CMFAdapterCheckRun();', timer)
        busy = method(self.source, 'CMFAdapterCheckBusy')
        for call in ['!theGame.IsActive()', 'theGame.IsBlackscreen()', 'theGame.GetGuiManager().IsAnyMenu()']:
            self.assertIn(call, busy)
        end = method(self.source, 'OnGameEnded')
        self.assertEqual(end.count('wrappedMethod();'), 1)
        self.assertIn("RemoveTimer('CMFAdapterCheckAfterLoad');", end)
        self.assertIn('cmfAdapterCheckPending = false;', end)
        state = DeferredState()
        state.start(); state.start()
        for kwargs in [dict(active=False), dict(black=True), dict(menu=True)]:
            state.run('mqi', **kwargs)
            self.assertEqual(state.notices, [])
        state.run('mqi'); state.run('mqi')
        self.assertEqual(state.notices, ['mqi'])
        state.end()
        self.assertFalse(state.pending or state.timer)

    def assert_busy_deferral(self, source_guard, **busy_state):
        busy = method(self.source, 'CMFAdapterCheckBusy')
        self.assertIn(source_guard, busy)
        run = method(self.source, 'CMFAdapterCheckRun')
        self.assertLess(run.index('CMFAdapterCheckBusy()'), run.index('CMFAdapterCheckConsume();'))
        timer = method(self.source, 'CMFAdapterCheckAfterLoad')
        self.assertRegex(timer, r'if \(CMFAdapterCheckBusy\(\)\)\s*\{\s*CMFAdapterCheckSchedule\(\);\s*return;')
        state = DeferredState()
        state.start()
        for _ in range(2):
            state.run('mqi', **busy_state)
            self.assertTrue(state.pending)
            self.assertFalse(state.checked)
            self.assertEqual((state.known, state.writes, state.notices), ('', 0, []))
        state.run('mqi')
        self.assertFalse(state.pending)
        self.assertTrue(state.checked)
        self.assertEqual((state.known, state.writes, state.notices), ('mqi', 1, ['mqi']))
        state.run('mqi')
        self.assertEqual((state.writes, state.notices), (1, ['mqi']))

    def test_dialogue_or_cutscene_keeps_pending_until_it_ends(self):
        self.assert_busy_deferral('theGame.IsDialogOrCutscenePlaying()', dialogue=True)

    def test_existing_message_popup_is_preserved_until_it_closes(self):
        self.assert_busy_deferral("theGame.GetGuiManager().GetPopup('MessagePopup')", message_popup=True)

    def test_missing_player_fallback_only_checks_after_close(self):
        schedule = method(self.source, 'CMFAdapterCheckSchedule')
        self.assertIn('if (!thePlayer)', schedule)
        self.assertIn('CMFAdapterCheckSetFallback(true);', schedule)
        self.assertIn('cmfAdapterCheckFallback = value;', method(self.source, 'CMFAdapterCheckSetFallback'))
        close = method(self.source, 'OnClosingMenu')
        self.assertEqual(close.count('wrappedMethod();'), 1)
        self.assertIn('cmfAdapterCheckPending && theGame.cmfAdapterCheckFallback', close)
        self.assertLess(close.index('wrappedMethod();'), close.index('CMFAdapterCheckSchedule();'))
        self.assertNotIn('CMFAdapterCheckMissing', close)
        state = DeferredState(); state.start(player=False)
        self.assertTrue(state.pending and state.fallback)
        state.run('mqi', active=False)
        self.assertEqual(state.notices, [])

    def test_dialog_has_one_localized_common_footer(self):
        run = method(self.source, 'CMFAdapterCheckRun')
        for key in ['panel_cmf_adapter_check', 'cmf_adapter_check_intro', 'cmf_adapter_check_footer']:
            self.assertEqual(run.count('GetLocStringByKeyExt("' + key + '")'), 1)
        strings = json.loads((ROOT / 'source/adapter-check/strings.json').read_text())['strings']
        fragments = [row['text']['en'] for row in strings if row['key'].startswith('cmf_adapter_check_mod_')]
        self.assertFalse(any('Nexus Mods' in text for text in fragments))
        self.assertIn('GetLocStringByKeyExt(missing[i].messageKey)', run)
        self.assertNotIn('StrBefore', run)


class AdapterBuildTests(unittest.TestCase):
    tool = AdapterCheckTests.tool
    def test_build_exact_payload_manifest_and_independent_hashes(self):
        import hashlib
        tool = self.tool()
        self.assertTrue(callable(getattr(tool, 'build', None)), 'build API is missing')
        (ROOT / 'build').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as parent:
            out = Path(parent) / 'package'
            files = tool.build(out, None)
            expected = {'Mods/modCMFAdapterCheck/content/scripts/local/cmfAdapterCheck.ws',
                        'Mods/modCMFAdapterCheck/README.md',
                        'bin/config/r4game/user_config_matrix/pc/modCMFAdapterCheck.xml'}
            expected.update('Mods/modCMFAdapterCheck/content/' + code + '.w3strings' for code in tool.LANGUAGES)
            self.assertEqual(set(files), expected)
            manifest = json.loads((out / 'build.json').read_text())
            self.assertEqual(manifest['files'], files)
            self.assertEqual(manifest['minCmfApi'], 11)
            self.assertEqual({p.relative_to(out).as_posix() for p in out.rglob('*') if p.is_file()}, expected | {'build.json'})
            for relative, digest in files.items():
                self.assertEqual(hashlib.sha256((out / relative).read_bytes()).hexdigest(), digest)
            with self.assertRaises((ValueError, SystemExit)):
                tool.build(out, None)

    def test_build_refuses_stale_external_occupied_and_reparse_paths(self):
        from unittest.mock import patch
        tool = self.tool()
        self.assertTrue(callable(getattr(tool, 'build', None)), 'build API is missing')
        with tempfile.TemporaryDirectory() as outside:
            with self.assertRaises((ValueError, SystemExit)):
                tool.build(Path(outside) / 'package', None)
        (ROOT / 'build').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as parent:
            out = Path(parent) / 'stale'
            with patch.object(tool, 'check', return_value=False), self.assertRaises((ValueError, SystemExit)):
                tool.build(out, None)
            self.assertFalse(out.exists())
            occupied = Path(parent) / 'occupied'; occupied.mkdir(); (occupied / 'keep').write_text('keep')
            with self.assertRaises((ValueError, SystemExit)):
                tool.build(occupied, None)
            self.assertEqual((occupied / 'keep').read_text(), 'keep')
            link = Path(parent) / 'junction'
            if sys.platform == 'win32':
                made = subprocess.run(['cmd', '/c', 'mklink', '/J', str(link), str(occupied)], capture_output=True)
                self.assertEqual(made.returncode, 0, made.stderr)
                try:
                    with self.assertRaises((ValueError, SystemExit)):
                        tool.build(link / 'child', None)
                finally:
                    link.rmdir()
            else:
                link.symlink_to(occupied, target_is_directory=True)
                with self.assertRaises((ValueError, SystemExit)):
                    tool.build(link / 'child', None)


if __name__ == '__main__':
    unittest.main()
