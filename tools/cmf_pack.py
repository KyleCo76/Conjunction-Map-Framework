"""CMF icon pack tool: check a pack source folder and build an installable pack.

A pack source folder is named exactly like the pack (that name is also its provider id):

  modMyIconPack/
    art/<name>.png                         one square PNG per image (optional for tint-only packs)
    content/scripts/local/<name>.ws        the start-up wrapper that calls CMFRegister...
    content/<lang>.w3strings               optional, only for a pack with its own menu
    bin/config/r4game/user_config_matrix/pc/<name>.xml   optional menu
    README.txt                             optional, copied as is

  check     report every problem, build nothing
  build     check, then write <out>/Mods/<pack>/... and <out>/pack-build.json (SHA-256 of every file)
  skeleton  print a starter script for the images in art/

Images are cooked into the pack's own content/texture.cache as single-mip BC3 with
tools/cmf_cooked_codec.py and tools/cmf_texture_cache.py, under the key
gameplay\\gui_new\\icons\\<pack lower case>\\<name>.png, which the map loads as
img://icons/<pack lower case>/<name>.png. Needs only the Python standard library.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import zlib

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import cmf_cooked_codec
import cmf_pin_types
import cmf_texture_cache as cache

API = {'CMFRegisterIcon', 'CMFRegisterLegendIcon', 'CMFRegisterTint', 'CMFRegisterIconForTag',
       'CMFRegisterBackground', 'CMFRegisterDisabled',
       'CMFRegisterDisabledForTag', 'CMFReleaseProvider', 'CMFRequireVersion', 'CMFGetVersion',
       'CMFRegister', 'CMFRegisterForTag', 'CMFHasProperty', 'CMFPropertyIcon', 'CMFPropertyLegendIcon',
       'CMFPropertyTint', 'CMFPropertyBackground', 'CMFPropertyDisabled',
       # Version 2: legend rows, filter tabs and per-pin styling.
       'CMFPropertyLegendRow', 'CMFPropertyLegendLabel', 'CMFPropertyLegendCategory', 'CMFRegisterLegendRow',
       'CMFRegisterLegendLabel', 'CMFRegisterLegendCategory', 'CMFStylePin', 'CMFStylePinIcon', 'CMFStylePinTint',
       # Version 3: hiding pins.
       'CMFPropertyHidden', 'CMFRegisterHidden', 'CMFRegisterHiddenForTag', 'CMFHidePin',
       # Version 4: pin size, labels, the info box height and per-tab hiding.
       'CMFPropertyPinScale', 'CMFPropertyLabelPlace', 'CMFPropertyLabelText', 'CMFPropertyLabelHide',
       'CMFPropertyInfoBoxHeight', 'CMFPropertyTabHide', 'CMFLabelHidePin', 'CMFLabelHideCrosshair',
       'CMFStylePinScale', 'CMFStylePinLabel', 'CMFLevelLabel',
       # Version 5: the map theme and the pin label colour.
       'CMFStylePart', 'CMFDraw', 'CMFDrawSet', 'CMFHasAbility', 'CMFPropertyLabelColor',
       # Version 6: pin clicks, the spread rank, keeping a tab's rows out of Default and map-space drawing.
       'CMFPropertyPinClick', 'CMFPropertyPinClickHint', 'CMFPropertyPinClickButton', 'CMFPropertySpreadRank',
       'CMFPropertyCategoryNoDefault', 'CMFRegisterCategoryNoDefault', 'CMFDrawSetList', 'CMFMapRefresh',
       # Version 8: the provider's name in CMF's in-game menu, and a changed player choice.
       'CMFSetProviderName', 'CMFChoicesChanged'}
# Categories the vanilla legend defines; a pack's own category id may not reuse one (CMF compares ignoring case).
VANILLA_CATEGORIES = ('All', 'Default', 'General', 'Quests', 'Exploration', 'NPCs', 'Buffs')
# Calls that need CMF 2; a pack using them should check CMFRequireVersion(pack, 2) or CMFHasProperty(8).
VERSION2 = {'CMFRegisterLegendRow', 'CMFRegisterLegendLabel', 'CMFRegisterLegendCategory', 'CMFStylePin',
            'CMFStylePinIcon', 'CMFStylePinTint'}
# Calls that need CMF 3; a pack using them should check CMFRequireVersion(pack, 3) or CMFHasProperty(9).
VERSION3 = {'CMFPropertyHidden', 'CMFRegisterHidden', 'CMFRegisterHiddenForTag', 'CMFHidePin'}
# Calls that need CMF 4; a pack using them should check CMFRequireVersion(pack, 4) or CMFHasProperty(15).
VERSION4 = {'CMFPropertyPinScale', 'CMFPropertyLabelPlace', 'CMFPropertyLabelText', 'CMFPropertyLabelHide',
            'CMFPropertyInfoBoxHeight', 'CMFPropertyTabHide', 'CMFLabelHidePin', 'CMFLabelHideCrosshair',
            'CMFStylePinScale', 'CMFStylePinLabel', 'CMFLevelLabel'}
# Calls that need CMF 5; a pack using them should check CMFRequireVersion(pack, 5).
VERSION5 = {'CMFStylePart', 'CMFDraw', 'CMFDrawSet', 'CMFHasAbility', 'CMFPropertyLabelColor'}
# Calls that need CMF 6 (pin clicks, the spread rank, a tab out of Default, map-space drawing); a pack using them
# should check CMFRequireVersion(pack, 6), and for the spread rank CMFHasProperty(22), for a tab out of Default
# CMFHasProperty(23), for map-space drawing CMFHasAbility('mapSpace', '').
VERSION6 = {'CMFPropertyPinClick', 'CMFPropertyPinClickHint', 'CMFPropertyPinClickButton', 'CMFPropertySpreadRank',
            'CMFPropertyCategoryNoDefault', 'CMFRegisterCategoryNoDefault', 'CMFDrawSetList', 'CMFMapRefresh'}
# Version 7 added theme keys only (the tall info box). Calls that need CMF 8 (players' choices); a pack using them
# should check CMFRequireVersion(pack, 8), and compiles only with CMF 8 or later.
VERSION7 = set()
VERSION8 = {'CMFSetProviderName', 'CMFChoicesChanged'}
# The map theme's fixed names and keys, as cmfCore.ws lists them (CMFThemeParts, CMFThemePartKeys and the rest;
# tests/test_cmf_pack.py keeps the two in step).
THEME_GLOW = ('glow1Color', 'glow1Alpha', 'glow1Blur', 'glow1Strength', 'glow2Color', 'glow2Alpha', 'glow2Blur',
              'glow2Strength')
THEME_SHADOW = ('shadowDistance', 'shadowAngle', 'shadowColor', 'shadowAlpha', 'shadowBlur', 'shadowStrength')
THEME_TEXT = ('font', 'size', 'color', 'spacing', 'align') + THEME_GLOW
THEME_PART_KEYS = {
    'screen': (),
    'map': ('top', 'bottom', 'panLimit', 'centerInLimit', 'backdrop'),
    'mapEdge': ('hide',),
    'title': THEME_TEXT + ('x', 'y', 'screenX', 'screenY', 'wrap', 'hide'),
    'tracker': THEME_GLOW + ('nameFont', 'nameSize', 'nameColor', 'hide'),
    'legend': THEME_GLOW,
    'legendRow': THEME_GLOW + ('color', 'colorSelected', 'colorOff', 'counterColor', 'hide'),
    'legendTab': THEME_GLOW + ('color', 'spacing', 'hide'),
    'tooltip': THEME_GLOW + ('titleFont', 'titleSize', 'titleColor', 'bodyFont', 'bodySize', 'bodyColor', 'hide',
                             'clearMinHeight', 'clearView', 'clearSide', 'clearCursor', 'clearLeft', 'clearTop',
                             'clearRight', 'clearBottom'),
    'preview': ('hide',),
    'worldButton': THEME_GLOW + ('hide',),
    'worldHint': THEME_GLOW + ('hide',),
    'hints': THEME_GLOW + ('x', 'y', 'scale', 'align'),
    'keyCap': THEME_GLOW + ('color', 'iconColor', 'brackets', 'keyGap', 'labelGap', 'hide'),
    'pinLabel': ('font', 'size', 'rise', 'riseTracked', 'riseOffset', 'riseOffsetTracked') + THEME_SHADOW,
    'pinName': ('font', 'size') + THEME_SHADOW,
    'navigation': ('frameTimed', 'stepMs', 'worldStepMs', 'maxStepMs', 'crosshairRoam', 'safeLeft', 'safeTop',
                   'safeRight', 'safeBottom', 'snapSeconds', 'centerSeconds', 'zoomTimed', 'padHoldMs',
                   'tweenEveryFrame', 'frameRate', 'zoomOutFit', 'edgeOvershoot'),
    'markerPanel': ('minLeft', 'maxRight', 'minTop', 'maxBottom'),
    'pinButton': ('width', 'height', 'curve', 'fill', 'alpha', 'stroke', 'strokeWidth', 'offsetX', 'offsetY') + THEME_TEXT,
    'mapSpace': (),
    'opening': ('slideSeconds', 'slideOffset', 'closeSeconds', 'pinsDuringSlide', 'pinStepMs', 'pinBatch',
                'pinBudgetMs', 'showDelayMs', 'fadeSeconds', 'tileFadeSeconds', 'revealSeconds'),
    'spread': ('on', 'anyPin', 'enterRadius', 'stackDistance', 'gap', 'maxPins', 'openMs', 'closeMs', 'lockRadius',
               'keepRadius'),
}
THEME_LAYERS = ('under', 'over', 'belowMap', 'aboveMap', 'top')
THEME_SHAPE_COMMON = ('left', 'top', 'right', 'bottom', 'width', 'height', 'widthShare', 'heightShare', 'minWidth',
                      'minHeight', 'alignX', 'alignY', 'offsetX', 'offsetY', 'minLeft', 'maxRight', 'minTop',
                      'maxBottom', 'screenLeft', 'screenRight', 'screenTop', 'screenBottom', 'measure', 'fill', 'alpha',
                      'fill2', 'alpha2', 'gradient', 'angle', 'curve', 'stroke', 'strokeAlpha', 'strokeWidth', 'layer',
                      'order', 'view', 'when', 'repeat', 'repeatStep', 'alphaList') + THEME_GLOW + THEME_SHADOW
# Version 6 (map-space drawing): drawing tabs, clicks and the hover look on the box kinds; the map-space kinds
# line and movie (mapSpace only) and text (mapSpace, placed at x, y metres, or any part or drawing).
THEME_HOVER = ('fillHover', 'alphaHover', 'strokeHover', 'strokeAlphaHover', 'strokeWidthHover', 'colorHover')
THEME_BOX = THEME_SHAPE_COMMON + ('tab', 'tabLabel', 'click', 'above') + THEME_HOVER + ('minPartHeight',)
THEME_SPACE = ('layer', 'order', 'alpha', 'view', 'area', 'preview', 'fadeMs', 'tab', 'tabLabel', 'listen',
               'listenFields')
THEME_KIND_KEYS = {'rect': THEME_BOX, 'ring': THEME_BOX + ('inset',), 'ellipse': THEME_BOX,
                   'polygon': THEME_BOX + ('points', 'originX', 'originY'),
                   'band': THEME_BOX + ('side', 'size', 'sizeZoom', 'minSize', 'maxShare'),
                   'line': THEME_SPACE + ('stroke', 'strokeAlpha', 'strokeWidth', 'strokeZoom'),
                   'text': THEME_BOX + ('text', 'font', 'size', 'color', 'align', 'wrap', 'padding', 'x', 'y',
                                        'sizeZoom', 'area', 'fadeMs', 'listen', 'listenFields'),
                   'movie': THEME_SPACE + ('src',)}
THEME_SHAPE_KEYS = set(k for keys in THEME_KIND_KEYS.values() for k in keys)
# CMFDrawSetList keys per kind (a movie takes any list key its author documents).
THEME_LIST_KEYS = {'line': ('xs', 'ys', 'starts', 'modes', 'colors')}
# Kinds the mapSpace anchor takes; line and movie take no other anchor.
THEME_SPACE_KINDS = ('line', 'text', 'movie')
# CMFStylePart("provider", 'part', 'key', ...), CMFDraw("provider", 'anchor', 'id', 'kind'),
# CMFDrawSet("provider", 'id', 'key', ...): literal names only; values are often computed.
THEME_PART = re.compile(r'\s*"([^"]*)"\s*,\s*\'([^\']*)\'\s*,\s*\'([^\']*)\'')
THEME_DRAW = re.compile(r'\s*"([^"]*)"\s*,\s*\'([^\']*)\'\s*,\s*\'([^\']*)\'\s*,\s*\'([^\']*)\'\s*\)')
# CMFCore methods a pack or adapter may wrap with @wrapMethod(CMFCore) (version 4 hooks, and OnPinClicked,
# OnDrawingClicked and OnMapListening from version 6).
HOOKS = ('OnPinReady', 'OnMapReady', 'OnPinClicked', 'OnDrawingClicked', 'OnMapListening')
HOOKS6 = ('OnPinClicked', 'OnDrawingClicked', 'OnMapListening')
# Input words a PinClick claim accepts (commas or spaces between them, case ignored).
CLICK_WORDS = ('use', 'doubleclick', 'button')
# Label words a LabelHide claim accepts (commas or spaces between them, case ignored).
LABEL_WORDS = ('pin', 'crosshair')
# Exemption words a hide claim accepts (commas or spaces between them, case ignored).
EXEMPTIONS = ('tracked', 'quest', 'fasttravel')
CLAIMS = {'CMFRegisterIcon': 'icon', 'CMFRegisterLegendIcon': 'legend', 'CMFRegisterTint': 'tint',
          'CMFRegisterIconForTag': 'tag icon'}
# Words that broke or are expected to break a WitcherScript compile when used as names.
RESERVED = {'entry', 'state', 'statemachine', 'latent', 'exec', 'quest', 'timer', 'saved', 'editable',
            'hint', 'cleanup', 'reward', 'storyscene', 'import', 'event', 'out', 'optional', 'default',
            'defaults', 'parent', 'super', 'this', 'in', 'new', 'delete', 'final', 'abstract'}
MIN_SIZE, MAX_SIZE, BEST_SIZE, MARGIN = 32, 128, 96, 4
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


class Report:
    def __init__(self):
        self.errors, self.warnings, self.notes = [], [], []

    def error(self, where, text):
        self.errors.append('%s: %s' % (where, text))

    def warn(self, where, text):
        self.warnings.append('%s: %s' % (where, text))

    def note(self, where, text):
        self.notes.append('%s: %s' % (where, text))

    def lines(self):
        return (['ERROR   ' + e for e in self.errors] + ['WARNING ' + w for w in self.warnings] +
                ['note    ' + n for n in self.notes])


# --- PNG ------------------------------------------------------------------------------

def read_png(data):
    """Decode a non-interlaced PNG to (width, height, straight RGBA8 bytes)."""
    if data[:8] != PNG_SIGNATURE:
        raise ValueError('not a PNG file')
    pos, chunks = 8, []
    while pos < len(data):
        if pos + 8 > len(data):
            raise ValueError('truncated PNG chunk')
        length, kind = struct.unpack_from('>I4s', data, pos)
        body = data[pos + 8:pos + 8 + length]
        if len(body) != length or zlib.crc32(kind + body) != struct.unpack_from('>I', data, pos + 8 + length)[0]:
            raise ValueError('damaged PNG chunk %r' % kind)
        chunks.append((kind, body))
        pos += 12 + length
        if kind == b'IEND':
            break
    if not chunks or chunks[0][0] != b'IHDR':
        raise ValueError('PNG has no header')
    width, height, depth, colour, _, _, interlace = struct.unpack('>IIBBBBB', chunks[0][1])
    if interlace:
        raise ValueError('interlaced PNG; save it without interlacing')
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(colour)
    if channels is None or depth not in ((1, 2, 4, 8) if colour == 3 else (8, 16) if colour else (1, 2, 4, 8, 16)):
        raise ValueError('unsupported PNG colour type %d at %d bits' % (colour, depth))
    palette = b''.join(body for kind, body in chunks if kind == b'PLTE')
    trns = b''.join(body for kind, body in chunks if kind == b'tRNS')
    raw = zlib.decompress(b''.join(body for kind, body in chunks if kind == b'IDAT'))
    bits = channels * depth
    stride, step = (width * bits + 7) // 8, max(1, bits // 8)
    rows, previous, pos = [], bytearray(stride), 0
    for _ in range(height):
        kind, line = raw[pos], bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        if len(line) != stride or kind > 4:
            raise ValueError('damaged PNG image data')
        for i in range(stride):
            a = line[i - step] if i >= step else 0
            b = previous[i]
            c = previous[i - step] if i >= step else 0
            if kind == 1:
                line[i] = (line[i] + a) & 255
            elif kind == 2:
                line[i] = (line[i] + b) & 255
            elif kind == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(line))
        previous = line
    out = bytearray()
    for line in rows:
        if depth < 8:
            mask = (1 << depth) - 1
            samples = [(line[(x * depth) // 8] >> (8 - depth - (x * depth) % 8)) & mask for x in range(width)]
        elif depth == 16:
            samples = list(line[0::2])
        else:
            samples = list(line)
        for x in range(width):
            px = samples[x * channels:(x + 1) * channels]
            if colour == 3:
                index = px[0]
                if 3 * index + 3 > len(palette):
                    raise ValueError('PNG palette index out of range')
                out += palette[3 * index:3 * index + 3] + bytes([trns[index] if index < len(trns) else 255])
            elif colour in (0, 4):
                grey = px[0] * 255 // ((1 << depth) - 1) if depth < 8 else px[0]
                out += bytes([grey, grey, grey, px[1] if colour == 4 else 255])
            else:
                out += bytes(px[:3]) + bytes([px[3] if colour == 6 else 255])
    return width, height, bytes(out)


def write_png(width, height, rgba):
    """Encode straight RGBA8 as a plain 8-bit RGBA PNG (used for CMF-drawn example art and tests)."""
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    rows = b''.join(b'\0' + rgba[y * width * 4:(y + 1) * width * 4] for y in range(height))
    return (PNG_SIGNATURE + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


# --- art checks --------------------------------------------------------------------------

def _expand565(value):
    return ((value >> 11 & 31) * 255 // 31, (value >> 5 & 63) * 255 // 63, (value & 31) * 255 // 31)


def bc3_colours(stream, width, height):
    """RGB of every texel the BC3 colour blocks decode to (alpha ignored), row major."""
    out = [None] * (width * height)
    block = 0
    for by in range(0, height, 4):
        for bx in range(0, width, 4):
            c0, c1, indices = struct.unpack_from('<HHI', stream, block * 16 + 8)
            p0, p1 = _expand565(c0), _expand565(c1)
            palette = (p0, p1, tuple((2 * p0[k] + p1[k]) // 3 for k in range(3)),
                       tuple((p0[k] + 2 * p1[k]) // 3 for k in range(3)))
            for n in range(16):
                out[(by + n // 4) * width + bx + n % 4] = palette[indices >> (2 * n) & 3]
            block += 1
    return out


def check_art(name, data, report):
    """Validate one PNG and return (width, height, BC3 stream) or None."""
    where = 'art/' + name
    if not re.fullmatch(r'[a-z0-9_]+\.png', name):
        report.error(where, 'file names must be lower-case letters, digits and _ only, ending in .png '
                            '(the name becomes the image key, and keys are lower case)')
        return None
    try:
        width, height, rgba = read_png(data)
    except (ValueError, zlib.error) as problem:
        report.error(where, 'cannot read PNG: %s' % problem)
        return None
    if width != height:
        report.error(where, 'image is %dx%d; it must be square' % (width, height))
        return None
    if width % 4 or width < MIN_SIZE or width > MAX_SIZE:
        report.error(where, 'image is %dx%d; use a multiple of 4 from %d to %d (%d recommended)'
                     % (width, height, MIN_SIZE, MAX_SIZE, BEST_SIZE))
        return None
    if width != BEST_SIZE:
        report.note(where, '%dx%d; %dx%d is recommended (it covers the selected pin at 4K)' % (width, width, BEST_SIZE, BEST_SIZE))
    alpha = rgba[3::4]
    if not any(alpha):
        report.warn(where, 'image is fully transparent')
    border = [alpha[y * width + x] for y in range(width) for x in range(width)
              if x < MARGIN or y < MARGIN or x >= width - MARGIN or y >= width - MARGIN]
    if any(border):
        report.warn(where, 'the outer %d pixels are not fully transparent; edges may bleed or be clipped' % MARGIN)
    stream = cmf_cooked_codec.encode_bc3(rgba, width, height)
    decoded = bc3_colours(stream, width, height)
    visible = [i for i in range(width * height) if alpha[i] >= 128]
    shifted = sum(1 for i in visible if max(abs(rgba[4 * i + k] - decoded[i][k]) for k in range(3)) > 40)
    if visible and shifted * 20 > len(visible):
        report.warn(where, '%d%% of visible pixels change colour noticeably when compressed; CMF\'s encoder suits '
                           'flat colours and outlines, not gradients or painted art' % (100 * shifted // len(visible)))
    return width, height, stream


# --- script checks -----------------------------------------------------------------------

def strip_comments(text):
    """Blank out // and /* */ comments, keeping string literals and line numbers."""
    out, i, n = [], 0, len(text)
    while i < n:
        if text[i] == '"':
            j = i + 1
            while j < n and text[j] not in '"\n':
                j += 2 if text[j] == '\\' else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif text.startswith('//', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i))
            i = j
        elif text.startswith('/*', i):
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r'[^\n]', ' ', text[i:j]))
            i = j
        else:
            out.append(text[i])
            i += 1
    return ''.join(out)


