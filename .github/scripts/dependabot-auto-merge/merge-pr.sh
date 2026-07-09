#!/usr/bin/env sh
# Squash-merge the checked Dependabot PR, unless main moved while the build
# check was running — then re-run the check instead of merging an unbuilt
# combination.
set -eu

# The first parent of the checked test merge commit is the main commit
# the build was validated against. (workflow_dispatch is exempt from
# the GITHUB_TOKEN recursion protection, so the re-dispatch works.)
checked_base=$(gh api "repos/$GH_REPO/commits/$MERGE_SHA" --jq '.parents[0].sha')
main_now=$(gh api "repos/$GH_REPO/git/ref/heads/main" --jq '.object.sha')
if [ "$main_now" != "$checked_base" ]; then
  echo "::notice::main moved from $checked_base to $main_now while the build check was running, re-running it"
  gh workflow run dependabot-auto-merge.yml --ref main -f pr="$PR" -f head="$HEAD_SHA"
  exit 0
fi
gh pr merge --squash --match-head-commit "$HEAD_SHA" "$PR"
# The squash commit this merge just put on main is the exact commit the
# release must build from; pin the dispatch to it. If main moves on
# (another Dependabot merge) before the release runs, the release aborts
# and that newer commit's own run handles it — nothing lands unreviewed.
released_sha=$(gh api "repos/$GH_REPO/pulls/$PR" --jq '.merge_commit_sha')
# A merge performed via GITHUB_TOKEN does not fire the push trigger
# of the auto-release workflow (recursion protection), so dispatch it
# explicitly — after giving the merge a moment to land on main. Handing
# over this run's ID and built tree lets the release attach the build
# check's binaries instead of rebuilding, when the trees still match.
sleep 10
gh workflow run auto-release.yml --ref main \
  -f commit="$released_sha" \
  -f checked_run_id="$GITHUB_RUN_ID" -f checked_tree="$CHECKED_TREE"
