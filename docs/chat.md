# Chat

Talk to the agent one message at a time, or keep a session open.

```bash
camy chat "what needs me before noon?"
camy
```

`camy chat` sends one message and streams back everything that happens in
response: the reply, every tool call, and any approval card the agent needs
you to answer. The bare `camy` command, with no arguments, opens a
persistent full-screen app instead — the same agent, kept open across many
turns.

This page covers both surfaces, plus `camy chats` for browsing and
searching past sessions, `camy calls` for searching your call history,
`camy mode` for choosing how deep the agent thinks, `camy crisis` for the
crisis lines in your country, and the project-instructions and
inline-image behavior that only show up while you're chatting.

## One-shot chat

```bash
camy chat "what needs me before noon?"
```

camy sends the message as a new turn and streams the reply to stdout as it
arrives. Tool calls the agent makes along the way — reading a file, running
a command — are traced to stderr as they happen, never printed as part of
the reply. If a tool call needs your approval before it can run, camy shows
an approval card, headed with the action in words
(`APPROVAL — send an email`) rather than the tool's internal name; see
[Approvals](approvals.md) for how those work and what happens when nothing
is there to answer them.

Each trace closes on its own line with what came back — `✓ 4 emails · 0.6s`, `✗ exit 1 · 0.4s`, `! awaiting approval`, or `! waiting for your answer` when the agent has asked you a question — so a turn reads as a ledger of what ran and what it found.

A tool call on your computer names what it worked on: the file it read,
the pattern it searched for, or the command it ran. One that failed says
why (`failed: <reason>`).

An action you approved closes on what really happened: `✗ failed` when it
didn't run and `✗ exit N` when its command failed, never a ✓. When camy.ai
sends the last lines of the command's output, up to 12 of them print
beneath the trace.

If an action you approved for your computer never starts, for example
because no computer of yours is connected, the turn still ends: camy
prints camy.ai's reply about it. If no word comes at all, camy stops
waiting 65 minutes after the approval with
`running on your machine — the result will land here`.

Your answer to a card counts once camy.ai takes it. If the card was already
settled somewhere else, say approved on the web a moment before you typed
`n`, camy prints camy.ai's account of what happened and the turn keeps
streaming instead of ending on an error.

Your answer also counts only for the version of the request the card
showed you. If the request was edited somewhere else after the card was
drawn, your answer runs nothing and the card keeps waiting: camy prints
camy.ai's reason and exits 4, with `camy approvals show <id>` as the hint.

Other things the web shows along the way get one line each on stderr: a
turn waiting for a free slot
(`queued — 2 of 2 turns already running; this one starts when one finishes`),
a reply the safety check flagged, earlier messages summarized to make room,
a Camy computer working on the turn (with a link to watch it live), and a
card that expired before anyone answered
(`… expired before anyone answered — nothing ran`). The agent's routine
progress notes show only with `--verbose`.

Before the reply, camy prints this line on stderr (but never under
`--json`, `--jq` or `--template`). `-q` doesn't hide it.

```text
Camy is an AI, not a person. It can make mistakes.
```

When camy.ai sends a reminder during a chat,
`· Reminder: Camy is an AI, not a person.` prints above a reply, or
`· Camy is an AI, not a person.` under one. `-q` doesn't hide these lines.

When camy.ai corrects a reply after streaming it, for example to add a
note at the end, camy prints only what changed, never the reply a second
time. Text that has already reached your screen or a pipe stays as it was
drawn, and the chat's history holds the corrected reply.

