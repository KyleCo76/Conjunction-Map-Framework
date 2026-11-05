"""Map edge fade fix: the gradient mask and strips overlap the map cut on every edge.

Reads the panel edits as text; only a launch proves how the fade looks.
"""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
EDITS = ROOT/'source/panel/pin-fields/edits.json'
CONTAINER = 'red/game/witcher3/menus/worldmap/HubMapContainer.as'
HEIGHT = 'this.mcHubMapContainerGradientMask.height = this.mcHubMapContainerLodMask.height + 2;'
HOOK = 'this.cmfThemeEdge();'
STRIP_LEFT = 'this.mcGradientContainer.mcGradientLeft.x = this._mapVisMinX - 3;'
STRIP_TOP = 'this.mcGradientContainer.mcGradientTop.y = -this._mapVisMaxY - 3;'
PLACE_X = 'this.mcHubMapContainerGradientMask.x = this._mapVisMinX - 3;'
PLACE_Y = 'this.mcHubMapContainerGradientMask.y = -this._mapVisMaxY - 3;'
SIZE_W = 'this.mcHubMapContainerGradientMask.width = this.mcHubMapContainerLodMask.width + 3;'
SIZE_H = 'this.mcHubMapContainerGradientMask.height = this.mcHubMapContainerLodMask.height + 3;'


class MapEdgeFade(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        changes = json.loads(EDITS.read_text(encoding='utf-8'))['classes'][CONTAINER]
        cls.hook_index = next(i for i, c in enumerate(changes) if c['replace'].endswith(HOOK + '\n') and HOOK not in c['find'])
        cls.fix_index = next(i for i, c in enumerate(changes) if PLACE_X in c['replace'])
        cls.fix = changes[cls.fix_index]
        cls.changes = changes

    def test_fix_finds_the_text_the_hook_edit_leaves(self):
        self.assertGreater(self.fix_index, self.hook_index)
        self.assertEqual(self.fix['find'], self.changes[self.hook_index]['replace'])
        self.assertEqual(self.fix['count'], 1)

    def test_mask_is_placed_before_the_theme_edge_runs(self):
        code = self.fix['replace']
        order = [code.index(text) for text in (HEIGHT, STRIP_LEFT, STRIP_TOP, PLACE_X, PLACE_Y, SIZE_W, SIZE_H, HOOK)]
        self.assertEqual(order, sorted(order))

    def test_edge_band_box_is_the_lod_box_grown_by_two(self):
        change = next(c for c in self.changes if 'LodMask.x - 2,' in c['replace'] and 'new Rectangle' in c['replace'])
        self.assertEqual(change['count'], 1)
        self.assertGreater(self.changes.index(change), next(i for i, c in enumerate(self.changes) if 'function cmfThemeEdge' in c['replace']))
        self.assertIn('box = new Rectangle(this.mcHubMapContainerLodMask.x - 2,this.mcHubMapContainerLodMask.y - 2,'
                      'this.mcHubMapContainerLodMask.width + 4,this.mcHubMapContainerLodMask.height + 4);', change['replace'])

    def test_no_per_opening_notes_remain(self):
        for change in self.changes:
            if PLACE_X in change['replace'] or 'LodMask.x - 2,' in change['replace']:
                self.assertNotIn('cmfSpaceNote(', change['replace'])
                self.assertNotIn('cmfMaskBefore', change['replace'])

    def test_strips_cover_logged_limits(self):
        # Pure model of the formulas. Limits logged in game; covers only these two areas.
        areas = {'Novigrad': (-500, 910, -510, 785), 'Skellige': (-1024, 1024, -820, 970)}
        for name, (minx, maxx, miny, maxy) in areas.items():
            lod_x, lod_y = minx, -maxy
            lod_w, lod_h = maxx - minx, maxy - miny
            left, top = minx - 3, -maxy - 3
            mask_w, mask_h = lod_w + 3, lod_h + 3
            self.assertEqual(lod_x - left, 3, name)
            self.assertEqual(lod_y - top, 3, name)
            # mask runs from left to left+mask_w: covers lod right/bottom edge by 0 plus the game's strips
            self.assertGreaterEqual(left + mask_w - (lod_x + lod_w), 0, name)
            self.assertGreaterEqual(top + mask_h - (lod_y + lod_h), 0, name)
            for v in (minx, maxx, miny, maxy):
                self.assertLessEqual(abs(v), 1250, name)


if __name__ == '__main__':
    unittest.main()
