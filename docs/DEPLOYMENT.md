# Deployment

## Architecture

```text
GitHub bootstrap ──> OpenMinis
                         │
                         └── Tailnet HTTPS ──> authenticated MCP bridge
                                                    └── loopback OpenViking
```

The public repository contains only the client installer and memory-use instructions. The bridge, token database, service configuration, and credentials stay on the trusted SG host. Tokens identify and authorize client entrances; they do not create separate OpenViking data silos.

## Server gate

Before phone initialization, verify:

- the bridge binds only to `127.0.0.1:1940`;
- OpenViking binds only to `127.0.0.1:1933`;
- each iCloud/device group has a separately revocable Token;
- all authorized entrances use the existing shared `default/default` OpenViking data plane;
- search returns the deduplicated union of native memory and active cross-host resources, while excluding same-host backup mirrors from the default roots;
- the exposed MCP tools are exactly `memory_search`, `memory_read`, `memory_remember`, and `health`;
- missing and invalid Tokens receive 401;
- Tailscale Serve exposes a dedicated private HTTPS port and Funnel is off.

## OpenMinis initialization

1. Install Tailscale and join the authorized Tailnet.
2. Add both variables from `docs/ENVIRONMENT.md`.
3. Import the Bootstrap URL from the repository README.
4. Run:

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh --configure-mcp
sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh
```

5. Verify a known shared-library project can be searched and read, then verify a non-sensitive write returns through the shared native pool.

## Updates and rollback

Run `install.sh` again to update the two managed skills. Each run backs up their previous directories under `/var/minis/backups/openminis-bootstrap-TIMESTAMP`. The installer does not modify SOUL or independently installed skills.
