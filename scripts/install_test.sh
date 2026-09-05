#!/bin/sh
# scripts/install_test.sh — exercises scripts/install.sh against a
# fake local channel (a plain `python3 -m http.server` over 127.0.0.1, no TLS
# — CAMY_DL_BASE's http:// branch clears --proto-pin for exactly this case).
# No network access beyond loopback; safe in CI.
#
#   sh scripts/install_test.sh
#
# Each numbered row below is one scenario the installer has to get right:
# some are clean installs, most are malformed or hostile channel responses
# that it must refuse. Row 12 checks the visible consequence of the atomic
# swap — no leftover .camy.* staging file after a success. The atomicity
# itself is a property of rename(2) rather than of this script, and a
# loopback harness cannot force the race that would test it, so no row
# claims to.
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
INSTALLER="$SCRIPT_DIR/install.sh"
[ -f "$INSTALLER" ] || { echo "no $INSTALLER" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/camy-install-test.XXXXXX")
CHAN="$WORK/channel"
mkdir -p "$CHAN"

PASS=0
FAIL=0

# ── build one real tarball + its correct digest, reused by the rows below
# (row 13 builds a second one of its own, with docs in it)
raw_os=$(uname -s | tr '[:upper:]' '[:lower:]')
raw_arch=$(uname -m)
case "$raw_arch" in
  arm64|aarch64) ARCH=arm64 ;;
  x86_64|amd64)  ARCH=amd64 ;;
  *) echo "unsupported test-host arch '$raw_arch'" >&2; exit 1 ;;
esac
OS="$raw_os"
VER="9.9.9"
TARBALL="camy_${VER}_${OS}_${ARCH}.tar.gz"

payload="$WORK/payload"
mkdir -p "$payload"
printf '#!/bin/sh\necho fake-camy\n' > "$payload/camy"
chmod 755 "$payload/camy"

mkdir -p "$CHAN/good"
tar -C "$payload" -czf "$CHAN/good/$TARBALL" camy
HASH=$(shasum -a 256 "$CHAN/good/$TARBALL" 2>/dev/null | awk '{print $1}')
[ -n "$HASH" ] || HASH=$(sha256sum "$CHAN/good/$TARBALL" | awk '{print $1}')
printf '%s  %s\n' "$HASH" "$TARBALL" > "$CHAN/good/SHA256SUMS"
# sha256 of the empty string — a fixed, well-formed, guaranteed-WRONG digest
WRONG=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

mkdir -p "$CHAN/r2" && cp "$CHAN/good/$TARBALL" "$CHAN/r2/"
printf '%s0  %s\n' "$HASH" "$TARBALL" > "$CHAN/r2/SHA256SUMS"           # 65 hex chars

mkdir -p "$CHAN/r3" && cp "$CHAN/good/$TARBALL" "$CHAN/r3/"
printf '%s  %s\n' "$WRONG" "$TARBALL" > "$CHAN/r3/SHA256SUMS"           # well-formed, wrong

mkdir -p "$CHAN/r4" && cp "$CHAN/good/$TARBALL" "$CHAN/r4/"
UPPER=$(printf '%s' "$HASH" | tr '[:lower:]' '[:upper:]')
printf '%s  %s\n' "$UPPER" "$TARBALL" > "$CHAN/r4/SHA256SUMS"           # uppercase digest

mkdir -p "$CHAN/r5" && cp "$CHAN/good/$TARBALL" "$CHAN/r5/"
{ printf '%s  %s\n' "$HASH" "$TARBALL"; printf '%s  %s\n' "$HASH" "$TARBALL"; } \
  > "$CHAN/r5/SHA256SUMS"                                               # duplicate merged lines

mkdir -p "$CHAN/r6" && cp "$CHAN/good/$TARBALL" "$CHAN/r6/"
{ printf '%s  %s\n' "$HASH" "$TARBALL"; printf '%s  %s\n' "$WRONG" "$TARBALL"; } \
  > "$CHAN/r6/SHA256SUMS"                                               # two disagreeing lines

mkdir -p "$CHAN/r7" && cp "$CHAN/good/$TARBALL" "$CHAN/r7/"
printf '%s *%s\n' "$HASH" "$TARBALL" > "$CHAN/r7/SHA256SUMS"            # binary-mode marker

mkdir -p "$CHAN/r8" && cp "$CHAN/good/$TARBALL" "$CHAN/r8/" && cp "$CHAN/good/SHA256SUMS" "$CHAN/r8/"
printf '<html><body>502 Bad Gateway</body></html>' > "$CHAN/r8/VERSION" # HTML-200 garbage

