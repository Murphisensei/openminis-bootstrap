# Environment variables

在OpenMinis **Settings → Environment Variables** 中手工创建：

| 变量 | 必需 | 内容 |
| --- | --- | --- |
| `OPENVIKING_MCP_URL` | 是 | Vaultwarden条目中的Tailnet HTTPS MCP地址 |
| `OPENVIKING_MCP_TOKEN` | 是 | 该iCloud/设备组专用的OpenViking Bearer Token |
| `WEBSEARCH_MCP_URL` | 是 | Vaultwarden条目中的AWS KR Tailnet HTTPS MCP地址 |
| `WEBSEARCH_MCP_TOKEN` | 是 | 该iCloud/设备组专用的Web Search Bearer Token |
| `FIRECRAWL_MCP_URL` | 启用Firecrawl时 | Vaultwarden条目中的AWS KR Tailnet HTTPS安全桥地址 |
| `FIRECRAWL_MCP_TOKEN` | 启用Firecrawl时 | 该iCloud/设备组专用的Firecrawl Bridge Bearer Token |
| `MEETING_MCP_URL` | 启用会议功能时 | Vaultwarden条目中的AWS KR Tailnet HTTPS地址 |
| `MEETING_MCP_TOKEN` | 启用会议功能时 | 该iCloud/设备组专用的Meeting Bearer Token |
| `IMAGE_MCP_URL` | 启用图片功能时 | Vaultwarden条目中的AWS KR Tailnet HTTPS地址 |
| `IMAGE_MCP_TOKEN` | 启用图片功能时 | 该iCloud/设备组专用的Image Bearer Token |
| `VIDEO_MCP_URL` | 启用视频功能时 | Vaultwarden条目中的AWS KR Tailnet HTTPS地址 |
| `VIDEO_MCP_TOKEN` | 启用视频功能时 | 该iCloud/设备组专用的Video Bearer Token |
| `PDF_MCP_URL` | 启用文档读取功能时 | Vaultwarden条目中的AWS KR Tailnet HTTPS地址；沿用原PDF地址 |
| `PDF_MCP_TOKEN` | 启用文档读取功能时 | 该iCloud/设备组专用的Document Reader Bearer Token；沿用原PDF Token |
| `PAPERLESS_MCP_URL` | 启用Paperless时 | Vaultwarden条目中的Oracle Tailnet HTTPS地址 |
| `PAPERLESS_MCP_TOKEN` | 启用Paperless时 | Freddy或Yurik专用的Paperless MCP Bearer Token |
| `DOWNLOAD_MCP_URL` | 启用下载功能时 | Vaultwarden条目中的AWS KR Tailnet HTTPS地址 |
| `DOWNLOAD_MCP_TOKEN` | 启用下载功能时 | 该iCloud/设备组专用的Download Bearer Token |
| `DASHI_MCP_URL` | 启用Dashi功能时 | Vaultwarden条目中的AWS KR Tailnet HTTPS地址 |
| `DASHI_MCP_TOKEN` | 启用Dashi功能时 | 该iCloud/设备组专用的Dashi Bearer Token |

同一iCloud下的设备使用同一组值；另一个iCloud使用不同Token，方便单独撤销和审计。
Freddy设备填写Freddy Token，Yurik设备填写Yurik Token。不同OpenViking Token访问同一个
全库，不创建个人数据孤岛。不要在客户端设置OpenViking account/user Header；Bridge固定
连接现有共享数据面。Web Search上游密钥和DashScope Key都只保留在AWS KR，绝不填写到
OpenMinis。各项可选能力使用独立Token；只填URL而漏填Token（或反之）不会注册该MCP。
Dashi和Firecrawl等AWS KR能力的上游密钥只留在服务端；Firecrawl客户端Token只授权服务端
白名单，不会作为上游Firecrawl API凭据转发。
Dashi的Freddy/Yurik出生档案保存在AWS KR的root管理私有文件，不经OpenViking检索，也不
下发到手机。

Paperless上游读写Token与元数据分析模型密钥只保留在Oracle；OpenMinis只填写MCP URL和
个人MCP Token。归档时服务端从可信Token强制加入`person:freddy`或`person:yurik`，搜索默认
覆盖该Paperless账号获准访问的全库，可按person标签筛选。

可选的仓库控制变量，通常不设置：

- `OPENMINIS_BOOTSTRAP_REPO`：默认 `Murphisensei/openminis-bootstrap`
- `OPENMINIS_BOOTSTRAP_REF`：默认 `main`
- `OPENMINIS_ROOT`：仅用于隔离测试；真实OpenMinis使用 `/var/minis`

Bootstrap会根据显式选择的profile安装对应SOUL和`openminis-agent`，并根据manifest安装共用Skills及注册已就绪的MCP。模型Provider不属于这个Bootstrap。个人专属能力使用单独GitHub仓库。不要把上游API Key、Vaultwarden session、SSH key、GitHub写Token、云管理员或交易凭据放入OpenMinis。
