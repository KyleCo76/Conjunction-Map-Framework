"""The late send line (seam finding S3): only under CMFDebug, after the second send. It reads no clock (the engine time
does not advance within a frame), so it costs nothing without CMFDebug; the panel stamps carry the timing.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ws_text import core_text, ws_function

CORE = core_text()
BODY = ws_function(CORE, 'function UpdateData(optional ignoreSelectionChange : bool)')


class LateSendLine(unittest.TestCase):
    def test_late_send_line_only_under_debug(self):
        at = BODY.index('"late send n="')
        self.assertIn('if (debugOn)', BODY[:at][-60:])
        self.assertEqual(BODY.count('CMFSettingsDebug()'), 1)

    def test_late_send_line_after_second_send(self):
        line = BODY.index('"late send n="')
        self.assertGreater(line, BODY.index('SetFlashArray("worldmap.global.pins.static", flashArray)'))
        self.assertLess(line, BODY.index('CMFMovieBuildSent();'))

    def test_no_clock_is_read(self):
        self.assertNotIn('GetEngineTimeAsSeconds', CORE)


if __name__ == '__main__':
    unittest.main()
