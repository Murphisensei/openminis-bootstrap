#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "skills" / "openminis-bootstrap" / "scripts" / "mcp_job.py"
SPEC = importlib.util.spec_from_file_location("mcp_job", SCRIPT)
assert SPEC and SPEC.loader
mcp_job = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mcp_job)


class MCPJobTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "minis"
        (self.root / "attachments").mkdir(parents=True)
        self.env = mock.patch.dict(
            os.environ,
            {
                "OPENMINIS_ROOT": str(self.root),
                "IMAGE_MCP_URL": "https://image.example.invalid:10003/mcp",
                "IMAGE_MCP_TOKEN": "test-token-not-a-secret",
                "DOWNLOAD_MCP_URL": "https://download.example.invalid:10006/mcp",
                "DOWNLOAD_MCP_TOKEN": "test-token-not-a-secret",
                "PAPERLESS_MCP_URL": "https://paperless.example.invalid:10008/mcp",
                "PAPERLESS_MCP_TOKEN": "test-token-not-a-secret",
            },
            clear=False,
        )
        self.env.start()

    def tearDown(self) -> None:
        self.env.stop()
        self.temp.cleanup()

    def test_local_input_is_confined_to_openminis_roots(self) -> None:
        allowed = self.root / "attachments" / "source.png"
        allowed.write_bytes(b"image")
        self.assertEqual(mcp_job.local_input(str(allowed)), allowed)
        outside = Path(self.temp.name) / "outside.png"
        outside.write_bytes(b"image")
        with self.assertRaises(mcp_job.WorkflowError):
            mcp_job.local_input(str(outside))

    def test_transfer_url_must_match_service_endpoint(self) -> None:
        parsed, target = mcp_job.checked_transfer_url(
            "image",
            "https://image.example.invalid:10003/transfer/uploads/upload_1",
            "/transfer/uploads/",
        )
        self.assertEqual(parsed.hostname, "image.example.invalid")
        self.assertEqual(target, "/transfer/uploads/upload_1")
        with self.assertRaises(mcp_job.WorkflowError):
            mcp_job.checked_transfer_url(
                "image",
                "https://attacker.invalid/transfer/uploads/upload_1",
                "/transfer/uploads/",
            )
        with self.assertRaises(mcp_job.WorkflowError):
            mcp_job.checked_transfer_url(
                "image",
                "https://token@image.example.invalid:10003/transfer/uploads/upload_1",
                "/transfer/uploads/",
            )

    def test_mcp_call_extracts_structured_content(self) -> None:
        reply = {
            "server": "image",
            "tool": "health",
            "result": {"isError": False, "structuredContent": {"status": "ok"}},
        }
        with mock.patch.object(mcp_job, "run_cli", return_value=reply):
            self.assertEqual(mcp_job.mcp_call("image", "health", {}), {"status": "ok"})

    def test_direct_download_uses_workspace_destination(self) -> None:
        status = {
            "status": "succeeded",
            "output": {"mode": "direct"},
            "artifacts": [{"artifact_id": "artifact_1"}],
        }
        args = argparse.Namespace(service="download", job_id="job_1", wait_seconds=0)
        with (
            mock.patch.object(mcp_job, "mcp_call", return_value=status),
            mock.patch.object(mcp_job, "download_artifact", return_value={"url": "minis://workspace/x"}) as fetch,
        ):
            result = mcp_job.command_status(args)
        self.assertEqual(result["status"], "succeeded")
        fetch.assert_called_once_with("download", status["artifacts"][0], "job_1", "workspace")

    def test_paperless_prepare_uploads_original_and_extracted_text(self) -> None:
        document = self.root / "attachments" / "report.pdf"
        extracted = self.root / "attachments" / "report.md"
        document.write_bytes(b"%PDF-test")
        extracted.write_text("体检报告", encoding="utf-8")
        args = argparse.Namespace(
            command="paperless-prepare-start",
            file=str(document),
            text=str(extracted),
            title="",
            date="",
            document_type="",
            correspondent="",
            tags="",
            sensitivity="sensitive",
            source_message_id="",
        )
        with (
            mock.patch.object(mcp_job, "upload", side_effect=["upload_doc", "upload_text"]),
            mock.patch.object(
                mcp_job,
                "mcp_call",
                return_value={"job_id": "job_prepare", "status": "queued"},
            ) as call,
            mock.patch.object(mcp_job, "emit"),
            mock.patch.object(argparse.ArgumentParser, "parse_args", return_value=args),
        ):
            mcp_job.main()
        self.assertEqual(call.call_args.args[0:2], ("paperless", "start_archive_prepare"))
        self.assertEqual(call.call_args.args[2]["document_upload_id"], "upload_doc")
        self.assertEqual(call.call_args.args[2]["text_upload_id"], "upload_text")


if __name__ == "__main__":
    unittest.main()
