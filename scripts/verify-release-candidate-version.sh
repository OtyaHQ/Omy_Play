#!/usr/bin/env bash
set -euo pipefail

# Maintenance-only PRs (docs/CI housekeeping) must not consume an Android
# build number. App, dependency, platform and release-publication changes still
# require a new immutable version. If event/diff metadata is unavailable, fail
# closed and run the full release-candidate check.

EVENT_NAME="${GITHUB_EVENT_NAME:-}"
EVENT_PATH="${GITHUB_EVENT_PATH:-}"
DIFF_RANGE=""

if [[ -n "$EVENT_PATH" && -s "$EVENT_PATH" ]]; then
  if [[ "$EVENT_NAME" == "pull_request" ]]; then
    BASE_SHA="$(jq -r '.pull_request.base.sha // empty' "$EVENT_PATH")"
    HEAD_SHA="$(jq -r '.pull_request.head.sha // empty' "$EVENT_PATH")"
    if [[ "$BASE_SHA" =~ ^[0-9a-f]{40}$ && "$HEAD_SHA" =~ ^[0-9a-f]{40}$ ]]; then
      DIFF_RANGE="${BASE_SHA}...${HEAD_SHA}"
    fi
  elif [[ "$EVENT_NAME" == "push" ]]; then
    BEFORE_SHA="$(jq -r '.before // empty' "$EVENT_PATH")"
    AFTER_SHA="$(jq -r '.after // empty' "$EVENT_PATH")"
    if [[ "$BEFORE_SHA" =~ ^[0-9a-f]{40}$ && ! "$BEFORE_SHA" =~ ^0{40}$ && "$AFTER_SHA" =~ ^[0-9a-f]{40}$ ]]; then
      DIFF_RANGE="${BEFORE_SHA}...${AFTER_SHA}"
    fi
  fi
fi

if [[ -n "$DIFF_RANGE" ]]; then
  if ! CHANGED_FILES="$(git diff --name-only "$DIFF_RANGE")"; then
    echo "WARNING: cannot determine changed files; enforcing the release-candidate gate."
  else
    if ! grep -Eq '^(lib/|test/|integration_test/|assets/|android/|ios/|web/|windows/|linux/|macos/|pubspec\.yaml$|pubspec\.lock$|scripts/verify-android-release-apk\.sh$|scripts/verify-play-publication-contract\.sh$|\.github/workflows/(release\.yml|play-closed-test\.yml|release-mode-validation\.yml)$)' <<< "$CHANGED_FILES"; then
      echo "No application or release-publication inputs changed; skipping immutable app build-number gate."
      exit 0
    fi
    echo "Application or release-publication inputs changed; enforcing immutable build-number gate."
  fi
else
  echo "Change set cannot be established for event '$EVENT_NAME'; enforcing release-candidate gate."
fi

APP_VERSION="$(awk '/^version:[[:space:]]*/ { print $2; exit }' pubspec.yaml)"
[[ "$APP_VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([1-9][0-9]*)$ ]] || {
  echo "ERROR: pubspec version must look like 1.0.0+4; found '$APP_VERSION'"
  exit 1
}

PUBLIC_VERSION="${BASH_REMATCH[1]}"
BUILD_NUMBER="${BASH_REMATCH[2]}"
CURRENT_TAG="v${APP_VERSION}"

# Actions checkout uses fetch-depth: 0 in Otya release/test workflows, but keep
# this helper safe when invoked independently as well.
git fetch --tags --force --quiet || true

LATEST_BUILD=0
while IFS= read -r tag; do
  [ -n "$tag" ] || continue
  candidate="${tag#v${PUBLIC_VERSION}+}"
  [[ "$candidate" =~ ^[1-9][0-9]*$ ]] || continue
  if (( candidate > LATEST_BUILD )); then
    LATEST_BUILD="$candidate"
  fi
done < <(git tag --list "v${PUBLIC_VERSION}+*")

if git rev-parse -q --verify "refs/tags/${CURRENT_TAG}" >/dev/null; then
  echo "ERROR: ${CURRENT_TAG} already exists. Bump pubspec.yaml before adding new source changes."
  exit 1
fi

if (( BUILD_NUMBER <= LATEST_BUILD )); then
  echo "ERROR: candidate ${APP_VERSION} is not newer than latest published ${PUBLIC_VERSION}+${LATEST_BUILD}."
  exit 1
fi

printf 'Otya release candidate version OK: %s (latest immutable build: %s+%s)\n' \
  "$APP_VERSION" "$PUBLIC_VERSION" "$LATEST_BUILD"
