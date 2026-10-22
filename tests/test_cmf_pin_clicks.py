"""Pin clicks (API version 6): ids 16, 20 and 21, the OnPinClicked hook, the map file's click edits and the
modZZCMFTestClick probe pack.

Static checks only; nothing here has run in game. The design is the pin click research
(2026-10-20, sections 4.1 to 4.5); the in-game check is its section 7 launch.
"""
from pathlib import Path
import json
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
PACK = ROOT/'source/providers/modZZCMFTestClick'
PACK_SCRIPT = PACK/'content/scripts/local/modzzcmftestclick_cmf.ws'
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack


def body(text, signature):
    # A class method (signature starting with a tab) ends at its own closing brace, a global function at column 0.
    start = text.index(signature)
    return text[start:text.index('\n\t}' if signature.startswith('\t') else '\n}', start)]


def parse_click(text):
    # Mirrors CMFParsePinClick and CMFPinClickText.
    words = [w for w in text.lower().replace(',', ' ').split(' ') if w]
    if not words or any(w not in ('use', 'doubleclick', 'button') for w in words):
        return None
    return ','.join(n for w, n in (('use', 'use'), ('doubleclick', 'doubleClick'), ('button', 'button')) if w in words)


def edits(cls):
    return json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/' + cls]


def replaced(cls):
    return ''.join(e['replace'] for e in edits(cls))


