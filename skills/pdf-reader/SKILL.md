---
name: pdf-reader
description: Extract readable Markdown from a local digital or scanned PDF through the private PDF MCP, using local parsing first and current OCR when needed. Use when the user attaches a PDF, asks to read or summarize one, or needs grounded page content before analysis.
---

# PDF Reader

Use this Skill to turn an OpenMinis PDF into a local Markdown artifact before answering questions
about it. The default `auto` route extracts digital text locally and invokes OCR only for scanned or
complex pages.

## Workflow

1. Resolve the exact `.pdf` path under `/var/minis/attachments`, `/var/minis/workspace`,
   `/var/minis/shared`, or `/var/minis/mounts`.
2. Start extraction:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py pdf-start '/var/minis/attachments/document.pdf' --mode auto
```

   Use `--mode local` only when OCR must be avoided. Use `--mode ocr` when the user explicitly
   requires OCR or auto extraction visibly failed.
3. Poll the same job ID:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status pdf JOB_ID --wait-seconds 120
```

4. Read the resulting `minis://workspace/...` Markdown file, answer from that content, and distinguish
   source text from interpretation. State missing or unreadable pages instead of filling gaps.
5. After answering, ask whether the user wants the original PDF archived to Paperless. Do not upload
   it to Paperless before the user agrees. On agreement, use `$paperless` with the original PDF and
   extracted Markdown so metadata is inferred from content and the correct person tag is enforced.

The server accepts up to 500 pages for local extraction and up to 50 pages for OCR. For a larger
scanned document, ask the user to split or prioritize it. Do not send the PDF to Web Search or any
public URL unless the user explicitly requests publication.
