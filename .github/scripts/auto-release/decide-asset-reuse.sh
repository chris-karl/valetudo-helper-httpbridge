#!/usr/bin/env sh
# Decide whether the build check's binaries can be attached to the release
# instead of rebuilding: only when the tree the build check built (the PR
# merged into main with the release version stamped in) is identical to the
# tree of the release commit $SHA. Any interleaved commit or version drift
# changes the tree and forces a rebuild — content equality makes reuse
# exactly as trustworthy as building again.
set -eu

reuse=false
if [ -n "$CHECKED_RUN_ID" ] && [ -n "$CHECKED_TREE" ] &&
   [ "$(git rev-parse "$SHA^{tree}")" = "$CHECKED_TREE" ]; then
  # The artifacts are deleted right after a successful attach and expire
  # after a day, so confirm they are actually still available — without
  # this, a retried release run would keep failing on the attach instead
  # of falling back to a rebuild (tree equality never expires).
  if names=$(gh api "repos/$GH_REPO/actions/runs/$CHECKED_RUN_ID/artifacts" \
      --jq '.artifacts[] | select(.expired | not) | .name' 2>/dev/null); then
    if printf '%s\n' "$names" | grep -Fxq "release-assets-linux" &&
       printf '%s\n' "$names" | grep -Fxq "release-assets-macos"; then
      reuse=true
    fi
  fi
fi
if [ "$reuse" = "true" ]; then
  echo "Release tree matches what build-check run $CHECKED_RUN_ID built, reusing its binaries"
else
  echo "No matching build-check assets, building the assets from scratch"
fi
echo "reuse=$reuse" >> "$GITHUB_OUTPUT"
