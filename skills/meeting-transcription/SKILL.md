---
name: meeting-transcription
description: Transcribe an OpenMinis audio or video attachment through the private meeting MCP, retrieve the speaker-aware Markdown transcript, and automatically turn it into reliable meeting minutes. Use for recordings, voice memos, interviews, calls, and meeting-note requests.
---

# Meeting Transcription

Use the shared asynchronous MCP for transcription. The recording stays behind the Tailnet transfer
route, provider credentials remain on AWS KR, and a job continues if the phone disconnects.

## Workflow

1. Identify the exact recording path under `/var/minis/attachments`, `/var/minis/workspace`,
   `/var/minis/shared`, or `/var/minis/mounts`. Do not guess a filename.
2. Start transcription with the helper. Speaker separation is on by default; add
   `--speaker-count N` only when the user supplied a reliable count.

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py meeting-start '/var/minis/attachments/meeting.m4a'
```

3. Keep the returned job ID. Check it without re-uploading the recording:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status meeting JOB_ID --wait-seconds 120
```

   If still queued or running, report that clearly and reuse the same status command later. Never
   start a duplicate job merely because one turn ended.
4. When successful, read the returned `minis://workspace/...` Markdown transcript.
5. Automatically prepare concise meeting minutes in the user's language:
   - purpose and executive conclusion;
   - decisions and rationale;
   - action items with owner and date only when stated;
   - key evidence, disagreements, risks, and unresolved questions;
   - claims that need external verification.

Preserve uncertainty and speaker labels. Never invent speakers, owners, dates, decisions, or facts
missing from the transcript. Keep raw transcripts out of durable memory; remember only confirmed,
stable outcomes when the user wants them retained.

## Routing

The default route uses current Beijing `fun-asr` with diarization for meetings up to two hours and
automatically falls back to the long-file ASR route when required. Do not override the server model
from the phone. Use this Skill for transcription and meeting synthesis; use `web-search` only when
the user asks to verify transcript claims against current sources.
