"""Theme send speed: the memo inside one SendTheme call gives what the old SendTheme gave.

The old SendTheme and the functions it used (tests/fixtures/theme_send_before.ws, the text before the memo) run in one
environment; the shipped ones run in a second environment holding the same state. The sent theme objects (field by field,
in order), the "cmf.map.lookOwners" list and the log lines (NoteTheme) must be identical. Offline contract runs of the
shipped WitcherScript bodies (see ws_contract_runner.py); nothing here has run in game.
"""
from pathlib import Path
from types import SimpleNamespace as Obj
import functools
import random
import re
import unittest
import ws_contract_runner
from ws_contract_runner import Array, bind
import test_cmf_rev13_fold_registration as fold
import test_cmf_rev13_map_contracts as contracts
from test_cmf_review_bundle import body

ROOT = Path(__file__).resolve().parents[1]
CORE = contracts.CORE
BEFORE = (ROOT/'tests/fixtures/theme_send_before.ws').read_text(encoding='ascii')

INK = 'Ink_and_Iron'
MQI = 'MapQuestInsight'
SMOOTH = 'SmoothMap'
FRAME = 'aFrameMod'
FRAME2 = 'zFrameOnly'
SPACE = 'SpaceDrawer'
FILLERS = [('Mod_%02d' if n % 3 == 0 else 'mod%02d') % n for n in range(31)]
ALL_PROVIDERS = [INK, MQI, SMOOTH, FRAME, FRAME2, SPACE] + FILLERS

PANELS = ['screen', 'legend', 'tooltip', 'hints', 'title', 'tracker', 'preview', 'worldButton', 'markerPanel', 'pin',
          'mapEdge', 'legendRow']
STYLE_KEYS = {
    'screen': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'shadow', 'glow', 'x', 'y', 'w', 'h', 'show', 'radius'],
    'legend': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'show', 'autoHideMs', 'padShowFirst', 'x', 'y', 'w'],
    'legendRow': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'h'],
    'tooltip': ['bg', 'border', 'pad', 'alpha', 'font', 'foldTag', 'foldOpen', 'clearAnchor', 'slide', 'x', 'y', 'w',
                'scrollStep', 'tallTop', 'showSeconds'],
    'hints': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'list'],
    'title': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'show', 'x', 'y'],
    'tracker': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'show', 'x', 'y'],
    'preview': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'show', 'movingMs'],
    'worldButton': ['bg', 'border', 'pad', 'alpha', 'font', 'tint', 'show'],
    'markerPanel': ['bg', 'border', 'pad', 'alpha', 'font', 'tint'],
    'pin': ['size', 'alpha', 'tint', 'shadow', 'glow', 'outline'],
}


