"""Smooth map movement (P6): the navigation keys, the opening part, "unset", and the panel edits that act on them.

Design: research/2026-10-20-cmf-smooth-map-movement-p6.md in the project's shared folder (sections 5, 7, 10 and
Appendix A). Static checks and a model of the panel's elapsed-time step; nothing here compiled or ran in game.
"""
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
GUIDE = ROOT/'docs/authors/icon-pack-guide.md'
SMOOTH_PACK = ROOT/'source/providers/modZZCMFTestSmooth/content/scripts/local/modzzcmftestsmooth_cmf.ws'
SMOOTH_MENU = ROOT/'source/settings/menus/modZZCMFTestSmooth.xml'
SMOOTH_STRINGS = ROOT/'source/settings/modZZCMFTestSmooth.strings.json'
# Record section 5.2, Smooth Map's column.
SMOOTH_MAP = {
    ('navigation', 'frameTimed'): 1, ('navigation', 'stepMs'): 17, ('navigation', 'worldStepMs'): 24,
    ('navigation', 'maxStepMs'): 100, ('navigation', 'zoomTimed'): 1, ('navigation', 'padHoldMs'): 0,
    ('navigation', 'tweenEveryFrame'): 1, ('opening', 'pinsDuringSlide'): 1, ('opening', 'pinStepMs'): 1,
    ('opening', 'pinBatch'): 0, ('opening', 'pinBudgetMs'): 8, ('opening', 'showDelayMs'): 1,
    ('opening', 'fadeSeconds'): 0.2, ('opening', 'tileFadeSeconds'): 0.2, ('opening', 'revealSeconds'): 0.2,
}
WORLDMAP = 'red/game/witcher3/menus/worldmap/'

NAVIGATION_NEW = ['zoomTimed', 'padHoldMs', 'tweenEveryFrame', 'frameRate', 'zoomOutFit', 'edgeOvershoot']
OPENING = ['slideSeconds', 'slideOffset', 'closeSeconds', 'pinsDuringSlide', 'pinStepMs', 'pinBatch', 'pinBudgetMs',
           'pinBudgetAfterSlideMs', 'showDelayMs', 'fadeSeconds', 'tileFadeSeconds', 'revealSeconds']
# Record section 5.2 and Appendix A.3: (lowest, highest); switches take 0 or 1.
RANGES = {
    'zoomTimed': 'switch', 'tweenEveryFrame': 'switch', 'zoomOutFit': 'switch', 'pinsDuringSlide': 'switch',
    'stepMs': (1, 1000), 'worldStepMs': (1, 1000), 'maxStepMs': (1, 1000), 'pinStepMs': (1, 1000),
    'padHoldMs': (0, 1000), 'pinBudgetMs': (0, 1000), 'pinBudgetAfterSlideMs': (0, 1000), 'showDelayMs': (0, 5000), 'frameRate': (24, 60),
    'edgeOvershoot': (0, 400), 'slideOffset': (-2000, 2000), 'pinBatch': (0, 100000),
    'slideSeconds': (0, 5), 'closeSeconds': (0, 5), 'fadeSeconds': (0, 5), 'tileFadeSeconds': (0, 5),
    'revealSeconds': (0, 5),
}


def body(text, signature):
    start = text.index(signature)
    end = text.index('\n}', start) if text[start - 1] == '\n' else text.index('\n\t}', start)
    return text[start:end]


def joined(edits, path):
    return ''.join(e['replace'] for e in edits['classes'][path])


def motion_ranges(core):
    """CMFThemeMotionValueOk as a table: key -> 'switch' or (lowest, highest)."""
    code = body(core, 'function CMFThemeMotionValueOk(key : name, number : float) : bool')
    table, pending = {}, []
    for line in code.splitlines():
        line = line.strip()
        case = re.match(r"case '(\w+)':", line)
        if case:
            pending.append(case.group(1))
            continue
        if line.startswith('return number') and pending:
            if line == 'return number == 0 || number == 1;':
                value = 'switch'
            else:
                low, high = re.match(r'return number >= (-?\d+) && number <= (\d+);', line).groups()
                value = (int(low), int(high))
            table.update(dict.fromkeys(pending, value))
            pending = []
    default = re.search(r'\}\n\treturn number >= (\d+) && number <= (\d+);', code)
    return table, (int(default.group(1)), int(default.group(2)))


