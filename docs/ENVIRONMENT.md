# Environment variables

在OpenMinis **Settings → Environment Variables** 中手工创建：

| 变量 | 必需 | 内容 |
| --- | --- | --- |
| `OPENVIKING_MCP_URL` | 是 | Vaultwarden条目中的Tailnet HTTPS MCP地址 |
| `OPENVIKING_MCP_TOKEN` | 是 | 该iCloud/设备组专用的OpenViking Bearer Token |
| `WEBSEARCH_MCP_URL` | 是 | Vaultwarden条目中的AWS KR Tailnet HTTPS MCP地址 |
| `WEBSEARCH_MCP_TOKEN` | 是 | 该iCloud/设备组专用的Web Search Bearer Token |

同一iCloud下的设备使用同一组值；另一个iCloud使用不同Token，方便单独撤销和审计。Freddy设备填写Freddy Token，Yurik设备填写Yurik Token。不同OpenViking Token访问同一个全库，不创建个人数据孤岛。不要在客户端设置OpenViking account/user Header；Bridge固定连接现有共享数据面。Web Search的Brave、GLM、Tavily、Firecrawl、Jina、xAI、SerpAPI和Gemini等上游密钥只保留在AWS KR，绝不填写到OpenMinis。

可选的仓库控制变量，通常不设置：

- `OPENMINIS_BOOTSTRAP_REPO`：默认 `Murphisensei/openminis-bootstrap`
- `OPENMINIS_BOOTSTRAP_REF`：默认 `main`
- `OPENMINIS_ROOT`：仅用于隔离测试；真实OpenMinis使用 `/var/minis`

Bootstrap会根据显式选择的profile安装对应SOUL和`openminis-agent`，并根据manifest安装共用Skills及注册已就绪的MCP。模型Provider不属于这个Bootstrap。个人专属能力使用单独GitHub仓库。不要把上游API Key、Vaultwarden session、SSH key、GitHub写Token、云管理员或交易凭据放入OpenMinis。