class ApiTests(unittest.TestCase):
    def test_version6_calls(self):
        core = CORE.read_text(encoding='ascii')
        for line in ('function CMFGetVersion() : int { return 8; }',
                     'function CMFPropertyPinClick() : int { return 16; }',
                     'function CMFPropertyPinClickHint() : int { return 20; }',
                     'function CMFPropertyPinClickButton() : int { return 21; }'):
            self.assertIn(line, core)
        self.assertIn('CMFIsClickProperty(propertyId);', body(core, 'function CMFHasProperty('))
        self.assertIn('!CMFIsClickProperty(propertyId)', body(core, 'function CMFRegisterForTag('))
        click = body(core, 'function CMFIsClickProperty(')
        for name in ('CMFPropertyPinClick()', 'CMFPropertyPinClickHint()', 'CMFPropertyPinClickButton()'):
            self.assertIn(name, click)
        # Earlier calls stay; ids 18 and 19 stay free for tooltip slots.
        for name in ('CMFStylePart', 'CMFPropertyLabelColor', 'CMFPropertyTabHide', 'CMFRegisterHidden'):
            self.assertIn('function %s(' % name, core)
        self.assertNotIn('return 18;', core)
        self.assertNotIn('return 19;', core)

    def test_inputs_are_checked_like_label_hide_words(self):
        core = CORE.read_text(encoding='ascii')
        parse = body(core, 'function CMFParsePinClick(')
        self.assertIn('rest = StrLower(StrReplaceAll(text, ",", " ")) + " ";', parse)
        self.assertEqual(re.findall(r'word == "(\w+)"', parse), ['use', 'doubleclick', 'button'])
        self.assertIn('return flags > 0;', parse)
        self.assertEqual(re.findall(r'text \+= "(\w+),";', body(core, 'function CMFPinClickText(')),
                         ['use', 'doubleClick', 'button'])
        self.assertEqual(parse_click('Button, use'), 'use,button')
        self.assertEqual(parse_click('doubleClick'), 'doubleClick')
        self.assertIsNone(parse_click('use click'))
        self.assertIsNone(parse_click(' , '))
        upsert = body(core, '\tpublic function Upsert(')
        self.assertIn('if (!CMFParsePinClick(incoming.text, flags))', upsert)
        self.assertIn('incoming.text = CMFPinClickText(flags);', upsert)


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_one_winner_per_pin_and_hints_follow_it(self):
        prepare = body(self.core, '\tpublic function Prepare()')
        block = prepare[prepare.index('if (CMFIsClickProperty(claims[i].propertyId))'):]
        block = block[:block.index('found = false;')]
        # A withdrawn claim leaves the pin to the next folder; hints and buttons are never arbitrated.
        self.assertLess(block.index('claims[i].number == 0'), block.index('winners.PushBack(claims[i]);'))
        self.assertIn('if (claims[i].propertyId != CMFPropertyPinClick())', block)
        self.assertEqual(prepare.count('ReportClickShadow('), 2)
        self.assertIn('NoteClick("click shadowed provider=" + loser + " by=" + winner);', self.core)
        write = body(self.core, '\tprivate function WriteClickFields(')
        self.assertIn('Find(CMFPropertyPinClick(), pinKey, pinTag, maxLevel, claim)', write)
        self.assertIn('Find(CMFPropertyPinClick(), legendKey, \'\', 1, claim)', write)
        self.assertIn('WriteClickText(dataObject, claim.provider,', write)
        text = body(self.core, '\tprivate function WriteClickText(')
        self.assertEqual(text.count('FindOwn('), 4)
        self.assertIn('winners[i].provider == provider', body(self.core, '\tprivate function FindOwn('))
        self.assertIn('WriteClickFields(dataObject, pinKey, legendKey, pinTag, maxLevel);',
                      body(self.core, '\tprivate function WriteFields('))

    def test_game_keeps_its_own_inputs(self):
        game = body(self.core, '\tprivate function GameClickInputs(')
        self.assertIn('!dataObject.GetMemberFlashBool("isFastTravel") && !dataObject.GetMemberFlashBool("isQuest")', game)
        self.assertIn('" reason=game"', game)
        self.assertIn('return CMFClickInputButton();', game)
        self.assertIn('dataObject.GetMemberFlashBool("isPlayer")', body(self.core, '\tprivate function WriteClickFields('))
        self.assertIn('NoteStyleRejected(provider, propertyId, "player");', body(self.core, '\tprivate function StyleClick('))

    def test_user_pins_get_clicks_on_every_pass(self):
        fill = body(self.core, '\tpublic function FillMissingPinFields(')
        user = fill[fill.index('if (dataObject && dataObject.GetMemberFlashBool("isUserPin") && '
                               '!dataObject.GetMemberFlashBool("isPlayer")'):]
        user = user[:user.index('// Every mod has added its pins')]
        # Outside the full-list test, so the one-pin update after placing a pin gets its button too.
        self.assertNotIn('fullList', user)
        self.assertIn('WriteClickFields(dataObject, dataObject.GetMemberFlashString("type"),', user)
        self.assertIn('dataObject.GetMemberFlashString("filteredType"), \'\', 1);', user)

    def test_per_pin_click_beats_tag_and_type(self):
        style = body(self.core, '\tpublic function StylePin(')
        self.assertLess(style.index('return StyleClick('), style.index('ownerField = CMFOwnerField(propertyId);'))
        click = body(self.core, '\tprivate function StyleClick(')
        # Version 8: the Pin clicks choice ranks two providers (PieceBeats with no choice set is ProviderBeats).
        self.assertIn('if (dataObject.GetMemberFlashBool("cmfClickPin") && PieceBeats(32, owner, provider))', click)
        self.assertIn('dataObject.SetMemberFlashBool("cmfClickPin", true);', click)
        self.assertIn('owner == CMFPinOwner(dataObject, "cmfClickBy")', click)
        self.assertIn('dataObject.GetMemberFlashBool("cmfClickPin")', body(self.core, '\tprivate function WriteClickFields('))

    def test_hook_event_and_literal_hint(self):
        self.assertIn('\tpublic function OnPinClicked(menu : CR4MapMenu, provider : string, pinTag : name, pinId : int, '
                      'pinType : string,\n\t\tinput : string, value : int) : bool\n\t{\n'
                      '\t\tCMFLog("click provider=" + provider + " pin=" + pinId + " reason=nohandler");\n'
                      '\t\treturn false;\n\t}', self.core)
        self.assertIn('@addMethod(CR4MapMenu)\nevent OnCMFPinClicked(pinTag : name, pinId : int, provider : string, '
                      'pinType : string, input : string, value : int)\n{\n'
                      '\ttheGame.CMFGetCore().PinClicked(this, pinTag, pinId, provider, pinType, input, value);\n}',
                      self.core)
        clicked = body(self.core, '\tpublic function PinClicked(')
        self.assertIn('CMFLog("click provider=" + provider + " input=" + input', clicked)
        self.assertIn('OnPinClicked(menu, provider, pinTag, pinId, pinType, input, value);', clicked)
        wrap = body(self.core, 'function OnAppendGFxButton(')
        self.assertIn('if (!StrBeginsWith(label, "cmf:"))', wrap)
        self.assertIn('return wrappedMethod(actionId, gamepadNavCode, keyboardKeyCode, label, holdPrefix, holdDuration);',
                      wrap)
        self.assertIn('binding.LocalizationKey = StrAfterFirst(label, "cmf:");', wrap)
        self.assertIn('binding.IsLocalized = true;', wrap)
        self.assertIn('@wrapMethod(CR4MenuBase)\nfunction OnAppendGFxButton(', self.core)
        # Names stay pin-specific, so a later drawing click can sit beside them.
        self.assertNotIn('OnCMFClicked', self.core)

    def test_pin_button_theme_part(self):
        self.assertIn(',pinButton', body(self.core, 'function CMFThemeParts('))
        keys = body(self.core, 'function CMFThemePartKeys(')
        self.assertIn("case 'pinButton':\n\t\t\treturn \"width,height,curve,fill,alpha,stroke,strokeWidth,offsetX,offsetY,\" "
                      "+ CMFThemeTextKeys();", keys)
        self.assertEqual(cmf_pack.THEME_PART_KEYS['pinButton'][:9],
                         ('width', 'height', 'curve', 'fill', 'alpha', 'stroke', 'strokeWidth', 'offsetX', 'offsetY'))


