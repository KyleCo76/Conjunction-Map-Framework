"""Animation text parsing is linear: long programs parse as before and as the Python reference, and no loop copies the remainder."""
import random
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tests'), str(ROOT / 'tools')]
import rev14_animation_contracts as contracts
import cmf_animation
import cmf_animation_cost as cost

CORE = contracts.CORE
FRAME = 'img://icons/pack/frame_%02d.png'


def parse_new(text, fps=8):
    return contracts.actual_parse(text, fps)


def parse_reference(text, fps=8):
    try:
        result = cmf_animation.parse_animation(text, fps)
    except ValueError as err:
        return dict(ok=False, canonical='', poster='', reason=str(err))
    return dict(ok=True, canonical=result['canonical'], poster=result['poster'], reason='')


def old_core():
    """The core as it was before the linear walk (the parent commit of this change), for an identical-result check."""
    base = 'ae24d32'
    out = subprocess.run(['git', 'show', base + ':source/core/content/scripts/local/cmfCore.ws'], cwd=ROOT,
                         capture_output=True, text=True)
    return out.stdout if out.returncode == 0 else None


def long_programs():
    stage = 's%d;frames=%s;fps=%d;plays=%s;direction=%s;holdFirst=0.5;holdLast=1;offset=%s;delay=0.25'
    for stages in (1, 2, 4, 8):
        for frames in (2, 5, 16):
            parts = ['program:v1', 'delay=1.5', 'finish=hold', 'poster=first', 'join=shared']
            for s in range(stages):
                last = s == stages - 1
                parts.append('stage=' + stage % (s, ','.join(FRAME % f for f in range(frames)), 8 + s,
                                                  'forever' if last and s % 2 else str(s + 1),
                                                  ('forward', 'reverse', 'pingpong')[s % 3], 'inherit' if s % 2 else '3'))
            if not parts[-1].split('plays=')[1].startswith('forever'):
                parts.append('repeat=3')
            yield '|'.join(parts)
    yield '  \t' + ',  '.join(FRAME % f for f in range(16)) + ' \n '
    yield ' ' * 1500 + ','.join(FRAME % f for f in range(16)) + ' ' * 600
    yield 'program:v1' + '|' + 'stage=a;frames=' + ','.join(FRAME % f for f in range(16)) + ';plays=1' + ' ' * 900


