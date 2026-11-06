"""The info box's place treats open screen movies as blocked (panel, API 17, general). Source and edit-chain tests."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text())['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']
MINE = [e for e in EDITS if 'cmfMovieRects' in e['replace'] or 'cmfNoteMovieAvoid(best)' in e['replace']]


def rects_function():
    text = next(e['replace'] for e in EDITS if 'protected function cmfMovieRects' in e['replace'])
    start = text.index('protected function cmfMovieRects')
    return text[start:text.index('protected function cmfNoteMovieAvoid')]


def edit_with(text):
    return next(e for e in EDITS if text in e['replace'])


def overlap(a, b):
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    return max(w, 0) * max(h, 0)


def clamp(v, lo, hi):
    return max(lo, min(v, hi))


def slides(side, r, limit, soft, hard):
    """Python model of cmfClearSlides: r and limit are (x, y, w, h) / (l, t, r, b)."""
    x, y, w, h = r
    vertical = side in ('left', 'right')
    out = [(clamp(x, limit[0], limit[2] - w), clamp(y, limit[1], limit[3] - h), w, h)]
    values = []
    if vertical:
        values = [limit[1], limit[3] - h] + [v for a in soft + hard for v in (a[1] - 8 - h, a[3] + 8)]
    else:
        values = [limit[0], limit[2] - w] + [v for a in soft + hard for v in (a[0] - 8 - w, a[2] + 8)]
    for v in values:
        cx, cy = (x, clamp(v, limit[1], limit[3] - h)) if vertical else (clamp(v, limit[0], limit[2] - w), y)
        out.append((clamp(cx, limit[0], limit[2] - w), clamp(cy, limit[1], limit[3] - h), w, h))
    if vertical:
        for a in hard:
            cx = max(x, a[2] + 8) if side == 'right' else min(x, a[0] - 8 - w)
            out.append((clamp(cx, limit[0], limit[2] - w), clamp(y, limit[1], limit[3] - h), w, h))
    return out


def pick(box, cx, cy, gap, limit, soft, hard, sides=('right', 'left', 'top', 'bottom')):
    cursor = (cx - gap, cy - gap, cx + gap, cy + gap)
    best, best_score = None, float('inf')
    w, h = box
    for side in sides:
        if side == 'right':
            r = (cursor[2], cy - h / 2, w, h)
        elif side == 'left':
            r = (cursor[0] - w, cy - h / 2, w, h)
        elif side == 'top':
            r = (cx - w / 2, cursor[1] - h, w, h)
        else:
            r = (cx - w / 2, cursor[3], w, h)
        r = (clamp(r[0], limit[0], limit[2] - w), clamp(r[1], limit[1], limit[3] - h), w, h)
        for c in slides(side, r, limit, soft, hard):
            rect = (c[0], c[1], c[0] + c[2], c[1] + c[3])
            score = 10 * overlap(rect, cursor) + 0.001 * (abs(c[0] - r[0]) + abs(c[1] - r[1]))
            score += sum(1000000 * overlap(rect, a) for a in hard) + sum(overlap(rect, a) for a in soft)
            if score < best_score:
                best, best_score = rect, score
    return best


class BoxAvoidsMovies(unittest.TestCase):
    def test_movies_are_hard_and_panels_soft_in_the_edit(self):
        e = edit_with('hard = this.cmfMovieRects();')
        self.assertIn('hard = this.cmfMovieRects();', e['replace'])
        loop = edit_with('1000000 * MapMenu.cmfOverlap(r,hard[n])')['replace']
        self.assertIn('score += MapMenu.cmfOverlap(r,avoid[n]);', loop)
        self.assertLess(loop.index('hard[n]'), loop.index('avoid[n]'))

    def test_movie_rects_no_longer_join_the_panel_list(self):
        self.assertFalse(any('avoid = avoid.concat(this.cmfMovieRects())' in e['replace'] for e in EDITS[EDITS.index(edit_with('hard = this.cmfMovieRects();')):]))

    def test_the_cursor_extension_still_sees_the_movies(self):
        self.assertTrue(any('avoid.concat(hard),best)' in e['replace'] for e in EDITS))

    def test_each_new_find_is_made_by_an_earlier_edit_and_no_edit_between_overlaps_it(self):
        first = EDITS.index(edit_with('hard = this.cmfMovieRects();'))
        for at in range(first, len(EDITS)):
            e = EDITS[at]
            if not any(e['find'] in EDITS[i]['replace'] for i in range(at)):
                continue
            make = max(i for i in range(at) if e['find'] in EDITS[i]['replace'])
            for i in range(make + 1, at):
                other = EDITS[i]['find']
                self.assertNotIn(e['find'], other, (at, i))
                self.assertNotIn(other, e['find'], (at, i))

    def test_only_live_screen_movies_with_drawn_content_count(self):
        text = edit_with('protected function cmfMovieRects')['replace']
        body = text[text.index('protected function cmfMovieRects'):text.index('protected function cmfNoteMovieAvoid')]
        self.assertIn('this.cmfLiveScreenMovie(state)', body)
        self.assertIn('state.loader.getBounds(this)', body)
        self.assertIn('if(r.width > 0 && r.height > 0)', body)

    def test_the_debug_note_comes_before_the_box_moves_and_counts_hard_and_soft(self):
        call = edit_with('this.cmfNoteMovieAvoid(best,avoid);')
        first = edit_with('this.cmfNoteMovieAvoid(best);\n         this.cmfNoteHintsRect(best);\n         this.tooltipInstance.x')
        self.assertLess(EDITS.index(first), EDITS.index(call))
        self.assertTrue(first['replace'].endswith('this.tooltipInstance.x += Math.round(best.x - box.x);\n'))
        note = ''.join(e['replace'] for e in EDITS)
        self.assertIn('info box placed round screen movies', note)
        self.assertIn('" hardCovered=" + Math.round(covered) + " softCovered=" + Math.round(softCovered)', note)

    def test_slides_helper_exists_and_is_used(self):
        self.assertIn('protected function cmfClearSlides(side:String', edit_with('protected function cmfClearSlides')['replace'])
        self.assertIn('slides = this.cmfClearSlides(sides[k],r,limit,avoid,hard);', ''.join(e['replace'] for e in EDITS))

    # The rule, as a model of the scoring and the slides.
    def test_rule_model_never_covers_a_movie_when_a_clear_place_exists(self):
        limit = (0, 0, 1920, 1080)
        movie = (0, 0, 600, 1080)          # Quest List on the left
        tracker = (1500, 0, 1920, 400)     # top-right panel
        # A pin 270 px right of the list, near the top: the tall box centred below it used to overlap the list border.
        for cx in (870, 700, 620, 610):
            best = pick((420, 560), cx, 150, 40, limit, [tracker], [movie])
            self.assertEqual(overlap(best, movie), 0, cx)

    def test_rule_model_box_may_cover_a_panel_when_it_must_but_not_the_movie(self):
        limit = (0, 0, 1920, 1080)
        movie = (0, 0, 900, 1080)
        panel = (900, 0, 1920, 1080)       # the panel fills all the rest
        best = pick((300, 300), 1200, 500, 40, limit, [panel], [movie])
        self.assertEqual(overlap(best, movie), 0)
        self.assertGreater(overlap(best, panel), 0)

    def test_rule_model_no_movie_keeps_the_first_place(self):
        limit = (0, 0, 1920, 1080)
        best = pick((300, 200), 960, 540, 40, limit, [], [])
        self.assertEqual(best, (1000, 440, 1300, 640))   # right of the cursor, centred, as before


PINS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text())['classes']['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as']


class ArtAgainNote(unittest.TestCase):
    """Logging only: a pin that already had a picture asking for one again is noted (first 40), as evidence for a flicker."""

    @staticmethod
    def pair():
        add = next(i for i, e in enumerate(PINS) if 'art again pin=' in e['replace'])
        decl = next(i for i, e in enumerate(PINS) if '_cmfArtAgain:int' in e['replace'])
        return add, decl

    def test_the_note_comes_before_the_old_loader_is_dropped(self):
        add = PINS[self.pair()[0]]
        self.assertTrue(add['find'].startswith('         this.cmfDropIconLoader();'))
        self.assertLess(add['replace'].index('art again pin='), add['replace'].index(add['find']))
        self.assertIn('this._cmfIconRequested != "" && StaticMapPinDescribed._cmfArtAgain < 40', add['replace'])

    def test_counter_declared_once_beside_cmfReleaseArt(self):
        decl = PINS[self.pair()[1]]
        self.assertIn('private static var _cmfArtAgain:int = 0;', decl['replace'])
        self.assertTrue(decl['replace'].rstrip().endswith('public function cmfReleaseArt(event:Event = null) : void'))

    def test_no_edit_between_makers_and_the_two_finds_overlaps_them(self):
        add, decl = self.pair()
        for at in (add, decl):
            e = PINS[at]
            make = max(i for i in range(at) if e['find'] in PINS[i]['replace'])
            for i in range(make + 1, at):
                self.assertNotIn(e['find'], PINS[i]['find'])
                self.assertNotIn(PINS[i]['find'], e['find'])


if __name__ == '__main__':
    unittest.main()
