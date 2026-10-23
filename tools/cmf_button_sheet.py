"""Controller button pictures: the map file's button sheets as one picture per button (revision 9, CMF 1.3.0).

  python tools/cmf_button_sheet.py map MOVIE.xml [--out tools/cmf_button_sheets.json]
  python tools/cmf_button_sheet.py cut --i49 SHEET.png --i1 SHEET.png --pack modMyPack --out FOLDER
                                       [--family xbox ...] [--map tools/cmf_button_sheets.json]

The map file draws each controller button from cut-outs of two texture sheets: _i49 (988 x 544) and the lower
rows of _i1 (1024 x 1020). Every family clip (mcIconXbox, mcIconPS4, mcIconPS5, mcIconSteam, mcIconSwitch) has one
frame per button, labelled with the button's name, and the frame places the cut-outs around the clip's origin.

map reads the map movie as FFDec writes it (java -jar ffdec.jar -swf2xml <movie> MOVIE.xml) and records, per family
and button, which rectangle of which sheet each cut-out comes from and where it sits in the button's box. Geometry
only: the result holds no pixels, so it can be committed (tools/cmf_button_sheets.json).

cut takes two sheet PNGs laid out like the game's (your own art drawn over a copy of the layout) and writes one PNG
per button into FOLDER/art/buttons/, the size of the rectangle the game's cut-outs cover (64 x 64 for most; about
100 x 64 for the two-piece RTLT and RBLB pictures), rounded up to multiples of 4 and capped at 128, and
FOLDER/register.ws holding one CMFRegisterButtonPicture line per picture for the pack's start-up wrapper. Copy the
art/buttons folder into the pack's art/ folder and build the pack with tools/cmf_pack.py.
Needs only the Python standard library.
"""
import argparse
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import cmf_pack

MAP = TOOLS/'cmf_button_sheets.json'
# The family clip's instance name in the map file, by the family name CMFRegisterButtonPicture takes.
FAMILY_CLIPS = {'xbox': 'mcIconXbox', 'ps4': 'mcIconPS4', 'ps5': 'mcIconPS5', 'steam': 'mcIconSteam',
                'switch': 'mcIconSwitch'}
# Children of every frame that are not part of the picture: the hold ring (hidden until a button is held) and the
# click area.
SKIP = ('holdIndicator', 'viewrect')
BOX, CAP = 64, 128


# --- map: geometry from the FFDec XML ----------------------------------------------------

