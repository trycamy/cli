# Scripting with camy

`camy` is meant to be driven by other programs. Data and chrome go to
different streams, machine output is stable, the exit codes are frozen, and
nothing ever blocks on a terminal behind a pipe. This page is the contract a
script can rely on.

The same contract ships inside the binary, in
[`camy docs`](reference/camy_docs.md) and the built-in help topics:

```bash
camy docs scripting
camy help exit-codes
camy help formatting
```

## The contract in five lines

1. **stdout is data, stderr is everything else.** Replies, JSON, tables and
   generated shell scripts go to stdout. Spinners, notes, traces, sign-in
   chrome, approval cards and every error go to stderr. `camy … | cmd` and
   `camy … 2>/dev/null` both do what you expect.
2. **`--json` is on every command, the JSON is stable, and streams emit
   NDJSON.** Machine output is never styled, whatever `FORCE_COLOR` or your
   terminal say.
3. **Exit codes are a public API.** They are frozen for 1.x. See
   [Exit codes](exit-codes.md).
4. **Headless runs fail closed.** With `--no-input`, a pause for a human ends
   the process with exit 4 and the approval id on stderr. Nothing is approved
   on your behalf.
5. **There is no yes-to-everything flag.** `--force` skips the confirmations
   camy itself asks before a destructive action. It cannot approve anything
   the agent asked for, and a prompt that times out never approves or
   denies.

## `--json` and machine mode

Plain `--json` prints indented JSON to stdout — here from
[`camy version`](reference/camy_version.md):

```bash
camy version --json
```

```json
{
  "arch": "arm64",
  "commit": "9f2c1ab",
  "local_sandbox": {
    "backend": "darwin",
    "enforcement": "full",
    "mode": "observe"
  },
  "os": "darwin",
  "version": "1.0.4",
  "wire_protocol": {
    "speaks": 2
  }
}
```

Illustration: `version` and `commit` are stamped into your build, and
`local_sandbox` and `wire_protocol` are described below. Those six keys are
the whole object.

`--jq` and `--template` switch a command to machine output on their own: any
one of the three puts the whole invocation into machine mode. Machine mode
also turns the [local bridge](local-bridge.md) off for that run and makes
every approval fail closed, because machine output must never emit a prompt.

### Listings, single things, and ids

Since 1.0.3 the shapes are uniform across commands:

- A **listing** (`camy jobs --json`, `camy inbox --json`, `camy keys --json`,
  `camy connectors --json`, …) is a JSON **array** of rows — never the
  server's envelope, and `[]` rather than `null` when it is empty, `--all`
  sweeps included. When a page fails partway through `camy jobs --all` or
  `camy webhooks deliveries --all`, the command emits
  `{"partial": true, "results": [...], "rows": N, "error": "..."}` so what
  was already fetched is never thrown away, as `camy api --paginate` does
  (below). `camy inbox --all` instead exits with the error and prints no
  rows.
- A command that **shows one thing** (`camy jobs show ID --json`,
  `camy approvals show ID --json`, …) emits an **object**.
- A verb that takes **several ids** (`camy approvals approve A B`,
  `camy tasks done A B`, `camy inbox archive A B`, …) emits one object when
  given one id — the shape it always had — and an array of per-id results
  (`{"ref", "id"?, "ok", "error"?}`) when given more; the exit code is the
  worst of the set, and every id is acted on even when one fails. A short
  ref or prefix that matched none of your rows carries no `id`, only the
  `ref` you typed. A full id is always echoed as `id`.
- Every id in `--json` is the **full** id. Human output prints typed short
  ids (`ap_789a`, `em_7f31`, `jb_aab2`, `tk_2b28`, `ob_` for outbox rows);
  every verb accepts the typed form, a bare prefix of at least four
  characters, or the full id. `--ids=hex` prints the pre-1.0.3
  eight-character form in human output; it is a compatibility flag, so
  don't build new scripts on it.
- `--raw` on a listing hands you the endpoint's own body instead of the
  array, for the wire shape; it does not apply to `--all` sweeps, and
  `camy approvals --json` stays narrowed (see below) with or without it.

Where a command wraps a server response that is not a listing, the JSON is
the server's own shape passed through unchanged. [`camy status --json`](reference/camy_status.md)
gives you `approvals`, `inbox_counts`, `jobs`, `workspace`, `credits`,
`run_meter` and `activity`; what is inside them is defined by the API, not by
the CLI, with `credits` the one exception below. `run_meter` holds context
and credit usage for a turn in progress, and is `null` unless a turn is
currently live on your last chat on this profile. `activity` holds the
server's counts of what Camy did in the last day, and is `null` when they
can't be read. Treat the keys camy itself documents as stable,
and treat a pass-through row as something that can gain fields.

