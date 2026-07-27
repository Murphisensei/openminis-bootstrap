# Environment checklist

Add values in OpenMinis **Settings → Environment Variables**. The bootstrap and diagnosis scripts only test whether a value exists; they never print it.

Required for private cross-device memory:

- `OPENVIKING_MCP_URL`: Tailnet-only HTTPS MCP endpoint.
- `OPENVIKING_MCP_TOKEN`: required iCloud/device-group bearer token from Vaultwarden. Use the Freddy Token with `--profile freddy` and the Yurik Token with `--profile yurik`. Tokens are separately revocable but use the same shared OpenViking library.

Optional repository controls, normally left unset:

- `OPENMINIS_BOOTSTRAP_REPO`: defaults to `Murphisensei/openminis-bootstrap`.
- `OPENMINIS_BOOTSTRAP_REF`: defaults to `main`.
- `OPENMINIS_ROOT`: test-only filesystem override; leave unset in OpenMinis so it uses `/var/minis`.

The selected Taco SOUL and `openminis-agent` are part of this bootstrap. Provider setup and all other skills are outside it. Do not copy Bitwarden sessions, SSH keys, GitHub write tokens, messaging bot tokens, cloud-admin credentials, or brokerage credentials to OpenMinis.
