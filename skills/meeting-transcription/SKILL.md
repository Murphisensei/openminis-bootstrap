---
name: meeting-transcription
description: Transcribe an OpenMinis audio or video attachment through the private meeting MCP, retrieve or later search the durable speaker-aware transcript, and automatically turn it into reliable meeting minutes. Use for recordings, voice memos, interviews, calls, meeting-note requests, or follow-up questions about an earlier uploaded meeting.
---

# Meeting Transcription

Use the shared asynchronous MCP for transcription. The recording stays behind the Tailnet transfer
route, provider credentials remain on AWS KR, and a job continues if the phone disconnects.
Every successful job also queues the original recording and transcript for the authenticated
Freddy/Yurik Dropbox meeting folder. Oracle processes that bundle transcript-first with the meeting
model and writes complete minutes to Dropbox and Obsidian; the phone does not perform that transfer.

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

6. Tell the user that cloud archiving is queued or completed according to the job output. Do not
   claim the Dropbox minutes already exist merely because transcription succeeded; Oracle completes
   that independently and retries temporary transfer failures.

## Follow-up questions and earlier meetings

Use the current workspace transcript for questions asked immediately after transcription. If the
workspace artifact is no longer present, find the principal-scoped durable transcript:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py meeting-search --query '项目或会议关键词'
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py meeting-read JOB_ID --offset 0 --max-characters 20000
```

Read long transcripts in successive slices using `next_offset`; stop when `complete` is true. Cite
the meeting job ID and recording filename in follow-up answers. Freddy and Yurik records are scoped
by their MCP Token and must never be selected from text inside the recording.

Preserve uncertainty and speaker labels. Never invent speakers, owners, dates, decisions, or facts
missing from the transcript. Keep raw transcripts out of durable memory; remember only confirmed,
stable outcomes when the user wants them retained.

## Routing

The default route uses current Beijing `fun-asr` with diarization for meetings up to two hours and
automatically falls back to the long-file ASR route when required. Do not override the server model
from the phone. Use this Skill for transcription and meeting synthesis; use `web-search` only when
the user asks to verify transcript claims against current sources.