CALL = re.compile(r'\b(CMF\w*)\s*\(')
LITERAL_CLAIM = re.compile(r'\s*"([^"]*)"\s*,\s*\'([^\']*)\'\s*,\s*("([^"]*)"|0[xX][0-9A-Fa-f]+|-?\d+)\s*\)')
# CMFRegister / CMFRegisterForTag("provider", id, 'target', 'context', "text", number)
GENERIC_CLAIM = re.compile(r'\s*"([^"]*)"\s*,\s*(\d+|CMFProperty\w+\(\s*\))\s*,\s*\'([^\']*)\'\s*,\s*\'([^\']*)\'\s*,'
                           r'\s*"([^"]*)"\s*,\s*(0[xX][0-9A-Fa-f]+|-?\d+)\s*\)')
PROPERTY_IDS = {'CMFPropertyIcon': 1, 'CMFPropertyLegendIcon': 2, 'CMFPropertyTint': 3, 'CMFPropertyBackground': 4,
                'CMFPropertyDisabled': 5, 'CMFPropertyLegendRow': 6, 'CMFPropertyLegendLabel': 7,
                'CMFPropertyLegendCategory': 8, 'CMFPropertyHidden': 9, 'CMFPropertyPinScale': 10,
                'CMFPropertyLabelPlace': 11, 'CMFPropertyLabelText': 12, 'CMFPropertyLabelHide': 13,
                'CMFPropertyInfoBoxHeight': 14, 'CMFPropertyTabHide': 15, 'CMFPropertyLabelColor': 17,
                'CMFPropertyPinClick': 16, 'CMFPropertyPinClickHint': 20, 'CMFPropertyPinClickButton': 21,
                'CMFPropertySpreadRank': 22, 'CMFPropertyCategoryNoDefault': 23}
