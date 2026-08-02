#!/usr/bin/env bash

set -euo pipefail

issue_title="ci: update actionlint"
repository="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
version_file="${ACTIONLINT_VERSION_FILE:-.github/actionlint-version}"
version_pattern='^[0-9]+\.[0-9]+\.[0-9]+$'

validate_version() {
  local label="$1"
  local version="$2"

  if [[ ! "$version" =~ $version_pattern ]]; then
    printf 'Invalid %s actionlint version: %s\n' "$label" "$version" >&2
    return 1
  fi
}

read_configured_version() {
  local configured_version
  configured_version="$(< "$version_file")"
  validate_version configured "$configured_version" || return 1
  printf '%s\n' "$configured_version"
}

fetch_latest_version() {
  local latest_tag
  local latest_version
  latest_tag="$(gh api repos/rhysd/actionlint/releases/latest --jq .tag_name)"
  latest_version="${latest_tag#v}"
  validate_version latest "$latest_version" || return 1
  printf '%s\n' "$latest_version"
}

find_issue_number() {
  gh issue list \
    --repo "$repository" \
    --state open \
    --search '"ci: update actionlint" in:title' \
    --json number,title \
    --jq 'map(select(.title == "ci: update actionlint")) | .[0].number // empty'
}

close_current_issue() {
  local issue_number="$1"
  local configured_version="$2"

  gh issue close "$issue_number" \
    --repo "$repository" \
    --comment "Resolved: actionlint ${configured_version} is the latest release."
}

upsert_update_issue() {
  local configured_version="$1"
  local latest_version="$2"
  local issue_number="$3"
  local issue_body

  printf -v issue_body \
    'CI pins an older actionlint release.\n\n- Configured: %s\n- Latest: %s\n\nUpdate .github/actionlint-version, then verify the release artifact attestation and CI checks.' \
    "$configured_version" \
    "$latest_version"

  if [[ -n "$issue_number" ]]; then
    gh issue edit "$issue_number" \
      --repo "$repository" \
      --body "$issue_body"
  else
    gh issue create \
      --repo "$repository" \
      --title "$issue_title" \
      --body "$issue_body"
  fi
}

main() {
  local configured_version
  local latest_version
  local issue_number

  configured_version="$(read_configured_version)" || return 1
  latest_version="$(fetch_latest_version)" || return 1
  issue_number="$(find_issue_number)" || return 1

  if [[ "$configured_version" == "$latest_version" ]]; then
    if [[ -n "$issue_number" ]]; then
      close_current_issue "$issue_number" "$configured_version" || return 1
    fi
    printf 'actionlint %s is current.\n' "$configured_version"
    return 0
  fi

  upsert_update_issue "$configured_version" "$latest_version" "$issue_number" || return 1
  printf 'actionlint %s is outdated; latest is %s.\n' \
    "$configured_version" \
    "$latest_version" >&2
  return 1
}

main "$@"
