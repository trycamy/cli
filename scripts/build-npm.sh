#!/bin/sh
# scripts/build-npm.sh — assemble the npm packages for one released version
# from the release channel's tarballs, verified against the version-scoped
# SHA256SUMS. Produces npm/out/<package>/ directories ready for `npm publish`.
#
#   sh scripts/build-npm.sh <version> [assets-dir]
#
# With no assets-dir the tarballs and manifest are downloaded from
# https://dl.camy.sh/stable/. Nothing is fetched at install time by the
# packages themselves; the binary is inside each platform package.
set -eu
V="${1:?usage: build-npm.sh <version> [assets-dir]}"
ASSETS="${2:-}"
CHANNEL="https://dl.camy.sh/stable"
ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$ROOT/npm/out"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

if [ -z "$ASSETS" ]; then
  ASSETS="$WORK/assets"; mkdir -p "$ASSETS"
  for f in "SHA256SUMS-$V" camy_${V}_darwin_arm64.tar.gz camy_${V}_darwin_amd64.tar.gz camy_${V}_linux_arm64.tar.gz camy_${V}_linux_amd64.tar.gz; do
    curl -fsSL --retry 3 --proto '=https' --tlsv1.2 -o "$ASSETS/$f" "$CHANNEL/$f"
  done
fi
sum() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
# LICENSE.md links to sibling files by relative path; inside a package they
# do not exist, so point them at the repository.
license() { sed -e 's#](CONTRIBUTING.md)#](https://github.com/trycamy/cli/blob/main/CONTRIBUTING.md)#' -e 's#](THIRD-PARTY-NOTICES.md)#](https://github.com/trycamy/cli/blob/main/THIRD-PARTY-NOTICES.md)#' "$ROOT/LICENSE.md" > "$1"; }

rm -rf "$OUT"; mkdir -p "$OUT"
for p in darwin-arm64:darwin_arm64:darwin:arm64:"macOS arm64" darwin-x64:darwin_amd64:darwin:x64:"macOS x64" linux-arm64:linux_arm64:linux:arm64:"Linux arm64" linux-x64:linux_amd64:linux:x64:"Linux x64"; do
  name=${p%%:*}; rest=${p#*:}; tar_arch=${rest%%:*}; rest=${rest#*:}; os=${rest%%:*}; rest=${rest#*:}; cpu=${rest%%:*}; human=${rest#*:}
  tarball="camy_${V}_${tar_arch}.tar.gz"
  want=$(awk -v f="$tarball" '($2 == f || $2 == "*" f) { print $1; exit }' "$ASSETS/SHA256SUMS-$V")
  got=$(sum "$ASSETS/$tarball")
  [ -n "$want" ] && [ "$want" = "$got" ] || { echo "checksum mismatch for $tarball" >&2; exit 1; }
  dir="$OUT/cli-$name"; mkdir -p "$dir/bin"
  tar -xzf "$ASSETS/$tarball" -C "$WORK" camy THIRD-PARTY-NOTICES.md
  mv "$WORK/camy" "$dir/bin/camy"; chmod 755 "$dir/bin/camy"; mv "$WORK/THIRD-PARTY-NOTICES.md" "$dir/THIRD-PARTY-NOTICES.md"
  license "$dir/LICENSE.md"
  sed -e "s/PLATFORM_HUMAN/$human/" -e "s/PLATFORM/$name/" "$ROOT/npm/platform-README.md" > "$dir/README.md"
  cat > "$dir/package.json" <<JSON
{
  "name": "@camy/cli-$name",
  "version": "$V",
  "description": "The camy binary for $human. Install the camy package instead.",
  "repository": "github:trycamy/cli",
  "homepage": "https://camy.ai",
  "license": "SEE LICENSE IN LICENSE.md",
  "os": ["$os"],
  "cpu": ["$cpu"],
  "files": ["bin/camy", "README.md", "LICENSE.md", "THIRD-PARTY-NOTICES.md"],
  "publishConfig": { "access": "public" }
}
JSON
done

dir="$OUT/camy"; mkdir -p "$dir/bin"
cp "$ROOT/npm/camy/bin/camy.js" "$dir/bin/camy.js"; chmod 755 "$dir/bin/camy.js"
cp "$ROOT/npm/camy/README.md" "$dir/README.md"; license "$dir/LICENSE.md"
cat > "$dir/package.json" <<JSON
{
  "name": "camy",
  "version": "$V",
  "description": "Camy in your terminal: the same agent, memory, and cloud computer you use at camy.ai, as one binary you can pipe, script, and schedule.",
  "keywords": ["camy", "cli", "agent", "terminal"],
  "repository": "github:trycamy/cli",
  "homepage": "https://camy.ai",
  "license": "SEE LICENSE IN LICENSE.md",
  "bin": { "camy": "bin/camy.js" },
  "engines": { "node": ">=18" },
  "optionalDependencies": {
    "@camy/cli-darwin-arm64": "$V",
    "@camy/cli-darwin-x64": "$V",
    "@camy/cli-linux-arm64": "$V",
    "@camy/cli-linux-x64": "$V"
  },
  "files": ["bin/camy.js", "README.md", "LICENSE.md"],
  "publishConfig": { "access": "public" }
}
JSON
echo "built npm/out: $(ls "$OUT" | tr '\n' ' ')" >&2
