#!/usr/bin/env python3
"""Safe OpenMinis file bridge for the asynchronous common MCP services."""

from __future__ import annotations

import argparse
import hashlib
import http.client
import json
import mimetypes
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any
from urllib.parse import quote, urlsplit


SERVICES = {
    "meeting": ("meeting", "MEETING_MCP_URL", "MEETING_MCP_TOKEN", "workspace"),
    "image": ("image", "IMAGE_MCP_URL", "IMAGE_MCP_TOKEN", "attachments"),
    "video": ("video", "VIDEO_MCP_URL", "VIDEO_MCP_TOKEN", "attachments"),
    "pdf": ("pdfreader", "PDF_MCP_URL", "PDF_MCP_TOKEN", "workspace"),
    "paperless": ("paperless", "PAPERLESS_MCP_URL", "PAPERLESS_MCP_TOKEN", "attachments"),
    "download": ("download", "DOWNLOAD_MCP_URL", "DOWNLOAD_MCP_TOKEN", "attachments"),
}
DAEMON_FILES = (
    "/tmp/minis-mcp-daemon.lock",
    "/tmp/minis-mcp-daemon.pid",
    "/tmp/minis-mcp-daemon.port",
)


class WorkflowError(RuntimeError):
    pass


def emit(value: dict[str, Any]) -> None:
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))


def minis_root() -> Path:
    return Path(os.getenv("OPENMINIS_ROOT", "/var/minis")).resolve()


def allowed_roots() -> tuple[Path, ...]:
    root = minis_root()
    return tuple((root / name).resolve() for name in ("attachments", "workspace", "shared", "mounts"))


def local_input(value: str) -> Path:
    path = Path(value).expanduser().resolve(strict=True)
    if not path.is_file():
        raise WorkflowError("input is not a regular file")
    if not any(path == root or path.is_relative_to(root) for root in allowed_roots()):
        raise WorkflowError("input must be under /var/minis attachments, workspace, shared, or mounts")
    return path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def media_type(path: Path) -> str:
    guessed = mimetypes.guess_type(path.name)[0]
    return (guessed or "application/octet-stream").lower()


def service_config(service: str) -> tuple[str, str, str, str, str]:
    server, url_env, token_env, destination = SERVICES[service]
    endpoint = os.getenv(url_env, "").strip()
    token = os.getenv(token_env, "").strip()
    if not endpoint:
        raise WorkflowError(f"{url_env} is missing")
    if not token:
        raise WorkflowError(f"{token_env} is missing")
    parsed = urlsplit(endpoint)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise WorkflowError(f"{url_env} must be a credential-free HTTPS URL")
    if parsed.path.rstrip("/") != "/mcp":
        raise WorkflowError(f"{url_env} must end in /mcp")
    return server, endpoint, token, destination, token_env


def parse_json_output(output: str) -> dict[str, Any]:
    try:
        value = json.loads(output)
    except json.JSONDecodeError as exc:
        raise WorkflowError("minis-mcp-cli returned invalid JSON") from exc
    if not isinstance(value, dict):
        raise WorkflowError("minis-mcp-cli returned a non-object result")
    return value


