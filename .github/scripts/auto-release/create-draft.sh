#!/usr/bin/env sh
# Create the draft release $TAG targeting commit $SHA, replacing a
# leftover draft with the same tag from a previous failed run.
set -eu

if [ "$(gh release view "$TAG" --json isDraft --jq '.isDraft' 2>/dev/null)" = "true" ]; then
  echo "Deleting leftover draft release $TAG from a previous failed run"
  gh release delete "$TAG" --yes
fi
gh release create "$TAG" --draft --title "$TAG" --generate-notes --target "$SHA"
