# Inbox, sweep, and feed

Three surfaces, one page. `camy inbox` is a unified view across your
connected mail accounts, with a triage verdict on every message.
`camy sweep` sets how much of that triage camy does on its own. `camy feed`
is the separate stream of cards camy raises for you — approvals, alerts,
anything that wants a word.

```bash
camy inbox --needs-you   # what is waiting on you
camy sweep               # the current mode
camy feed                # cards waiting for a word
```

## The unified inbox

```bash
camy inbox
```

Lists mail across your connected accounts, one line per message: a short
id, the sender, the subject, and a triage verdict. With nothing to show it
prints `inbox zero — nothing here` and exits 0.

The verdict is computed locally from whether the message is read and its
classification — the list itself carries no separate verdict field:

- **needs you** — unread, and not in a bulk class
- **handled** — read, and not in a bulk class
- **filed** — classified as newsletter, marketing, automated mail, or
  similar bulk mail, regardless of read state

Above the list, human mode prints a header with unread and needs-you
counts. The header is stderr chrome: `camy inbox | wc -l` never counts it,
and `-q` suppresses it.

Whenever the number of rows shown differs from your total unread count, a
footer line states both figures and points at a larger `-L` or `--all`.
That line is part of stdout, alongside the rows.

### Flags

| Flag | Effect |
|---|---|
| `--unread` | unread only |
| `--needs-you` | only what's waiting on you |
| `--tab string` | one of `needs-you`, `unread`, `people`, `newsletters`, `receipts`, `calendar`, `all` |
| `--cursor string` | resume from a `next_cursor` |
| `-L, --limit int` | page size |
| `--all` | auto-paginate to the end, following `next_cursor` |

```bash
camy inbox --needs-you
camy inbox --tab newsletters -L 50
camy inbox --all
```

An unrecognized `--tab` value is a usage error (exit 2) before any request
goes out. See [camy inbox](reference/camy_inbox.md) for the complete flag
reference.

### Reading a message

```bash
camy inbox show em_7f31
```

Prints one message in full: subject, sender, date, an attachment count if
there are any, the AI summary and why-it-matters line when triage is
available, then the body. Attachments open on the web, not from the CLI.

If the message carries a List-Unsubscribe method, a hint line points at
`camy inbox unsubscribe`. Pass `-w`/`--web` to open the message at
`https://camy.ai/p/inbox` instead of printing it in the terminal.

An id that resolves to nothing is a runtime error (exit 1), not an empty
success — a missing message never looks like an empty one.

```bash
camy inbox read em_7f31
```

Shows the message exactly like `show`, then marks it read — two steps
fused into one, never a silent write with no output.

See [camy inbox show](reference/camy_inbox_show.md) and
[camy inbox read](reference/camy_inbox_read.md).

### Batch actions

```bash
camy inbox mark-read em_7f31 em_a01c
camy inbox archive em_7f31
camy inbox restore em_7f31
```

Each takes one or more ids and applies the same action to each in turn.
The batch stops at the first id that fails — ids already processed before
that point have already taken effect. There is no aggregate `--json`
summary distinguishing which ids succeeded.

See [camy inbox mark-read](reference/camy_inbox_mark-read.md),
[camy inbox archive](reference/camy_inbox_archive.md), and
[camy inbox restore](reference/camy_inbox_restore.md).

### Unsubscribing

```bash
camy inbox unsubscribe em_7f31
```

Acts on the message's List-Unsubscribe header. A one-click or `mailto`
method runs server-side and confirms directly. A link method never fetches
itself — a `GET` isn't an unsubscribe — so the CLI prints the link for you
to open instead. A message with no unsubscribe method available says so.

See [camy inbox unsubscribe](reference/camy_inbox_unsubscribe.md).

### Replying

```bash
camy inbox reply em_7f31
```

With no `--body`, this drafts a reply grounded in the message and prints
it — nothing is sent. Add `--send` to queue it:

```bash
camy inbox reply em_7f31 --edit --send
camy inbox reply em_7f31 --body "sounds good" --send --at 2h
```

| Flag | Effect |
|---|---|
| `--body string` | skip the AI draft and use your text instead |
| `--edit` | open the draft (or your `--body` text) in `$EDITOR` first |
| `--send` | queue the reply into a short undo window |
| `--at string` | schedule further out: a duration or RFC3339 timestamp |
| `--no-wait` | accepted; the send path is identical either way |

- `--edit` needs a real terminal; in a headless session use `--body`
  instead.
- The undo window is 30 seconds by default. The queued line prints the
  real send time, and `camy inbox outbox` shows it too.
- `--at` replaces that default window and requires `--send` — passing
  `--at` alone is a usage error. It also refuses anything that isn't
  strictly in the future.