def pan_px(fps, seconds, step_ms=17, max_step_ms=100, hitch_at=None, hitch_ms=0):
    """Mirrors HubMap.cmfNavTick for a held key: 15 px per step_ms of elapsed time, gaps capped at max_step_ms."""
    now, last, px = 0.0, -1.0, 0.0
    frame = 1000.0 / fps
    while now < seconds * 1000:
        now += frame
        if hitch_at is not None and last < hitch_at <= now:
            now += hitch_ms
        ms = step_ms if last < 0 else now - last
        if ms < 1:
            continue
        last = now
        px += 15 * min(ms, max_step_ms) / step_ms
    return px


def zoom_steps(fps, seconds, step_ms=17, max_step_ms=100):
    """Mirrors the zoomTimed 0 accumulator: the first frame steps once, then one step per step_ms elapsed."""
    now, last, debt, held, steps = 0.0, -1.0, 0.0, False, 0
    frame = 1000.0 / fps
    while now < seconds * 1000:
        now += frame
        ms = step_ms if last < 0 else now - last
        last = now
        f = min(ms, max_step_ms) / step_ms
        debt = debt + f if held else 1
        held = True
        n = min(int(debt), -(-max_step_ms // step_ms))
        debt -= int(debt)
        steps += n
    return steps


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_keys_and_opening_part(self):
        from rev13_legacy_source import theme_environment, check_behavior_anchors
        env = theme_environment(self.core)
        navigation = env['CMFThemeNavigationKeys']().split(',')
        self.assertEqual(navigation[:len(NAVIGATION_NEW)], NAVIGATION_NEW)
        self.assertTrue(set(navigation) <= set(cmf_pack.THEME_PART_KEYS['navigation']))
        opening = env['CMFThemeOpeningKeys']().split(',')
        self.assertEqual(opening[:len(OPENING) + 2], OPENING + ['readyAtFadeStart', 'revealEase'])
        self.assertEqual(opening, list(cmf_pack.THEME_PART_KEYS['opening']))
        self.assertIn('opening', env['CMFThemeParts']().split(','))
        # Opening remains won per key and must be rejected as a drawing anchor.
        self.assertIn("part == 'opening' || part == 'spread' ||", body(self.core, 'private function ThemeStyleOwner('))
        check_behavior_anchors(self, self.core, ('navigation', 'opening', 'spread', 'wide'))

    def test_ranges_match_the_record(self):
        table, default = motion_ranges(self.core)
        self.assertEqual(default, (0, 5))
        for key, expected in RANGES.items():
            self.assertEqual(table.get(key, default), expected, key)
        routed = body(self.core, 'function CMFThemeValueOk(part : name, key : name, text : string, number : float)')
        self.assertIn("if (part == 'opening' || (part == 'navigation' && (CMFListHas(CMFThemeNavigationKeys(), k) || "
                      'k == "stepMs" ||\n\t\tk == "worldStepMs" || k == "maxStepMs")))\n\t{\n'
                      '\t\treturn CMFThemeMotionValueOk(key, number);', routed)

    def test_unset_withdraws_only_this_providers_key(self):
        style = body(self.core, 'function CMFStylePart(provider : string, part : name, key : name, text : string, '
                                'number : float) : bool')
        unknown = style.index('reason=unknown')
        unset = style.index('if (text == "unset")')
        value = style.index('if (!CMFThemeValueOk(part, key, text, number))')
        self.assertLess(unknown, unset)
        self.assertLess(unset, value)
        # Version 12 (review Q4): logged only when a value was there to withdraw.
        self.assertIn('if (theGame.CMFGetCore().UnsetTheme(provider, part, key) > 0)\n\t\t{\n\t\t\tCMFLog("theme unset '
                      'provider=" + provider + " part=" + NameToString(part) + " key=" + NameToString(key));\n\t\t}\n'
                      '\t\treturn true;', style)
        withdraw = body(self.core, '\tpublic function UnsetTheme(provider : string, part : name, key : name) : int')
        self.assertIn('themeEntries[i].provider == provider && themeEntries[i].kind == 1 && '
                      'themeEntries[i].target == part &&\n\t\t\t\tthemeEntries[i].key == key', withdraw)
        self.assertIn('themeEntries.Erase(i);', withdraw)

    def test_version_is_six(self):
        # P6 ships with pin clicks as API version 6.
        self.assertIn('function CMFGetVersion() : int { return 19; }', self.core)


class PanelTests(unittest.TestCase):
    def setUp(self):
        self.edits = json.loads(EDITS.read_text(encoding='utf-8'))
        self.hub = joined(self.edits, WORLDMAP + 'HubMap.as')
        self.menu = joined(self.edits, WORLDMAP + 'MapMenu.as')
        self.container = joined(self.edits, WORLDMAP + 'HubMapContainer.as')
        self.universe = joined(self.edits, WORLDMAP + 'UniverseMap.as')
        self.tween = joined(self.edits, 'com/gskinner/motion/GTween.as')

    def test_no_claim_no_change(self):
        # Every opening value defaults to the game's own constant, and the timers only change under frameTimed.
        for text in ('new Timer(this.cmfPinStepMs())', 'MapMenu.cmfNum("opening","pinStepMs",20)',
                     'MapMenu.cmfNum("opening","pinBatch",MAX_PROCESSED_PIN_COUNT)',
                     'MapMenu.cmfNum("opening","showDelayMs",SHOW_INTERVAL)',
                     'MapMenu.cmfNum("opening","fadeSeconds",FADING_GRADIENT_DURATION)',
                     'MapMenu.cmfNum("opening","tileFadeSeconds",FADING_TEXTURES_DURATION)',
                     'if(this._menuAnimCompleted || MapMenu.cmfNum("opening","pinsDuringSlide",0) != 0)',
                     'this._scrollAndZoomTimer = this.cmfRetime(this._scrollAndZoomTimer,'
                     'this.cmfTimed ? 1 : SCROLL_AND_ZOOM_INTERVAL_MS,this.handleScrollAndZoomTimer);',
                     'private static const SCROLL_AND_ZOOM_INTERVAL_MS:Number = 17;',
                     'if(this.cmfTimed)\n         {\n            this.cmfNavTick();\n            return;\n         }'):
            self.assertIn(text, self.hub)
        self.assertIn('this.scrollTimer = this.cmfRetime(this.scrollTimer,this.cmfTimed ? 1 : SCROLL_INTERVAL_MS,'
                      'this.handleScrollTimer);', self.universe)
        self.assertIn('private static const SCROLL_INTERVAL_MS:Number = 24;', self.universe)
        self.assertIn('if(this.cmfTimed)\n         {\n            this.cmfScrollTick();\n            return;', self.universe)
        # The stick acceleration timer keeps its own 150 ms beat.
        for edit in self.edits['classes'][WORLDMAP + 'HubMap.as']:
            self.assertNotIn('_speedTimer', edit['find'] + edit['replace'])
            self.assertNotIn('handleSpeedTimer', edit['find'] + edit['replace'])

    def test_timers_are_replaced_not_retimed(self):
        # Narcolepsy, 2026-10-24: a running Scaleform timer ignores a new delay, so the panel never writes one;
        # cmfRetime stops the old timer and starts a new one at the asked delay (only if the old one ran).
        for text in (self.hub, self.universe):
            self.assertNotIn('.delay = ', text)
            self.assertIn('if(param1.delay == param2)\n         {\n            return param1;', text)
            self.assertIn('running = param1.running;\n         param1.removeEventListener(TimerEvent.TIMER,param3);\n'
                          '         param1.stop();\n         timer = new Timer(param2);\n'
                          '         timer.addEventListener(TimerEvent.TIMER,param3,false,0,true);\n'
                          '         if(running)\n         {\n            timer.start();', text)
        self.assertIn('this._initialTimer = this.cmfRetime(this._initialTimer,this.cmfPinStepMs(),this.handleInitialTimer);',
                      self.hub)

    def test_view_measured_again_after_the_slide(self):
        # Narcolepsy, 2026-10-24: with pinsDuringSlide the view at rest is measured again when the slide ends.
        self.assertIn('this.updatePreviewAnchorPosition();\n'
                      '         // pinsDuringSlide: pins and tiles were placed while the menu slid in', self.hub)
        self.assertIn('if(MapMenu.cmfNum("opening","pinsDuringSlide",0) != 0 && IsEnabled())\n         {\n'
                      '            this.UpdateVisibilityAndPinPositions(false);\n'
                      '            this.mcHubMapZoomContainer.mcHubMapContainer.ShowTilesFromCurrentLod();', self.hub)

    def test_elapsed_step(self):
        for text in ('ms = this.cmfLastTick < 0 ? this.cmfStepMs : now - this.cmfLastTick;',
                     'if(ms < 1)\n         {\n            return;', 'ms = Math.min(ms,this.cmfMaxStepMs);',
                     'f = ms / this.cmfStepMs;', 'dy = KEYBOARD_SCROLL_SPEED * f;',
                     'this.scrollMap(this.cmfPadX * 0.5 * f,this.cmfPadY * 0.5 * f);',
                     'this._isZooming = this.ZoomByFactor(Math.pow(base,dir * f));',
                     'this.cmfZoomDebt = this.cmfZoomHeld ? this.cmfZoomDebt + f : 1;',
                     'else if(now - this.cmfPadAt > this.cmfPadHoldMs)'):
            self.assertIn(text, self.hub)
        self.assertIn('f = Math.min(ms,this.cmfMaxStepMs) / this.cmfStepMs;', self.universe)
        # Held keys cover the same distance at any frame rate; a hitch counts at most maxStepMs.
        expected = 15 * 3000 / 17
        for fps in (30, 60, 144):
            self.assertAlmostEqual(pan_px(fps, 3) / expected, 1, delta=0.02, msg=fps)
        # The hitched frame spans 500 ms plus one frame but moves only maxStepMs worth.
        lost = 15 * (500 + 1000 / 60 - 100) / 17
        self.assertAlmostEqual(pan_px(60, 3) - pan_px(60, 3, hitch_at=1000, hitch_ms=500), lost, delta=20)
        # zoomTimed 0: one zoom step per stepMs at any frame rate (to within the last partial step).
        for fps in (30, 60, 144):
            self.assertAlmostEqual(zoom_steps(fps, 2), 2000 / 17, delta=1.5, msg=fps)

    def test_pin_batch_rule(self):
        self.assertIn('return Math.max(1,int(batch));', self.hub)
        self.assertIn('return MapMenu.cmfNum("opening","pinBudgetMs",0) > 0 || MapMenu.cmfNum("opening","pinBudgetAfterSlideMs",0) > 0 ? 100000 : 30000;', self.hub)
        self.assertIn('if(cmfBudget > 0 && _loc4_ > cmfFirst && getTimer() - cmfStart >= cmfBudget)', self.hub)

    def test_log_notes(self):
        for text in ('"nav pan ms=" + Math.round(this.cmfPanMs) + " ticks=" + this.cmfPanTicks + " px=" + '
                     'Math.round(this.cmfPanPx)', '"nav zoomOutFit min="'):
            self.assertIn(text, self.hub)
        for text in ('"opening ms=" + ms', 'note = "nav frameTimed=" + ', '" frameRate asked=" + ', '" now=" + ',
                     '" opening=slide:" + ', '" ready=" + ms + "ms"', 'this._cmfOpenedAt = getTimer();'):
            self.assertIn(text, self.menu)

    def test_frame_rate_and_tweens(self):
        self.assertIn('stage.frameRate = this._cmfFrameRateAsked;', self.menu)
        self.assertIn('stage.frameRate = this._cmfFrameRateWas;', self.menu)
        self.assertIn('if(MapMenu.cmfNum("navigation","tweenEveryFrame",0) != 0)\n            {\n'
                      '               GTween.cmfTickEveryFrame(true);', self.menu)
        self.assertIn('GTween.cmfTickEveryFrame(false);', self.menu)
        self.assertIn('cmfTimer = new Timer(1);\n            cmfTimer.addEventListener(TimerEvent.TIMER,staticTick);',
                      self.tween)

    def test_opening_and_reveal(self):
        self.assertIn('override public function hideAnimation() : void', self.menu)
        self.assertIn('if(!MapMenu.cmfHas("opening","closeSeconds") || closingMenu)\n         {\n'
                      '            super.hideAnimation();', self.menu)
        self.assertIn('!this._cmfShowDone && Boolean(GTweener.getTween(this,"alpha"))', self.menu)
        self.assertIn('this.cmfRevealPanels(param1);', self.menu)
        self.assertIn('this.cmfReveal(this.mcHubMapQuestTracker);', self.menu)
        self.assertIn('this.cmfApplyMotion();', self.menu)
        # A snap keeps the fade tweens when an opening key is set.
        self.assertEqual(self.hub.count('if(!this.cmfOpeningSet)'), 2)

    def test_zoom_out_fit(self):
        self.assertIn('_loc2_ = Math2.clamp(_loc2_,this.cmfMinZoom(),this._maxZoom);', self.hub)
        self.assertIn('return fit > 0 && fit < this._minZoom ? fit : this._minZoom;', self.hub)
        self.assertIn('this.mcHubMapZoomContainer.mcHubMapContainer.cmfGameMinZoom = param1;', self.hub)
        self.assertIn('var cmfEdge:Array = this.cmfEdgeLimit(cmfLimit);', self.container)
        self.assertEqual(self.container.count('var cmfEdge:Array = this.cmfEdgeLimit(cmfLimit);'), 2)
        self.assertIn('t = Math.min(1,(this.cmfGameMinZoom - z) / (this.cmfGameMinZoom - fit));', self.container)
        self.assertIn('if(z >= this.cmfGameMinZoom || fit <= 0 || fit >= this.cmfGameMinZoom)', self.container)

    def test_new_classes_are_listed(self):
        self.assertIn(WORLDMAP + 'UniverseMap.as', self.edits['classes'])
        self.assertIn('com/gskinner/motion/GTween.as', self.edits['classes'])


class GuideTests(unittest.TestCase):
    def test_guide_describes_the_keys_and_says_it_ran(self):
        guide = GUIDE.read_text(encoding='utf-8')
        section = guide[guide.index('### Smooth map movement (API version '):guide.index('## 6. Choosing pin types')]
        self.assertIn('Ran in game on 2026-10-20 through the Smooth Map', section)
        for key in NAVIGATION_NEW + OPENING + ['frameTimed', 'stepMs', 'worldStepMs', 'maxStepMs']:
            self.assertIn('`%s`' % key, section)
        self.assertIn('"unset"', section)
        self.assertIn('### Smooth map movement (API version 6)', section)


class SmoothCheckPackTests(unittest.TestCase):
    def test_pack_sends_smooth_maps_column_or_withdraws_it(self):
        data = SMOOTH_PACK.read_bytes()
        self.assertNotIn(b'\r', data)
        self.assertTrue(all(b < 128 for b in data))
        text = data.decode()
        sent = {(p, k): float(n) for p, k, n in
                re.findall(r"CMFTestSmoothKey\('(\w+)', '(\w+)', text, ([\d.]+)\);", text)}
        self.assertEqual(sent, SMOOTH_MAP)
        for part, key in sent:
            self.assertIn(key, cmf_pack.THEME_PART_KEYS[part])
        self.assertIn("GetVarValue('CMFTestSmooth', 'CMFTS_Enabled') == \"true\"", text)
        self.assertIn('text = "unset";', text)
        self.assertIn('CMFStylePart("modZZCMFTestSmooth", part, key, text, number);', text)
        self.assertGreater('modzzcmftestsmooth', 'modmapquestinsight')

    def test_menu_and_strings_use_the_developer_block(self):
        menu = SMOOTH_MENU.read_text(encoding='ascii')
        self.assertIn('<Group id="CMFTestSmooth" displayName="Mods.cmf_menu.cmftestsmooth">', menu)
        self.assertIn('<Var id="CMFTS_Enabled" value="false" displayName="cmfts_enabled" displayType="TOGGLE"/>', menu)
        catalog = json.loads(SMOOTH_STRINGS.read_text(encoding='utf-8'))
        keys = {s['key']: s['id'] for s in catalog['strings']}
        self.assertEqual(set(keys), {'panel_cmftestsmooth', 'option_cmfts_enabled'})
        self.assertTrue(all(2000209000 <= i <= 2000209999 for i in keys.values()))


if __name__ == '__main__':
    unittest.main()
