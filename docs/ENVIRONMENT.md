# Environment variables

在OpenMinis **Settings → Environment Variables** 中手工创建：

| 变量 | 必需 | 内容 |
| --- | --- | --- |
| `OPENVIKING_MCP_URL` | 是 | Vaultwarden条目中的Tailnet HTTPS MCP地址 |
| `OPENVIKING_MCP_TOKEN` | 是 | 该iCloud/个人专用的Bearer Token |

同一iCloud下的设备使用同一组值；另一个人的iCloud必须使用不同Token。不要在客户端设置OpenViking account/user Header，Bridge会根据Token固定映射。

可选的仓库控制变量，通常不设置：

- `OPENMINIS_BOOTSTRAP_REPO`：默认 `Murphisensei/openminis-bootstrap`
- `OPENMINIS_BOOTSTRAP_REF`：默认 `main`
- `OPENMINIS_ROOT`：仅用于隔离测试；真实OpenMinis使用 `/var/minis`

模型Provider、SOUL和其他Skill不属于这个Bootstrap。不要把Vaultwarden session、SSH key、GitHub写Token、云管理员或交易凭据放入OpenMinis。
