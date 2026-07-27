#!/bin/sh
set -eu

repo="${OPENMINIS_BOOTSTRAP_REPO:-Murphisensei/openminis-bootstrap}"
ref="${OPENMINIS_BOOTSTRAP_REF:-main}"
minis_root="${OPENMINIS_ROOT:-/var/minis}"
configure_mcp=0
profile=""
core_skills="openminis-bootstrap openviking-memory"

usage() {
  printf '%s\n' \
    'Usage: install.sh --profile freddy|yurik [--configure-mcp]' \
    '' \
    'Installs the selected Taco SOUL, agent skill, and OpenViking memory link.' \
    'After first setup, --profile may be omitted to reuse the saved profile.' \
    '--configure-mcp adds the Tailnet memory MCP using $$VARNAME placeholders.'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --configure-mcp) configure_mcp=1 ;;
    --profile)
      shift
      if [ "$#" -eq 0 ]; then
        printf '%s\n' 'Missing value for --profile' >&2
        usage >&2
        exit 2
      fi
      profile="$1"
      ;;
    --profile=*) profile="${1#--profile=}" ;;
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

profile_state_dir="$minis_root/config/openminis-bootstrap"
profile_state="$profile_state_dir/profile"
if [ -z "$profile" ] && [ -s "$profile_state" ]; then
  profile="$(sed -n '1p' "$profile_state")"
fi
case "$profile" in
  freddy|yurik) ;;
  '')
    printf '%s\n' 'Choose a client profile: --profile freddy or --profile yurik' >&2
    exit 2
    ;;
  *)
    printf 'Unsupported profile: %s\n' "$profile" >&2
    exit 2
    ;;
esac

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
profile_root="$source_root/profiles/$profile"
test -f "$profile_root/SOUL.md"
test -f "$profile_root/skills/openminis-agent/SKILL.md"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_root="$minis_root/backups/openminis-bootstrap-$timestamp"
mkdir -p \
  "$minis_root/skills" \
  "$minis_root/memory" \
  "$profile_state_dir" \
  "$backup_root/skills" \
  "$backup_root/memory" \
  "$backup_root/config"

installed=0
install_skill() {
  skill_name="$1"
  source_skill="$2"
  test -d "$source_skill"
  test -f "$source_skill/SKILL.md"
  destination="$minis_root/skills/$skill_name"
  case "$destination" in
    "$minis_root"/skills/*) ;;
    *) printf 'Unsafe skill destination: %s\n' "$destination" >&2; exit 1 ;;
  esac
  if [ -d "$destination" ]; then
    mv "$destination" "$backup_root/skills/$skill_name"
  fi
  mkdir -p "$destination"
  cp -R "$source_skill"/. "$destination"/
  if [ -d "$destination/scripts" ]; then
    chmod +x "$destination"/scripts/*.sh 2>/dev/null || true
  fi
  installed=$((installed + 1))
}

for skill_name in $core_skills; do
  install_skill "$skill_name" "$source_root/skills/$skill_name"
done
install_skill openminis-agent "$profile_root/skills/openminis-agent"

soul_destination="$minis_root/memory/SOUL.md"
if [ -f "$soul_destination" ]; then
  cp "$soul_destination" "$backup_root/memory/SOUL.md"
fi
cp "$profile_root/SOUL.md" "$soul_destination"

if [ -f "$profile_state" ]; then
  cp "$profile_state" "$backup_root/config/profile"
fi
printf '%s\n' "$profile" > "$profile_state"

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
printf 'Activated Taco profile: %s\n' "$profile"
printf 'Updated SOUL and openminis-agent; unrelated skills were left unchanged.\n'
printf '%s\n' 'OpenMinis may need the current turn to finish before new skills appear.'
