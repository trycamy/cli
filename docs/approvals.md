# Approvals

Anything camy's agent wants to do that carries real risk — running a command
on your machine, writing a file, sending a message, publishing something —
pauses first. That pause is a checkpoint. You clear it by approving,
denying, or answering it, from wherever you happen to be: the terminal that
hit it, the full-screen app, the web, or a different terminal entirely.

```bash
camy approvals                  # what's waiting
camy approvals show ID...       # the full checkpoint, before you decide
camy approvals approve ID...    # approve
camy approvals deny ID...       # deny
camy approvals answer ID TEXT...   # answer a question/choice/form
```

Those five commands clear a checkpoint the same way no matter where it
surfaced. Each one's reference page carries its full flag list.

## The model

A checkpoint pauses one of four kinds of thing:

- an **approval** — a plain yes/no, most often a local command or file write
- a **question** — free text
- a **choice** — pick one or more from a list, or type your own answer
- a **form** — a few fields, filled in one at a time

Nothing runs on a timeout. A checkpoint nobody decides is never approved and
never denied — it stays pending until someone decides it, or until the
server's own `expires_at` passes and it is recorded as expired. Stopping the
turn it belongs to cancels it too. When the turn was paused on approvals,
the camy app says how many it cancelled.

One carve-out: a local command the CLI can itself verify is read-only and
confined to your project root, or one covered by a grant you added with
[`camy local trust`](reference/camy_local_trust.md) or by the exact grant
`a` records, is answered automatically on a turn camy.ai has marked eligible
for auto-answering (a verified read may also arrive with no card at all);
otherwise it gets a card like any other — see
[The local bridge](local-bridge.md).

### Checkpoint ids

`ID` accepts the typed short id `camy approvals` prints in its list
(`ap_789a`), a bare prefix of at least 4 hex characters of the checkpoint
id, or the full id. The list lengthens a short id past four characters only
when two pending checkpoints would otherwise share it. `--ids=hex` prints the
older untyped 8-character form instead, for this release.

- A prefix that matches nothing is passed straight to the API by `approve`,
  `deny` and `answer`, which report it as not found; `show` instead fails
  locally with "no pending checkpoint …".
- A prefix that matches more than one pending checkpoint is a usage error
  asking for a longer one.

## Listing and reading

```bash
camy approvals
camy approvals --web
camy approvals show ap_789a
```

[`camy approvals`](reference/camy_approvals.md) groups what is waiting by
what the decision is — NEEDS AN ANSWER, WANTS TO RUN SOMETHING, WANTS TO
SEND SOMETHING — one line per checkpoint: a typed short id (`ap_789a`),
what it wants in plain words, the detail, where the bite would land and how
bad (`⌂ this machine · low · reversible`,
`✉ leaves camy · high · not undoable`), and how long ago it arrived.
Repeats of the same question collapse into one row with a count and a date
range, and the list ends in the verbs that apply to its rows.
With nothing pending it prints "no approvals waiting — the leash is slack"
and exits 0.

The list also shows other decisions waiting on you that are not
checkpoints, such as a card or an agent run asking to go ahead. They sit
under NEEDS AN ANSWER with `—` where the id would be, because `show`,
`approve`, `deny`, and `answer` act only on checkpoints.

`--web` opens For You at camy.ai, where approvals wait, in your browser
instead of printing the list.

[`camy approvals show`](reference/camy_approvals_show.md) prints the
checkpoint in full — the complete prompt, not the truncated summary from the
list — so you can read exactly what you'd be approving. Read a checkpoint
you don't recognize with `show` rather than deciding from the list line
alone.

## Deciding

```bash
camy approvals approve a1b2c3d4
camy approvals deny a1b2c3d4
camy approvals answer a1b2c3d4 use the staging database
```

[`approve`](reference/camy_approvals_approve.md),
[`deny`](reference/camy_approvals_deny.md), and
[`show`](reference/camy_approvals_show.md) take one or more ids:

```bash
camy approvals approve ap_789a ap_2c40
```

Each id is tried in turn, and one that fails doesn't stop the rest; the
command then exits on the worst code any of them produced.
[`answer`](reference/camy_approvals_answer.md) takes exactly one id plus one
or more words of free text, joined with spaces and sent as the answer.

