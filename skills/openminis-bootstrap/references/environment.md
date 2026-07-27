# Environment checklist

Add values in OpenMinis **Settings → Environment Variables**. The bootstrap and diagnosis scripts only test whether a value exists; they never print it.

Required for common Tailnet MCP capabilities:

- `OPENVIKING_MCP_URL`: Tailnet-only HTTPS MCP endpoint.
- `OPENVIKING_MCP_TOKEN`: required iCloud/device-group bearer token from Vaultwarden. Use the Freddy Token with `--profile freddy` and the Yurik Token with `--profile yurik`. Tokens are separately revocable but use the same shared OpenViking library.
- `WEBSEARCH_MCP_URL`: Tailnet-only Web Search MCP endpoint.
- `WEBSEARCH_MCP_TOKEN`: bearer Token matching this person/iCloud group. Upstream search-provider
  keys stay on AWS KR and must never be copied into OpenMinis.

Optional repository controls, normally left unset:

- `OPENMINIS_BOOTSTRAP_REPO`: defaults to `Murphisensei/openminis-bootstrap`.
- `OPENMINIS_BOOTSTRAP_REF`: defaults to `main`.
- `OPENMINIS_ROOT`: test-only filesystem override; leave unset in OpenMinis so it uses `/var/minis`.

The selected Taco SOUL, `openminis-agent`, and manifest-managed common Skills are part of this
bootstrap. Person-specific capabilities use separate GitHub repositories. Do not copy provider API
keys, Bitwarden sessions, SSH keys, GitHub write tokens, messaging bot tokens, cloud-admin
credentials, or brokerage credentials to OpenMinis.