Four shapes are worth knowing because they are camy's own, not the server's:

- `local_sandbox` in `camy version --json` (and `camy --version --json`) is
  camy's own: the `--sandbox` mode in effect, the OS mechanism behind it,
  and whether it is enforced. See [The local bridge](local-bridge.md).
  `wire_protocol.speaks` beside it is the highest version of the chat
  stream protocol this build understands, known without any connection.
- `credits` in [`camy status --json`](reference/camy_status.md) is a
  deliberately narrowed object, not the balance endpoint's whole body:
  `plan`, `monthly_remaining`, `daily_remaining`, `daily_max`,
  `daily_reset_at`, `purchased` and `welcome_grant`. It is `null` when the
  balance can't be read; the rest of the object is still emitted.
- [`camy doctor --json`](reference/camy_doctor.md) is an array of checks,
  each `{"name", "ok", "info"}` plus `"warn"` and `"fix"` when they apply.
  The exit code is driven only by `ok: false`; a row with `warn: true` never
  fails the command, so inspect `warn` per row if you care about it.
- [`camy approvals --json`](reference/camy_approvals.md) is a deliberately
  narrowed list — `checkpoint_id`, `family`, `subject_id`, `chat_id`,
  `kind`, `tool_name`, `prompt`, `parameters`, `status`, `created_at`,
  `expires_at`, plus `merchant` and `amount` (`{"value","currency"}`) on a
  computer checkout hold that carries them. Every row names its `family`. A row the checkpoint verbs
  act on is `"family": "checkpoint"`, with `subject_id` equal to its
  `checkpoint_id`. Any other decision waiting on you carries its own
  `family` and `subject_id`, and its `checkpoint_id` is `""`, so filter on
  `family` before you hand ids to `approve`, `deny` or `answer`.
  [`camy approvals show ID --json`](reference/camy_approvals_show.md) emits
  the full server row instead. The two shapes differ on purpose; do not
  assume one parser handles both.

### The error shape

In machine mode an error is usually a single JSON line on **stderr**:

```bash
camy status --json
```

```json
{"error":{"code":"auth","exit":3,"hint":"run camy auth login","message":"not signed in","request_id":""}}
```

These five keys are always present:

| Key | Meaning |
| --- | --- |
| `code` | stable machine name: `usage`, `auth`, `checkpoint_pending`, `rate_limited`, `plan`, `unavailable`, `checkpoint_denied`, `runtime` |
| `exit` | the process exit code, the same number your shell sees |
| `message` | one sentence describing what happened. A server refusal camy has no name of its own for reads `HTTP <status>: <server sentence>` for most 4xx statuses (400, 422 and similar), the server's sentence alone for a 409, `not found: <sentence>` for a 404, and `blocked at the edge or forbidden: <sentence>` for a 403 that isn't a scope, key, plan or credit refusal. A 5xx reads `camy.ai had a problem`, or the app's own sentence when a 502, 503 or 504 carries one, followed by `(request <id>)` when the server tagged the request |
| `hint` | the single next thing to try, or `""` |
| `request_id` | the server request id when a request happened, else `""` |

Two additions ride along when they apply:

| Key | When it appears |
| --- | --- |
| `checkpoint_id` | on a checkpoint-pending error — hand it straight to [`camy approvals approve`](reference/camy_approvals_approve.md) |
| `title`, `details` (rows of `{"label","value"}`), `fixes` (rows of `{"cmd","note"}`) | when the error carries a diagnosis card |

`hint` is the error's own one-line hint. On a card error it can carry
detail the card shows differently, such as the server's sentence, so it is
not a collapse of `fixes`.

stdout carries only data the command had already finished emitting. For most
failures that is nothing at all, but see `camy doctor` above, and `camy api
--paginate` and the `--all` sweeps of `camy jobs` and `camy webhooks
deliveries` below.

