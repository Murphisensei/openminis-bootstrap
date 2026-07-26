#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"


def main() -> None:
    DIST.mkdir(exist_ok=True)
    count = 0
    for skill_dir in sorted((ROOT / "skills").iterdir()):
        if not (skill_dir / "SKILL.md").is_file():
            continue
        destination = DIST / f"{skill_dir.name}.skill"
        with ZipFile(destination, "w", ZIP_DEFLATED) as archive:
            for path in sorted(skill_dir.rglob("*")):
                if path.is_file() and "__pycache__" not in path.parts:
                    archive.write(path, path.relative_to(skill_dir))
        print(f"Built {destination}")
        count += 1
    print(f"Packaged {count} skills")


if __name__ == "__main__":
    main()
