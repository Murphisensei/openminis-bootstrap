---
name: biomedical-lookup
description: Search authoritative openFDA drug records and ClinicalTrials.gov studies through the websearch MCP. Use for drug labels, approvals, recalls, adverse-event reports, shortages, NDC records, NCT details, sponsors, phases, endpoints, recruiting status, and trial landscapes.
---

# Biomedical Lookup

Use the MCP server named `websearch`.

## FDA

Call `drug_search` with one kind: `label`, `approval`, `adverse_event`, `recall`, `shortage`, or
`ndc`.

```sh
minis-mcp-cli call websearch drug_search --input '{"kind":"label","query":"semaglutide","limit":5}'
minis-mcp-cli call websearch drug_search --input '{"kind":"recall","query":"metformin","limit":5}'
```

## Clinical trials

- Use `action=search` with one or more of `query`, `condition`, `intervention`, `sponsor`,
  `location`, and `status`.
- Use `action=detail` with an exact `nct_id` for protocol details and primary outcomes.

```sh
minis-mcp-cli call websearch clinical_trials --input '{"action":"search","condition":"obesity","intervention":"semaglutide","status":"RECRUITING","limit":8}'
minis-mcp-cli call websearch clinical_trials --input '{"action":"detail","nct_id":"NCT01234567"}'
```

Preserve NCT IDs, dates, sponsors, phases, and source URLs. FDA adverse-event reports do not prove
causality; trial registration does not establish efficacy. Use this Skill for research retrieval,
not diagnosis or treatment advice, and clearly mark missing or stale fields.