# Property ids this CMF accepts (18 and 19 are kept for tooltip slots).
KNOWN_PROPERTIES = set(range(1, 18)) | {20, 21, 22, 23}
GENERIC_KINDS = {1: 'icon', 2: 'legend', 3: 'tint'}
LITERAL_PROVIDER = re.compile(r'\s*"([^"]*)"\s*[,)]')
# CMFRegisterLegendRow("provider", 'filteredType', 'category', priority) and
# CMFRegisterLegendCategory("provider", 'category', "label", priority)
LEGEND_ROW = re.compile(r'\s*"([^"]*)"\s*,\s*\'([^\']*)\'\s*,\s*\'([^\']*)\'\s*,\s*(-?\d+)\s*\)')
LEGEND_TEXT = re.compile(r'\s*"([^"]*)"\s*,\s*\'([^\']*)\'\s*,\s*"([^"]*)"\s*[,)]')
# CMFRegisterHidden / CMFRegisterHiddenForTag("provider", 'target', 'context', "exemptions", hide)
HIDDEN_CLAIM = re.compile(r'\s*"([^"]*)"\s*,\s*\'([^\']*)\'\s*,\s*\'([^\']*)\'\s*,\s*"([^"]*)"\s*,\s*(true|false)\s*\)')


def exemption_issues(text_value):
    """Errors CMF's core would reject for a hide claim's exemption text."""
    words = [w for w in re.split(r'[\s,]+', text_value.lower()) if w]
    return ['unknown exemption "%s" (use %s); CMF rejects the claim' % (w, ', '.join(EXEMPTIONS))
            for w in words if w not in EXEMPTIONS]


