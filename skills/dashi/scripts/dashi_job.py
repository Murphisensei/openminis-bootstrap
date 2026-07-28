#!/usr/bin/env python3
"""Poll or cancel one already-started OpenMinis Dashi MCP job."""

from __future__ import annotations

import argparse
import json
import subprocess
import time
from pathlib import Path
from typing import Any

DAEMON_FILES = (
    "/tmp/minis-mcp-daemon.lock",
    "/tmp/minis-mcp-daemon.pid",
    "/tmp/minis-mcp-daemon.port",
)


class WorkflowError(RuntimeError):
    pass


def emit(value: dict[str, Any]) -> None:
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))


def parse_output(output: str) -> dict[str, Any]:
    try:
        value = json.loads(output)
    except json.JSONDecodeError as exc:
        raise WorkflowError("minis-mcp-cli returned invalid JSON") from exc
    if not isinstance(value, dict):
        raise WorkflowError("minis-mcp-cli returned a non-object result")
    return value


def invoke(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, capture_output=True, text=True, timeout=310)


def mcp_call(tool: str, arguments: dict[str, Any]) -> dict[str, Any]:
    command = [
        "minis-mcp-cli",
        "call",
        "dashi",
        tool,
        "--input",
        json.dumps(arguments, ensure_ascii=False, separators=(",", ":")),
    ]
    try:
        result = invoke(command)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise WorkflowError(f"minis-mcp-cli could not complete: {type(exc).__name__}") from exc
    parsed = parse_output(result.stdout.strip()) if result.stdout.strip() else {}
    if result.returncode != 0 and parsed.get("code") == "NO_DAEMON":
        subprocess.run(
            ["minis-mcp-cli", "shutdown"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=15,
        )
        for value in DAEMON_FILES:
            Path(value).unlink(missing_ok=True)
        time.sleep(0.5)
        result = invoke(command)
        parsed = parse_output(result.stdout.strip()) if result.stdout.strip() else {}
    if result.returncode != 0:
        message = str(parsed.get("error") or result.stderr.strip() or "MCP call failed")[:500]
        raise WorkflowError(message)
    outer = parsed.get("result")
    if not isinstance(outer, dict) or outer.get("isError"):
        raise WorkflowError("Dashi MCP tool call failed")
    structured = outer.get("structuredContent")
    if isinstance(structured, dict):
        return structured
    for item in outer.get("content") or []:
        if not isinstance(item, dict) or item.get("type") != "text":
            continue
        try:
            value = json.loads(str(item.get("text") or ""))
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    raise WorkflowError("Dashi MCP returned no structured object")


def status(job_id: str, wait_seconds: int) -> dict[str, Any]:
    deadline = time.monotonic() + wait_seconds
    while True:
        result = mcp_call("job_status", {"job_id": job_id})
        state = str(result.get("status") or "unknown")
        if state in {"succeeded", "failed", "cancelled"} or time.monotonic() >= deadline:
            return result
        time.sleep(5)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    status_parser = sub.add_parser("status")
    status_parser.add_argument("job_id")
    status_parser.add_argument("--wait-seconds", type=int, choices=range(0, 241), default=0)
    cancel_parser = sub.add_parser("cancel")
    cancel_parser.add_argument("job_id")
    args = parser.parse_args()
    if args.command == "status":
        emit(status(args.job_id, args.wait_seconds))
    else:
        emit(mcp_call("cancel_job", {"job_id": args.job_id}))


if __name__ == "__main__":
    try:
        main()
    except (WorkflowError, ValueError, KeyError) as exc:
        emit({"error": str(exc)[:1000], "code": "WORKFLOW_ERROR"})
        raise SystemExit(1)
