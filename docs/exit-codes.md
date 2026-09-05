# Exit codes

Every `camy` command ends with one of ten exit codes. [`camy vm exec`](reference/camy_vm_exec.md)
is the one exception: it also mirrors your remote command's own 0-254 code.

Scripts and CI should branch on the code, not on the wording of an error
message. Message text is free to change between releases; the codes are
[frozen for 1.x](#stability).

The binary never prints its own exit code — read it from your shell
(`echo $?`) or your process runner. What it does print is either a two-line
human message on stderr or, under [`--json`](scripting.md), a single JSON
object on stderr.

## The table

```bash
camy help exit-codes   # the same table, from the binary
```

| Code | Meaning | JSON `code` |
| --- | --- | --- |
| 0 | success | — |
| 1 | runtime or API error | `runtime` |
| 2 | usage error | `usage` |
| 3 | auth — bad key or missing scope | `auth` |
| 4 | checkpoint pending — approve out of band, then re-attach | `checkpoint_pending` |
| 5 | rate limited | `rate_limited` |
| 6 | plan — payment required or a paid-tier feature | `plan` |
| 7 | unavailable — workspace asleep with `--no-wake`, or the workspace terminal unreachable | `unavailable` |
| 8 | checkpoint denied — a human said no | `checkpoint_denied` |
| 255 | `camy vm exec` only: camy's own failure | `runtime` |

## What each code means

### 0 — success

The command did what it was asked. Stderr carries only the command's own
progress and chrome lines — a workspace waking up, `camy vm exec`'s
mirrored-exit note, `--verbose` request ids — plus, at most once a day, an
update note. An extra line names a non-default API origin when `--api-url`,
`CAMY_API_URL`, or config sets one.

### 1 — runtime or API error

Something went wrong that isn't a usage mistake, an auth problem, or one of
the other named conditions below: a failed HTTP call, a server-side error, a
[`camy chat`](reference/camy_chat.md) turn hitting `error` mid-turn, or
[`camy update`](reference/camy_update.md) refusing to overwrite a binary it
doesn't own.

Some runtime errors carry a [diagnosis card](#diagnosis-cards) instead of the
plain two-line message — `camy update` explaining exactly why it wouldn't
touch the installed binary, with the paths involved and a runnable fix. See
[Installation](installation.md) and
[`camy doctor`](reference/camy_doctor.md).

### 2 — usage error

```bash
camy approvals approve
```

```text
camy: accepts 1 arg(s), received 0
      camy approvals approve --help shows usage
```

What exits 2:

- A missing argument, an unknown command, or an unknown flag.
- A value the CLI rejects before any request goes out — an unparseable
  `--until`, an `--at` that isn't in the future.
- A short ID that turns out to match more than one row once the list comes
  back.
- A destructive-operation confirmation prompt running headless
  (`--no-input` or no controlling TTY) without `--force`.

Irreversible operations are stricter: `--force` does not satisfy them.
Interactively they ask you to type a fixed confirmation word back —
`uninstall` for [`camy uninstall`](reference/camy_uninstall.md), `revoke` for
[`camy auth logout`](reference/camy_auth_logout.md) `--revoke`. Headless,
they exit 2 until you pass that word as `--confirm <word>`.

### 3 — auth

The stored API key is missing, invalid, or lacks the scope the command
needs. See [Authentication](authentication.md).

### 4 — checkpoint pending

A chat turn hit a checkpoint — a pause for a human decision — and the
process couldn't ask: it was running with `--no-input`, under `--json`, or
with no `/dev/tty` to prompt on. A 120-second prompt timeout is treated the
same way: never approved, never denied, left pending.

The message carries the checkpoint's ID, so you can act on it separately:

```text
checkpoint <id> requires approval:
  camy approvals approve <id>
```

Resolve it from another session with
[`camy approvals`](reference/camy_approvals.md) — `approve`, `deny`, or
`answer`, described in full in [Approvals](approvals.md).

`approve` and `answer` take `--wait` to stream the resumed turn straight back
to you; otherwise [`camy chat attach`](reference/camy_chat_attach.md)
`--chat <id>` re-joins it, or [`camy chats show`](reference/camy_chats_show.md)
`<id>` shows how it continued.

A `--temp` chat can never hold an approval at all. It fails closed with its
own message instead of a checkpoint ID, since there is no chat row to attach
a pending approval to.

### 5 — rate limited

The API returned HTTP 429. How much retrying already happened depends on the
request:

- `GET` requests through the wrapped commands retry a couple of times with
  server-driven backoff before giving up.
- The [`camy api`](reference/camy_api.md) escape hatch and file uploads make
  exactly one attempt.
- A non-`GET` request — a write — never retries automatically.

So a 5 on the last two means the retry is yours to make.

### 6 — plan

The API returned HTTP 402, or a 403 that means "available on a paid tier,"
rather than an auth problem. The message is `your plan doesn't include
this`, with `camy.ai/pricing` as the hint.

A chat turn whose entire answer is a plan-or-credit refusal also exits 6.
The refusal has already been shown as part of the turn, so no extra error
line — and no `--json` error object — follows it.

### 7 — unavailable

```bash
camy vm exec --no-wake -- pytest -q
```

The thing the command needs isn't reachable right now. Two cases produce
this today:

- `camy vm exec --no-wake` against a stopped or sleeping workspace: it
  refuses to spend a multi-minute wake-up silently. See
  [Workspace](workspace.md).
- [`camy vm shell`](reference/camy_vm_shell.md) when the workspace terminal
  socket won't open or won't complete its handshake. Check
  [`camy vm status`](reference/camy_vm_status.md), then
  [`camy vm start`](reference/camy_vm_start.md).

### 8 — checkpoint denied

Exit 8 belongs to the turn that got told no, not to the act of saying no. It
comes from two places:

- A human rejecting an approval at this process's own prompt during a live
  chat turn — the interactive `y/N` card a one-shot `camy chat` draws in a
  terminal.
- [`camy auth login`](reference/camy_auth_login.md) when you refuse the
  sign-in in the browser: it exits 8 with `you denied the sign-in — nothing
  was granted`, and nothing is stored.

Three refusals that do not exit 8:

- A denial inside the full-screen app or the REPL is just a decided card,
  and the session still exits 0 when you leave it.
- [`camy approvals deny`](reference/camy_approvals_deny.md) run on its own
  reports success and exits 0 when it records the denial.
- A `camy chat` turn where the agent carried on and finished some other way
  after a mid-turn no is a success and exits 0.

`camy chat attach` is blunter: any rejection during the turn it re-joined
exits 8.

### 255 — camy vm exec's own failure

`camy vm exec` follows the ssh convention. The command you ran on your
workspace can exit anything from 0 to 254, and that code is mirrored
straight to your shell — camy adds no error of its own, only a plain
`exit <n> — mirrored to your shell` note on stderr (suppressed under
`--json`, `--jq`, and `--template`).

A remote command that exits 255 or higher reaches your shell as 254, so a
mirrored code can never be mistaken for camy's own 255; the stderr note
still names the raw remote code.

255 is camy failing to make the exec happen at all — not signed in, a
network failure, the workspace unreachable, a workspace agent error — with
the reason on stderr.

Inside `camy vm exec` it replaces the ordinary code: an auth, rate-limit or
plan failure that would exit 3, 5 or 6 anywhere else exits 255 here, so a
failure camy hit while making the request itself can never be confused with
your remote command's.

Camy-side codes that still escape as themselves:

| Failure | Code | When |
| --- | --- | --- |
| a bad flag, or an unparseable `--jq`/`--template` expression | 2 | before anything runs remotely |
| `--no-wake` refusing to wake a stopped workspace | 7 | before anything runs remotely |
| a `--jq` or `--template` expression failing while rendering the result | 1 | after the run — replaces the mirrored code |

Under `--json` a camy-side 255 carries `"code":"runtime"` with `"exit":255`;
a mirrored remote code emits no error object at all. See
[`camy vm exec`](reference/camy_vm_exec.md).

## The JSON error shape

Under [`--json`](scripting.md) (or `--jq`/`--template`), a failing command
writes one JSON object to stderr instead of the two-line message, wrapped in
`error`:

```bash
camy status --json
```

```json
{"error":{"code":"auth","exit":3,"hint":"run camy auth login","message":"not signed in","request_id":""}}
```

| Field | Always present | Notes |
| --- | --- | --- |
| `code` | yes | the stable machine name from the table above |
| `exit` | yes | the numeric exit code |
| `message` | yes | the error text |
| `hint` | yes | second-line guidance; empty string when there is none |
| `request_id` | yes | the server request ID, or `""` when there isn't one |
| `checkpoint_id` | only on exit 4 | the pending checkpoint's ID |
| `title`, `details`, `fixes` | only on a diagnosis-card error | structured form of the [card](#diagnosis-cards) |

`request_id` is often empty: it's populated for errors that came back from a
REST call, but a chat turn's checkpoint and error frames arrive over the
WebSocket connection and never carry one.

## The human-readable shape

Without `--json`, most errors print two lines to stderr:

```text
camy: <message>
      <hint>
```

The `camy:` prefix is the CLI speaking in its own voice: it fronts every
two-line error, and also the startup notices that name a non-default API
origin or an ignored `api_url`.

A pending checkpoint that carries a checkpoint ID (exit 4) is printed
without it, in a neutral voice, because fail-closed is the CLI declining to
guess, not an error condition. The exit-4 cases that have no ID to hand
back — a `--temp` chat, for one — use the ordinary `camy:` voice.

### Diagnosis cards

A handful of runtime errors print a fuller card instead of the two lines —
today, `camy update`'s refusal to overwrite a binary it doesn't own. A card
has a titled header, the message, sometimes a chain of labeled details (for
example the path you ran versus the real binary it resolves to), and one or
more runnable fix commands, most with a short note under them.

The `hint` field in `--json` mode still carries the one-line collapse of
those fix steps, so a script reading `hint` loses nothing.

## Stability

This table, the JSON error shape, and the machine `code` names are frozen
for the entire 1.x series. A script that branches on exit code or on
`error.code` today will keep working across every 1.x release.

## See also

- [Scripting with camy](scripting.md) — `--json`, `--jq`, `--template`, and `--no-input`
- [Approvals](approvals.md) — the full checkpoint lifecycle behind exits 4 and 8
- [`camy status`](reference/camy_status.md), [`camy doctor`](reference/camy_doctor.md), and [`camy auth status`](reference/camy_auth_status.md) — checking what's wrong before you act on an exit code
