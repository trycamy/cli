# Troubleshooting

Most problems start with one command: `camy doctor`. It checks the things
that usually go wrong — the binary, your `PATH`, the keychain, sign-in, and
the terminal — and prints a fix for anything that needs one. The sections
below cover the situation behind each exit code, then updates, `PATH`,
terminal rendering, and where camy keeps its files.

This page is diagnosis. The full exit-code table and the JSON error shape
are in [Exit codes](exit-codes.md).

## Start with `camy doctor`

```bash
camy doctor
```

```text
$ camy doctor
  ✓ binary     /usr/local/bin/camy
  ! path       not on PATH — add /usr/local/bin to PATH
  ✓ version    v1.0.0 (darwin/arm64)
  ! keychain   exit status 154 — keys fall back to a 0600 file in the state dir
  × auth       no key on profile default — camy auth login
  ! terminal   hyperlinks no · graphics no — iTerm2/kitty unlock inline image previews
camy: some checks failed
```

`✓`, `!`, and `×` mark ok, warning, and failure — `OK`, `!`, and `x` in
`--accessible` mode or a non-UTF-8 locale. Each row's fix, when it has one,
follows the dash. The `terminal` row is the exception: it reports whether
your terminal can draw hyperlinks and inline images, so its note isn't a
command to run.

[`camy doctor`](reference/camy_doctor.md) runs up to seven checks, in this
order. `path` appears only when the binary's directory isn't on `$PATH` —
or, for an npm install, when no `camy` on `$PATH` leads back to it — and
`api` only when a key is stored:

| Check | What it verifies | Can fail the command? |
| --- | --- | --- |
| `binary` | The path of the running executable. | No — always ok |
| `path` | Whether the binary's directory is on `$PATH` — or, for an npm install, whether some `camy` on `$PATH` leads back to it. Only shown when it isn't. | No — warning only |
| `version` | The installed version and platform. | No — always ok |
| `keychain` | A round-trip write/delete against your OS keychain. | No — warning only |
| `auth` | Whether a key is stored, and whether the server still accepts it. | **Yes** |
| `api` | Reachability and latency to your `api_url`. Shown whenever a key is stored — including when that key is rejected, in which case both rows fail. | **Yes** |
| `terminal` | Hyperlink and inline-image support in your current terminal. | No — warning only |

Only `auth` and `api` can fail the command. Every other row is
informational, so an otherwise-healthy machine with a flaky keychain, no
`PATH` entry, or a plain terminal still exits 0.

Three things trip exit 1: not signed in, a stored key the server no longer
accepts, or an API camy can't reach at all. A network failure fails the
`auth` and `api` rows together, so check the `api` row's host before
assuming the key is bad.

Add `--json` for a script-readable array of `{"name","ok","info"}` objects.
Each carries `"warn": true` and a `"fix"` string only when it has one; both
keys are omitted otherwise. Test truthiness (`select(.warn)`) rather than
comparing against `false`, since the exit code alone reflects only `ok`:

```bash
camy doctor --json | jq '.[] | select(.ok == false)'
```

## Common situations

### Usage errors (exit 2)

```text
$ camy approvals approve
camy: accepts 1 arg(s), received 0
      camy approvals approve --help shows usage
```

A missing argument or an unknown flag. The hint names the exact `--help` to
read.

A value the CLI rejects locally — `--channel bogus`, `--timeout 5000`,
[`camy mode`](reference/camy_mode.md) `fast` — is exit 2 too, but its hint
names the flag's own contract, or there is no hint line at all.

A typo in the command name is a usage error as well, with a suggestion when
one is close enough:

```text
$ camy nosuchcmd
camy: unknown command "nosuchcmd" for "camy"
      camy --help lists its commands
```

### Not signed in (exit 3)

```text
camy: not signed in
      run camy auth login
```

No key is stored for the active profile, or the stored one no longer
authenticates — a revoked key, an expired session. Run
[`camy auth login`](reference/camy_auth_login.md), or set `CAMY_API_KEY` for
a headless run. See [Authentication](authentication.md).

When camy has recorded an expiry for the stored key and that moment has
passed, the same exit 3 reads `camy: your session expired <date>` with the
hint `camy auth login — one click renews it`.