def build_entries(withTop=True):
    """About 1,000 entries of a 37-mod mix as (provider, kind, target, anchor, key, text, number, values)."""
    groups = []

    def group(*rows):
        groups.append(list(rows))

    # Ink and Iron-like: about 160 styles, 70 drawings, about 650 drawing keys.
    styles = []
    for part, keys in STYLE_KEYS.items():
        for key in keys:
            styles.append((INK, 1, part, '', key, 'v' + key, 1.5))
    styles = styles[:158]
    for at in range(0, len(styles), 20):
        group(*styles[at:at + 20])
    kinds = ['rect', 'image', 'movie', 'text']
    ids = ['ink_d%02d' % n for n in range(70)]
    for n, ident in enumerate(ids):
        anchor = PANELS[n % len(PANELS)]
        if n % 9 == 8:
            anchor = ids[n - 3]  # a drawing nested in an earlier drawing
        kind = kinds[n % 4]
        rows = [(INK, 2, ident, anchor, kind, '', 0.)]
        for key in ('x', 'y', 'w', 'h', 'alpha', 'tint'):
            rows.append((INK, 3, ident, '', key, '', float(n)))
        if kind == 'image':
            rows.append((INK, 3, ident, '', 'src', 'img://ink/%d.png' % n if n % 13 else 'http://bad/%d.png' % n, 0.))
        if kind == 'movie':
            rows.append((INK, 3, ident, '', 'src', 'swf/ink%d.swf' % n if n % 11 else 'bad/%d.swf' % n, 0.))
        if kind == 'text':
            rows.append((INK, 3, ident, '', 'text', 'label %d' % n, 0.))
        if PANELS[n % len(PANELS)] == 'pin' and anchor == 'pin':
            rows.append((INK, 3, ident, '', 'pinTag', 'Boat, boat ,Horse,,' + str(n), 0.))
        if n % 17 == 3:
            rows.append((INK, 3, ident, '', 'src', 'img://rect/refused.png', 0.))
        if n % 5 == 0:
            rows.append((INK, 4, ident, '', 'points', '', 0., [1., 2., float(n)]))
        group(*rows)
    # Map Quest Insight-like: screen, mapEdge and legend styles; drawings on screen, mapEdge, legend and the tooltip.
    rows = []
    for part in ('screen', 'mapEdge', 'legend'):
        for key in ('bg', 'border', 'pad', 'alpha', 'font', 'tint', 'x'):
            rows.append((MQI, 1, part, '', key, 'q' + key, 2.5))
    group(*rows)
    for n, anchor in enumerate(['screen', 'mapEdge', 'legend', 'tooltip', 'screen', 'legend', 'tooltip', 'mapEdge',
                                'screen', 'legend']):
        ident = 'mqi_d%d' % n
        rows = [(MQI, 2, ident, anchor, 'rect', '', 0.)]
        for key in ('x', 'y', 'w', 'h'):
            rows.append((MQI, 3, ident, '', key, '', float(n)))
        group(*rows)
    # A drawing id made by two providers, and a key without a drawing.
    group((INK, 2, 'shared_d', 'screen', 'rect', '', 0.), (INK, 3, 'shared_d', '', 'x', '', 1.),
          (MQI, 2, 'shared_d', 'legend', 'rect', '', 0.), (MQI, 3, 'shared_d', '', 'x', '', 2.),
          (MQI, 3, 'shared_d', '', 'y', '', 3.), (INK, 3, 'ghost_d', '', 'x', '', 0.),
          (FILLERS[2], 3, 'ghost_d', '', 'x', '', 9.))
    # Smooth Map-like: opening and navigation keys; a navigation key of a different choice.
    group(*[(SMOOTH, 1, 'opening', '', key, '', 1.) for key in
            ('revealSeconds', 'revealLegendSeconds', 'revealTrackerSeconds', 'zoom', 'x', 'y')],
          *[(SMOOTH, 1, 'navigation', '', key, '', 2.) for key in
            ('zoomOutFit', 'edgeOvershoot', 'crosshairRoam', 'snapSeconds', 'speed', 'friction')])
    # Map frame: top and frame keys (frame keys follow the top's owner while anyone sends top).
    frame = [(FRAME, 1, 'map', '', key, '', 3.) for key in ('bottom', 'left', 'frame', 'frameTop', 'frameBottom', 'zoomMin')]
    if withTop:
        frame.append((FRAME, 1, 'map', '', 'top', '', 3.))
    group(*frame)
    group(*[(FRAME2, 1, 'map', '', key, '', 4.) for key in ('frame', 'frameTop', 'color', 'zoomMin')])
    if withTop:
        group((FILLERS[5], 1, 'map', '', 'top', '', 5.))
    # One pure drawing provider on mapSpace (skipped by the send), and a drawing nested in one of its drawings.
    for n in range(5):
        ident = 'space_d%d' % n
        rows = [(SPACE, 2, ident, 'mapSpace', 'rect', '', 0.)]
        for key in ('x', 'y', 'w', 'h', 'area'):
            rows.append((SPACE, 3, ident, '', key, '', float(n)))
        group(*rows)
    group((FILLERS[6], 2, 'inside_space', 'space_d1', 'rect', '', 0.), (FILLERS[6], 3, 'inside_space', '', 'x', '', 1.))
    # Two drawings pointing at each other (no root), and one on a root that is no part.
    group((FILLERS[7], 2, 'loop_a', 'loop_b', 'rect', '', 0.), (FILLERS[7], 2, 'loop_b', 'loop_a', 'rect', '', 0.),
          (FILLERS[7], 3, 'loop_a', '', 'x', '', 1.), (FILLERS[7], 2, 'lost_d', 'nowhere', 'rect', '', 0.))
    # The 31 other mods: a few styles each over the other parts, and a drawing or two on panels.
    rng = random.Random(1311)
    parts = list(STYLE_KEYS) + ['wide', 'spread', 'sounds', 'world', 'crosshair', 'edgePointer', 'pinLabel', 'keyCap']
    extra = {'wide': ['panels', 'panelsLegend', 'panelsTracker', 'panelsPreview', 'x'], 'spread': ['x', 'y', 'radius'],
             'sounds': ['open', 'close'], 'world': ['x'], 'crosshair': ['bg', 'show'], 'edgePointer': ['bg'],
             'pinLabel': ['rise', 'riseOffset', 'font', 'bg'], 'keyCap': ['bg']}
    for n, mod in enumerate(FILLERS):
        rows = []
        for _ in range(rng.randint(3, 8)):
            part = rng.choice(parts)
            key = rng.choice(extra.get(part) or STYLE_KEYS[part])
            rows.append((mod, 1, part, '', key, 'f' + key, float(rng.randint(0, 9))))
        group(*rows)
        if n % 4 == 1:
            ident = 'f%02d_d' % n
            rows = [(mod, 2, ident, rng.choice(PANELS), 'rect', '', 0.)]
            for key in ('x', 'y', 'w', 'h', 'alpha', 'tint'):
                rows.append((mod, 3, ident, '', key, '', float(n)))
            group(*rows)
    # A few more drawing keys so the mix lands near 1,000 entries.
    pad = []
    for n in range(0, 70, 2):
        for key in ('dx', 'dy', 'scale'):
            pad.append((INK, 3, ids[n], '', key, '', float(n)))
    group(*pad)
    # Fixed shuffle of the groups: folder order differs from registration order.
    order = random.Random(77)
    order.shuffle(groups)
    out = []
    for rows in groups:
        out.extend(rows)
    return out


