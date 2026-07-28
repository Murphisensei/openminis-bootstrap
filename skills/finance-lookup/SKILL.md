---
name: finance-lookup
description: Retrieve bounded market prices, history, fundamentals, screening results, A/H data, macro indicators, financial reports, news, and announcements through the websearch MCP. Use for quick financial facts and document discovery; do not use for trading or full investment decisions.
---

# Finance Lookup

Use the MCP server named `websearch`. Refresh discovery once if a new tool is missing:

```sh
minis-mcp-cli tools websearch --refresh
```

## Route

- `market_data`:
  - `quote` or `history`: set comma-separated `symbols`; Yahoo is best-effort evidence.
  - `fundamentals`: set a focused Chinese natural-language `query`; uses EastMoney.
  - `screen`: set explicit screening conditions in `query`; uses EastMoney.
  - `a_share_daily`, `a_share_daily_basic`, `hk_daily`: set Tushare-format symbols and dates.
  - `trade_calendar`: set `symbols` to an exchange such as `SSE` and provide dates.
  - `macro`: set `query` to a World Bank indicator code and `symbols` to country codes.
- `finance_documents`: choose `reports`, `news`, or `announcements`. Use `ticker`, `query`, and
  dates to narrow the search. Returned data is discovery evidence, not guaranteed full text.
- Use `read_url` only when a returned public URL needs full-text verification.

Examples:

```sh
minis-mcp-cli call websearch market_data --input '{"kind":"quote","symbols":"AAPL,0700.HK","limit":5}'
minis-mcp-cli call websearch market_data --input '{"kind":"fundamentals","query":"贵州茅台 市盈率 ROE 股息率"}'
minis-mcp-cli call websearch finance_documents --input '{"kind":"reports","query":"GLP-1 最新研报","limit":8}'
```

State the provider and observation date. Treat quotes as time-sensitive and Yahoo as best effort.
Do not place orders, access portfolios, or imply that a report snippet is the full document. For
multi-source valuation, portfolio decisions, or long-form investment research, return a compact
evidence brief for OpenClaw instead of recreating its research workflow locally.
