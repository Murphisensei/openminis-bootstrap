#!/usr/bin/env python3
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "openminis-bootstrap",
    "openviking-memory",
    "remote-toolbox",
    "research-router",
    "investor-research",
    "pharma-research",
    "critical-review",
}


def fail(message: str) -> None:
    print(f"FAIL  {message}")
    raise SystemExit(1)


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    if not match:
        fail(f"invalid frontmatter: {path.relative_to(ROOT)}")
    values: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if not line.strip():
            continue
        key, separator, value = line.partition(":")
        if not separator:
            fail(f"invalid frontmatter line in {path.relative_to(ROOT)}")
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values, match.group(2)


def is_cjk(codepoint: int) -> bool:
    ranges = (
        (0x4E00, 0x9FFF), (0x3400, 0x4DBF), (0x20000, 0x2A6DF),
        (0x2A700, 0x2EBEF), (0x30000, 0x323AF), (0x3040, 0x309F),
        (0x30A0, 0x30FF), (0x31F0, 0x31FF), (0xAC00, 0xD7AF),
        (0x1100, 0x11FF), (0x3130, 0x318F), (0x3000, 0x303F),
        (0xFF00, 0xFFEF),
    )
    return any(start <= codepoint <= end for start, end in ranges)


def soul_token_count(body: str) -> int:
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


def main() -> None:
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    if set(manifest["managedSkills"]) != EXPECTED:
        fail("manifest skill set differs from validator")

    actual = {path.parent.name for path in (ROOT / "skills").glob("*/SKILL.md")}
    if actual != EXPECTED:
        fail(f"unexpected skill set: {sorted(actual ^ EXPECTED)}")

    for name in sorted(EXPECTED):
        path = ROOT / "skills" / name / "SKILL.md"
        frontmatter, _ = parse_frontmatter(path)
        if set(frontmatter) != {"name", "description"}:
            fail(f"frontmatter keys for {name} must be name and description only")
        if frontmatter["name"] != name:
            fail(f"skill name mismatch for {name}")
        if len(frontmatter["description"]) > 1024:
            fail(f"description too long for {name}")

    soul_meta, soul_body = parse_frontmatter(ROOT / "SOUL.md")
    if set(soul_meta) != {"name", "style", "lang"}:
        fail("SOUL frontmatter keys must be name, style, and lang")
    token_count = soul_token_count(soul_body.strip())
    if token_count > 2000:
        fail(f"SOUL exceeds OpenMinis limit: {token_count}/2000")

    for script in (ROOT / "skills").glob("*/scripts/*.sh"):
        subprocess.run(["sh", "-n", str(script)], check=True)

    # Build signatures from fragments so the scanner does not flag its own
    # source while still scanning every repository file, including this one.
    signatures = [
        "-----" + r"BEGIN [A-Z ]*PRIVATE KEY-----",
        "gh" + r"[pousr]_[A-Za-z0-9_]{20,}",
        "s" + r"k-[A-Za-z0-9_-]{20,}",
        "BW_" + r"SESSION=",
        "/home/ubuntu/" + r"\." + "openclaw",
        "tail" + r"[0-9a-f]{6}\.ts\.net",
    ]
    forbidden = re.compile("(" + "|".join(signatures) + ")", re.I)
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if forbidden.search(text):
            fail(f"possible private material in {path.relative_to(ROOT)}")

    print(f"PASS  {len(EXPECTED)} skills")
    print(f"PASS  SOUL token count {token_count}/2000")
    print("PASS  shell syntax")
    print("PASS  private-material scan")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        fail(f"shell syntax check failed: {error.cmd}")
    except (KeyError, json.JSONDecodeError) as error:
        fail(f"manifest error: {error}")
