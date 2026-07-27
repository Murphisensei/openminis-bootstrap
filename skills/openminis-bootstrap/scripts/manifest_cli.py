#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

NAME = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
ENV = re.compile(r"^[A-Z][A-Z0-9_]{0,95}$")
TOOL = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]{0,95}$")
MCP_KEYS = {
    "name",
    "skill",
    "urlEnv",
    "tokenEnv",
    "required",
    "note",
    "requiredTools",
}


def fail(message: str) -> None:
    raise SystemExit(f"manifest error: {message}")


def clean_text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{label} must be a non-empty string")
    text = value.strip()
    if any(character in text for character in ("\n", "\r", "\t", "\x00")):
        fail(f"{label} contains a control character")
    return text


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(str(exc))
    if not isinstance(data, dict):
        fail("root must be an object")
    managed = data.get("managedSkills")
    if not isinstance(managed, list) or not managed:
        fail("managedSkills must be a non-empty list")
    managed_names = [clean_text(value, "managed skill") for value in managed]
    if len(set(managed_names)) != len(managed_names) or any(
        not NAME.fullmatch(value) for value in managed_names
    ):
        fail("managedSkills contains a duplicate or invalid name")
    if "openminis-agent" not in managed_names:
        fail("managedSkills must include openminis-agent")

    servers = data.get("mcpServers")
    if not isinstance(servers, list) or not servers:
        fail("mcpServers must be a non-empty list")
    seen: set[str] = set()
    for index, server in enumerate(servers):
        label = f"mcpServers[{index}]"
        if not isinstance(server, dict) or set(server) != MCP_KEYS:
            fail(f"{label} must contain exactly {sorted(MCP_KEYS)}")
        name = clean_text(server["name"], f"{label}.name")
        skill = clean_text(server["skill"], f"{label}.skill")
        url_env = clean_text(server["urlEnv"], f"{label}.urlEnv")
        token_env = clean_text(server["tokenEnv"], f"{label}.tokenEnv")
        note = clean_text(server["note"], f"{label}.note")
        tools = server["requiredTools"]
        if not NAME.fullmatch(name) or name in seen:
            fail(f"{label}.name is invalid or duplicated")
        if not NAME.fullmatch(skill) or skill not in managed_names:
            fail(f"{label}.skill must reference a managed skill")
        if not ENV.fullmatch(url_env) or not ENV.fullmatch(token_env):
            fail(f"{label} has an invalid environment variable name")
        if not isinstance(server["required"], bool):
            fail(f"{label}.required must be boolean")
        if not isinstance(tools, list) or not tools:
            fail(f"{label}.requiredTools must be a non-empty list")
        tool_names = [clean_text(value, f"{label}.requiredTools") for value in tools]
        if len(set(tool_names)) != len(tool_names) or any(
            not TOOL.fullmatch(value) for value in tool_names
        ):
            fail(f"{label}.requiredTools contains a duplicate or invalid name")
        seen.add(name)
        server["name"] = name
        server["skill"] = skill
        server["urlEnv"] = url_env
        server["tokenEnv"] = token_env
        server["note"] = note
        server["requiredTools"] = tool_names
    return data


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "command",
        choices=("validate", "core-skills", "required-env", "mcp-tsv", "doctor-tsv"),
    )
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    manifest = load_manifest(args.manifest)

    if args.command == "validate":
        print("manifest valid")
    elif args.command == "core-skills":
        for skill in manifest["managedSkills"]:
            if skill != "openminis-agent":
                print(skill)
    elif args.command == "required-env":
        for server in manifest["mcpServers"]:
            if server["required"]:
                print(server["urlEnv"])
                print(server["tokenEnv"])
    elif args.command == "mcp-tsv":
        for server in manifest["mcpServers"]:
            print(
                "\t".join(
                    (
                        server["name"],
                        server["urlEnv"],
                        server["tokenEnv"],
                        "1" if server["required"] else "0",
                        server["note"],
                    )
                )
            )
    else:
        for server in manifest["mcpServers"]:
            print(
                "\t".join(
                    (
                        server["name"],
                        "1" if server["required"] else "0",
                        server["urlEnv"],
                        server["tokenEnv"],
                        ",".join(server["requiredTools"]),
                    )
                )
            )


if __name__ == "__main__":
    main()
