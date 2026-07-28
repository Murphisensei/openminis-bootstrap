---
name: company-lookup
description: Retrieve Chinese company registration, legal-risk, and patent information through the paid Tianyancha capability of the websearch MCP. Use only when the user asks for a specific company and explicitly confirms the displayed per-call price.
---

# Company Lookup

Use `company_search` on the MCP server named `websearch` with `kind=info|risk|patent` and an exact
company name, company ID, or unified social credit code.

First request a price preview:

```sh
minis-mcp-cli call websearch company_search --input '{"kind":"info","query":"示例公司","confirm_paid":false}'
```

Show `estimated_cost_cny` and ask the user for explicit confirmation. Only after confirmation,
repeat the exact query with `confirm_paid=true`. Do not infer confirmation, broaden the company
name, or make multiple paid calls automatically. Cache hits are returned without another charge,
and the server enforces a per-person daily budget.

Treat registration, risk, and patent records as source data that may be delayed or incomplete.
Distinguish similarly named companies and preserve identifiers and dates. Use ordinary
`web_search` for free public context before suggesting another paid lookup.
