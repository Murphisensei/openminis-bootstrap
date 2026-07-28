# Deployment

## Architecture

```text
GitHub shared bootstrap ──> Freddy OpenMinis (Taco + Freddy Tokens) ──┐
                                                                     ├── Tailnet ──> SG memory MCP ──> shared OpenViking
                          └> Yurik OpenMinis (Taco + Yurik Tokens) ───┤
                                                                     └── Tailnet ──> AWS KR independent MCPs
                                                                                     web / meeting / image
                                                                                     video / PDF / download / Dashi
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
- every AWS KR MCP exposes only the tools declared for it in `manifest.json`, runs as its own service
  account, and binds its application only to loopback behind its dedicated Tailnet HTTPS port;
- meeting, image, video, and PDF provider credentials exist only in root-readable AWS KR service
  configuration; the download MCP has no provider credential;
- Dashi's Freddy/Yurik birth profiles exist only in its root-managed AWS KR config file, are read
  by exact subject ID, and are absent from GitHub, OpenViking search, MCP status, and client output;
- upload and artifact routes require the same service-specific bearer Token, contain no Token in
  their URL, scope every object to the authenticated principal, and expire temporary data;
- download rejects private/reserved destinations and enforces file-size bounds;
- missing and invalid Tokens receive 401;
- Tailscale Serve exposes dedicated private HTTPS ports and Funnel is off for all of them.

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
5. Verify the doctor reports the expected profile, every managed Skill, both required MCP
   handshakes, every configured optional MCP handshake, and all declared tools. Then verify a known
   shared-library project, a current web query, and one non-billable health call for each newly
   configured capability. Run a paid generation only when the user requests it.

## Updates and rollback

Run `install.sh` again to update the saved profile's SOUL, manifest-managed common Skills, and any
newly ready MCP entries. Each run backs up previous managed content under
`/var/minis/backups/openminis-bootstrap-TIMESTAMP-PID`. Independently installed personal Skills remain
unchanged.
