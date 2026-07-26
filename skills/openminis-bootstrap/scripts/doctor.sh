#!/bin/sh
set -u

status=0
minis_root="${OPENMINIS_ROOT:-/var/minis}"

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; status=1; }
skip() { printf 'SKIP  %s\n' "$1"; }

for skill in openminis-bootstrap openviking-memory remote-toolbox research-router investor-research pharma-research critical-review; do
  if [ -s "$minis_root/skills/$skill/SKILL.md" ]; then
    pass "skill $skill"
  else
    fail "skill $skill is missing"
  fi
done

if [ -s "$minis_root/memory/SOUL.md" ]; then
  pass 'SOUL.md exists'
else
  fail 'SOUL.md is missing'
fi

if printenv OPENVIKING_MCP_URL >/dev/null 2>&1; then
  pass 'OPENVIKING_MCP_URL is set'
else
  fail 'OPENVIKING_MCP_URL is missing'
fi

if printenv OPENVIKING_MCP_TOKEN >/dev/null 2>&1; then
  pass 'OPENVIKING_MCP_TOKEN is set'
else
  skip 'OPENVIKING_MCP_TOKEN is optional'
fi

if command -v minis-mcp-cli >/dev/null 2>&1; then
  pass 'minis-mcp-cli exists'
  if minis-mcp-cli ping openviking >/dev/null 2>&1; then
    pass 'OpenViking MCP handshake'
  else
    fail 'OpenViking MCP handshake failed'
  fi
  if printenv OPENCLAW_MCP_URL >/dev/null 2>&1; then
    if minis-mcp-cli ping toolbox >/dev/null 2>&1; then
      pass 'toolbox MCP handshake'
    else
      fail 'toolbox MCP handshake failed'
    fi
  else
    skip 'toolbox MCP is optional'
  fi
else
  fail 'minis-mcp-cli is missing'
fi

exit "$status"
