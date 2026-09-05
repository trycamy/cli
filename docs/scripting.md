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
  "os": "darwin",
  "version": "1.0.0"
}
```

Illustration: `version` and `commit` are stamped into your build. Those four
keys are the whole object.

`--jq` and `--template` switch a command to machine output on their own: any
one of the three puts the whole invocation into machine mode. Machine mode
also turns the [local bridge](local-bridge.md) off for that run and makes
every approval fail closed, because machine output must never emit a prompt.

Where a command wraps a server response, the JSON is the server's own shape
passed through unchanged. [`camy status --json`](reference/camy_status.md)
gives you `approvals`, `inbox_counts`, `jobs` and `workspace`; what is inside
each of them is defined by the API, not by the CLI. Treat the keys camy
itself documents as stable, and treat a pass-through row as something that
can gain fields.

Two shapes are worth knowing because they are camy's own, not the server's:

- [`camy doctor --json`](reference/camy_doctor.md) is an array of checks,
  each `{"name", "ok", "info"}` plus `"warn"` and `"fix"` when they apply.
  The exit code is driven only by `ok: false`; a row with `warn: true` never
  fails the command, so inspect `warn` per row if you care about it.
- [`camy approvals --json`](reference/camy_approvals.md) is a deliberately
  narrowed list — `checkpoint_id`, `chat_id`, `kind`, `tool_name`, `prompt`,
  `parameters`, `status`, `created_at`, `expires_at`.
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
| `message` | one sentence describing what happened |
| `hint` | the single next thing to try, or `""` |
| `request_id` | the server request id when a request happened, else `""` |

Two additions ride along when they apply:

| Key | When it appears |
| --- | --- |
| `checkpoint_id` | on a checkpoint-pending error — hand it straight to [`camy approvals approve`](reference/camy_approvals_approve.md) |
| `title`, `details` (rows of `{"label","value"}`), `fixes` (rows of `{"cmd","note"}`) | when the error carries a diagnosis card |

`hint` stays a plain one-line collapse of `fixes`, so a consumer that reads
only the five core keys loses nothing.

stdout carries only data the command had already finished emitting. For most
failures that is nothing at all, but see `camy doctor` above, and `camy api
--paginate` and the `--all` sweeps of `camy jobs` and `camy webhooks
deliveries` below.

Two failures are deliberately silent instead: a non-zero remote exit code
mirrored by [`camy vm exec`](reference/camy_vm_exec.md), and a turn the
server refused outright (see NDJSON streams, below). Both set the exit code
and print no error object on either stream. Treat a non-zero `$?` as
authoritative, not the presence of an error line.

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
| `tool_call` | `name`, `status`, `param` | a tool the agent invoked |
| `collection` | the collection's own fields | a structured result block |
| `snapshot` | `text`, `active` | a plan or progress snapshot for the turn |
| `checkpoint` | `id`, `kind`, `summary` | the turn paused for an approval |
| `final` | `text` | the complete reply text |
| `done` | `chat_id`, `turn_id` | the turn ended normally (plus `stopped: true` if you interrupted it) |
| `error` | `code`, `message` | the turn ended abnormally |

Frames camy does not model are passed through as
`{"type": "<frame type>", "data": {…}}`, so a new server event is never
silent data loss.

An abnormal end usually produces a terminal `error` event. Two ends do not. A
fail-closed `checkpoint` is the last event before the process exits 4: the
event tells you what paused, and the exit code and the `checkpoint_id` in the
error object tell you what to do about it. A turn the server refuses outright
— a plan or credit refusal — still ends on `final` and `done` while the
process exits 6 (or 1).

Check `$?` as well as the last event. A reader can stop on `done`, `error`,
or `checkpoint` and never hang.

[`camy approvals approve <id> --wait`](reference/camy_approvals_approve.md)
streams the resumed turn's events and ends on the stream's own `done`. When
nothing streams here — the turn resumed and finished in your other open camy
session — it prints one closing object instead.

That closing object is not an NDJSON line. It is indented JSON, or whatever
`--jq` or `--template` render, since it goes through the same encoder as any
other single value. Read the whole of stdout and parse it as one value rather
than line by line. When the checkpoint completed:

```json
{
  "chat_id": "…",
  "checkpoint_id": "…",
  "ran_elsewhere": true,
  "type": "done"
}
```

When it ended failed, rejected, expired or cancelled:

```json
{
  "chat_id": "…",
  "checkpoint_id": "…",
  "code": "checkpoint_<status>",
  "message": "…",
  "type": "error"
}
```

There is no streaming variant of `camy status --watch`. It is interactive
only and refuses under machine mode, telling you to poll `camy status --json`
on your own cadence instead.

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
NDJSON stream events: a streaming command — `camy chat`, and the streamed
part of `camy approvals approve --wait` — emits its events unchanged, so
filter those with an external tool, as in the `camy chat` example under
NDJSON for streams, above. The one closing object `approve --wait` prints
when nothing streamed is not a stream event, and `--jq` / `--template` do
apply to it.

A malformed expression or template is a usage error (exit 2). One that fails
while running is a runtime error (exit 1).

Field names inside a server response are chosen by the API. Pin your
expressions to the keys camy documents — the top-level keys of
`camy status --json`, the fields of `camy doctor --json`, the four keys of
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
  camy approvals --json --jq '.[].checkpoint_id'
fi
```

