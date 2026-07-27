# OpenMinis Taco Bootstrap

这个公开仓库为 Freddy 和 Yurik 分别初始化 OpenMinis。两边的助手都叫 **Taco**，但使用不同的 SOUL、移动端 Agent Skill 和每项 MCP 的独立 Bearer Token。

两个入口访问同一个 OpenViking 全库和同一套 AWS KR Web Search 能力。Token 用于身份、审计和单独撤销；OpenViking Token 不创建彼此隔离的空记忆池。

仓库不包含密钥、Vaultwarden 标识、私人账号、Tailnet 主机名、内网地址或记忆正文，也不安装模型 Provider、远程执行工具或服务器专用 Skill。共用 MCP 与对应基础 Skill 由 manifest 管理；个人专属能力放在单独 GitHub 仓库中。

## 首次初始化

1. 在对应 iCloud/device group 的 OpenMinis **Settings → Environment Variables** 添加：
   - `OPENVIKING_MCP_URL`
   - `OPENVIKING_MCP_TOKEN`：必须使用这个人的 Vaultwarden Token
   - `WEBSEARCH_MCP_URL`
   - `WEBSEARCH_MCP_TOKEN`：必须使用这个人的 Vaultwarden Token
2. 在 Skills 页面导入：

   `https://github.com/Murphisensei/openminis-bootstrap/blob/main/skills/openminis-bootstrap/SKILL.md`

3. Freddy 的设备执行：

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh --profile freddy --configure-mcp && sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh --profile freddy
```

Yurik 的设备执行：

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh --profile yurik --configure-mcp && sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh --profile yurik
```

安装器会更新：

- `/var/minis/memory/SOUL.md`
- `/var/minis/skills/openminis-agent`
- `/var/minis/skills/openviking-memory`
- `/var/minis/skills/web-search`
- `/var/minis/skills/openminis-bootstrap`

原文件会先备份到 `/var/minis/backups/openminis-bootstrap-TIMESTAMP-PID`。SOUL 会由 OpenMinis 的 iCloud 机制在同一 iCloud 设备组内同步；两个不同 iCloud 需要分别执行一次对应 Bootstrap。

## 后续更新

首次安装会保存设备的 `freddy` 或 `yurik` profile 和公共 manifest。以后运行下面一行即可沿用已保存身份、更新共用 Skills，并注册环境变量已经就绪的新 MCP：

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh && sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh
```

如果设备安装的是旧版、尚未支持 `--profile`，先重新导入上面的 Bootstrap URL；或者先运行一次旧的 `install.sh` 更新脚本，再执行对应的首次初始化命令。

新的共用 MCP 必须同时提供对应 Skill，并登记到 manifest；Bootstrap 会统一安装和检查。
Freddy 或 Yurik 的个性化 Skill/配置使用单独 GitHub 仓库，通过对应 `SKILL.md` URL 额外导入，不加入这个共享 Bootstrap。

## 两套 Taco 的定位

- Freddy：结论先行、独立判断，侧重 Pharma/Biotech、BD 与投资研究的证据链和反面论据。
- Yurik：清晰专业、允许方向性判断，侧重医疗器械、Healthcare PE、尽调问题和研究包规划，默认 chat-first。
- 两者：OpenMinis 负责会议记录、转写整理、快速捕捉、共享记忆、轻量分析和任务分流；重研究与复杂执行整理成任务后交给 OpenClaw/Codex。

部署说明见 [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)，变量说明见 [docs/ENVIRONMENT.md](docs/ENVIRONMENT.md)。
