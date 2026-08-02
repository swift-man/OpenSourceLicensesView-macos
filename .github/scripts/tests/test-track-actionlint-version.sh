#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tracker="$repository_root/.github/scripts/track-actionlint-version.sh"
test_directory="$(mktemp -d)"
mock_directory="$test_directory/bin"
mock_log="$test_directory/gh.log"
stderr_log="$test_directory/stderr.log"
stdout_log="$test_directory/stdout.log"
version_file="$test_directory/actionlint-version"
mkdir -p "$mock_directory"

cleanup() {
  local directory="${test_directory:?test directory must be set}"
  if [[ "$directory" == "/" ]]; then
    printf 'Refusing to remove root directory\n' >&2
    return 1
  fi
  rm -r -- "$directory"
}

trap cleanup EXIT

cat > "$mock_directory/gh" <<'MOCK'
#!/usr/bin/env bash

set -euo pipefail

command_name="${1:-} ${2:-}"
{
  printf 'COMMAND %s\n' "$command_name"
  printf 'ARGS'
  printf ' <%s>' "$@"
  printf '\n'
} >> "${GH_MOCK_LOG:?GH_MOCK_LOG is required}"

if [[ "$command_name" == "${GH_MOCK_FAIL_COMMAND:-}" ]]; then
  exit "${GH_MOCK_FAILURE_STATUS:-17}"
fi

case "$command_name" in
  "api repos/rhysd/actionlint/releases/latest")
    printf '%s\n' "${GH_MOCK_LATEST_TAG:?GH_MOCK_LATEST_TAG is required}"
    ;;
  "issue list")
    if [[ -n "${GH_MOCK_ISSUE_NUMBER:-}" ]]; then
      printf '[{"number":%s,"title":"ci: update actionlint"}]\n' \
        "$GH_MOCK_ISSUE_NUMBER"
    else
      printf '[]\n'
    fi
    ;;
  "issue close" | "issue edit")
    ;;
  "issue create")
    printf 'https://github.com/example/repository/issues/1\n'
    ;;
  *)
    printf 'Unexpected gh command: %s\n' "$command_name" >&2
    exit 99
    ;;
esac
MOCK
chmod +x "$mock_directory/gh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_log_contains() {
  local expected="$1"
  grep -Fq -- "$expected" "$mock_log" || fail "missing log entry: $expected"
}

assert_log_excludes() {
  local unexpected="$1"
  if grep -Fq -- "$unexpected" "$mock_log"; then
    fail "unexpected log entry: $unexpected"
  fi
}

run_tracker() {
  local expected_status="$1"
  local configured_version="$2"
  local latest_tag="$3"
  local issue_number="$4"
  local fail_command="${5:-}"
  local actual_status

  : > "$mock_log"
  printf '%s\n' "$configured_version" > "$version_file"

  set +e
  PATH="$mock_directory:$PATH" \
    ACTIONLINT_VERSION_FILE="$version_file" \
    GH_MOCK_FAIL_COMMAND="$fail_command" \
    GH_MOCK_FAILURE_STATUS=17 \
    GH_MOCK_ISSUE_NUMBER="$issue_number" \
    GH_MOCK_LATEST_TAG="$latest_tag" \
    GH_MOCK_LOG="$mock_log" \
    GITHUB_REPOSITORY="example/repository" \
    "$tracker" > "$stdout_log" 2> "$stderr_log"
  actual_status=$?
  set -e

  if [[ "$actual_status" -ne "$expected_status" ]]; then
    printf '%s\n' "--- stdout ---"
    cat "$stdout_log"
    printf '%s\n' "--- stderr ---" >&2
    cat "$stderr_log" >&2
    fail "expected status $expected_status, got $actual_status"
  fi
}

run_tracker 0 "1.7.12" "v1.7.12" ""
assert_log_contains "COMMAND api repos/rhysd/actionlint/releases/latest"
assert_log_contains "COMMAND issue list"
assert_log_excludes "COMMAND issue create"
assert_log_excludes "COMMAND issue edit"
assert_log_excludes "COMMAND issue close"

run_tracker 0 "1.7.12" "v1.7.12" "42"
assert_log_contains "COMMAND issue close"
assert_log_contains "<42>"

run_tracker 1 "1.7.11" "v1.7.12" ""
assert_log_contains "COMMAND issue create"
assert_log_contains "Configured: 1.7.11"
assert_log_contains "Latest: 1.7.12"
assert_log_excludes "COMMAND issue edit"

run_tracker 1 "1.7.11" "v1.7.12" "42"
assert_log_contains "COMMAND issue edit"
assert_log_contains "<42>"
assert_log_excludes "COMMAND issue create"

run_tracker 1 "1.7 .12" "v1.7.12" ""
if [[ -s "$mock_log" ]]; then
  fail "malformed configured version should fail before GitHub requests"
fi

run_tracker 1 "1.7.12" "not-a-version" ""
assert_log_contains "COMMAND api repos/rhysd/actionlint/releases/latest"
assert_log_excludes "COMMAND issue list"

run_tracker 17 "1.7.12" "v1.7.12" "" \
  "api repos/rhysd/actionlint/releases/latest"
assert_log_excludes "COMMAND issue list"

run_tracker 17 "1.7.12" "v1.7.12" "" "issue list"
assert_log_excludes "COMMAND issue close"

run_tracker 17 "1.7.12" "v1.7.12" "42" "issue close"
assert_log_contains "COMMAND issue close"

run_tracker 17 "1.7.11" "v1.7.12" "" "issue create"
assert_log_contains "COMMAND issue create"

run_tracker 17 "1.7.11" "v1.7.12" "42" "issue edit"
assert_log_contains "COMMAND issue edit"

: > "$mock_log"
set +e
(
  cd "$test_directory" || exit 1
  PATH="$mock_directory:$PATH" \
    GH_MOCK_LATEST_TAG="v1.7.12" \
    GH_MOCK_LOG="$mock_log" \
    GITHUB_REPOSITORY="example/repository" \
    "$tracker" > "$stdout_log" 2> "$stderr_log"
)
default_path_status=$?
set -e
if [[ "$default_path_status" -ne 0 ]]; then
  fail "tracker should find its default version file outside the repository"
fi
assert_log_contains "COMMAND issue list"

run_tracker 0 $'1.7.12\r' "v1.7.12" ""
assert_log_contains "COMMAND issue list"

printf 'PASS: 13 actionlint tracker scenarios\n'
