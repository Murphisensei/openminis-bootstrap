# OpenMinis OpenViking Bootstrap

这个公开仓库只负责初始化 OpenMinis 与私人 OpenViking 记忆服务之间的连接。它不会安装 SOUL、研究工作流、远程执行工具或模型 Provider。

仓库不包含密钥、Vaultwarden 标识、私人账号、Tailnet 主机名、内网地址或记忆正文。

## 初始化

1. 在 OpenMinis **Settings → Environment Variables** 添加：
   - `OPENVIKING_MCP_URL`
   - `OPENVIKING_MCP_TOKEN`
2. 在 Skills 页面导入：

   `https://github.com/Murphisensei/openminis-bootstrap/blob/main/skills/openminis-bootstrap/SKILL.md`

3. 让 OpenMinis 执行：

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh --configure-mcp
sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh
```

初始化器只安装 `openminis-bootstrap` 和 `openviking-memory`，注册一个带Bearer Token的Tailnet MCP，并检查握手与四个允许的记忆工具。SOUL和其他Skill保持不变。

## 后续新增Skill

其他Skill放在各自的GitHub目录中，通过对应 `SKILL.md` URL单独导入。它们不加入Bootstrap的受管列表，也不会随记忆初始化自动安装。

## 安全边界

- MCP只通过Tailscale Serve在Tailnet内开放；禁止Funnel。
- 原生OpenViking仅监听服务器loopback。
- 每个iCloud/设备组使用独立Bearer Token，便于单独撤销和审计；所有入口共享现有OpenViking全库。
- Bridge搜索原生记忆与活跃跨主机资源的去重并集，OpenMinis只是现有多入口体系中的新增入口。
- 不把Vaultwarden session、SSH key、GitHub写Token、云管理或交易凭据放入OpenMinis。

部署说明见 [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)，变量说明见 [docs/ENVIRONMENT.md](docs/ENVIRONMENT.md)。
