#!/usr/bin/env sh
# Attach the binaries of build-check run $CHECKED_RUN_ID to the draft
# release $TAG instead of rebuilding them. Only ever called after
# decide-asset-reuse.sh verified the build check built the exact release
# tree and that the artifacts are still available.
set -eu

gh run download "$CHECKED_RUN_ID" --dir checked-assets
gh release upload "$TAG" checked-assets/*/* --clobber
# The artifacts served their purpose; drop them now instead of letting
# them sit out the retention window (storage on private repos is billed
# per GB-day). Best effort — the assets are on the release at this
# point, so a failed cleanup must not fail the run.
gh api "repos/$GH_REPO/actions/runs/$CHECKED_RUN_ID/artifacts" \
  --jq '.artifacts[].id' | while read -r artifact_id; do
  gh api -X DELETE "repos/$GH_REPO/actions/artifacts/$artifact_id" \
    || echo "::warning::Could not delete artifact $artifact_id of build-check run $CHECKED_RUN_ID"
done
