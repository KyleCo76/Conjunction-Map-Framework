"""The map's edge frame keys go with the owner of the map's top edge (2026-10-31, Map Quest Insight's full-screen bars)."""
import unittest

from test_cmf_rev13_fold_registration import style_env

FRAME = ('frame', 'frameTop', 'frameBottom')


class MapFrameOwnerTests(unittest.TestCase):
    def send(self, env, provider, key, text='', number=0.):
        self.assertTrue(env['CMFStylePart'](provider, 'map', key, text, number), (provider, key))

    def owners(self, env):
        return {key: env['ThemeStyleOwner']('map', key) for key in ('top',) + FRAME}

    def test_frame_only_provider_never_takes_top_and_follows_its_owner(self):
        # A sends only frame keys, B sends top: B keeps top and owns the frame keys, so A's frame is shadowed.
        for first in ('modA', 'modB'):
            env, _ = style_env()
            order = (('modA', 'frame', 'area'), ('modA', 'frameTop', '', 0.25), ('modB', 'top', '', 100.))
            for entry in (order if first == 'modA' else order[::-1]):
                self.send(env, *entry)
            owners = self.owners(env)
            self.assertEqual(owners['top'], 'modB', first)
            self.assertEqual({owners[key] for key in FRAME}, {'modB'}, first)

    def test_frame_goes_with_top_when_both_send_top(self):
        # A sends top and frame, B sends top and wins it: A's frame is shadowed with A's top.
        env, _ = style_env()
        self.send(env, 'modB', 'top', '', 100.)
        self.send(env, 'modA', 'top', '', 0.)
        self.send(env, 'modA', 'frame', 'area')
        self.send(env, 'modA', 'frameBottom', '', 0.75)
        top = env['ThemeStyleOwner']('map', 'top')
        self.assertIn(top, ('modA', 'modB'))
        self.assertEqual({env['ThemeStyleOwner']('map', key) for key in FRAME}, {top})
        if top == 'modB':
            self.assertNotEqual(env['ThemeStyleOwner']('map', 'frame'), 'modA')

    def test_top_ownership_is_unchanged_by_frame_keys(self):
        for frame_sender in ('', 'modA', 'modC'):
            env, _ = style_env()
            self.send(env, 'modB', 'top', '', 100.)
            self.send(env, 'modA', 'top', '', 0.)
            before = env['ThemeStyleOwner']('map', 'top')
            if frame_sender:
                self.send(env, frame_sender, 'frame', 'area')
            self.assertEqual(env['ThemeStyleOwner']('map', 'top'), before, frame_sender)

    def test_frame_only_provider_owns_it_when_nobody_sends_top(self):
        env, _ = style_env()
        self.send(env, 'modA', 'frame', 'area')
        self.send(env, 'modA', 'frameTop', '', 0.18359375)
        self.send(env, 'modA', 'frameBottom', '', 0.828125)
        self.assertEqual(self.owners(env), {'top': '', 'frame': 'modA', 'frameTop': 'modA', 'frameBottom': 'modA'})


if __name__ == '__main__':
    unittest.main()
