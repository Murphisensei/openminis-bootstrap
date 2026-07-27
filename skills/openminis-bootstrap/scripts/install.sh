#!/bin/sh
set -eu

repo="${OPENMINIS_BOOTSTRAP_REPO:-Murphisensei/openminis-bootstrap}"
ref="${OPENMINIS_BOOTSTRAP_REF:-main}"
minis_root="${OPENMINIS_ROOT:-/var/minis}"
configure_mcp=0
managed_skills="openminis-bootstrap openviking-memory"

usage() {
  printf '%s\n' \
    'Usage: install.sh [--configure-mcp]' \
    '' \
    'Installs only the bootstrap and OpenViking memory skills.' \
    '--configure-mcp adds the Tailnet memory MCP using $$VARNAME placeholders.'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --configure-mcp) configure_mcp=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$repo" in
  */*) ;;
  *) printf 'OPENMINIS_BOOTSTRAP_REPO must be owner/repository\n' >&2; exit 2 ;;
esac
case "$minis_root" in
  /*) ;;
  *) printf 'OPENMINIS_ROOT must be an absolute path\n' >&2; exit 2 ;;
esac
if [ "$minis_root" = / ]; then
  printf 'OPENMINIS_ROOT cannot be /\n' >&2
  exit 2
fi

tmp="$(mktemp -d /tmp/openminis-bootstrap.XXXXXX)"
cleanup() {
  case "$tmp" in
    /tmp/openminis-bootstrap.*) rm -rf "$tmp" ;;
  esac
}
trap cleanup EXIT HUP INT TERM

archive="$tmp/repository.tar.gz"
url="https://codeload.github.com/$repo/tar.gz/$ref"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$archive"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$archive" "$url"
else
  printf 'Neither curl nor wget is available.\n' >&2
  exit 1
fi

tar -xzf "$archive" -C "$tmp"
source_root="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
test -n "$source_root"
test -d "$source_root/skills"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_root="$minis_root/backups/openminis-bootstrap-$timestamp"
mkdir -p "$minis_root/skills" "$backup_root/skills"

installed=0
for skill_name in $managed_skills; do
  source_skill="$source_root/skills/$skill_name"
  test -d "$source_skill"
  test -f "$source_skill/SKILL.md"
  destination="$minis_root/skills/$skill_name"
  case "$destination" in
    "$minis_root"/skills/*) ;;
    *) printf 'Unsafe skill destination: %s\n' "$destination" >&2; exit 1 ;;
  esac
  if [ -d "$destination" ]; then
    cp -R "$destination" "$backup_root/skills/$skill_name"
  fi
  mkdir -p "$destination"
  cp -R "$source_skill"/. "$destination"/
  if [ -d "$destination/scripts" ]; then
    chmod +x "$destination"/scripts/*.sh 2>/dev/null || true
  fi
  installed=$((installed + 1))
done

configure_http_mcp() {
  name="$1"
  url_var="$2"
  token_var="$3"
  note="$4"
  url_value="$(printenv "$url_var" 2>/dev/null || true)"
  token_value="$(printenv "$token_var" 2>/dev/null || true)"
  if [ -z "$url_value" ]; then
    printf 'Missing required variable: %s\n' "$url_var" >&2
    return 1
  fi
  if [ -z "$token_value" ]; then
    printf 'Missing required variable: %s\n' "$token_var" >&2
    return 1
  fi
  minis-mcp-cli add --name "$name" --url "\$\$$url_var" \
    --header "Authorization: Bearer \$\$$token_var" --note "$note" >/dev/null
  printf 'Configured MCP %s with environment placeholders.\n' "$name"
}

if [ "$configure_mcp" -eq 1 ]; then
  if ! command -v minis-mcp-cli >/dev/null 2>&1; then
    printf 'minis-mcp-cli is unavailable; MCP entries were not configured.\n' >&2
    exit 1
  fi
  configure_http_mcp openviking OPENVIKING_MCP_URL OPENVIKING_MCP_TOKEN \
    'Tailnet OpenViking durable memory; recall first, write only stable facts.'
fi

printf 'Installed %s managed skills.\n' "$installed"
printf 'SOUL and unrelated skills were left unchanged.\n'
printf '%s\n' 'OpenMinis may need the current turn to finish before new skills appear.'
