"""Mod author pages: docs/wiki/ is what tools/cmf_author_docs.py builds from docs/authors/, and every link holds."""
import os
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_author_docs as docs

WIKI = ROOT/docs.OUT


def anchors(text):
    found = set()
    fence = False
    for line in text.split('\n'):
        if line.startswith('```'):
            fence = not fence
        match = None if fence else re.match(r'^#{1,6} (.*)$', line)
        if match:
            found.add(docs.slug(match.group(1)))
    return found


class AuthorDocsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = docs.Build()
        cls.pages, cls.theme = cls.build.run()

    def test_build_has_no_errors(self):
        self.assertEqual(self.build.errors, [])

    def test_pages_are_current(self):
        for name, text in self.pages.items():
            self.assertTrue((WIKI/name).exists(), '%s missing: run python tools/cmf_author_docs.py build' % name)
            self.assertEqual((WIKI/name).read_text(encoding='utf-8'), text,
                             '%s is out of date: run python tools/cmf_author_docs.py build' % name)
        self.assertEqual(sorted(p.name for p in WIKI.glob('*.md')), sorted(self.pages))
        self.assertEqual((ROOT/docs.THEME).read_text(encoding='utf-8'), self.theme,
                         'theme tables out of date: run python tools/cmf_author_docs.py build')
        self.assertEqual((ROOT/docs.SETTINGS).read_text(encoding='utf-8'), self.build.settings,
                         'settings keys out of date: run python tools/cmf_author_docs.py build')

    def test_links_and_anchors_resolve(self):
        for name, text in self.pages.items():
            for target in re.findall(r'\]\(([^)\s]+)\)', text):
                if re.match(r'^[a-z]+://', target):
                    continue
                path, _, anchor = target.partition('#')
                full = os.path.normpath(os.path.join(str(WIKI), path or name))
                self.assertTrue(os.path.exists(full), '%s links to missing %s' % (name, target))
                if anchor and full.endswith('.md'):
                    self.assertIn(anchor, anchors(Path(full).read_text(encoding='utf-8')),
                                  '%s links to missing anchor %s' % (name, target))

    def test_every_guide_heading_has_a_page(self):
        placed = set(self.build.where) | docs.LEFT_OUT
        for _level, title, _body in self.build.guide:
            self.assertIn(title, placed)

    def test_every_call_and_hook_is_in_the_reference(self):
        reference = self.pages['API-Reference.md']
        for call in docs.cmf_pack.API:
            self.assertIn('`%s(' % call, reference)
        for hook in docs.cmf_pack.HOOKS:
            self.assertIn('`%s(' % hook, reference)

    def test_nothing_private_is_named(self):
        for name, text in self.pages.items():
            for word in docs.PRIVATE:
                self.assertNotIn(word, text, '%s names %s' % (name, word))

    def test_a_new_guide_heading_without_a_page_fails(self):
        build = docs.Build()
        build.guide.append((3, 'A new section', []))
        build.plan()
        self.assertTrue(any('A new section' in error for error in build.errors))

    def test_an_undescribed_theme_key_fails(self):
        build = docs.Build()
        text = (ROOT/docs.THEME).read_text(encoding='utf-8').replace('`riseOffsetTracked`', 'riseOffsetTracked')
        build.theme_text(text)
        self.assertTrue(any('riseOffsetTracked' in error for error in build.errors))

    def test_every_settings_key_is_listed(self):
        core = (ROOT/docs.CORE).read_text(encoding='utf-8')
        listed = re.search(r'function CMFChoiceKeys\(\) : string\s*\{\s*return (.*?);', core, re.S).group(1)
        keys = [k for k in ''.join(re.findall(r'"([^"]*)"', listed)).split(',') if k]
        self.assertGreater(len(keys), 50)
        page = self.pages['Settings-File-Keys.md']
        for key in keys + ['Fallthrough']:
            self.assertIn('| `CMFFile_%s` |' % key, page)

    def test_a_choice_key_without_a_menu_row_fails(self):
        build = docs.Build()
        real = docs.read
        docs.read = lambda path: real(path).replace('CMFPick_Look_Hints', 'CMFPick_Gone') if path == docs.CHOICE_MENU else real(path)
        try:
            build.settings_tables()
        finally:
            docs.read = real
        self.assertTrue(any('Look_Hints' in error for error in build.errors))

    def test_wiki_form(self):
        build = docs.Build(wiki=True, repo_url='https://github.com/OWNER/REPO')
        pages, _theme = build.run()
        self.assertEqual(build.errors, [])
        self.assertIn('_Sidebar.md', pages)
        self.assertIn('](Getting-Started)', pages['Home.md'])
        self.assertIn('](https://github.com/OWNER/REPO/tree/main/examples/modCMFExampleIconPack)',
                      pages['Getting-Started.md'])
        self.assertNotIn('.md)', pages['Home.md'])


if __name__ == '__main__':
    unittest.main()
