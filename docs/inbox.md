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

Lists mail across your connected accounts, one line per message: a mark
for the triage verdict, a short id, the sender, the subject, and how long
ago it arrived. For mail you sent, the sender column names who it went to
instead (`to jordan@acme.com`). With nothing to show it prints
`inbox zero — nothing here` and exits 0; a filtered view with nothing in
it says `nothing here — this view is filtered` instead.

The verdict is computed locally from whether the message is read and its
classification — the list itself carries no separate verdict field:

- `!` **needs you** — unread, and not in a bulk class
- `✓` **handled** — read, and not in a bulk class
- `○` **filed** — classified as newsletter, marketing, automated mail, or
  similar bulk mail, regardless of read state

Above the list, a count line gives your unread and needs-you totals
(`3,342 unread · 7 need you`), with `camy inbox --needs-you` at its right
unless `--needs-you` or `--tab` already narrows the list. Below the rows, a line of commands suggests where to
go next. Both are part of stdout, alongside the rows, so a script that
wants only the messages should use `--json`.

When there's another page after the one shown, a footer says how many
rows you're seeing out of how many the view holds, and how to get the
rest:

```text
showing 60 of 3,342 · --all walks everything · next page: --cursor '…'
```

The total counts the same view you asked for: the whole inbox, your unread
mail with `--unread`, what needs you with `--needs-you`, or the tab's own
count with `--tab`. When no count covers the view (`--tab people --unread`,
say), the footer gives the row count alone. The last page of a view has no
footer. That line is part of stdout too.

### Flags