def n4_issues(prop_id, text_value, number):
    """Errors CMF's core would reject for a version 4 to 6 claim (ids 10 to 17, 20 to 22); 0 withdraws ids 14, 16, 20, 21."""
    number = int(number, 16) if number.lower().startswith('0x') else int(number)
    if prop_id == 10 and not 25 <= number <= 400:
        return ['pin scale %d is outside 25 to 400 percent; CMF rejects the claim' % number]
    if prop_id == 11 and not 0 <= number <= 10000:
        return ['label place %d is outside 0 to 10000 tenths of a pin unit; CMF rejects the claim' % number]
    if prop_id == 12 and not text_value:
        return ['empty label text; CMF rejects the claim']
    if prop_id == 13:
        words = [w for w in re.split(r'[\s,]+', text_value.lower()) if w]
        if not words or any(w not in LABEL_WORDS for w in words):
            return ['label hide text "%s" must name pin, crosshair or both; CMF rejects the claim' % text_value]
    if prop_id == 14 and number != 0 and not 100 <= number <= 1080:
        return ['info box height %d is outside 100 to 1080 px (0 withdraws); CMF rejects the claim' % number]
    if prop_id == 15 and not text_value.strip(' ,'):
        return ['no filter tab named; CMF rejects the claim']
    if prop_id == 17 and not 0 <= number <= 0xFFFFFF:
        return ['label colour %d is not a colour 0xRRGGBB; CMF rejects the claim' % number]
    if prop_id == 16:
        words = [w for w in re.split(r'[\s,]+', text_value.lower()) if w]
        if not words or any(w not in CLICK_WORDS for w in words):
            return ['click inputs "%s" must name use, doubleClick or button; CMF rejects the claim' % text_value]
    if prop_id in (20, 21) and not text_value:
        return ['empty %s text; CMF rejects the claim' % ('hint' if prop_id == 20 else 'button')]
    if prop_id == 22 and not 0 <= number <= 1000:
        return ['spread rank %d is outside 0 to 1000; CMF rejects the claim' % number]
    return []