class LinearParseTests(unittest.TestCase):
    def test_long_programs_match_reference(self):
        env = contracts.parser_environment()
        for text in long_programs():
            for fps in (1, 8, 30):
                got = contracts.actual_parse(text, fps, env)
                self.assertEqual(got, parse_reference(text, fps), (len(text), fps))

    def test_refusals_keep_their_reasons(self):
        ok = 'stage=a;frames=' + ','.join(FRAME % f for f in range(3))
        cases = ['program:v1|' + ok + '|stage=a;frames=' + FRAME % 1 + ',' + FRAME % 2, 'program:v1|' + ok + ';',
                 'program:v1|' + ok + ';plays=0', 'program:v1|' + ok + ';x=1', 'program:v1|', 'program:v1', 'program:v1|=',
                 'program:v1|delay=1|delay=2|' + ok, 'program:v1|finish=maybe|' + ok, 'program:v1|' + ok + '|',
                 ','.join(FRAME % f for f in range(17)), FRAME % 1, '', ' ', ',', 'x' * 8193,
                 'program:v1|' + '|'.join('stage=s%d;frames=%s,%s' % (i, FRAME % 1, FRAME % 2) for i in range(9))]
        env = contracts.parser_environment()
        for text in cases:
            self.assertEqual(contracts.actual_parse(text, 8, env), parse_reference(text, 8), text[:60])

    def test_random_programs_match_old_core(self):
        old = old_core()
        if old is None:
            self.skipTest('parent commit not available')
        saved = contracts.CORE
        try:
            contracts.CORE = old
            old_env = contracts.parser_environment()
        finally:
            contracts.CORE = saved
        new_env = contracts.parser_environment()
        rng = random.Random(14)
        pieces = ['program:v1', 'stage=a', 'stage=b', 'frames=' + FRAME % 1 + ',' + FRAME % 2, 'frames=' + FRAME % 3,
                  'fps=12', 'plays=forever', 'plays=2', 'delay=0.5', 'poster=first', 'finish=hold', 'repeat=2', '',
                  ' ', 'join=shared', 'direction=reverse', 'offset=inherit', 'x=1', 'repeatFrom=a', 'holdFirst=1']
        for _ in range(120):
            top = rng.choice(['program:v1|', 'program:v1|', ''])
            if top:
                text = top + '|'.join(';'.join(rng.choice(pieces) for _ in range(rng.randint(1, 5)))
                                      for _ in range(rng.randint(0, 4)))
            else:
                text = ','.join(rng.choice([FRAME % rng.randint(0, 9), ' ', 'bad', '']) for _ in range(rng.randint(0, 5)))
            self.assertEqual(contracts.actual_parse(text, 8, new_env), contracts.actual_parse(text, 8, old_env), text)

    def test_control_characters_are_refused_exactly_as_before(self):
        ok = ','.join(FRAME % f for f in range(3))
        cases = [ok + '\x01', FRAME % 1 + ',img://a\x07b', ' \t' + ok + '\n ', ok.replace(',', ',\t', 1),
                 ok.replace(',', '\t,', 1), 'program:v1|stage=a;frames=' + ok + '\x7f',
                 'program:v1|stage=a;frames=' + ok + ';fps=\x0b8', 'program:v1|stage=a;frames=' + ok + ';plays=\t1\t',
                 'program:v1|delay=\x1f1|stage=a;frames=' + ok, 'program:v1|stage=a;frames=' + ok + '|poster=' + FRAME % 1 + '\x9f',
                 '\x85' + ok]
        env = contracts.parser_environment()
        for text in cases:
            self.assertEqual(contracts.actual_parse(text, 8, env), parse_reference(text, 8), repr(text))
        self.assertFalse(env['animationTextClean'], 'the flag never outlives a parse')

    def test_native_calls_per_program(self):
        text = cost.program(7, 16)
        counts = {}

        def counted(env, name):
            inner = env[name]

            def wrapper(*args):
                counts[name] = counts.get(name, 0) + 1
                return inner(*args)
            env[name] = wrapper

        old = old_core()
        if old is None:
            self.skipTest('parent commit not available')
        saved = contracts.CORE
        totals = {}
        try:
            for label, source in (('old', old), ('new', saved)):
                contracts.CORE = source
                env = contracts.parser_environment()
                counts.clear()
                for name in ('StrFindFirst', 'StrChar', 'StrMid', 'StrLeft', 'StrRight', 'StrBeforeFirst', 'StrAfterFirst'):
                    counted(env, name)
                # The wrapped natives were captured when the functions were bound, so bind again over the wrapped ones.
                env = contracts.parser_environment()
                for name in ('StrFindFirst', 'StrChar', 'StrMid', 'StrLeft', 'StrRight', 'StrBeforeFirst', 'StrAfterFirst'):
                    counted(env, name)
                contracts.install(env, set(__import__('re').findall(r'function (Animation\w+|ParseAnimation)\(', source)) | {'TrimFilterWord', 'ClaimNumber', 'ParseAskInt'})
                counts.clear()
                self.assertTrue(contracts.actual_parse(text, 8, env)['ok'])
                totals[label] = dict(counts)
        finally:
            contracts.CORE = saved
        print('\nnative calls for one %d-char program: %s' % (len(text), totals))
        self.assertLess(totals["new"]["StrChar"] * 20, totals["old"]["StrChar"])
        self.assertLess(sum(totals["new"].values()) * 2, sum(totals["old"].values()))

    def test_no_loop_copies_the_remainder(self):
        for name in ('AnimationFrames', 'AnimationStage', 'AnimationDecode', 'AnimationCount', 'AnimationTrim'):
            start = CORE.index('private function %s(' % name)
            body = CORE[start:CORE.index('\n\t}\n', start)]
            self.assertNotIn('StrAfterFirst(rest', body, name)
            self.assertNotIn('StrBeforeFirst(rest', body, name)
            self.assertNotIn('StrRight(text, StrLen(text) - 1)', body, name)
        self.assertIn('private function AnimationNextPiece(', CORE)
        self.assertNotIn('AnimationCount(cached.canonical, "|stage=")', CORE)

    def test_copy_model_is_linear(self):
        small = cost.program(2, 16)
        large = cost.program(8, 16)
        for text in (small, large):
            self.assertLess(cost.cost(text, cost.new_split, cost.new_trim), cost.cost(text, cost.old_split, cost.old_trim))
        padded = ' ' * 8000 + 'x'
        self.assertEqual(cost.new_trim(padded)[1], 1)
        self.assertGreater(cost.old_trim(padded)[1], 30000000)


if __name__ == '__main__':
    unittest.main()