class PanelTests(unittest.TestCase):
    def test_pin_fields_declared(self):
        data = replaced('data/StaticMapPinData.as')
        for field in ('cmfClick:String', 'cmfClickBy:String', 'cmfClickValue:int', 'cmfClickHint:String',
                      'cmfClickHintBy:String', 'cmfClickButton:String', 'cmfClickButtonBy:String',
                      'cmfClickPin:Boolean', 'aqoomCachedPin:int', 'wmkIcon:String', 'aqoomRowLabel:String'):
            self.assertIn('public var %s' % field, data)
        core = CORE.read_text(encoding='ascii')
        for name in re.findall(r'SetMember\w+\("(cmfClick\w*)"', core):
            self.assertIn('public var %s:' % name, data)

    def test_inputs_dispatch_to_the_winner(self):
        hub = replaced('menus/worldmap/HubMap.as')
        # The id goes to the script's int as int(id): a uint above 2147483647 would not fit it (the tag keeps
        # the uint for the game's own pins, as its fast-travel event sends it). A panel note logs the click before it is sent.
        self.assertIn('var pinId:int = int(param1.id);', hub)
        self.assertIn('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFPanelNote",["click sent input=" + param2 + '
                      '" pin=" + pinId]));\n         dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFPinClicked",'
                      '[pinTag,pinId,param1.cmfClickBy,param1.type,param2,param1.cmfClickValue]));', hub)
        # A placed pin's id is no name: its tag goes as 0 (launch P6+C2 ended the game on the second placed-pin
        # click, between this event and the script's first line).
        self.assertIn('var pinTag:uint = Boolean(param1.isUserPin) ? 0 : param1.id;', hub)
        # E, Enter and A act on release, only after a press seen on the map.
        self.assertIn('if(_loc3_)\n               {\n                  this.cmfUseDown = true;', hub)
        self.assertIn('if(this.cmfUseDown)\n                  {\n                     this.cmfDispatchClick('
                      'this.cmfSelectedData(),"use");', hub)
        self.assertIn('if(this.cmfClickSelected("doubleClick"))\n         {\n            return;\n         }\n'
                      '         this.UseSelectedPin();', hub)
        # The tap on a user pin stays the game's remove; on another pin the winner of "use" takes it.
        self.assertIn('this.setUserMapPin(0,false);\n               }\n               else if(this.cmfClickSelected("use"))', hub)
        self.assertIn('return param2 == "button" || !param1.isFastTravel && !param1.isQuest;', hub)

    def test_hint_and_buttons(self):
        menu = replaced('menus/worldmap/MapMenu.as')
        self.assertIn('InputFeedbackManager.appendButton(this,NavigationCode.GAMEPAD_A,KeyCode.E,"cmf:" + '
                      'this.cmfClickHintText(event.mapppinData));', menu)
        self.assertIn('InputFeedbackManager.removeButton(this,this._cmfClickHint);', menu)
        self.assertIn('param1.cmfClickHintBy != param1.cmfClickBy', menu)
        self.assertIn('param1.cmfClickButtonBy != param1.cmfClickBy', menu)
        for event in ('MOUSE_DOWN,this.cmfPinButtonPress', 'MOUSE_UP,this.cmfPinButtonPress', 'CLICK,this.cmfPinButtonClick'):
            self.assertIn('button.addEventListener(MouseEvent.%s' % event, menu)
        # Two for pin clicks, two for drawing clicks (map-space drawing, tests/test_cmf_map_space.py).
        self.assertEqual(menu.count('param1.stopPropagation();'), 4)
        self.assertIn('this.mcHubMap.cmfDispatchClick(pin.data as StaticMapPinData,"button");', menu)
        # Every pinButton key the map reads is one the core accepts, and CMF's own look is not a mod's.
        read = set(re.findall(r'cmfNum\("pinButton","(\w+)"', menu))
        self.assertEqual(read, set(cmf_pack.THEME_PART_KEYS['pinButton'][:9]))
        for colour in (0xC8A55A, 0x1A1410, 0xE8D3A0):
            self.assertNotIn(',%d)' % colour, menu)

    def test_click_edits_are_appended(self):
        # The click edits of a class sit together after its version 5 edits, so the theme work keeps its finds.
        for cls in ('data/StaticMapPinData.as', 'menus/worldmap/HubMap.as', 'menus/worldmap/MapMenu.as'):
            names = [i for i, e in enumerate(edits(cls)) if 'cmfClick' in e['replace'] or 'aqoom' in e['replace'] or
                     'cmfUseDown' in e['replace'] or 'cmfPinButton' in e['replace']]
            self.assertEqual(names, list(range(names[0], names[-1] + 1)), cls)