def legend_issues(prop_id, target, text_value):
    """Errors CMF's core would reject for a legend row (6), label (7), category (8) or out-of-Default (23) claim."""
    issues = []
    if not target:
        issues.append('empty %s; CMF rejects the claim' % ('category id' if prop_id in (8, 23) else 'filteredType'))
    if prop_id in (8, 23) and target.lower() in [c.lower() for c in VANILLA_CATEGORIES]:
        issues.append("'%s' is a vanilla legend category; declare your own id (prefix it with your pack name)"
                      % target)
    if prop_id in (7, 8) and not text_value:
        issues.append('empty %s; CMF rejects the claim' % ('label' if prop_id == 7 else 'tab name'))
    return issues


def check_script(path_label, text, pack, report, claims, calls, provider=None):
    # provider: the name every claim must use; the pack folder name, or for an adapter the adapted mod's
    # folder name, so folder order between mods is the same with CMF as without it.
    provider_name = provider or pack
    owner = 'the adapted mod\'s folder name' if provider else 'the pack folder name'
    if '\r' in text:
        report.error(path_label, 'use LF line endings, not CRLF')
    if any(ord(c) > 127 for c in text):
        report.error(path_label, 'scripts must be plain ASCII')
    code = strip_comments(text)
    line_of = lambda offset: code.count('\n', 0, offset) + 1
    for match in re.finditer(r'\bfunction\s+(CMF\w*)', code):
        report.error('%s:%d' % (path_label, line_of(match.start())), 'do not define functions starting with CMF '
                     '(%s); that prefix belongs to Conjunction Map Framework' % match.group(1))
    for match in re.finditer(r'\b(cmfIconPath|cmfLegendIconPath|cmfIconTint\w*|cmfIconBy|cmfTintBy|cmfLegend\w+|'
                             r'cmfCategory\w+|cmfRowHide|cmfHiddenBy|cmfIconScale|cmfLabelPlace|cmfLabelText|'
                             r'cmfLabelHide\w*|cmfLabelColor\w*|cmfTabHide\w*|cmfScaleBy|cmfPlaceBy|cmfLabelBy|cmfDescMax\w+|cmfTabName|'
                             r'cmfSpreadRank\w*)\b',
                             code):
        report.error('%s:%d' % (path_label, line_of(match.start())), 'do not write CMF pin fields (%s) yourself; '
                     'register through CMFRegister... or style one pin with CMFStylePin, so CMF can resolve packs '
                     'against each other' % match.group(1))
    styles = re.search(r'\b(CMFStylePin\w*|CMFHidePin)\s*\(', code)
    for match in re.finditer(r'@wrapMethod\(\s*CR4MapMenu\s*\)\s*function\s+AddPinTypeData', code):
        if not styles:
            report.warn('%s:%d' % (path_label, line_of(match.start())), 'a pack should not wrap '
                        'CR4MapMenu.AddPinTypeData except to style or hide single pins with CMFStylePin or '
                        'CMFHidePin; CMF already wraps it, and cannot see other changes made there')
    for match in re.finditer(r'\bvar\s+([\w\s,]+?)\s*:', code):
        for word in re.split(r'\s*,\s*', match.group(1).strip()):
            if word.lower() in RESERVED:
                report.error('%s:%d' % (path_label, line_of(match.start())), '"%s" is a reserved word in WitcherScript; '
                             'rename the variable' % word)
    defined = set(re.findall(r'\bfunction\s+(\w+)', code))
    # Movie drawings take their author's own keys and list keys (CMFDrawSet, CMFDrawSetList).
    movies = set(m.group(3) for m in re.finditer(r'\bCMFDraw\(' + THEME_DRAW.pattern, code) if m.group(4) == 'movie')
    for match in CALL.finditer(code):
        where = '%s:%d' % (path_label, line_of(match.start()))
        name = match.group(1)
        calls.add(name)
        if name in defined and name not in API:
            continue
        if name not in API:
            report.error(where, '%s is not a CMF function (the game will stop at the script compile screen)' % name)
            continue
        rest = code[match.end():]
        if name in CLAIMS:
            literal = LITERAL_CLAIM.match(rest)
            if not literal:
                report.warn(where, '%s uses non-literal arguments, so the pack tool cannot check it' % name)
                continue
            provider, target, value = literal.group(1), literal.group(2), literal.group(3)
            claims.append({'call': name, 'kind': CLAIMS[name], 'provider': provider, 'target': target,
                           'value': value, 'where': where})
        elif name in ('CMFRegister', 'CMFRegisterForTag'):
            literal = GENERIC_CLAIM.match(rest)
            if not literal:
                report.warn(where, '%s uses non-literal arguments, so the pack tool cannot check it' % name)
                continue
            provider, prop, target, context, text_value, number = literal.groups()
            prop_id = int(prop) if prop.isdigit() else PROPERTY_IDS.get(prop.split('(')[0].strip())
            if prop_id is None or prop_id not in KNOWN_PROPERTIES:
                report.warn(where, 'property %s is unknown to CMF 6; guard the call with CMFHasProperty' % prop)
                continue
            for issue in legend_issues(prop_id, target, text_value) if 6 <= prop_id <= 8 or prop_id == 23 else []:
                report.error(where, issue)
            for issue in exemption_issues(text_value) if prop_id == 9 else []:
                report.error(where, issue)
            for issue in n4_issues(prop_id, text_value, number) if prop_id >= 10 else []:
                report.error(where, issue)
            if prop_id == 14 and (target or name == 'CMFRegisterForTag'):
                report.error(where, 'the info box height applies to the whole map: use CMFRegister with target \'\'')
                continue
            if provider != provider_name:
                report.error(where, 'provider "%s" must be %s "%s", exactly' % (provider, owner, provider_name))
            if context and prop_id not in (5, 9):
                report.error(where, 'a map context applies only to CMFPropertyDisabled and CMFPropertyHidden; CMF '
                                    'rejects this claim')
            kind = GENERIC_KINDS.get(prop_id)
            if name == 'CMFRegisterForTag':
                if prop_id not in (1, 5, 9, 10, 11, 12, 13, 15, 16, 17, 20, 21):
                    report.error(where, 'CMFRegisterForTag accepts only CMFPropertyIcon, CMFPropertyDisabled, '
                                        'CMFPropertyHidden and ids 10 to 13, 15 to 17, 20 and 21')
                    continue
                if prop_id != 1 and not target:
                    report.error(where, 'empty pin tag; CMF rejects the claim')
                kind = 'tag icon' if prop_id == 1 else None
            if kind:
                value = number if kind == 'tint' else '"%s"' % text_value
                claims.append({'call': name, 'kind': kind, 'provider': provider, 'target': target,
                               'value': value, 'where': where})
        elif name in ('CMFRegisterLegendRow', 'CMFRegisterLegendLabel', 'CMFRegisterLegendCategory'):
            literal = (LEGEND_ROW if name == 'CMFRegisterLegendRow' else LEGEND_TEXT).match(rest)
            if not literal:
                report.warn(where, '%s uses non-literal arguments, so the pack tool cannot check it' % name)
                continue
            provider, target, text_value = literal.group(1), literal.group(2), literal.group(3)
            if provider != provider_name:
                report.error(where, 'provider "%s" must be %s "%s", exactly' % (provider, owner, provider_name))
            prop_id = {'CMFRegisterLegendRow': 6, 'CMFRegisterLegendLabel': 7, 'CMFRegisterLegendCategory': 8}[name]
            for issue in legend_issues(prop_id, target, text_value):
                report.error(where, issue)
        elif name in ('CMFRegisterHidden', 'CMFRegisterHiddenForTag'):
            literal = HIDDEN_CLAIM.match(rest)
            if not literal:
                report.warn(where, '%s uses non-literal arguments, so the pack tool cannot check it' % name)
                continue
            provider, target, context, text_value, _ = literal.groups()
            if provider != provider_name:
                report.error(where, 'provider "%s" must be %s "%s", exactly' % (provider, owner, provider_name))
            if name == 'CMFRegisterHiddenForTag' and not target:
                report.error(where, 'empty pin tag; CMF rejects the claim')
            for issue in exemption_issues(text_value):
                report.error(where, issue)
        elif name in ('CMFStylePart', 'CMFDrawSet'):
            literal = THEME_PART.match(rest)
            if not literal:
                continue
            provider, target, key = literal.groups()
            if provider != provider_name:
                report.error(where, 'provider "%s" must be %s "%s", exactly' % (provider, owner, provider_name))
            if name == 'CMFStylePart':
                if target not in THEME_PART_KEYS:
                    report.error(where, "'%s' is not a part of CMF's map (%s); CMF rejects the call"
                                 % (target, ', '.join(THEME_PART_KEYS)))
                elif key not in THEME_PART_KEYS[target]:
                    report.error(where, "part '%s' takes no key '%s' in CMF 7; CMF rejects the call (ask "
                                        "CMFHasAbility first for a key a later CMF adds)" % (target, key))
            elif key not in THEME_SHAPE_KEYS and target not in movies:
                report.error(where, "'%s' is not a drawing key in CMF 7; CMF rejects the call (a movie drawing "
                                    "takes its own keys after CMFDraw)" % key)
        elif name == 'CMFDrawSetList':
            literal = THEME_PART.match(rest)
            if not literal:
                continue
            provider, target, key = literal.groups()
            if provider != provider_name:
                report.error(where, 'provider "%s" must be %s "%s", exactly' % (provider, owner, provider_name))
            if key not in THEME_LIST_KEYS['line'] and target not in movies:
                report.error(where, "'%s' is not a list key (%s, or a movie drawing's own list key); CMF rejects the "
                                    "call" % (key, ', '.join(THEME_LIST_KEYS['line'])))
        elif name == 'CMFDraw':
            literal = THEME_DRAW.match(rest)
            if not literal:
                continue
            provider, anchor, draw_id, kind = literal.groups()
            if provider != provider_name:
                report.error(where, 'provider "%s" must be %s "%s", exactly' % (provider, owner, provider_name))
            if kind and kind not in THEME_KIND_KEYS:
                report.error(where, "'%s' is not a drawing kind (%s); CMF rejects the call"
                             % (kind, ', '.join(THEME_KIND_KEYS)))
            if draw_id in THEME_PART_KEYS or draw_id in THEME_LAYERS or draw_id in THEME_KIND_KEYS or not draw_id:
                report.error(where, "'%s' cannot be a drawing id: ids are your own names (prefix them with your "
                                    "mod's name)" % draw_id)
            if anchor in THEME_LAYERS or anchor in THEME_KIND_KEYS or anchor in ('navigation', 'opening', 'spread') or not anchor:
                report.error(where, "'%s' cannot be an anchor: use a part of the map or a drawing id" % anchor)
            elif anchor == 'mapSpace' and kind and kind not in THEME_SPACE_KINDS:
                report.error(where, "mapSpace takes only %s drawings; CMF rejects the call"
                             % ', '.join(THEME_SPACE_KINDS))
            elif anchor != 'mapSpace' and kind in ('line', 'movie'):
                report.error(where, "a %s drawing takes only the mapSpace anchor; CMF rejects the call" % kind)
        elif name in ('CMFStylePin', 'CMFStylePinIcon', 'CMFStylePinTint', 'CMFStylePinScale', 'CMFStylePinLabel',
                      'CMFHidePin', 'CMFReleaseProvider', 'CMFRequireVersion'):
            literal = LITERAL_PROVIDER.match(rest)
            if literal and literal.group(1) != provider_name:
                report.error(where, '%s names provider "%s"; it must be %s "%s"'
                             % (name, literal.group(1), owner, provider_name))
    needs2 = sorted(set(m.group(1) for m in CALL.finditer(code)) & VERSION2)
    if needs2:
        report.note(path_label, 'calls %s, so the pack compiles only with CMF 2 or later; say so in its README '
                                '(the generic CMFRegister ids 6 to 8 behind CMFHasProperty(8) still compile on CMF 1)'
                    % ', '.join(needs2))
    needs3 = sorted(set(m.group(1) for m in CALL.finditer(code)) & VERSION3)
    if needs3:
        report.note(path_label, 'calls %s, so the pack compiles only with CMF 3 or later; say so in its README '
                                '(the generic CMFRegister id 9 behind CMFHasProperty(9) still compiles on CMF 1)'
                    % ', '.join(needs3))
    needs4 = sorted(set(m.group(1) for m in CALL.finditer(code)) & VERSION4)
    for match in re.finditer(r'@wrapMethod\(\s*CMFCore\s*\)\s*function\s+(\w+)', code):
        if match.group(1) not in HOOKS:
            report.error('%s:%d' % (path_label, line_of(match.start())), 'wrap only the CMFCore hooks %s; other '
                         'CMFCore methods are not part of the API and may change' % ', '.join(HOOKS))
        elif match.group(1) not in HOOKS6:
            needs4 = sorted(set(needs4) | {'CMFCore.' + match.group(1)})
    if needs4:
        report.note(path_label, 'uses %s, so the pack compiles only with CMF 4 or later; say so in its README '
                                '(the generic CMFRegister ids 10 to 15 behind CMFHasProperty(15) still compile on CMF 1)'
                    % ', '.join(needs4))
    needs5 = sorted(set(m.group(1) for m in CALL.finditer(code)) & VERSION5)
    if needs5:
        report.note(path_label, 'calls %s, so the pack compiles only with CMF 5 or later; say so in its README '
                                '(the generic CMFRegister id 17 behind CMFHasProperty(17) still compiles on CMF 1)'
                    % ', '.join(needs5))
    needs6 = sorted(set(m.group(1) for m in CALL.finditer(code)) & VERSION6)
    for hook in HOOKS6:
        if re.search(r'@wrapMethod\(\s*CMFCore\s*\)\s*function\s+%s\s*\(' % hook, code):
            needs6 = sorted(set(needs6) | {'CMFCore.' + hook})
    if needs6:
        report.note(path_label, 'uses %s, so the pack compiles only with CMF 6 or later; say so in its README '
                                '(the generic CMFRegister ids 16, 20 and 21 behind CMFHasProperty(16) still compile on '
                                'CMF 1)' % ', '.join(needs6))
    needs8 = sorted(set(m.group(1) for m in CALL.finditer(code)) & VERSION8)
    if needs8:
        report.note(path_label, 'calls %s, so the pack compiles only with CMF 8 (1.2.0) or later; say so in its README'
                    % ', '.join(needs8))
    hooked = re.search(r'@wrapMethod\(\s*CMFCore\s*\)\s*function\s+(%s)\s*\(' % '|'.join(HOOKS), code)
    if (not re.search(r'@wrapMethod\(\s*CR4Game\s*\)\s*function\s+OnGameStarted\s*\(', code) and not hooked
            and CALL.search(code)):
        report.warn(path_label, 'no @wrapMethod(CR4Game) OnGameStarted wrapper found; packs register from that '
                                'wrapper so the calls run on every new game and loaded save')


