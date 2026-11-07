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
  ! path       not on PATH
               add /usr/local/bin to PATH
  ✓ version    v1.0.6 (darwin/arm64)
  ! keychain   exit status 154
               keys fall back to a 0600 file in the state dir
  ✗ auth       no key on profile default
               camy auth login
  · render     256 colours · dark ground (default) · 120 columns · hyperlinks no
  ! terminal   no inline graphics — iTerm2 or kitty unlock camy computer peek

  one thing is broken and everything below it is unknown, not fine
camy: some checks failed
      the ✗ row above names the fix
```

`✓`, `!`, `✗` and `·` mark ok, warning, failure and a neutral note — `+`,
`!`, `x` and `-` in a non-UTF-8 locale, and the words `OK`, `NEEDS`,
`FAIL` and `NOTE` in `--accessible` mode. A row's fix, when it has one, is
the line under it.

[`camy doctor`](reference/camy_doctor.md) runs its checks in this order.
`path` appears only when the binary's directory isn't on `$PATH` — or, for
an npm install, when no `camy` on `$PATH` leads back to it — `api` only
when a key is stored, and `terminal` only when your terminal can't draw
inline images:

| Check | What it verifies | Can fail the command? |
| --- | --- | --- |
| `binary` | The path of the running executable. | No — always ok |
| `path` | Whether the binary's directory is on `$PATH` — or, for an npm install, whether some `camy` on `$PATH` leads back to it. Only shown when it isn't. | No — warning only |
| `version` | The installed version and platform. | No — always ok |
| `keychain` | A round-trip write/delete against your OS keychain. | No — warning only |
| `auth` | Whether a key is stored, and whether the server still accepts it. | **Yes** |
| `api` | Reachability and latency to your `api_url`. Shown whenever a key is stored. | **Yes** |
| `render` | How camy draws in this terminal: colours, light or dark ground, width, and hyperlinks. | No — a note |
| `terminal` | Inline-image support in your current terminal. Only shown when it's missing. | No — warning only |

Only `auth` and `api` can fail the command. Every other row is
informational, so an otherwise-healthy machine with a flaky keychain, no
`PATH` entry, or a plain terminal still exits 0.

When your key works but can't run commands on your cloud computer, a
second `auth` line says so:
`this key can't run commands on your cloud computer; run camy auth login to add that`.
[`camy auth status`](reference/camy_auth_status.md) prints the same line.

Three things trip exit 1: not signed in, a stored key the server no longer
accepts, or an API camy can't reach at all. When the API can't be reached,
the `api` row fails with the host that didn't answer and `auth` reads
`not checked — needs the api`, so nothing is claimed about the key.

Add `--json` for a script-readable array of `{"name","ok","info"}` objects.
Each carries `"warn": true`, `"note": true` and a `"fix"` string only when
it has one; those keys are omitted otherwise. Test truthiness
(`select(.warn)`) rather than comparing against `false`, since the exit
code alone reflects only `ok`:

```bash
camy doctor --json | jq '.[] | select(.ok == false)'
```

## Common situations

### A server refusal (exit 1)

When the server turns a request down for a reason camy has no name of its
own for, the message carries the server's own sentence, and the request id
follows when the server tagged the request. Most refusals (HTTP 400, 422
and similar) put the HTTP status first:

```text
camy: HTTP 400: That code is invalid or has expired. Request a new one.
      request <id>
```

