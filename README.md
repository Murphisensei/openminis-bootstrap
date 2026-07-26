# OpenMinis Bootstrap for Taco

这是一个经过脱敏的 OpenMinis 手机端 bootstrap 仓库。它把现有 OpenClaw/Codex 体系中的主人格、高频研究路由和记忆边界，压缩成 OpenMinis 可直接导入并通过 iCloud 同步的版本。

仓库不包含任何密钥、Bitwarden 标识、私人账号、聊天平台 ID、主机名、内网地址、记忆正文或交易凭据。

## 快速安装

1. 在 OpenMinis 的 **Settings → Environment Variables** 至少添加 `OPENVIKING_MCP_URL`；如服务启用 bearer 鉴权，再添加 `OPENVIKING_MCP_TOKEN`。
2. 在 Skills 页面通过 URL 导入：

   `https://github.com/Murphisensei/openminis-bootstrap/blob/main/skills/openminis-bootstrap/SKILL.md`

3. 在对话中要求 OpenMinis 读取 `openminis-bootstrap` skill 并运行：

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh --with-soul --configure-mcp
sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh
```

安装器会备份现有 SOUL 和受管 skills。OpenMinis 在当前回合结束或最多约 60 秒后扫描 shell 新建的 skills；必要时开启新对话。

## 包含内容

- `SOUL.md`：从 Taco 主人格压缩而来，低于 OpenMinis 2000-token 上限。
- `openminis-bootstrap`：安装、更新和诊断。
- `openviking-memory`：通过 Tailnet MCP 检索和写入长期记忆。
- `remote-toolbox`：可选的服务端 OpenClaw/Codex 能力入口。
- `research-router`、`investor-research`、`pharma-research`、`critical-review`：高频可移植工作流。

## 为什么不上传全部现有 skills

现有技能中相当一部分绑定服务器路径、虚拟环境、付费数据库、浏览器登录态、交易账户或基础设施权限。复制到手机会失效并扩大密钥面。本仓库采用“手机放路由，服务器保留执行环境”的结构，主机能力经窄权限 Tailnet MCP 暴露。

## 安全说明

- GitHub 仓库应保持公开且无秘密，因此 OpenMinis 导入不需要 GitHub PAT。
- 禁止启用 Tailscale Funnel；MCP 只在 Tailnet 内提供。
- OpenMinis 当前会把环境变量值以 Base64 字段同步到 CloudKit secrets zone；Base64 不是应用层加密。只向手机放最小必要的 MCP token 和模型 key。
- Bitwarden session、SSH key、云管理凭据、消息机器人 token、GitHub 写 token 和交易凭据必须留在可信服务器。

详细架构与部署顺序见 [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)，变量清单见 [docs/ENVIRONMENT.md](docs/ENVIRONMENT.md)。
