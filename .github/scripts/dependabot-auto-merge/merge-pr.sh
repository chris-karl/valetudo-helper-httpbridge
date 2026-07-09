#!/usr/bin/env sh
# Squash-merge the gated Dependabot PR, unless main moved while the gate
# was running — then re-dispatch the gate instead of merging an unbuilt
# combination.
set -eu

# The first parent of the gated test merge commit is the main commit
# the build was validated against. (workflow_dispatch is exempt from
# the GITHUB_TOKEN recursion protection, so the re-dispatch works.)
gated_base=$(gh api "repos/$GH_REPO/commits/$MERGE_SHA" --jq '.parents[0].sha')
main_now=$(gh api "repos/$GH_REPO/git/ref/heads/main" --jq '.object.sha')
if [ "$main_now" != "$gated_base" ]; then
  echo "::notice::main moved from $gated_base to $main_now while the gate was running, re-running the gate"
  gh workflow run dependabot-auto-merge.yml --ref main -f pr="$PR" -f head="$HEAD_SHA"
  exit 0
fi
gh pr merge --squash --match-head-commit "$HEAD_SHA" "$PR"
# A merge performed via GITHUB_TOKEN does not fire the push trigger
# of the auto-release workflow (recursion protection), so dispatch it
# explicitly — after giving the merge a moment to land on main. Handing
# over this run's ID and built tree lets the release attach the gate's
# artifacts instead of rebuilding, when the trees still match.
sleep 10
gh workflow run auto-release.yml --ref main \
  -f gate_run_id="$GITHUB_RUN_ID" -f gate_tree="$GATE_TREE"
