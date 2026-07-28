#!/bin/sh
set -eu

repo="${OPENMINIS_BOOTSTRAP_REPO:-Murphisensei/openminis-bootstrap}"
ref="${OPENMINIS_BOOTSTRAP_REF:-main}"
minis_root="${OPENMINIS_ROOT:-/var/minis}"
configure_mcp=0
profile=""

usage() {
  printf '%s\n' \
    'Usage: install.sh --profile freddy|yurik [--configure-mcp]' \
    '' \
    'Installs the selected Taco SOUL plus all common manifest-managed skills and MCP links.' \
    'After first setup, --profile may be omitted to reuse the saved profile.' \
    '--configure-mcp requires every mandatory MCP variable during first setup.' \
    'Normal updates configure any MCP whose environment-variable pair is already present.'
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
manifest_source="$source_root/manifest.json"
manifest_tool="$source_root/skills/openminis-bootstrap/scripts/manifest_cli.py"
test -f "$manifest_source"
test -f "$manifest_tool"

# OpenMinis uses Alpine. Install the MCP HTTP runtime only on first setup;
# subsequent updates take the fast path when both imports are already present.
if ! command -v python3 >/dev/null 2>&1 || \
   ! python3 -c 'import httpx' >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then
    printf '%s\n' 'Installing first-run Python MCP dependencies.'
    apk add --no-cache python3 py3-httpx
  fi
fi
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 is required to validate the bootstrap manifest; install it and rerun.\n' >&2
  exit 1
fi
if ! python3 -c 'import httpx' >/dev/null 2>&1; then
  printf 'Python httpx is required by minis-mcp-daemon; install it and rerun.\n' >&2
  exit 1
fi
python3 "$manifest_tool" validate "$manifest_source" >/dev/null
core_skills="$(python3 "$manifest_tool" core-skills "$manifest_source")"
mcp_tsv="$tmp/mcp.tsv"
python3 "$manifest_tool" mcp-tsv "$manifest_source" > "$mcp_tsv"

if [ "$configure_mcp" -eq 1 ]; then
  missing=0
  for variable in $(python3 "$manifest_tool" required-env "$manifest_source"); do
    variable_value="$(printenv "$variable" 2>/dev/null || true)"
    if [ -z "$variable_value" ]; then
      printf 'Missing required variable: %s\n' "$variable" >&2
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
fi

profile_root="$source_root/profiles/$profile"
test -f "$profile_root/SOUL.md"
test -f "$profile_root/skills/openminis-agent/SKILL.md"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_root="$minis_root/backups/openminis-bootstrap-$timestamp-$$"
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
manifest_state="$profile_state_dir/manifest.json"
if [ -f "$manifest_state" ]; then
  cp "$manifest_state" "$backup_root/config/manifest.json"
fi
cp "$manifest_source" "$manifest_state"

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

if command -v minis-mcp-cli >/dev/null 2>&1; then
  while IFS="$(printf '\t')" read -r name url_var token_var required note; do
    test -n "$name" || continue
    url_value="$(printenv "$url_var" 2>/dev/null || true)"
    token_value="$(printenv "$token_var" 2>/dev/null || true)"
    if [ -n "$url_value" ] && [ -n "$token_value" ]; then
      configure_http_mcp "$name" "$url_var" "$token_var" "$note"
    else
      printf 'Skipped MCP %s; set %s and %s, then rerun bootstrap.\n' \
        "$name" "$url_var" "$token_var"
    fi
  done < "$mcp_tsv"
elif [ "$configure_mcp" -eq 1 ]; then
    printf 'minis-mcp-cli is unavailable; MCP entries were not configured.\n' >&2
    exit 1
else
  printf 'minis-mcp-cli is unavailable; skipped MCP refresh.\n' >&2
fi

printf 'Installed %s managed skills.\n' "$installed"
printf 'Activated Taco profile: %s\n' "$profile"
printf 'Updated SOUL and openminis-agent; unrelated skills were left unchanged.\n'
printf '%s\n' 'OpenMinis may need the current turn to finish before new skills appear.'
