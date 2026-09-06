#!/bin/sh
# scripts/publish-npm.sh — publish the packages assembled by build-npm.sh.
# Platform packages first, then the launcher that depends on them. A version
# that is already on the registry is skipped, so re-runs are safe. In CI the
# workflow's OIDC identity is the credential (npm trusted publishing) and
# --provenance attaches a build attestation; locally, your npm login is used.
# --stage uses `npm stage publish`: the versions land in the registry's
# staging area and a maintainer approves each one on npmjs.com (2FA) before
# it is public. That is how the release mirror publishes.
#
#   sh scripts/publish-npm.sh [--provenance] [--stage]
set -eu
ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
FLAGS="--access public"; CMD="publish"
for a in "$@"; do
  case "$a" in
    --provenance) FLAGS="$FLAGS --provenance" ;;
    --stage) CMD="stage publish" ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done
for pkg in cli-darwin-arm64 cli-darwin-x64 cli-linux-arm64 cli-linux-x64 camy; do
  dir="$ROOT/npm/out/$pkg"
  name=$(node -p "require('$dir/package.json').name"); version=$(node -p "require('$dir/package.json').version")
  if npm view "$name@$version" version >/dev/null 2>&1; then
    # Already on the registry: skip only if it is byte-for-byte what we just
    # built. A stranger's publish under our next version number is refused.
    pub=$(mktemp -d)
    curl -fsSL --proto '=https' --tlsv1.2 -o "$pub/pub.tgz" "$(npm view "$name@$version" dist.tarball)"
    tar -xzf "$pub/pub.tgz" -C "$pub"
    ours=$(cd "$dir" && tar -cf - --sort=name --mtime='1970-01-01' --owner=0 --group=0 . 2>/dev/null | sha256sum | cut -d' ' -f1)
    theirs=$(cd "$pub/package" && tar -cf - --sort=name --mtime='1970-01-01' --owner=0 --group=0 . 2>/dev/null | sha256sum | cut -d' ' -f1)
    rm -rf "$pub"
    if [ "$ours" = "$theirs" ]; then echo "$name@$version already published with these bytes; skipping" >&2; continue; fi
    echo "$name@$version is already on the registry with DIFFERENT contents — refusing to continue" >&2; exit 1
  fi
  # shellcheck disable=SC2086
  (cd "$dir" && npm $CMD $FLAGS)
done