def _matrix(element):
    """(a, b, c, d, tx, ty) in pixels from an FFDec MATRIX element (translate is in twips)."""
    if element is None:
        return (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    scale = element.get('hasScale') == 'true'
    rotate = element.get('hasRotate') == 'true'
    return (float(element.get('scaleX', 1)) if scale else 1.0, float(element.get('rotateSkew0', 0)) if rotate else 0.0,
            float(element.get('rotateSkew1', 0)) if rotate else 0.0, float(element.get('scaleY', 1)) if scale else 1.0,
            int(element.get('translateX', 0)) / 20.0, int(element.get('translateY', 0)) / 20.0)


def _compose(outer, inner):
    """outer after inner."""
    a, b, c, d, tx, ty = outer
    e, f, g, h, ux, uy = inner
    return (a * e + c * f, b * e + d * f, a * g + c * h, b * g + d * h, a * ux + c * uy + tx, b * ux + d * uy + ty)


class Movie:
    def __init__(self, xml_text):
        root = ET.fromstring(xml_text)
        tags = root.find('tags')
        if tags is None:
            raise ValueError('not an FFDec -swf2xml file (no <tags>)')
        self.sheets, self.subimages, self.sprites, self.shapes, self.clips = {}, {}, {}, {}, {}
        for tag in tags:
            kind = tag.get('type', '')
            if kind == 'DefineExternalImage2':
                name = re.search(r'(_i\w+)\.dds$', tag.get('fileName', ''))
                if name:
                    self.sheets[tag.get('imageID')] = (name.group(1), int(tag.get('targetWidth')),
                                                       int(tag.get('targetHeight')))
            elif kind == 'DefineSubImage':
                self.subimages[tag.get('characterID')] = (tag.get('imageId'), int(tag.get('x1')), int(tag.get('y1')),
                                                          int(tag.get('x2')), int(tag.get('y2')))
            elif kind == 'DefineSpriteTag':
                self.sprites[tag.get('spriteId')] = tag
            elif kind.startswith('DefineShape'):
                self.shapes[tag.get('shapeId')] = tag
        for tag in root.iter('item'):
            if tag.get('type', '').startswith('PlaceObject') and tag.get('name') in FAMILY_CLIPS.values():
                self.clips.setdefault(tag.get('name'), tag.get('characterId'))

    def frames(self, sprite_id):
        """Yield (label, display list) for every labelled frame of a sprite; the list maps depth to
        (character id, matrix, instance name)."""
        shown, label = {}, None
        for tag in self.sprites[sprite_id].find('subTags'):
            kind = tag.get('type', '')
            if kind == 'FrameLabelTag':
                label = tag.get('name')
            elif kind.startswith('PlaceObject'):
                depth = int(tag.get('depth'))
                move = tag.get('placeFlagMove') == 'true'
                old = shown.get(depth) if move else None
                character = tag.get('characterId') if tag.get('placeFlagHasCharacter') == 'true' else (old or (None,))[0]
                matrix = _matrix(tag.find('matrix')) if tag.get('placeFlagHasMatrix') == 'true' else \
                    (old[1] if old else _matrix(None))
                name = tag.get('name') if tag.get('placeFlagHasName') == 'true' else (old[2] if old else None)
                shown[depth] = (character, matrix, name)
            elif kind in ('RemoveObject2Tag', 'RemoveObjectTag'):
                shown.pop(int(tag.get('depth')), None)
            elif kind == 'ShowFrameTag':
                if label is not None:
                    yield label, dict(shown)
                label = None

    def pieces(self, shown, outer=(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)):
        """The sheet cut-outs a display list draws, back to front."""
        out = []
        for depth in sorted(shown):
            character, matrix, name = shown[depth]
            if name in SKIP or character is None:
                continue
            matrix = _compose(outer, matrix)
            if character in self.subimages:
                out.append(self._piece(self.subimages[character], matrix))
            elif character in self.sprites:
                first = next(self.frames_unlabelled(character), {})
                out += self.pieces(first, matrix)
            elif character in self.shapes:
                for style in self.shapes[character].iter('item'):
                    bitmap = style.get('bitmapId')
                    if style.get('type') == 'FILLSTYLE' and bitmap in self.subimages:
                        fill = _matrix(style.find('bitmapMatrix'))
                        # A bitmap fill's matrix maps bitmap pixels to twips: 20 is one pixel.
                        fill = (fill[0] / 20, fill[1] / 20, fill[2] / 20, fill[3] / 20, fill[4], fill[5])
                        out.append(self._piece(self.subimages[bitmap], _compose(matrix, fill)))
        return out

    def frames_unlabelled(self, sprite_id):
        shown = {}
        for tag in self.sprites[sprite_id].find('subTags'):
            kind = tag.get('type', '')
            if kind.startswith('PlaceObject') and tag.get('placeFlagHasCharacter') == 'true':
                shown[int(tag.get('depth'))] = (tag.get('characterId'), _matrix(tag.find('matrix')), tag.get('name'))
            elif kind == 'ShowFrameTag':
                yield dict(shown)
                return

    def _piece(self, subimage, matrix):
        image, x1, y1, x2, y2 = subimage
        sheet = self.sheets[image][0]
        return {'sheet': sheet, 'x': x1, 'y': y1, 'w': x2 - x1, 'h': y2 - y1, 'm': [round(v, 5) for v in matrix]}

    def button_map(self):
        families = {}
        for family, clip in FAMILY_CLIPS.items():
            if clip not in self.clips:
                raise ValueError('the movie has no %s clip' % clip)
            buttons = {}
            for label, shown in self.frames(self.clips[clip]):
                pieces = self.pieces(shown)
                if pieces:
                    buttons[label] = pieces
            families[family] = buttons
        used = sorted(set(p['sheet'] for f in families.values() for b in f.values() for p in b))
        sheets = {name: [w, h] for name, w, h in self.sheets.values() if name in used}
        cutouts = len(set((p['sheet'], p['x'], p['y'], p['w'], p['h'])
                          for f in families.values() for b in f.values() for p in b))
        return {'schema': 'cmf-button-sheets-1',
                'about': 'Where each controller button picture of the 5.01 world map file '
                         '(gameplay/gui_new/swf/worldmap/panel_worldmap.redswf) comes from: per family and button, '
                         'the sheet rectangle (x, y, w, h) of each cut-out, back to front, and the matrix m '
                         '(a, b, c, d, tx, ty) that places its pixels in the button\'s box (x\' = a x + c y + tx, '
                         'y\' = b x + d y + ty, pixels from the box centre). Geometry only; no pixels.',
                'box': BOX, 'sheets': sheets, 'cutouts': cutouts, 'families': families}


def dump_map(result):
    """The map as JSON with one cut-out per line, so a diff shows which button changed."""
    head = {k: v for k, v in result.items() if k != 'families'}
    lines = ['{'] + [' %s: %s,' % (json.dumps(k), json.dumps(v)) for k, v in head.items()] + [' "families": {']
    for f_index, (family, buttons) in enumerate(result['families'].items()):
        lines.append('  %s: {' % json.dumps(family))
        for b_index, (button, pieces) in enumerate(buttons.items()):
            lines.append('   %s: [' % json.dumps(button))
            lines += ['    %s%s' % (json.dumps(piece), ',' if n < len(pieces) - 1 else '') for n, piece in enumerate(pieces)]
            lines.append('   ]%s' % (',' if b_index < len(buttons) - 1 else ''))
        lines.append('  }%s' % (',' if f_index < len(result['families']) - 1 else ''))
    return '\n'.join(lines + [' }', '}']) + '\n'


# --- cut: one picture per button ---------------------------------------------------------

def _corners(piece):
    a, b, c, d, tx, ty = piece['m']
    return [(a * x + c * y + tx, b * x + d * y + ty) for x in (0, piece['w']) for y in (0, piece['h'])]


def covered(pieces):
    """The rectangle (left, top, right, bottom) the game's cut-outs cover in the button's box: the panel draws a
    pack's picture stretched to exactly this rectangle."""
    corners = [corner for piece in pieces for corner in _corners(piece)]
    return (min(x for x, _ in corners), min(y for _, y in corners), max(x for x, _ in corners),
            max(y for _, y in corners))


def picture_size(pieces):
    """(width, height) of the cut picture: the covered rectangle rounded up to multiples of 4 (BC3), scaled down to
    fit the 128 x 128 cap."""
    left, top, right, bottom = covered(pieces)
    width, height = right - left, bottom - top
    scale = min(1.0, CAP / max(width, height))
    return tuple(max(4, int(-(-round(side * scale, 3) // 4) * 4)) for side in (width, height))


def cut_button(pieces, sheets):
    """(width, height, RGBA bytes) of one button: every cut-out drawn back to front (source over) with nearest
    pixels, filling the picture so that stretching it to the covered rectangle puts each pixel where the game
    draws it."""
    left, top, right, bottom = covered(pieces)
    width, height = picture_size(pieces)
    step_x, step_y = (right - left) / width, (bottom - top) / height
    canvas = bytearray(width * height * 4)
    for piece in pieces:
        sheet_width, sheet_height, rgba = sheets[piece['sheet']]
        if piece['x'] + piece['w'] > sheet_width or piece['y'] + piece['h'] > sheet_height:
            raise ValueError('sheet %s is %dx%d; the game\'s layout needs %dx%d at least'
                             % (piece['sheet'], sheet_width, sheet_height, piece['x'] + piece['w'],
                                piece['y'] + piece['h']))
        a, b, c, d, tx, ty = piece['m']
        det = a * d - b * c
        if abs(det) < 1e-9:
            continue
        for y in range(height):
            for x in range(width):
                # The output pixel's centre in the box, then back in the cut-out's own pixels.
                px, py = left + (x + 0.5) * step_x - tx, top + (y + 0.5) * step_y - ty
                u, v = (d * px - c * py) / det, (a * py - b * px) / det
                if not (0 <= u < piece['w'] and 0 <= v < piece['h']):
                    continue
                sx, sy = piece['x'] + int(u), piece['y'] + int(v)
                src = rgba[(sy * sheet_width + sx) * 4:(sy * sheet_width + sx) * 4 + 4]
                o = (y * width + x) * 4
                alpha = src[3]
                if alpha == 255 or canvas[o + 3] == 0:
                    canvas[o:o + 4] = src
                elif alpha:
                    under = canvas[o + 3] * (255 - alpha) // 255
                    total = alpha + under
                    for k in range(3):
                        canvas[o + k] = (src[k] * alpha + canvas[o + k] * under) // total
                    canvas[o + 3] = total
    return width, height, bytes(canvas)


def file_name(family, button):
    return '%s_%s.png' % (family, button.lower().replace('-', '_'))


def cut(button_map, sheet_files, pack, out, families=None):
    """Write out/art/buttons/<family>_<button>.png for every button of the families and out/register.ws; return the
    lines."""
    out = Path(out)
    if out.exists():
        raise ValueError('output folder already exists; give a new one')
    sheets = {}
    for name, path in sheet_files.items():
        width, height, rgba = cmf_pack.read_png(Path(path).read_bytes())
        expected = button_map['sheets'].get(name)
        if expected and [width, height] != expected:
            raise ValueError('%s is %dx%d; the game\'s sheet %s is %dx%d, and the cut-outs are read at its '
                             'places' % (path, width, height, name, expected[0], expected[1]))
        sheets[name] = (width, height, rgba)
    (out/'art/buttons').mkdir(parents=True)
    lines = []
    for family in families or list(button_map['families']):
        if family not in button_map['families']:
            raise ValueError('unknown family %r (%s)' % (family, ', '.join(button_map['families'])))
        for button, pieces in button_map['families'][family].items():
            missing = sorted(set(p['sheet'] for p in pieces) - set(sheets))
            if missing:
                raise ValueError('%s %s needs sheet %s' % (family, button, ', '.join(missing)))
            width, height, rgba = cut_button(pieces, sheets)
            name = file_name(family, button)
            (out/'art/buttons'/name).write_bytes(cmf_pack.write_png(width, height, rgba))
            lines.append('CMFRegisterButtonPicture("%s", \'%s\', "%s", "img://icons/%s/buttons/%s");'
                         % (pack, family, button, pack.lower(), name))
    (out/'register.ws').write_text('// Paste into your pack\'s OnGameStarted wrapper, behind CMFRequireVersion("%s", 9).\n'
                                   % pack + '\n'.join(lines) + '\n', encoding='ascii', newline='\n')
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest='command', required=True)
    mapped = sub.add_parser('map', help='record the button geometry from the map movie (FFDec -swf2xml output)')
    mapped.add_argument('xml')
    mapped.add_argument('--out', default=str(MAP))
    cutting = sub.add_parser('cut', help='cut two sheet PNGs into one PNG per button')
    cutting.add_argument('--i49', help='PNG laid out like the game\'s _i49 sheet (988 x 544)')
    cutting.add_argument('--i1', help='PNG laid out like the game\'s _i1 sheet (1024 x 1020)')
    cutting.add_argument('--pack', required=True, help='the pack folder name (the provider and the img:// folder)')
    cutting.add_argument('--out', required=True, help='new output folder')
    cutting.add_argument('--family', action='append', choices=sorted(FAMILY_CLIPS))
    cutting.add_argument('--map', default=str(MAP))
    args = parser.parse_args()
    if args.command == 'map':
        result = Movie(Path(args.xml).read_text(encoding='utf-8')).button_map()
        Path(args.out).write_text(dump_map(result), encoding='utf-8', newline='\n')
        print('%s: %d families, %d buttons, %d cut-outs' % (args.out, len(result['families']),
              sum(len(b) for b in result['families'].values()), result['cutouts']))
        return 0
    button_map = json.loads(Path(args.map).read_text(encoding='utf-8'))
    sheet_files = {name: path for name, path in (('_i49', args.i49), ('_i1', args.i1)) if path}
    lines = cut(button_map, sheet_files, args.pack, args.out, args.family)
    print('\n'.join(lines))
    print('\n%d pictures in %s and the lines in %s' % (len(lines), Path(args.out)/'art'/'buttons',
                                                      Path(args.out)/'register.ws'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
