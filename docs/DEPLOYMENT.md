# Deployment

## Target architecture

```text
GitHub public repo ──imports──> OpenMinis skills + SOUL
                                     │
                                     ├── iCloud sync to the user's devices
                                     │
                                     ├── Tailnet HTTPS ──> OpenViking MCP bridge
                                     │                         └── 127.0.0.1:1933
                                     │
                                     └── Tailnet HTTPS ──> optional toolbox MCP
                                                               └── approved server tools
```

OpenMinis is the client and lightweight control plane. Oracle remains the production OpenClaw runtime and the authoritative OpenViking writer host. SG endpoint-local memory and host-bound skills are not copied into this repository.

## Phase 1: GitHub

Publish this sanitized repository as public. The OpenMinis GitHub importer uses the unauthenticated GitHub Contents API and recursively downloads sibling files under a skill directory. Public import therefore needs no token.

Do not publish raw OpenClaw configuration, workspace memory, `.env` files, Bitwarden item IDs, hostnames, private Tailnet DNS names, or copied proprietary skill bundles.

## Phase 2: OpenViking MCP on Oracle

Run an MCP bridge on loopback, for example `127.0.0.1:1940`, and connect it only to the local OpenViking service at `127.0.0.1:1933`.

Expose only a narrow tool allowlist:

- recall/search/find
- read/get/list within approved memory roots
- remember/write with fixed account and user identity
- health

Do not expose arbitrary filesystem paths, shell execution, deletion, account switching, service configuration, or bulk export. Tag writes with source `openminis` and timestamp. Redact arguments in logs.

Publish the loopback MCP service to the Tailnet with Tailscale Serve. On the currently verified Tailscale CLI, the basic form is:

```sh
tailscale serve --bg 1940
tailscale serve status
```

If the host already uses HTTPS 443, create a dedicated Tailscale service or an explicit path using `--service` or `--set-path`; do not overwrite the existing Serve configuration. Never use `tailscale funnel`.

Recommended endpoint shape:

```text
https://OPENVIKING_TAILNET_NAME/mcp
```

Protect the bridge with both Tailnet ACLs and a scoped bearer token. The token grants only the MCP allowlist, not OpenViking administration.

## Phase 3: optional toolbox MCP

Expose existing server skills through a second narrow MCP gateway rather than copying their runtimes to the phone. Start read-only with research/search/document-inspection tools. Keep these absent or confirmation-gated:

- trading and cash movement
- infrastructure mutation
- messaging sends
- credential access
- arbitrary shell
- destructive filesystem operations

The toolbox must dispatch to named tools with schemas and timeouts. It must not accept a free-form shell command.

## Phase 4: OpenMinis

1. Install Tailscale on the device and verify the Tailnet endpoint opens.
2. Add environment variables from `docs/ENVIRONMENT.md`.
3. Import the bootstrap skill URL from the repository README.
4. Run the bootstrap with `--with-soul --configure-mcp`.
5. Run `doctor.sh` and verify both the MCP handshake and a narrow recall query.
6. Write one test memory with a unique non-sensitive marker, recall it, then remove it through an approved administrative path if cleanup is required.
7. Confirm SOUL and the full skill bundles appear on a second device through iCloud sync.

## Rollback

Each bootstrap run stores previous managed skills and SOUL under `/var/minis/backups/openminis-bootstrap-TIMESTAMP`. Restore by copying the desired backup into `/var/minis/skills` or `/var/minis/memory/SOUL.md`, then finish the current chat so OpenMinis rescans the filesystem.