| Flag | Effect |
|---|---|
| `--unread` | unread only |
| `--needs-you` | only what's waiting on you |
| `--tab string` | one of `needs-you`, `unread`, `people`, `newsletters`, `receipts`, `calendar`, `all` |
| `--cursor string` | resume from a `next_cursor` |
| `-L, --limit int` | page size, 1 to 200 (default: the server's 60) |
| `--all` | auto-paginate to the end, following `next_cursor` |

```bash
camy inbox --needs-you
camy inbox --tab newsletters -L 50
camy inbox --all
```

An unrecognized `--tab` value, or a `-L` above 200 or below zero, is a
usage error (exit 2) before any request goes out. See
[camy inbox](reference/camy_inbox.md) for the complete flag reference.

### Reading a message

```bash
camy inbox show em_7f31
camy inbox show em_7f31 em_2a0c
```

Prints one message in full: the short id and subject, with `unread` or
`read` at the right (or the list's triage verdict, when camy.ai sends the
message's classification); then the sender, every recipient on `to`, `cc`,
and `bcc` lines, the date received, and an attachment count if there are
any; then the commands you can run on it (`reply`, `archive`,
`mark-read`); then the AI summary and why-it-matters line when triage is
available, and the body last. On a narrow terminal a long subject wraps under itself and that
word takes its own line, so the header never runs past the edge.
Attachments open on the web, not from the CLI. Name several ids to get one
message after another.

If the message carries a List-Unsubscribe method, the commands line offers
`unsubscribe` too. Pass `-w`/`--web` to open the message itself in the web
inbox at `https://camy.ai/p/inbox` instead of printing it in the terminal.
`-w` takes one id at a time. A short id or prefix that matches no email in
your inbox is refused (exit 2) rather than opening the page on nothing. A
full id opens the page without being checked.

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
camy inbox trash em_7f31 em_2a0c
camy inbox unread em_7f31
camy inbox restore em_7f31
```

Each takes one or more ids and applies the same action to each. Every id
is resolved first, then every one that resolved is acted on: an id that
fails doesn't stop the rest. Each success prints its own line
(`✓ archived — em_7f31`). If any failed, the command ends with a summary
such as `1 of 3 didn't work`, naming each id that failed and why, and
exits non-zero; what went through stays done, and nothing is rolled back.

The server can accept a request and still change nothing, for instance
for an id that isn't one of your emails. That counts as a failure, never a
✓: `archive didn't apply — the server changed nothing for that email`
(exit 1). The same goes for the mark `camy inbox read` makes after showing
the message.

`restore` finds a short id among the 1,000 most recently received
messages in your archived mail and in your trash. When camy can read those
folders, a short id none of them holds is refused before anything is sent:
`no archived or trashed email matches em_7f31` (exit 2). A message received
earlier than those needs its full id (`--json` on `archive` or `trash`
prints it), even if you archived or trashed it a moment ago.

See [camy inbox mark-read](reference/camy_inbox_mark-read.md),
[camy inbox archive](reference/camy_inbox_archive.md), and
[camy inbox restore](reference/camy_inbox_restore.md).

### Moving mail to the trash

```bash
camy inbox trash em_7f31 em_2a0c
```

Moves each message to the trash and prints a line for each one that went
(`✓ trashed — em_7f31`). The ✓ line means the message moved to the trash
in Camy. camy.ai also tries to make the same change at your mail provider,
but camy doesn't report whether that part worked. Trashing a message also
marks it read. It follows the batch rules above and asks for no
confirmation: `camy inbox restore` brings trashed mail back.

See [camy inbox trash](reference/camy_inbox_trash.md).

### Marking mail unread

```bash
camy inbox unread em_7f31 em_2a0c
```

The opposite of `mark-read`: marks each message unread and prints a line
for each (`✓ unread — em_7f31`). The ✓ line means the message was marked
unread in Camy. camy.ai also tries to make the same change at your mail
provider, but camy doesn't report whether that part worked.
`camy inbox mark-unread` is the same command. It follows the batch rules
above.

See [camy inbox unread](reference/camy_inbox_unread.md).

### Unsubscribing

```bash
camy inbox unsubscribe em_7f31
```

Acts on the message's List-Unsubscribe header. A one-click or `mailto`
method runs server-side and confirms directly
(`✓ unsubscribed — via one-click`). A link method never fetches itself — a
`GET` isn't an unsubscribe — so the CLI prints the link for you to open
instead. A message with no unsubscribe method fails with
`this email carries no unsubscribe method` (exit 1): nothing was done, and
`camy inbox archive` files it instead.

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
  clock time it closes, with the date when that isn't today
  (`✓ queued — sending at 10:04:30 · changed your mind? camy inbox undo …`),
  and `camy inbox outbox` shows it too.
- `--at` replaces that default window and requires `--send` — passing
  `--at` alone is a usage error. It also refuses anything that isn't
  strictly in the future.
- Before a scheduled reply says `✓ queued for …`, camy checks the outbox,
  but only when it can trust the answer: the send is due more than 30
  seconds out, camy.ai answered with an outbox id, and the outbox can be
  read and lists at least one queued send (and fewer than 200). If that id
  isn't among them, the command fails instead:
  `not queued — camy.ai answered with ob_31f2, which isn't waiting in the outbox`
  (exit 1), with a hint to check `camy inbox outbox` before scheduling
  again. Under `--json` the server's response still prints first. With
  nothing else in the outbox, as after undoing your only queued reply,
  camy can't tell and still prints `✓ queued for …`, so check
  `camy inbox outbox` yourself.
- Under `--json` with no `--send`, the draft path emits
  `{"draft": "…", "sent": false}`; with `--send` you get the server's
  outbox response instead.

```bash
camy inbox undo ob_31f2
camy inbox undo ob_31f2 ob_9c4d
```

Pulls one or more queued replies back before they leave, inside the undo
window. It takes the `ob_` short id `camy inbox outbox` prints, a prefix of
at least 4 characters, or the full id, and resolves it against what is
still queued: an id that matches nothing queued is refused
(`nothing queued matches ob_31f2`, exit 2). That includes an `ob_` short
id for a reply that already left or was already cancelled. It reports
`✓ cancelled — ob_31f2 never left` only when the send was actually pulled
back. `not cancelled` (exit 1) happens only for a full outbox id, or when
the send goes out between the lookup and the cancel.

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

A send can also fail in a way that leaves it unclear whether the mail
left: camy.ai answers with a server error, or no answer comes back in time.
Then camy doesn't tell you to just try again. The hint says
`check your Sent folder before retrying — it may have gone out`, or for a
scheduled send
`check camy inbox outbox before retrying — it may already be queued`.
Without `--provider` it adds
`if it didn't, retry with --provider gmail|outlook`.

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
immediately instead and says `✓ back in the inbox — em_7f31`.

`unsnooze` looks a short id up among your snoozed mail (the newest 1,000),
not in the inbox, and never sends one it couldn't find there. A short id
that matches no snoozed email is a usage error
(`no snoozed email matches em_7f31 — nothing to bring back`, exit 2). A
full id goes through as typed, unless camy can tell from your snoozed mail
that it isn't snoozed: then it fails with
`em_7f31 isn't snoozed — nothing to bring back` (exit 1).

See [camy inbox snooze](reference/camy_inbox_snooze.md) and
[camy inbox unsnooze](reference/camy_inbox_unsnooze.md).

### Short ids

Every email id in this section accepts the typed short id `camy inbox`
prints (`em_7f31`), a bare prefix of at least 4 characters of the full id,
or the full id. A short id is looked up in your whole inbox, then your
needs-you view, then your unread mail (the newest 200 of each), so a
message that sits far down a large inbox still resolves. `restore` and
`unsnooze` look where that mail lives instead: your archived mail and
trash, or your snoozed mail (the newest 1,000 of each).

- A prefix under 4 characters is refused outright.
- A prefix matching nothing is passed through to the API, and the command
  fails there rather than guessing.
- A prefix matching more than one message is a usage error asking for a
  longer one. Resolution never guesses between candidates.

Four verbs refuse a prefix that matches nothing instead of passing it on:
`inbox show -w`, because the web page needs the full id; `inbox undo`,
which resolves outbox ids against `camy inbox outbox`; `inbox unsnooze`;
and `inbox restore`, whenever it can read your archived mail and trash.
`inbox send`'s recipients are addresses, taken exactly as typed.

## The sweep dial

`camy sweep` controls how much triage camy is allowed to do to your inbox
without asking each time.

```bash
camy sweep
```

Prints the dial: all four modes, each with a line on what it does, the
current one marked `← now` (`← now, paused` when it's paused), then the
commands to review what it filed, restore it, and step the dial up or
down.

### Modes

The dial takes exactly four values: `off`, `shadow`, `suggest`, `auto`.

```bash
camy sweep set suggest
camy sweep set auto --dry-run
```

`camy sweep set` refuses anything else as a usage error before any request
goes out.

The CLI does not carry out the four modes — `sweep set` checks the name
you typed and hands it to your account, which applies it server-side, so
`camy sweep` reads back whatever your account is set to. Whatever a sweep
files stays listed and reversible through `camy sweep review` and
`camy sweep restore`.

On success `sweep set` prints
`✓ sweep dial → suggest — you can always camy sweep review`. If the server
doesn't save the change, it fails with the reason (exit 1) instead of
confirming a dial that didn't move.

`--dry-run` shows the current mode against the one you're about to set,
without writing anything.

See [camy sweep](reference/camy_sweep.md) and
[camy sweep set](reference/camy_sweep_set.md).

### Reviewing and restoring

```bash
camy sweep review
```

Lists every batch the sweep has filed, restorable: a batch id, how many
messages, and when. Under each batch comes one line per message it filed:
the item id `restore --items` takes, then the sender and subject, with
`(back in the inbox)` after one that has already been restored. With
nothing filed yet, it says so rather than printing an empty table.

`sweep review` shortens the batch id it prints to its first 8 characters,
and `sweep restore` resolves that short id, or any prefix of at least 4
characters, against the same list. A prefix that matches no batch is a
usage error (exit 2) before anything is restored.

```bash
camy sweep restore 9f2c41ab
camy sweep restore 9f2c41ab --items gmail_18f2a9c0d1,gmail_18f2a9c0d2
```

Brings a filed batch back to the inbox. `--items` restores only the listed
items from that batch instead of the whole batch — the list is split on
commas and each id trimmed, so `--items "a, b"` works. An `--items` that
names no ids (`--items ""`) is a usage error (exit 2), never a whole-batch
restore; drop the flag to restore the whole batch.
The CLI reports how many came back
(`✓ restored 26 emails — back in the inbox, sender remembered`). If
nothing came back, because no such batch exists or everything in it is
already in the inbox, `restore` says `nothing restored` and exits 1.

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

Each line shows a short id (`fd_3f2a`), the kind of card, the title, and
how long ago it arrived. Approval, needs-input, escalation and alert cards
that are still new or pending are marked `!` and counted in the line above
the list (`2 cards · 1 need a decision`). Other cards are listed without
the mark.
With nothing to show, `camy feed` prints `nothing needs a decision`.

By default `camy feed` lists new and pending cards only; `--all` lists
every card whatever its status, including held, snoozed, done, dismissed,
expired, and archived ones. `-L, --limit int` sets the page size, 1 to 100
(default 40); anything outside that is a usage error (exit 2) before any
request goes out.

See [camy feed](reference/camy_feed.md).

### Reading a card

```bash
camy feed show 3f2a
camy feed show 3f2a 90ac
```

Prints the full card: title, type, body, and — when the card offers any —
one line per available action with its action id and label. Name several
ids to get a card each.

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

If the server doesn't carry the press out, for instance because it came
too late or the action needs a confirmation in the Camy app first, `act`
fails with the server's reason (exit 1) instead of printing ✓.

```bash
camy feed dismiss 3f2a
camy feed dismiss 3f2a 90ac
```

Puts one or more cards away, and fails the same way when the server
refuses. Unlike `act`, `dismiss` does **not** ask for confirmation — a
deliberate difference between the two, worth knowing before scripting
either one.

See [camy feed act](reference/camy_feed_act.md) and
[camy feed dismiss](reference/camy_feed_dismiss.md).

### Short ids in the feed

`show`, `act`, and `dismiss` resolve a short id against the first 100 new
and pending cards, highest priority first and then newest. If it isn't
there, they resolve it against the first 100 cards of any status in the
same order, so a done or dismissed card's short id resolves too. The server
has no way to look further back by id prefix. A card outside that
window is only reachable by its full id, and only for `act`/`dismiss`;
`feed show` has no such fallback and reports the card as unreachable
within the newest 100.

`camy feed --all -L 100` lists that second window — `--all` on its own
widens the status filter but keeps the default page size of 40.

## `--json` output

| Command | Emits |
|---|---|
| `inbox`, `inbox outbox`, `feed` | the raw array of rows the server returned — no counts line, no pager |
| `inbox show`, `inbox read`, `feed show`, `sweep` | the full raw object for the one item requested |
| `sweep review` | the server's whole review object, with the batches under a `batches` key |
| `unsubscribe`, `reply`, `send`, `snooze`, `unsnooze`, `undo`, `sweep set`, `sweep restore`, `feed act`, `feed dismiss` | a small result object on success: either the server's own response, or a locally built `{"ok": true, ...}` for the few that construct their own confirmation |
| `mark-read`, `unread`, `archive`, `trash`, `restore` | a locally built `{"ok": true, "email_id": "…", "action": "archive"}`, with the full email id |

An empty list is `[]`, never `null`, for all three listings, so
`jq '.[]'` is safe on an empty inbox. `--raw` swaps the array for the
server's own response object, which is where `next_cursor` lives for
`--cursor`; with `--all` there is no single response to hand back, so the
array stands.

The verbs that take several ids (`inbox show`, `mark-read`, `unread`,
`archive`, `trash`, `restore`, `undo`, `feed show`, `feed dismiss`) emit
the object above when you name one id. Name several and you get an array with one object per id,
each carrying the `ref` you typed, `ok`, and an `error` when that id
failed. A single id that fails emits that same per-id object before the
command exits non-zero.

`inbox read` emits the same object `inbox show` does, then marks the
message read.

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
