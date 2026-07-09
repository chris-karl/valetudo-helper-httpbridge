#!/usr/bin/env sh
# Decide whether a release should happen: emits release/tag outputs.
# Automatic mode ($BUMP empty or "auto") releases when all commits since
# the last tag are authored by Dependabot (version bump commits from a
# previous auto-release run are fine too). Manual mode ($BUMP set to a
# version component) releases the current state unconditionally — the
# human who dispatched the run already decided that.
# The tag to release comes from compute-next-tag.sh.
# Requires a checkout with full history and tags.
set -eu

# When the dispatcher pinned the commit they expect to release
# ($EXPECTED_COMMIT), refuse to run on anything else: commits that
# landed on main after the user reviewed it must not slip into the
# release unnoticed. Abbreviated SHAs are fine.
if [ -n "${EXPECTED_COMMIT:-}" ]; then
  expected=$(echo "$EXPECTED_COMMIT" | tr 'A-F' 'a-f')
  case $expected in
    *[!0-9a-f]*)
      echo "::error::Expected commit \"$EXPECTED_COMMIT\" is not a hexadecimal commit SHA"
      exit 1
      ;;
  esac
  if [ "${#expected}" -lt 7 ]; then
    echo "::error::Expected commit \"$EXPECTED_COMMIT\" is too short to identify a commit, use at least 7 characters"
    exit 1
  fi
  head=$(git rev-parse HEAD)
  case $head in
    "$expected"*) ;;
    *)
      echo "::error::This run is for commit $head, not for the expected $expected — main moved or points elsewhere. Nothing was released; re-run with the current commit to release it."
      exit 1
      ;;
  esac
fi

if [ "${BUMP:-auto}" != "auto" ]; then
  # Refuse to cut a second release for a commit that already has one
  # (e.g. an accidental double dispatch — after a release, main's tip
  # is exactly the tagged version bump commit).
  released_as=$(git tag -l 'v*' --points-at HEAD)
  if [ -n "$released_as" ]; then
    echo "::error::Commit $(git rev-parse HEAD) is already released as $released_as"
    exit 1
  fi
  if ! next_tag=$("$(dirname "$0")/../compute-next-tag.sh"); then
    # The captured output holds the ::error:: diagnostic.
    echo "$next_tag"
    exit 1
  fi
  echo "Releasing $next_tag (manually requested $BUMP bump)"
  {
    echo "release=true"
    echo "tag=$next_tag"
  } >> "$GITHUB_OUTPUT"
  exit 0
fi

last_tag=$(git describe --tags --abbrev=0)
# Two steps instead of piping git into sort, so that a git failure
# aborts the script (set -e cannot see the left side of a pipe).
author_emails=$(git log "$last_tag"..HEAD --format='%ae')
if [ -z "$author_emails" ]; then
  echo "No new commits since $last_tag, nothing to release"
  echo "release=false" >> "$GITHUB_OUTPUT"
  exit 0
fi
# github-actions[bot] authors the version bump commits; one can sit
# untagged on main when a previous run failed after pushing it.
unexpected=$(printf '%s\n' "$author_emails" | sort -u | grep -Fxv \
  -e '49699333+dependabot[bot]@users.noreply.github.com' \
  -e '41898282+github-actions[bot]@users.noreply.github.com' || true)
if [ -n "$unexpected" ]; then
  echo "Commits since $last_tag are not exclusively authored by Dependabot, skipping auto-release. Unexpected authors:"
  echo "$unexpected"
  echo "release=false" >> "$GITHUB_OUTPUT"
  exit 0
fi
# Changes that only touch the CI setup do not alter the shipped
# binaries; hold the release until something outside .github/ changes.
changed_files=$(git diff --name-only "$last_tag"..HEAD)
outside_ci=$(printf '%s\n' "$changed_files" | grep -v '^\.github/' || true)
if [ -z "$outside_ci" ]; then
  echo "Commits since $last_tag only touch .github/, nothing to release"
  echo "release=false" >> "$GITHUB_OUTPUT"
  exit 0
fi
if ! next_tag=$(BUMP=patch "$(dirname "$0")/../compute-next-tag.sh"); then
  # The captured output holds the ::error:: diagnostic.
  echo "$next_tag"
  exit 1
fi
echo "Releasing $next_tag"
{
  echo "release=true"
  echo "tag=$next_tag"
} >> "$GITHUB_OUTPUT"