**stdout is the reply, stderr is everything else.** The reply text (or, in
JSON mode, the NDJSON event stream — see
[below](#machine-output---json-and-ndjson)) is the only thing camy writes to
stdout. The wordmark, tool traces, spinners, and approval cards all go to
stderr, so a pipeline that only wants the reply can just take stdout:

```bash
git diff | camy chat "review this"
camy chat --json "give me the numbers" | jq -r 'select(.type=="final") | .text'
```

Piped, or in accessible mode, a card inside a reply prints as plain lines:
its data fields (such as an email's `to:` and subject) and its text,
without its icon, layout, or suggestion lines.

### The bare-message shorthand

```bash
camy "what's on my plate today?"
```

A plain quoted message typed at the bare `camy` prompt, without a
recognized subcommand in front of it, is shorthand for `camy chat`. The
rewrite only fires for a single argument that contains a space, typed at an
interactive terminal (camy checks that both stdin and stderr are TTYs),
whose first word isn't a known command.

A single bare word like `camy hello` is not rewritten and fails as an
unknown command. The rewrite never fires for piped input or inside a
script, so scripts always have to name `chat` explicitly.

Passing no message at all, with nothing piped in, is an error — there's
nothing to send:

```bash
camy chat
# exit 2: nothing to say
```

Quote a message, or pipe something in instead.

### After the turn

When the turn ends, camy exits with a code describing how it ended:

| Exit code | Meaning |
|---|---|
| 0 | The turn completed normally. |
| 1 | A runtime failure — an error in the turn itself, a dropped connection, or the turn was stopped or detached after Ctrl-C. |
| 2 | Any usage error before the message is sent. Examples: nothing to say, an unknown `--tier`, `--temp` with `-c`/`--chat`, an `--attach` file that can't be read, is a folder, or is over 50MB, a `--chat` id that is too short, ambiguous, or matches none of your chats, or a message too large to send (see [stdin as context](#stdin-as-context)). Also the code while your account still needs your month and year of birth: camy says so and links the camy.ai page where you answer. |
| 3 | camy.ai refused your key, including a key that lacks the `chat:read` scope chat needs (the hint says how to sign in with it), and an account that has been closed because Camy is only for adults (camy links the page where you can ask for age verification). When the refusal is ambiguous, camy checks the key once more first, and a key that still works ends on 7 instead. |
| 4 | A checkpoint needed approval and camy couldn't prompt for it (headless, `--no-input`, no controlling terminal, or `--json`) — or you pressed Ctrl-C while a prompt was open, or the request you answered had been edited somewhere else since its card was drawn. See [Approvals](approvals.md). |
| 5 | Any rate limit: sending messages too fast, too many connections for your account or from your network, too many turns at once, or a rate-limited request before the turn starts (creating the chat, uploading an attachment). Each comes with a hint on when to try again. |
| 6 | The turn ended on a plan or credit limit, including a turn held until you add credits (see [below](#an-interrupted-turn-offered-back)). |
| 7 | camy.ai was unavailable: its chat service was down, it was restarting and camy's resend gave up, or it couldn't check your key just then. |
| 8 | An approval was rejected and nothing happened after it — a turn the agent kept going after a rejection and still produced something does not exit 8. |
| 131 | You pressed `Ctrl-\` (SIGQUIT). |

The full, command-independent table lives in [Exit codes](exit-codes.md).

In a human terminal, a completed turn ends in a quiet trailer on stderr —
the tier the turn ran on, how long the turn took, the chat id — and a line
of commands that continue it (`camy chat -c`, `camy chats show <id>`). The
tier reads `quick` or `agent`, or the two joined by an arrow, such as
`quick → agent`, when camy.ai ran the turn on a different tier from the
one it asked for. When camy.ai doesn't report the tier that ran, the
trailer shows the tier the turn started with, and `agent` when there is
none. If the turn approved something that
ran, the line of commands leads with `undo any of it: camy chats show <id>`,
so you know where to look to undo it. A `--temp` turn prints none of
this — there is nothing to show or continue.

When a turn stops on an approval camy can't prompt for, there is no
trailer. camy exits 4 and prints the checkpoint id, with
`camy approvals approve <id>` as the hint. A `--temp` chat can't hold an
approval, so it exits 4 without an id.

Press Ctrl-C while a reply streams and camy gives you two seconds to press
it again. A second Ctrl-C stops the turn, along with any command it is
running on your computer, whose result still goes to camy.ai so the turn
isn't left waiting on it; otherwise camy lets go of the turn and leaves it
running on camy.ai. For a saved chat, `camy chat attach`
can rejoin a turn you let go of. A `--temp` turn you let go of keeps
running on camy.ai too, but nothing can rejoin it, so press Ctrl-C twice to
stop it. Either way camy exits 1.

A turn stopped from somewhere else, such as the web's stop button or
another device, keeps whatever reply had already streamed, prints
`stopped` on stderr, followed by the usual trailer at a terminal, and
exits 0. Exit 1 is only for a stop or detach you trigger with Ctrl-C. In
`--json` mode, check the `done` event's `"stopped": true`, not the exit
code.

Full flag reference: [camy chat](reference/camy_chat.md).

## Continuing, targeting, and temporary chats

A plain `camy chat` starts a new chat every time. Three flags change that.

```bash
camy chat -c "and the second one?"
```

`-c`/`--continue` resumes the last chat you used on this profile. If there
isn't one yet, camy says so and starts fresh instead.

```bash
camy chat --chat 2f1c9ab3 "keep going on that one"
```

`--chat` targets a specific chat by id. The short id `camy chats` prints
(`ch_2f1c`), or a prefix of the full id, resolves the same way it does
everywhere in camy: under 4 characters is refused outright, and a prefix
matching more than one chat is a usage error rather than a guess. Archived
chats resolve too, so an id `camy chats search` prints for one works here.
A short id or prefix that matches none of your chats fails at once with
`no chat matches <id>` (exit 2). An id you give `--chat` becomes the chat
`-c` continues only once camy.ai starts the turn on it, so a mistyped one
never breaks `-c`.

```bash
camy chat --temp "just testing something, don't save this"
```

`--temp` starts a temporary chat: it isn't saved to your history or
memory, it never appears in `camy chats`, and it can't be resumed with
`-c` or `--chat`. It is mutually exclusive with both of them. It never uploads a
file on its own either: only one you name with `--attach` goes up. Its
second Ctrl-C stops the turn like any other chat's. A `--temp` turn you let
go of after one Ctrl-C keeps running on camy.ai, but nothing can rejoin it,
so press Ctrl-C twice to stop it.

When camy.ai keeps a copy of temporary chats for safety, a `--temp` turn
at a terminal says so on stderr before it starts:

```text
Temporary chat: not saved to your history or memory. For safety, we keep messages for 30 days. camy.ai/privacy#temporary-chats
```

The line never prints under `--json`, `--jq`, `--template` or
`--no-input`, or when stderr isn't a terminal. Once a `--temp` turn on
your profile has seen that copy kept, the `--temp` line in
`camy chat --help` also says an encrypted copy is kept 30 days for safety.

A temporary chat also can't hold an approval. If a tool call in a `--temp`
turn needs your sign-off and camy can't prompt for it right then, the turn
fails outright instead of leaving a pending checkpoint with nowhere to
attach to later.

### stdin as context

```bash
git diff | camy chat "review this"
```

If stdin isn't a real terminal — that is, something is piped in — camy
reads up to 2MB from it and folds it into the turn as context. If you also
gave a message, the piped content is appended after it, separated from your
words; if you didn't, the piped content becomes the whole message.

Either way, stdout stays reserved for the reply, and the piped block is
never echoed back: with a typed message the chrome echoes just your
message, and a bare pipe with no message shows `(piped input)` instead.

A pipe that stays silent never holds a chat up. A pipe is read only if
something arrives on it within 200 ms, or within two seconds when the pipe
is the whole message (`git diff | camy chat`); otherwise camy treats it as
empty and goes on. So a script that runs `camy chat "…"` with an open,
silent stdin doesn't hang. A file redirected in (`< notes.txt`), or a pipe
once data arrives, is read up to the 2MB cap, and camy waits for the pipe
to close (or for 2MB) before it sends.

Input that runs past 2MB is cut after the last whole line that fits, and
the `stdin ·` note camy prints on stderr says so: it ends
`· cut to the first 2 MB of <size>` for a redirected file, or
`· cut to the first 2 MB` for a pipe. The note never prints under `--json`
or `-q`, and the message itself doesn't mention the cut.

camy.ai takes a message of a little under 64 KB once it's encoded for
sending. camy measures the encoded message, not the raw text. When a piped
block pushes the message past that, camy uploads the block as an attachment named
`stdin.txt` and sends your typed words with it (a bare pipe sends the
attachment alone), and says so on stderr:

```text
· stdin is over 64 KB — attached as stdin.txt (310.4 KB)
```

A `--temp` chat never uploads on its own, so there a piped block that large
is a usage error (exit 2): trim it, or `--attach` a file to send it
explicitly. A message you typed that is itself too long is a usage error
too, before the message is sent: save it to a file and send it with
`--attach`.

For text that might start with a dash or otherwise look like a flag, `--`
marks the end of flags so the rest is passed through literally — the
unambiguous form for scripts handling untrusted text:

```bash
camy chat -- "$UNTRUSTED"
```

## Attachments

`--attach` uploads a local file and sends it along with the message —
repeat the flag to attach more than one:

```bash
camy chat --attach report.pdf --attach chart.png "summarize these"
```

Each file is uploaded before the turn starts, up to 50MB each. camy doesn't
check the file's type on your end, only that it can be opened, that it
isn't a folder or over 50MB, and that the upload comes back with an id —
what the agent can actually do with the content is up to the server. In
practice that means images, PDFs, audio, video, text files (plain,
Markdown, CSV), JSON, XML and RTF, and Office documents, whose text the
agent reads.

An unreadable path or a folder stops the send before any chat is created
(`can't read <path>: <reason>`, exit 2), and so does a file over 50MB
(`<path>: File too large. Maximum size: 50MB`, exit 2). A pipe, such as
`--attach <(cmd)`, or a device has no size to check up front: camy stops
reading it at 50MB with the same sentence and exit 2, and sends nothing of
it. A failed upload stops the send before any turn is created, so a message
never goes out silently missing what you meant to attach. If camy.ai then
takes fewer files than were sent, camy says so on stderr
(`1 of 2 attachments didn't reach the agent — an expired or unknown upload`),
or with a `warning` event under `--json`.

This is a different "attach" from
[`camy chat attach`](#reattaching-to-a-paused-turn): this one attaches a
*file* to an outgoing message; that one re-attaches your *terminal* to a
turn already in progress. There's no equivalent inside the full-screen
app's composer — attaching a file is a one-shot `camy chat --attach`
operation only.

### Files the agent gives back

When a turn produces a file — a generated image, an exported document —
camy prints a 📎 receipt with an attachment id. Fetch it with:

```bash
camy download <attachment-id>
camy download <attachment-id> -o report.pdf
```

By default the file lands under the server's own filename in your current
directory; `-o` picks a different destination. camy refuses to write
through an existing symlink at the destination — even with `--force` — and
refuses to overwrite an ordinary existing file unless you pass `--force`.

The file is saved readable only by you, and it lands at the destination
only once all of it has arrived and checked out, so a download that fails
or is interrupted leaves an existing file as it was, with or without
`--force`.

If the terminal supports inline images (see [below](#inline-images)) and
the downloaded file is 8MB or smaller and looks like an image, it renders
right after the confirmation line.

Full flag reference: [camy download](reference/camy_download.md).

## Reattaching to a paused turn

```bash
camy chat attach
camy chat attach --chat 2f1c9ab3
```

If a turn is paused on an approval, or was left running in the background,
`camy chat attach` rejoins it: it re-dials, catches you up on whatever
streamed while you were away, and picks up the fail-closed → approve →
collect loop where it left off — including if the approval was answered
somewhere else (another terminal, the web, or
[`camy approvals approve`](reference/camy_approvals_approve.md)).

With no `--chat`, it rejoins your last chat on this profile. `--turn` names
the turn id you expect, the chat's live turn is what actually gets
attached, and camy says so on stderr when the live turn isn't the one you
named, rather than silently attaching a different one.

If nothing is running, the turn you came back for has usually just
finished, so `camy chat attach` prints the chat's latest reply, read back
from the transcript, under `nothing running — the chat's latest reply`
and how long ago it was sent. Under `--json` it arrives as a `last_reply`
event. When the chat's newest message has no reply yet, it says
`nothing running — this chat is idle`.

Right after an approval is answered, `camy chat attach` follows the turn
the answer resumed and ends with that turn's reply once it finishes, also
when the reply was stored on camy.ai without streaming to you. If the turn
is still resuming after a while, it says
`still resuming — camy chat attach --chat <id> picks it up`.

You rarely need `attach` for a blip. If camy has to reconnect while a reply
is streaming (in any chat but a `--temp` one), it catches up on the turn and
prints only the part of the reply you missed, once. In a terminal, when it
can't line the two up, it says so instead of guessing:
`the connection dropped and came back — some of this reply may be missing here; camy chats show <id> has all of it`.
In the full-screen app and the accessible REPL the note points at the
chat's history instead (`the chat's history has all of it`). Under `--json`
camy emits no event for the gap, so the `token` text may be missing a
piece.

Full flag reference: [camy chat attach](reference/camy_chat_attach.md).

## An interrupted turn, offered back

camy.ai can hold a turn in this chat, either one that broke partway
through or one it paused at a limit, including the turn you just sent. camy
offers it back once the current turn is over, never in the middle of a
reply. The offer is drawn as an approval-style card headed
`INTERRUPTED`: what you originally asked, the step it stopped on, and how
long the hold has left (`held 28 minutes`), each shown only when the server
says so. The step it stopped on is shown only when no step is unsure.

```text
resume? [y/N]
```

Answer `y` to resume it: the resumed turn streams to its end like any
other. When camy.ai won't resume it because the chat is already running
a turn, or because the hold is gone or replaced, camy says so
(`not resumed — this chat is already running a turn`,
`not resumed — there's nothing left to resume`). Otherwise the card
simply ends. A card answers only for the held turn it was drawn for,
and an offer camy.ai withdraws before the current turn ends (a newer hold
replaced it, or another device answered it) is never drawn. In
`camy chat` and the accessible REPL, any line other than `y`,
`yes`, `r` or `resume` (or `f`/`fresh` on an unsure card), including an
empty Enter, leaves it held and sends nothing. So does waiting 120
seconds. In the full-screen app, Esc on the card leaves it held too.

If the outcome of a step is unknown, the heading says so
(`INTERRUPTED — one step unsure`), the card lists `unsure <tool>` for each
such step, and the question becomes `[resume/fresh]`: `resume` picks the
turn back up with the unsure step skipped, `fresh` clears the hold, and
Enter keeps it held.

Not every held turn broke. The heading reads `PAUSED — …` only for a
limit: `PAUSED — reached its cost ceiling` for a turn that hit its own cost
ceiling, `PAUSED — reached a limit` for any other limit, with the same
question. A crash keeps `INTERRUPTED`. A turn held because your account
ran out of credits is different, since resuming would run into the same wall: camy
asks nothing and draws a `NOT ENOUGH CREDITS` card with what you asked, how
long it's held, and `add credits, then say continue`, pointing at
`camy.ai/p/plan`. `camy chat` then exits 6.

This happens in `camy chat`, the full-screen app, and the accessible REPL.
Headless and `--no-input` turns are never asked, and in `--json` mode the
offer arrives as a `resume_offer` event (`chat_id`, `unsure`, `held_until`
when the hold's end is known, and `stop_reason` and `ceiling_axis` when
camy.ai says why it held the turn) instead of a question.

## Crisis lines

```bash
camy crisis
```

`camy crisis` lists the crisis lines for your country: a
`Crisis resources` heading, with your country's name when camy knows it,
then one row per line with how to reach it, and a closing note. It needs
no sign-in. For an account in the United States it prints lines like
these:

```text
  Crisis resources · United States

  Suicide and Crisis Lifeline     call or text 988
  Crisis Text Line                text HOME to 741741
  Emergency services              call 911
  Find a helpline                 https://findahelpline.com

  Camy can’t call or text these lines for you.
```

A line whose call and text numbers differ gets a row for each.

If the lines for your country can't be loaded, it says so and prints the
US lines and a worldwide helpline finder (`https://findahelpline.com`)
instead, and still exits 0. Under `--json` it prints an object with
`country`, `resources` (the lines) and `bundled`, which is `true` when
those are the built-in US lines.

When camy.ai includes crisis lines with a reply, camy prints them after
the reply, on stderr (in the full-screen app, in the transcript): a short
heading such as `If you want to talk to someone`, the lines exactly as
camy.ai sent them, and the same closing note. With no lines in it, the
block reads `` Crisis resources: run `camy crisis` ``. `-q` doesn't hide
it. Under `--json`, the `done` event carries camy.ai's crisis block
unchanged as `care`, with the lines in `care.resources`.

Full flag reference: [camy crisis](reference/camy_crisis.md).

## Past chats: list, search, show, export

```bash
camy chats
camy chats list --all
camy chats search "invoice"
camy chats show 2f1c9ab3
camy chats export 2f1c9ab3 > transcript.md
camy chats prune
```

`prune` deletes the sessions that never got a message; the current chat and
agent chats are kept.

`camy chats` (or `camy chats list`) lists your sessions newest first, 25 at
a time by default. `-L 50` changes the page size and `--all` shows
everything, on `camy chats` and `camy chats list` alike. Archived chats
stay out of the list, but `camy chats search` finds them, and their short
ids resolve anywhere a chat id is taken.

Under `--json` the list holds every chat unless you pass `-L`, which keeps
the newest N. Before 1.0.6, `-L` was ignored under `--json`; a script that
passes it and expects every chat should drop it.

`camy chats show ID` renders a transcript through the same markdown
pipeline live chat uses. `camy chats export ID` writes a portable markdown
transcript to stdout — markdown is the only export format today. Both
accept a short id prefix the same way `--chat` does, and both hide the
internal checkpoint-response bookkeeping a raw transcript would otherwise
clutter the reading with.

### Searching past chats

```bash
camy chats search "invoice"
camy chats search "invoice" --chat ch_0a4f
camy chats search invoice march -L 50
camy chats search invoice --offset 25
```

`camy chats search` finds messages across every chat you have, archived
ones included. Every word after `search` is part of the query, so quotes
are optional.

The first line counts the hits on this page (`3 matches in 2 chats`).
Raise `-L` (up to 100), or page on with `--offset`, to see more. Hits are
grouped under their chat in the order the server ranked them: each group
opens with the chat's short id and title (with `- archived` after it for
an archived chat), then one row per matching message — `you` or `camy`, a
short excerpt around the first word you searched for, and how long ago it
was said. When a chat has more matches than the page shows, an
`N more in this chat` line says what the page left out. The last line
points at `camy chats show` and
`camy chat --chat` for the first chat. The checkpoint bookkeeping that
`chats show` hides never appears as a hit.

- `--chat ID` searches one conversation. It takes a short id the same way
  `camy chat --chat` does.
- `-L`/`--limit` sets the page size: 1 to 100, 25 by default, best
  matches first.
- `--offset N` skips the first N matches, so `--offset 25` is the second
  page of 25.
- The query is capped at 100 characters. An empty query, a longer one, a
  `-L` outside 1 to 100, or a negative `--offset` is a usage error (exit 2)
  before anything is sent.

When a page comes back full, a line under it says more may match and names
the next page's flag
(`more may match than this page shows — --offset 25 for the next page`).
With no hits it prints `nothing matched "invoice"`; an empty page past the
first says `no more matches for "invoice" past offset 25` instead. If the
server ranked only the newest 500 matches, a line under the results says
older ones may be missing, so a cut-short list never reads as complete.
Search is capped at 30 requests a minute; past that the command exits 5
(rate limited).

Under `--json` you get the server's whole response object rather than a
bare array, including `candidates_truncated`, which says whether older
matches were left out of the ranking.

Full flag reference: [camy chats](reference/camy_chats.md),
[camy chats list](reference/camy_chats_list.md),
[camy chats search](reference/camy_chats_search.md),
[camy chats show](reference/camy_chats_show.md),
[camy chats export](reference/camy_chats_export.md).

## Your call history

```bash
camy calls search "the plumber"
camy calls search "invoice" --filter need_you
```

`camy calls` holds your call history, and its one verb, `search`, finds a
call by what was said on it. `camy calls` on its own prints its help.

The first line counts the hits (`4 calls matched`). Each call then shows
the caller (the name when there is one, otherwise the number, otherwise
`Unknown caller`), the group it was sorted into, and how long ago it came
in, with a line of the transcript underneath and the words that matched in
bold — or the call's summary when there is no matching excerpt.

- `--filter` narrows the search to one group: `all`, `need_you`,
  `messages`, `handled`, or `spam`. Anything else is a usage error
  (exit 2), checked before the search is sent.
- `-L`/`--limit` sets the page size: 1 to 200, 25 by default, most recent
  first.
- The query is capped at 200 characters.

With no hits it prints `no call matched "the plumber"`. When your
transcripts are cleared after a set number of days, a second line says so:
older calls then match by caller only. If more calls matched than the
search could scan, a line says older ones may be missing. Like chat
search, call search is capped at 30 requests a minute (exit 5 past it).

If searching calls isn't available on your account, the command prints
`Searching your calls isn't on for your account yet.` and exits 7
(unavailable). Before 1.0.6 it exited 1; a script that checks for 1 there
should check for 7.

Under `--json` you get the server's response object untouched; the words
that matched in each snippet stay wrapped in `[[` and `]]`.

Full flag reference: [camy calls](reference/camy_calls.md),
[camy calls search](reference/camy_calls_search.md).

## The full-screen app

Run [`camy`](reference/camy.md) with no arguments at a real terminal and,
unless you've asked for something more linear (see below), you get the
full-screen app: a persistent session that stays open across many turns
instead of exiting after one. It keeps one connection alive for as long as
you leave it running, so an approval answered from another terminal or the
web while you're idle still shows up here without you having to reconnect.
If that connection drops, the app heals it in place, and the dot at the end
of the key bar says whether it's live. If a message can't go out because
camy.ai can't be reached, the app says
`not sent — camy.ai can't be reached; ↑ brings your message back`, and ↑
recalls it. Once camy.ai refuses your key, the app stops trying: the dot
stays dead, and the next message you send shows the sign-in error. A key
that lacks a scope chat needs is refused the same way: the app says so
once (`this key lacks a required scope — quit, then camy auth login`)
instead of reconnecting over and over.

When the app picks up the chat you used last, it prints that chat's last
exchange under `picking up where you left off`.

Replies render through the same markdown pipeline as `camy chats show` —
headings, code blocks, and emphasis draw as formatted text, not raw
markdown source.

### The screen

A masthead is pinned at the top: the mode, the chat, and how many things
are waiting on you, with the local scope and the profile on the right. It
stays on screen when you scroll up. The transcript scrolls between, and is
laid out again when you resize the window: lines and tables wrap to the
new width instead of being cut off, a URL or path too long for one line
continues on the next and stays one link, and a code line keeps its
indentation. At the bottom, directly above your input, sits
the status row — what the turn is doing and for how long while it runs, the
waiting card while one is up, a picker's count while one is open — then the
hairline, the composer, a one-line hint, and a key bar drawn from the same
table the keys come from, with a dot at its end that says whether the
connection is live. `?` (or F1) on an empty composer opens a help overlay
of those keys and every slash command.

### Composing

- Enter submits — or, while a turn is still generating, queues the message
  and sends it as soon as the turn ends.
- Alt+Enter inserts a newline without submitting, for a multi-line message.
  Each line of the draft gets the full width, and a line that runs past
  the edge scrolls to keep the cursor in view, with `…` marking the hidden
  side. An answer you type into a waiting card scrolls the same way.
- Pasting text arrives as one block; line breaks inside a paste become
  literal newlines in the message instead of each one submitting early.
- Ctrl+R opens a reverse-search over your input history; type to filter,
  Ctrl+R again walks to older matches, Enter takes the match, Esc closes
  the search.

### Slash commands

| Command | Does |
|---|---|
| `/approvals` | Opens a picker over pending checkpoints — the leash, inline. Type to filter by words or by id. Space marks rows; `a` first shows what each marked approval will do, then a single `y` approves exactly those (any other key goes back to the list with the marks kept); `d` denies every marked row at once. |
| `/inbox` | Shows the inbox list, read-only, inline. |
| `/status` | The right-now status pane. |
| `/compact` | Summarizes older context on demand, and says so when there's nothing to compact. |
| `/mode [agent\|quick]` | Shows or sets how deep the agent thinks — see [below](#mode-agent-or-quick). |
| `/jobs` | What's scheduled and when it next fires. |
| `/vm` | Your cloud workspace. |
| `/new` | Starts a fresh chat; the old one stays in `/chats`. |
| `/chats` | Opens a picker over your chats, with archived ones left out; `/chat ID` switches straight to one by its short id, archived or not. A short id is looked up in the background (`loading /chat…`), and a message you send meanwhile goes to that chat once the app has switched. |
| `/attach` | Rejoins this chat's turn if it is still running, or the card it is waiting on, as the line after a stop camy.ai didn't confirm suggests. With no chat open it asks `which chat?`. |
| `/plan` | The agent's checklist for this turn, as a pane; the status row counts it (`3 of 5 done · /plan`). |
| `/queue` | What is waiting to send when this turn ends. Enter steers the chosen message into the running turn now (`steered:`); it leaves the queue once the turn has taken it, or once the chat has saved it without this turn taking it in (`saved to the chat:`, never sent again), and otherwise goes next (`next:`). `d` drops it. A steered message the turn ended without using comes back to the top of `/queue` (`not used by that turn:`) and waits there: it never sends by itself, Enter sends it, and `d` drops it. |
| `/usage` | Your plan and credits — the same pane as `camy plan`. Credits never appear on the status row. |
| `/help` | Keys and commands (also `?` or F1). |
| `/<verb>` | Any read-only camy verb — `/feed`, `/tasks`, `/canvas`, `/doctor`, `/schedule`, `/ledger`, `/connectors` … — runs through the same renderer into the transcript; one that only groups other verbs, such as `/local`, `/runs` or `/calls`, prints its help there. A verb that changes things, such as `/capture`, doesn't run: the app names the `camy` command to run from a shell instead. |
| `/quit` | Leaves — anything scheduled keeps running. |

Esc stops any command the turn is running on this machine, asks the server
to stop the turn that's generating, and waits for the confirmation — Esc
again hands the composer back at once. A command the stop ends still sends
its result to camy.ai, so the turn isn't left waiting on it. When the stop
lands, the transcript says `stopped`. Once the composer is handed back,
the next message you send goes out as usual. The menu keeps working while
a turn runs. Two Ctrl-C's in quick succession leave the app, and so does
Ctrl-D on an empty composer.

### `--inline` and `--accessible`

Two flags change how the app draws without changing what it can do:

- `--inline` (or `CAMY_INLINE=1`) keeps the same app and the same slash
  commands, but renders into your terminal's native scrollback instead of
  taking over the screen with an alternate-screen, animated layout. It has
  no masthead: one line under the composer says where you are — the chat,
  the folder camy may touch, what is waiting, and `/help`. Its opening
  banner carries the same line that says Camy is an AI as a one-shot
  turn does (see [One-shot chat](#one-shot-chat)).
- `--accessible` (or `CAMY_ACCESSIBLE=1`, or a `TERM=dumb` terminal) skips
  the full-screen app entirely and drops you into a plain line-by-line
  REPL instead: no redraws, no spinners, no boxes. Its header carries the
  same line. Ctrl-C or Ctrl-D at its prompt leaves the way `/quit` does,
  with the goodbye line.

The REPL's slash set is a shorter one. It has no `/compact`, `/plan`,
`/queue`, `/usage`, `/<verb>` passthrough or `/chats show ID`, and adds
`/last`, which prints the current chat id, and `/resume`, another name for
`/attach`, which rejoins a detached or dropped turn:
`/new`, `/chat ID`, `/mode`, `/approvals`, `/inbox`, `/status`, `/jobs`,
`/vm`, `/chats`, `/last`, `/attach`, `/help`, and `/quit` (also `/exit` and `/q`, which
work in the full-screen app too). In the REPL, `/status`, `/inbox`,
`/jobs` and `/vm` print the one-shot output instead of a pane.

Each of those delegates to the same one-shot logic
[`camy approvals`](reference/camy_approvals.md),
[`camy inbox`](reference/camy_inbox.md),
[`camy status`](reference/camy_status.md), and friends already use, rather
than drawing an in-composer picker.

### Input history

Every line you type in either surface — including slash commands — is
appended to a per-profile input history file, so the full-screen app's ↑/↓
recall and Ctrl+R search pick up where the last session left off. The
accessible REPL writes to the same file but reads plain lines, with no
recall or search of its own.

The file is `history` in the per-profile state directory —
`~/.local/state/camy/<profile>/history`, or
`$XDG_STATE_HOME/camy/<profile>/history` when that variable is set (see
[Configuration](configuration.md)). It's created mode 0600, and camy
refuses to write through a symlink planted at that path.

## Mode: agent or quick

```bash
camy mode
camy mode agent
camy mode quick
```

`camy mode` reads or sets how deep the agent thinks for chats on this
profile: `agent` reasons with the full tool set, `quick` answers fast with
fewer tools. With no argument it prints the current setting on stdout
(`-q` doesn't hide it):

```text
mode: agent  — camy mode agent · camy mode quick
```

For a script, use `camy mode --jq .mode`, which prints the setting by
itself, or `camy mode --json`, which prints it as `mode` in a JSON object.
Don't use `$(camy mode)`, which captures the whole line.

With `agent` or `quick` it persists the choice. The full-screen app's and
the REPL's `/mode` slash command read and write the exact same persisted
setting.

`camy chat --tier agent|quick` overrides the persisted mode for one turn
only, without changing what's saved. Any other value is a usage error
(exit 2) before anything is sent; case and surrounding spaces don't matter.
The server may still choose
differently than what you asked for. The tier that actually ran is
reported back at the end of the turn: in the trailer (see
[After the turn](#after-the-turn)) and, in `--json` mode, as the `done`
event's `tier_effective`, beside `tier_requested` and `tier_reason`, when
camy.ai reports them. The `start` event's `tier` is the tier the turn
asked for, not proof of what ran, so a script checking a specific tier
should read `tier_effective` rather than assume the request was honored
as-is.

In machine mode (`--json`, `--jq`, or `--template`) the persisted mode is
deliberately not sent: a script that didn't ask for a tier gets the
server's own default. Pass `--tier` explicitly when a script needs a
specific one.

Full flag reference: [camy mode](reference/camy_mode.md).

## Project instructions from AGENTS.md and CLAUDE.md

When a chat runs with the [local bridge](local-bridge.md) live against your
project — not against the cloud workspace — camy looks for an `AGENTS.md`
file at the project root and, if that's not there, a `CLAUDE.md`, and sends
its contents along as project instructions for the turn, together with your
own `~/.camy/AGENTS.md` when you keep one. The content is sent to the server
as data for the turn, not as instructions the model blindly follows; see
[Project instructions](local-bridge.md#project-instructions) for how the two
files combine.

Only a plain regular file qualifies. A symlink or a hard link at that path
is refused outright, even one pointing at an ordinary file inside the
project, since either could smuggle in content the project's own visible
files never held. The file is capped at 16KB and whitespace-trimmed; an
empty result after trimming counts as no file at all.

The instructions travel in the opening message camy sends when it
connects, together with a short listing of the folder, and camy.ai takes
an opening message of up to 64 KB. When the folder's context would push it
past that, camy leaves out the listing first, then the end of the
instructions, then the folder's context altogether, so the chat still
connects.

The first time a session actually reads one, camy prints a one-line notice
to stderr naming the file and how to opt out. It never happens again for
the rest of that process, and the file's contents are never echoed, only
the fact that one was read. Skip the discovery entirely with
`--no-project-instructions` or `CAMY_NO_PROJECT_INSTRUCTIONS=1`.

## Inline images

On a terminal that supports it, a file you fetch with `camy download`
renders inline right after the confirmation line instead of just leaving a
file on disk. In a one-shot `camy chat`, the last image a turn generated is
fetched from camy's own CDN and drawn under the reply, up to 8MB.

| Where | What draws |
|---|---|
| iTerm2, WezTerm, kitty | The image, inline. |
| kitty, anything but a PNG | Nothing: kitty's protocol in this release only draws PNGs, even for formats that would work in iTerm2 or WezTerm. |
| The full-screen app and `--inline` | The image's link line only, never the picture. |
| `tmux` | Nothing, by design — a half-drawn escape sequence is worse than no image at all. |
| `--accessible`, `CAMY_ACCESSIBLE=1`, `TERM=dumb` | Nothing, everywhere: the accessible REPL and `camy download --accessible` only ever print the line. |
| `CAMY_NO_INLINE_IMAGES=1` | Nothing: the feature is off entirely. |

## Machine output: `--json` and NDJSON

```bash
camy chat --json "give me the numbers" | jq -r 'select(.type=="final") | .text'
```

With `--json` (or `--jq`/`--template`), `camy chat` streams
newline-delimited JSON events on stdout instead of rendered text — one JSON
object per line, in the order things happen during the turn. `--jq` and
`--template` switch `camy chat` into this mode but do not filter or format
the stream itself; pipe the NDJSON to `jq` for that, as in the example
above.

The event types are `start`, `token`, `tool_call`, `collection`,
`snapshot`, `checkpoint`, `checkpoint_replayed`, `retry`, `resume_offer`,
`last_reply`, `warning`, `final`, `done`, and `error`. A `retry` event
means the model restarted its answer: its `dropped_chars` says how many
characters of the `token` text already sent are void. A `retry` with
`"reason": "replace"` means camy.ai corrected the reply after streaming
it; the `token` that follows carries the corrected rest. The `done` event
also carries `tier_requested`, `tier_effective` and `tier_reason` when
camy.ai reports the tier that ran, and `care` when a reply came with crisis
lines; `start` and `done` carry `ai_notice` when camy.ai sends a reminder
that Camy is an AI. An `error` event
usually ends the stream, but after a failed attach or a restarting server
camy can retry and keep streaming, so read the last event and `$?`, not the
first `error` event. An `error` event's `code` is never empty (`turn_error`
when the turn itself failed). Frames with no dedicated event type of their own —
`response_envelope`, `chain_progress`, `plan_updated`, and anything new the
server adds — pass through as `{"type": "<frame type>", "data": {…}}` when
they name this turn's chat. Another chat's frames never pass through, and
neither do account-wide notices or keepalive frames. Frames that name no
chat pass only when camy can tie them to this turn: a card this turn is
about (`checkpoint_resolved`, `action_confirmed`, `action_timeout`), so an
approval resolving in another chat, or the backlog a fresh connection
replays, never reads as an event of this turn; a Camy computer session this
turn met (`computer_session_update`, `computer_session_resumed`); or one
of the turn's own notices (`turn_queued`, `agent_notification`, `guardrail_warning`,
`context_compacted`, `message_sent`, `session_handoff_offer`). [Scripting with
camy](scripting.md) has the field-by-field table, the full stdout/stderr
contract, `--jq`/`--template`, and the frozen exit-code table shared across
every command.

Machine mode never prompts. A `checkpoint` event in `--json` mode means the
checkpoint fails closed immediately (exit 4) rather than waiting for an
answer that can't be typed into a pipe — see [Approvals](approvals.md) for
how to answer it out of band and resume with `camy chat attach`.
