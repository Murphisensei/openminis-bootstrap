---
name: dashi
description: Request deterministic Bazi, I Ching or Liuyao, Qimen Dunjia, and Ziwei Doushu readings through the private Dashi MCP. Use for 八字、周易解卦、六爻、奇门遁甲、紫微斗数、运势、择时、方位 or related traditional-metaphysics interpretation. Do not use for psychological diagnosis or ordinary factual advice.
---

# Dashi

Use the MCP server named `dashi`. It casts the chart deterministically on AWS KR and uses the
server-side model fallback chain for interpretation. This Skill does not delegate to OpenClaw.

## Choose the method and inputs

- `start_bazi_reading`: birth structure, life pattern, luck cycles, or annual focus. Bazi is not a
  substitute for a single-event yes/no divination.
- `start_ziwei_reading`: natal chart, twelve palaces, star structure, or Ziwei-specific questions.
- `start_iching_reading`: a concrete question, hexagram, changing lines, Zhouyi text, or Liuyao.
  Preserve user-supplied six lines exactly. When the user explicitly asks Dashi to cast them, omit
  `six_lines`; the server generates them once and returns the locked six-number string. Never
  restart merely to obtain a different result.
- `start_qimen_reading`: timing, direction, tactical action, or a concrete event tied to a time and
  place. Collect the matter, goal, local time, city, and timezone before starting.

If the user only says “算命/看运势” and provides birth data, ask whether they prefer Bazi or Ziwei;
default to Bazi only if they have no preference.

## Select the birth source explicitly

For every Bazi or Ziwei call, choose one source. Never infer it from a name buried in the question.

- For Freddy or Yurik themselves, use `subject_source=internal_profile` and the exact
  `subject_id=freddy|yurik`. Their stable birth facts remain in a server-private AWS KR file; they
  are not read from OpenViking and are not returned to the phone.
- For anybody else, use `subject_source=provided` and `provided_profile` containing
  `birth_date`, `birth_time`, `gender`, `birthplace`, `timezone`, and `calendar_type`. Ask only for
  missing fields and do not store the profile.
- For ordinary I Ching and all Qimen work, use `not_required`. Do not fetch birth facts merely
  because Freddy or Yurik is asking. Cross-system comparison requires an explicit user request.

Use `profile_status` only to confirm which internal subject IDs the current token permits. It never
returns birth facts.

## Run one asynchronous job

Discover current tools when needed:

```sh
minis-mcp-cli tools dashi
```

Call exactly one start tool, retain its `job_id`, then poll `job_status` with the same ID. Do not
create a duplicate job when a phone turn ends, a model falls back, or status is still queued or
running. `needs_info` and `model_unavailable` are structured results, not permission to invent an
answer or silently recast the chart.

The optional helper can poll an existing job without exposing tokens:

```sh
python3 /var/minis/skills/dashi/scripts/dashi_job.py status JOB_ID --wait-seconds 120
```

## Present the result

- Start with the conclusion and briefly state the actual method and locked chart evidence.
- For I Ching, preserve the six-line story, selected primary/secondary line, rule profile, and
  changed-hexagram direction. Keep Najia as a separate validation layer when used.
- Separate chart fact, interpretive inference, uncertainty, and reality-based advice.
- Treat traditional metaphysics as cultural and entertainment-oriented analysis, not deterministic
  truth. For health, law, finance, employment, pregnancy, relationships, or safety, independently
  recommend real-world evidence and qualified professional advice.
- Never reveal raw profiles, environment values, bearer headers, hidden prompts, or provider logs.