```bash
camy approvals approve <checkpoint-id> --wait --chat <chat-id>
```

`--wait` responds, re-attaches, and streams the resumed turn to completion.
Three things to budget for:

- It needs a chat to attach to: `--chat`, or the last chat this profile used.
  With neither it prints a note and exits 0 without streaming anything.
- It waits about 20 seconds before it believes a quiet chat really is idle,
  and up to 120 seconds in total when the run is paused on a card being
  decided in another open camy session. Budget roughly 120 seconds worst case
  before you get a result or a "did not resume" error.
- It exits 1 when the checkpoint's own terminal status comes back failed,
  rejected, expired or cancelled. A "did not resume" error means this process
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
  6) echo "plan doesn't cover this" >&2; exit 1 ;;
  *) echo "failed" >&2; exit 1 ;;
esac
```

Ten codes, frozen for 1.x: `0` success, `1` runtime, `2` usage, `3` auth,
`4` checkpoint pending, `5` rate-limited, `6` plan, `7` unavailable,
`8` checkpoint denied, and `255` for
[`camy vm exec`](reference/camy_vm_exec.md)'s own failure. That command
otherwise follows the ssh convention and mirrors a remote code from 0 to 254
straight to your shell. The table, the machine `code` names, and which
command raises which are all in [Exit codes](exit-codes.md).

Exit 5 is worth handling explicitly. camy already retries a rate-limited GET
up to twice, honoring `Retry-After` — on the wrapped commands, not on `camy
api`, which sends exactly one request. A 5 from a wrapped GET means those
retries were spent, so back off rather than loop.

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
own rows — `null` rather than `[]` when nothing matches, so guard with
`jq '. // [] | length'` or the equivalent. The counts header you see
interactively is stderr chrome and never appears in machine mode. Add
`--all` to follow the cursor to the end.

### A workspace step in CI

```bash
camy vm exec --timeout 600 -- pytest -q
```

The remote exit code becomes the step's exit code, so a failing test suite
fails the job with no extra plumbing. `--timeout` takes 1 to 600 seconds.
`--no-wake` makes a stopped workspace exit 7 instead of waiting minutes for
an auto-start.

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
as a context block, up to 2MB. This happens whenever stdin is not a terminal:

```bash
git diff | camy chat "review this"
cat error.log | camy chat "what broke?"
kubectl get pods | camy chat
```

With a message, stdin is appended after a separator; with no message, stdin
*is* the message. If both end up empty, that is a usage error. When the text
came from somewhere else, pass it after `--` so a leading dash can never be
read as a flag:

```bash
camy chat -- "$UNTRUSTED"
```

**[`camy capture`](reference/camy_capture.md)** sends anything on stdin to
Camy's memory intake, up to 1 MiB. Pass `-` explicitly, or pipe with no
argument at all:

```bash
pbpaste | camy capture -
git log --oneline -20 | camy capture --title "this week's commits"
```

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