# r9 deliberately reuses "good" (no VERSION file there) without a pin.
# r10 reuses "good" too, WITH a pin — proves no VERSION round-trip.

# ── serve it
PORT=$((20000 + $$ % 20000))
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$CHAN" \
  >"$WORK/server.log" 2>&1 &
SERVER_PID=$!

cleanup() { kill "$SERVER_PID" 2>/dev/null || :; rm -rf "$WORK"; }
trap cleanup EXIT INT TERM

i=0
while ! curl -fsS -o /dev/null "http://127.0.0.1:$PORT/good/SHA256SUMS" 2>/dev/null; do
  i=$((i + 1))
  [ "$i" -lt 50 ] || { echo "fake channel never came up" >&2; exit 1; }
  sleep 0.1
done

mode_of() { python3 -c "import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))" "$1" 2>/dev/null; }

# run_case NAME SUBDIR PIN EXPECT_EXIT MUST_CONTAIN
# SUBDIR is the directory under the fake channel root this case downloads
# from; PIN="" leaves CAMY_VERSION unset, so the installer has to fetch
# VERSION for itself. Each case installs into its own throwaway directory
# with PATH modification off, then the exit code and output are checked.
run_case() {
  name=$1; subdir=$2; pin=$3; want_exit=$4; want_grep=$5
  idir="$WORK/install-$name"
  out="$WORK/out-$name"
  set -- env CAMY_DL_BASE="http://127.0.0.1:$PORT/$subdir" \
             CAMY_INSTALL_DIR="$idir" CAMY_NO_MODIFY_PATH=1
  [ -n "$pin" ] && set -- "$@" CAMY_VERSION="$pin"
  got_exit=0
  "$@" sh "$INSTALLER" >"$out" 2>&1 || got_exit=$?
  ok=1
  if [ "$got_exit" != "$want_exit" ]; then
    ok=0
    echo "  x $name: exit $got_exit, want $want_exit" >&2
  fi
  if [ -n "$want_grep" ] && ! grep -qF "$want_grep" "$out"; then
    ok=0
    echo "  x $name: output missing '$want_grep'" >&2
    sed 's/^/      | /' "$out" >&2
  fi
  if [ "$ok" = 1 ]; then
    echo "  ok $name"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
  # left behind in a global so callers can make extra assertions about the
  # directory this case installed into
  LAST_IDIR=$idir
}

echo "camy install.sh test suite ($OS/$ARCH, tarball=$TARBALL)"
echo ""

run_case "01-happy-path"            good "$VER" 0 "checksum verified"
r1_idir=$LAST_IDIR
run_case "02-malformed-65hex"       r2   "$VER" 1 "no usable checksum"
run_case "03-wellformed-wrong-hash" r3   "$VER" 1 "checksum verification FAILED"
run_case "04-uppercase-digest"      r4   "$VER" 0 "checksum verified"
run_case "05-duplicate-sums-lines"  r5   "$VER" 0 "checksum verified"
run_case "06-disagreeing-sums"      r6   "$VER" 1 "no usable checksum"
run_case "07-binary-mode-marker"    r7   "$VER" 0 "checksum verified"
run_case "08-html-200-version"      r8   ""     1 "couldn't read the latest version"
run_case "09-version-unreachable"   good ""     1 "couldn't read the latest version"

# row 10, continued: the pin must skip the VERSION fetch entirely. Row 9
# (just above) legitimately DOES hit /good/VERSION, so only the log lines
# written during THIS case count.
log_before=$(wc -l < "$WORK/server.log")
run_case "10-camy-version-pin"      good "$VER" 0 "checksum verified"
if tail -n +$((log_before + 1)) "$WORK/server.log" | grep -q "GET /good/VERSION"; then
  echo "  x 10-camy-version-pin: hit /VERSION despite CAMY_VERSION pin" >&2
  FAIL=$((FAIL + 1))
else
  echo "  ok 10-camy-version-pin: no /VERSION round-trip"
  PASS=$((PASS + 1))
fi

# row 1, continued: exact mode + content, not just exit code
if [ "$(mode_of "$r1_idir/camy")" = "0o755" ]; then
  echo "  ok 01-happy-path: mode 0755"
  PASS=$((PASS + 1))
else
  echo "  x 01-happy-path: mode $(mode_of "$r1_idir/camy"), want 0o755" >&2
  FAIL=$((FAIL + 1))
fi
if cmp -s "$r1_idir/camy" "$payload/camy"; then
  echo "  ok 01-happy-path: installed bytes match the tarball"
  PASS=$((PASS + 1))
else
  echo "  x 01-happy-path: installed bytes differ from the tarball" >&2
  FAIL=$((FAIL + 1))