- Under `--json` with no `--send`, the draft path emits
  `{"draft": "…", "sent": false}`; with `--send` you get the server's
  outbox response instead.

```bash
camy inbox undo ob_31f2
```

Pulls a queued reply back before it leaves, inside the undo window. The
outbox id is used exactly as given — it is not resolved from a short
prefix the way other ids in this area are.

```bash
camy inbox outbox
```

Lists everything still inside its undo window: an id, its kind, and when
it sends.

See [camy inbox reply](reference/camy_inbox_reply.md),
[camy inbox undo](reference/camy_inbox_undo.md), and
[camy inbox outbox](reference/camy_inbox_outbox.md).

### Sending new mail

```bash
camy inbox send jordan@acme.com --subject "Redlines" --body "see attached"
camy inbox send a@x.com,b@y.com --subject Update --edit
camy inbox send a@x.com --subject "Standup" --body "…" --at 2h
```

`TO...` takes one or more recipients — each may itself be a comma-separated
list.

Without `--at`, this is synchronous, unlike `reply --send`: **there is no
outbox and no undo window**. Once it sends, it's sent.

With `--at` the send is deferred, but `camy inbox send` still hands back no
outbox handle of its own. `camy inbox undo` takes the outbox ids
`reply --send` returns, so check `camy inbox outbox` for a handle before
counting on being able to stop a scheduled send.

| Flag | Effect |
|---|---|
| `--subject string` | required |
| `--body string` | email body (skips `$EDITOR`) |
| `--edit` | open the body in `$EDITOR` first |
| `--cc string`, `--bcc string` | comma-separated addresses |
| `--provider string` | `gmail` or `outlook`; defaults to your first connected account |
| `--at string` | schedule instead of sending now: a duration or RFC3339 timestamp |

Every send asks for confirmation first — `send to <recipients> now`, or
the scheduled equivalent with `--at`. In a script, pass `--force` once you
trust the addresses; without a terminal and without `--force`, the command
exits 2 rather than sending. This confirmation applies even under `--json`.

The recipient count (`to` + `cc` + `bcc` combined) is capped at 50; going
over it is a usage error before any request is sent. An empty body after
`--edit`/`--body` is also a usage error.

If the send returns success at the HTTP level but the mail provider itself
rejected it, `camy inbox send` still exits non-zero — under `--json` the
response body is printed first so you can see why, then the command exits
1. A bounced send is never reported as sent, to a script or otherwise.

See [camy inbox send](reference/camy_inbox_send.md).

### Snoozing

```bash
camy inbox snooze em_7f31 --until 3h
camy inbox snooze em_7f31 --until 2026-09-03T09:00:00-07:00
camy inbox unsnooze em_7f31
```

`--until` is required on `snooze` and takes a duration or an RFC3339
timestamp — like every other `--at`/`--until` in this area, it refuses a
value that isn't strictly in the future. A snoozed message resurfaces to
the inbox automatically once the time passes; `unsnooze` brings it back
immediately instead.

See [camy inbox snooze](reference/camy_inbox_snooze.md) and
[camy inbox unsnooze](reference/camy_inbox_unsnooze.md).

### Short ids

Every id in this section accepts a prefix of at least 4 characters — the
same 8 characters `camy inbox` prints in its list.

- A prefix under 4 characters is refused outright.
- A prefix matching nothing is passed through to the API, which reports it
  not found.
- A prefix matching more than one message is a usage error asking for a
  longer one. Resolution never guesses between candidates.

Three things are taken exactly as typed instead: the outbox id used by
`inbox undo`, `inbox send`'s recipients, and `inbox show -w`, which puts
the id you typed straight into the URL without resolving it.

## The sweep dial

`camy sweep` controls how much triage camy is allowed to do to your inbox
without asking each time.

```bash
camy sweep
```

Prints the current mode and whether it's paused.

### Modes

The dial takes exactly four values: `off`, `shadow`, `suggest`, `auto`.

```bash
camy sweep set suggest
camy sweep set auto --dry-run
```

`camy sweep set` refuses anything else as a usage error before any request
goes out.

The CLI does not define the four modes — it checks the name you typed and
hands it to your account, which applies it server-side, so `camy sweep`
reads back whatever your account is set to. Whatever a sweep files stays
listed and reversible through `camy sweep review` and `camy sweep restore`.

`--dry-run` shows the current mode against the one you're about to set,
without writing anything.

See [camy sweep](reference/camy_sweep.md) and
[camy sweep set](reference/camy_sweep_set.md).

### Reviewing and restoring

```bash
camy sweep review
```

Lists every batch the sweep has filed, restorable: a batch id, how many
messages, and when. With nothing filed yet, it says so rather than
printing an empty table.

