# Jobs, schedules, tasks, and data

Everything that runs without you watching, and everything that gets into
and out of Camy without a chat turn.

| Area | Start with | What it is |
| --- | --- | --- |
| [Jobs](#jobs) | `camy jobs` | durable, multi-day work |
| [Schedules](#schedules) | `camy schedule` | one instruction on a timer |
| [Runs](#runs) | `camy runs search` | what your agents did, and what they said |
| [Tasks](#tasks) | `camy tasks` | quick to-dos; nothing fires on its own |
| [Capture](#capture) | `camy capture` | one line into memory intake |
| [Integrations](#integrations) | `camy integrations` | connected accounts |
| [Webhooks](#webhooks) | `camy webhooks` | endpoints and their deliveries |

## Jobs

A job is a durable, multi-day piece of work — the kind that keeps firing
over days, as opposed to a schedule, which fires one instruction on a
timer. Jobs are created elsewhere, in a chat or by an agent; this area
lists, searches, inspects, cancels, and nudges them.

### Listing jobs

```bash
camy jobs
camy jobs --status active --limit 20
camy jobs --all --json
```

Prints a list under a count of how many jobs are live and how many need
you: a short id such as `jb_3f2a`, the job's title, its state, and next
fire. A job in a terminal state — cancelled, failed, expired, disabled,
done, or completed — always shows `—` for next fire, even if the server
still has a stale timestamp on the row, since a terminal job fires never.

| Flag | Effect |
| --- | --- |
| `--status string` | one of `active`, `suspended`, `blocked`, `completed`, `failed`, `cancelled`, `needs_attention`, passed straight through and not validated locally |
| `-L, --limit int`, `--offset int` | page manually; `--limit` takes 1 to 100 (default 100), and anything else is a usage error before any network call |
| `--all` | auto-paginate to the end |

If a page fails partway through an `--all` sweep, the rows already fetched
are kept, not thrown away. Human mode prints them plus a note that it
stopped early, and `--json` mode emits
`{"partial": true, "results": [...], "rows": N, "error": "..."}`. Both
still exit non-zero.

### Finding a job

```bash
camy jobs search "newsletter"
camy jobs search "invoice" --status active
```

Finds jobs by the words you set them up with and prints them in the same
list as `camy jobs`, under a count of how many matched. When the page
comes back full, a line under the list says more may have matched.
`QUERY...` is one or more words, joined with spaces, up to 200 characters.

| Flag | Effect |
| --- | --- |
| `--status string` | the same values as `camy jobs --status`, passed straight through; a value the server doesn't know finds nothing rather than failing |
| `-L, --limit int` | how many to show, 1 to 100 (default 25) |

If search isn't on for your account yet, the command says so and exits 1.

### One job in detail

```bash
camy jobs show jb_3f2a
camy jobs show jb_3f2a jb_02e2
camy jobs show jb_3f2a --web
```

Shows one job as a pane. What it's stuck on comes first, if anything: a
question nobody answered, with the `camy approvals answer` command that
frees it, or the error from its last run. Then its title, schedule and next
fire, last run, how its runs went, and, when the job has them, its
progress, credits spent, and the chat it came from. The pane shows up to
eight recent runs, newest first. `--json` carries up to the 50 most recent
runs; older runs aren't returned. Name several ids to get a pane each.

`--web` opens camy.ai instead of rendering the job: it prints the link to
Settings → Activity, where your jobs are listed (there's no page for a
single job), and opens it in your browser. It takes one id. The link prints
on stdout even under `--json`, so don't combine `--web` with `--json` in a
script.

With `--web` the id is still checked against your job list, so a ref
under 4 characters or one matching several jobs fails in the terminal. An
id that matches no job is not caught, and the Activity page opens anyway.
A short id costs one list call; a full id skips the network.

`ID` is the short id the list prints (`jb_3f2a`), a prefix of at least 4
characters, or a full id. A short id is resolved against the job list; one
matching more than one job is a usage error. It is matched against the
first 100 jobs only; for a job older than that, pass the full id.

### Cancelling and re-firing

```bash
camy jobs cancel jb_3f2a
camy jobs run-now jb_3f2a
```

`cancel` stops the job and its schedule, and asks for confirmation first
(see [Destructive confirmations](#destructive-confirmations)). It takes
several ids and asks once for all of them. `run-now`
pulls the job's next fire forward to now, but isn't synchronous: it fires
on the dispatcher's next tick, about 30 seconds out.

See [camy jobs](reference/camy_jobs.md), [camy jobs search](reference/camy_jobs_search.md),
[camy jobs show](reference/camy_jobs_show.md),
[camy jobs cancel](reference/camy_jobs_cancel.md), and
[camy jobs run-now](reference/camy_jobs_run-now.md) for the full flag list.

## Schedules

```bash
camy schedule
```

Lists everything that fires on a timer: the scheduled tasks you made
with `schedule create` (an agent can make one for you in a chat, too), the
reminders and timers an agent set for you during a chat, and any other
schedules on your account. These live in separate places behind the
scenes, and `camy schedule` merges them into one list, soonest next fire
first. Each row has a mark (`●` when it fires, `○` when it's paused), a
short id such as `sc_3f2a`, what it fires, when (`daily`, `hourly`,
`weekly`, `once`, the kind of reminder or timer, or a cron), and its next
fire.

A recurring schedule shows its next fire, not the first one it ever had.
A paused schedule stays in the list, under the same id, with `—` for next
fire, since it won't fire until you resume it; it sorts after everything
that will. A scheduled task on a cron outside the three `WHEN` shapes
below (weekdays only, say) shows the cron itself and `—` for next fire.

The reminders-and-timers half of the list covers the first 100 that are
still pending (active, paused, or snoozed), soonest fire first. If reading
those, or your scheduled tasks, fails, the list quietly leaves them out.

### Creating a schedule

```bash
camy schedule create WHEN --run INSTRUCTION [--tz ZONE] [--channels LIST] [--dry-run]
```

Creates a scheduled task. Each time it fires, Camy carries out the
instruction on its own, with web search as its one tool, and delivers a
short report to the channels in `--channels`.

`WHEN` accepts exactly three shapes:

| You write | Means | Cron |
| --- | --- | --- |
| `"07:00"` | daily at that time; the first fire is tomorrow if it's already past today | `0 7 * * *` |
| `"hourly"` | the next hour boundary, then every hour after | `0 * * * *` |
| `"mon 07:00"` | weekly, that weekday and time (`sun`…`sat`, first 3 letters, case-insensitive) | `0 7 * * 1` |

```bash
camy schedule create "07:00" --run "prep my morning brief"
camy schedule create "mon 09:00" --run "weekly pipeline review" --tz America/Chicago
```

`WHEN` is parsed on your machine, and the raw string never reaches the
server — it only ever sees the resulting schedule and timezone. Parsing
happens after the timezone is settled, so unless you pass `--tz` the CLI
first looks up your account's timezone, one network call.

Any other value is refused client-side as a usage error before the
schedule is created. A value containing the word "weekday", or with four or more
spaces in it — the CLI's rough heuristic for "this looks like a cron
expression" — gets a specific message saying weekday subsets and cron
expressions aren't schedulable yet.

Anything else unparseable gets a generic "couldn't parse" error. Both list
the three supported forms as the hint.

| Flag | Effect |
| --- | --- |
| `--run string` | required; the instruction that fires, up to 4,000 characters |
| `--tz string` | an IANA timezone name (`America/Chicago`, `Europe/London`); without it, your account's timezone, fetched live, falling back to this machine's local zone if that lookup fails; if neither can be named, a usage error asks for `--tz` |
| `--channels string` | where each run's report goes, comma-separated, from `thread`, `inbox`, `email`, `push`, and `user_email` (default `thread,email`); any other name is a usage error before anything is created |
| `--dry-run` | print what would be created instead of creating anything |

A create that works prints the new schedule's short id:

```text
✓ schedule sc_1a2b created · daily, next fire 2026-09-04T07:00:00-04:00 · delivers to thread, email
```

Creating takes two steps: the task, then its delivery channels (and, for
`hourly`, its cadence). If camy.ai refuses the second step, the CLI
deletes the half-made task and shows the refusal, so you're never left
with a task that isn't the one you asked for. If that delete fails too,
the error names the task and the `camy schedule delete` command that
removes it.

A schedule made with `schedule create` before 1.0.4 never ran its
instruction. If `camy schedule` still lists one, delete it and create it
again.

`--dry-run` prints a one-line summary in human mode, the exact request
body under `--json`:

```bash
camy schedule create "hourly" --run "check inbox" --tz America/New_York --dry-run
```

```text
✓ dry run — would create: check inbox · hourly (0 * * * *, America/New_York), next fire 2026-09-03T15:00:00-04:00 · delivers to thread, email
```

It never creates anything, but unless you pass `--tz` it still reads your
account timezone over the network first. If that lookup fails, the dry run
silently resolves against this machine's local zone, so what it prints can
differ from what a real create would use.

### Pausing, resuming, and deleting

```bash
camy schedule pause sc_9f8e
camy schedule resume sc_9f8e
camy schedule delete sc_9f8e
```

`ID` is the short id the list prints (`sc_9f8e`), a prefix of at least 4
characters, or a full id, resolved against every kind of schedule
together. `pause` works on everything except the reminders and timers an
agent set; those can only be deleted, and trying gives a usage error
pointing at `delete` instead.

`resume` undoes `pause`, and the schedule fires again:

```text
✓ resumed sc_9f8e
```

`resume` refuses any reminder or timer an agent set, with a usage error.
That includes a timer the agent paused, which the list shows as paused; ask
the agent in a chat to resume it, or delete it. When most of a scheduled
task's recent runs failed, camy.ai
may decline to resume it: the command exits 1 with the reason, and
`--force` resumes it anyway.

`delete` works on every kind: it cancels an agent's reminder or timer, or
deletes anything else, whichever the id resolves to. It takes several ids
and asks for confirmation once, before acting.

### Changing and firing a scheduled task

```bash
camy schedule update sc_1a2b --cron "0 8 * * *" --tz America/Chicago --channels thread,email
camy schedule run-now sc_1a2b
```

`update` and `run-now` act on scheduled tasks only, the kind
`schedule create` makes. They take the short id the list prints; a short
id that belongs to a reminder, a timer, or another kind of schedule is a
usage error.

`update` changes the task's cron (five fields), timezone, or delivery
channels in place, and needs at least one of `--cron`, `--tz`, or
`--channels`. It prints the next fire; when the task has already missed
one, it says it's overdue and fires on the scheduler's next pass instead,
and when there's no next fire to report, it prints none.

`run-now` fires it outside its schedule, on the next tick, about 30
seconds later.

See [camy schedule](reference/camy_schedule.md),
[camy schedule create](reference/camy_schedule_create.md),
[camy schedule pause](reference/camy_schedule_pause.md),
[camy schedule resume](reference/camy_schedule_resume.md),
[camy schedule delete](reference/camy_schedule_delete.md),
[camy schedule update](reference/camy_schedule_update.md), and
[camy schedule run-now](reference/camy_schedule_run-now.md) for the full
flag list. You can also print the WHEN grammar from the binary itself with
[`camy docs`](reference/camy_docs.md):

```bash
camy docs time
```

## Runs

A run is one firing of something that works on its own: a job, a
scheduled task, a schedule, a web monitor, or a standing goal. `camy runs
search` looks through your runs, and through what your agents wrote while
they ran.

```bash
camy runs search "timeout"
camy runs search "invoice" --status failed
```

Prints up to two lists. First the runs that matched: what ran, its state,
and how long ago. Then "What your agents said": each matching piece of an
agent's output, with its title, state, and age, and an excerpt with the
matching words in bold. A line under the runs says when more matched than
it shows. A line under "What your agents said" appears whenever that list
came back full, so more may have matched. Runs are listed without ids,
since no command takes one.

`QUERY...` is one or more words, joined with spaces, up to 200 characters.

| Flag | Effect |
| --- | --- |
| `--status string` | one of `running`, `completed`, `dispatched`, `skipped_empty`, `needs_attention`, `failed`; anything else is a usage error before any network call |
| `--source string` | one of `scheduled_agent`, `kernel_schedule`, `web_monitor`, `standing_goal`, checked the same way |
| `-L, --limit int` | how many runs, 1 to 100 (default 25), newest first |

`--status` and `--source` narrow the runs list only. "What your agents
said" matches on your words alone and isn't filtered by either flag.
`--source` narrows to the last four kinds of run above only; it has no
value for jobs, so a job's runs show up only when `--source` is left off.

If search isn't on for your account yet, `camy runs search` and
`camy jobs search` both say so and exit 1. Past 30 searches a minute you
get the rate-limit exit (5).

See [camy runs](reference/camy_runs.md) and
[camy runs search](reference/camy_runs_search.md) for the full flag list.

## Tasks

Quick to-dos, separate from jobs and schedules — nothing here fires on its
own.

```bash
camy tasks
```

Lists tasks under a count of how many are open: a mark, a short id such
as `tk_2b28`, the title, and the due date when one is set. An open task
shows an open circle and a done task a check, unless its due date has
passed. Then the row reads `overdue` and is marked `!`, done or not.

```bash
camy tasks add "renew passport" --due 2026-11-01 --priority high
camy tasks add "call the accountant about Q3"
```

`TITLE...` is one or more words, joined with spaces. `--due` takes an ISO
8601 date, sent as-is with no local format checking. `--priority` must be
exactly `low`, `medium`, or `high` — anything else is a usage error before
any network call.

```bash
camy tasks done tk_2b28
camy tasks reopen tk_2b28
camy tasks rm tk_2b28
```

`done` marks a task complete, with no confirmation needed, and prints the
`camy tasks reopen` command that undoes it. `reopen` puts a done task back
on the list. `rm` deletes it and asks for confirmation first. All three
take several ids, each a short id or a prefix; `rm` asks once for the
whole set.

See [camy tasks](reference/camy_tasks.md), [camy tasks add](reference/camy_tasks_add.md),
[camy tasks done](reference/camy_tasks_done.md),
[camy tasks reopen](reference/camy_tasks_reopen.md), and
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
waiting for input.

A capture holds up to 20,000 characters, and a `--title` up to 500.
Anything longer is a usage error before it's sent, never cut short, and so
is piped input over 1 MiB.

See [camy capture](reference/camy_capture.md) for the full flag list.

## Integrations

```bash
camy integrations
```

Lists connected accounts — calendar, mail, and similar providers — with a
rollup of what each one knows: an email address, or an event or message
count. When a sign-in has failed, the row reads `reconnect` and shows the
error; mail and calendar are checked separately, so a Google or Microsoft
account can show one of each.

Connected providers are listed first, then anything not connected. If your
organization has disabled a provider, that's called out in a trailing
line.

```bash
camy integrations health
camy integrations health gmail
```

A shallow check across every provider, or just one. Each row shows a
status (healthy, unknown, not connected, or a warning), and whatever detail
is available: a last error, when a token expires, or when the last sync
happened. A provider you never connected reads `not connected`, not as a
warning.

`google` and `microsoft`, the names `camy integrations` lists those
accounts under, are read as `gmail` and `outlook`. Any other `PROVIDER` is
passed through as typed, so a typo surfaces as a not-found error rather
than a specific "unknown provider" message.

### Connecting an account

```bash
camy integrations connect google
camy integrations connect github --no-browser
```

Asks camy.ai for a sign-in link, opens it in your browser, and waits while
you sign in on the provider's own page. The link has to be opened within
the time it prints; the sign-in itself can take as long as it takes. When
the provider reads connected:

```text
✓ gmail connected
```

`PROVIDER` is a provider's own name: `gmail`, `google_calendar`,
`outlook`, `microsoft_calendar`, `github`, `slack`, `zoom`, `twitter`,
`facebook`, `instagram`, `oura`, `whoop`, or `tesla`, which is also what
shell completion offers. `google` means `gmail`, since one Google sign-in
covers mail and calendar; `microsoft` means `outlook`, Outlook mail, since
Microsoft's calendar is a separate sign-in. A provider that doesn't connect
from a terminal is a usage error pointing at camy.ai.

The wait lasts up to six minutes; Ctrl-C stops waiting, and nothing is
connected until you finish in the browser. If it runs out, the command says
the account isn't connected yet and suggests running it again for a fresh
link.

| Flag | Effect |
| --- | --- |
| `--no-browser` | print the link instead of opening it |

Under `--no-input`, or when stderr isn't a terminal, the command prints the
link and returns without waiting; `--no-input` also leaves the browser
closed. Run `camy integrations` afterward to see the account.

Disconnecting an account isn't a CLI operation; do that at
camy.ai/p/settings/integrations, where you also connect the providers that
don't connect from a terminal.

See [camy integrations](reference/camy_integrations.md),
[camy integrations health](reference/camy_integrations_health.md), and
[camy integrations connect](reference/camy_integrations_connect.md) for the
full flag list.

## Webhooks

```bash
camy webhooks
```

Lists your webhook endpoints: `●` when the endpoint is active and `○` when
it is not, then a short id such as `wh_a1b2`, the URL, and its state.
Creating or removing an endpoint isn't a CLI operation — the CLI only lists
endpoints and works with their deliveries.

### Deliveries

```bash
camy webhooks deliveries wh_a1b2
camy webhooks deliveries wh_a1b2 --all --json
```

Lists delivery attempts for one endpoint, newest first, with a mark for
success or failure, the response status code (`—` when the endpoint never
answered), whether it was delivered or failed, the event type, and when it
happened.

`--limit`/`-L` (default 30 here, 100 for `camy jobs`) and `--offset` page
manually; `--all` auto-paginates, keeping whatever it already fetched if a
later page fails, the same partial-result contract as `camy jobs --all`.
`--limit` takes 1 to 200 and `--offset` can't be negative; anything else is
a usage error before any network call.

### Dead letters

```bash
camy webhooks dead-letters wh_a1b2
```

Lists the deliveries that ran out of retries, newest first: a short id
such as `dl_90ff`, the last response status code, `dead` or `replayed`,
the event type, why it gave up, and when. These `dl_` ids are what
`replay` takes; a delivery attempt from `deliveries` is not one.

### Test and replay

```bash
camy webhooks trigger wh_a1b2
```

Sends a test delivery synchronously through the same delivery path a real
event takes, so you see the endpoint's actual response rather than a
queued attempt:

```text
✓ test delivery sent — HTTP 200
```

If the endpoint didn't take the delivery, `trigger` fails (exit 1) and says
why: the endpoint's error, the HTTP status it answered with, or that it
never answered.

```bash
camy webhooks replay wh_a1b2 dl_90ff
```

Re-enqueues one dead-lettered delivery under a fresh idempotency key, so
it's retried as a new attempt rather than deduplicated against the failed
one. The dead-letter id is resolved against that endpoint's dead letters;
a short id that matches none is a usage error.

### Endpoint and delivery ids

Both ids in this section take the short form their own list prints: the
endpoint id taken by `deliveries`, `dead-letters`, `trigger`, and `replay`
as `camy webhooks` prints it (`wh_a1b2`), and the dead-letter id in
`replay` as `camy webhooks dead-letters` prints it (`dl_90ff`). A prefix of
at least 4 characters, or the full id, works too.

See [camy webhooks](reference/camy_webhooks.md),
[camy webhooks deliveries](reference/camy_webhooks_deliveries.md),
[camy webhooks dead-letters](reference/camy_webhooks_dead-letters.md),
[camy webhooks trigger](reference/camy_webhooks_trigger.md), and
[camy webhooks replay](reference/camy_webhooks_replay.md) for the full
flag list.

## Destructive confirmations

`camy jobs cancel`, `camy schedule delete`, and `camy tasks rm` each ask
before acting:

```text
cancel job jb_3f2a? [y/N]
```

Given several ids, they ask once for the whole set (`cancel 3 jobs? [y/N]`).
Anything other than `y`/`yes` cancels the operation. The prompt reads
`/dev/tty` directly, not stdin, so it never conflicts with a command that
also takes piped input elsewhere (`camy capture -`, for instance, stays
purely a stdin reader).

Running headless — `--no-input`, or no controlling terminal at all — skips
the prompt and fails closed with a usage error unless you pass `--force`:

```bash
camy jobs cancel jb_3f2a --force
camy schedule delete sc_9f8e --force
camy tasks rm tk_2b28 --force
```

When some of several ids fail, the rest still go through: camy lists the
ones that didn't work and exits with the worst code among them.

This is camy's lighter confirmation tier. A few irreversible commands
([`camy auth logout`](reference/camy_auth_logout.md) `--revoke`,
[`camy uninstall`](reference/camy_uninstall.md)) use a stricter one where
`--force` is not enough and you type the word back or pass `--confirm` — see
[Scripting with camy](scripting.md) and [Exit codes](exit-codes.md).

## `--json` output

Every command in this document supports `--json`. Shapes vary by command:

- `camy jobs`, `camy tasks`, `camy webhooks`, `camy webhooks deliveries`,
  `camy webhooks dead-letters`, `camy integrations` — a JSON array of rows:
  the CLI unwraps the server's list envelope, but each row is passed
  through field for field. An empty list is `[]`. Add `--raw` for the
  server's own envelope instead (except on an `--all` sweep, which stays an
  array).
- `camy jobs --all` / `camy webhooks deliveries --all` on a mid-sweep
  failure — `{"partial": true, "results": [...], "rows": N, "error": "..."}`,
  still a non-zero exit.
- `camy jobs search`, `camy runs search` — the server's whole answer as one
  object, not an array, so it carries whether more matched: `truncated`
  for jobs; `has_more`, the `output_matches` list, and
  `output_matches_truncated` for runs. `truncated` and
  `output_matches_truncated` mean the page was full and there may be more;
  `has_more` is exact.
- `camy jobs show ID` — the full job object as the server returns it.
- `camy webhooks trigger ID` — the test-delivery result the endpoint
  returned, not the endpoint row. It prints even when the event wasn't
  delivered, and the command then exits 1.
- `camy schedule` — one array of every kind of schedule, in the order
  they're read rather than by next fire: other schedules first, then an
  agent's reminders and timers, both as the server sends them, then
  scheduled tasks, each trimmed to `id`, `type` (`"scheduled_task"`),
  `name`, `label`, `status`, `recurrence_rule`, `next_fire_at` (`null`
  when it won't fire or can't be worked out), `cron`, `timezone`,
  `channels`, and `created_at`. The kinds have different shapes.
- `camy schedule create --dry-run --json` — the request body that would
  have been sent, never sent: the task's name, the prompt around your
  instruction, and its schedule. For example:

  ```bash
  camy schedule create "hourly" --run "check inbox" --tz America/New_York --dry-run --json --jq '.schedule_config'
  ```

  ```json
  {"cron":"0 * * * *","mode":"scheduled","timezone":"America/New_York"}
  ```

  The delivery channels are set in a second step after the task is
  created, so they aren't in this body.
- `camy capture`, `camy tasks add`, `camy schedule create` (without
  `--dry-run`) — the created object as the server returned it; for
  `schedule create`, with the delivery channels added under
  `delivery_config`.
- `camy jobs cancel`, `camy schedule pause`, `camy schedule resume`,
  `camy schedule delete`, `camy tasks done`, `camy tasks reopen`,
  `camy tasks rm` — a small confirmation object, for example:

  ```json
  {"ok": true, "job_id": "a1b2c3d4...", "cancelled": true}
  ```

- `camy jobs run-now`, `camy schedule run-now` — a confirmation object
  with an extra field noting when it fires:

  ```json
  {"ok": true, "job_id": "a1b2c3d4...", "fires": "next tick (~30s)"}
  ```

- `camy jobs show`, `camy jobs cancel`, `camy schedule delete`,
  `camy tasks done`, `camy tasks reopen`, `camy tasks rm` given several
  ids — an array with one object per id: what that id returned, plus
  `ref` (what you typed), `ok`, the full `id` once it resolved, and
  `error` when that id failed. Given one id, they emit the single object
  shown above.
- `camy schedule update` — the updated schedule as the server returns it.
- `camy webhooks replay` —
  `{"ok": true, "endpoint_id": "...", "replayed": "<dead letter id>"}`.
- `camy integrations health` — the raw server response object.
- `camy integrations connect` — the sign-in link as camy.ai returned it,
  with the provider's name and how long the link can be opened; nothing
  opens and nothing waits.

Apart from the scheduled tasks `camy schedule` trims, none of these shapes
are scrubbed the way
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
