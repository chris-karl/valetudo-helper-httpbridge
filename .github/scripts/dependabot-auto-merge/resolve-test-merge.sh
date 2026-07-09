#!/usr/bin/env sh
# Resolve which test merge commit the build gate should run on, plus the
# gate parameters derived from it: whether the builds can be skipped
# (the PR only touches CI files) and the predicted release tag to stamp
# into the binaries so they double as the release assets.
# pull_request mode: take the merge straight from the event context.
# workflow_dispatch mode (retry after main moved): re-validate the PR and
# use its freshly computed test merge; exits without outputs when the
# retry has become moot, which makes the downstream jobs skip.
# Requires a checkout with tags for the tag prediction.
set -eu

if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  pr=$PR_EVENT_NUMBER
  merge_sha=$RUN_MERGE_SHA
  head_sha=$PR_EVENT_HEAD
else
  # GitHub recomputes the test merge asynchronously, hence the polling.
  mergeable=null
  json=
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    json=$(gh api "repos/$GH_REPO/pulls/$PR_DISPATCH")
    mergeable=$(echo "$json" | jq -r '.mergeable')
    [ "$mergeable" != "null" ] && break
    sleep 5
  done
  if [ "$(echo "$json" | jq -r '.user.login')" != "dependabot[bot]" ]; then
    echo "::error::PR #$PR_DISPATCH was not created by Dependabot"
    exit 1
  fi
  if [ "$(echo "$json" | jq -r '.state')" != "open" ]; then
    echo "PR #$PR_DISPATCH is no longer open, nothing to do"
    exit 0
  fi
  if [ "$(echo "$json" | jq -r '.head.sha')" != "$EXPECTED_HEAD" ]; then
    echo "PR #$PR_DISPATCH got new commits, the pull_request run for them takes over"
    exit 0
  fi
  if [ "$mergeable" != "true" ]; then
    echo "PR #$PR_DISPATCH is not cleanly mergeable, leaving it to Dependabot to rebase"
    exit 0
  fi
  pr=$PR_DISPATCH
  merge_sha=$(echo "$json" | jq -r '.merge_commit_sha')
  head_sha=$EXPECTED_HEAD
fi

# A PR that only touches CI files cannot affect the built binaries, so
# the gate merges it without building anything.
files=$(gh api "repos/$GH_REPO/pulls/$pr/files" --paginate --jq '.[].filename')
outside_ci=$(printf '%s\n' "$files" | grep -v '^\.github/' || true)
if [ -z "$outside_ci" ]; then
  echo "PR #$pr only touches .github/, skipping the builds"
  skip_build=true
else
  skip_build=false
fi

# Predict the tag an auto-release of this merge would carry, so the gate
# builds binaries that already report the release version and can be
# attached to the release as-is. Prediction failure is not fatal: the
# gate still validates the build, and the release run redoes the tag
# computation (surfacing the error) and rebuilds.
if ! next_tag=$(BUMP=patch "$(dirname "$0")/../compute-next-tag.sh"); then
  echo "::warning::Cannot compute the next release tag, the gate assets will not be reusable"
  echo "$next_tag"
  next_tag=
fi

{
  echo "pr=$pr"
  echo "merge_sha=$merge_sha"
  echo "head_sha=$head_sha"
  echo "skip_build=$skip_build"
  echo "next_tag=$next_tag"
} >> "$GITHUB_OUTPUT"
