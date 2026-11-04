"""CMF API 16: a movie drawing hides map panels while it is shown (map.hidePanels)."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
MENU_KEY = 'red/game/witcher3/menus/worldmap/MapMenu.as'
MENU_EDITS = EDITS[MENU_KEY]
DOC = (ROOT / 'docs/authors/own-screen-movie.md').read_text(encoding='utf-8')
PARTS = ('legend', 'title', 'tracker', 'preview', 'worldButton', 'worldHint')


def as3_body(text, name):
    match = re.search(r'\bfunction ' + re.escape(name) + r'\([^{}]*\)\s*(?::\s*[\w*]+)?\s*\{', text)
    assert match, 'missing function ' + name
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


def simulate_chain(entries):
    """Walk an edit list in order and return one record per entry.

    The evolving text starts empty. An entry whose find is not in the text yet is treated as vanilla text and
    appended as a seeded block. Each record holds the evolving text produced by the entries BEFORE it, whether the
    entry had to be seeded, and how often its find matched. The edit is then applied count times, so a seed
    that overlaps an earlier one cannot multiply CMF-added text.
    """
    text = ''
    records = []
    for index, entry in enumerate(entries):
        seeded = entry['find'] not in text
        if seeded:
            text += '\n' + entry['find']
        records.append({'index': index, 'before': text, 'seeded': seeded, 'matches': text.count(entry['find'])})
        text = text.replace(entry['find'], entry['replace'], entry['count'])
    return records, text


def assert_finds_anchor_on_added_text(case, entries, first_new):
    """Every entry from first_new on matches exactly count times in the text the earlier entries produced, and is not vanilla."""
    records, _ = simulate_chain(entries)
    case.assertLess(first_new, len(entries))
    for record in records[first_new:]:
        entry = entries[record['index']]
        label = 'entry %d %r' % (record['index'], entry['find'][:60])
        case.assertFalse(record['seeded'], label + ' anchors on text no earlier entry produced')
        case.assertEqual(record['matches'], entry['count'], label + ' matches the evolving text a wrong number of times')


def release_functions(text):
    """Every MapMenu function that releases the pan lock: it sets pan false itself or calls the release that does."""
    names = []
    for match in re.finditer(r'\bfunction (\w+)\(', text):
        name = match.group(1)
        try:
            body = as3_body(text, name)
        except AssertionError:
            continue
        if re.search(r'\.pan = false|cmfReleaseMovieControls\(', body) and name not in names:
            names.append(name)
    return names


MENU = simulate_chain(MENU_EDITS)[1]


def hide_body():
    return as3_body(MENU, 'cmfHidePanels')


class MovieHidePanels(unittest.TestCase):
    def test_facade_has_hide_panels(self):
        self.assertRegex(as3_body(MENU, 'cmfScreenMap'), r'hidePanels\s*[:=]\s*function\s*\(\s*parts')

    def test_known_parts_only(self):
        body = as3_body(MENU, 'cmfPanelClip')
        for part in PARTS:
            self.assertIn('"%s"' % part, body)
        self.assertEqual(sorted(set(re.findall(r'part == "(\w+)"', body))), sorted(PARTS))
        self.assertIn('if(!clip) { continue; }', hide_body())

    def test_restore_uses_the_saved_visibility(self):
        self.assertRegex(hide_body(), r'_cmfHiddenPanels\[[^\]]+\]\s*=\s*[^;]*\.visible')
        self.assertRegex(as3_body(MENU, 'cmfSettleHiddenPanel'), r'\.visible = Boolean\(this\._cmfHiddenPanels\[part\]\)')

    def test_empty_or_null_restores_this_movie(self):
        self.assertRegex(hide_body(), r'!parts \|\| parts\.length == 0\) \{ this\.cmfRestoreHiddenPanels\(state\)')

    def test_hidden_panels_are_restored_on_every_release_path(self):
        names = release_functions(MENU)
        self.assertIn('cmfReleaseMovieControls', names)
        for caller in ('cmfDropScreenMovie', 'cmfSuspendScreenMovie', 'cmfScreenMoviesAreaMoved'):
            self.assertIn(caller, names)
        self.assertIn('cmfRestoreHiddenPanels', as3_body(MENU, 'cmfReleaseMovieControls'))
        # Removal, ownership loss, load failure and map close reach the drop; area change and hide reach the release.
        self.assertIn('cmfDropScreenMovie', as3_body(MENU, 'cmfFailScreenMovie'))
        self.assertIn('cmfDropScreenMovie', as3_body(MENU, 'cmfCloseScreenMovies'))

    def test_each_movie_restores_only_what_it_hid(self):
        body = as3_body(MENU, 'cmfSettleHiddenPanel')
        self.assertIn('hidden[part]) { return; }', body)
        self.assertIn('delete this._cmfHiddenPanels[part]', body)

    def test_control_route_is_live_movie_only(self):
        self.assertIn('if(action == "hidePanels")', as3_body(MENU, 'cmfMovieControl'))

    def test_new_finds_survive_the_whole_chain(self):
        first = next(i for i, e in enumerate(MENU_EDITS) if 'cmfRestoreHiddenPanels' in e['replace'] or 'hidePanels' in e['replace'])
        assert_finds_anchor_on_added_text(self, MENU_EDITS, first)
        self.assertGreaterEqual(len(MENU_EDITS) - first, 3)

    def test_chain_helper_flags_a_vanilla_anchor(self):
        edits = [{'find': 'a', 'replace': 'a\nb', 'count': 1}, {'find': 'zz', 'replace': 'y', 'count': 1}]
        with self.assertRaises(AssertionError):
            assert_finds_anchor_on_added_text(self, edits, 1)
        broken = [{'find': 'a', 'replace': 'x', 'count': 1}, {'find': 'a\nb', 'replace': 'q', 'count': 1}]
        with self.assertRaises(AssertionError):
            assert_finds_anchor_on_added_text(self, broken, 1)

    def test_hub_bar_part(self):
        self.assertIn('part == "hubBar"', hide_body())
        self.assertNotIn('"hubBar"', as3_body(MENU, 'cmfPanelClip'))
        self.assertIn('"OnCMFHubBar",[visible]', as3_body(MENU, 'cmfSendHubBar'))
        self.assertIn('cmfSendHubBar(false)', as3_body(MENU, 'cmfHoldHubBar'))
        settle = as3_body(MENU, 'cmfSettleHiddenPanel')
        self.assertLess(settle.index('hidden[part]) { return; }'), settle.index('cmfSendHubBar(true)'))

    def test_hub_bar_owners_in_a_model(self):
        # Model of the ownership: first hold sends false, only the last release sends true.
        held, sent, owners = {}, [], {}

        def hold(owner):
            first = 'hubBar' not in held
            owners[owner] = True
            held['hubBar'] = True
            if first:
                sent.append(False)

        def release(owner):
            owners.pop(owner, None)
            if owners or 'hubBar' not in held:
                return
            sent.append(True)
            del held['hubBar']
        hold('a'); hold('b'); release('a')
        self.assertEqual(sent, [False])
        release('b')
        self.assertEqual(sent, [False, True])
        release('b')
        self.assertEqual(sent, [False, True])
        # The real code uses the same shape.
        settle = as3_body(MENU, 'cmfSettleHiddenPanel')
        self.assertIn('if(this._cmfHiddenPanels.hasOwnProperty(part)) { this.cmfSendHubBar(true); }', settle)
        self.assertIn('first) { this.cmfSendHubBar(false)', as3_body(MENU, 'cmfHoldHubBar'))
        self.assertIn('cmfRestoreHiddenPanels', as3_body(MENU, 'cmfReleaseMovieControls'))

    def test_core_has_the_hub_bar_route(self):
        core = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='utf-8')
        self.assertIn('@addMethod(CR4CommonMenu)\nfunction CMFSetHubBarVisible(value : bool)', core)
        self.assertIn('GetMemberFlashFunction("setPlayerDetailsVisible")', core)
        self.assertIn('InvokeSelfOneArg(FlashArgBool(value))', core)
        self.assertIn('@addMethod(CR4MapMenu)\nevent OnCMFHubBar(visible : bool)', core)
        close = core[core.index('function OnClosingMenu()'):]
        close = close[:close.index('\n}\n')]
        self.assertRegex(close, r'if \(cmfHubBarHidden\)\s*\{\s*OnCMFHubBar\(true\);')
        self.assertIn('cmfHubBarHidden = !visible;', core)
        self.assertLess(close.index('OnCMFHubBar(true);'), close.index('wrappedMethod()'))
        self.assertNotIn('\r', core)

    def test_mqi_movie_sends_hub_bar(self):
        movie = (ROOT / 'source/adapters/map-quest-insight/movie-src/MqiAdapterQuestList.as').read_text(encoding='utf-8')
        self.assertIn('map.hidePanels(["legend","title","hubBar"])', movie)

    def test_doc_row(self):
        self.assertIn('`"hubBar"`', DOC)
        self.assertIn('| `map.hidePanels(parts)` |', DOC)
        self.assertIn('hidden panels', DOC)


if __name__ == '__main__':
    unittest.main()
