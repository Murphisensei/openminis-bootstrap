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
export BOOTSTRAP_TEST_PYTHON="$(command -v python3)"
export PATH="$repo_root/tests/fixtures:$PATH"
export OPENMINIS_BOOTSTRAP_REPO=test/repository
export OPENMINIS_BOOTSTRAP_REF=main
export OPENVIKING_MCP_URL=https://memory.invalid/mcp
export OPENVIKING_MCP_TOKEN=test-memory-token
export WEBSEARCH_MCP_URL=https://search.invalid/mcp
export WEBSEARCH_MCP_TOKEN=test-search-token
export FIRECRAWL_MCP_URL=https://firecrawl.invalid/mcp
export FIRECRAWL_MCP_TOKEN=test-firecrawl-token
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
export DASHI_MCP_URL=https://dashi.invalid/mcp
export DASHI_MCP_TOKEN=test-dashi-token

minis_root="$test_root/minis"
export OPENMINIS_ROOT="$minis_root"
sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" \
  --profile freddy --configure-mcp > "$test_root/install-first.log"

test -s "$minis_root/memory/SOUL.md"
test -s "$minis_root/config/openminis-bootstrap/soul-native.sha256"
cmp -s "$repo_root/profiles/freddy/SOUL.md" "$minis_root/memory/SOUL.md"
test -s "$minis_root/skills/openminis-bootstrap/SKILL.md"
test -s "$minis_root/skills/openviking-memory/SKILL.md"
test -s "$minis_root/skills/web-search/SKILL.md"
test -s "$minis_root/skills/firecrawl-web/SKILL.md"
test -s "$minis_root/skills/finance-lookup/SKILL.md"
test -s "$minis_root/skills/biomedical-lookup/SKILL.md"
test -s "$minis_root/skills/travel-lookup/SKILL.md"
test -s "$minis_root/skills/company-lookup/SKILL.md"
test -s "$minis_root/skills/meeting-transcription/SKILL.md"
test -s "$minis_root/skills/image-studio/SKILL.md"
test -s "$minis_root/skills/video-generation/SKILL.md"
test -s "$minis_root/skills/pdf-reader/SKILL.md"
test -s "$minis_root/skills/wechat-article/SKILL.md"
grep -Fq 'MUST use for every mp.weixin.qq.com URL' "$minis_root/skills/wechat-article/SKILL.md"
grep -Fq 'mcp_job.py wechat-read-start' "$minis_root/skills/wechat-article/SKILL.md"
grep -Fq 'WECHAT_SOURCE_READY' "$minis_root/skills/wechat-article/SKILL.md"
grep -Fq 'Do not handle a WeChat article inside this general document Skill' "$minis_root/skills/pdf-reader/SKILL.md"
if grep -Fq 'mcp_job.py wechat-read-start' "$minis_root/skills/pdf-reader/SKILL.md"; then
  printf '%s\n' 'pdf-reader unexpectedly duplicates the WeChat execution flow' >&2
  exit 1
fi
grep -Fq 'always route it to wechat-article first' "$minis_root/skills/web-search/SKILL.md"
grep -Fq 'Highest-priority URL route' "$minis_root/skills/openminis-agent/SKILL.md"
grep -Fq 'WECHAT_SOURCE_READY' "$minis_root/skills/openminis-agent/SKILL.md"
grep -Fq '第一项工具动作必须使用 `wechat-article`' "$minis_root/memory/SOUL.md"
test -s "$minis_root/skills/file-download/SKILL.md"
test -s "$minis_root/skills/dashi/SKILL.md"
test -s "$minis_root/skills/openminis-agent/SKILL.md"
test -s "$minis_root/config/openminis-bootstrap/manifest.json"
grep -Fq 'add --name openviking --url $$OPENVIKING_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name websearch --url $$WEBSEARCH_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name firecrawl --url $$FIRECRAWL_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name meeting --url $$MEETING_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name image --url $$IMAGE_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name video --url $$VIDEO_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name pdfreader --url $$PDF_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name download --url $$DOWNLOAD_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'add --name dashi --url $$DASHI_MCP_URL' "$BOOTSTRAP_TEST_CALL_LOG"
grep -Fq 'minis-config set-batch soul.name soul.style soul.lang soul.body' \
  "$BOOTSTRAP_TEST_CALL_LOG"

sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" > "$test_root/install-update.log"
find "$minis_root/backups" -mindepth 1 -maxdepth 1 -type d | grep -q .
test "$(grep -Fc 'minis-config set-batch' "$BOOTSTRAP_TEST_CALL_LOG")" -eq 1

if ! sh "$minis_root/skills/openminis-bootstrap/scripts/doctor.sh" \
  --profile freddy > "$test_root/doctor.log"; then
  cat "$test_root/doctor.log" >&2
  exit 1
