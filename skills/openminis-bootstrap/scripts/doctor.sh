#!/bin/sh
set -u

status=0
minis_root="${OPENMINIS_ROOT:-/var/minis}"
profile=""

usage() {
  printf '%s\n' 'Usage: doctor.sh [--profile freddy|yurik]'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; status=1; }
profile_state="$minis_root/config/openminis-bootstrap/profile"
saved_profile=""
if [ -s "$profile_state" ]; then
  saved_profile="$(sed -n '1p' "$profile_state")"
fi
if [ -z "$profile" ]; then
  profile="$saved_profile"
fi
case "$profile" in
  freddy|yurik) ;;
  *) fail 'client profile is missing or invalid' ;;
esac
if [ -n "$saved_profile" ] && [ "$saved_profile" = "$profile" ]; then
  pass "client profile $profile"
else
  fail 'saved client profile does not match the requested profile'
fi

manifest_state="$minis_root/config/openminis-bootstrap/manifest.json"
manifest_tool="$minis_root/skills/openminis-bootstrap/scripts/manifest_cli.py"
manifest_ok=0
if command -v python3 >/dev/null 2>&1 && \
   [ -s "$manifest_state" ] && [ -s "$manifest_tool" ] && \
   python3 "$manifest_tool" validate "$manifest_state" >/dev/null 2>&1; then
  pass 'bootstrap manifest'
  manifest_ok=1
else
  fail 'bootstrap manifest is missing or invalid; rerun install.sh'
fi

if [ "$manifest_ok" -eq 1 ]; then
  for skill in $(python3 "$manifest_tool" core-skills "$manifest_state"); do
    if [ -s "$minis_root/skills/$skill/SKILL.md" ]; then
      pass "skill $skill"
    else
      fail "skill $skill is missing"
    fi
  done
fi
if [ -s "$minis_root/skills/openminis-agent/SKILL.md" ]; then
  pass 'skill openminis-agent'
else
  fail 'skill openminis-agent is missing'
fi

if [ -s "$minis_root/memory/SOUL.md" ] && \
   grep -q '^name: "Taco"$' "$minis_root/memory/SOUL.md"; then
  pass 'Taco SOUL'
else
  fail 'Taco SOUL is missing or invalid'
fi

if [ "$manifest_ok" -eq 1 ]; then
  for variable in $(python3 "$manifest_tool" required-env "$manifest_state"); do
    variable_value="$(printenv "$variable" 2>/dev/null || true)"
    if [ -n "$variable_value" ]; then
      pass "$variable is set"
    else
      fail "$variable is missing"
    fi
  done
fi

if command -v minis-mcp-cli >/dev/null 2>&1; then
  pass 'minis-mcp-cli exists'
  if [ "$manifest_ok" -eq 1 ]; then
    doctor_tsv="$(mktemp /tmp/openminis-bootstrap-doctor.XXXXXX)"
    python3 "$manifest_tool" doctor-tsv "$manifest_state" > "$doctor_tsv"
    while IFS="$(printf '\t')" read -r server required url_var token_var required_tools; do
      test -n "$server" || continue
      url_value="$(printenv "$url_var" 2>/dev/null || true)"
      token_value="$(printenv "$token_var" 2>/dev/null || true)"
      if [ -z "$url_value" ] || [ -z "$token_value" ]; then
        if [ "$required" -eq 1 ]; then
          fail "$server MCP configuration variables are missing"
        else
          pass "$server optional MCP is not configured"
        fi
        continue
      fi
      ping_output="$(minis-mcp-cli ping "$server" 2>&1)"
      ping_status=$?
      if [ "$ping_status" -ne 0 ] && printf '%s' "$ping_output" | grep -q 'NO_DAEMON'; then
        minis-mcp-cli shutdown >/dev/null 2>&1 || true
        rm -f \
          /tmp/minis-mcp-daemon.lock \
          /tmp/minis-mcp-daemon.pid \
          /tmp/minis-mcp-daemon.port
        ping_output="$(minis-mcp-cli ping "$server" 2>&1)"
        ping_status=$?
      fi
      if [ "$ping_status" -eq 0 ]; then
        pass "$server MCP handshake"
        tools="$(minis-mcp-cli tools "$server" --refresh 2>/dev/null || \
          minis-mcp-cli tools "$server" 2>/dev/null || true)"
        old_ifs="$IFS"
        IFS=,
        for tool in $required_tools; do
          if printf '%s' "$tools" | grep -q "$tool"; then
            pass "$server tool $tool"
          else
            fail "$server tool $tool is missing"
          fi
        done
        IFS="$old_ifs"
      else
        fail "$server MCP handshake failed"
      fi
    done < "$doctor_tsv"
    rm -f "$doctor_tsv"
  fi
else
  fail 'minis-mcp-cli is missing'
fi

exit "$status"
