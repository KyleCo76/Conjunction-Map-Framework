"""Panel seam fixes S1, S2, S12, S18 and the keep fields (S14), as edits at the end of each class's list.

Source tests only: they read source/panel/pin-fields/edits.json and need no built panel or game files. Findings:
docs/reviews/2026-11-04-seam-review/FINDINGS.md.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
PREFIX = 'red/game/witcher3/'
DESCRIBED = PREFIX + 'menus/worldmap/StaticMapPinDescribed.as'
HUBMAP = PREFIX + 'menus/worldmap/HubMap.as'
DATA = PREFIX + 'data/StaticMapPinData.as'
TAG = re.compile(r'seam (S1|S2|S12|S18|S14)\b')


def mine(cls):
    """The edits of this patch in one class: those whose replacement carries a '// seam Sn' tag."""
    return [(i, e) for i, e in enumerate(EDITS[cls]) if TAG.search(e['replace'])]


def tagged(cls, name):
    found = [e for _, e in mine(cls) if ('seam ' + name) in e['replace']]
    assert found, 'no edit tagged seam %s in %s' % (name, cls)
    return found


def brace_body(text, head):
    start = text.index(head)
    brace = text.index('{', start)
    depth = 0
    for i in range(brace, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise AssertionError('unbalanced braces after ' + head)


def final_function(cls, head):
    """The text of one ActionScript function after every edit of the class that touches it, newest text first."""
    for e in reversed(EDITS[cls]):
        if head in e['replace']:
            return brace_body(e['replace'], head)
    raise AssertionError(head)


class SeamPanelFixes(unittest.TestCase):
    def test_every_new_edit_finds_text_exactly_once_and_comes_last(self):
        for cls in (DESCRIBED, HUBMAP, DATA):
            edits = EDITS[cls]
            new = mine(cls)
            self.assertTrue(new, cls)
            # at the END of the class's list, in order
            self.assertEqual([i for i, _ in new], list(range(new[0][0], new[0][0] + len(new))), cls)  # contiguous, after the older edits
            for i, e in new:
                self.assertEqual(e['count'], 1, e['find'][:60])
                earlier = ''.join(x['replace'] for x in edits[:i])
                self.assertEqual(earlier.count(e['find']), 1, 'find must occur once in the earlier text: ' + e['find'][:70])
                for j, later in new:
                    if j > i:
                        self.assertNotIn(e['find'], later['find'], 'edits overlap: ' + e['find'][:60])
                for line in e['replace'].split('\n'):
                    self.assertNotIn('\t', line)
                    self.assertFalse(re.search(r'claude|opus|sonnet|haiku', line, re.I), line)

    def test_animation_only_pin_gets_a_base_alpha(self):
        """S1: both halves: the early return also tests the frame fields, and the look captures the alpha lazily."""
        guard = tagged(DESCRIBED, 'S1')
        text = ''.join(e['replace'] for e in guard)
        self.assertIn('!param1.cmfIconFrames && !param1.cmfIconUnderFrames /* seam S1 */', text)
        self.assertRegex(text, r'this\._cmfBaseIconAlpha < 0\) \{ this\._cmfBaseIconAlpha = this\.mcIcon\.mcPinIcon\.alpha; \}')
        # the lazy capture sits before the first use of the base alpha in the latest cmfApplyDisabledLook
        replaced = next(e for e in guard if 'cmfBaseIconAlpha = ' in e['replace'])
        self.assertLess(replaced['replace'].index('_cmfBaseIconAlpha < 0'), len(replaced['replace']))
        self.assertIn('filters = base.concat();', replaced['find'] + replaced['replace'])
        self.assertLess(replaced['replace'].index('_cmfBaseIconAlpha < 0'),
                        replaced['replace'].index('if(this._cmfDisabledLook)'))

    def test_fresh_ordered_pin_is_attached_after_it_is_reparented(self):
        """S2: after cmfOrderWithinParent() in addPinChild, attach when the pin has no animation owner."""
        e = tagged(HUBMAP, 'S2')[0]
        text = e['replace']
        order = text.index('param1.cmfOrderWithinParent();')
        attach = text.index('cmfAnimationAttach(param1)')
        self.assertLess(order, attach)
        self.assertIn('!param1.cmfAnimationOwner', text[order:])
        self.assertIn('MapMenu.cmfMenu', text[order:])

    def test_rejected_recycled_clip_releases_its_art(self):
        e = tagged(HUBMAP, 'S12')[0]
        text = e['replace']
        self.assertLess(text.index('pin.cmfReleaseArt();'), text.index('return null;'))
        self.assertIn('this._cmfPoolChanged++;', text)

    def test_failed_url_not_requested_again(self):
        edits = tagged(DESCRIBED, 'S18')
        text = ''.join(e['replace'] for e in edits)
        self.assertIn('private static var _cmfArtFailed:Object = {};', text)
        # recorded where a Loader's own failure is handled, before cmfDropIconLoader resets the requested url
        failed = next(e for e in edits if 'function cmfOnIconArtFailed' in e['replace'])['replace']
        self.assertIn('StaticMapPinDescribed._cmfArtFailed[this._cmfIconRequested] = true;', failed)
        self.assertIn('this._cmfIconLoader is Loader &&', failed)  # only a Loader's own failure counts
        # skipped at the start of cmfRequestIconArt, before a Loader is made
        request = next(e for e in edits if 'StaticMapPinDescribed._cmfArtFailed[param1]' in e['replace'])['replace']
        self.assertIn('return;', request)
        # forgotten where the picture cache is reset
        self.assertTrue(any('_cmfArtFailed = {};' in e['replace'] and '_cmfArtCache = {};' in e['replace'] for e in edits))

    def test_keep_fields_declared_and_class_dynamic(self):
        text = ''.join(e['replace'] for e in EDITS[DATA])
        self.assertIn('public var cmfGridKeep:Boolean = false;', text)
        self.assertIn('public var cmfGridKeepBy:String = "";', text)
        self.assertEqual(text.count('public var cmfGridKeep:Boolean'), 1)
        self.assertIn('public dynamic class StaticMapPinData', EDITS[DATA][9]['replace'])  # S23


if __name__ == '__main__':
    unittest.main()