A validation refusal (HTTP 422) names the field it didn't accept, as in
`camy: HTTP 422: email: Field required`. A few statuses read differently. A
409 is the server's sentence alone, with no status. A 404 reads
`not found: <sentence>`. A 403 that camy can't read as anything more
specific reads `blocked at the edge or forbidden: <sentence>`, with the hint
`if this persists it's us, not you`. If the sentence doesn't tell you
what to change, include that request id in a bug report; see
[Getting request IDs for support](#getting-request-ids-for-support).

Many 403s do read as something more specific: a missing scope, a refused
key, your plan or your credits, and the account and app-only refusals under
[Not signed in](#not-signed-in-exit-3). Where Camy isn't offered in your
country or region, a sign-in or any other command reads
`Camy is not available in your country or region.`, and publishing a site
from the canvas, or changing a published one, reads
`Publishing is not available in your country or region.` Both exit 1 with
no hint: trying again won't change the answer.

A server fault (HTTP 5xx) is exit 1 as well, with the hint `try again`. It
reads `camy.ai had a problem`, followed by `(request <id>)` when the server
tagged the request. When a 502, 503 or 504 carries the app's own sentence,
such as `Couldn't reach the app.`, that sentence replaces the generic one,
and when that sentence already says to try again there is no second
`try again` hint under it.
That copy applies unless a verb rewords it. On a custom app,
[`camy connectors check`](reference/camy_connectors_check.md),
[`resume`](reference/camy_connectors_resume.md) and the approval in
[`review`](reference/camy_connectors_review.md) replace
`camy.ai had a problem` with
`couldn't finish reading <name>'s tools — camy.ai may not have reached it`,
put the request id on its own line, and give the hint
`camy connectors list shows <name>'s status · try again in a moment`.
`camy inbox send` rewords its hint, below.

A write that fails with a server fault, or on a connection that broke after
the request went out, may still have gone through. Check before you retry
it. An answer that stops arriving partway counts as such a broken
connection: it fails on the `can't reach <host>` card, exit 1, never as an
empty success. [`camy inbox send`](reference/camy_inbox_send.md) says so
in place of the retry hint: `check your Sent folder before retrying — it may have gone out`,
or `check camy inbox outbox before retrying — it may already be queued` for
a send scheduled with `--at`. When you gave no `--provider`, either one goes
on with ` · if it didn't, retry with --provider gmail|outlook`. On the
connection-failure card the same text is an `already sent?` row.

### Usage errors (exit 2)

```text
$ camy approvals approve
camy: requires at least 1 arg(s), only received 0
      camy approvals approve --help shows usage
```

A missing argument or an unknown flag. The hint names the exact `--help` to
read.

A value the CLI rejects locally — `--channel bogus`, `--timeout 5000`,
[`camy mode`](reference/camy_mode.md) `fast` — is exit 2 too, but its hint
names the flag's own contract, or there is no hint line at all.

A value the server would reject is caught the same way, before anything is
sent: a `--limit` outside the range a listing accepts, or a
[`camy capture`](reference/camy_capture.md) longer than a capture holds. The
message names the limit:

```text
$ camy inbox -L 500
camy: --limit takes 1 to 200
```

A chat message too long to send in one piece, over 64 KB, is refused
before the message is sent. A one-shot `camy chat` refuses it before it
opens the chat connection, with
`that message is too long to send (<size>; the limit is 64 KB)` and the hint
`save it to a file and send it with --attach`. Any `--attach` files, and a
piped block camy uploaded for you, have gone up by then. In the REPL and the
full-screen app the hint is `trim it — or save it to a file and attach that`.
When camy.ai refuses the message itself, it reads
`that message is too long to send`, with no size. A long block piped into
`camy chat` is attached for you instead, except in a `--temp` chat; see
[Stdin](scripting.md#stdin).

A typo in the command name is a usage error as well, with a suggestion when
one is close enough:

```text
$ camy nosuchcmd
camy: unknown command "nosuchcmd" for "camy"
      camy --help lists its commands
```

So is a help topic camy doesn't have, as in `camy help nope`, which reads
``Unknown help topic [`nope`]``, and an `--api-url` or `CAMY_API_URL` that
isn't a valid address:

```text
$ camy --api-url not-a-url status
camy: config: api_url "not-a-url" (from flag) must be an https:// URL (http://
      is allowed only for localhost)
```

An account that still needs your month and year of birth stops every
command and chat turn with exit 2 until you answer:

```text
! Camy needs your month and year of birth before it can continue.
  Answer at https://camy.ai/p/account/age
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

Those two lines are what you see when no key is stored. When the server
turns down a stored key, a terminal draws a card instead, and the card says
why when the server does:

| Card title | Message | When |
| --- | --- | --- |
| `your sign-in expired` | `your session expired <date>` | camy recorded an expiry for the stored key, and that moment has passed |
| `your sign-in expired` | `your key expired` | the server says the key expired, and camy has no past expiry on record for it |
| `this key was revoked` | `this key was revoked — it no longer works` | the key was revoked, or rotated and its grace window has passed |
| `not signed in` | `not signed in` | any other refusal of the key |

Every one of them has `camy auth login` as its fix. On the two expiry cards
the hint `camy auth login — one click renews it` appears only in the
`--json` error object.

That table applies to ordinary commands. On the chat connection, as in
`camy chat`, `camy chat attach` and `camy approvals approve --wait`, a
refused key draws `not signed in` whatever the reason, or
`your sign-in expired` with `your session expired <date>` when camy recorded
an expiry that has passed. The fix is still `camy auth login`. Two
refusals there say more: a key without the scope chat needs gets the
missing-scope refusal below, and an account refused for age says so, as
under [Account refusals](#account-refusals-exit-3).

A 403 that refuses the key itself, rather than the request, is exit 3 too.
It prints the server's own sentence, such as `Account is not active`, with a
hint that says what does work. A terminal holding its computer's key
instead of its own sign-in is told that `camy auth login` signs it in with
its own.

When camy.ai couldn't look the key up at all, that isn't a verdict on the
key, and camy never reads it as one. A command exits 1 with the server's
sentence or `camy.ai couldn't check your key just now`; a chat connection
exits 7. Nothing about your key changed, so try again.

### Only in the Camy app or at camy.ai (exit 3)

camy.ai lets no API key do some things, such as changing a setting that
loosens a safeguard, exporting your data, billing, and setting up or
resizing your cloud computer. The terminal always signs in with an API
key, so these exit 3 with camy.ai's own sentence and a hint that says
where to go:

```text
$ camy vm resize large
camy: Your Desktop can only be set up or resized from your signed-in Camy app or
      browser, not with an API key
      do it in the Camy app or at camy.ai — the terminal always signs in with an
      API key
```

Signing in again doesn't change this. Do it in the Camy app or at camy.ai.
[`camy vm resize`](reference/camy_vm_resize.md) says so at once, before it
reads anything or asks you to confirm.

### Account refusals (exit 3)

Signing in to an account that is scheduled for deletion says when it will
be deleted, in this computer's local time, and how to cancel. There is no
command for cancelling; it happens on the web:

```text
camy: Your account is scheduled for deletion on March 4, 2027 at 3:04 PM.
      To cancel, sign in at camy.ai and choose Cancel deletion.
```

When camy.ai gives no date, the first line is
`Your account is scheduled for deletion.`

An account closed because Camy is only for adults stops every command and
chat turn:

```text
✗ This account has been closed because Camy is available only to adults.
  If this is incorrect, request age verification at https://camy.ai/p/account/age
```

If camy.ai can't read the account's age record just now, the command
reads `camy.ai had a problem` with the hint `try again`, and exits 7.

### Missing scope (exit 3)

```text
camy: this key lacks a required scope
      API key missing required scope(s): datasets:write — mint one: camy auth login --scopes +datasets:write
```

The key is valid but wasn't granted the scope the command needs. The hint
starts with the server's sentence, then names the scope in the `--scopes`
grammar: `+datasets:write` signs you in with the default scopes plus that
one. When the server says any one of several scopes will do, the hint says
`any one of them will do` and names the first. When it names no scope camy
can read, the hint ends `mint a key that has it: camy auth login --scopes +<scope>`.
`--scopes all` still grants every scope, if you want that instead.

Chat needs `chat:read`. A key without it stops a chat turn at once, with
this refusal and a hint ending `camy auth login --scopes +chat:read`,
instead of reconnecting again and again. The REPL or the full-screen app,
open with nothing running, says it once, followed by
`— quit, then camy auth login`.

A key that may not offer this computer's local tools to Camy isn't refused
outright. The full-screen app says why once, in camy.ai's words or as
`This API key can't register local tools. Run camy auth login to sign in with a key that can.`,
and the chat goes on without local tools. A one-shot `camy chat` goes on
without local tools too and doesn't print the line.

`workspace:exec`, which [`camy vm exec`](reference/camy_vm_exec.md) and
[`camy vm shell`](reference/camy_vm_shell.md) need, is in the default set,
so a plain `camy auth login` key has it. A key minted before the scope
existed, or one minted without it on purpose, gets the refusal. That hint
ends
`run camy auth login to sign in again; the new key can run commands in your workspace`.
`camy vm exec` reports the refusal as its own failure, exit 255.
`camy auth status` and `camy doctor` warn about such a key before you
try. See [Scopes](authentication.md#scopes).

### Checkpoint pending, in a script (exit 4)

```text
checkpoint <id> requires approval:
  camy approvals approve <id>
```

A chat turn paused for a human decision and the process couldn't ask —
`--no-input`, any machine output (`--json`/`--jq`/`--template`), or no
`/dev/tty` to prompt on. Nothing failed. When the card is a question, the
handle names the verb that answers it:

```text
checkpoint <id> is a question — it's answered, never approved:
  camy approvals answer <id> "…"
```

A command on your own machine that would run without asking at a terminal
doesn't stop here under `--no-input` or with no `/dev/tty`: it runs
headless too. Under `--json`/`--jq`/`--template` the local bridge is off
for the run, so no command runs on your machine.

Resolve it out of band with [`camy approvals`](reference/camy_approvals.md)
`approve`, `deny`, or `answer`; the whole model is in
[Approvals](approvals.md).

Add `--wait` to `approve`/`answer` to stream the resumed turn right there,
re-join it later with [`camy chat attach`](reference/camy_chat_attach.md),
or read the result with [`camy chats show`](reference/camy_chats_show.md).

`camy approvals approve` and `deny` exit 4 too when the request was edited
somewhere else after `camy approvals show` or a `camy approvals --json`
listing showed it, on the same profile within a day. Nothing runs, the card
still waits, and the hint is `camy approvals show <id>`: read what it asks
now, then decide again. A row seen only in the `camy approvals` table is
answered as it stands.

### Rate limited (exit 5)

```text
camy: rate limited
      retry in 12s
```

The API returned HTTP 429. `GET` requests already retry up to four times on
your behalf with server-driven backoff before giving up. A write never
retries automatically, so a 5 from one of those is yours to retry.

When the server sends a `Retry-After`, as seconds or as a date, the hint
names the wait; otherwise it says `retry shortly`. A `GET` retries on its
own only while that wait is two minutes or less. A longer one ends the
command at once instead of retrying into the same refusal, and the hint
names the wait in minutes, hours or days, as in `retry in about an hour`.
However large the value, camy gives up cleanly with exit 5.

One limit isn't about time. When you already have as many active
schedules as your account allows,
[`camy schedule create`](reference/camy_schedule_create.md) and
[`camy schedule resume`](reference/camy_schedule_resume.md) exit 5 with
camy.ai's own reason instead of `rate limited`, and no retry hint. Waiting
won't help: delete one with `camy schedule delete ID`, or pause one with
`camy schedule pause ID`, first.

The chat connection has rate limits of its own, and they exit 5 as well.
Your account can hold only so many open connections at once:

```text
camy: camy.ai has too many connections open for this account
      close another camy or browser tab, or retry in a moment
```

A connection refused as it opens reads
`the chat connection couldn't be opened`, with a hint that says why: too
many chat connections, or connections from your network refused (HTTP
403), usually a connection-rate limit. A message the server rate-limits,
and a turn that can't start because every turn slot on the account stayed
busy, exit 5 too.

### Plan or credits (exit 6)

```text
camy: your plan doesn't include this
      <camy.ai's sentence> — camy.ai/pricing ↗
```

The API returned HTTP 402, or a 403 that means paid tier only, rather than
an auth problem. The hint puts the server's own sentence, which usually
names the tier you'd need, ahead of the pricing link. A 402 draws a
card instead of two lines, with `camy.ai/p/plan` and `camy mode quick` as
its fixes. There's nothing to fix client-side.

Running out of credits is exit 6 too, and says so. Outside a chat turn the
message is `you're out of credits`, never a plan or a missing-scope error.
A 403 that carries only a sentence prints two lines, with the server's
sentence as the hint. A 402, or the structured refusal starting a
workspace can send, draws a card whose fix is
`camy.ai/p/plan`, where you add credits; otherwise wait for the daily
refresh. Under `--json` the error's `hint` carries the server's sentence.
For the structured workspace refusal it reads
`add credits, or wait for the daily refresh`, and names how many credits
the action needs against what you have only when the server sends both
figures, and when they refresh when the server says.

A `camy chat` turn refused for credits is different: the server's own text
appears in the turn, and the process exits 6 with no further error line and
no `--json` error object. See [Exit codes](exit-codes.md#6--plan).

When camy.ai holds the turn for a top-up instead of dropping it, a terminal
draws a card headed `NOT ENOUGH CREDITS` after that text, never a question
about resuming. It shows what you asked, how long the hold lasts when the
server says, `add credits, then say continue`, and `camy.ai/p/plan` as the
place to add them. A one-shot `camy chat` exits 6 on it. Under `--json` the
hold arrives as a `resume_offer` event whose `stop_reason` is
`credit_budget` or whose `ceiling_axis` is `wallet`; see
[NDJSON for streams](scripting.md#ndjson-for-streams).

### Workspace asleep (exit 7)

```bash
camy vm exec --no-wake -- pytest -q
```

`--no-wake` refuses to spend a multi-minute silent wake-up on a stopped or
sleeping workspace. Drop it to let the workspace wake normally, or start it
yourself first with [`camy vm start`](reference/camy_vm_start.md). See
[Workspace](workspace.md).

With no workspace at all, `camy vm exec` doesn't create one on your
behalf. It counts that refusal as its own failure, so it exits 255, not 7:

```text
camy: you don't have a workspace yet — exec won't create one
      set one up in the Camy app or at camy.ai (camy vm sizes lists what it costs)
```

Setting one up happens in the Camy app or at camy.ai, never from the
terminal; see [Only in the Camy app or at camy.ai](#only-in-the-camy-app-or-at-camyai-exit-3).

### Chat service unavailable (exit 7)

A chat connection that camy.ai can't serve right now exits 7, not 1:

- The connection is refused as it opens because the chat service is down
  (HTTP 502, 503 or 504): `the chat connection couldn't be opened`, with a
  hint naming the status and `camy doctor`.
- camy.ai couldn't take the connection or check your key just now:
  `camy.ai couldn't take this connection just now` or
  `camy.ai couldn't check your key just now`. Your key is fine.
- camy.ai was restarting: `camy.ai is restarting`. For a new message camy
  reconnects and resends up to three times first, but never resends a
  message whose attached files the server had already taken; attach them
  again and resend it yourself. An attach, as in `camy chat attach` or
  `camy approvals approve --wait`, exits 7 straight away. A reconnect
  refused for the key or for rate exits 3 or 5 instead.

Retry in a moment. A chat that is already mid-turn is different: it exits
1 with a hint to rejoin it with
[`camy chat attach`](reference/camy_chat_attach.md).

### Not on for your account yet (exit 7)

A feature camy.ai hasn't turned on for your account says so and exits 7,
as in `Searching your calls isn't on for your account yet.` or
`Linking a computer isn't on for your account yet.` Nothing is wrong with
your key or your install.

A [`camy device`](reference/camy_device.md) command that needs this Mac to
be linked exits 7 as well when it isn't, with
`This Mac isn't linked to a Camy account.` and the hint
`camy device enroll`.

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

### Quit (exit 131)

When camy gets SIGQUIT, which Ctrl-\\ sends from a terminal, it exits 131
at once, with no error line and no JSON error object. If you are reporting
a hang, set `CAMY_DEBUG_DUMP=1` before you reproduce it: SIGQUIT then prints
Go's goroutine dump to stderr and exits 2. See
[Exit codes](exit-codes.md#131--quit).

## Keychain unreachable and the 0600 fallback

If `camy doctor`'s `keychain` row warns, your OS keychain refused the
scratch write-then-delete `camy` tried:

```text
! keychain   exit status 154
             keys fall back to a 0600 file in the state dir
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
installer again. The installer needs `minisign`; see
[The one-line installer](installation.md#the-one-line-installer).

The installer lands in `~/.local/bin`, which you own, and adds that
directory to the front of `PATH` in your rc file for new shells; the card
then asks you to make sure `~/.local/bin` really comes before the blocked
directory.

A Homebrew-managed `camy` is refused before any of this: `camy update`
detects it and points you at `brew upgrade camy` instead. An npm-managed
one is refused the same way, pointing at `npm update -g @camy/cli`;
`camy uninstall` behaves the same for both. `camy update --check` still
works on either, and names that command. Only a binary that lives in
Homebrew's own `Cellar` counts as Homebrew-managed, so a `camy` you copied
straight into a Homebrew `bin` folder updates in place. See
[Updating](installation.md#updating) and [npm](installation.md#npm).

### When the new version doesn't start

`camy update` runs the new binary once before it reports success. If the
new binary doesn't start, or doesn't report the version it was meant to be,
camy puts the version you were running back in place and exits 1. That case
prints no message of its own in a terminal, so run the update again with
`--json` to see what happened:

```bash
camy update --json
```

```json
{
  "current": "1.0.3",
  "latest": "1.0.4",
  "rolled_back": true,
  "smoke_failure": "exit_nonzero",
  "smoke_ok": false,
  "staged": true,
  "update_available": true,
  "updated": false
}
```

`smoke_failure` is `not_run`, `timeout`, `exit_nonzero` or
`version_mismatch`. `rolled_back: true` means the version you were running
is back in place. `rolled_back: false` means camy couldn't
keep or restore its copy, and the new binary is still in place: reinstall
the version you had with the installer, pinned with `CAMY_VERSION` (see
[Installation](installation.md#environment-variables)). Under `sudo`, camy
keeps its copy only in a folder that belongs to root, so when the update
folder is yours, as it is when `sudo` keeps your `HOME`, `staged` is
`false` and there is nothing to put back.

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
- `NO_COLOR=1` or `CLICOLOR=0` turns it off unless an explicit
  `--color=always` overrides it. `TERM=dumb` turns it off even then.
- `--color=always` turns it on wherever the terminal can carry it —
  `TERM=dumb` still yields no color, and an empty or unset `TERM` gets 16
  colours. `FORCE_COLOR` and `CLICOLOR_FORCE` do the same.
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

## Local commands and the sandbox

Commands Camy runs on your machine go through the local command sandbox,
set with `--sandbox` or `CAMY_LOCAL_SANDBOX`. Left unset, it enforces only
where this machine can fully contain a command, and otherwise observes.
When you ask for `enforce` yourself on a machine that can't contain a
command, camy refuses to run it, saying this machine cannot contain a
command and why, instead of running it without the sandbox. Install what
the reason names, or use `--sandbox observe`.

On Linux the sandbox is bubblewrap (`bwrap`):

- camy uses only a bubblewrap installed for the whole system, such as your
  distribution's `bubblewrap` package. A copy in your home folder isn't
  used, so if that was your only one, install the system package.
- camy checks that bubblewrap can really start a sandbox. Where it can't,
  as in some containers, the sandbox reads unavailable with bubblewrap's
  own reason, and an unset mode observes.

`local_sandbox` in `camy version --json` shows what this machine does:
`enforcement` is `full` when it can contain a command and `unavailable`
when it can't. See
[The boundary, and the sandbox](local-bridge.md#the-boundary-and-the-sandbox).

## Getting request IDs for support

```bash
camy --verbose --json status
```

With `-v`/`--verbose`, most commands print one line on stderr for each
request they make, with the method, the path (never its query), the
status, the time it took, and the request id when the server sent one:

```text
GET <path> 200 · 182ms · req <id>
```

Request IDs also arrive in the JSON error object with `--json`, at the end
of a 5xx message as `camy.ai had a problem (request <id>)` or
`<the app's own sentence> (request <id>)` unless a verb rewords it, and as
a last `request <id>` line under any other exit-1 error from a request the
server tagged.

That object carries `request_id` whenever the failing call was a REST
request the server tagged with one. It is empty for errors that arrive over
the chat WebSocket, which don't carry a request ID — see
[the JSON error shape](exit-codes.md#the-json-error-shape).

`-v` adds three more things: a one-line note on which credential source a
command used (`auth: <prefix>… key from <source>`), the agent's per-step
trace lines while a chat streams, and the underlying error when a chat
connection can't be opened. Combine it with `--json` when something fails.

When filing a [bug report](../SUPPORT.md), include the output of
[`camy version --json`](reference/camy_version.md) and `camy doctor` —
neither prints anything secret — plus the `request_id` from the failing call
if there is one.

## Where state lives, and what's safe to delete

camy uses up to three directories on disk: cache, state, and config. The
state directory, `~/.local/state/camy/`, holds one subdirectory per profile
and one `update/` subdirectory shared by every profile, so the table gives
the update copy its own row. The exact paths, and how the
`XDG_*` variables override them, are in
[Configuration: Where things live](configuration.md#where-things-live). camy
does not write a separate log file; everything it prints goes to your
terminal's own scrollback.

camy needs `HOME` to be an absolute path, unless `XDG_CONFIG_HOME`,
`XDG_STATE_HOME` and `XDG_CACHE_HOME` are all set to absolute paths. When
it isn't, every command stops with exit 1:

```text
camy: config: HOME is not an absolute path, so camy cannot find its config,
      state or cache directory — set HOME (or XDG_CONFIG_HOME, XDG_STATE_HOME
      and XDG_CACHE_HOME) to an absolute path
```

A relative `XDG_*` value is ignored, and the default under `HOME` is used
instead.

| Directory | What it holds | Deleting it |
| --- | --- | --- |
| Cache — `~/.cache/camy` | Reserved. Nothing is written here today, so the directory usually doesn't exist. | Safe any time. [`camy uninstall`](reference/camy_uninstall.md) removes it if it's there. |
| Per-profile state — `~/.local/state/camy/<profile>/` | The 0600 credential fallback file (only written when your keychain isn't reachable), your cached granted scopes and key expiry, the last chat id that [`camy chat`](reference/camy_chat.md) `-c`, `camy chat attach`, [`camy canvas`](reference/camy_canvas.md), and `camy approvals … --wait` fall back to, your chat input history, the chat mode you set with `camy mode`, any local-tool results still waiting to be replayed, your local-bridge trust grants, and, for a day, the ids and versions of the approvals camy last showed you. | Revokes your trust grants, so every trusted command and path is prompted for again. Loses your history and last-chat pointer, resets your chat mode to `agent`, and clears the cached scopes and expiry. A later `camy approvals approve` or `deny` then answers the request as it stands. |
| Update copy — `~/.local/state/camy/update/` | The `camy` binary you were running before your last [`camy update`](reference/camy_update.md), readable only by you, kept so a new version that doesn't start can be put back. One copy, shared by every profile; the next update replaces it. | Safe any time. The next `camy update` keeps a fresh copy before it swaps. |
| `config.toml` — `~/.config/camy/config.toml` | Your settings, profiles, and aliases. | Resets everything to defaults. Doesn't touch your stored credential. |

Deleting per-profile state signs you out only if your key was living in the
fallback file rather than the keychain. A key in the keychain isn't touched:
you'd be left with a stale keychain entry and an empty state cache, which is
confusing more than harmful, but it isn't the clean way to sign out.

[`camy auth logout`](reference/camy_auth_logout.md) is the clean way — it
clears the keychain entry (or the fallback file) and the cached state
together.

`camy uninstall` offers to remove all three directories for you, separately
from removing the binary. The update copy goes with the state directory it
lives in. See [Uninstalling](installation.md#uninstalling).

## See also

- [Exit codes](exit-codes.md) — the frozen table, the JSON error shape, and every code in depth
- [`camy doctor`](reference/camy_doctor.md), [`camy status`](reference/camy_status.md), [`camy auth status`](reference/camy_auth_status.md)
- [Installation](installation.md) — updating, uninstalling, and the installer's own PATH wiring
- [Authentication](authentication.md) — sign-in, scopes, and where keys are stored
- [Terminal output and accessibility](terminal.md) — color, `--accessible`, paging, and inline images
- [Scripting with camy](scripting.md) — `--json`, `--no-input`, and the machine-output contract
- [SUPPORT.md](../SUPPORT.md) — where to file a bug or ask a question