def check_claims(pack, claims, images, report, types, provider=None, literal=()):
    owner = 'the adapted mod\'s folder name' if provider else 'the pack folder name'
    provider = provider or pack
    prefix = 'img://icons/%s/' % pack.lower()
    used, seen, first, quest_art = set(), {}, {}, {}
    for claim in claims:
        where, kind, target, value = claim['where'], claim['kind'], claim['target'], claim['value']
        if claim['provider'] != provider:
            report.error(where, 'provider "%s" must be %s "%s", exactly' % (claim['provider'], owner, provider))
        if not target:
            report.error(where, 'empty pin %s; CMF rejects the claim' % ('tag' if kind == 'tag icon' else 'type'))
        if kind == 'tint':
            if value.startswith('"'):
                report.error(where, 'the tint must be a number, not a string')
                continue
            if value.lower().startswith('0x'):
                report.error(where, 'write the tint in decimal (%d for %s); hexadecimal literals are untested in '
                                    'WitcherScript' % (int(value, 16), value))
                continue
            number = int(value)
            if not 0 <= number <= 0xFFFFFF:
                report.error(where, 'tint %d is outside 0 to 16777215 (0xFFFFFF)' % number)
            claim['rgb'] = '0x%06X' % (number & 0xFFFFFF)
        else:
            if not value.startswith('"'):
                report.error(where, 'the image must be a string such as "%sname.png"' % prefix)
                continue
            url = claim['url'] = claim['value'][1:-1]
            if not url:
                report.error(where, 'empty image path; CMF rejects the claim')
            elif url.startswith(prefix):
                image = url[len(prefix):]
                used.add(image)
                if image not in images:
                    report.error(where, '%s has no image in art/ (the map would silently keep the stock icon)' % url)
            elif url.startswith('img://'):
                report.warn(where, '%s is not in this pack\'s cache; it shows only if another installed cache '
                                   'holds that image' % url)
            else:
                report.error(where, 'image paths start with img:// (%s...)' % prefix)
        if kind != 'tag icon' and target:
            entry = types.get(target)
            if entry is None:
                close = [name for name in types if name.lower() == target.lower()]
                report.warn(where, "'%s' is not a 5.01 world map pin type%s (see docs/authors/pin-types.md)"
                            % (target, '; did you mean \'%s\'?' % close[0] if close else ''))
            elif entry['reach'] in ('base', 'no'):
                report.warn(where, "'%s' has no effect in CMF 1: %s" % (target, entry['note']))
            elif entry['reach'] == 'unknown':
                report.warn(where, "'%s' has a stock glyph but vanilla was not seen sending it to the map" % target)
            if target in cmf_pin_types.QUEST and kind in ('icon', 'legend'):
                quest_art.setdefault(kind, {})[target] = claim.get('url')
        slot = (kind, target)
        if slot in seen and seen[slot] != value:
            report.warn(where, 'the %s for %s was already set at %s; the last call wins' % (kind, target, first[slot]))
        seen[slot] = value
        first.setdefault(slot, where)
    legend = dict(quest_art.get('icon', {}), **quest_art.get('legend', {}))
    if len(set(legend.values())) > 1:
        report.warn('quest types', 'quest pins share one legend row, so %s get different legend images and the row '
                                   'shows whichever the map adds first; give them one legend image'
                    % ', '.join(sorted(legend)))
    for image in sorted(literal):
        if image not in images:
            report.error('script', '%s%s has no image in art/' % (prefix, image))
    for image in sorted(set(images) - used - set(literal)):
        report.warn('art/' + image, 'not used by any CMFRegister call in the script')