def fill(env, rows):
    entries = Array()
    for number, row in enumerate(rows):
        e = env['SCMFThemeEntry']()
        e.provider, e.kind, e.target, e.anchor, e.key, e.text, e.number = row[:7]
        e.order = number + 1
        if len(row) > 7:
            e.values = Array(row[7])
        entries.append(e)
    env['themeEntries'] = entries


def rank_of(order, provider):
    names = order.split(',') if order else []
    return names.index(provider) if provider in names else -1


NEW_BINDINGS = (
    ('ThemeDrawingOwner', ('id',), ()), ('ComputeThemeDrawingOwner', ('id',), ()),
    ('DrawingKind', ('provider', 'id'), ()), ('ComputeDrawingKind', ('provider', 'id'), ()),
    ('PanelDrawingLeftOut', ('entryValue', 'owner'), (1,)), ('ComputePanelDrawingLeftOut', ('entryValue', 'owner'), (1,)),
)
COMMON_BINDINGS = (
    ('PanelPart', ('part',), ()), ('ThemeLookChoice', ('part',), ()), ('PreparedLookOwner', ('part',), ()),
    ('SendLookOwners', ('storage',), ()), ('DrawingRoot', ('id',), ()), ('ResolveDrawingRoot', ('id',), ()),
    ('PrepareDrawingRoots', (), ()), ('IsSpaceDrawing', ('id',), ()), ('DrawingSourceOk', ('entryValue',), ()),
    ('PinTagFilters', ('provider', 'text', 'storage'), ()), ('TrimFilterWord', ('text',), ()),
    ('ChoiceOnlySkips', ('choice', 'provider'), ()), ('PieceBeats', ('choice', 'a', 'b'), ()),
    ('MenuPickDecides', ('choice', 'a', 'b', 'result'), (3,)),
)
OLD_BINDINGS = (
    ('ThemeStyleOwner', ('part', 'key'), ()), ('ThemeDrawingOwner', ('id',), ()), ('DrawingKind', ('provider', 'id'), ()),
    ('PanelDrawingLeftOut', ('entryValue', 'owner'), (1,)), ('ThemeFolderRank', ('provider',), ()),
    ('SendTheme', ('storage',), ()),
)


_RUNNER_BODY = ws_contract_runner.body