Three failures are deliberately silent instead: a non-zero remote exit code
mirrored by [`camy vm exec`](reference/camy_vm_exec.md), a turn the server
refused outright or held for credits (see NDJSON streams, below), and
[`camy update`](reference/camy_update.md) when the new binary doesn't start.
All three set the exit code and print no error object on either stream. The
update exits 1, and under `--json` it writes its result object to stdout,
with `updated: false`, `smoke_ok: false`, `smoke_failure` and
`rolled_back`; see
[When the new version doesn't start](troubleshooting.md#when-the-new-version-doesnt-start).
SIGQUIT (Ctrl-\\) prints no error object either: the process exits 131 at
once. Treat a non-zero `$?` as authoritative, not the presence of an error
line.

### NDJSON for streams

[`camy chat`](reference/camy_chat.md) under `--json` writes one JSON object
per line as the turn happens:

```bash
camy chat --json "summarize today" | jq -r 'select(.type=="final") | .text'
```

| `type` | Fields | When |
| --- | --- | --- |
| `start` | `chat_id`, `turn_id`, `tier` | the turn begins; `tier` is what the server actually used |
| `token` | `text` | a chunk of the streamed reply |
| `tool_call` | `name`, `status`, `param`, and `duration_ms` and `result_count` when the server sends them | a tool the agent invoked; `param` is the server's parameter for the call as text (JSON-encoded when it isn't a string, `""` when there is none), with secrets redacted |
| `collection` | the collection's own fields | a structured result block (emails, events, news, …) |
| `snapshot` | `text`, `active`, `status`, `message_id`, and `error` when the turn ended in one | an attach joined the turn, as `camy chat attach` and `approve --wait` do. `text` is the reply so far, and the `token` events after it carry only what it didn't already hold. `status` is `generating`, `paused`, `complete` and so on, or `""` when nothing runs. `message_id` is the turn joined, and `done` repeats it as `turn_id` |
| `checkpoint` | `id`, `kind`, `summary`, `tool_name`, `risk_level`, `prompt`, `description`, `expires_at`, and `choices` and `fields` when the card has them | the turn paused for an approval; see below |
| `checkpoint_replayed` | `id`, `status` | a card of this chat that no longer waits on anyone; see below |
| `action_confirmed` | `data`, the server's own frame | an approved action's outcome; see below |
| `retry` | `dropped_chars`, `attempt`, `reason` | the model restarted its answer; `dropped_chars` counts the characters of `token` text already sent that are now void |
| `resume_offer` | `chat_id`, `unsure`, and `held_until`, `stop_reason` and `ceiling_axis` when the server sends them | a turn in this chat was interrupted or held and can be resumed; `unsure` lists steps whose outcome is unknown. See below, and [An interrupted turn, offered back](chat.md#an-interrupted-turn-offered-back) |
| `last_reply` | `chat_id`, `message_id`, `created_at`, `text` | `camy chat attach` found nothing running, so it read back the chat's latest reply. Absent when the newest message is still unanswered |
| `warning` | `code` (`attachments_dropped`), `sent`, `accepted`, `message` | the server resolved fewer attachments than were sent, because an upload expired or was unknown; the agent never saw the rest. `sent` counts every attachment on the message, `--attach` files plus an automatic `stdin.txt`, and `accepted` is how many the server resolved |
| `final` | `text` | the complete reply text |
| `done` | `chat_id`, `turn_id` | the turn ended normally (plus `stopped: true` if you interrupted it) |
| `error` | `code`, `message` | the turn ended abnormally; see [Error codes in the stream](#error-codes-in-the-stream) |

A `checkpoint` event carries what a script needs to decide without a second
call. `tool_name`, `risk_level`, `prompt`, `description` and `expires_at`
are always present, as strings that may be empty. `description` is the
server's own account of the action, such as the command a workspace card
would run, or else the tool's arguments as `key: value` lines, the same
arguments [`camy approvals show`](reference/camy_approvals_show.md) prints.
`choices` (rows of `{"id","label","description"}`) and `fields` (rows of
`{"key","title","type","required"}`, plus `description` and `enum` when set)
appear only when the card has them. Secrets in any of that text are
redacted.

A `checkpoint_replayed` event reports, once, a card of this chat whose own
status is no longer `pending`, met when an attach re-checks the chat's
cards. It is never drawn and never ends the process with exit 4, and a card
this process answered itself is never reported. A `status` of `executing`
means an approved tool is still running: attach again for its outcome.

An `action_confirmed` event is the server's frame, verbatim under `data`:
`confirmed`, `resumed`, `executed` (`false` when the action did not run),
`error` and `message`. Only a frame with `resumed: true` and a boolean
`executed` is the outcome; an earlier one is the server's acknowledgement.
`exit_code` and `output_tail` (for a workspace command) and `url` (when the
action produced an address, such as a deploy) appear only when the server
sends them, which it doesn't on every path. When `exit_code` is there, read
it over `message`. When it isn't, `message` is the only field that carries a
failed command's exit code, as in
`Action ran, but the command failed (exit code 1): …`.

A `resume_offer` carries the hold's cause when the server gives one.
`stop_reason` `credit_budget` with `ceiling_axis` `wallet` is the
out-of-credits stop, and either value alone is read the same way: the turn
is held for a top-up, and a one-shot `camy chat` exits 6 on it, with no
`error` event and no error object.
`stop_reason` `turn_cost_ceiling` is a turn that reached its own cost
ceiling. `stop_reason` can also be `crash_effect_ambiguous`, a crashed turn
held with steps whose outcome is unsure, which a terminal heads
`INTERRUPTED — one step unsure` or `INTERRUPTED — <n> steps unsure`. Any
other value is a turn that reached another limit, headed
`PAUSED — reached a limit`. Only a plain crash offer carries neither field.

A frame camy does not model is passed through as
`{"type": "<frame type>", "data": {…}}` only when it names this turn's chat.
A new server event about your turn is never silent data loss, and one about
another chat, or an account-wide notice that names no chat, never appears.
Keepalive `ping` and `pong` frames never appear either, and another chat on
your account finishing or failing does not end this stream.
`checkpoint_resolved`, `action_timeout` and `action_confirmed`, which name
only a card, appear only for a card this turn is about: one it drew or
answered, or the one `camy approvals approve --wait` answered.

An abnormal end usually produces a terminal `error` event. Two ends do not. A
fail-closed `checkpoint` is the last event before the process exits 4: the
event tells you what paused, and the exit code and the `checkpoint_id` in the
error object tell you what to do about it. A turn the server refuses outright
— a plan or credit refusal — still ends on `final` and `done` while the
process exits 6 (or 1).

Check `$?` as well as the last event. A reader can stop on `done`, `error`,
or `checkpoint` and never hang. The exception is an `attach_failed` error,
which more events can follow; see
[Error codes in the stream](#error-codes-in-the-stream).

[`camy approvals approve <id> --wait`](reference/camy_approvals_approve.md)
streams the resumed turn's events and ends on the stream's own `done`. When
the turn does not stream here but camy can read what became of the
checkpoint, it ends instead on one closing line of its own.

That closing line is NDJSON like every event before it: one compact object
on one line, so a line-at-a-time reader handles both endings the same way.
When the checkpoint completed:

```json
{"chat_id":"…","checkpoint_id":"…","ran_elsewhere":true,"type":"done"}
```

When it did not run:

```json
{"chat_id":"…","checkpoint_id":"…","code":"checkpoint_<status>","message":"…","type":"error"}
```

`code` is `checkpoint_failed`, `checkpoint_rejected`, `checkpoint_expired` or
`checkpoint_cancelled`, or `checkpoint_uncorrelated` when results came back
but none could be tied to this approval. Each of those exits 1.

When the approval doesn't resume a turn at all, as with a connector write
that ran inside the approve itself, there is nothing to stream:
`approve --wait` prints one closing line, with the checkpoint's `status`,
and exits 0.

```json
{"checkpoint_id":"…","resumed":false,"status":"…","type":"done"}
```

A "did not resume" timeout writes no closing line. stdout simply ends after
the last streamed event, the error object on stderr says
`the turn did not resume within 2m0s of the approve`, and the process exits
1. An attach that fails outright also ends with no closing line, only its
error object. Check `$?` rather than rely on a closing line.

There is no streaming variant of `camy status --watch`. It is interactive
only and refuses under machine mode, telling you to poll `camy status --json`
on your own cadence instead.

#### Error codes in the stream

The `error` event that ends a turn is its last event, except for
`attach_failed` below, and its `code` is never empty. The closing line of
`--wait`, above, has its own codes.

| `code` | Exit | Meaning |
| --- | --- | --- |
| `turn_error` | 1 | the turn itself failed, or the server refused it without a code of its own |
| `turn_in_flight` | 1 | the chat is already mid-turn; [`camy chat attach`](reference/camy_chat_attach.md) rejoins it |
| `message_too_large` | 2 | the server refused the message as over its 64 KB limit; send the text with `--attach` instead |
| `TOKEN_EXPIRED`, `TOKEN_REVOKED`, `SESSION_INVALIDATED`, `INVALID_TOKEN`, `auth` | 3 | camy.ai refused the key, in its own code or as `auth`; exceptions below |
| `approval_pending` | 4 | a checkpoint in this chat is waiting on you; [`camy approvals`](reference/camy_approvals.md) lists it |
| `rate_limited`, `too_many_connections`, `turn_concurrency_limit` | 5 | a rate refusal: your message, the account's cap on open connections, or every turn slot on the account staying busy |
| `server_draining` | 7 | camy.ai was restarting; see below for when camy retries first |
| `AUTH_UNAVAILABLE`, `unavailable` | 7 | camy.ai couldn't look your key up, or take the connection, just now; the key is fine |
| `stream_dropped`, `turn_lost`, `interrupted`, `send_failed`, `attach_failed` | 1 | camy's own: the stream dropped, a `--temp` chat's turn was lost, the turn was interrupted, or the message or attach couldn't be sent |
| any other code | 1 | a refusal the server coded some other way, passed through as it was sent |

Some of those are not what they seem:

- `message_too_large` is only the server's own refusal. A message camy can
  measure as too big fails before the message is sent, as a usage error
  (exit 2). For a one-shot `camy chat` that is the top-level
  `{"error":{"code":"usage",…}}` object on stderr, not a stream event. A
  resend after a restart that measures over 64 KB ends the stream on an
  `error` event with code `usage`, exit 2.
- `INVALID_TOKEN`, and an `auth` refusal the server sent with no code of
  its own, are checked once with an ordinary request. If the key still
  works there, the refusal was a lookup that failed, not the key: the
  process exits 7.
- Any key refusal on a connection that had already signed in, whatever its
  code, means camy.ai closed that connection, typically because another
  sign-in on the account was revoked. It says nothing about this key: the
  process exits 1 with `camy.ai closed this connection` and the hint
  `say it again`. When the server's reason is one camy knows, the message
  ends with `(a sign-in on this account was revoked)` or
  `(it was disconnected from this account)`. Any other reason adds nothing.
- `server_draining` depends on what was going out. For a new message camy
  redials and resends up to three times before it emits `server_draining`
  (exit 7). For an attach, as in `camy chat attach` and `approve --wait`,
  camy emits it and exits 7 straight away. A redial refused for the key or for rate exits 3
  or 5 without a `server_draining` event.
- `attach_failed` can be followed by more events. `camy chat attach` and
  `approve --wait` redial and attach once more after it, and the retried
  attach's events follow the `error` event on the same stream. The process
  can then exit 0. For `camy chat attach --json` and `approve --wait`, the
  exit code, not the first `error` event, says how the turn ended.

The chat connection's own failures end on these real exit codes, never on
the generic 1 of a dropped stream: 3 when camy.ai refused the key, 5 when
it refused for rate, and 7 when the chat service was unavailable. That
holds for a refusal as the connection opens, too, which prints only the
error object on stderr and no stream event. A chat that is already
mid-turn stays 1. [Troubleshooting](troubleshooting.md#common-situations)
shows the human messages.

### Quiet mode

`-q` / `--quiet` suppresses camy's non-data stderr lines — notes, spinners,
progress. Errors still print, and stdout is untouched.

```bash
camy jobs --json -q > jobs.json
```

See [`camy jobs`](reference/camy_jobs.md) and
[Jobs, schedules, tasks, and data](automation.md).

### Commands with no machine output

A few commands are text-only on purpose and accept `--json` without acting on
it: [`camy config get KEY`](reference/camy_config_get.md) (use
[`camy config list --json`](reference/camy_config_list.md) instead), the
`camy help <topic>` pages, and the success line from
[`camy uninstall`](reference/camy_uninstall.md). Do not build a parser
against those.

## `--jq` and `--template`

Both are built into the binary. You do not need `jq` installed, and you do
not need to pass `--json` alongside them.

```bash
camy version --jq '.version'
camy doctor --jq '[.[] | select(.ok == false)] | length'
camy status --jq '.approvals | length'
camy api GET /v1/jobs --jq '.[].id'
```

`--jq EXPR` runs a jq expression over the JSON the command would have
printed. Each result is printed on its own line: strings raw, everything else
as compact JSON.

```bash
camy version --template '{{.version}} {{.os}}/{{.arch}}'
camy doctor --template '{{range .}}{{.name}}: {{.ok}}{{"\n"}}{{end}}'
```

`--template TMPL` formats the same value with a Go
[text/template](https://pkg.go.dev/text/template). The value is round-tripped
through JSON first, so the template sees plain maps and slices under the JSON
field names, and a newline is printed after the rendered output.

Both apply to the single JSON value a command prints. They do not filter
NDJSON stream events: a streaming command — `camy chat`, and
`camy approvals approve --wait` down to its closing line — emits its events
unchanged, so filter those with an external tool, as in the `camy chat`
example under NDJSON for streams, above.

A malformed expression or template is a usage error (exit 2). One that fails
while running is a runtime error (exit 1).

Field names inside a server response are chosen by the API. Pin your
expressions to the keys camy documents — the top-level keys of
`camy status --json`, the fields of `camy doctor --json`, the six keys of
`camy version --json` — and treat anything nested inside a pass-through row
as something that can change shape.

## `camy api`: the escape hatch

[`camy api METHOD PATH`](reference/camy_api.md) calls any endpoint with your
stored credentials and prints the JSON response. It is how you reach whatever
the command tree has not wrapped.

```bash
camy api GET /v1/jobs --jq '.[].id'
camy api POST /v1/tasks --field title="renew passport"
camy api GET /v1/inbox --paginate
```

`METHOD` and `PATH` are both required; a `PATH` without a leading `/` gets
one.

**Request bodies.** `--field k=v` is repeatable and builds a JSON object.
Values are strings by default; a trailing colon on the key, `k:=v`, parses
the value as raw JSON instead.

```bash
camy api POST /v1/tasks --field title="renew passport" --field 'metadata:={"priority":1}'
```

If you pass no `--field`, stdin is not a terminal, and the method is POST,
PUT or PATCH, camy reads the body from stdin (up to 10MB) and requires it to
parse as JSON:

```bash
echo '{"title":"renew passport"}' | camy api POST /v1/tasks
```

**`--paginate`** walks `limit=100&offset=N` pages and prints one flat JSON
array of every row. It stops on a short page, and it stops on an endpoint
that ignores `offset`: a repeated page is detected by stable row identity and
reported rather than looped forever. There is a hard ceiling of 100,000 rows,
past which camy tells you to use the endpoint's own cursor parameter.

If a page fails partway through a sweep, the rows already fetched are still
printed as `{"partial":true,"results":[…],"rows":N,"error":"…"}` **and** the
command still exits non-zero — so a script keeps what it paid for and can
still tell a truncated sweep from a clean one:

```bash
camy api GET /v1/inbox --paginate > inbox.json || echo "sweep was truncated" >&2
```

[`camy jobs --all`](reference/camy_jobs.md) and
[`camy webhooks deliveries --all`](reference/camy_webhooks_deliveries.md)
sweep pages the same way and emit the identical `partial` object on a
mid-sweep page failure.

A response body that is not JSON is printed as-is, after terminal escape
sequences are stripped from it.

## Non-interactive runs

### `--no-input`

`--no-input` promises that nothing will block on a terminal. It has two
different outcomes, by design:

- **An approval fails closed with exit 4.** The turn stops, nothing runs, and
  the checkpoint id is on stderr — in the JSON error object as
  `checkpoint_id`. The pause is a durable handle: approve it later and
  re-attach.
- **Every other prompt exits 2.** A destructive-action confirmation, or
  [`camy config edit`](reference/camy_config_edit.md), becomes a usage error
  naming what to pass instead.

`--json` fails closed on approvals on its own, even in a real terminal. So
does any run with no controlling terminal. Approval prompts read `/dev/tty`
directly and never stdin, so `echo y | camy chat …` cannot answer one.

[`camy auth login`](reference/camy_auth_login.md) refuses `--no-input`
outright; use `CAMY_API_KEY` for headless authentication.

### `--force`

`-f` / `--force` skips the `y/N` confirmation camy asks before a destructive
action it is about to take itself — cancelling a job, revoking a key,
deleting a schedule. It has no effect on approvals: it will not approve a
checkpoint.

A few irreversible operations sit above `--force`, notably
[`camy uninstall`](reference/camy_uninstall.md) and
[`camy auth logout --revoke`](reference/camy_auth_logout.md). They want the
word typed back, or `--confirm <word>` up front; `--force` and `--no-input`
are both refused there rather than read as consent.

### Completing the loop

The headless pattern is: run, catch exit 4, decide out of band, resume.

```bash
camy --no-input chat "clean up the build directory"
if [ $? -eq 4 ]; then
  camy approvals --json --jq '.[] | select(.family == "checkpoint") | .checkpoint_id'
fi
```

```bash
camy approvals approve <checkpoint-id> --wait --chat <chat-id>
```

`--wait` responds, re-attaches, and streams the resumed turn to completion.
Three things to budget for:

- It needs a chat to attach to: `--chat`, else the chat the checkpoint
  belongs to, else the last chat this profile used. With none of those it
  prints a note and exits 0 without streaming anything.
- It waits about 120 seconds before it believes a quiet chat really is
  idle, and up to 600 seconds in total when the run is paused on a card
  being decided in another open camy session. Budget roughly ten minutes
  worst case before you get a result or a "did not resume" error.
- It exits 1 when the checkpoint's own terminal status comes back failed,
  rejected, expired or cancelled, or when the result can't be tied to this
  approval. A "did not resume" error means this process
  gave up watching, not that the approval was undone — read
  [`camy chats show <chat-id>`](reference/camy_chats_show.md) for what
  actually happened.

**Timeouts never approve.** An approval prompt left unanswered for two
minutes leaves the checkpoint exactly as pending as it was. Walking away is
always safe. See [Approvals](approvals.md).

## Exit codes

Branching on the exit code:

```bash
camy --no-input chat "run the migration"
case $? in
  0) echo "done" ;;
  4) echo "waiting on an approval" >&2; exit 0 ;;
  3) echo "not signed in" >&2; exit 1 ;;
  5) echo "rate limited — back off and retry" >&2; exit 75 ;;
  6) echo "plan or credits don't cover this" >&2; exit 1 ;;
  *) echo "failed" >&2; exit 1 ;;
esac
```

Eleven codes, frozen for 1.x: `0` success, `1` runtime, `2` usage, `3` auth,
`4` checkpoint pending, `5` rate-limited, `6` plan or credits, `7` unavailable,
`8` checkpoint denied, `131` quit (Ctrl-\\, SIGQUIT), and `255` for
[`camy vm exec`](reference/camy_vm_exec.md)'s own failure. That command
otherwise follows the ssh convention and mirrors a remote code from 0 to 254
straight to your shell. The table, the machine `code` names, and which
command raises which are all in [Exit codes](exit-codes.md).

Exit 5 is worth handling explicitly. camy already retries a rate-limited GET
up to four times, honoring `Retry-After` — on the wrapped commands, not on
`camy api`, which sends exactly one request. A 5 from a wrapped GET means
those retries were spent, or that the server asked for a wait longer than
two minutes, which camy never sits through: the hint names that wait, as in
`retry in about an hour`. Either way, back off rather than loop. A `camy chat`
refused by the chat connection's own rate limits exits 5 as well.

A write that fails with exit 1 on a server fault (HTTP 5xx), or on a
connection that broke after the request went out, may still have gone
through. Check before you retry it; see
[A server refusal](troubleshooting.md#a-server-refusal-exit-1).

## Cron and CI

### A scheduled status check

```bash
#!/bin/sh
set -eu
count=$(camy status --json --jq '.approvals | length')
if [ "$count" -gt 0 ]; then
  printf 'camy: %s approvals waiting\n' "$count" >&2
fi
```

[`camy status`](reference/camy_status.md) treats "every fetch failed" as a
hard error (exit 1), not as a calm empty result, so an unreachable API can
never render as "nothing waiting".

### A nightly inbox digest

```bash
camy inbox --needs-you --json > "$HOME/needs-you-$(date +%F).json"
camy inbox --needs-you --json --jq 'length'
```

[`camy inbox`](reference/camy_inbox.md) prints a flat array of the server's
own rows, and `[]` when nothing matches, `--all` included. The counts header
you see interactively is part of the human listing on stdout, and never
appears under `--json`, `--jq` or `--template`.
Add `--all` to follow the cursor to the end.

### A workspace step in CI

```bash
camy vm exec --timeout 600 -- pytest -q
```

The remote exit code becomes the step's exit code, so a failing test suite
fails the job with no extra plumbing. `--timeout` takes 1 to 3600 seconds.
`--no-wake` makes a stopped workspace exit 7 instead of waiting minutes for
an auto-start. With no workspace at all, `camy vm exec` exits 255, its own
failure, rather than creating one.

Under `--json` the remote streams arrive inside a single object as `stdout`
and `stderr` alongside `exit_code`, rather than on your own streams, while
the process exit code still mirrors the remote one:

```bash
camy vm exec --json -- pytest -q | jq -r '.stdout'
```

See [Workspace](workspace.md).

### Credentials in CI

There is no `--api-key` flag. `CAMY_API_KEY` is the only way to supply a key
without signing in interactively:

```bash
CAMY_API_KEY="$CI_CAMY_KEY" camy status --json
```

It wins over the OS keychain and the fallback file, and camy never writes it
anywhere. Three cautions:

- Keep it in your CI provider's secret store, never in a checked-in file or a
  shell rc. Mint a key scoped to what the job actually needs.
- If you set `CAMY_API_KEY` **and** name a profile with `--profile` or
  `CAMY_PROFILE`, the environment key silently replaces that profile's own
  key. In human mode camy prints one note to stderr the first time this
  matters; under `--json`, `--jq` or `--template` there is no note at all.
- `camy auth logout --revoke` refuses to run when the active key came from
  `CAMY_API_KEY`, so a script cannot destroy a shared CI key by accident.

`CAMY_PROFILE` selects which stored key, `api_url` and per-profile state a
run uses, which is the clean way to keep a CI identity separate from your own:

```bash
CAMY_PROFILE=ci camy status --json
```

Both are covered in [Authentication](authentication.md) and
[Configuration](configuration.md).

## Stdin

These commands read stdin as data.

**[`camy chat`](reference/camy_chat.md)** adds piped stdin to the message
as a context block, up to 2MB, whenever stdin is not a terminal:

```bash
git diff | camy chat "review this"
cat error.log | camy chat "what broke?"
kubectl get pods | camy chat
camy chat "summarize this" < notes.txt
```

A headless chat never blocks on stdin. A file redirected to stdin is read
whole. A pipe is read only if data, or its end, shows up within 200 ms, or
within 2 seconds when you gave no message and the pipe is the whole
message. Otherwise stdin counts as empty, so a script that runs
`camy chat "…"` with an open pipe it never writes to still goes ahead. Once
data is there, `git diff | camy chat` reads to the end.

With a message, stdin is appended after a separator; with no message, stdin
*is* the message. If both end up empty, that is a usage error. When the text
came from somewhere else, pass it after `--` so a leading dash can never be
read as a flag:

```bash
camy chat -- "$UNTRUSTED"
```

A message goes to camy.ai in one piece of at most 64 KB. When piped stdin
pushes it past that, camy uploads the piped block as an attachment named
`stdin.txt`, the same upload `--attach` makes, and sends only your typed
words as the message, or the attachment alone for a bare pipe. A message
still too long after that, or a long block piped into a `--temp` chat,
which never uploads on its own, is a usage error (exit 2), refused before
the chat connection is opened and before the message is sent:

```text
camy: that message is too long to send (70.2 KB; the limit is 64 KB)
      save it to a file and send it with --attach
```

Any `--attach` files, and a `stdin.txt` camy already uploaded, have gone up
by then. When the long part was piped into a `--temp` chat, the hint says to trim
it, or to `--attach` a file yourself.

`stdin.txt` goes up as `text/plain`. Every attachment goes up with its bare
media type, such as `text/csv` rather than `text/csv; charset=utf-8`, the
form camy.ai accepts for text files.

**[`camy capture`](reference/camy_capture.md)** sends anything on stdin to
Camy's memory intake. Pass `-` explicitly, or pipe with no argument at all:

```bash
pbpaste | camy capture -
git log --oneline -20 | camy capture --title "this week's commits"
```

A capture holds up to 20,000 characters and its title up to 500. Anything
longer, or more than 1 MiB on stdin, is a usage error (exit 2) before
anything is sent, never a silent cut.

**`camy api`** reads a JSON request body from stdin for POST, PUT and PATCH
when no `--field` was given, as described above.

Because every prompt reads `/dev/tty` rather than stdin, piping data in never
collides with a confirmation — and piping `y` in never answers one.

## Color, TTY detection, and paging

Machine output is never styled. `--json`, `--jq` and `--template` write
through an encoder that emits no escape sequences, so the bytes on stdout are
the same whether or not `FORCE_COLOR` is set.

For human output the usual conventions apply, in this order:

| Signal | Effect |
| --- | --- |
| `--color never` / `--color always` | wins over everything below |
| config `color = never` or `off` | same as `--color never` |
| `NO_COLOR` (any non-empty value), `CLICOLOR=0`, `TERM=dumb` | color off |
| `FORCE_COLOR`, `CLICOLOR_FORCE` (any non-empty value) | color on even when piped |
| stdout is not a terminal | color off |

`TERM=dumb` also puts camy in accessible mode — linear output, no spinners,
boxes or redraws — as do `--accessible` and `CAMY_ACCESSIBLE=1`.

Color on stderr is decided from stderr's own capabilities, separately from
stdout, so `camy … 2> log` records plain text even from an interactive
session.

**Paging.** camy pages only when stdout is a terminal, accessible mode is
off, and the output is taller than the terminal. Piped or redirected output
is never paged, so no script needs `--no-pager`.

The flag exists all the same, alongside `CAMY_PAGER`, `PAGER`, and setting
the config `pager` to `off` or `cat` to disable paging outright. See
[Terminal output and accessibility](terminal.md).

## See also

- [Exit codes](exit-codes.md) — the frozen table and the JSON error shape in full
- [Approvals](approvals.md) — the checkpoint model behind exit 4
- [Configuration](configuration.md) — every environment variable and the precedence ladder
- [Command reference](reference/camy.md) — every command and flag