# --- pack ----------------------------------------------------------------------------------

def check_pack(source, adapts=None):
    """Check a pack source folder; return (report, plan) where plan lists the files a build writes.

    adapts: for an adapter, the folder name of the mod it adapts (for example modMapQuestInsight). Every
    claim must then name that folder as its provider, so the adapted mod keeps its place in folder order.
    """
    source = Path(source)
    pack, report = source.name, Report()
    if adapts is not None and not re.fullmatch(r'mod[A-Za-z0-9_]+', adapts):
        report.error(str(adapts), 'the adapted mod\'s folder name must start with "mod" and use only letters, '
                                  'digits and _')
    if not source.is_dir():
        report.error(str(source), 'not a folder')
        return report, None
    if not re.fullmatch(r'mod[A-Za-z0-9_]+', pack):
        report.error(pack, 'the folder name must start with "mod" and use only letters, digits and _')
    if pack.lower().startswith(('mod0000_', 'mod0001_')):
        report.error(pack, 'mod0000_ and mod0001_ are reserved for CMF and for Script Merger output')
    files = {}
    images, entries = {}, []
    art = source/'art'
    for path in sorted(art.iterdir()) if art.is_dir() else []:
        if path.is_file() and path.suffix.lower() == '.png':
            result = check_art(path.name, path.read_bytes(), report)
            if result:
                images[path.name] = result
        elif path.is_file():
            report.warn('art/' + path.name, 'ignored; only .png files are cooked')
    scripts = sorted(p for p in (source/'content').rglob('*.ws')) if (source/'content').is_dir() else []
    claims, calls, literal = [], set(), set()
    for path in scripts:
        label = path.relative_to(source).as_posix()
        if not label.startswith('content/scripts/local/'):
            report.error(label, 'scripts go in content/scripts/local/; anything else replaces a vanilla script')
        if not re.sub(r'^z+_', '', path.name.lower()).startswith(pack.lower()):
            report.warn(label, 'start the file name with the pack name (%s_cmf.ws) so it cannot collide with '
                               'another mod\'s script' % pack.lower())
        data = path.read_bytes()
        try:
            text = data.decode('ascii')
        except UnicodeDecodeError:
            report.error(label, 'scripts must be plain ASCII')
            text = data.decode('latin-1')
        check_script(label, text, pack, report, claims, calls, adapts)
        # An image named in any string literal counts as used, so art a script picks per pin (for example
        # through CMFStylePinIcon) is not reported as unused.
        literal |= set(re.findall(r'"img://icons/%s/([^"]+)"' % re.escape(pack.lower()), strip_comments(text)))
        files['content/' + path.relative_to(source/'content').as_posix()] = data
    if not scripts:
        report.error('content/scripts/local', 'no .ws script; the pack registers nothing without one')
    for path in sorted(p for p in source.rglob('*') if p.is_file()):
        label = path.relative_to(source).as_posix()
        if label.startswith(('art/', 'content/scripts/')) or label == 'README.txt':
            continue
        if re.fullmatch(r'content/[a-z]{2,4}\.w3strings', label) or \
                re.fullmatch(r'bin/config/r4game/user_config_matrix/pc/[^/]+\.xml', label):
            files[label] = path.read_bytes()
        else:
            report.error(label, 'not part of an icon pack; keep working files outside the pack folder (and never '
                                'ship your own texture.cache, a bundle, a map panel or CMF\'s own files)')
    if (source/'README.txt').is_file():
        files['README.txt'] = (source/'README.txt').read_bytes()
    else:
        report.warn('README.txt', 'missing; start from docs/authors/pack-readme-template.txt')
    check_claims(pack, claims, images, report, cmf_pin_types.known_types(), adapts, literal)
    if scripts and 'CMFRequireVersion' not in calls:
        report.note('script', 'consider guarding the calls with CMFRequireVersion("%s", 1)' % (adapts or pack))
    if images:
        entries = [('gameplay\\gui_new\\icons\\%s\\%s' % (pack.lower(), name), w, h, cache.frame_bc3(stream))
                   for name, (w, h, stream) in images.items()]
        try:
            data = cache.build_cache(entries)
            keys = [(e[0], e[1], e[2]) for e in cache.read_entries(data)]
            if keys != [(e[0], e[1], e[2]) for e in entries]:
                report.error('content/texture.cache', 'cache read-back mismatch')
            files['content/texture.cache'] = data
        except ValueError as problem:
            report.error('content/texture.cache', str(problem))
    plan = {'pack': pack, 'provider': adapts or pack, 'files': files, 'claims': claims,
            'images': {name: {'key': 'gameplay\\gui_new\\icons\\%s\\%s' % (pack.lower(), name),
                              'url': 'img://icons/%s/%s' % (pack.lower(), name), 'size': [w, h]}
                       for name, (w, h, _) in images.items()}}
    return report, plan


