"""The author guide documents the API 18 rules (grid keep revoke, refresh refusal, one-pin updates, Velen alias).

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUIDE = (ROOT / 'docs/authors/icon-pack-guide.md').read_text(encoding='utf-8')
WIKI = (ROOT / 'docs/wiki/API-Reference.md').read_text(encoding='utf-8')


class Api18Docs(unittest.TestCase):
    def test_guide_documents_api18(self):
        at = GUIDE.index('### Keeping pins over a grid, refreshing and one-pin updates (API version 18)')
        text = GUIDE[at:GUIDE.index('\n### ', at + 5)]
        for needle in ('CMFGridUnkeepPin', 'CMFPropertyGridKeepEpoch', 'property 49', "CMFHasAbility('grid', 'keepRevoke')",
                       "Any provider's keep", 'refused', 'CMFMapRefreshPins', 'CMFMapRefresh`', 'one-pin', 'version 18'):
            self.assertIn(needle, text, needle)
        self.assertIn('AN_Velen', GUIDE)

    def test_wiki_line_names_any_provider(self):
        self.assertNotIn("this provider's grid drawings", WIKI)

    def test_on_map_ready_wording_matches_late_pins(self):
        self.assertIn('it runs again when late pins are caught', GUIDE)
        self.assertNotIn('calls `OnMapReady(menuFlash : CScriptedFlashSprite)` once, before', GUIDE)


if __name__ == '__main__':
    unittest.main()
