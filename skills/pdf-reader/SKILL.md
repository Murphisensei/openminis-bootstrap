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

### WeChat analysis contract

Treat the fetched article as source material, not as verified truth. Do not search for or invent the
article body through another tool. After the grounded Markdown is available, choose the smallest
useful review mode:

- If the user explicitly asks only to summarize or extract, return a concise source-faithful digest,
  the author's main interpretation, and material information the article does not disclose.
- For a shared link, “看看”, “分析”, “怎么看”, or an unspecified request, default to the compact
  critical review below.
- For “核实”, “真假”, medical/pharma diligence, investment implications, or a claim whose current
  accuracy changes the answer, finish source extraction first and then use `$web-search` to verify
  at most the decisive claims. Keep external evidence and the article's statements visibly separate.

Default compact review:

1. **结论** — one directional sentence and a calibrated confidence level.
2. **原文主张** — separate checkable claims from the author's interpretation, forecast, recommendation,
   and emotional framing. Say “原文称” until a claim is independently verified.
3. **最强反方** — challenge the weakest material link using **problem → basis → impact**. Check source
   chain, date, denominator, baseline, sample, time window, causality, selective citation, conflicts of
   interest, and omitted alternatives. Give at least one plausible counterexample or alternative
   explanation when evidence supports it; do not manufacture disagreement.
4. **Taco 的独立判断** — state what still holds after the countercase, what would change the judgment,
   and why. Give decision-relevant rationale, not hidden chain-of-thought or a performative debate.
5. **待核验 / 下一步** — list only unresolved claims that could materially change the conclusion and
   the smallest useful verification action.

If no material objection is supported, say “未发现有依据的重大反方”，rather than inventing one.
External verification should prefer primary or official sources, include dates and direct links, and
must never silently turn a single article into a full investment thesis. For deep competitive,
clinical, valuation, or transaction work, return the compact review plus a scoped handoff brief.

The archive contains source metadata, normalized article Markdown, and retrievable WeChat images.
If the job output says the archive is queued or retrying, analysis can still continue. Check the
durable archive separately with:

```sh
minis-mcp-cli call pdfreader wechat_archive_status --input '{"job_id":"JOB_ID"}'
```

Do not create a Paperless draft for a WeChat article unless the user explicitly asks for a second,
formal document archive. Keep the automatic Obsidian note source-pure: it stores the article and
images, not model conclusions. Do not claim the chat analysis was archived unless a separate,
explicitly confirmed analysis-note workflow actually writes it.

## Limits and boundaries

- PDF: up to 500 pages locally; OCR up to 50 pages.
- Modern Office: up to 250 MiB with OOXML expansion and compression-ratio checks.
- Text/CSV/HTML: up to 32 MiB; normalized output is bounded to 4 million characters.
- WeChat URL fetching accepts only the official article host and approved image CDN hosts.
- Never send private attachments to Web Search or a public URL.
