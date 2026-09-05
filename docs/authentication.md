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

     confirm this code there:  <CODE>

     <verification link>
   ```

2. camy opens the link in your browser, but only when it is on the same
   registrable domain as your `api_url`. If it is not, camy prints
   `sign-in URL … isn't on your api_url's domain — refusing to open it`,
   aborts the sign-in, and points you at `camy auth login --code` (the email
   plus one-time code flow) instead.
3. You confirm the code on the page. camy polls in the background until you
   approve or deny it. If the server reports the code expired, camy stops
   with `that code expired`; camy gives up on its own after 11 minutes with
   `sign-in timed out`.
4. On approval the server mints an API key with the scopes camy asked for at
   step 1 — the default set unless you passed [`--scopes`](#scopes) — and
   hands it back once. camy stores it and immediately verifies it by calling
   the account endpoint. A key that gets stored but fails to authenticate is
   reported as a failure, not a silent success.

If you deny the sign-in, `camy auth login` exits with the
[`checkpoint_denied`](exit-codes.md) code. If the code expires or you cancel
with Ctrl-C, nothing is granted.

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

## Signing in with a code or a key

### `--code`: email and a one-time code

```bash
camy auth login --code
```

camy prompts for your email, sends a one-time code, then prompts for the
code. If your account has two-factor authentication enabled, camy prompts
for an authenticator or backup code next; a failed authenticator code is
retried once as a backup code automatically.

Accounts whose only second factor is a passkey (WebAuthn) can't complete a
code sign-in from the terminal — camy detects this and points you at
`--with-key` instead. If code sign-in is disabled on the server you're
pointed at, `--code` fails with `code sign-in is disabled here` and the same
hint.

### `--with-key`: paste an existing key

```bash
camy auth login --with-key
```

camy prompts for a key on the terminal (never on stdin) and checks that it
looks like a camy key (`camy_live_…` or `camy_test_…`) before storing it.
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
| `all` | every scope the server knows about |
| `+add,-remove` | the default set, adjusted |
| `chat:read,files:read` | exactly that list, replacing the default set |

The two list forms can't be mixed: `--scopes +files:read,chat:read` is a
usage error (`don't mix a bare scope list with +/- adjustments`). Any scope
the server doesn't register is rejected as `unknown scope` when you add it
(`+scope`) or name it in a bare list. A `-scope` removal isn't checked — a
name that isn't in the set is silently ignored.

Signing in without network access, or against an older server, falls back to
camy's own compiled-in list.

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

Grant only what you need — `--scopes all` is convenient but broader than
most keys should be.

## Signing in again

With `camy auth login --code`, signing in again from the same machine reuses
the same machine-named key (`camy-cli @ <hostname>`) rather than piling up a
new one every time. What happens to that key depends on whether you passed
`--scopes`:

- **No `--scopes`**: camy **rotates** the existing key in place. Rotation
  keeps the key's current scopes — if that differs from what you'd get from
  a fresh grant, camy tells you so and points at `--scopes` to change them.
- **Explicit `--scopes`** (even one that matches what's already granted):
  camy revokes the existing key and mints a fresh one with exactly the
  scopes you asked for.

A key that's expired or in its grace period also can't be rotated — camy
revokes and mints fresh in that case too, regardless of `--scopes`.

For the default browser flow, the requested scopes are sent when the sign-in
starts, and the server decides how the machine's key is reused.

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

See [`camy auth status`](reference/camy_auth_status.md).

## `camy auth logout` and `--revoke`

```bash
camy auth logout
```

Removes the key from this machine — the keychain entry or fallback file —
and clears its cached scopes and expiry. This needs no confirmation and
always succeeds locally, even if the key was already invalid.

```bash
camy auth logout --revoke
```

Also revokes the key on the server, so it stops working everywhere, not just
here. The server-side revoke is best-effort: if camy can't reach the API, or
can't match the stored key to a row in your key list, it still removes the
local key and reports success. Check with `camy keys list`, or revoke by id
with `camy keys revoke`.

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
account — short id, prefix, name, and when each was created and last used.
`camy keys` with no subcommand runs the same listing.

```bash
camy keys rotate <id>
camy keys revoke <id>
```

`rotate` replaces a key with a new one carrying the same scopes and prints
the new full key once, to stdout. `revoke` kills a key server-side
immediately. Both take a short id prefix (at least 4 characters) or a full
id, and both ask for confirmation unless you pass `--force`.

Neither command touches the key stored locally on this machine. If you
rotate the key your current profile is actively using, re-store the new
value with:

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