def build_pack(source, out, adapts=None):
    report, plan = check_pack(source, adapts)
    if report.errors:
        return report, None
    out = Path(out)
    if out.exists():
        report.error(str(out), 'output folder already exists; give a new one')
        return report, None
    root = 'Mods/%s/' % plan['pack']
    written = {}
    for name, data in sorted(plan['files'].items()):
        target = (out/name) if name.startswith('bin/') else (out/(root + name))
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        written[target.relative_to(out).as_posix()] = hashlib.sha256(data).hexdigest()
    manifest = {'schema': 'cmf-pack-build-1', 'pack': plan['pack'], 'provider': plan['provider'], 'files': written, 'images': plan['images'],
                'claims': [{'call': c['call'], 'target': c['target'], 'value': c.get('url', c.get('rgb', c['value']))}
                           for c in plan['claims']],
                'warnings': report.warnings}
    (out/'pack-build.json').write_text(json.dumps(manifest, indent=1) + '\n', encoding='utf-8', newline='\n')
    return report, manifest


def skeleton(source):
    """Starter script: one CMFRegisterIcon per art/<type>.png, one CMFRegisterLegendIcon per art/<type>_legend.png."""
    source = Path(source)
    pack = source.name
    types = {name.lower(): name for name, entry in cmf_pin_types.known_types().items() if entry['reach'] == 'yes'}
    lines = ['// %s for Conjunction Map Framework. Requires CMF 1 or later.' % pack, '',
             '@wrapMethod(CR4Game)', 'function OnGameStarted(restored : bool)', '{', '\tvar result : bool;',
             '\tresult = wrappedMethod(restored);', '\tif (CMFRequireVersion("%s", 1))' % pack, '\t{']
    for path in sorted((source/'art').glob('*.png')) if (source/'art').is_dir() else []:
        stem, url = path.stem, 'img://icons/%s/%s' % (pack.lower(), path.name)
        legend = stem.endswith('_legend')
        name = types.get((stem[:-len('_legend')] if legend else stem).replace('_', ''))
        call = 'CMFRegisterLegendIcon' if legend else 'CMFRegisterIcon'
        if name:
            lines.append('\t\t%s("%s", \'%s\', "%s");' % (call, pack, name, url))
        else:
            lines.append('\t\t// %s("%s", \'PinType\', "%s");' % (call, pack, url))
    lines += ['\t\t// CMFRegisterTint("%s", \'PinType\', 4259648);' % pack, '\t}', '\treturn result;', '}', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest='command', required=True)
    for name in ('check', 'build', 'skeleton'):
        command = sub.add_parser(name)
        command.add_argument('source', help='pack source folder, named exactly like the pack')
        if name == 'build':
            command.add_argument('--out', required=True, help='new output folder')
        if name in ('check', 'build'):
            command.add_argument('--adapts', metavar='MODFOLDER', help='for an adapter: the folder name of the '
                                 'mod it adapts, which every claim must use as its provider')
    args = parser.parse_args()
    if args.command == 'skeleton':
        sys.stdout.write(skeleton(args.source))
        return 0
    if args.command == 'check':
        report, plan = check_pack(args.source, args.adapts)
    else:
        report, plan = build_pack(args.source, args.out, args.adapts)
    for line in report.lines():
        print(line)
    if plan and plan.get('images'):
        print('\nImages and the URL to use in your script:')
        for name, image in sorted(plan['images'].items()):
            print('  art/%-24s %s' % (name, image['url']))
    if report.errors:
        print('\n%d error(s); nothing was built.' % len(report.errors) if args.command == 'build'
              else '\n%d error(s).' % len(report.errors))
        return 1
    if args.command == 'build':
        print('\nBuilt %s in %s (see pack-build.json). Copy its Mods folder into the game folder.'
              % (plan['pack'], args.out))
    else:
        print('\nNo errors (%d warning(s)).' % len(report.warnings))
    return 0


if __name__ == '__main__':
    sys.exit(main())
