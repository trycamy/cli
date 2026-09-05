# Installation

camy ships as a single static binary. Install it with the one-line script,
with Homebrew, or from a tarball you download by hand — then confirm it's
working with [`camy doctor`](reference/camy_doctor.md).

## Supported platforms

- macOS, arm64 or amd64
- Linux, arm64 or amd64

Running under WSL2 counts as Linux: install and update the same way you
would on a native Linux machine.

## The one-line installer

```bash
curl -fsSL https://camy.ai/cli/install.sh | sh
```

No `sudo` is used at any step. The script, in order:

1. **Resolves what to install.** It picks a download base (default
   `https://dl.camy.sh/stable`) and an install directory (default
   `~/.local/bin`), then the version to fetch: either the value you passed
   in `CAMY_VERSION`, or the current version from that base's `VERSION`
   file.
2. **Detects your platform.** OS (`darwin` or `linux`) and architecture
   (`arm64` or `amd64`, with `aarch64` and `x86_64` accepted as aliases).
3. **Downloads and verifies.** It fetches your platform's release tarball
   and the channel's cumulative `SHA256SUMS` index — one flat file covering
   every published version — then checks the tarball's SHA-256 against the
   matching line. Any mismatch, or no match, stops the install, and the
   temp download directory is removed on the way out.
4. **Stages and installs atomically.** The tarball is unpacked in a
   temporary directory. The binary is staged as a randomly-named file
   inside your install directory — so the final swap is a same-filesystem
   rename — made executable, then moved into place with a single rename.
   There's never a moment where `camy` at its final path is a partial file.