def setUpModule():
    # The runner looks a function body up in the 600 KB source on every call; the old chain makes millions of calls.
    # Caching that pure lookup changes no result.
    ws_contract_runner.body = functools.lru_cache(maxsize=None)(_RUNNER_BODY)


def tearDownModule():
    ws_contract_runner.body = _RUNNER_BODY


def remember(env, name, state=()):
    """The real source body bound under `name`, with its answers remembered per (arguments, the env fields it reads).
    The old chain asks these thousands of times with the same arguments, which the runner cannot afford; the answer is
    the same each time because the state it reads does not change inside one send."""
    real = env[name]
    known = {}

    def ask(*args):
        key = args + tuple(env[field] for field in state)
        if key not in known:
            known[key] = real(*args)
        return known[key]
    env[name] = ask


def make_env(old, scenario, rows):
    """One environment: the old SendTheme chain (from the fixture) or the shipped one, with identical state."""
    env, _ = fold.style_env()
    logs = []
    env.update(CMFLog=logs.append, logs=logs, drawingRootIds=Array(), drawingRootParts=Array(),
               ResolveKnownTag=lambda provider, word: len(word) * 7 + len(provider),
               AdditiveAllows=lambda feature, provider: provider not in scenario.get('excluded', ()),
               CMFSettingsProviderRank=rank_of, CMFSettingsDebug=lambda: False, debugTiming=False,
               RoundF=lambda value: int(round(value)))
    env['__ws_live_state__'] = tuple(env['__ws_live_state__']) + ('themeMemoOn',)
    for name, args, outs in COMMON_BINDINGS:
        env[name] = bind(CORE, name, env, args, outs)
    for name in ('CMFListHas', 'PartChoice', 'PartKeyChoice', 'ThemeOwnershipKey', 'ThemeLookChoice', 'ChoiceOnlySkips'):
        remember(env, name)
    remember(env, 'CMFProviderBeats', ('menuOrder', 'providerOrder'))
    remember(env, 'PieceBeats', ('choicesActive', 'menuOrder', 'providerOrder'))
    if old:
        for name, args, outs in OLD_BINDINGS:
            env[name] = bind(BEFORE, name, env, args, outs)
    else:
        for name, args, outs in NEW_BINDINGS:
            env[name] = bind(CORE, name, env, args, outs)
    core = Obj(**{name: fn for name, fn in env.items() if callable(fn)})
    env.update(__ws_core_receiver__=core, theGame=Obj(CMFGetCore=lambda: core))
    fill(env, rows)
    env.update(dirty=False, providerOrder=scenario.get('providerOrder', ''), menuOrder=scenario.get('menuOrder', ''),
               choicesActive=scenario.get('choices', False), fallVanilla=scenario.get('fall', False))
    answers = Array([''] * 80)
    for choice, answer in scenario.get('answers', {}).items():
        answers[choice] = answer
    env['decideAnswer'] = answers
    menu = Array([''] * 80)
    for choice, pick in scenario.get('menu', {}).items():
        menu[choice] = pick
    env['menuChoices'] = menu
    files = Array([''] * 80)
    for choice, pick in scenario.get('file', {}).items():
        files[choice] = pick
    env['fileChoices'] = files
    env['PrepareDrawingRoots']()
    return env


def dump(value):
    if hasattr(value, 'fields'):
        return [(k, dump(v)) for k, v in value.fields.items()]
    if isinstance(value, list):
        return [dump(v) for v in value]
    return value


def send(env):
    storage = fold.Storage()
    env['SendTheme'](storage)
    return {key: dump(value) for key, value in storage.sent.items()}


