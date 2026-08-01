#!/usr/bin/env python3
"""Prepare a minis-config batch for an OpenMinis SOUL.md profile."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


BODY_TOKEN_LIMIT = 2000
ALLOWED_LANGUAGES = {"auto", "zh", "en"}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        fail(f"Unable to read SOUL profile: {error}")

    match = re.fullmatch(r"---\n(.*?)\n---\n\n?(.*)", text, re.S)
    if not match:
        fail("SOUL profile must contain YAML frontmatter and a Markdown body")

    metadata: dict[str, str] = {}
    for raw_line in match.group(1).splitlines():
        key, separator, raw_value = raw_line.partition(":")
        if not separator:
            fail("Invalid SOUL frontmatter line")
        key = key.strip()
        raw_value = raw_value.strip()
        try:
            value = json.loads(raw_value) if raw_value.startswith('"') else raw_value
        except json.JSONDecodeError as error:
            fail(f"Invalid SOUL frontmatter value for {key}: {error}")
        if not isinstance(value, str):
            fail(f"SOUL frontmatter value for {key} must be a string")
        metadata[key] = value

    if set(metadata) != {"name", "style", "lang"}:
        fail("SOUL frontmatter must contain exactly name, style, and lang")
    if not metadata["name"].strip():
        fail("SOUL name must not be empty")
    if metadata["lang"] not in ALLOWED_LANGUAGES:
        fail("SOUL lang must be auto, zh, or en")
    return metadata, match.group(2)


def is_cjk(codepoint: int) -> bool:
    ranges = (
        (0x4E00, 0x9FFF),
        (0x3400, 0x4DBF),
        (0x20000, 0x2A6DF),
        (0x2A700, 0x2EBEF),
        (0x30000, 0x323AF),
        (0x3040, 0x309F),
        (0x30A0, 0x30FF),
        (0x31F0, 0x31FF),
        (0xAC00, 0xD7AF),
        (0x1100, 0x11FF),
        (0x3130, 0x318F),
        (0x3000, 0x303F),
        (0xFF00, 0xFFEF),
    )
    return any(start <= codepoint <= end for start, end in ranges)


def token_count(body: str) -> int:
    count = 0
    in_word = False
    for character in body:
        if is_cjk(ord(character)):
            if in_word:
                count += 1
                in_word = False
            count += 1
        elif character.isspace():
            if in_word:
                count += 1
                in_word = False
        else:
            in_word = True
    return count + int(in_word)


def prepare_batch(source: Path, destination: Path) -> None:
    metadata, body = parse_frontmatter(source)
    observed_tokens = token_count(body.strip())
    if observed_tokens > BODY_TOKEN_LIMIT:
        fail(
            f"SOUL body exceeds the OpenMinis limit: "
            f"{observed_tokens}/{BODY_TOKEN_LIMIT} tokens"
        )

    values = (
        ("soul.name", metadata["name"]),
        ("soul.style", metadata["style"]),
        ("soul.lang", metadata["lang"]),
        ("soul.body", body),
    )
    batch = [
        {
            "path": path,
            "value_json": json.dumps(value, ensure_ascii=False),
        }
        for path, value in values
    ]
    destination.write_text(
        json.dumps(batch, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def main() -> None:
    if len(sys.argv) != 4 or sys.argv[1] != "prepare-batch":
        fail("usage: soul_cli.py prepare-batch SOURCE_SOUL OUTPUT_JSON")
    prepare_batch(Path(sys.argv[2]), Path(sys.argv[3]))


if __name__ == "__main__":
    main()
