#!/bin/sh
# camy installer — https://camy.ai/cli/install.sh
#
#   curl -fsSL https://camy.ai/cli/install.sh | sh
#
# Hardened against the classic curl-pipe-sh failure modes:
#   - everything lives in main(), invoked on the LAST line: a truncated
#     download defines half a function and executes nothing
#   - downloads land in a temp dir, are checksum-verified against the
#     release's SHA256SUMS, then staged INSIDE the install dir and swapped
#     in with a same-directory rename — the only genuinely atomic mv
#   - no sudo: installs to ~/.local/bin (override: CAMY_INSTALL_DIR)
#
# Making `camy` work IMMEDIATELY: a curl|sh child can never modify the
# parent shell's environment (OS design — rustup/uv share the constraint),
# so besides writing the rc line for future shells, the installer symlinks
# the binary into a directory that is ALREADY on PATH when one is writable
# (/opt/homebrew/bin, /usr/local/bin, ~/bin) — every open terminal sees
# `camy` instantly, no source, no restart.
#
# Environment knobs, all optional:
#   CAMY_VERSION         install this exact version instead of whichever one
#                        the channel currently publishes
#   CAMY_INSTALL_DIR     where the binary goes (default ~/.local/bin)
#   CAMY_NO_MODIFY_PATH  set to 1 to leave shell rc files and symlinks alone
#   CAMY_DL_BASE         alternate download base URL, for local or air-gapped
#                        mirrors (default https://dl.camy.sh/stable)
#
# What this script verifies: the tarball's SHA-256 against the release's
# SHA256SUMS, both fetched over TLS from the same channel. Every release also
# publishes a cosign- and minisign-signed per-version manifest beside it for
# anyone verifying by hand; see docs/verifying-releases.md in
# github.com/trycamy/cli.
set -eu

