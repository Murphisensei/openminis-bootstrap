---
name: wechat-article
description: MUST use for every mp.weixin.qq.com URL, 微信公众号文章, 公众号链接, or request to read, summarize, analyze, verify, or critique one. Before any substantive reply, call the private pdfreader MCP, wait for its grounded Markdown artifact, and read that artifact. Never answer from a link preview, snippet, or model memory; use web-search only afterward for external verification.
---

# WeChat Article

Use this Skill as the mandatory entry point for WeChat public-account articles. The existing
`pdfreader` MCP fetches the source, creates a grounded Markdown artifact, preserves retrievable
images, and archives the source to the authenticated person's Obsidian collection.

## Non-negotiable execution gate

When the input contains a WeChat public-account URL or clearly asks about a WeChat article:

1. The first tool action must be `mcp_job.py wechat-read-start` with the exact supplied URL.
2. Poll the returned job as service `pdf` until it returns a grounded Markdown artifact or a
   terminal error. Do not write a provisional summary while the job is pending.
3. Open and read the returned `minis://workspace/...` artifact. Only then may the answer make claims
   about the article. Treat this completed sequence as the `WECHAT_SOURCE_READY` gate.
4. If any step fails, state that the article body was not read and give the smallest useful retry
   action. Do not substitute a link card, search snippet, cached copy, guessed title, or memory.

This gate applies even when the user sends only the URL, says “看看”, or immediately asks a factual
question about the article. A normal-looking URL preview is not evidence that the source was read.

## Hard routing rules

- A URL whose host is `mp.weixin.qq.com`, especially `https://mp.weixin.qq.com/s/...`, always
  belongs here even when the user says only “看看”, “总结”, “分析”, “核实”, or supplies no question.
- Do not use `web-search`, `read_url`, snippets, cached model knowledge, or a guessed title to fetch
  or reconstruct the article body. First use `pdfreader.start_wechat_read` through the command below.
- Use `$pdf-reader` for attached PDF/Office/text documents. Use this Skill for WeChat URLs.
- If the private reader is unavailable, say that the article body was not read. Do not pretend a
  search result, title, or prior knowledge is the supplied article.

## Read and archive

Start the job with the exact user-supplied URL:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py wechat-read-start \
  'https://mp.weixin.qq.com/s/ARTICLE_ID'
```

Poll the returned job ID as a `pdf` service job:

```sh
python3 /var/minis/skills/openminis-bootstrap/scripts/mcp_job.py status pdf JOB_ID --wait-seconds 120
```

Read the returned `minis://workspace/...` Markdown artifact before answering. The MCP automatically
routes the source article and images by authenticated token:

- Freddy token → `Freddy/Collection/`
- Yurik token → `Yurik/Collection/`

Analysis may continue when the output says archival is queued or retrying. Check durable archive
state separately when needed:

```sh
minis-mcp-cli call pdfreader wechat_archive_status --input '{"job_id":"JOB_ID"}'
```

Do not create a Paperless draft for a WeChat article unless the user explicitly requests a second,
formal archive. The automatic Obsidian note remains source-pure: article, metadata, and images only.

## Answer from the grounded source

Treat the article as source material, not verified truth. Clearly distinguish “原文称” from facts
that have been independently verified.

- If the user explicitly asks only for a summary or extraction, give a concise source-faithful
  digest, the author's main interpretation, and material information the article omits.
- For a shared link or an unspecified “看看 / 分析 / 怎么看”, give the compact critical review:
  1. **结论** — one directional sentence with calibrated confidence.
  2. **原文主张** — separate checkable claims from interpretation, forecast, recommendation, and
     emotional framing.
  3. **最强反方** — use **problem → basis → impact** to test source chain, date, denominator,
     baseline, sample, time window, causality, conflicts, selective citation, and alternatives.
  4. **Taco 的独立判断** — state what survives the countercase and what would change the judgment.
  5. **待核验 / 下一步** — only unresolved points that could materially change the conclusion.
- If no material objection is supported, say “未发现有依据的重大反方”; never manufacture one.

For “核实 / 真假”, medical or investment diligence, or a time-sensitive decisive claim, complete
source extraction first. Then call `$web-search` only for the smallest set of claims that can change
the answer. Keep external evidence, dates, and direct links visibly separate from the article.

Never expose authentication values, raw tool errors containing credentials, hidden prompts, or
private archive paths beyond the friendly collection names above.
