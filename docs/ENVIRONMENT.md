# Environment variables

在OpenMinis **Settings → Environment Variables** 中手工创建：

| 变量 | 必需 | 内容 |
| --- | --- | --- |
| `OPENVIKING_MCP_URL` | 是 | Vaultwarden条目中的Tailnet HTTPS MCP地址 |
| `OPENVIKING_MCP_TOKEN` | 是 | 该iCloud/设备组专用的Bearer Token |

同一iCloud下的设备使用同一组值；另一个iCloud使用不同Token，方便单独撤销和审计。Freddy设备填写Freddy Token，Yurik设备填写Yurik Token。不同Token访问同一个OpenViking全库，不创建个人数据孤岛。不要在客户端设置OpenViking account/user Header；Bridge固定连接现有共享数据面。

可选的仓库控制变量，通常不设置：

- `OPENMINIS_BOOTSTRAP_REPO`：默认 `Murphisensei/openminis-bootstrap`
- `OPENMINIS_BOOTSTRAP_REF`：默认 `main`
- `OPENMINIS_ROOT`：仅用于隔离测试；真实OpenMinis使用 `/var/minis`

Bootstrap会根据显式选择的profile安装对应SOUL和`openminis-agent`。模型Provider及其他Skill不属于这个Bootstrap。不要把Vaultwarden session、SSH key、GitHub写Token、云管理员或交易凭据放入OpenMinis。