fi
# cosmetic: the "good" tarball packs only the binary, no completions or man
# pages, so the installer must not print a "docs" row for it.
if grep -qF "completions + man pages installed under" "$WORK/out-01-happy-path"; then
  echo "  x 01-happy-path: printed a docs row with no completions/man pages in the tarball" >&2
  FAIL=$((FAIL + 1))
else
  echo "  ok 01-happy-path: no docs row without completions/man pages"
  PASS=$((PASS + 1))
fi

# row 12: no .camy.* staging file survives a successful install
stray=$(find "$r1_idir" -maxdepth 1 -name '.camy.*' 2>/dev/null || :)
if [ -z "$stray" ]; then
  echo "  ok 12-no-stray-staging-file"
  PASS=$((PASS + 1))
else
  echo "  x 12-no-stray-staging-file: $stray" >&2
  FAIL=$((FAIL + 1))
fi

# row 11: unwritable INSTALL_DIR parent — skipped as root, which bypasses
# every permission bit this row exists to exercise.
if [ "$(id -u)" = "0" ]; then
  echo "  -- 11-unwritable-install-dir: skipped (running as root)"
else
  ro="$WORK/readonly"
  mkdir -p "$ro"
  chmod 555 "$ro"
  out="$WORK/out-11"
  got_exit=0
  env CAMY_DL_BASE="http://127.0.0.1:$PORT/good" CAMY_INSTALL_DIR="$ro/sub" \
      CAMY_NO_MODIFY_PATH=1 CAMY_VERSION="$VER" \
    sh "$INSTALLER" >"$out" 2>&1 || got_exit=$?
  chmod 755 "$ro"
  if [ "$got_exit" = 1 ] && grep -qF "can't create" "$out"; then
    echo "  ok 11-unwritable-install-dir"
    PASS=$((PASS + 1))
  else
    echo "  x 11-unwritable-install-dir: exit $got_exit" >&2
    sed 's/^/      | /' "$out" >&2
    FAIL=$((FAIL + 1))
  fi
fi

# row 13: a tarball that DOES carry completions + man pages (the shape a
# real release ships) → the docs row must print, and the files must land —
# under an isolated XDG_DATA_HOME/XDG_CONFIG_HOME, never the real $HOME, so
# this suite stays side-effect-free on the host running it.
mkdir -p "$CHAN/withdocs"
docs_payload="$WORK/docs_payload"
mkdir -p "$docs_payload/completions" "$docs_payload/manpages"
printf '#!/bin/sh\necho fake-camy\n' > "$docs_payload/camy"
chmod 755 "$docs_payload/camy"
printf '# bash completion\n' > "$docs_payload/completions/camy.bash"
printf '# zsh completion\n'  > "$docs_payload/completions/camy.zsh"
printf '# fish completion\n' > "$docs_payload/completions/camy.fish"
printf 'fake-gz' > "$docs_payload/manpages/camy.1.gz"
tar -C "$docs_payload" -czf "$CHAN/withdocs/$TARBALL" camy completions manpages
DHASH=$(shasum -a 256 "$CHAN/withdocs/$TARBALL" 2>/dev/null | awk '{print $1}')
[ -n "$DHASH" ] || DHASH=$(sha256sum "$CHAN/withdocs/$TARBALL" | awk '{print $1}')
printf '%s  %s\n' "$DHASH" "$TARBALL" > "$CHAN/withdocs/SHA256SUMS"

xdg_data="$WORK/xdg-data-13"
xdg_config="$WORK/xdg-config-13"
idir="$WORK/install-13-docs-row-present"
out="$WORK/out-13"
got_exit=0
env CAMY_DL_BASE="http://127.0.0.1:$PORT/withdocs" CAMY_INSTALL_DIR="$idir" \
    CAMY_NO_MODIFY_PATH=1 CAMY_VERSION="$VER" \
    XDG_DATA_HOME="$xdg_data" XDG_CONFIG_HOME="$xdg_config" \
  sh "$INSTALLER" >"$out" 2>&1 || got_exit=$?
if [ "$got_exit" = 0 ] && grep -qF "completions + man pages installed under" "$out" \
   && [ -f "$xdg_data/bash-completion/completions/camy" ] \
   && [ -f "$xdg_data/zsh/site-functions/_camy" ] \
   && [ -f "$xdg_config/fish/completions/camy.fish" ] \
   && [ -f "$xdg_data/man/man1/camy.1.gz" ]; then
  echo "  ok 13-docs-row-present: docs row printed, all four artifacts landed"
  PASS=$((PASS + 1))
else
  echo "  x 13-docs-row-present: exit $got_exit" >&2
  sed 's/^/      | /' "$out" >&2
  FAIL=$((FAIL + 1))
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
