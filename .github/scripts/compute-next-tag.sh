#!/usr/bin/env sh
# Compute the tag the next release would carry and print it as the only
# stdout output. On failure, the diagnostic (a ::error:: line) goes to
# stdout instead and the exit code is nonzero — callers capture stdout
# and decide whether to surface or tolerate the failure.
#
# $BUMP selects the version component to increment: patch (the default,
# used by all automatic releases), minor, or major.
#
# The version in package.json is the single source of truth. Normally it
# equals the latest tag and gets bumped; when it is ahead of the tags (a
# previous release run bumped it and then failed before publishing), a
# patch release re-releases exactly that version, while minor/major
# bumps increment from it.
# Requires the v* tags to be present in the checkout.
set -eu

bump=${BUMP:-patch}
case $bump in
  patch|minor|major) ;;
  *)
    echo "::error::Unknown BUMP value \"$bump\", expected patch, minor or major"
    exit 1
    ;;
esac

bump_version() { # $1 = version, $2 = component to increment
  echo "$1" | awk -F. -v OFS=. -v part="$2" '{
    if (part == "major") { $1++; $2 = 0; $3 = 0 }
    else if (part == "minor") { $2++; $3 = 0 }
    else { $3++ }
    print
  }'
}

# Compare against the newest tag in version order (the nearest reachable
# tag can miss a newer one created manually without a package.json bump).
newest_tag=$(git tag -l 'v*' | sort -V | tail -n 1)
current=$(jq -r .version package.json)
if git rev-parse -q --verify "refs/tags/v$current" > /dev/null; then
  if [ "v$current" != "$newest_tag" ]; then
    echo "::error::package.json version $current is behind the newest tag $newest_tag. Reconcile with npm version before releasing."
    exit 1
  fi
  next_tag="v$(bump_version "$current" "$bump")"
else
  # package.json is ahead of the tags (a previous run failed after the
  # bump) — but it must never be behind the newest tag.
  ahead=$(printf '%s\nv%s\n' "$newest_tag" "$current" | sort -V | tail -n 1)
  if [ "$ahead" != "v$current" ]; then
    echo "::error::package.json version $current is behind the newest tag $newest_tag. Reconcile with npm version before releasing."
    exit 1
  fi
  if [ "$bump" = "patch" ]; then
    next_tag="v$current"
  else
    next_tag="v$(bump_version "$current" "$bump")"
  fi
fi
if git rev-parse -q --verify "refs/tags/$next_tag" > /dev/null; then
  echo "::error::Tag $next_tag already exists"
  exit 1
fi
echo "$next_tag"