# ── terminal colors ────────────────────────────────────────────────────────
# Color is only ever put on individual words (the "camy" wordmark, a
# checkmark, an arrow) using foreground codes; nothing paints a whole line's
# background. Enabled only when stderr is a real terminal, TERM is not
# "dumb", and the reader has not set NO_COLOR. Otherwise the color variables
# are empty and the marks fall back to plain ASCII: "camy", "ok", "->".
if [ -t 2 ] && [ "${TERM:-dumb}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
  R="$(printf '\033[0m')"
  EMBER="$(printf '\033[38;5;202m')"; PINK="$(printf '\033[38;5;175m')"
  LAV="$(printf '\033[38;5;140m')";   AMBER="$(printf '\033[38;5;179m')"
  RUST="$(printf '\033[38;5;166m')";  LATTE="$(printf '\033[38;5;180m')"
  GREEN="$(printf '\033[38;5;35m')";  DIMI="$(printf '\033[2m')"
  WM="${EMBER}c${PINK}a${LAV}m${AMBER}y${R}"
  OKM="${GREEN}✓${R}"; ARR="${RUST}→${R}"
else
  R=""; RUST=""; LATTE=""; GREEN=""; DIMI=""; WM="camy"; OKM="ok"; ARR="->"
fi

say()  { printf '%s\n' "$*" >&2; }
row()  { printf '  %s %-34s %s\n' "$1" "$2" "${LATTE}$3${R}" >&2; }
fail() { printf '  %s %s\n' "${RUST}x${R}" "$*" >&2; exit 1; }

main() {
  DL_BASE="${CAMY_DL_BASE:-https://dl.camy.sh/stable}"
  INSTALL_DIR="${CAMY_INSTALL_DIR:-$HOME/.local/bin}"
  # the channel's VERSION file names the current release. CAMY_VERSION is the
  # ONE escape hatch (air-gapped mirrors, pinning a known-good build); there is
  # no other fallback, because a version we made up is worse than no install.
  VERSION=$(printf '%s' "${CAMY_VERSION:-}" | tr -cd '0-9a-zA-Z.-' | cut -c1-32)
  if [ -z "$VERSION" ]; then
    # --retry covers 5xx/timeouts mid-release-flip; DNS/connection failures
    # are not "transient" to curl and fall straight through to the message.
    VERSION=$(curl -fsSL --retry 2 --retry-delay 1 "$DL_BASE/VERSION" 2>/dev/null | tr -cd '0-9a-zA-Z.-' | cut -c1-32)
    # a captive portal or an HTML error body served 200 survives tr as
    # non-empty garbage — require something version-shaped before trusting it
    case "$VERSION" in
      [0-9]*.[0-9]*) ;;
      *) fail "couldn't read the latest version from $DL_BASE/VERSION — check your connection and retry, or pin one:
     curl -fsSL https://camy.ai/cli/install.sh | CAMY_VERSION=x.y.z sh" ;;
    esac
  fi

  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  arch=$(uname -m)
  case "$os" in
    darwin|linux) ;;
    *) fail "unsupported OS '$os' (macOS and Linux today; WSL2 counts)" ;;
  esac
  case "$arch" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64)  arch=amd64 ;;
    *) fail "unsupported architecture '$arch'" ;;
  esac

  say ""
  say "  $WM ${LATTE}— installing v$VERSION${R}"
  say ""

  tarball="camy_${VERSION}_${os}_${arch}.tar.gz"
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/camy-install.XXXXXX")
  trap 'rm -rf "$tmp"' EXIT INT TERM

  # https is pinned unless the user explicitly pointed CAMY_DL_BASE at http
  # (a deliberate act — local mirrors, air-gapped testing)
  proto_pin="--proto =https --proto-default https"
  case "$DL_BASE" in http://*) proto_pin="" ;; esac

  # on a terminal, show curl's own progress bar; otherwise stay silent but
  # still print the reason if the transfer fails (that is what -sS buys)
  bar="-sS"
  [ -t 2 ] && bar="--progress-bar"
  # shellcheck disable=SC2086
  curl -fL $bar --retry 2 --retry-delay 1 $proto_pin -o "$tmp/$tarball" "$DL_BASE/$tarball" || \
    fail "download failed — is $DL_BASE reachable?"
  # shellcheck disable=SC2086
  curl -fsSL --retry 2 --retry-delay 1 $proto_pin -o "$tmp/SHA256SUMS" "$DL_BASE/SHA256SUMS" || \
    fail "checksums missing — refusing to install unverified binaries"

  # Verify by computing our own digest and comparing strings — never by a
  # tool's `-c` exit code. Darwin ships its own /sbin/sha256sum (not GNU
  # coreutils) which answers a malformed checksum line with "WARNING: 1 line
  # is improperly formatted" and exit 0 — zero files verified, reported as
  # success. Trusting that exit code would turn a truncated or CRLF-mangled
  # SHA256SUMS into a silent pass on macOS, so this script never asks.
  # awk exact-field match (not grep) so the '.'s in the filename can't act as
  # regex wildcards and a binary-mode '*name' marker still matches; sort -u
  # collapses the duplicate lines a hand-merged SHA256SUMS can carry, while
  # two DISAGREEING entries survive as two lines, which the hex-only check
  # and the 64-character length check below both reject.
  want=$(awk -v f="$tarball" '$2 == f || $2 == "*" f { print tolower($1) }' "$tmp/SHA256SUMS" | sort -u)
  case "$want" in *[!0-9a-f]*|"") want="" ;; esac
  [ "${#want}" -eq 64 ] || \
    fail "no usable checksum for $tarball in SHA256SUMS — refusing to install unverified binaries"
  got=$( { shasum -a 256 "$tmp/$tarball" 2>/dev/null || sha256sum "$tmp/$tarball" 2>/dev/null; } | awk '{print tolower($1)}')
  [ -n "$got" ] || fail "no sha256 tool found (need shasum or sha256sum) — refusing to install unverified binaries"
  [ "$got" = "$want" ] || fail "checksum verification FAILED — not installing"

  size=$(wc -c < "$tmp/$tarball" | tr -d ' ')
  size_mb=$(awk "BEGIN{printf \"%.1f\", $size/1048576}")
  row "$OKM" "$tarball" "${size_mb} MB · checksum verified"

  tar -xzf "$tmp/$tarball" -C "$tmp" || fail "couldn't unpack $tarball"
  [ -f "$tmp/camy" ] || fail "no camy binary in $tarball — not installing"
  mkdir -p "$INSTALL_DIR" || fail "can't create $INSTALL_DIR"
  # Stage INSIDE INSTALL_DIR (never $tmp — tmpfs /tmp on a different device
  # from $HOME is the Linux default, and mv across devices degrades to a
  # non-atomic copy-then-unlink) so the swap is a same-directory rename(2).
  # On Linux it also sidesteps ETXTBSY: rename over a running camy is fine,
  # write onto one is not (macOS does not enforce this). chmod runs BEFORE the
  # rename so the binary is never observable at its final name
  # half-permissioned. 0755 explicitly, not `chmod +x`: mktemp creates 0600
  # and `+x` is masked by umask, which would ship 0700 under umask 077 and
  # break every other user of a shared prefix.
  newbin=$(mktemp "$INSTALL_DIR/.camy.XXXXXX") || fail "can't write to $INSTALL_DIR — check permissions"
  trap 'rm -rf "$tmp"; rm -f "$newbin"' EXIT INT TERM
  cp "$tmp/camy" "$newbin" || fail "couldn't stage the binary in $INSTALL_DIR"
  chmod 0755 "$newbin"
  mv -f "$newbin" "$INSTALL_DIR/camy"   # same directory: rename(2), atomic
  newbin=""
  home_disp=$INSTALL_DIR
  # shellcheck disable=SC2088 # display text, not a path — the literal "~/"
  # is what we want printed, not a tilde expansion.
  case "$INSTALL_DIR" in "$HOME"/*) home_disp="~/${INSTALL_DIR#"$HOME"/}" ;; esac
  row "$OKM" "installed" "$home_disp/camy"

  # --- completions + man pages -----------------------------------------
  # Best effort, never fatal: a doc file must not fail an install. Not every
  # tarball carries completions or man pages, so every branch is guarded.
  # docs_installed tracks whether any branch below actually copied something,
  # so the "docs" row (and its fpath/MANPATH hint) only prints when there is
  # something under $share for it to point at.
  share="${XDG_DATA_HOME:-$HOME/.local/share}"
  docs_installed=""
  if [ -f "$tmp/completions/camy.bash" ] && mkdir -p "$share/bash-completion/completions" 2>/dev/null &&
     cp "$tmp/completions/camy.bash" "$share/bash-completion/completions/camy" 2>/dev/null; then
    docs_installed=1
  fi
  if [ -f "$tmp/completions/camy.zsh" ] && mkdir -p "$share/zsh/site-functions" 2>/dev/null &&
     cp "$tmp/completions/camy.zsh" "$share/zsh/site-functions/_camy" 2>/dev/null; then
    docs_installed=1
  fi
  if [ -f "$tmp/completions/camy.fish" ] && mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions" 2>/dev/null &&
     cp "$tmp/completions/camy.fish" "${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions/camy.fish" 2>/dev/null; then
    docs_installed=1
  fi
  if [ -d "$tmp/manpages" ] && mkdir -p "$share/man/man1" 2>/dev/null &&
     cp "$tmp"/manpages/*.1.gz "$share/man/man1/" 2>/dev/null; then
    docs_installed=1
  fi
  if [ -n "$docs_installed" ]; then
    row "$OKM" "docs" "completions + man pages installed under $share"
    row "$DIMI" ""    "zsh: add $share/zsh/site-functions to \$fpath · man: add $share/man to \$MANPATH"
  fi

  configure_path "$INSTALL_DIR"

  say ""
  say "  $ARR try:  ${RUST}camy${R}"
  say ""
}

# link_now makes `camy` resolvable in EVERY ALREADY-OPEN terminal by
# symlinking into a writable directory that is already on PATH. Returns the
# directory used via $LINKED, or fails silently (the rc line still covers
# future shells).
link_now() {
  dir="$1"
  LINKED=""
  case ":$PATH:" in *":$dir:"*) LINKED="$dir"; return 0 ;; esac
  for cand in /opt/homebrew/bin /usr/local/bin "$HOME/bin"; do
    case ":$PATH:" in *":$cand:"*) ;; *) continue ;; esac
    [ -d "$cand" ] || continue
    [ -w "$cand" ] || continue
    ln -sf "$dir/camy" "$cand/camy" 2>/dev/null || continue
    LINKED="$cand"
    return 0
  done
  return 1
}

# configure_path wires camy onto the PATH twice over: a symlink into an
# already-on-PATH dir for THIS terminal (link_now), and one guarded,
# idempotent rc line for machines without such a dir. CAMY_NO_MODIFY_PATH=1
# keeps hands off both rc files and symlinks (CI / self-managed PATHs).
configure_path() {
  dir="$1"

  if [ "${CAMY_NO_MODIFY_PATH:-}" = "1" ]; then
    row "$ARR" "add to PATH yourself" "export PATH=\"$dir:\$PATH\""
    return 0
  fi

  now_note="open a new terminal"
  if link_now "$dir"; then
    if [ "$LINKED" = "$dir" ]; then
      now_note="already on your PATH"
    else
      now_note="linked via $LINKED"
    fi
  fi

  # the rc line covers future shells on machines where no linkable dir exists
  disp="$dir"
  case "$dir" in "$HOME"/*) disp="\$HOME/${dir#"$HOME"/}" ;; esac
  shell_name=$(basename "${SHELL:-sh}")
  case "$shell_name" in
    zsh)  rc="${ZDOTDIR:-$HOME}/.zshrc"; line="export PATH=\"$disp:\$PATH\"" ;;
    bash)
      case "$os" in
        darwin) rc="$HOME/.bash_profile" ;;  # Terminal.app runs a login shell
        *)      rc="$HOME/.bashrc" ;;
      esac
      line="export PATH=\"$disp:\$PATH\""
      ;;
    fish)
      rc="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
      line="fish_add_path $disp"
      ;;
    *)    rc="$HOME/.profile"; line="export PATH=\"$disp:\$PATH\"" ;;
  esac

  rc_disp=$rc
  # shellcheck disable=SC2088 # display text, not a path — see above.
  case "$rc" in "$HOME"/*) rc_disp="~/${rc#"$HOME"/}" ;; esac

  if [ -f "$rc" ] && grep -F "$disp" "$rc" >/dev/null 2>&1; then
    row "$OKM" "ready in this terminal" "$now_note · PATH kept in $rc_disp"
    return 0
  fi
  mkdir -p "$(dirname "$rc")" 2>/dev/null || true
  if printf '\n# camy CLI (added by the installer)\n%s\n' "$line" >>"$rc" 2>/dev/null; then
    row "$OKM" "ready in this terminal" "$now_note · PATH added to $rc_disp"
  else
    row "$ARR" "add to PATH yourself" "export PATH=\"$dir:\$PATH\""
  fi
}

main "$@"