fi
grep -Fq 'PASS  skill web-search' "$test_root/doctor.log"
grep -Fq 'PASS  skill wechat-article' "$test_root/doctor.log"
grep -Fq 'PASS  websearch MCP handshake' "$test_root/doctor.log"
grep -Fq 'PASS  websearch tool web_search' "$test_root/doctor.log"
grep -Fq 'PASS  websearch tool market_data' "$test_root/doctor.log"
grep -Fq 'PASS  websearch tool drug_search' "$test_root/doctor.log"
grep -Fq 'PASS  websearch tool aviation_search' "$test_root/doctor.log"
grep -Fq 'PASS  firecrawl MCP handshake' "$test_root/doctor.log"
grep -Fq 'PASS  firecrawl tool firecrawl_scrape' "$test_root/doctor.log"
grep -Fq 'PASS  firecrawl tool firecrawl_research_search_github' "$test_root/doctor.log"
grep -Fq 'PASS  openviking tool memory_search' "$test_root/doctor.log"
grep -Fq 'PASS  meeting tool start_transcription' "$test_root/doctor.log"
grep -Fq 'PASS  image tool start_edit' "$test_root/doctor.log"
grep -Fq 'PASS  video tool start_generation' "$test_root/doctor.log"
grep -Fq 'PASS  pdfreader tool start_read' "$test_root/doctor.log"
grep -Fq 'PASS  download tool start_download' "$test_root/doctor.log"
grep -Fq 'PASS  dashi tool start_iching_reading' "$test_root/doctor.log"

printf '%s\n' '# stale shell edit' >> "$minis_root/memory/SOUL.md"
if sh "$minis_root/skills/openminis-bootstrap/scripts/doctor.sh" \
  --profile freddy > "$test_root/doctor-stale.log"; then
  printf '%s\n' 'doctor unexpectedly accepted a stale SOUL' >&2
  exit 1
fi
grep -Fq 'FAIL  Taco SOUL is stale or was not saved through the OpenMinis native API' \
  "$test_root/doctor-stale.log"
sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" > "$test_root/install-repair.log"
cmp -s "$repo_root/profiles/freddy/SOUL.md" "$minis_root/memory/SOUL.md"
test "$(grep -Fc 'minis-config set-batch' "$BOOTSTRAP_TEST_CALL_LOG")" -eq 2
sh "$minis_root/skills/openminis-bootstrap/scripts/doctor.sh" \
  --profile freddy > "$test_root/doctor-repaired.log"
grep -Fq 'PASS  Taco SOUL content and native-save state' "$test_root/doctor-repaired.log"

# Simulate a device upgraded from the filesystem-only installer: the SOUL
# bytes are current, but there is no proof that SoulStore.save() ran.
rm -f "$minis_root/config/openminis-bootstrap/soul-native.sha256"
sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" > "$test_root/install-legacy-repair.log"
test "$(grep -Fc 'minis-config set-batch' "$BOOTSTRAP_TEST_CALL_LOG")" -eq 3
sh "$minis_root/skills/openminis-bootstrap/scripts/doctor.sh" \
  --profile freddy > "$test_root/doctor-legacy-repaired.log"
grep -Fq 'PASS  Taco SOUL content and native-save state' \
  "$test_root/doctor-legacy-repaired.log"

strict_root="$test_root/strict-missing"
export OPENMINIS_ROOT="$strict_root"
unset WEBSEARCH_MCP_TOKEN
if sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" \
  --profile freddy --configure-mcp > "$test_root/strict.log" 2>&1; then
  printf '%s\n' 'strict install unexpectedly accepted a missing variable' >&2
  exit 1
fi
test ! -e "$strict_root"

export WEBSEARCH_MCP_TOKEN=test-search-token
native_fail_root="$test_root/native-fail"
export OPENMINIS_ROOT="$native_fail_root"
export BOOTSTRAP_TEST_MINIS_CONFIG_FAIL=1
if sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" \
  --profile freddy > "$test_root/native-fail.log" 2>&1; then
  printf '%s\n' 'install unexpectedly accepted a failed native SOUL save' >&2
  exit 1
fi
test ! -e "$native_fail_root/config/openminis-bootstrap/soul-native.sha256"
test ! -e "$native_fail_root/skills/openminis-agent"
grep -Fq 'SOUL native save failed: minis-config permission is disabled.' \
  "$test_root/native-fail.log"
unset BOOTSTRAP_TEST_MINIS_CONFIG_FAIL

yurik_root="$test_root/yurik"
export OPENMINIS_ROOT="$yurik_root"
sh "$repo_root/skills/openminis-bootstrap/scripts/install.sh" \
  --profile yurik > "$test_root/yurik-install.log"
cmp -s "$repo_root/profiles/yurik/SOUL.md" "$yurik_root/memory/SOUL.md"
sh "$yurik_root/skills/openminis-bootstrap/scripts/doctor.sh" \
  --profile yurik > "$test_root/yurik-doctor.log"
grep -Fq 'PASS  client profile yurik' "$test_root/yurik-doctor.log"
grep -Fq 'PASS  Taco SOUL content and native-save state' "$test_root/yurik-doctor.log"

printf '%s\n' 'PASS  manifest-driven install, update, MCP registration, and doctor'