`sweep review` shortens the batch id it prints to its first 8 characters,
and `sweep restore` takes the id exactly as given — it does not expand a
prefix the way the inbox ids do. If the shortened id is rejected, take the
full one from `camy sweep review --json`.

```bash
camy sweep restore batch_9f2
camy sweep restore batch_9f2 --items em_1,em_2
```

Brings a filed batch back to the inbox. `--items` restores only the listed
message ids from that batch instead of the whole batch — the list is
split on commas exactly as typed, so write `em_1,em_2` with no spaces.
Either way the CLI reports the restore as
`back in the inbox, sender remembered`.

See [camy sweep review](reference/camy_sweep_review.md) and
[camy sweep restore](reference/camy_sweep_restore.md).

## The feed

`camy feed` is a separate surface from the inbox: cards camy surfaces for
you — approvals, alerts, things that need a word — the same feed the web
home shows.

```bash
camy feed                     # new + pending cards
camy feed show 3f2a
camy feed act 3f2a sweep_archive
camy feed dismiss 3f2a
```

Each line shows a short id, the card type, the title, and how long ago it
arrived. With nothing to show, `camy feed` prints
`nothing in the feed — all quiet`.

By default `camy feed` lists new and pending cards only; `--all` lists
every card regardless of status. `-L, --limit int` sets the page size
(default 40).

See [camy feed](reference/camy_feed.md).

### Reading a card

```bash
camy feed show 3f2a
```

Prints the full card: title, type, body, and — when the card offers any —
one line per available action with its action id and label.

See [camy feed show](reference/camy_feed_show.md).

### Acting on a card

```bash
camy feed act 3f2a sweep_archive
camy feed act 3f2a sweep_archive --note "already handled" --force
```

`ACTION_ID` must be one the card actually offers. When the card resolves,
the CLI checks the id against the card's own action list before any
request is sent, so a typo surfaces as a usage error rather than an opaque
server failure.

Acting on a card older than the newest 100 by its full id skips the local
check, and the server has the last word. `--note` attaches an optional
note to the action.

Like `inbox send`, this confirms before firing: a TTY asks y/N, and a
headless run without `--force` exits 2 — including under `--json`. Script
it with `--force` once you trust the action id.

```bash
camy feed dismiss 3f2a
```

Puts a card away. Unlike `act`, `dismiss` does **not** ask for
confirmation — a deliberate difference between the two, worth knowing
before scripting either one.

See [camy feed act](reference/camy_feed_act.md) and
[camy feed dismiss](reference/camy_feed_dismiss.md).

### Short ids in the feed

`show`, `act`, and `dismiss` resolve a short id against the newest 100
cards — the server has no way to look further back by id prefix. A card
older than that window is only reachable by its full id, and only for
`act`/`dismiss`; `feed show` has no such fallback and reports the card as
unreachable within the newest 100.

`camy feed --all -L 100` lists every card a short id can still reach —
`--all` on its own widens the status filter but keeps the default page
size of 40.

## `--json` output

| Command | Emits |
|---|---|
| `inbox`, `inbox outbox`, `feed` | the raw array of rows the server returned — no counts header, no pager |
| `inbox show`, `inbox read`, `feed show`, `sweep` | the full raw object for the one item requested |
| `sweep review` | the server's whole review object, with the batches under a `batches` key |
| `unsubscribe`, `reply`, `send`, `snooze`, `unsnooze`, `undo`, `sweep set`, `sweep restore`, `feed act`, `feed dismiss` | a small result object on success: either the server's own response, or a locally built `{"ok": true, ...}` for the few that construct their own confirmation |
| `mark-read`, `archive`, `restore` | nothing at all — check the exit code |

Empty lists differ by command. `camy inbox` emits `null` rather than `[]`,
while `inbox outbox` and `feed` emit `[]` when the server sends an empty
list. A script that iterates should write `jq '. // [] | .[]'` (or test
for null) rather than `jq '.[]'`, so it survives either shape.

`inbox read` emits the same object `inbox show` does, then marks the
message read. The per-id success lines of `mark-read`, `archive`, and
`restore` are suppressed in machine mode and nothing replaces them.

The reference pages list flags, not payloads — run the command once with
`--json` (or `--jq .`) to see the exact object a given verb returns.

## See also

- [Approvals](approvals.md) — the approval model that other risky actions
  in camy go through; `inbox send` and `feed act` use a separate,
  lighter-weight confirmation instead, described above
- [Scripting with camy](scripting.md) — the `--json`/`--jq`/`--template`
  contract, `--no-input`, and exit codes in general
- [Exit codes](exit-codes.md) — the frozen table
- [Command reference](reference/camy.md) — every flag on every command in
  this document
