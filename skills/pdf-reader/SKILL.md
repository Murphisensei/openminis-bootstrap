---
name: pdf-reader
description: Read and critically analyze attached PDF, Word, Excel, PowerPoint, text, CSV, and HTML files through the private Document Reader MCP. Use for grounded document analysis, scanned-PDF OCR, spreadsheet range inspection, or slide and speaker-note extraction. Route mp.weixin.qq.com URLs to the dedicated wechat-article Skill.
---

# Document Reader

Use this Skill to convert an attached document into a local, grounded Markdown artifact before
answering. It keeps the existing `pdfreader` MCP name, URL, and token even though the service now
handles more than PDF. The dedicated `$wechat-article` Skill is the mandatory router for WeChat
public-account URLs and uses this same MCP.

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

Do not handle a WeChat article inside this general document Skill. Any `mp.weixin.qq.com` URL,
微信公众号文章, or 公众号链接 must switch to `$wechat-article`, whose source-readiness gate requires
the private `pdfreader.start_wechat_read` MCP workflow before any article summary or analysis.

## Limits and boundaries

- PDF: up to 500 pages locally; OCR up to 50 pages.
- Modern Office: up to 250 MiB with OOXML expansion and compression-ratio checks.
- Text/CSV/HTML: up to 32 MiB; normalized output is bounded to 4 million characters.
- WeChat URL fetching accepts only the official article host and approved image CDN hosts.
- Never send private attachments to Web Search or a public URL.
