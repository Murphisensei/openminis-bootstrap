#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test_root="$(mktemp -d /tmp/openminis-bootstrap-test.XXXXXX)"
cleanup() {
  case "$test_root" in
    /tmp/openminis-bootstrap-test.*) rm -rf "$test_root" ;;
  esac
}
trap cleanup EXIT HUP INT TERM

archive="$test_root/repository.tar.gz"
tar -czf "$archive" \
  --exclude .git \
  --exclude dist \
  --exclude __pycache__ \
  --transform 's,^\./,openminis-bootstrap-main/,' \
  -C "$repo_root" .

export BOOTSTRAP_TEST_ARCHIVE="$archive"
export BOOTSTRAP_TEST_CALL_LOG="$test_root/mcp-calls.log"
export PATH="$repo_root/tests/fixtures:$PATH"
export OPENMINIS_BOOTSTRAP_REPO=test/repository
export OPENMINIS_BOOTSTRAP_REF=main
export OPENVIKING_MCP_URL=https://memory.invalid/mcp
export OPENVIKING_MCP_TOKEN=test-memory-token
export WEBSEARCH_MCP_URL=https://search.invalid/mcp
export WEBSEARCH_MCP_TOKEN=test-search-token
export MEETING_MCP_URL=https://meeting.invalid/mcp
export MEETING_MCP_TOKEN=test-meeting-token
export IMAGE_MCP_URL=https://image.invalid/mcp
export IMAGE_MCP_TOKEN=test-image-token
export VIDEO_MCP_URL=https://video.invalid/mcp
export VIDEO_MCP_TOKEN=test-video-token
export PDF_MCP_URL=https://pdf.invalid/mcp
export PDF_MCP_TOKEN=test-pdf-token
export DOWNLOAD_MCP_URL=https://download.invalid/mcp
export DOWNLOAD_MCP_TOKEN=test-download-token

minis_root="$test_root/minis"
export OPENMINIS_ROOT="$minis_root"
sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" \
  --profile freddy --configure-mcp > "$test_root/install-first.log"

test -s "$minis_root/memory/SOUL.md"
test -s "$minis_root/skills/openminis-bootstrap/SKILL.md"
test -s "$minis_root/skills/openviking-memory/SKILL.md"
test -s "$minis_root/skills/web-search/SKILL.md"
test -s "$minis_root/skills/meeting-transcription/SKILL.md"
test -s "$minis_root/skills/image-studio/SKILL.md"
test -s "$minis_root/skills/video-generation/SKILL.md"
test -s "$minis_root/skills/pdf-reader/SKILL.md"
test -s "$minis_root/skills/file-download/SKILL.md"
test -s "$minis_root/skills/openminis-agent/SKILL.md"
test -s "$minis_root/config/openminis-bootstrap/manifest.json"
grep -Fq 'add --name openviking --url $$OPENVIKING_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name websearch --url $$WEBSEARCH_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name meeting --url $$MEETING_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name image --url $$IMAGE_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name video --url $$VIDEO_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name pdfreader --url $$PDF_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name download --url $$DOWNLOAD_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"

sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" > "$test_root/install-update.log"
find "$minis_root/backups" -mindepth 1 -maxdepth 1 -type d | grep -q .

sh "$minis_root/skills/openminis-bootstrap/scripts/doctor.sh" \
  --profile freddy > "$test_root/doctor.log"
grep -Fq 'PASS  skill web-search' "$test_root/doctor.log"
grep -Fq 'PASS  websearch MCP handshake' "$test_root/doctor.log"
grep -Fq 'PASS  websearch tool web_search' "$test_root/doctor.log"
grep -Fq 'PASS  openviking tool memory_search' "$test_root/doctor.log"
grep -Fq 'PASS  meeting tool start_transcription' "$test_root/doctor.log"
grep -Fq 'PASS  image tool start_edit' "$test_root/doctor.log"
grep -Fq 'PASS  video tool start_generation' "$test_root/doctor.log"
grep -Fq 'PASS  pdfreader tool start_read' "$test_root/doctor.log"
grep -Fq 'PASS  download tool start_download' "$test_root/doctor.log"

strict_root="$test_root/strict-missing"
export OPENMINIS_ROOT="$strict_root"
unset WEBSEARCH_MCP_TOKEN
if sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" \
  --profile freddy --configure-mcp > "$test_root/strict.log" 2>&1; then
  printf '%s\n' 'strict install unexpectedly accepted a missing variable' >&2
  exit 1
fi
test ! -e "$strict_root"

printf '%s\n' 'PASS  manifest-driven install, update, MCP registration, and doctor'
