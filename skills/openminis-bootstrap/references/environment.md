# Environment checklist

Add values in OpenMinis **Settings → Environment Variables**. The bootstrap and diagnosis scripts only test whether a value exists; they never print it.

Required for shared memory:

- `OPENVIKING_MCP_URL`: Tailnet-only HTTPS MCP endpoint.
- `OPENVIKING_MCP_TOKEN`: optional bearer token; recommended when the bridge enforces one.

Optional remote capability gateway:

- `OPENCLAW_MCP_URL`: Tailnet-only toolbox MCP endpoint.
- `OPENCLAW_MCP_TOKEN`: bearer token for that endpoint.

Optional repository controls, normally left unset:

- `OPENMINIS_BOOTSTRAP_REPO`: defaults to `Murphisensei/openminis-bootstrap`.
- `OPENMINIS_BOOTSTRAP_REF`: defaults to `main`.
- `OPENMINIS_ROOT`: test-only filesystem override; leave unset in OpenMinis so it uses `/var/minis`.

Provider keys belong in OpenMinis provider settings as `$$VARNAME` references. Do not place secrets directly in provider or MCP JSON.

Do not copy Bitwarden sessions, SSH keys, GitHub write tokens, messaging bot tokens, cloud-admin credentials, or brokerage trading credentials to OpenMinis.
