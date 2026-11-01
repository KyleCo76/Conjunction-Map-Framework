"""Parse API 14 author animation text; no playback or internal-wire reader.

Refusal tokens and normalization match the shipped CMF core parser. Numeric
strings retain exact authored decimal precision rather than passing through floats.
"""
import re

_WHITESPACE = " \t\n\v\f\r"
_STAGE_KEYS = ("stage", "frames", "fps", "plays", "direction", "holdFirst", "holdLast", "offset", "delay")


def _trim(text):
    return text.strip(_WHITESPACE)


def _token(text):
    return not any(ord(c) < 32 or 127 <= ord(c) < 160 for c in text)


def _path(text):
    return (_token(text) and len(text) > 6 and text.startswith(("img://", "frame:"))
            and not any(c in text for c in ",;|="))


def _name(text):
    return re.fullmatch(r"[a-zA-Z0-9_-]+", text) is not None


def _number(text, maximum, integer, reason, positive=False):
    pattern = r"[+-]?[0-9]+" if integer else r"[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)"
    if not re.fullmatch(pattern, text):
        raise ValueError(reason)
    negative = text.startswith("-")
    text = text.lstrip("+-")
    whole, _, fraction = text.partition(".")
    whole = whole.lstrip("0") or "0"
    fraction = fraction.rstrip("0")
    if (negative and (whole != "0" or fraction) or len(whole) > 7
            or int(whole) > maximum or int(whole) == maximum and fraction):
        raise ValueError(reason)
    result = whole + ("." + fraction if fraction else "")
    if positive and result == "0":
        raise ValueError(reason)
    return result


def _frames(text):
    frames = tuple(_trim(path) for path in text.split(","))
    if not 2 <= len(frames) <= 16 or not all(_path(path) for path in frames):
        raise ValueError("frame paths")
    return ",".join(frames)


def _stage(text, fps):
    result = dict(stage="", frames="", fps=str(fps), plays="1", direction="forward",
                  holdFirst="0", holdLast="0", offset="0", delay="0")
    keys = set()
    for part in text.split(";"):
        part = _trim(part)
        if "=" not in part:
            raise ValueError("stage options")
        key, value = map(_trim, part.split("=", 1))
        if key in keys or key != "frames" and not _token(value):
            raise ValueError("stage options")
        keys.add(key)
        if key == "stage":
            if not _name(value):
                raise ValueError("stage options")
        elif key == "frames":
            value = _frames(value)
        elif key == "fps":
            value = _number(value, 30, True, "fps range", positive=True)
        elif key == "plays":
            if value != "forever":
                value = _number(value, 1000000, True, "plays range", positive=True)
        elif key == "direction":
            if value not in ("forward", "reverse", "pingpong"):
                raise ValueError("stage options")
        elif key in ("holdFirst", "holdLast", "delay"):
            value = _number(value, 3600, False, "time range")
        elif key == "offset":
            if value != "inherit":
                value = _number(value, 15, True, "offset range")
        else:
            raise ValueError("stage options")
        result[key] = value
    if result["plays"] == "forever" and "offset" not in keys:
        result["offset"] = "inherit"
    if not result["stage"] or not result["frames"]:
        raise ValueError("stage options")
    return result


def parse_animation(text: str, fps: int) -> dict:
    """Return canonical text, poster and normalized program fields, or ValueError.

    Stages contain the canonical named fields as strings, including comma-joined
    frames. Author text alone is accepted; cmfanim:v1 is an internal panel format.
    """
    if len(text) > 8192:
        raise ValueError("author length")
    if not isinstance(fps, int) or isinstance(fps, bool) or not 1 <= fps <= 30:
        raise ValueError("fps range")
    text = _trim(text)
    result = dict(delay="0", finish="restore", poster="", join="shared", repeat="1", repeatFrom="", stages=[])
    keys, names = set(), []
    if not text.startswith("program:v1|"):
        frames = _frames(text)
        result["stages"].append(dict(stage="loop", frames=frames, fps=str(fps), plays="forever",
            direction="forward", holdFirst="0", holdLast="0", offset="inherit", delay="0"))
        result["poster"] = frames.split(",")[0]
        names.append("loop")
    else:
        for part in text.split("|")[1:]:
            part = _trim(part)
            if "=" not in part:
                raise ValueError("program options")
            key, value = map(_trim, part.split("=", 1))
            if key == "stage":
                if len(names) >= 8:
                    raise ValueError("program options")
                stage = _stage(part, fps)
                if stage["stage"] in names:
                    raise ValueError("duplicate stage")
                if names and result["stages"][-1]["plays"] == "forever":
                    raise ValueError("unreachable stage")
                names.append(stage["stage"])
                result["stages"].append(stage)
                continue
            if key in keys or not _token(value):
                raise ValueError("program options")
            keys.add(key)
            if key == "delay":
                value = _number(value, 3600, False, "time range")
            elif key == "finish":
                if value not in ("restore", "hold"):
                    raise ValueError("program options")
            elif key == "poster":
                if value != "first" and not _path(value):
                    raise ValueError("poster path")
            elif key == "join":
                if value != "shared":
                    raise ValueError("program options")
            elif key == "repeat":
                if value != "forever":
                    value = _number(value, 1000000, True, "repeat range", positive=True)
            elif key == "repeatFrom":
                if not _name(value):
                    raise ValueError("program options")
            else:
                raise ValueError("program options")
            result[key] = value
        if result["poster"] in ("", "first") and names:
            result["poster"] = result["stages"][0]["frames"].split(",")[0]
    if not names:
        raise ValueError("stages required")
    if "repeat" in keys and result["stages"][-1]["plays"] == "forever":
        raise ValueError("clashing options")
    result["repeatFrom"] = result["repeatFrom"] or names[0]
    if result["repeatFrom"] not in names:
        raise ValueError("repeat stage")
    result["canonical"] = "cmfanim:v1|" + "|".join(key + "=" + result[key]
        for key in ("delay", "finish", "poster", "join", "repeat", "repeatFrom"))
    result["canonical"] += "".join("|" + ";".join(key + "=" + stage[key] for key in _STAGE_KEYS)
                                  for stage in result["stages"])
    return result


def animation_paths(program: dict) -> tuple[str, ...]:
    """Unique paths: poster first, then authored stages/frames; never reorder positions."""
    return tuple(dict.fromkeys([program["poster"]] + [path for stage in program["stages"]
        for path in stage["frames"].split(",")]))