LOOK = (39, 40, 41, 42, 43, 44, 45, 46, 29, 68, 77, 60, 73)
SCENARIOS = {
    'choices off': dict(),
    'choices off, order and excluded drawings': dict(providerOrder=MQI + ',' + FILLERS[5] + ',' + FRAME2, excluded={FILLERS[1], INK}),
    'choices on, nothing picked': dict(choices=True),
    'choices on, @order': dict(choices=True, providerOrder=FILLERS[4] + ',' + MQI, menuOrder=FILLERS[3] + ',' + INK,
                               answers={c: '@order' for c in LOOK}),
    'choices on, picks, fall off': dict(
        choices=True, answers={39: 'vanilla', 40: MQI, 41: INK, 42: '@order', 44: FRAME, 45: SMOOTH, 46: 'vanilla',
                               29: FILLERS[4], 77: FRAME2, 43: FILLERS[9], 68: 'vanilla', 60: INK}),
    'choices on, picks, fall on': dict(
        choices=True, fall=True, providerOrder=INK + ',' + MQI,
        answers={39: MQI, 40: MQI, 41: 'vanilla', 42: INK, 44: FRAME2, 45: 'missingMod', 46: SMOOTH, 29: FILLERS[4],
                 77: INK, 43: '@order', 68: FILLERS[12]}),
    'choices on, a mod picked that is not there, fall on': dict(
        choices=True, fall=True, answers={c: 'missingMod' for c in LOOK}),
    'choices on, in-game and file picks': dict(
        choices=True, providerOrder=SMOOTH, menu={41: FILLERS[9], 39: MQI, 40: FILLERS[2]},
        file={39: INK, 42: FILLERS[11], 43: FILLERS[11]}, answers={c: '' for c in LOOK}),
}


COMPARED = {}  # each scenario runs once for the whole module


