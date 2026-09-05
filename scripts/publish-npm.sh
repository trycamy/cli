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
  if npm view "$name@$version" version >/dev/null 2>&1; then echo "$name@$version already published; skipping" >&2; continue; fi
  (cd "$dir" && npm publish $FLAGS)
done
