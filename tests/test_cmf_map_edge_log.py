"""CMF logs each map area's visible and scroll limits and zoom range beside its tile geometry (logging only)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / 'source/core/content/scripts/local/cmfCore.ws'


class MapEdgeLog(unittest.TestCase):
    def setUp(self):
        text = CORE.read_text(encoding='ascii')
        start = text.index('public function MapImageRoot(')
        self.body = text[start:text.index('return root;', start)]

    def test_limits_line_follows_the_background_line(self):
        self.assertIn('CMFLog("background limits area=', self.body)
        self.assertLess(self.body.index('" mapSize="'), self.body.index('background limits area='))

    def test_every_limit_and_zoom_is_logged_by_the_games_own_call(self):
        for key, call in (('vMinX', 'Vmin' + 'X'), ('vMaxX', 'VmaxX'), ('vMinY', 'VminY'), ('vMaxY', 'VmaxY'),
                          ('sMinX', 'SminX'), ('sMaxX', 'SmaxX'), ('sMinY', 'SminY'), ('sMaxY', 'SmaxY'),
                          ('minZoom', 'MinZoom'), ('maxZoom', 'MaxZoom')):
            self.assertIn('" %s=" + FloatToString(theGame.GetMiniMap%s(area))' % (key, call), self.body)


if __name__ == '__main__':
    unittest.main()