class OldVersusNewTests(unittest.TestCase):
    maxDiff = None

    def compare(self, name, scenario, rows):
        key = (name, len(rows))
        if key not in COMPARED:
            COMPARED[key] = self.run_pair(name, scenario, rows)
        return COMPARED[key]

    def run_pair(self, name, scenario, rows):
        old = make_env(True, scenario, rows)
        new = make_env(False, scenario, rows)
        sent_old = send(old)
        sent_new = send(new)
        self.assertEqual(sent_new['cmf.map.theme'], sent_old['cmf.map.theme'], name)
        self.assertEqual(sent_new['cmf.map.lookOwners'], sent_old['cmf.map.lookOwners'], name)
        self.assertEqual(sent_new, sent_old, name)
        self.assertEqual(new['logs'], old['logs'], name)
        self.assertEqual(list(new['themeNotes']), list(old['themeNotes']), name)
        # The memo is gone after the call, and the old chain never used one.
        self.assertFalse(new['themeMemoOn'])
        for field in ('styleMemoKeys', 'styleMemoOwners', 'drawingMemoIds', 'drawingMemoOwners', 'kindMemoKeys',
                      'kindMemoValues', 'leftOutMemoKeys', 'leftOutMemoFlags', 'leftOutMemoOwners',
                      'rankMemoProviders', 'rankMemoValues'):
            self.assertEqual(len(new[field]), 0, (name, field))
        return old, new, sent_old, sent_new

    def test_the_mix_is_the_size_of_the_37_mod_set(self):
        rows = build_entries()
        self.assertGreaterEqual(len(rows), 900)
        self.assertLessEqual(len(rows), 1200)
        self.assertEqual(len({r[0] for r in rows}), 37)
        self.assertEqual(len({r[2] for r in rows if r[0] == INK and r[1] == 2}), 71)  # 70 own drawings and the shared id
        self.assertGreaterEqual(sum(r[1] == 3 for r in rows if r[0] == INK), 550)

    def test_every_scenario_sends_the_same_theme_lookowners_and_log_lines(self):
        rows = build_entries()
        seen = []
        for name, scenario in SCENARIOS.items():
            _, _, sent_old, _ = self.compare(name, scenario, rows)
            theme = sent_old['cmf.map.theme']
            self.assertGreater(len(theme), 100, name)
            self.assertGreater(len(sent_old['cmf.map.lookOwners']), 5, name)
            seen.append(sent_old)
        # The scenarios differ from each other, so the equality is not a comparison of one fixed answer.
        self.assertGreater(len({repr(s['cmf.map.theme']) for s in seen}), 3)

    def test_the_same_notes_are_exercised(self):
        rows = build_entries()
        texts = []
        for name, scenario in SCENARIOS.items():
            old, _, _, _ = self.compare(name, scenario, rows)
            texts.extend(old['logs'])
        for prefix in ('theme style shadowed', 'theme drawing left out', 'theme key without drawing',
                       'theme drawing refused', 'theme source refused'):
            self.assertTrue(any(t.startswith(prefix) for t in texts), prefix)
        self.assertTrue(any('reason=panel' in t for t in texts))
        self.assertTrue(any('reason=choice' in t for t in texts))

    def test_without_a_map_top_the_frame_senders_decide_among_themselves(self):
        rows = build_entries(withTop=False)
        for name in ('choices off', 'choices on, picks, fall off', 'choices on, picks, fall on'):
            self.compare(name + ' (no top)', SCENARIOS[name], rows)

    def test_a_second_send_after_a_change_is_still_equal(self):
        rows = build_entries()
        old = make_env(True, SCENARIOS['choices on, @order'], rows)
        new = make_env(False, SCENARIOS['choices on, @order'], rows)
        self.assertEqual(send(new), send(old))
        for env in (old, new):
            env['decideAnswer'][40] = MQI
            env['decideAnswer'][41] = 'vanilla'
            env['providerOrder'] = FILLERS[8]
            env['fallVanilla'] = True
        self.assertEqual(send(new), send(old))
        self.assertEqual(new['logs'], old['logs'])

    def test_the_memoised_functions_answer_like_the_old_ones_when_no_send_runs(self):
        rows = build_entries()
        for name in ('choices off', 'choices on, picks, fall on'):
            scenario = SCENARIOS[name]
            old = make_env(True, scenario, rows)
            new = make_env(False, scenario, rows)
            self.assertFalse(new['themeMemoOn'])
            seen = set()
            for e in new['themeEntries']:
                if e.kind == 1 and (e.target, e.key) not in seen:
                    seen.add((e.target, e.key))
                    self.assertEqual(new['ThemeStyleOwner'](e.target, e.key), old['ThemeStyleOwner'](e.target, e.key),
                                     (name, e.target, e.key))
            self.assertGreater(len(seen), 80)
            for e in list(new['themeEntries'])[::7]:
                if e.kind == 2:
                    self.assertEqual(new['ThemeDrawingOwner'](e.target), old['ThemeDrawingOwner'](e.target))
                    self.assertEqual(new['DrawingKind'](e.provider, e.target), old['DrawingKind'](e.provider, e.target))
            for provider in ALL_PROVIDERS:
                self.assertEqual(new['ThemeFolderRank'](provider), old['ThemeFolderRank'](provider), provider)
            # Nothing was remembered by those direct calls.
            self.assertEqual(len(new['styleMemoKeys']), 0)
            self.assertEqual(len(new['rankMemoProviders']), 0)

    def test_the_timing_line_is_logged_only_with_cmfdebug(self):
        rows = build_entries()
        scenario = SCENARIOS['choices on, picks, fall off']
        off = make_env(False, scenario, rows)
        send(off)
        self.assertFalse(any(t.startswith('timing theme') for t in off['logs']))
        on = make_env(False, scenario, rows)
        on['CMFSettingsDebug'] = lambda: True
        core = on['theGame'].CMFGetCore()
        on['theGame'] = Obj(CMFGetCore=lambda: core)
        sent = send(on)
        lines = [t for t in on['logs'] if t.startswith('timing theme')]
        self.assertEqual(len(lines), 1)
        self.assertRegex(lines[0], r'^timing theme entries=%d sent=%d$' % (len(rows), len(sent['cmf.map.theme'])))
        self.assertEqual(on['logs'][-1], lines[0])
        # The same state sends the same theme with or without the timing line.
        self.assertEqual(sent, send(off))