def run_cli(command: list[str]) -> dict[str, Any]:
    def invoke() -> subprocess.CompletedProcess[str]:
        return subprocess.run(command, capture_output=True, text=True, timeout=310)

    try:
        result = invoke()
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise WorkflowError(f"minis-mcp-cli could not complete: {type(exc).__name__}") from exc
    parsed = parse_json_output(result.stdout.strip()) if result.stdout.strip() else {}
    if result.returncode != 0 and parsed.get("code") == "NO_DAEMON":
        subprocess.run(
            ["minis-mcp-cli", "shutdown"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=15,
        )
        for value in DAEMON_FILES:
            try:
                Path(value).unlink()
            except FileNotFoundError:
                pass
        time.sleep(0.5)
        result = invoke()
        parsed = parse_json_output(result.stdout.strip()) if result.stdout.strip() else {}
    if result.returncode != 0:
        message = str(parsed.get("error") or result.stderr.strip() or "MCP call failed")[:500]
        code = str(parsed.get("code") or "MCP_ERROR")
        raise WorkflowError(f"{code}: {message}")
    return parsed


def mcp_call(service: str, tool: str, arguments: dict[str, Any]) -> dict[str, Any]:
    server, _endpoint, _token, _destination, _token_env = service_config(service)
    outer = run_cli(
        [
            "minis-mcp-cli",
            "call",
            server,
            tool,
            "--input",
            json.dumps(arguments, ensure_ascii=False, separators=(",", ":")),
        ]
    )
    result = outer.get("result")
    if not isinstance(result, dict):
        raise WorkflowError("MCP call returned no result object")
    if result.get("isError"):
        content = result.get("content") or []
        message = "tool call failed"
        if content and isinstance(content[0], dict):
            message = str(content[0].get("text") or message)
        raise WorkflowError(message[:500])
    structured = result.get("structuredContent")
    if isinstance(structured, dict):
        return structured
    for item in result.get("content") or []:
        if isinstance(item, dict) and item.get("type") == "text":
            try:
                value = json.loads(str(item.get("text") or ""))
            except json.JSONDecodeError:
                continue
            if isinstance(value, dict):
                return value
    raise WorkflowError("MCP tool returned no structured object")


def checked_transfer_url(service: str, value: str, route: str) -> tuple[Any, str]:
    _server, endpoint, _token, _destination, _token_env = service_config(service)
    expected = urlsplit(endpoint)
    parsed = urlsplit(value)
    if (
        parsed.scheme != "https"
        or parsed.netloc != expected.netloc
        or parsed.username
        or parsed.password
        or not parsed.path.startswith(route)
        or parsed.fragment
    ):
        raise WorkflowError("MCP returned an unsafe transfer URL")
    request_target = parsed.path + (("?" + parsed.query) if parsed.query else "")
    return parsed, request_target


def connection(parsed: Any, timeout: int = 900) -> http.client.HTTPSConnection:
    return http.client.HTTPSConnection(parsed.hostname, parsed.port or 443, timeout=timeout)


def upload(service: str, path: Path, tool: str) -> str:
    size = path.stat().st_size
    slot = mcp_call(
        service,
        tool,
        {
            "filename": path.name,
            "media_type": media_type(path),
            "size_bytes": size,
            "sha256": sha256_file(path),
        },
    )
    upload_url = str(slot.get("upload_url") or "")
    upload_id = str(slot.get("upload_id") or "")
    if not upload_url or not upload_id:
        raise WorkflowError("MCP did not return an upload slot")
    parsed, target = checked_transfer_url(service, upload_url, "/transfer/uploads/")
    _server, _endpoint, token, _destination, _token_env = service_config(service)
    conn = connection(parsed)
    try:
        conn.putrequest("PUT", target)
        conn.putheader("Authorization", f"Bearer {token}")
        conn.putheader("Content-Type", media_type(path))
        conn.putheader("Content-Length", str(size))
        conn.endheaders()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                conn.send(chunk)
        response = conn.getresponse()
        body = response.read(4096)
        if response.status < 200 or response.status >= 300:
            raise WorkflowError(f"upload failed with HTTP {response.status}: {body[:200]!r}")
    finally:
        conn.close()
    return upload_id


def unique_destination(directory: Path, filename: str, sha256: str, job_id: str) -> Path:
    safe_name = Path(filename).name.replace("\x00", "").strip(" .") or "artifact.bin"
    destination = directory / safe_name
    if destination.is_file() and sha256_file(destination) == sha256:
        return destination
    if not destination.exists():
        return destination
    stem, suffix = destination.stem, destination.suffix
    candidate = directory / f"{stem}-{job_id[-8:]}{suffix}"
    index = 2
    while candidate.exists():
        candidate = directory / f"{stem}-{job_id[-8:]}-{index}{suffix}"
        index += 1
    return candidate


def download_artifact(
    service: str,
    artifact: dict[str, Any],
    job_id: str,
    destination_override: str = "",
) -> dict[str, Any]:
    _server, _endpoint, token, destination_kind, _token_env = service_config(service)
    if destination_override:
        destination_kind = destination_override
    expected_sha = str(artifact.get("sha256") or "").lower()
    if len(expected_sha) != 64:
        raise WorkflowError("artifact is missing a valid SHA-256")
    expected_size = int(artifact.get("size_bytes") or 0)
    if expected_size <= 0 or expected_size > 2 * 1024**3:
        raise WorkflowError("artifact size is invalid")
    parsed, target = checked_transfer_url(
        service,
        str(artifact.get("download_url") or ""),
        "/transfer/artifacts/",
    )
    destination_dir = minis_root() / destination_kind
    destination_dir.mkdir(parents=True, exist_ok=True)
    destination = unique_destination(
        destination_dir,
        str(artifact.get("filename") or "artifact.bin"),
        expected_sha,
        job_id,
    )
    if destination.is_file() and sha256_file(destination) == expected_sha:
        return local_artifact(destination, expected_sha)
    temporary_path: Path | None = None
    conn = connection(parsed)
    try:
        conn.request("GET", target, headers={"Authorization": f"Bearer {token}"})
        response = conn.getresponse()
        if response.status < 200 or response.status >= 300:
            body = response.read(4096)
            raise WorkflowError(f"artifact download failed with HTTP {response.status}: {body[:200]!r}")
        digest = hashlib.sha256()
        received = 0
        with tempfile.NamedTemporaryFile(dir=destination_dir, prefix=".mcp-artifact-", delete=False) as handle:
            temporary_path = Path(handle.name)
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                received += len(chunk)
                if received > expected_size:
                    raise WorkflowError("artifact exceeded its declared size")
                digest.update(chunk)
                handle.write(chunk)
        if received != expected_size or digest.hexdigest() != expected_sha:
            raise WorkflowError("artifact size or SHA-256 mismatch")
        os.replace(temporary_path, destination)
        temporary_path = None
    finally:
        conn.close()
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    return local_artifact(destination, expected_sha)


def local_artifact(path: Path, sha256: str) -> dict[str, Any]:
    relative = path.relative_to(minis_root()).as_posix()
    return {
        "filename": path.name,
        "path": str(path),
        "url": "minis://" + quote(relative, safe="/"),
        "sha256": sha256,
        "size_bytes": path.stat().st_size,
    }


def started(service: str, result: dict[str, Any]) -> dict[str, Any]:
    job_id = str(result.get("job_id") or "")
    if not job_id:
        raise WorkflowError("MCP did not return a job ID")
    return {
        "service": service,
        "job_id": job_id,
        "status": str(result.get("status") or "queued"),
        "next": f"python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status {service} {job_id}",
    }


def command_status(args: argparse.Namespace) -> dict[str, Any]:
    deadline = time.monotonic() + args.wait_seconds
    while True:
        result = mcp_call(args.service, "job_status", {"job_id": args.job_id})
        state = str(result.get("status") or "unknown")
        if state in {"succeeded", "failed", "cancelled"} or time.monotonic() >= deadline:
            break
        time.sleep(5)
    output: dict[str, Any] = {
        "service": args.service,
        "job_id": args.job_id,
        "status": state,
    }
    if state == "succeeded":
        output["output"] = result.get("output") or {}
        destination_override = ""
        if args.service == "download":
            mode = str((result.get("output") or {}).get("mode") or "")
            destination_override = "workspace" if mode == "direct" else "attachments"
        output["artifacts"] = [
            download_artifact(args.service, item, args.job_id, destination_override)
            for item in result.get("artifacts") or []
            if isinstance(item, dict)
        ]
    elif state == "failed":
        output["error"] = str(result.get("error") or "job failed")[:1000]
    else:
        output["next"] = (
            f"python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py "
            f"status {args.service} {args.job_id}"
        )
    return output


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    meeting = sub.add_parser("meeting-start")
    meeting.add_argument("file")
    meeting.add_argument("--speaker-count", type=int)
    meeting.add_argument("--languages", default="zh,en")
    meeting.add_argument("--no-diarize", action="store_true")

    meeting_search = sub.add_parser("meeting-search")
    meeting_search.add_argument("--query", default="")
    meeting_search.add_argument("--limit", type=int, choices=range(1, 101), default=20)

    meeting_read = sub.add_parser("meeting-read")
    meeting_read.add_argument("job_id")
    meeting_read.add_argument("--offset", type=int, default=0)
    meeting_read.add_argument(
        "--max-characters", type=int, choices=range(1, 20001), default=20000
    )

    image_gen = sub.add_parser("image-generate-start")
    image_gen.add_argument("--prompt", required=True)
    image_gen.add_argument("--size", choices=("1K", "2K", "4K"), default="2K")
    image_gen.add_argument("--count", type=int, choices=range(1, 5), default=1)
    image_gen.add_argument("--no-prompt-extend", action="store_true")
    image_gen.add_argument("--no-thinking", action="store_true")

    image_edit = sub.add_parser("image-edit-start")
    image_edit.add_argument("--file", action="append", required=True)
    image_edit.add_argument("--prompt", required=True)
    image_edit.add_argument("--size", choices=("1K", "2K"), default="2K")
    image_edit.add_argument("--count", type=int, choices=range(1, 5), default=1)
    image_edit.add_argument("--no-prompt-extend", action="store_true")

    video = sub.add_parser("video-start")
    video.add_argument("--prompt", required=True)
    video.add_argument("--duration", required=True, type=int, choices=range(2, 16))
    video.add_argument("--resolution", required=True, choices=("720P", "1080P"))
    video.add_argument("--ratio", required=True, choices=("16:9", "9:16", "1:1", "4:3", "3:4"))
    video.add_argument("--negative-prompt", default="")
    video.add_argument("--audio")
    video.add_argument("--no-prompt-extend", action="store_true")

    pdf = sub.add_parser("pdf-start")
    pdf.add_argument("file")
    pdf.add_argument("--mode", choices=("auto", "local", "ocr"), default="auto")

    paperless_prepare = sub.add_parser("paperless-prepare-start")
    paperless_prepare.add_argument("file")
    paperless_prepare.add_argument("--text")
    paperless_prepare.add_argument("--title", default="")
    paperless_prepare.add_argument("--date", default="")
    paperless_prepare.add_argument("--document-type", default="")
    paperless_prepare.add_argument("--correspondent", default="")
    paperless_prepare.add_argument("--tags", default="")
    paperless_prepare.add_argument(
        "--sensitivity",
        choices=("normal", "sensitive", "highly-sensitive"),
        default="sensitive",
    )
    paperless_prepare.add_argument("--source-message-id", default="")

    paperless_download = sub.add_parser("paperless-download-start")
    paperless_download.add_argument("document_id", type=int)
    paperless_download.add_argument(
        "--rendition", choices=("original", "archive"), default="original"
    )

    download = sub.add_parser("download-start")
    download.add_argument("url")
    download.add_argument("--mode", choices=("auto", "direct", "media", "audio"), default="auto")
    download.add_argument("--filename", default="")
    download.add_argument("--max-mb", type=int, choices=range(1, 2049), default=500)

    status = sub.add_parser("status")
    status.add_argument("service", choices=tuple(SERVICES))
    status.add_argument("job_id")
    status.add_argument("--wait-seconds", type=int, choices=range(0, 241), default=0)

    cancel = sub.add_parser("cancel")
    cancel.add_argument("service", choices=tuple(SERVICES))
    cancel.add_argument("job_id")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    if args.command == "meeting-start":
        path = local_input(args.file)
        upload_id = upload("meeting", path, "create_upload")
        result = mcp_call(
            "meeting",
            "start_transcription",
            {
                "upload_id": upload_id,
                "filename": path.name,
                "diarize": not args.no_diarize,
                "speaker_count": args.speaker_count,
                "language_hints": args.languages,
            },
        )
        emit(started("meeting", result))
    elif args.command == "meeting-search":
        emit(
            mcp_call(
                "meeting",
                "search_meetings",
                {"query": args.query, "limit": args.limit},
            )
        )
    elif args.command == "meeting-read":
        if args.offset < 0:
            raise WorkflowError("offset must be non-negative")
        emit(
            mcp_call(
                "meeting",
                "get_meeting_transcript",
                {
                    "job_id": args.job_id,
                    "offset": args.offset,
                    "max_characters": args.max_characters,
                },
            )
        )
    elif args.command == "image-generate-start":
        result = mcp_call(
            "image",
            "start_generation",
            {
                "prompt": args.prompt,
                "size": args.size,
                "n": args.count,
                "prompt_extend": not args.no_prompt_extend,
                "thinking_mode": not args.no_thinking,
            },
        )
        emit(started("image", result))
    elif args.command == "image-edit-start":
        paths = [local_input(value) for value in args.file]
        upload_ids = [upload("image", path, "create_upload") for path in paths]
        result = mcp_call(
            "image",
            "start_edit",
            {
                "upload_ids": upload_ids,
                "prompt": args.prompt,
                "size": args.size,
                "n": args.count,
                "prompt_extend": not args.no_prompt_extend,
            },
        )
        emit(started("image", result))
    elif args.command == "video-start":
        audio_upload_id = ""
        if args.audio:
            audio_upload_id = upload("video", local_input(args.audio), "create_audio_upload")
        result = mcp_call(
            "video",
            "start_generation",
            {
                "prompt": args.prompt,
                "duration": args.duration,
                "resolution": args.resolution,
                "ratio": args.ratio,
                "negative_prompt": args.negative_prompt,
                "prompt_extend": not args.no_prompt_extend,
                "audio_upload_id": audio_upload_id,
            },
        )
        emit(started("video", result))
    elif args.command == "pdf-start":
        path = local_input(args.file)
        upload_id = upload("pdf", path, "create_upload")
        result = mcp_call(
            "pdf",
            "start_read",
            {"upload_id": upload_id, "filename": path.name, "mode": args.mode},
        )
        emit(started("pdf", result))
    elif args.command == "paperless-prepare-start":
        path = local_input(args.file)
        document_upload_id = upload("paperless", path, "create_upload")
        text_upload_id = ""
        if args.text:
            text_upload_id = upload("paperless", local_input(args.text), "create_upload")
        result = mcp_call(
            "paperless",
            "start_archive_prepare",
            {
                "document_upload_id": document_upload_id,
                "text_upload_id": text_upload_id,
                "title": args.title,
                "date": args.date,
                "document_type": args.document_type,
                "correspondent": args.correspondent,
                "tags": args.tags,
                "sensitivity": args.sensitivity,
                "source_channel": "openminis",
                "source_message_id": args.source_message_id,
            },
        )
        emit(started("paperless", result))
    elif args.command == "paperless-download-start":
        if args.document_id <= 0:
            raise WorkflowError("document_id must be positive")
        result = mcp_call(
            "paperless",
            "start_document_download",
            {"document_id": args.document_id, "rendition": args.rendition},
        )
        emit(started("paperless", result))
    elif args.command == "download-start":
        result = mcp_call(
            "download",
            "start_download",
            {
                "url": args.url,
                "mode": args.mode,
                "filename": args.filename,
                "max_bytes": args.max_mb * 1024**2,
            },
        )
        emit(started("download", result))
    elif args.command == "status":
        emit(command_status(args))
    else:
        result = mcp_call(args.service, "cancel_job", {"job_id": args.job_id})
        emit({"service": args.service, **result})


if __name__ == "__main__":
    try:
        main()
    except (WorkflowError, ValueError, KeyError) as exc:
        emit({"error": str(exc)[:1000], "code": "WORKFLOW_ERROR"})
        raise SystemExit(1)
