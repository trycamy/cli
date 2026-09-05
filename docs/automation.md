# Jobs, schedules, tasks, and data

Everything that runs without you watching, and everything that gets into
and out of Camy without a chat turn.

| Area | Start with | What it is |
| --- | --- | --- |
| [Jobs](#jobs) | `camy jobs` | durable, multi-day work |
| [Schedules](#schedules) | `camy schedule` | one instruction on a timer |
| [Tasks](#tasks) | `camy tasks` | quick to-dos; nothing fires on its own |
| [Capture](#capture) | `camy capture` | one line into memory intake |
| [Integrations](#integrations) | `camy integrations` | connected accounts |
| [Webhooks](#webhooks) | `camy webhooks` | endpoints and their deliveries |

## Jobs

A job is a durable, multi-day piece of work — the kind that keeps firing
over days, as opposed to a schedule, which fires one instruction on a
timer. Jobs are created elsewhere, in a chat or by an agent; this area
lists, inspects, cancels, and nudges them.

### Listing jobs

```bash
camy jobs
camy jobs --status active --limit 20
camy jobs --all --json
```

Prints a table: short id, title, state, and next fire. A job in a terminal
state — cancelled, failed, expired, disabled, done, or completed — always
shows `—` for next fire, even if the server still has a stale timestamp on
the row, since a terminal job fires never.

| Flag | Effect |
| --- | --- |
| `--status string` | one of `active`, `suspended`, `blocked`, `completed`, `failed`, `cancelled`, `needs_attention`, passed straight through and not validated locally |
| `-L, --limit int`, `--offset int` | page manually |
| `--all` | auto-paginate to the end |

If a page fails partway through an `--all` sweep, the rows already fetched
are kept, not thrown away. Human mode prints them plus a note that it
stopped early, and `--json` mode emits
`{"partial": true, "results": [...], "rows": N, "error": "..."}`. Both
still exit non-zero.

### One job in detail

```bash
camy jobs show a1b2c3d4
camy jobs show a1b2c3d4 --web
```

Shows one job's title, status, cadence, and next fire, followed by up to
ten recent firings (status and a relative time).

`--web` prints the job's camy.ai link and opens it in your browser instead
of fetching and rendering the job. The link prints on stdout even under
`--json`, so don't combine `--web` with `--json` in a script.

It skips the job-detail call, but a short id prefix is still resolved
against `camy jobs` first, which costs one list call; a full id skips the
network entirely.

`ID` accepts a short prefix — at least 4 characters — resolved against the
job list; a prefix matching more than one job is a usage error. The prefix
is matched against the first 100 jobs only; for a job older than that,
pass the full id.

### Cancelling and re-firing

```bash
camy jobs cancel a1b2c3d4
camy jobs run-now a1b2c3d4
```

`cancel` stops the job and its schedule, and asks for confirmation first
(see [Destructive confirmations](#destructive-confirmations)). `run-now`
pulls the job's next fire forward to now, but isn't synchronous: it fires
on the dispatcher's next tick, about 30 seconds out.

See [camy jobs](reference/camy_jobs.md), [camy jobs show](reference/camy_jobs_show.md),
[camy jobs cancel](reference/camy_jobs_cancel.md), and
[camy jobs run-now](reference/camy_jobs_run-now.md) for the full flag list.

## Schedules

```bash
camy schedule
```

Lists everything that fires on a timer — schedules you created with
`schedule create`, and schedules an agent created for you during a chat
(a reminder, a timer, a recurring instruction). These live in two separate
places behind the scenes, and `camy schedule` merges them into one list: a
green check, short id, recurrence, next fire, and the instruction.

The agent-created half covers the first 100 active ones. If that lookup
fails, the list quietly shows only the schedules you created.

### Creating a schedule

```bash
camy schedule create WHEN --run INSTRUCTION [--tz ZONE] [--dry-run]
```

`WHEN` accepts exactly three shapes:

| You write | Means | Recurrence sent |
| --- | --- | --- |
| `"07:00"` | daily at that time; rolls to tomorrow if it's already past today | `daily` |
| `"hourly"` | the next hour boundary, then every hour after | `hourly` |
| `"mon 07:00"` | weekly, that weekday and time (`sun`…`sat`, first 3 letters, case-insensitive) | `weekly` |

```bash
camy schedule create "07:00" --run "prep my morning brief"
camy schedule create "mon 09:00" --run "weekly pipeline review" --tz America/Chicago
```

`WHEN` is parsed on your machine, and the raw string never reaches the
server — it only ever sees the resolved fire time and recurrence rule.
Parsing happens after the account-timezone lookup, so unless you pass
`--tz` the CLI makes one `GET /v1/users/me` call first.

Any other value is refused client-side as a usage error before the
schedule is created. A value containing the word "weekday", or with four or more
spaces in it — the CLI's rough heuristic for "this looks like a cron
expression" — gets a specific message saying weekday subsets and cron
expressions aren't schedulable yet.

Anything else unparseable gets a generic "couldn't parse" error. Both list
the three supported forms as the hint.

| Flag | Effect |
| --- | --- |
| `--run string` | required; the instruction that fires |
| `--tz string` | an IANA timezone name (`America/Chicago`, `Europe/London`); without it, your account's timezone, fetched live, falling back to this machine's local zone if that lookup fails |
| `--dry-run` | print what would be created instead of creating anything |

`--dry-run` prints a one-line summary in human mode, the exact request
body under `--json`:

```bash
camy schedule create "hourly" --run "check inbox" --dry-run
```

```text
✓ dry run — would create: check inbox at 2026-09-03T15:00:00-04:00 (hourly)
```

It never posts the schedule, but unless you pass `--tz` it still reads
your account timezone over the network first (a single
`GET /v1/users/me`). If that call fails, the dry run silently resolves
against this machine's local zone, so the time it prints can differ from
what a real create would use.

### Pausing and deleting

```bash
camy schedule pause 9f8e7d6c
camy schedule delete 9f8e7d6c
```

`ID` accepts a short prefix, resolved against both stores together.
`pause` only works on schedules you created with `schedule create` — an
agent-created schedule can't be paused, and trying gives a usage error
pointing at `delete` instead.

`delete` works on either kind: it cancels an agent-created schedule or
deletes a `schedule create` one, whichever the id resolves to. It asks for
confirmation first.

There is no `resume` — un-pausing a schedule isn't a CLI operation today;
delete the schedule and create it again.

See [camy schedule](reference/camy_schedule.md),
[camy schedule create](reference/camy_schedule_create.md),
[camy schedule pause](reference/camy_schedule_pause.md), and
[camy schedule delete](reference/camy_schedule_delete.md) for the full
flag list. You can also print the WHEN grammar from the binary itself with
[`camy docs`](reference/camy_docs.md):

```bash
camy docs time
```

## Tasks

Quick to-dos, separate from jobs and schedules — nothing here fires on its
own.

```bash
camy tasks
```

Lists tasks: an open circle or a green mark for done, short id, title, and
a due-date suffix when one is set.

```bash
camy tasks add "renew passport" --due 2026-11-01 --priority high
camy tasks add "call the accountant about Q3"
```

`TITLE...` is one or more words, joined with spaces. `--due` takes an ISO
8601 date, sent as-is with no local format checking. `--priority` must be
exactly `low`, `medium`, or `high` — anything else is a usage error before
any network call.

```bash
camy tasks done 4c5d6e7f
camy tasks rm 4c5d6e7f
```

`done` marks a task complete; no confirmation needed. `rm` deletes it and
asks for confirmation first. Both accept a short id prefix.

See [camy tasks](reference/camy_tasks.md), [camy tasks add](reference/camy_tasks_add.md),
[camy tasks done](reference/camy_tasks_done.md), and
[camy tasks rm](reference/camy_tasks_rm.md) for the full flag list.

## Capture

```bash
camy capture [TEXT | -] [--title TITLE]
```

Sends text into Camy's memory intake — a place to drop a note, a quote, or
a stray thought without opening a chat.

```bash
camy capture "call the accountant about Q3"
camy capture "meeting notes" --title "Q3 sync"
pbpaste | camy capture -
```

Text comes from three places, in this order: a literal `-` reads stdin; no
arguments at all, with something piped in (stdin isn't a terminal), also
reads stdin; anything else is the joined argument text.

A bare `camy capture` with nothing piped and nothing typed reads no stdin
and fails immediately with "nothing to capture" rather than hanging
waiting for input. Piped input is capped at 1 MiB.

See [camy capture](reference/camy_capture.md) for the full flag list.

## Integrations

```bash
camy integrations
```

Lists connected accounts — calendar, mail, and similar providers — with a
rollup of what each one knows: an email address, an event or message
count, or an error if something's wrong with the connection.

Connected providers are listed first, then anything not connected. If your
organization has disabled a provider, that's called out in a trailing
line.

```bash
camy integrations health
camy integrations health gmail
```

A shallow check across every provider, or just one. Each row shows a
status (healthy, unknown, or a warning), and whatever detail is available:
a last error, when a token expires, or when the last sync happened.

`PROVIDER` is passed through as typed — there's no local list of known
provider names to validate it against, so a typo surfaces as "no health to
report" or a not-found error rather than a specific "unknown provider"
message. Use the provider name exactly as `camy integrations` printed it
(the name beside the status dot).

Connecting or disconnecting an integration isn't a CLI operation — do that
at camy.ai/p/connections.

See [camy integrations](reference/camy_integrations.md) and
[camy integrations health](reference/camy_integrations_health.md) for the
full flag list.

## Webhooks

```bash
camy webhooks
```

Lists your webhook endpoints: a green check when the endpoint is active
and a dim circle when it is not, then id, URL, and status. Creating or
removing an endpoint isn't a CLI operation — the CLI only lists endpoints
and works with their deliveries.

### Deliveries

```bash
camy webhooks deliveries 1a2b3c4d5e6f
camy webhooks deliveries 1a2b3c4d5e6f --all --json
```

Lists delivery attempts for one endpoint, newest first, with a mark for
success or failure, the response status code, the event type, and when it
happened.

`--limit`/`-L` (default 30 here, 100 for `camy jobs`) and `--offset` page
manually; `--all` auto-paginates, keeping whatever it already fetched if a
later page fails, the same partial-result contract as `camy jobs --all`.

### Test and replay

```bash
camy webhooks trigger 1a2b3c4d5e6f
```

Sends a test delivery synchronously through the same delivery path a real
event takes, so you see the endpoint's actual response rather than a
queued attempt.

```bash
camy webhooks replay 1a2b3c4d5e6f dl_9988
```

Re-enqueues one dead-lettered delivery under a fresh idempotency key, so
it's retried as a new attempt rather than deduplicated against the failed
one.

### Endpoint and delivery ids

Neither id in this section — the endpoint id taken by `deliveries`,
`trigger`, and `replay`, nor the dead-letter id in `replay` — accepts a
short prefix the way ids elsewhere in this document do; pass them exactly
as the server issued them.

The human listings are not a reliable source: `camy webhooks` truncates a
long endpoint id to fit its column, and `camy webhooks deliveries` prints
no id at all. Take both ids from `--json` — for example
`camy webhooks --json --jq '.[].id'`.

See [camy webhooks](reference/camy_webhooks.md),
[camy webhooks deliveries](reference/camy_webhooks_deliveries.md),
[camy webhooks trigger](reference/camy_webhooks_trigger.md), and
[camy webhooks replay](reference/camy_webhooks_replay.md) for the full
flag list.

## Destructive confirmations

`camy jobs cancel`, `camy schedule delete`, and `camy tasks rm` each ask
before acting:

```text
cancel job a1b2c3d4? [y/N]
```

Anything other than `y`/`yes` cancels the operation. The prompt reads
`/dev/tty` directly, not stdin, so it never conflicts with a command that
also takes piped input elsewhere (`camy capture -`, for instance, stays
purely a stdin reader).

Running headless — `--no-input`, or no controlling terminal at all — skips
the prompt and fails closed with a usage error unless you pass `--force`:

```bash
camy jobs cancel a1b2c3d4 --force
camy schedule delete 9f8e7d6c --force
camy tasks rm 4c5d6e7f --force
```

This is camy's lighter confirmation tier. A few irreversible commands
([`camy auth logout`](reference/camy_auth_logout.md) `--revoke`,
[`camy uninstall`](reference/camy_uninstall.md)) use a stricter one where
`--force` is not enough and you type the word back or pass `--confirm` — see
[Scripting with camy](scripting.md) and [Exit codes](exit-codes.md).

## `--json` output

Every command in this document supports `--json`. Shapes vary by command:

- `camy jobs`, `camy tasks`, `camy webhooks` — a JSON array of rows: the
  CLI unwraps the server's list envelope, but each row is passed through
  field for field.
- `camy jobs --all` / `camy webhooks deliveries --all` on a mid-sweep
  failure — `{"partial": true, "results": [...], "rows": N, "error": "..."}`,
  still a non-zero exit. An `--all` sweep that ends with no rows emits
  `null` rather than `[]`, so a script that iterates should write
  `jq '. // [] | .[]'` rather than `jq '.[]'`.
- `camy jobs show ID` — the full job object as the server returns it.
- `camy webhooks trigger ID` — the test-delivery result the endpoint
  returned, not the endpoint row.
- `camy schedule` — the concatenated array of both stores' rows (the ones
  you created with `schedule create` first, then the agent-created ones);
  the two have different shapes.
- `camy schedule create --dry-run --json` — the request body that would
  have been sent, never sent:

  ```json
  {
    "fire_at": "2026-09-03T15:00:00-04:00",
    "kind": "at_time",
    "recurrence_rule": "hourly",
    "target_config": {
      "instruction": "check inbox"
    },
    "target_type": "operator"
  }
  ```

- `camy capture`, `camy tasks add`, `camy schedule create` (without
  `--dry-run`) — the created object as the server returned it.
- `camy jobs cancel`, `camy schedule pause`, `camy schedule delete`,
  `camy tasks done`, `camy tasks rm` — a small confirmation object, for
  example:

  ```json
  {"ok": true, "job_id": "a1b2c3d4...", "cancelled": true}
  ```

- `camy jobs run-now` — a confirmation object with an extra field noting
  when it fires:

  ```json
  {"ok": true, "job_id": "a1b2c3d4...", "fires": "next tick (~30s)"}
  ```

- `camy webhooks replay` — `{"ok": true, "replayed": "<dead letter id>"}`.
- `camy integrations`, `camy integrations health` — the raw server
  response object.

None of these shapes are scrubbed the way
[`camy approvals --json`](reference/camy_approvals.md) is (see
[Approvals](approvals.md)) — what the server sends is what you get, field
for field.

## See also

- [Exit codes](exit-codes.md) — auth (3), usage (2) from a bad `WHEN` or a
  refused confirmation, and the rest of the frozen table
- [Scripting with camy](scripting.md) — `--json`, `--jq`, `--template`,
  `--no-input`, and using camy from cron
- [Approvals](approvals.md) — how a pause for a human works, for anything an
  agent stops on rather than a scheduled fire
- [Inbox, sweep, and feed](inbox.md) — the other place things arrive
  without a chat turn