class SourceTests(unittest.TestCase):
    def test_each_memoised_function_reads_its_memo_only_under_the_flag(self):
        for name, compute in (('ThemeStyleOwner', 'ComputeThemeStyleOwner'), ('ThemeDrawingOwner', 'ComputeThemeDrawingOwner'),
                              ('DrawingKind', 'ComputeDrawingKind'), ('PanelDrawingLeftOut', 'ComputePanelDrawingLeftOut'),
                              ('ThemeFolderRank', 'ComputeThemeFolderRank')):
            text = body(CORE, name)
            guard = re.search(r'if \(!themeMemoOn\) \{ return ' + compute + r'\(', text)
            self.assertTrue(guard, name)
            self.assertNotIn('for (', text, name)
            self.assertNotIn('while', text, name)
            memo = re.search(r'\w+Memo\w*', text)
            self.assertTrue(memo, name)
            self.assertLess(guard.start(), memo.start(), name)
            computed = body(CORE, compute)
            self.assertNotIn('themeMemoOn', computed, compute)
            self.assertNotRegex(computed, r'\b(style|drawing|kind|leftOut|rank)Memo', compute)

    def test_clear_theme_memo_clears_every_memo_array(self):
        text = body(CORE, 'ClearThemeMemo')
        fields = ('styleMemoKeys', 'styleMemoOwners', 'drawingMemoIds', 'drawingMemoOwners', 'kindMemoKeys',
                  'kindMemoValues', 'leftOutMemoKeys', 'leftOutMemoFlags', 'leftOutMemoOwners', 'rankMemoProviders',
                  'rankMemoValues')
        for field in fields:
            self.assertIn(field + '.Clear();', text, field)
            self.assertRegex(CORE, r'private var ' + field + r' : array<')
        self.assertRegex(CORE, r'private var themeMemoOn : bool;')

    def test_send_theme_sets_the_flag_and_clears_the_memo_at_both_ends(self):
        text = body(CORE, 'SendTheme')
        start = text.index('if (dirty) { Prepare(); }\n\t\tClearThemeMemo();\n\t\tthemeMemoOn = true;')
        end = text.index('SendLookOwners(storage);\n\t\tthemeMemoOn = false;\n\t\tClearThemeMemo();')
        self.assertLess(start, text.index('ThemeStyleOwner('))
        self.assertLess(start, text.index('ThemeFolderRank('))
        self.assertLess(text.index('ThemeFolderRank('), end)
        self.assertEqual(text.count('themeMemoOn = true;'), 1)
        self.assertEqual(text.count('themeMemoOn = false;'), 1)
        self.assertEqual(text.count('ClearThemeMemo();'), 2)
        self.assertNotIn('return', text[start:end].replace('if (!storage)', ''))

    def test_the_timing_line_is_logged_by_send_theme_only_under_debug_timing(self):
        text = body(CORE, 'SendTheme')
        self.assertLess(text.index('debugTiming = CMFSettingsDebug();'), text.index('if (!storage)'))
        self.assertNotIn('GetEngineTimeAsSeconds', text)
        line = ('CMFLog("timing theme entries=" + '
                'themeEntries.Size() + " sent=" + sent);')
        self.assertTrue(text.rstrip().endswith('\t\tif (debugTiming)\n\t\t{\n\t\t\t' + line + '\n\t\t}'))
        self.assertEqual(text.count('timing theme'), 1)
        self.assertLess(text.index('SendLegendRowArt(storage);'), text.index('timing theme'))

    def test_the_version_is_unchanged_and_no_public_api_was_added(self):
        self.assertIn('function CMFGetVersion() : int { return 19; }', CORE)
        for name in ('ClearThemeMemo', 'ThemeStyleOwner', 'ThemeDrawingOwner', 'PanelDrawingLeftOut', 'ThemeFolderRank',
                     'ComputeThemeStyleOwner', 'ComputeThemeDrawingOwner', 'ComputeDrawingKind', 'ComputePanelDrawingLeftOut',
                     'ComputeThemeFolderRank'):
            self.assertRegex(CORE, r'private function ' + name + r'\(')
        self.assertRegex(CORE, r'public function DrawingKind\(')
        self.assertRegex(CORE, r'private function ComputeDrawingKind\(')

    def test_files_are_ascii_tabs_and_lf(self):
        for text in (CORE, BEFORE):
            text.encode('ascii')
            self.assertNotIn('\r', text)
            self.assertNotRegex(text, r'(?m)^ +\S')

    def test_the_fixture_holds_the_old_functions_without_a_memo(self):
        for name in ('ThemeStyleOwner', 'ThemeDrawingOwner', 'DrawingKind', 'PanelDrawingLeftOut', 'ThemeFolderRank',
                     'SendTheme'):
            self.assertRegex(BEFORE, r'function ' + name + r'\(')
        self.assertNotIn('Memo', BEFORE)
        self.assertNotIn('timing', BEFORE)


if __name__ == '__main__':
    unittest.main()
