"""Offline estimate of the temporary characters the core copies while parsing one animation program.

Counts characters produced by string natives (StrBeforeFirst, StrAfterFirst, StrLeft/Right/Mid, string concatenation)
for the old walk (copy the remainder per token) and the new one (AnimationNextPiece windows). It is a model of the
shipped WitcherScript, not a timing: the game has no profiler here.
"""
import sys


def old_split(text, sep):
    """Characters copied by: rest = text + sep; while rest: token = before(rest); rest = after(rest)."""
    copied = len(text) + 1  # text + sep
    rest = text + sep
    pieces = []
    while rest:
        at = rest.find(sep)
        token = rest[:at] if at >= 0 else rest
        copied += len(token)
        rest = rest[at + 1:] if at >= 0 else ""
        copied += len(rest)
        pieces.append(token)
    return pieces, copied


def new_split(text, sep):
    """Characters copied by AnimationNextPiece: StrMid windows (64, doubling to 2048) plus the piece appends."""
    copied = 0
    pos = 0
    pieces = []
    length = len(text)
    while pos <= length:
        window, piece = 64, ""
        start = pos
        pos = None
        p = start
        while p < length:
            window = min(window, length - p)
            chunk = text[p:p + window]
            copied += len(chunk)
            at = chunk.find(sep)
            if at >= 0:
                piece += chunk[:at]
                copied += at
                pos = p + at + 1
                break
            piece += chunk
            copied += len(chunk)
            p += window
            window = min(window * 2, 2048)
        if pos is None:
            pos = length + 1
        pieces.append(piece)
    return pieces, copied


def old_trim(text):
    ws = " \t\n\v\f\r"
    copied = 0
    while text and text[0] in ws:
        text = text[1:]
        copied += len(text)
    while text and text[-1] in ws:
        text = text[:-1]
        copied += len(text)
    return text, copied


def new_trim(text):
    ws = " \t\n\v\f\r"
    start, finish = 0, len(text)
    while start < finish and text[start] in ws:
        start += 1
    while finish > start and text[finish - 1] in ws:
        finish -= 1
    return text[start:finish], (0 if start == 0 and finish == len(text) else finish - start)


def program(stages, frames, path="img://icons/pack/frame_%02d.png", fps=8):
    parts = ["program:v1", "delay=0"]
    for s in range(stages):
        paths = ",".join((path % f) for f in range(frames))
        parts.append("stage=s%d;frames=%s;fps=%d;plays=%s" % (s, paths, fps, "1" if s < stages - 1 else "forever"))
    return "|".join(parts)


def cost(text, split, trim):
    """Copied characters for the three split levels of one program, plus the final whole-text trim."""
    total = trim(text)[1]
    pieces, c = split(text, "|")
    total += c
    for piece in pieces[1:]:
        piece, t = trim(piece)
        total += t
        if not piece.startswith("stage="):
            continue
        parts, c = split(piece, ";")
        total += c
        for part in parts:
            part, t = trim(part)
            total += t
            if part.startswith("frames="):
                frames, c = split(part[7:], ",")
                total += c
                for frame in frames:
                    total += trim(frame)[1]
    return total


def canonical_count(text, split):
    return split(text, ",")[1]


def main():
    shapes = (("40 programs, ~3,400 chars", 3400), ("20 programs, ~6,800 chars", 6800))
    for name, size in shapes:
        frames = 16
        stages = 1
        while len(program(stages, frames)) < size and stages < 8:
            stages += 1
        text = program(stages, frames)
        old, new = cost(text, old_split, old_trim), cost(text, new_split, new_trim)
        print("%s: %d chars as built (%d stages x %d frames): old %d copied, new %d copied (x%.1f less)"
              % (name, len(text), stages, frames, old, new, old / max(new, 1)))
    pad = " " * 8000 + "img://a,img://b"
    print("8,000 padding spaces + 2 frames: old trim %d, new trim %d" % (old_trim(pad)[1], new_trim(pad)[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
