---
name: pdf-reader
description: Read PDF, Word, Excel, PowerPoint, text, CSV, HTML, and WeChat public-account articles through the private Document Reader MCP. Use for grounded document analysis, scanned-PDF OCR, spreadsheet range inspection, slide/notes extraction, or WeChat read-and-archive workflows.
---

# Document Reader

Use this Skill to convert an attached document or WeChat public-account article into a local,
grounded Markdown artifact before answering. It keeps the existing `pdfreader` MCP name, URL, and
token even though the service now handles more than PDF.

## Local files

Supported inputs are `.pdf`, `.docx`, `.xlsx`, `.pptx`, `.txt`, `.md`, `.csv`, `.html`, and `.htm`
under `/var/minis/attachments`, `/var/minis/workspace`, `/var/minis/shared`, or
`/var/minis/mounts`. Legacy Office and macro-bearing formats are intentionally rejected; the
service never executes Office macros.

Start a normal extraction:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py document-start \
  '/var/minis/attachments/document.docx'
```

For Excel, inspect only the sheets/ranges relevant to the question whenever possible:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py document-start \
  '/var/minis/attachments/model.xlsx' --sheet 'Forecast' --range 'A1:H200'
```

The default Excel ceiling is 500 rows × 50 columns per selected sheet. Raise it only when needed,
up to 5,000 × 200. Formulas and cached values are retained by default. PowerPoint extraction
includes speaker notes by default but flags image-only content that was not OCRed.

For PDF, `auto` first tries embedded text and uses the configured OCR model only when text is sparse:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py document-start \
  '/var/minis/attachments/document.pdf' --mode auto
```

Use `--mode local` when OCR must be avoided, and `--mode ocr` only for PDF when the user explicitly
requests OCR or auto visibly failed. The legacy `pdf-start` command remains available.

Poll the returned job ID:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status pdf JOB_ID --wait-seconds 120
```

Read the resulting `minis://workspace/...` Markdown file and answer from that content. Clearly
separate source text from interpretation, and surface extraction warnings rather than filling gaps.

After answering from a local file, ask whether the user wants the original archived to Paperless.
Do not upload before agreement. On agreement, use `$paperless` with the original file and extracted
Markdown; Paperless supplies automatic metadata and the trusted Freddy/Yurik person tag.

## WeChat public-account articles

For an `https://mp.weixin.qq.com/s/...` URL, use:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py wechat-read-start \
  'https://mp.weixin.qq.com/s/ARTICLE_ID'
```

Poll it as a `pdf` service job, read the returned Markdown artifact, and analyze it in the same
answer. Unlike formal documents, a WeChat article is automatically archived to the authenticated
person's Obsidian vault:

- Freddy token → `Freddy/Collection/`
- Yurik token → `Yurik/Collection/`

The archive contains source metadata, normalized article Markdown, and retrievable WeChat images.
If the job output says the archive is queued or retrying, analysis can still continue. Check the
durable archive separately with:

```sh
minis-mcp-cli call pdfreader wechat_archive_status --input '{"job_id":"JOB_ID"}'
```

Do not create a Paperless draft for a WeChat article unless the user explicitly asks for a second,
formal document archive.

## Limits and boundaries

- PDF: up to 500 pages locally; OCR up to 50 pages.
- Modern Office: up to 250 MiB with OOXML expansion and compression-ratio checks.
- Text/CSV/HTML: up to 32 MiB; normalized output is bounded to 4 million characters.
- WeChat URL fetching accepts only the official article host and approved image CDN hosts.
- Never send private attachments to Web Search or a public URL.

interface:
  display_name: "Document Reader"
  short_description: "Read PDF, Office, spreadsheets, slides, web articles, and WeChat"
  default_prompt: "Use $pdf-reader to read this document or WeChat article and return grounded results."
