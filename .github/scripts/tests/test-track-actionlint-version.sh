#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tracker="$repository_root/.github/scripts/track-actionlint-version.sh"
test_directory="$(mktemp -d)"
mock_directory="$test_directory/bin"
missing_gh_directory="$test_directory/missing-gh-bin"
missing_jq_directory="$test_directory/missing-jq-bin"
mock_log="$test_directory/gh.log"
stderr_log="$test_directory/stderr.log"
stdout_log="$test_directory/stdout.log"
version_file="$test_directory/actionlint-version"
test_count=0
mkdir -p "$mock_directory" "$missing_gh_directory" "$missing_jq_directory"

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

link_command() {
  local command_name="$1"
  local destination_directory="$2"
  local command_path

  command_path="$(command -v "$command_name")" \
    || fail "required test command is unavailable: $command_name"
  ln -s "$command_path" "$destination_directory/$command_name"
}

link_command bash "$missing_gh_directory"
link_command dirname "$missing_gh_directory"
link_command jq "$missing_gh_directory"
link_command bash "$missing_jq_directory"
link_command dirname "$missing_jq_directory"
ln -s "$mock_directory/gh" "$missing_jq_directory/gh"

run_test() {
  local test_name="$1"
  local test_function="$2"

  "$test_function"
  test_count=$((test_count + 1))
  printf 'ok %d - %s\n' "$test_count" "$test_name"
}

assert_file_contains() {
  local file="$1"
  local expected="$2"

  grep -Fq -- "$expected" "$file" \
    || fail "missing expected output: $expected"
}

assert_log_contains() {
  local expected="$1"
  assert_file_contains "$mock_log" "$expected"
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

run_tracker_with_restricted_path() {
  local missing_command="$1"
  local restricted_path="$2"
  local actual_status

  : > "$mock_log"
  set +e
  PATH="$restricted_path" \
    GITHUB_REPOSITORY="example/repository" \
    "$tracker" > "$stdout_log" 2> "$stderr_log"
  actual_status=$?
  set -e

  if [[ "$actual_status" -ne 1 ]]; then
    fail "missing $missing_command should return status 1, got $actual_status"
  fi
  assert_file_contains \
    "$stderr_log" \
    "Required command is unavailable: $missing_command"
  if [[ -s "$mock_log" ]]; then
    fail "missing $missing_command should fail before GitHub requests"
  fi
}

test_current_version_without_issue() {
  run_tracker 0 "1.7.12" "v1.7.12" ""
  assert_log_contains "COMMAND api repos/rhysd/actionlint/releases/latest"
  assert_log_contains "COMMAND issue list"
  assert_log_excludes "COMMAND issue create"
  assert_log_excludes "COMMAND issue edit"
  assert_log_excludes "COMMAND issue close"
}

test_current_version_closes_issue() {
  run_tracker 0 "1.7.12" "v1.7.12" "42"
  assert_log_contains "COMMAND issue close"
  assert_log_contains "<42>"
}

test_outdated_version_creates_issue() {
  run_tracker 1 "1.7.11" "v1.7.12" ""
  assert_log_contains "COMMAND issue create"
  assert_log_contains "Configured: 1.7.11"
  assert_log_contains "Latest: 1.7.12"
  assert_log_excludes "COMMAND issue edit"
}

test_outdated_version_edits_issue() {
  run_tracker 1 "1.7.11" "v1.7.12" "42"
  assert_log_contains "COMMAND issue edit"
  assert_log_contains "<42>"
  assert_log_excludes "COMMAND issue create"
}

test_malformed_configured_version() {
  run_tracker 1 "1.7 .12" "v1.7.12" ""
  if [[ -s "$mock_log" ]]; then
    fail "malformed configured version should fail before GitHub requests"
  fi
}

test_malformed_latest_version() {
  run_tracker 1 "1.7.12" "not-a-version" ""
  assert_log_contains "COMMAND api repos/rhysd/actionlint/releases/latest"
  assert_log_excludes "COMMAND issue list"
}

test_latest_release_failure() {
  run_tracker 17 "1.7.12" "v1.7.12" "" \
    "api repos/rhysd/actionlint/releases/latest"
  assert_log_excludes "COMMAND issue list"
}

test_issue_list_failure() {
  run_tracker 17 "1.7.12" "v1.7.12" "" "issue list"
  assert_log_excludes "COMMAND issue close"
}

test_issue_close_failure() {
  run_tracker 17 "1.7.12" "v1.7.12" "42" "issue close"
  assert_log_contains "COMMAND issue close"
}

test_issue_create_failure() {
  run_tracker 17 "1.7.11" "v1.7.12" "" "issue create"
  assert_log_contains "COMMAND issue create"
}

test_issue_edit_failure() {
  run_tracker 17 "1.7.11" "v1.7.12" "42" "issue edit"
  assert_log_contains "COMMAND issue edit"
}

test_default_version_path() {
  local default_path_status

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
}

test_crlf_version_file() {
  run_tracker 0 $'1.7.12\r' "v1.7.12" ""
  assert_log_contains "COMMAND issue list"
}

test_missing_gh() {
  run_tracker_with_restricted_path gh "$missing_gh_directory"
}

test_missing_jq() {
  run_tracker_with_restricted_path jq "$missing_jq_directory"
}

run_test "current version without an issue" test_current_version_without_issue
run_test "current version closes an issue" test_current_version_closes_issue
run_test "outdated version creates an issue" test_outdated_version_creates_issue
run_test "outdated version edits an issue" test_outdated_version_edits_issue
run_test "malformed configured version" test_malformed_configured_version
run_test "malformed latest version" test_malformed_latest_version
run_test "latest release request failure" test_latest_release_failure
run_test "issue list failure" test_issue_list_failure
run_test "issue close failure" test_issue_close_failure
run_test "issue create failure" test_issue_create_failure
run_test "issue edit failure" test_issue_edit_failure
run_test "default version path outside repository" test_default_version_path
run_test "CRLF version file" test_crlf_version_file
run_test "missing gh preflight" test_missing_gh
run_test "missing jq preflight" test_missing_jq

printf 'PASS: %d actionlint tracker scenarios\n' "$test_count"
