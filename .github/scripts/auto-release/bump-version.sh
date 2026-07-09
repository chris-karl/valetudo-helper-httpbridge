#!/usr/bin/env sh
# Set the package.json / package-lock.json version to $TAG (without the
# leading v) and push that as a commit to main, so the tag ends up on a
# commit whose package files carry the version it names. Emits the
# commit to build and tag as the sha output.
set -eu

version=${TAG#v}
npm version --no-git-tag-version --allow-same-version "$version" > /dev/null
if git diff --quiet; then
  # A previous run bumped already and then failed before publishing;
  # reuse its commit.
  echo "Version is already $version, nothing to commit"
else
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add package.json package-lock.json
  git commit -m "Bump version to $version"
  # If something else lands on main first, this push fails and the run
  # with it — the auto-release run dispatched for whatever landed will
  # redo the bump on top and release everything together.
  git push origin HEAD:main
fi
echo "sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
