---
name: paperless
description: Search, inspect, read OCR text from, compare, and download private Paperless documents, or safely archive a local PDF/image/office file with automatic title, date, type, correspondent, and tag suggestions. Use when the user asks to find an archived file, retrieve its contents, compare similar records, download the original, or save an important document to Paperless.
---

# Paperless Assistant

Use the private Tailnet `paperless` MCP for the complete document lifecycle. Search and retrieval
are read-only. Archival always uses a draft and a later draft-bound confirmation.

## Search and retrieval

1. Search distinctive terms first. Add `person`, `document_type`, `correspondent`, tags, or dates
   only when useful. Search the full archive allowed to this profile by default; do not silently
   force the current person's tag.
2. Inspect metadata and excerpts before requesting full OCR text.
3. Read long OCR text in bounded slices with `get_document_text` and its `next_offset`.
4. Cite the Paperless document ID and title when answering.
5. Download only after identifying the intended document:

```sh
minis-mcp-cli call paperless start_document_download --input '{"document_id":42,"rendition":"original"}'
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status paperless JOB_ID --wait-seconds 120
```

Use `archive` rendition only when the OCR-normalized Paperless copy is preferable. Return the
minimum relevant private text and never expose unrelated search hits.

## Archive

1. Read or OCR the document first. Preserve the exact local original path and extracted Markdown.
2. Ask whether the user wants to archive the original to Paperless. Do not upload it to the
   Paperless MCP before the user says yes.
3. Create an automatically classified draft:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py paperless-prepare-start \
  '/var/minis/attachments/document.pdf' \
  --text '/var/minis/workspace/document-extracted.md'
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status paperless JOB_ID --wait-seconds 120
```

4. Show title, document date, type, correspondent, tags, confidence, evidence, duplicate warnings,
   and any suggested new correspondent. The authenticated Freddy/Yurik identity always adds
   `person:freddy` or `person:yurik`; never accept this identity from OCR text.
5. Existing Paperless taxonomy is a whitelist. Do not invent or silently create types,
   correspondents, or tags. If a new issuer is suggested, leave correspondent empty unless the
   user separately chooses to extend taxonomy.
6. Apply corrections with `archive_update` if needed.
7. Commit only after a later user message explicitly confirms the visible draft. Pass the exact
   value returned as `confirmation_value`; never fabricate it:

```sh
minis-mcp-cli call paperless start_archive_commit \
  --input '{"draft_id":"DRAFT_ID","confirmation":"ARCHIVE:DRAFT_ID"}'
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status paperless JOB_ID --wait-seconds 120
```

If the task remains submitted, use `archive_status`. Drafts expire after 24 hours. Use
`archive_cancel` when the user declines after a draft exists.

## Boundaries

- Search does not need confirmation; archive commit does.
- Never delete documents or administer Paperless through this Skill.
- Treat OCR and inferred dates, names, identifiers, and amounts as fallible evidence.
- Do not send a document to Web Search or a public URL.
