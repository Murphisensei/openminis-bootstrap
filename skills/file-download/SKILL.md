---
name: file-download
description: Download a user-supplied public HTTP or HTTPS file, media item, or extracted audio through the private download MCP and save the verified result into OpenMinis. Use for explicit download requests, including direct files and supported yt-dlp media URLs.
---

# File Download

Use the download MCP only for a URL the user supplied or clearly selected. It rejects local,
private, reserved, credential-bearing, and oversized destinations; do not attempt to bypass those
checks.

## Choose a mode

- `auto`: try a bounded direct download, then supported media handling when appropriate.
- `direct`: ordinary public file URL.
- `media`: supported page/video through yt-dlp.
- `audio`: extract MP3 from supported media.

Start one asynchronous job:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py download-start 'https://example.com/file.pdf' --mode direct --max-mb 500
```

Then reuse its job ID:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status download JOB_ID --wait-seconds 120
```

Direct files are stored in `/var/minis/workspace`; playable media and extracted audio are stored in
`/var/minis/attachments`. Return the resulting `minis://...` URL. Never claim success until the
helper has verified size and SHA-256. Do not download copyrighted, paywalled, authenticated, or
access-controlled material unless the user has lawful access and the selected method is authorized.
