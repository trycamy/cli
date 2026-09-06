#!/bin/sh
# scripts/publish-npm.sh — publish the packages assembled by build-npm.sh.
# Platform packages first, then the launcher that depends on them. A version
# that is already on the registry is skipped, so re-runs are safe. In CI the
# workflow's OIDC identity is the credential (npm trusted publishing) and
# --provenance attaches a build attestation; locally, your npm login is used.
#
#   sh scripts/publish-npm.sh [--provenance]
set -eu
ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
FLAGS="--access public ${1:-}"
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
  (cd "$dir" && npm publish $FLAGS)
done
