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

This page covers both surfaces, plus `camy chats` for browsing past
sessions, `camy mode` for choosing how deep the agent thinks, and the
project-instructions and inline-image behavior that only show up while
you're chatting.

## One-shot chat

```bash
camy chat "what needs me before noon?"
```

camy sends the message as a new turn and streams the reply to stdout as it
arrives. Tool calls the agent makes along the way — reading a file, running
a command — are traced to stderr as they happen, never printed as part of
the reply. If a tool call needs your approval before it can run, camy shows
an approval card; see [Approvals](approvals.md) for how those work and what
happens when nothing is there to answer them.

**stdout is the reply, stderr is everything else.** The reply text (or, in
JSON mode, the NDJSON event stream — see
[below](#machine-output---json-and-ndjson)) is the only thing camy writes to
stdout. The wordmark, tool traces, spinners, and approval cards all go to
stderr, so a pipeline that only wants the reply can just take stdout:

```bash
git diff | camy chat "review this"
camy chat --json "give me the numbers" | jq -r 'select(.type=="final") | .text'
```

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
| 4 | A checkpoint needed approval and camy couldn't prompt for it (headless, `--no-input`, no controlling terminal, or `--json`) — or you pressed Ctrl-C while a prompt was open. See [Approvals](approvals.md). |
| 6 | The turn ended on a plan or credit limit. |
| 8 | An approval was rejected and nothing happened after it — a turn the agent kept going after a rejection and still produced something does not exit 8. |

The full, command-independent table lives in [Exit codes](exit-codes.md).

In a human terminal, a completed turn prints a one-line footer: `camy chats
show <id>` if the turn approved anything, so you know where to look to undo
it, or a reminder that `camy chat -c` continues the conversation otherwise.
A `--temp` turn prints neither line — there is nothing to show or continue.

Full flag reference: [camy chat](reference/camy_chat.md).

## Continuing, targeting, and throwaway chats

A plain `camy chat` starts a new chat every time. Three flags change that.

```bash
camy chat -c "and the second one?"
```

`-c`/`--continue` resumes the last chat you used on this profile. If there
isn't one yet, camy says so and starts fresh instead.

```bash
camy chat --chat 2f1c9ab3 "keep going on that one"
```

`--chat` targets a specific chat by id. A short prefix (from `camy chats`)
resolves the same way it does everywhere in camy: under 4 characters is
refused outright, and a prefix matching more than one chat is a usage error
rather than a guess.

```bash
camy chat --temp "just testing something, don't save this"
```

`--temp` starts a throwaway chat: nothing is persisted server-side, it
never appears in `camy chats`, and it can't be resumed with `-c` or
`--chat`. It is mutually exclusive with both of them.

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
check the file's type on your end, only that it can be opened and that the
upload comes back with an id — what the agent can actually do with the
content is up to the server. In practice that means images, PDFs, audio,
and video: the kinds the agent can read.

An unreadable path or a failed upload stops the send before any turn is
created, so a message never goes out silently missing what you meant to
attach.

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

Full flag reference: [camy chat attach](reference/camy_chat_attach.md).

## Past chats: list, show, export

```bash
camy chats
camy chats list --all
camy chats show 2f1c9ab3
camy chats export 2f1c9ab3 > transcript.md
```

`camy chats` (or `camy chats list`) lists your sessions newest first, 25 at
a time by default. The two paging flags live on the subcommand: `camy chats
list -L 50` changes the page size and `camy chats list --all` shows
everything.

`camy chats show ID` renders a transcript through the same markdown
pipeline live chat uses. `camy chats export ID` writes a portable markdown
transcript to stdout — markdown is the only export format today. Both
accept a short id prefix the same way `--chat` does, and both hide the
internal checkpoint-response bookkeeping a raw transcript would otherwise
clutter the reading with.

Full flag reference: [camy chats](reference/camy_chats.md),
[camy chats list](reference/camy_chats_list.md),
[camy chats show](reference/camy_chats_show.md),
[camy chats export](reference/camy_chats_export.md).

## The full-screen app

Run [`camy`](reference/camy.md) with no arguments at a real terminal and,
unless you've asked for something more linear (see below), you get the
full-screen app: a persistent session that stays open across many turns
instead of exiting after one. It keeps one connection alive for as long as
you leave it running, so an approval answered from another terminal or the
web while you're idle still shows up here without you having to reconnect.

Replies render through the same markdown pipeline as `camy chats show` —
headings, code blocks, and emphasis draw as formatted text, not raw
markdown source.

### Composing

- Enter submits — or, while a turn is still generating, queues the message
  and sends it as soon as the turn ends.
- Alt+Enter inserts a newline without submitting, for a multi-line message.
- Pasting text arrives as one block; line breaks inside a paste become
  literal newlines in the message instead of each one submitting early.
- Ctrl+R opens a reverse-search over your input history; type to filter,
  Ctrl+R again walks to older matches, Enter takes the match, Esc closes
  the search.

### Slash commands

| Command | Does |
|---|---|
| `/approvals` | Opens a picker over pending checkpoints — the leash, inline. |
| `/inbox` | Shows the inbox list, read-only, inline. |
| `/status` | The right-now status pane. |
| `/compact` | Summarizes older context on demand, and says so when there's nothing to compact. |
| `/mode [agent\|quick]` | Shows or sets how deep the agent thinks — see [below](#mode-agent-or-quick). |
| `/jobs` | What's scheduled and when it next fires. |
| `/vm` | Your cloud workspace. |
| `/new` | Starts a fresh chat; the old one stays in `/chats`. |
| `/chats` | Opens a picker over every conversation; `/chat ID` switches straight to one. |
| `/help` | Keys and commands. |
| `/quit` | Leaves — anything scheduled keeps running. |

Esc interrupts a turn that's generating; two Ctrl-C's in quick succession
leave the app.

### `--inline` and `--accessible`

Two flags change how the app draws without changing what it can do:

- `--inline` (or `CAMY_INLINE=1`) keeps the same app and the same slash
  commands, but renders into your terminal's native scrollback instead of
  taking over the screen with an alternate-screen, animated layout.
- `--accessible` (or `CAMY_ACCESSIBLE=1`, or a `TERM=dumb` terminal) skips
  the full-screen app entirely and drops you into a plain line-by-line
  REPL instead: no redraws, no spinners, no boxes.

The REPL's slash set is the same one, minus `/compact` and the app's
`/chats show ID` form, and plus `/last`, which prints the current chat id:
`/new`, `/chat ID`, `/mode`, `/approvals`, `/inbox`, `/status`, `/jobs`,
`/vm`, `/chats`, `/last`, `/help`, and `/quit` (also `/exit` and `/q`, which
work in the full-screen app too).

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
fewer tools. With no argument it prints the current setting; with `agent`
or `quick` it persists the choice. The full-screen app's and the REPL's
`/mode` slash command read and write the exact same persisted setting.

`camy chat --tier agent|quick` overrides the persisted mode for one turn
only, without changing what's saved. The server may still choose
differently than what you asked for. The tier actually used is reported
back as part of the streamed turn — the `start` event's `tier` field in
`--json` mode — so a script checking a specific tier should read it from
there rather than assume the request was honored as-is.

In machine mode (`--json`, `--jq`, or `--template`) the persisted mode is
deliberately not sent: a script that didn't ask for a tier gets the
server's own default. Pass `--tier` explicitly when a script needs a
specific one.

Full flag reference: [camy mode](reference/camy_mode.md).

## Project instructions from AGENTS.md and CLAUDE.md

When a chat runs with the [local bridge](local-bridge.md) live against your
project — not against the cloud workspace — camy looks for an `AGENTS.md`
file at the project root and, if that's not there, a `CLAUDE.md`, and sends
its contents along as project instructions for the turn. The content is
sent to the server as data for the turn, not as instructions the model
blindly follows.

Only a plain regular file qualifies. A symlink or a hard link at that path
is refused outright, even one pointing at an ordinary file inside the
project, since either could smuggle in content the project's own visible
files never held. The file is capped at 16KB and whitespace-trimmed; an
empty result after trimming counts as no file at all.

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
`snapshot`, `checkpoint`, `final`, `done`, and `error`. Frames with no
dedicated event type of their own — `response_envelope`, `chain_progress`,
`plan_updated`, and anything new the server adds — pass through as
`{"type": "<frame type>", "data": {…}}`. [Scripting with
camy](scripting.md) has the field-by-field table, the full stdout/stderr
contract, `--jq`/`--template`, and the frozen exit-code table shared across
every command.

Machine mode never prompts. A `checkpoint` event in `--json` mode means the
checkpoint fails closed immediately (exit 4) rather than waiting for an
answer that can't be typed into a pipe — see [Approvals](approvals.md) for
how to answer it out of band and resume with `camy chat attach`.