class PackTests(unittest.TestCase):
    def test_probe_pack_loses_to_map_pin_teleport(self):
        data = PACK_SCRIPT.read_bytes()
        self.assertNotIn(b'\r', data)
        self.assertTrue(all(b < 128 for b in data))
        code = data.decode('ascii')
        self.assertIn('if (CMFHasProperty(16))\n\t{\n\t\tCMFRegister("modZZCMFTestClick", 16, \'User1\', \'\', "use", 1);',
                      code)
        self.assertLess('modMapPinTeleport'.lower(), 'modZZCMFTestClick'.lower())
        report, plan = cmf_pack.check_pack(PACK)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertEqual(list(PACK.rglob('*.ws')), [PACK_SCRIPT])

    def test_pack_tool_knows_clicks(self):
        def check(line):
            with tempfile.TemporaryDirectory() as root:
                source = Path(root)/'modAcmeClicks'
                (source/'content/scripts/local').mkdir(parents=True)
                (source/'README.txt').write_text('x\n', encoding='ascii')
                (source/'content/scripts/local/modacmeclicks_cmf.ws').write_text(
                    '@wrapMethod(CR4Game)\nfunction OnGameStarted(restored : bool)\n{\n\tvar result : bool;\n'
                    '\tresult = wrappedMethod(restored);\n' + line + '\treturn result;\n}\n', encoding='ascii')
                return cmf_pack.check_pack(source)[0]

        report = check('\tCMFRegister("modAcmeClicks", 16, \'User1\', \'\', "use, button", 7);\n'
                       '\tCMFRegister("modAcmeClicks", CMFPropertyPinClickButton(), \'User1\', \'\', "Go", 1);\n'
                       '\tCMFRegisterForTag("modAcmeClicks", 20, \'acme_well\', \'\', "Draw water", 1);\n')
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('only with CMF 6' in n for n in report.notes), report.notes)
        self.assertTrue(any('must name use, doubleClick or button' in e for e in
                            check('\tCMFRegister("modAcmeClicks", 16, \'User1\', \'\', "tap", 1);\n').errors))
        self.assertTrue(any('empty hint' in e for e in
                            check('\tCMFRegister("modAcmeClicks", 20, \'User1\', \'\', "", 1);\n').errors))
        self.assertIn('OnPinClicked', cmf_pack.HOOKS)


if __name__ == '__main__':
    unittest.main()