There is no flag for picking a numbered choice or filling structured form
fields from the command line; that richer interaction happens only in the
live [approval card](#the-approval-card). Answering a choice checkpoint with
`camy approvals answer ID 2` sends the literal text `"2"`, not a pick of
option 2.

`approve`, `deny`, and `answer` exit 1 with camy.ai's reason, and print no
success line, when camy.ai turns the response down: an answer that didn't
take, or a write that didn't run. When the response was recorded but the
paused turn couldn't be restarted, the success line stands and a warning
follows it on stderr.

`camy approvals deny` always exits 0 on success: it succeeded at telling the
agent no. Exit code 8 (checkpoint denied) is a different signal — within the
approvals surface it comes only from a live turn whose own interactive
prompt was answered no. See [Exit codes](exit-codes.md) for every command
that can return 8.

## Streaming with `--wait`

`approve` and `answer` both take `--wait`:

```bash
camy approvals approve a1b2c3d4 --wait
camy approvals answer a1b2c3d4 "use option B" --wait --chat 9f8e7d6c
```

It stays attached after responding and streams the resumed turn to your
terminal, instead of just confirming the checkpoint was cleared. `--wait`
follows one turn, so `approve --wait` takes a single id; naming several is a
usage error (exit 2).

`--wait` attaches to the chat named by `--chat ID`, or, without it, to the
last chat you were in on this profile. It does not read the chat id off the
checkpoint, so pass `--chat` when the checkpoint belongs to some other chat.
With neither available, it prints a note and exits 0 without streaming
anything.

Attaching takes a moment. The resume is spawned on the server
asynchronously, so the CLI waits up to 120 seconds before it trusts that the
turn is actually idle rather than just not-yet-resumed.

It then keeps waiting on a "paused" state, up to a total of ten minutes from
the approve — the turn may be waiting on a different checkpoint, possibly
one being decided in your other open session, and it says so once. Budget up
to about ten minutes worst case before `--wait` either finishes or gives up.

If the checkpoint's own outcome reaches a terminal state — completed,
failed, rejected, expired, cancelled — `--wait` reports it and exits
accordingly: 0 for completed, 1 otherwise. It only ever reports an outcome
it can tie back to the approval it's actually waiting on — a different
step's result landing on the same chat around the same time is never read
as this one finishing.

If the turn never resumes within that window, `--wait` exits 1. When it
never found any result it could tie to this approval, it says the turn did
not resume; when it saw one but couldn't tell whether it belonged to this
approval or some other step, it says that instead of guessing. Either way
the approval was not undone; only this CLI process gave up watching. Use
[`camy chats show ID`](reference/camy_chats_show.md) to see what actually
happened.

## The approval card

When a checkpoint pauses a chat you're watching live — in a terminal or the
full-screen app — it draws as a rounded card in the amber the CLI reserves for the leash.
The header row names what's being asked — `APPROVAL`, `QUESTION`, `CHOICE`,
or `FORM`, with the tool or action in plain words — and carries the
checkpoint's id at the right; a divider, the body, then labelled rows:
where the bite lands (`lane`), how bad (`risk`), where it came from
(`from`), and when it was asked. The question is never inside the frame:
it is its own line beneath the card, with its keys, and
`[y/N/o(pen web)]` is unchanged.

The body shows the summary, capped at a few lines, with a
"… +N more — o opens the full card" marker when it runs long. For a local
command it shows the verbatim command instead, wrapped but never
truncated, so nothing risky can hide past a cutoff. A command card can also
state how this machine confines commands, the same sentence
`camy --version` prints, but only once per connection: the first command
card you actually see may not carry it if an earlier one was answered for
you, so `camy --version` is the dependable place to read it. A local file
write shows the verbatim path the same way, then what the write would actually change:
when the file already exists, a diff against the copy on disk,
capped with an "o opens the full card" note if it runs long, or a line
saying the file already has these contents, or why no diff could be read.
When the file is new there's nothing to diff against, so the card shows its
line count and size instead. Whenever no diff is shown — a new file, or a
diff that couldn't be read — a preview of the proposed content follows.

A local edit, which changes part of an existing file, gets the same body:
the path, then the diff the edit would make against the copy on disk, under
the same cap. When that diff can't be computed, for example because a
search block no longer matches the file, the card says why where it can,
and shows the proposed search-and-replace blocks instead. A write or edit
to a file that runs on its own, such as a git hook, a CI workflow,
`package.json`, or a `Makefile`, carries a warning line under the path.

What answers it depends on the kind:

| Kind | Prompt | What counts |
|---|---|---|
| Approval | `approve? [y/N/o(pen web)]` | `y`/`yes` approves; `o` prints a link to the checkpoint's chat at camy.ai, or to For You when it has no chat (a clickable hyperlink where the terminal supports one), and asks again; anything else, including nothing typed, denies. |
| Approval, a local `run_command` card | `y run · N deny · a always · o web` | as above, plus `a` — see below. |
| Approval, a connector write | `approve? [y/N/a(lways for this tool)/o(pen web)]` | as above, plus `a`: it approves and tells Camy to stop asking before that tool runs in that connection, which you can undo in Connections. A destructive tool's card doesn't offer `a`, and a typed `a` there denies. |
| Question | `answer (empty rejects):` | anything typed answers; nothing typed rejects. |
| Choice | `pick (1 or 1,3) or type — empty rejects:` | a number or comma-separated numbers picks by position; anything else is sent as free text; nothing typed rejects. |
| Form | one prompt per field | a required field re-prompts if left blank; an optional field may be left blank. |

Prompts read `/dev/tty` directly, never stdin — piping input at a
[`camy chat`](reference/camy_chat.md) turn (`echo y | camy chat "..."`) can
never answer a checkpoint, by design. Every piece of server text shown on a
card — the summary, choice labels, field descriptions — is sanitized before
it reaches your terminal.

### `a` on a local command card

`a` approves the checkpoint and grants this exact command for this project,
and records a dated family grant beside it for commands of the same shape —
see [Trust](local-bridge.md#trust). It is offered only when the command
isn't destructive or content-unvetted. Where it isn't offered, `a` is not a
no-op:

- On a destructive command it denies the checkpoint outright.
- On a content-unvetted one — a script run through an interpreter — it
  approves this one run without granting anything.
- On a connector write it does what the connector row above says.
- On any other card that isn't a local `run_command`, it falls through to
  the same web-link-and-reprompt as `o`.

### The build-grant offer

Some cards carry an extra block: an offer for a standing build grant, a
single acceptance that would cover every further action in a class of
tools for the rest of the build, with no card for any of them. When a card
carries one, it lists exactly what's on offer:

- which actions the grant would cover, named tool by tool
- which read-only checks never need approval either way, grant or no grant
- that anything else — publishing, deploying, deleting a file, paying —
  still gets its own card regardless

Answering from the CLI never grants the standing authorization: `y` here
approves only the one action in front of you. The standing grant is offered
only on Camy's own approval card, in Camy's app or at camy.ai, not on any
card camy draws in your terminal.

## Headless behavior

Outside a real interactive session a checkpoint is never prompted: it's left
pending, and the command that hit it fails closed. That covers `--no-input`,
machine mode (`--json`/`--jq`/`--template`, even on a real TTY), and a
process with no controlling terminal.

```bash
camy --no-input chat "clean up the build directory"
```

That exits **4**, with the checkpoint id on stderr in human mode and in the
`checkpoint_id` field of the JSON error object in machine mode. This is not
a failure in the ordinary sense — it's the documented way a risky action
defers to a human. Clear it out of band:

```bash
camy approvals approve <checkpoint id>
```

Add `--wait` to see the full turn finish in the same process instead of just
clearing the checkpoint:

```bash
camy approvals approve <checkpoint id> --wait
```

A temporary chat (`--temp`) can never hold an approval at all. Hitting a
checkpoint there still exits 4, but with no checkpoint id, since a temp chat
has nothing for `camy approvals` to attach to later.

## Timeouts

Every checkpoint prompt — the single-line approval/question/choice line and
each form field — waits **120 seconds** on `/dev/tty`. A timeout is not a
decision: it leaves the checkpoint pending, never an implicit approve and
never an implicit deny. No flag turns this wait into an approval, and there
is none that approves everything automatically.

## Approved elsewhere

A checkpoint that pauses a local action — a command, file write, or file
edit on your machine — can only actually run on a machine that itself witnessed the
approval. That's true even when the checkpoint is cleared somewhere else:

- Approving or answering a local checkpoint with `camy approvals` and no
  `--wait` clears the checkpoint, but nothing executes in that one-shot
  process. It prints a note that the command runs in your other open camy
  session instead — the camy app, meaning `camy` with no arguments for the
  full-screen surface or `camy --inline` for the classic scrollback one —
  wherever that session's socket is still live. Add `--wait` to run it right
  there instead.
- An approval made from the web or from a different device works the same
  way: it clears the checkpoint, but a local command, write, or edit still
  needs a live camy session on the machine it targets.
- When the camy app picks the resumed turn back up, it shows the card again
  — "approved elsewhere · run it here?" — rather than executing silently.
  Only a session that itself witnessed a decision (a keystroke on a card, a
  trusted auto-run, a read-only command the CLI verified itself,
  `approve --wait`, or a live re-confirm like this one) is allowed to run a
  local command, write, or edit, so you confirm it once more, there.
- Any other session — the REPL,
  [`camy chat attach`](reference/camy_chat_attach.md), a one-shot
  `camy chat`, or anything headless — has no way to draw that
  re-confirmation, so it refuses the call outright and says so.

This is deliberate: a server telling a CLI process to execute something is
never enough on its own.

## `--json` output

### `camy approvals --json`

A JSON array, one object per pending checkpoint or other decision, with
repeats never collapsed. The shape is deliberately scrubbed — it drops the
server's internal replay data — and carries exactly these fields:

```json
{
  "checkpoint_id": "...",
  "family": "checkpoint",
  "subject_id": "...",
  "chat_id": "...",
  "kind": "approval",
  "tool_name": "local__run_command",
  "prompt": "...",
  "parameters": {"argv": ["npm", "test"], "cwd": "."},
  "status": "pending",
  "created_at": "2026-09-03T12:00:00Z",
  "expires_at": "2026-09-03T12:05:00Z"
}
```

`parameters` holds the checkpoint's tool arguments as camy.ai stores them.
For a local command that includes its `argv` and `cwd`; for other kinds,
such as connector writes, it is the checkpoint's own argument envelope. A
checkpoint's `family` is `"checkpoint"` and its `subject_id` is its
`checkpoint_id`. A row that is a different kind of decision carries its own
`family` and `subject_id`, an empty `checkpoint_id`, and null `chat_id`,
`tool_name`, `parameters`, `status` and `created_at`; `kind`, `prompt` and
`expires_at` are filled from the decision. The checkpoint verbs can't act on
it, so filter on `family` before piping `checkpoint_id` into `approve`.

### `camy approvals show ID --json`

The full, unfiltered server row for that one checkpoint. It is not the same
shape as the list; don't assume the two match field for field.

### `approve` / `deny` / `answer --json` (without `--wait`)

```bash
camy approvals approve a1b2c3d4 --json
```

```json
{"ok": true, "checkpoint_id": "a1b2c3d4...", "action": "approve", "runs_locally": true}
```

`deny` omits `runs_locally` — there's nothing to run — and reports
`"action": "reject"`, the wire word for a denial, not `deny`. `runs_locally`
is true only for a local (`local__`) checkpoint: it is the field a script
checks to decide whether it also needs `--wait`, or a run on the machine
that holds the session, to see the command actually execute. The object
also carries `resume_state` and camy.ai's `message` whenever camy.ai reports
one: `"pending"` when the turn is resuming, `"unconfirmed"` when the
response was recorded but the turn couldn't be restarted. Only
`"unconfirmed"` prints the warning on stderr in human mode.

With two or more ids, `approve`, `deny`, and `show` print an array instead,
one object per id, each with the `ref` you typed, the full `id` when it
resolved, `ok`, and `error` when that id failed.

### `--wait --json`

With `--wait`, the resumed turn streams as NDJSON, in the same event shapes
any `camy chat` / `camy chat attach --json` stream uses. When the turn
streams here, that stream is the whole output.

If instead the CLI finds the chat idle and the checkpoint resolved somewhere
else, it prints one extra object, on a single line so the whole output stays
NDJSON, and stops. A completed checkpoint prints this — `ran_elsewhere` is
always true on this path:

```json
{"type": "done", "chat_id": "...", "checkpoint_id": "a1b2c3d4...", "ran_elsewhere": true}
```

Any other terminal outcome prints this instead:

```json
{"type": "error", "code": "checkpoint_rejected", "chat_id": "...", "checkpoint_id": "a1b2c3d4...", "message": "..."}
```

`code` is `checkpoint_` followed by the outcome: `failed`, `rejected`,
`expired`, or `cancelled`. `checkpoint_uncorrelated` is a fifth code in the
same object shape, but it isn't an outcome — it means `--wait` gave up
without ever being able to tell which result, if any, was this approval's.

## See also

- [The local bridge](local-bridge.md) — what a local
  `run_command`/`write_file`/`edit_file` checkpoint actually authorizes, trust grants, and the destructive floor
- [Exit codes](exit-codes.md) — the full frozen table, including 4 and 8
- [Chat](chat.md) — where a live checkpoint card is drawn mid-turn
- [Scripting with camy](scripting.md) — the stdout/stderr and `--json`
  contract this document assumes
