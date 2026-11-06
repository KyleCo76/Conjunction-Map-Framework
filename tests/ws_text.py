"""Shared text helpers for the source-reading tests (brace matched function bodies).

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE_PATH = ROOT / 'source/core/content/scripts/local/cmfCore.ws'


def core_text():
    return CORE_PATH.read_text(encoding='utf-8')


def ws_function(text, head):
    """Text of the function that starts with `head`, from the head to its closing brace."""
    start = text.index(head)
    brace = text.index('{', start)
    depth = 0
    for i in range(brace, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise AssertionError('unbalanced braces after ' + head)
