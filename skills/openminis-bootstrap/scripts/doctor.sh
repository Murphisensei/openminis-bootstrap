#!/bin/sh
set -u

status=0
minis_root="${OPENMINIS_ROOT:-/var/minis}"

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; status=1; }
for skill in openminis-bootstrap openviking-memory; do
  if [ -s "$minis_root/skills/$skill/SKILL.md" ]; then
    pass "skill $skill"
  else
    fail "skill $skill is missing"
  fi
done

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
  if minis-mcp-cli ping openviking >/dev/null 2>&1; then
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
