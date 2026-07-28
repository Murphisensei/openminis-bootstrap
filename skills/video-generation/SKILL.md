---
name: video-generation
description: Generate a short 2-15 second video, optionally with a local MP3 or WAV soundtrack, through the private video MCP and retrieve the MP4 into OpenMinis. Use for explicit text-to-video or short visual-clip requests after duration, resolution, and aspect ratio are confirmed.
---

# Video Generation

Video calls are paid. Before starting, confirm the prompt plus all three billable/output settings:
duration (2-15 seconds), resolution (720P or 1080P), and ratio (16:9, 9:16, 1:1, 4:3, or 3:4).
Do not treat defaults as consent when the user omitted them.

## Start and retrieve

Build a prompt with subject, action, scene, camera movement, lighting, timing, and visual style. Then
run the helper with the confirmed settings:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py video-start --prompt 'PROMPT' --duration 5 --resolution 720P --ratio 16:9
```

For a custom soundtrack, add an explicit MP3 or WAV under an allowed OpenMinis directory:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py video-start --prompt 'PROMPT' --duration 5 --resolution 720P --ratio 16:9 --audio '/var/minis/attachments/soundtrack.mp3'
```

Keep the returned job ID and poll it; generation can outlive the current turn:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status video JOB_ID --wait-seconds 120
```

When complete, return the verified `minis://attachments/...` MP4. Never launch a duplicate job
while the first is queued or running. If the result is unsatisfactory, describe the issue and obtain
approval for another paid generation.