5. **Installs completions and man pages, best-effort.** If the release
   tarball includes them, shell completions and man pages are copied into
   the XDG locations listed under [After installing](#after-installing). A
   missing completion or man page never fails the install.
6. **Wires up your `PATH`.** Two steps, below.

### PATH wiring

Unless you've set `CAMY_NO_MODIFY_PATH=1`, the script does two things.

**For the terminals you already have open.** If your install directory
isn't already on `PATH`, it symlinks the binary into the first writable,
already-on-`PATH` directory it finds among `/opt/homebrew/bin`,
`/usr/local/bin`, and `~/bin`, so every open terminal picks up `camy`
immediately. If none of those is writable, open a new terminal instead.

**For the shells you open next.** It appends a `PATH` line to your rc file
— `export PATH="…"` for zsh, bash, and other POSIX shells, or
`fish_add_path …` for fish — commented, so it's easy to find and remove.
It's added even when the directory is on `PATH` some other way, and
skipped only when the rc file already names it as `$HOME/…`.

The rc file is chosen from your `$SHELL`:

| Shell | File |
|---|---|
| zsh | `~/.zshrc`, or `$ZDOTDIR/.zshrc` |
| bash | `~/.bash_profile` on macOS, `~/.bashrc` on Linux |
| fish | `~/.config/fish/config.fish` |
| anything else | `~/.profile` |

### Environment variables

| Variable | Effect |
|---|---|
| `CAMY_VERSION` | Install this exact version instead of whatever the channel's `VERSION` file currently points at. |
| `CAMY_INSTALL_DIR` | Install to this directory instead of `~/.local/bin`. |
| `CAMY_NO_MODIFY_PATH` | Set to `1` to skip both the `PATH` symlink and the rc-file edit. The script prints the export line for you to add yourself. |
| `CAMY_DL_BASE` | Download from this base URL instead of `https://dl.camy.sh/stable`. The installer honors it unconditionally — pointing it at a mirror is how the script itself is retargeted. Once `camy` is installed, `camy update` treats `CAMY_DL_BASE` differently; see [Updating](#updating). |

```bash
# Pin a version
curl -fsSL https://camy.ai/cli/install.sh | CAMY_VERSION=1.0.0 sh

# Install somewhere else
curl -fsSL https://camy.ai/cli/install.sh | CAMY_INSTALL_DIR="$HOME/bin" sh

# Skip PATH changes
curl -fsSL https://camy.ai/cli/install.sh | CAMY_NO_MODIFY_PATH=1 sh
```

## Homebrew

```bash
brew tap trycamy/tap
brew install camy
```

The tap is added once; from then on `brew install camy`, `brew upgrade camy`,
and `brew uninstall camy` work by the short name. The one-line form
`brew install trycamy/tap/camy` taps and installs in a single step.

The formula installs shell completions and man pages alongside the binary,
so there's nothing extra to set up. It is regenerated from the release
channel by the tap's own workflow whenever a version ships, so
`brew upgrade camy` follows releases without anyone editing it by hand.

A Homebrew-managed `camy` isn't updated or removed by `camy update` or
`camy uninstall` — both detect a Homebrew install and point you at
`brew upgrade camy` or `brew uninstall camy` instead.

## Manual download

Download a release tarball directly from `https://dl.camy.sh/stable/`.
Each platform's tarball is named:

```text
camy_<version>_<os>_<arch>.tar.gz
```

for example `camy_1.0.0_darwin_arm64.tar.gz`. The tarball contains the
`camy` binary at its root, plus `README.md` and, when the release ships
them, `completions/` and `manpages/` directories.

A `SHA256SUMS` file alongside the tarballs lets you verify the download
yourself:

```bash
shasum -a 256 -c <(grep camy_1.0.0_darwin_arm64.tar.gz SHA256SUMS)
```

For a stronger, signature-based verification of a specific release, see
[Verifying releases](verifying-releases.md).

Once you trust the tarball, unpack it and put `camy` somewhere on your
`PATH` — for example:

```bash
tar -xzf camy_1.0.0_darwin_arm64.tar.gz
mkdir -p ~/.local/bin
mv camy ~/.local/bin/camy
chmod +x ~/.local/bin/camy
```

## After installing

```bash
camy doctor
camy version
```

[`camy doctor`](reference/camy_doctor.md) checks the binary, your `PATH`,
the version, keychain access, sign-in status, API reachability, and
terminal capabilities, and prints a fix for anything that needs one. Only
`auth` and `api` can fail the command; every other row is a caution at
most.

Before you sign in, the `auth` row fails and `camy doctor` exits 1 —
that's expected, and the `api` row doesn't appear at all until there's a
key to check with. [Troubleshooting](troubleshooting.md#start-with-camy-doctor)
reads each row in full.

[`camy version`](reference/camy_version.md) prints the installed version
and platform, for example `camy v1.0.0 (darwin/arm64)`. Add `--json` for a
machine-readable object that also carries the build `commit`.

### Shell completions

If the installer or Homebrew didn't already put completions in place,
generate them yourself:

```bash
mkdir -p ~/.local/share/bash-completion/completions ~/.local/share/zsh/site-functions ~/.config/fish/completions
camy completion bash > ~/.local/share/bash-completion/completions/camy
camy completion zsh > ~/.local/share/zsh/site-functions/_camy
camy completion fish > ~/.config/fish/completions/camy.fish
```

For zsh, make sure `~/.local/share/zsh/site-functions` is on your `$fpath`
before `compinit` runs.

The installer and `camy update` write completions to these paths, where
`$XDG_DATA_HOME` defaults to `~/.local/share` and `$XDG_CONFIG_HOME` to
`~/.config`:

| Shell | File |
|---|---|
| bash | `$XDG_DATA_HOME/bash-completion/completions/camy` |
| zsh | `$XDG_DATA_HOME/zsh/site-functions/_camy` |
| fish | `$XDG_CONFIG_HOME/fish/completions/camy.fish` |

### Man pages

Man pages, when present in the release tarball, are installed to
`man/man1/` under `$XDG_DATA_HOME`. Add the `man` directory above it —
`~/.local/share/man`, or `$XDG_DATA_HOME/man` — to your `MANPATH` if it
isn't picked up automatically.

## Updating

```bash
camy update
```

[`camy update`](reference/camy_update.md) downloads the current version for
your platform, verifies its checksum against `SHA256SUMS` the same way the
installer does, and swaps it into place with a single atomic rename. The
running binary is never touched until the new one has been fully staged and
verified, so a failed update leaves you exactly where you started.

If the channel has nothing newer than the binary you are running, `camy
update` prints `up to date` and exits 0 without downloading anything. It
never downgrades.

Check what's available without installing it:

```bash
camy update --check
camy update --check --json
```

Switch channels with `--channel`:

```bash
camy update --channel canary
```

`--channel` accepts `stable` or `canary`. Without it, camy uses
`CAMY_CHANNEL` when that names a channel, and `stable` otherwise; a
`CAMY_CHANNEL` that is neither is ignored with a note, not an error.

`CAMY_DL_BASE` does not redirect `camy update` on a released binary. That
override is inert once `camy` has an actual version stamped into it, which
closes off a shell environment being used to point your live install at an
untrusted host.

It only has an effect on an unreleased development build, and even there
only when it is an `https://` URL; anything else is ignored. Either way
`camy update` says so on stderr rather than ignoring the variable
silently.

### The update note

After a command that succeeds, if a newer version is available, camy prints
a one-line note about it to stderr — at most once per day. Silence it with:

```bash
export CAMY_NO_UPDATE_NOTE=1
```

`CAMY_NO_UPDATE_CHECK=1` is accepted as an alias of `CAMY_NO_UPDATE_NOTE=1`.
The note never appears in `--json`/`--jq`/`--template` output, under
`--quiet`, or when stderr isn't a terminal.

### When the install directory isn't writable

If `camy update` can't write to the directory the binary lives in, it
doesn't fail with a raw permission error. It prints a diagnosis explaining
why (for example, the directory belongs to another user, or to root) and a
concrete fix, such as re-running the installer or using `sudo`.

Re-running the installer reinstalls into `~/.local/bin`, which you always
own. If the old copy is still earlier in your `PATH`, or you reached it
through a symlink, the diagnosis also tells you to remove that symlink, or
to put `~/.local/bin` ahead of the old directory in `PATH`, before the new
copy takes over.

[Troubleshooting](troubleshooting.md#the-diagnosis-card-when-the-binarys-directory-isnt-writable)
shows the shapes that card takes.

## Uninstalling

```bash
camy uninstall
```

[`camy uninstall`](reference/camy_uninstall.md) is interactive by default.
It asks you to type `uninstall` to confirm before removing the binary, then
asks separately whether to also remove your config, state, cache, and any
credential stored in the keychain. Answering no to the second prompt leaves
your config and stored key in place, in case you're reinstalling.

For scripts, pass `--confirm uninstall` to satisfy the confirmation gate
and `--no-input` to skip the second prompt; `--no-input` without
`--confirm` exits 2 (see [Exit codes](exit-codes.md)):

```bash
camy uninstall --confirm uninstall --no-input
```

`--no-input` never removes config, state, or your keychain entry on its
own: that step always requires an interactive answer, so a scripted
uninstall never silently wipes a stored credential.

## Next steps

- [Quick start](quickstart.md) — sign in and do something useful
- [Authentication](authentication.md) — device-flow sign-in, keys, and profiles
