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

for skill in openminis-bootstrap openviking-memory openminis-agent; do
  if [ -s "$minis_root/skills/$skill/SKILL.md" ]; then
    pass "skill $skill"
  else
    fail "skill $skill is missing"
  fi
done

if [ -s "$minis_root/memory/SOUL.md" ] && \
   grep -q '^name: "Taco"$' "$minis_root/memory/SOUL.md"; then
  pass 'Taco SOUL'
else
  fail 'Taco SOUL is missing or invalid'
fi

if printenv OPENVIKING_MCP_URL >/dev/null 2>&1; then
  pass 'OPENVIKING_MCP_URL is set'
else
  fail 'OPENVIKING_MCP_URL is missing'
fi

if printenv OPENVIKING_MCP_TOKEN >/dev/null 2>&1; then
  pass 'OPENVIKING_MCP_TOKEN is set'
else
  fail 'OPENVIKING_MCP_TOKEN is missing'
fi

if command -v minis-mcp-cli >/dev/null 2>&1; then
  pass 'minis-mcp-cli exists'
  ping_output="$(minis-mcp-cli ping openviking 2>&1)"
  ping_status=$?
  if [ "$ping_status" -ne 0 ] && printf '%s' "$ping_output" | grep -q 'NO_DAEMON'; then
    minis-mcp-cli shutdown >/dev/null 2>&1 || true
    rm -f \
      /tmp/minis-mcp-daemon.lock \
      /tmp/minis-mcp-daemon.pid \
      /tmp/minis-mcp-daemon.port
    ping_output="$(minis-mcp-cli ping openviking 2>&1)"
    ping_status=$?
  fi
  if [ "$ping_status" -eq 0 ]; then
    pass 'OpenViking MCP handshake'
    tools="$(minis-mcp-cli tools openviking 2>/dev/null || true)"
    for tool in memory_search memory_read memory_remember health; do
      if printf '%s' "$tools" | grep -q "$tool"; then
        pass "OpenViking tool $tool"
      else
        fail "OpenViking tool $tool is missing"
      fi
    done
  else
    fail 'OpenViking MCP handshake failed'
  fi
else
  fail 'minis-mcp-cli is missing'
fi

exit "$status"