### Missing scope (exit 3)

```text
camy: this key lacks a required scope
      <detail> — mint one: camy auth login --scopes all
```

The key is valid but wasn't granted the scope the command needs. Re-run
`camy auth login --scopes all`, or a narrower `--scopes +the:scope` grant.
See [Scopes](authentication.md#scopes).

### Checkpoint pending, in a script (exit 4)

```text
checkpoint <id> requires approval:
  camy approvals approve <id>
```

A chat turn paused for a human decision and the process couldn't ask —
`--no-input`, any machine output (`--json`/`--jq`/`--template`), or no
`/dev/tty` to prompt on. Nothing failed.

Resolve it out of band with [`camy approvals`](reference/camy_approvals.md)
`approve`, `deny`, or `answer`; the whole model is in
[Approvals](approvals.md).

Add `--wait` to `approve`/`answer` to stream the resumed turn right there,
re-join it later with [`camy chat attach`](reference/camy_chat_attach.md),
or read the result with [`camy chats show`](reference/camy_chats_show.md).

### Rate limited (exit 5)

```text
camy: rate limited
      retry in 12s
```

The API returned HTTP 429. `GET` requests already retry a couple of times on
your behalf with server-driven backoff before giving up. A write never
retries automatically, so a 5 from one of those is yours to retry.

When the server sends a `Retry-After`, the hint names the wait; otherwise it
says `retry shortly`.

### Plan (exit 6)

```text
camy: your plan doesn't include this
      camy.ai/pricing
```

The API returned HTTP 402, or a 403 that means paid tier only, rather than
an auth problem. There's nothing to fix client-side.

### Workspace asleep (exit 7)

```bash
camy vm exec --no-wake -- pytest -q
```

`--no-wake` refuses to spend a multi-minute silent wake-up on a stopped or
sleeping workspace. Drop it to let the workspace wake normally, or start it
yourself first with [`camy vm start`](reference/camy_vm_start.md). See
[Workspace](workspace.md).

### Denied (exit 8)

A human said no to an approval during the same turn — through the
interactive prompt, or through
[`camy approvals deny`](reference/camy_approvals_deny.md) acting on a
checkpoint that turn was waiting on.

`camy approvals deny` itself always exits 0 on success: exit 8 belongs to
the turn that got told no, not to the act of saying no.

One non-chat case shares the code. Declining the browser sign-in exits 8
with `you denied the sign-in — nothing was granted`. See
[Approvals](approvals.md).

## Keychain unreachable and the 0600 fallback

If `camy doctor`'s `keychain` row warns, your OS keychain refused the
scratch write-then-delete `camy` tried:

```text
! keychain   exit status 154 — keys fall back to a 0600 file in the state dir
```

At sign-in, the same problem shows up as a note instead:

```text
keychain unavailable — key stored at ~/.local/state/camy/default/credentials (0600). Guard that file.
```

This is a warning, not a failure. camy falls back to a plain file in your
per-profile state directory, created and rewritten at mode `0600` so only
you can read it. Signing in and everything else keeps working; you don't get
OS-level key protection until the keychain is reachable again. See
[Where keys are stored](authentication.md#where-keys-are-stored).

## Updates

### Picking a channel

```bash
camy update --channel canary
```

`--channel` accepts `stable` or `canary`. An unrecognized value is a usage
error before any network call. Without `--channel`, camy uses `CAMY_CHANNEL`
if it's set to one of those two values, or `stable` otherwise — see
[Updating](installation.md#updating).

### The diagnosis card when the binary's directory isn't writable

[`camy update`](reference/camy_update.md) doesn't stop at a raw permission
error. It works out the reason and prints a titled card with the paths
involved and a runnable fix: a ruled title line naming the problem, the
message, any detail rows, and a `fix` line with the command to run.

There are a few shapes, depending on who owns the directory the binary lives
in and how you invoked `camy`.

**Installed system-wide, owned by root:**

```text
─ update needs root ───────────────────────────
  camy is installed system-wide — /usr/local/bin belongs to root

  fix  sudo camy update
       one update covers every user
```

**Owned by someone else, reached through a symlink, and you have your own install:**

```text
─ update blocked ──────────────────────────────
  this camy belongs to alice, not you

  you ran      /usr/local/bin/camy
  a link to    /home/alice/.local/bin/camy

  fix  rm /usr/local/bin/camy
       your own camy at /home/you/.local/bin/camy takes over
```

**Owned by someone else, through a symlink, and you have no install of your own:**

```text
─ update blocked ──────────────────────────────
  this camy belongs to alice, not you

  you ran      /usr/local/bin/camy
  a link to    /home/alice/.local/bin/camy

  fix  rm /usr/local/bin/camy
       curl -fsSL https://camy.ai/cli/install.sh | sh
       the installer lands in ~/.local/bin
```

**Owned by someone else, no symlink involved:**

```text
─ update blocked ──────────────────────────────
  this camy belongs to alice, not you

  it lives in  /home/alice/.local/bin

  fix  curl -fsSL https://camy.ai/cli/install.sh | sh
       then put ~/.local/bin ahead of /home/alice/.local/bin in PATH
```

**The directory is yours (or its owner can't be determined) but isn't writable:**

```text
─ update blocked ──────────────────────────────
  no write permission in /usr/local/bin

  fix  curl -fsSL https://camy.ai/cli/install.sh | sh
       the installer lands in ~/.local/bin
```

Every fix is one of three: run with `sudo` for a root-owned system install,
remove a stray symlink that's shadowing your own install, or run the
installer again.

The installer lands in `~/.local/bin`, which you own, and adds that
directory to the front of `PATH` in your rc file for new shells; the card
then asks you to make sure `~/.local/bin` really comes before the blocked
directory.

A Homebrew-managed `camy` is refused before any of this: `camy update`
detects it and points you at `brew upgrade camy` instead. An npm-managed
one is refused the same way, pointing at `npm update -g @camy/cli`;
`camy uninstall` behaves the same for both. See
[Updating](installation.md#updating) and [npm](installation.md#npm).

### Why `camy update` ignores `CAMY_DL_BASE`

`CAMY_DL_BASE` only affects the installer script and an unstamped
development build. On a real, released `camy` — everything from `curl | sh`,
Homebrew, or a downloaded tarball — `camy update` ignores it outright and
prints a note saying so.

This is deliberate: it stops a poisoned shell rc file from quietly
repointing your updates at another host. If you need a different channel,
use `--channel`.

## `PATH` not wired after install

If `camy` works when you type the full path but not as a bare command, its
directory isn't on `PATH` for your shell. `camy doctor`'s `path` row catches
this and names the directory to add.

The installer already tries to wire it up (see
[Installation](installation.md#the-one-line-installer)) by symlinking into a
directory already on `PATH` and editing your shell's rc file.

The rc edit only takes effect in new shells, and `CAMY_NO_MODIFY_PATH=1`
skips both steps entirely. Either open a new terminal, `source` your rc
file, or add the directory yourself.

The `path` check only looks at the binary that is running right now. If a
different, older `camy` sits earlier on your `PATH` — a stale Homebrew
install, for instance — it won't catch that on its own. Run `which -a camy`
to see every `camy` your shell can find.

An npm install (`npm install -g @camy/cli`) is judged differently. The
binary lives inside `node_modules`, and what sits on your `PATH` is the
launcher npm links to it, so the `path` row stays quiet as long as some
`camy` on your `PATH` leads back to that install, and names npm's global bin
directory as the fix only when none does. See [npm](installation.md#npm).

## Wrong or missing color

Color depends on `NO_COLOR`, `--color`, and what your terminal reports
through `TERM`/`COLORTERM`. The full ladder, plus the config key `color`, is
covered in [Terminal output and accessibility](terminal.md#color). The short
version:

- `--color=never` always turns color off.
- `NO_COLOR=1` (or `CLICOLOR=0`, or `TERM=dumb`) turns it off unless an
  explicit `--color=always` overrides it.
- `--color=always` turns it on wherever the terminal can carry it —
  `TERM=dumb` or an unset `TERM` still yields no color.
- Machine output (`--json`/`--jq`/`--template`) is never styled, regardless
  of any of this.

## Full-screen app rendering

Bare `camy` in a real terminal opens the full-screen app. If it renders
oddly in your terminal or over an unusual connection (a limited SSH session,
a CI log viewer, tmux with no true-color support):

```bash
camy --inline
camy --accessible
```

`--inline` keeps the classic scrollback behavior instead of taking over the
screen. `--accessible` (or `CAMY_ACCESSIBLE=1`, or a plain `TERM=dumb`) goes
further: no spinners, no redrawn boxes, no cursor movement, and it forces
the plain-line REPL over the full-screen app entirely. See
[The full-screen app and `--inline`](terminal.md#the-full-screen-app-and---inline).

## Getting request IDs for support

```bash
camy --verbose --json status
```

Request IDs do not come from `-v`. They arrive in the JSON error object with
`--json`, and inside a 5xx message as
`camy.ai had a problem (request <id>)`.

That object carries `request_id` whenever the failing call was a REST
request the server tagged with one. It is empty for errors that arrive over
the chat WebSocket, which don't carry a request ID — see
[the JSON error shape](exit-codes.md#the-json-error-shape).

`-v`/`--verbose` adds something different: a one-line note on which
credential source a command used (`auth: <prefix>… key from <source>`), the
agent's per-step trace lines while a chat streams, and the underlying error
when a chat connection can't be opened. Combine it with `--json` when
something fails.

When filing a [bug report](../SUPPORT.md), include the output of
[`camy version --json`](reference/camy_version.md) and `camy doctor` —
neither prints anything secret — plus the `request_id` from the failing call
if there is one.

## Where state lives, and what's safe to delete

camy uses up to three directories on disk. The exact paths, and how the
`XDG_*` variables override them, are in
[Configuration: Where things live](configuration.md#where-things-live). camy
does not write a separate log file; everything it prints goes to your
terminal's own scrollback.

| Directory | What it holds | Deleting it |
| --- | --- | --- |
| Cache — `~/.cache/camy` | Reserved. Nothing is written here today, so the directory usually doesn't exist. | Safe any time. [`camy uninstall`](reference/camy_uninstall.md) removes it if it's there. |
| Per-profile state — `~/.local/state/camy/<profile>/` | The 0600 credential fallback file (only written when your keychain isn't reachable), your cached granted scopes and key expiry, the last chat id that [`camy chat`](reference/camy_chat.md) `-c`, `camy chat attach`, [`camy canvas`](reference/camy_canvas.md), and `camy approvals … --wait` fall back to, your chat input history, the chat mode you set with `camy mode`, any local-tool results still waiting to be replayed, and your local-bridge trust grants. | Revokes your trust grants, so every trusted command and path is prompted for again. Loses your history and last-chat pointer, resets your chat mode to `agent`, and clears the cached scopes and expiry. |
| `config.toml` — `~/.config/camy/config.toml` | Your settings, profiles, and aliases. | Resets everything to defaults. Doesn't touch your stored credential. |

Deleting per-profile state signs you out only if your key was living in the
fallback file rather than the keychain. A key in the keychain isn't touched:
you'd be left with a stale keychain entry and an empty state cache, which is
confusing more than harmful, but it isn't the clean way to sign out.

[`camy auth logout`](reference/camy_auth_logout.md) is the clean way — it
clears the keychain entry (or the fallback file) and the cached state
together.

`camy uninstall` offers to remove all three directories for you, separately
from removing the binary — see [Uninstalling](installation.md#uninstalling).

## See also

- [Exit codes](exit-codes.md) — the frozen table, the JSON error shape, and every code in depth
- [`camy doctor`](reference/camy_doctor.md), [`camy status`](reference/camy_status.md), [`camy auth status`](reference/camy_auth_status.md)
- [Installation](installation.md) — updating, uninstalling, and the installer's own PATH wiring
- [Authentication](authentication.md) — sign-in, scopes, and where keys are stored
- [Terminal output and accessibility](terminal.md) — color, `--accessible`, paging, and inline images
- [Scripting with camy](scripting.md) — `--json`, `--no-input`, and the machine-output contract
- [SUPPORT.md](../SUPPORT.md) — where to file a bug or ask a question
