# Deployment

## Architecture

```text
GitHub shared bootstrap ──> Freddy OpenMinis (Taco + Freddy Tokens) ──┐
                                                                     ├── Tailnet ──> SG memory MCP ──> shared OpenViking
                          └> Yurik OpenMinis (Taco + Yurik Tokens) ───┤
                                                                     └── Tailnet ──> AWS KR Web Search MCP
```

The public repository contains two non-secret client profiles, a manifest-driven installer, and common MCP-use Skills. Bridges, token databases, service configuration, and credentials stay on trusted servers. Tokens identify and authorize client entrances; they do not create separate OpenViking data silos. Person-specific capabilities live in separate GitHub repositories.

## Server gate

Before phone initialization, verify:

- the bridge binds only to `127.0.0.1:1940`;
- OpenViking binds only to `127.0.0.1:1933`;
- each iCloud/device group has a separately revocable Token;
- all authorized entrances use the existing shared `default/default` OpenViking data plane;
- search returns the deduplicated union of native memory and active cross-host resources, while excluding same-host backup mirrors from the default roots;
- the exposed MCP tools are exactly `memory_search`, `memory_read`, `memory_remember`, and `health`;
- the AWS KR Web Search MCP exposes the tools declared in `manifest.json` and binds its application
  only to loopback behind Tailnet HTTPS;
- missing and invalid Tokens receive 401;
- Tailscale Serve exposes a dedicated private HTTPS port and Funnel is off.

## OpenMinis initialization

1. Install Tailscale and join the authorized Tailnet.
2. Add all variables from `docs/ENVIRONMENT.md`, using the Tokens that match this person.
3. Import the Bootstrap URL from the repository README.
4. Run:

```sh
sh /var/minis/skills/openminis-bootstrap/scripts/install.sh --profile freddy --configure-mcp
sh /var/minis/skills/openminis-bootstrap/scripts/doctor.sh --profile freddy
```

   Use `--profile yurik` for Yurik's iCloud/device group.
5. Verify the doctor reports the expected profile, every managed Skill, both MCP handshakes, and all
   required tools. Then verify a known shared-library project can be searched/read and a current web
   query returns cited results.

## Updates and rollback

Run `install.sh` again to update the saved profile's SOUL, manifest-managed common Skills, and any
newly ready MCP entries. Each run backs up previous managed content under
`/var/minis/backups/openminis-bootstrap-TIMESTAMP-PID`. Independently installed personal Skills remain
unchanged.
