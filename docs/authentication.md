# Authentication

`camy` authenticates with an API key. Sign in once with
[`camy auth login`](reference/camy_auth_login.md); after that the key lives
on your machine and every command uses it automatically.

```bash
camy auth login
```

In CI and other headless environments, set
[`CAMY_API_KEY`](#camy_api_key) instead of signing in.

## Browser sign-in

By default, `camy auth login` uses a browser device flow.

1. camy starts a sign-in and prints a short code and a verification link to
   your terminal. Both go to stderr, so `camy auth login >/dev/null` still
   shows them:

   ```text
     camy — sign in from your browser

     confirm this code there   <CODE>
     <verification link> ↗
   ```

2. camy opens the link in your browser, but only when it is on the same
   registrable domain as your `api_url`. If it is not, camy prints
   `sign-in URL … isn't on your api_url's domain — refusing to open it`,
   aborts the sign-in, and points you at `camy auth login --code` (the email
   plus one-time code flow) instead.
3. You confirm the code on the page. camy polls in the background until you
   approve or deny it, showing `waiting for you to click` with
   `ctrl-c cancels · nothing is granted until you click` beneath it. If the
   server reports the code expired, camy stops
   with `that code expired`; camy gives up on its own after 11 minutes with
   `sign-in timed out`. If the server no longer knows the sign-in at all,
   camy stops at once with
   `that sign-in is no longer pending — nothing more will arrive from it`;
   run `camy auth login` again.
4. On approval the server mints an API key with the scopes camy asked for at
   step 1 — the default set unless you passed [`--scopes`](#scopes) — and
   hands it back once. camy stores it and immediately verifies it by calling
   the account endpoint. A key that gets stored but fails to authenticate is
   reported as a failure, not a silent success.

If you deny the sign-in, `camy auth login` exits with the
[`checkpoint_denied`](exit-codes.md) code. If the code expires or you cancel
with Ctrl-C, nothing is granted. If your account already holds as many API
keys as it can, the approval mints nothing: camy prints camy.ai's reason,
such as `Maximum of 20 API keys reached — nothing was granted`, with the
same exit code as a denial. Revoke keys you no longer use (see
[`camy keys`](#camy-keys)) and sign in again.

On success, camy prints a card to stderr with who you signed in as, the
key's prefix and where it's stored, its scopes, and its expiry (if the
server set one):

```text
  camy — signed in
  ────────────────────────────────────────
  you        <name or email>
  key        <prefix>… (OS keychain)
  scopes     chat:read chat:write ...
  expires    Oct 4 2026 — camy auth login renews it
  ────────────────────────────────────────
  try: camy status
```

stdout stays empty in this flow — the card is chrome, not data. With
`--json`, camy prints one object instead, indented and with its keys sorted
alphabetically (the same rendering every `--json` command uses — see
[Scripting with camy](scripting.md)):

```json
{
  "expires_at": "2026-10-04T00:00:00Z",
  "scopes": [
    "chat:read",
    "chat:write"
  ],
  "status": "signed_in",
  "who": "<name or email>"
}
```

`camy auth login` is interactive by nature and refuses to run under
`--no-input`, in any combination with other flags:

```text
$ camy auth login --no-input
camy: login is interactive
      set CAMY_API_KEY in the environment for headless use
```

If browser sign-in isn't available on the server you're pointed at, camy
falls back to the email-code flow automatically and tells you it's doing so.

See [`camy auth`](reference/camy_auth.md) for the whole sign-in command
group.

## Linking this Mac as you sign in

On an interactive terminal, the browser sign-in also links this Mac to your
account. One approval gives you two credentials: this terminal's key, stored
as above, and this Mac's own credential, stored the same way. Linking also
makes a signing key on this Mac and keeps it in a file (see
[Your Mac as a device](device.md#link-this-mac)). Pass `--no-device` to sign
in without linking:

```bash
camy auth login
camy auth login --no-device
```

The handoff says what the click will also do:

```text
  camy — sign in from your browser

  confirm this code there   <CODE>
  <verification link> ↗

  that click also links MacBook Air — it can't do anything until you say
  ⋮ key kept in a file on this Mac · reads only
```

When you approve, camy prints the signed-in card, then the link, then offers
to let Camy read the folder you ran the command in:

```text
  ✓ linked      MacBook Air · key kept in a file on this Mac · reads only

  ╭──────────────────────────────────────────────────────────────────────────╮
  │ GRANT · read one folder                                      MacBook Air │
  ├──────────────────────────────────────────────────────────────────────────┤
  │ Let Camy read ~/Projects/lattice-brief                                   │
  │                                                                          │
  │ reads  files, listings, search · nothing runs, nothing changes           │
  │ scope  this folder and beneath it · nothing else on this Mac             │
  │ later  Settings → Your computers · or camy device scope add              │
  ╰──────────────────────────────────────────────────────────────────────────╯
  y grant · N skip, the default — the Mac stays linked, does nothing
  grant? [y/N]
```

`y` grants reading on that folder; if Camy refuses the grant, camy prints
its reason. `N`, the default, grants nothing, and so does no answer within
two minutes: the Mac stays linked and can do nothing until you add a grant
with [`camy device scope add`](device.md#grant-and-remove-scopes) or in
Settings. camy doesn't offer the card when you run it from your home folder
or from `/`. If you deny the sign-in, cancel it, or let the code expire,
nothing is linked either.

camy signs in without linking, and says nothing about linking, when:

- you pass `--no-device`, or `CAMY_NO_LOCAL=1` is set
- stdin or stderr isn't a terminal, or you ask for `--json`, `--jq`, or
  `--template`
- this Mac is already linked; the sign-in then renews only this terminal's
  key
- you sign in with `--code` or `--with-key`
- the server doesn't offer linking at sign-in

A Mac counts as already linked while it still holds its local link record
and its own credential, until it learns that the link was revoked or that
its credential expired; the resident agent notes either as soon as it hears
of it. After that, `camy auth login` offers to link it again, and the new
link replaces the old one. Until then, for example right after you revoke
the link on camy.ai while the agent isn't running, run `camy device forget`
first to link it again, whether through `camy auth login` or
`camy device enroll`.

The sign-in completes even when the link doesn't. If the approval comes back
without linking this Mac, camy says so and names the way to link it later,
or prints Camy's own reason when Camy refused the link:

```text
  ⋮ MacBook Air wasn't linked — camy device enroll links it
```

If linking a computer isn't on for your account, it says
`MacBook Air wasn't linked — linking a computer isn't on for your account yet`
instead.

If Camy refuses the combined sign-in before it starts, camy says so once and
runs the plain sign-in:

```text
This Mac won't be linked this time (<reason>) — signing in without it; camy device enroll links it later.
```

## Signing in with a code or a key

### `--code`: email and a one-time code

```bash
camy auth login --code
```

camy prompts for your email, sends a one-time code, then prompts for the
code. If your account has two-factor authentication enabled, camy prompts
for an authenticator code or a backup code next, and checks what you type as
either one. If it matches neither, camy stops with
`that authenticator or backup code didn't match`; run
`camy auth login --code` again.

Before it mints this terminal's key, camy asks for one more, fresh check:

```text
Minting this terminal's key needs a fresh check that it's you.
```

If your account uses an authenticator, type its next code, not the one you
just used, or press Enter to get a code by email. Otherwise camy emails you
a second code; camy.ai sends one code a minute, so camy may wait up to a
minute before it sends it. A code that doesn't confirm it's you gets two more
tries. After that camy stops with `that code didn't confirm it's you`
(exit 3), and nothing is changed.

Like the browser sign-in's key, the key a `--code` sign-in mints is marked
as this terminal's sign-in key, which is the only kind of key
`camy vm logout-everywhere` runs with.

Accounts whose only second factor is a passkey (WebAuthn) can't complete a
code sign-in from the terminal — camy detects this and points you at creating
a key at `https://camy.ai/p/settings/developer` and signing in with
`--with-key` instead. If code sign-in is disabled on the server you're
pointed at, `--code` fails with `code sign-in is disabled here` and the same
hint.

### `--with-key`: paste an existing key

```bash
camy auth login --with-key
```

camy prompts for a key on the terminal (never on stdin), naming
`https://camy.ai/p/settings/developer` as the place to create one, and checks
that it looks like a camy key (`camy_live_…` or `camy_test_…`) before storing
it.
This is the way to install a key that was created elsewhere — for example
one shown once by `camy keys rotate`.

There is no `--api-key` flag on any command, by design. Pasting or setting a
key always goes through one of `auth login --with-key` or the
[`CAMY_API_KEY`](#camy_api_key) environment variable.

## Scopes

Scopes control what a key can do. Every sign-in resolves a set of them — the
permissions the stored key carries.

```bash
camy auth login --scopes +datasets:write,-jobs:write
```

`--scopes` applies to the browser flow and `--code` only. With `--with-key`
it is ignored: a pasted key already carries whatever scopes it was created
with, and camy reads them back from your key list.

| `--scopes` | Requests |
|---|---|
| unset | camy's default set — the scopes marked below |
| `all` | every scope the server registers except `device:link` |
| `+add,-remove` | the default set, adjusted |
| `chat:read,files:read` | exactly that list, replacing the default set |

The two list forms can't be mixed: `--scopes +files:read,chat:read` is a
usage error (`don't mix a bare scope list with +/- adjustments`). Any scope
the server doesn't register is rejected as `unknown scope` when you add it
(`+scope`) or name it in a bare list. A `-scope` removal isn't checked — a
name that isn't in the set is silently ignored.

When camy can't fetch the server's list of scopes (you're offline, the
server is older, or its answer is malformed), it uses its own compiled-in
list instead, both to check `+scope` and bare lists and to expand `all`.

`device:link` belongs only to this Mac's own credential, never to a
terminal's key.
`--scopes all` leaves it out, so signing in with it still links this Mac, and
naming it (`+device:link`, or in a bare list) is a usage error:

```text
camy: device:link isn't a scope for this terminal's key — it belongs to this Mac's own key
      camy auth login links this Mac as it signs in; camy device enroll links it later
```

| Scope | Covers | Default |
|---|---|---|
| `chat:read` | Reading chats and their history | ✓ |
| `chat:write` | Sending chat messages | ✓ |
| `memory:read` | Reading stored memory | |
| `memory:write` | Writing stored memory | |
| `files:read` | Reading files in your workspace | |
| `files:write` | Writing files in your workspace | |
| `integrations:read` | Reading integration status | |
| `integrations:write` | Managing integrations | |
| `deploys:write` | Publishing sites from Canvas | |
| `jobs:write` | Creating and managing jobs | ✓ |
| `tasks:write` | Creating and managing tasks | ✓ |
| `webhooks:read` | Reading webhook config and deliveries | |
| `webhooks:write` | Managing webhooks | |
| `datasets:read` | Reading datasets | |
| `datasets:write` | Writing datasets | |
| `data:read` | Reading inbox and feed data | ✓ |
| `data:actions:draft_email` | Drafting an email as a card action | |
| `data:actions:create_event` | Creating a calendar event as a card action | |
| `data:actions:append_memory` | Appending to memory as a card action | |
| `data:actions:append_dataset` | Appending to a dataset as a card action | |
| `capture:write` | [`camy capture`](reference/camy_capture.md) | ✓ |
| `keys:manage` | `camy keys` self-management | ✓ |
| `workspace:exec` | Running commands in your cloud workspace: [`camy vm exec`](reference/camy_vm_exec.md) and [`camy vm shell`](reference/camy_vm_shell.md) | ✓ |

The server also registers `proactive:write`, `github:write`,
`history:read`, `secrets:read`, and `secrets:write`, none of which a `camy`
command needs. `--scopes all` includes them, and `+scope` accepts them, from
the server's list or camy's own.

Grant only what you need — `--scopes all` is convenient but broader than
most keys should be.

When a command is refused because the key lacks a scope, camy says
`this key lacks a required scope` (exit 3, except `camy vm exec`, which
exits 255), and the hint names the sign-in that adds it, such as
`camy auth login --scopes +datasets:write`. `workspace:exec` is in the
default set, but a key minted before it joined doesn't have it, so
`camy vm exec` and `camy vm shell` refuse that key; the hint then tells you
to run `camy auth login` to sign in again.

## Signing in again

Signing in again replaces the key this terminal holds rather than piling up
a new one every time.

With the default browser flow, every sign-in mints a new key. Once the new
key is stored and verified, camy revokes the key this profile held before,
but only when an earlier `camy auth login` on this profile stored it:

```text
retired the key this terminal held before (<prefix>…<last4>)
```

It never retires a key you pasted with `--with-key`, a key from
[`CAMY_API_KEY`](#camy_api_key), or a key another machine's sign-in minted.
A key stored by an older camy isn't marked as this profile's sign-in key, so
the first sign-in after you update retires nothing. If the revoke fails, the
sign-in still succeeds, and camy names the `camy keys revoke` command that
finishes the job. With `--json`, the signed-in object carries
`previous_key_revoked` only when camy tried to retire an earlier sign-in key:
`true` when it revoked it, `false` when the revoke failed. Otherwise the field
is absent.

With `camy auth login --code`, camy looks for this machine's key, the one
named exactly `camy-cli @ <hostname>`. When that key exists, what happens to
it depends on whether you passed `--scopes`:

- **No `--scopes`**, and the key already holds every scope the sign-in asks
  for: camy **rotates** the existing key in place. Rotation keeps the key's
  current scopes — if that differs from what you'd get from a fresh grant,
  camy tells you so and points at `--scopes` to change them.
- **Explicit `--scopes`** (even one that matches what's already granted), or
  a key that lacks one of the default scopes: camy mints a fresh key with
  exactly the scopes it asked for, named
  `camy-cli @ <hostname> (code sign-in <date and time>)`, and revokes the
  old key only after the new one exists.

A key that's expired, or one the server won't rotate, gets the same fresh
mint, regardless of `--scopes`. Either way, the key this machine holds is
never revoked before its replacement exists. If revoking the old key fails,
camy says it is still active and names the `camy keys revoke` command.

When there is no key with that exact name (a revoked one doesn't count),
`--code` mints a new key and retires the key this profile held before once
the new one exists, as described above. That is what happens on the sign-in
after a dated mint: the key this machine holds carries the dated name and
the undated key was revoked, so the next `--code` sign-in mints again rather
than rotating.

## Where keys are stored

A key is stored in your OS keychain, under the service name `camy` and an
account name scoped to your profile — each [profile](#profiles) gets its own
entry.

If the keychain can't be reached, camy falls back to a plain file in your
per-profile state directory, created with permissions `0600` (readable only
by you) and rewritten to `0600` on every write. camy tells you when it falls
back to the file, both at sign-in time and from `camy doctor`:

```text
! keychain   exit status 154 — keys fall back to a 0600 file in the state dir
```

The `keychain`, `path`, and `terminal` checks in `camy doctor` are cautions
and never fail the command — the file fallback genuinely works, so a broken
keychain alone never fails `camy doctor`. Only the `auth` row (no key found,
or the stored key rejected) fails the command; a rejected key marks the
`api` row failed alongside it. See
[`camy doctor`](reference/camy_doctor.md) and
[Troubleshooting](troubleshooting.md).

## `camy auth status`

```bash
camy auth status
```

Shows who you're signed in as, the first 12 characters of the key, where it
came from, your `api_url`, and your active profile:

```text
✓ <name or email> · key <prefix>… · source: profile default · https://api.camy.ai · profile default
```

`camy auth status` verifies the key against the account endpoint, so it
needs the network; when a key expiry is on record the line ends with
`· expires Oct 4`.

The `source` field names the credential: `env` when
[`CAMY_API_KEY`](#camy_api_key) supplied the key, or `profile <name>`
naming the profile whose stored key is in use. `--json` gives the full
shape, indented and with its keys sorted alphabetically:

```json
{
  "api_url": "https://api.camy.ai",
  "key_expires": "",
  "key_prefix": "<prefix>…",
  "key_source": "keychain",
  "profile": "default",
  "user": { "...": "..." }
}
```

The two are not the same vocabulary: the human line's `source:` is `env` or
`profile <name>`, while the JSON `key_source` names the store — `env`,
`keychain`, or `file`.

Not signed in is reported as an auth error in both modes, but the shape
differs: in human mode it's the two-line message below on stderr; under
`--json` it's the standard error object on stderr (see
[Scripting with camy](scripting.md)). Either way no status object is
printed and stdout stays empty:

```text
$ camy auth status
camy: not signed in
      run camy auth login
```

A key that is stored but no longer works gets its own message instead:
`your key expired` (or `your session expired <date>` when camy knows the
date) for an expired key, and `this key was revoked — it no longer works`
for a revoked one. Both are auth errors (exit 3), and `camy auth login`
signs this terminal in again.

See [`camy auth status`](reference/camy_auth_status.md).

## `camy auth logout` and `--revoke`

```bash
camy auth logout
```

Removes the key from this machine — the keychain entry or fallback file —
and clears its cached scopes and expiry. This needs no confirmation and
always succeeds locally, even if the key was already invalid. It doesn't
touch this Mac's link, its signing key, or its own credential; see
[Take it back](device.md#take-it-back) for those.

```bash
camy auth logout --revoke
```

Also revokes the key on the server, so it stops working everywhere, not just
here. camy finds the key in your key list by both its prefix and its last
four characters, revokes that one key, and only then removes it here:

```text
✓ signed out — key revoked and removed from this machine
```

A key the server already refuses as expired or revoked has nothing left to
revoke: camy removes it here and says the key no longer worked anyway. If
the revoke fails, for example because camy can't reach the API, the key
lacks `keys:manage`, or camy can't find it among your active keys, camy
revokes nothing, keeps the key stored here so you can try again, and exits
non-zero with the reason, starting `didn't revoke this terminal's key`
(or, when the key isn't listed,
`couldn't find this terminal's key (…) among your active keys`). Check with
`camy keys list`, or revoke by id with `camy keys revoke`. With `--json`,
the object says whether it `revoked`, and adds `already_invalid` for a key
that was already dead. With no key stored, `--revoke` has nothing to do: it
asks for no confirmation and signs out like a plain logout.

Because this can't be undone, it asks you to type `revoke` to confirm (or
pass `--confirm revoke` in a script) — `--force` and `--no-input` alone are
not enough for this one:

```bash
camy auth logout --revoke --confirm revoke
```

If the key currently in play for your profile came from
[`CAMY_API_KEY`](#camy_api_key) rather than a stored profile key, `--revoke`
refuses outright, before it even asks for confirmation:

```text
camy: CAMY_API_KEY is overriding profile "default" — refusing to revoke it as that profile's key
      unset CAMY_API_KEY to revoke the profile's own stored key, or use camy keys revoke
```

Unset `CAMY_API_KEY` to revoke the profile's own key, or use
[`camy keys revoke`](reference/camy_keys_revoke.md) to revoke a specific key
by id regardless of which one is stored locally.

See [`camy auth logout`](reference/camy_auth_logout.md).

## `CAMY_API_KEY`

```bash
export CAMY_API_KEY=camy_live_...
camy auth status
```

Setting `CAMY_API_KEY` overrides whatever key your active profile would
otherwise use, for the lifetime of the process. It is never written to disk
by camy. This is the supported way to authenticate non-interactively — in
CI, cron, or any script — since `auth login` itself cannot run headless.

If you've also explicitly chosen a profile (with `--profile`, `CAMY_PROFILE`,
or `default_profile`) while `CAMY_API_KEY` is set, camy prints a one-time
caution so it's clear which credential actually won:

```text
camy: CAMY_API_KEY overrides profile "work"
```

The caution is stderr chrome: it is suppressed under `--json`, `--jq`, and
`--template`, and by `-q`/`--quiet`. Use `camy auth status`'s `key_source`
field to detect the env key from a script.

## `camy keys`

```bash
camy keys list
```

[`camy keys list`](reference/camy_keys_list.md) lists the API keys on your
account — short id, prefix, name, and when each was created, when it
expires, and when it was last used. Another key on your account that has
expired reads `expired` in the `expires` column. The key this terminal holds is marked `· this terminal`, and it is also the key the
listing is made with, so when it has expired, `camy keys list` shows no list.
It fails with `your key expired` or `your session expired <date>` (exit 3),
and `camy auth login` fixes it.
`camy keys` with no subcommand runs the same listing.

```bash
camy keys rotate <id>
camy keys revoke <id> [<id>...]
```

`rotate` replaces a key with a new one carrying the same scopes and prints
the new full key once, to stdout. `revoke` kills one or more keys server-side
immediately, with a single confirmation for the whole set; it carries on past
an id that fails and exits non-zero if any did. Both take a short id prefix
(at least 4 characters) or a full id, and both ask for confirmation unless
you pass `--force`. With `--json`, revoking one key prints one object and
revoking several prints an array with one result per id.

`revoke` doesn't touch the key stored locally on this machine. When you
rotate the key this terminal holds, the confirmation says so, and camy
stores the replacement in its place, so this terminal keeps working:

```text
this terminal now uses it — kept in the OS keychain
```

If the old key was this terminal's sign-in key, so is the replacement. With
`--json`, the rotate object gains `stored_locally`. A key that came from
`CAMY_API_KEY` is the exception: camy can't change your environment, so it
says
`CAMY_API_KEY still holds the old key — it stops working in 24h; put the new one there`.

To use a rotated key on another machine, paste it there with:

```bash
camy auth login --with-key
```

See [`camy keys`](reference/camy_keys.md) and
[`camy keys rotate`](reference/camy_keys_rotate.md).

## Profiles

A profile is a named identity: its own stored key, its own state directory,
and optionally its own `api_url`/`editor`/`pager` overrides in
`config.toml`. This lets you keep separate accounts — say, personal and
work — side by side, independent of each other.

```bash
camy profile
camy profile use work
```

Bare `camy profile` lists `default` plus every profile that has a
`[profile.NAME]` table in `config.toml`, marking the persisted default.

[`camy profile use NAME`](reference/camy_profile_use.md) only persists the
default choice — it writes `default_profile` and does not create a
`[profile.NAME]` table, so the name still won't show up in `camy profile`'s
list until you add such a table with
[`camy config edit`](reference/camy_config_edit.md). It also doesn't check
that `NAME` has a signed-in key; if it doesn't, commands run under it report
"not signed in" until you run `camy auth login` there too.

Select a profile for a single command with `--profile` or `CAMY_PROFILE`:

```bash
camy --profile work auth login
CAMY_PROFILE=work camy auth status
```

See [`camy profile`](reference/camy_profile.md) and
[Configuration](configuration.md) for `config.toml` and the full precedence
ladder.

## Flags and environment variables

| Flag | Command | Meaning |
|---|---|---|
| `--code` | [`camy auth login`](reference/camy_auth_login.md) | email plus a one-time code instead of the browser |
| `--with-key` | [`camy auth login`](reference/camy_auth_login.md) | paste an existing key |
| `--no-device` | [`camy auth login`](reference/camy_auth_login.md) | sign in without linking this Mac |
| `--scopes` | [`camy auth login`](reference/camy_auth_login.md) | scope grammar: `+add,-remove` relative to the default set, a bare list, or `all`; browser flow and `--code` only, ignored with `--with-key` |
| `--revoke` | [`camy auth logout`](reference/camy_auth_logout.md) | also revoke the key server-side |
| `--confirm revoke` | [`camy auth logout`](reference/camy_auth_logout.md) | confirmation word for `--revoke` in scripts |
| `--profile` | any command | run under a named profile instead of the persisted default (env `CAMY_PROFILE`) |

| Variable | Meaning |
|---|---|
| `CAMY_API_KEY` | the key to use; wins over the keychain, never persisted by camy |
| `CAMY_PROFILE` | profile name |
| `CAMY_API_URL` | API origin, default `https://api.camy.ai` |

## See also

- [Configuration](configuration.md) — `config.toml`, the precedence ladder,
  and every environment variable
- [Scripting with camy](scripting.md) — the stdout/stderr contract and
  `--json` output
- [Exit codes](exit-codes.md) — what `auth`, `usage`, and `checkpoint_denied`
  mean here
- [Troubleshooting](troubleshooting.md) — `camy doctor` and common sign-in
  problems
