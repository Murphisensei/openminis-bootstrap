# Environment variables

在 OpenMinis **Settings → Environment Variables** 中手工创建。Bitwarden 只作为取值来源，不要把 Bitwarden session 或 vault 凭据放入 OpenMinis。

`OPENMINIS_ROOT` 只用于仓库的隔离测试；真实 OpenMinis 中不要设置，默认根目录是 `/var/minis`。

## 最小部署

| 变量 | 必需性 | 用途 | Bitwarden 建议 |
| --- | --- | --- | --- |
| `OPENVIKING_MCP_URL` | 必需 | Oracle Tailnet 上的 OpenViking MCP HTTPS URL | URL 可记入 Secure Note，不属于密钥 |
| `OPENVIKING_MCP_TOKEN` | 条件必需 | MCP bridge 的 scoped bearer token | 独立 Login/API Key 条目，仅授予 memory MCP |
| `OPENCLAW_MCP_URL` | 可选 | 远程 toolbox MCP URL | 仅部署 toolbox 后填写 |
| `OPENCLAW_MCP_TOKEN` | 可选 | toolbox scoped bearer token | 与 OpenViking token 分开 |

## 模型 Provider

当前主体系使用 Aliyun/Sub2API/OpenRouter 等 provider。OpenMinis 中只配置你实际使用的一个主 provider 和至多一个 fallback：

| 变量 | 用途 |
| --- | --- |
| `SUB2API_GPT_BASE_URL` | 当前 GPT 兼容 API 的 base URL |
| `SUB2API_GPT_API_KEY` | 当前 GPT 兼容 API key |
| `DASHSCOPE_API_KEY` | Aliyun Bailian/DashScope 直连 fallback |
| `OPENROUTER_API_KEY` | OpenRouter fallback |
| `XAI_API_KEY` | xAI provider，仅实际启用时填写 |

在 Provider 设置中使用 `$$SUB2API_GPT_API_KEY` 这类引用，不要粘贴到 JSON、skill 或 SOUL。

## 仅在手机本地直连搜索 API 时添加

默认方案通过 native browser 或 server toolbox，不需要以下 key。只有以后安装对应本地 skill 才添加：

- `BRAVE_API_KEY`
- `GLM_API_KEY`
- `TAVILY_API_KEY`
- `FIRECRAWL_API_KEY`
- `SERPAPI_API_KEY`
- `JINA_API_KEY`

## 禁止放入手机

- `BW_SESSION`、Bitwarden client secret 或 machine-account 凭据
- SSH private key、云管理员 key、OCI/AWS 凭据
- GitHub 写权限 PAT
- Discord/Telegram/Feishu/WhatsApp bot token
- IBKR、Binance、Kraken、Longbridge 等交易或资金权限凭据
- OpenClaw gateway 管理 token

原因：OpenMinis 的环境变量会随 iCloud 同步；当前实现对值使用 Base64 表示，不能把它视为应用层加密保险箱。
