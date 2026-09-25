# Changelog

All notable changes to the camy CLI are recorded here.

Versions follow [Semantic Versioning](https://semver.org/). The public API is
the `--json` output shapes and the [exit-code table](docs/exit-codes.md); a
change to either that is not backward compatible bumps the major version.

Each GitHub Release on this repository carries the same notes as its section
below, plus the signed checksums for that version.

## 1.0.4 — 2026-09-25

This update makes camy more careful on your machine and easier to search
from it. An edit shows its diff before you approve it, your chats are
searchable from the terminal, a turn carries on after you answer its card,
and from 6 October commands camy runs on your machine write only inside your
project by default, wherever the OS can enforce it.

**New**

- Adds `camy chats search` to find a message across your chats by what was
  said. See [Searching past chats](docs/chat.md#searching-past-chats).
  `camy calls search`, `camy runs search` and `camy jobs search` follow as
  search reaches your account; until then each says so.
- `camy auth login` signs in and links this Mac in one approval, from any
  install. `--no-device` signs in without linking, `--scopes all` no longer
  skips the link, and a backup code completes `camy auth login --code`. See
  [Linking this Mac as you sign in](docs/authentication.md#linking-this-mac-as-you-sign-in).
- Adds `camy schedule resume`, the undo for `camy schedule pause`. See
  [Pausing, resuming, and deleting](docs/automation.md#pausing-resuming-and-deleting).
- Adds `camy webhooks dead-letters`: the deliveries that ran out of retries,
  with the ids `camy webhooks replay` takes. See
  [Dead letters](docs/automation.md#dead-letters).
- `camy device status` names the folders this Mac has granted and says
  whether the resident agent is running. See [Status](docs/device.md#status).

**Improvements**

- From 6 October 2026, commands camy runs on your machine can write only
  inside your project, wherever the OS can enforce it. A blocked command can
  ask you for wider access. `--sandbox observe` or
  `CAMY_LOCAL_SANDBOX=observe` keeps today's behaviour. See
  [The boundary, and the sandbox](docs/local-bridge.md#the-boundary-and-the-sandbox).
- Shows the real diff on the approval card for an edit to part of a file on
  your machine, as it already did for a whole-file write, and what you
  approve is exactly what runs. See
  [Writes and edits](docs/local-bridge.md#writes-and-edits).
- Fixes a turn going quiet after you answered its approval card; the agent's
  reply now follows. Another chat's activity no longer takes over or ends
  your turn, a turn stopped elsewhere says it was stopped, and `--json`
  streams carry only this turn's events.
- Fixes Approve on a connector's approval card, which rejected the write,
  and `camy connectors` commands failing on some accounts. `connectors
  remove` confirms it is you with a code, `connectors review` can approve a
  server whose tools changed, and the list flags an expired sign-in or an
  unreachable server. See [Connectors](docs/connectors.md).
- Gives commands on your machine more time, two minutes by default and up
  to thirty, keeps a result that could not reach camy.ai for up to an hour
  so the next connection delivers it, and runs more read-only `aws`, `gh`
  and `gcloud` commands without an approval card. See
  [What the agent can touch](docs/local-bridge.md#what-the-agent-can-touch).
- Lets the agent read a large file on your machine a page at a time and
  find files by name in subfolders; searching and listing skip hidden and
  cache folders.
- Tells camy.ai where a local session runs, so the agent stops guessing the
  project root: the project's root, branch and remote without credentials,
  whether it has uncommitted changes, your OS and shell, and up to 40
  top-level names, never file contents. `--cloud` turns send none of it.
  See [What the server sees](docs/local-bridge.md#what-the-server-sees).
- In the full-screen app, `esc` stops a command running on your machine,
  stopping a turn parked on an approval cancels its card, and Enter on a
  message in `/queue` steers it into the running turn.
- Offers an interrupted turn back once the current one ends, so you can
  resume it. `--json` turns get a `resume_offer` event instead, and headless
  runs are never asked. See
  [An interrupted turn, offered back](docs/chat.md#an-interrupted-turn-offered-back).
- Fixes commands that reported success when camy.ai refused or changed
  nothing: `inbox undo`, `archive`, `restore` and `mark-read`, `sweep set`
  and `restore`, `feed act` and `dismiss`, `approvals answer`, `approve` and
  `deny`, `webhooks trigger` and `device scope remove` now fail instead.
- Fixes exit codes for scripts: a one-shot `camy chat` whose agent carries
  on after a no exits 0, not 8; `camy chat --json` no longer exits 4 over
  another task's card; and a refusal for lack of credits exits 6, not 3.
  `approve --wait --json` and `answer --wait --json` end with a one-line
  verdict, so the stream is valid NDJSON, and `camy approvals --json` rows
  carry `family`, `subject_id` and the checkpoint's `parameters`. See
  [Exit codes](docs/exit-codes.md).
- Refuses a `--limit` camy.ai would reject, and `camy capture` text over
  20,000 characters or piped input over 1 MiB, before sending anything.
  Out-of-credits and plan refusals say what they are, and server, workspace
  and canvas refusals read as plain sentences.
- `camy approvals -w` and `camy status -w` open For You, `camy jobs show -w`
  opens Activity, `camy inbox show -w` opens the message, `camy canvas open`
  opens the canvas, and `o` on a card opens its chat.
- On a linked Mac, `camy stop` keeps the resident agent stopped until
  `camy device install` starts it again, `device scope add` requires a
  path, and the agent's log rotates at 5 MB. See
  [Stop it now](docs/device.md#stop-it-now).
- `camy inbox show` lists the recipients, `inbox unsubscribe` says when an
  email has no way to unsubscribe, `sweep review` prints the ids
  `sweep restore --items` takes, `feed --all` lists cards of every status,
  and short ids resolve for done cards, archived chats and older mail.
- Fixes `camy schedule create`, whose schedules never ran their
  instruction: it now makes a scheduled task that does, reporting to the
  thread and by email unless `--channels` says otherwise. A schedule
  created with an earlier version never ran; delete it and create it
  again. `camy schedule` lists scheduled tasks with your other schedules,
  shows when a recurring one really fires next, and keeps paused ones
  listed.
- `camy integrations connect` takes the catalog's names and waits until the
  account is connected, and `integrations health` reads `not connected` for
  a provider you never connected.
- `camy canvas versions` lists a site's archived versions, `canvas rollback`
  names the version it restored, and `canvas domain verify` says why a
  check failed.
- `camy vm exec --timeout` goes up to an hour, `vm exec` with no workspace
  exits 7 and points to `camy vm provision` instead of provisioning one,
  `vm status`, `vm sizes` and `vm ls` fill in blank fields, and
  `camy vm shell` keeps reconnecting after dropped connections. See
  [camy vm exec](docs/workspace.md#camy-vm-exec).
- `camy update` keeps the version you were running and checks that the new
  one starts before reporting success; if it does not, the previous version
  is put back. See [Updating](docs/installation.md#updating).
- Fixes camy hanging at startup in some Linux terminals.

**Security**

- Hardens how camy protects the files, credentials and commands on your
  machine, and how it trusts a linked Mac. Updating is recommended.

**Compatibility**

- camy and Camy for Mac now require macOS 13 or later.

## 1.0.3 — 2026-09-15

The terminal has been redesigned. Every screen follows the same layout and
ends with what to do next, approvals are a card with the question on its
own line, the full-screen app shows what is happening right above your
input, and help leads with examples.

**New**

- Adds `camy plan`: your plan, today's turns and when they reset, and your
  balance for the month, with where to change it.
- Adds a help overlay to the full-screen app (`?` or F1), and runs any
  read-only command inside it as `/command`. See
  [The full-screen app](docs/terminal.md#the-full-screen-app-and---inline).
- Adds `/plan`, `/queue` and `/usage` to the app: the agent's checklist for
  the current turn, the messages waiting behind it (Enter sends one next,
  `d` drops it), and your plan and credits. Credits no longer sit on the
  status row.
- Adds multi-select to the app's `/approvals` picker: press space to mark
  rows, then `a` to approve or `d` to deny them together.
- Adds `camy tasks reopen`, the undo for `camy tasks done`.
- Adds `--ground dark|light` to force the colour palette, `--no-truncate`
  to keep list cells whole, and `--raw` to get a listing's unmodified
  response under `--json`.

**Improvements**

- Ids are short and typed, such as `ap_789a` or `jb_aab2`, and every
  command accepts one alongside a prefix or a full id. `--json` keeps full
  ids, and `--ids=hex` prints the old eight-character form for one more
  release.
- Commands that take an id now take several: `approvals show`, `approve`
  and `deny`; `inbox show`, `undo`, `mark-read`, `archive` and `restore`;
  `jobs show` and `cancel`; `tasks done`, `reopen` and `rm`; `schedule
  show` and `delete`; `feed show` and `dismiss`; `keys revoke`. One
  confirmation covers the set, and `--json` returns one result per id.
- Makes `--json` consistent: a listing is always an array, an empty listing
  is `[]`, a single item is an object, and a `--all` sweep that partly
  fails keeps what it fetched in a `partial` envelope. `camy connectors`
  and `camy integrations` no longer wrap their listings. See
  [Scripting](docs/scripting.md#listings-single-things-and-ids).
- `camy approvals` groups what is waiting by the kind of decision, collapses
  repeats, and shows only the actions that apply. The card names the kind,
  id, lane, risk, origin and age, with the question and its keys beneath.
  `[y/N/o(pen web)]` is unchanged. See [Approvals](docs/approvals.md).
- `camy status` shows the command behind each row, marks a row it could
  not fetch with `?` instead of hiding it, and marks browser destinations
  with `↗`.
- `camy jobs show` and `camy feed show` put a job's blocker first, with the
  command that clears it. `camy chats show` renders a transcript the way
  the app does.
- The full-screen app keeps a fixed header, shows what the turn is doing
  right above your input, lists its keys along the bottom with a
  connection indicator, and keeps the transcript plain text you can copy.
- In a chat, each tool call closes on its own line with what it returned
  and how long it took, and a one-shot turn ends with a short trailer
  naming the tier, the time and the chat.
- Errors are two lines, what went wrong and how to fix it. When camy can
  diagnose the cause (network, sign-in, credits, a sleeping workspace), the
  fix is shown as a command.
- Shows progress on any read that takes longer than 150 ms, with a way to
  cancel.
- Help leads with examples on every command, followed by its verbs, flags
  and what to run next. The root page lists commands in the order you are
  likely to need them.
- Shell completion completes ids from the same lists the commands print,
  instead of local filenames.
- Everything fits 60 columns and works under `NO_COLOR` and with
  `--accessible`, which uses words a screen reader can say instead of
  symbols, frames and spinners. A light terminal background is detected
  and gets its own palette. See
  [Terminal output and accessibility](docs/terminal.md).
- Fixes the full-screen app freezing when a turn got stuck. The menu works
  while a turn runs, and `esc` always returns you to the composer.

## 1.0.2 — 2026-09-13

Camy now runs on your Mac as a resident agent, connectors have a home in
the CLI, and every release ships signed and notarized macOS binaries.

**New**

- Adds `camy device`: link your Mac to your account, grant it read or write
  access to the folders you choose and, if you want, the terminal, and let
  it work in the background. `camy stop` halts it at once and `camy ledger`
  lists everything it accepted or refused. See
  [Your Mac as a device](docs/device.md).
- Adds Camy for Mac, the notarized app the resident agent runs from,
  published with each release as `Camy_<version>_darwin.zip`. Everything
  else works from any install; only linking a Mac and installing the agent
  need the app. See [Camy for Mac](docs/installation.md#camy-for-mac).
- Adds `camy connectors` to see the accounts and tool servers Camy acts
  through, and to check, pause, resume, review, or remove one. Adding still
  happens on camy.ai. See [Connectors](docs/connectors.md).
- Adds `camy schedule update` and `camy schedule run-now` for scheduled
  agents: change the cron, timezone, or channels in place, or fire one on
  the next tick.
- Adds `--sandbox` to confine what local commands can write. `enforce`
  refuses writes outside your project wherever the OS can enforce it; the
  default, `observe`, leaves commands unconfined. See
  [The local bridge](docs/local-bridge.md).

**Improvements**

- Creates a chat only when its first message is sent, and adds
  `camy chats prune` to clear the empty ones left behind.
- Lets a local command keep running after the turn that started it ends;
  the approval card says so before you answer.
- Reads your own `~/.camy/AGENTS.md` alongside a project's `AGENTS.md` or
  `CLAUDE.md`.
- `/attach` and `/resume` now work inside the REPL.
- `camy approvals` and a connector's approval card now name the connection
  and the action.
- Fixes edits landing in the wrong place in a file, and duplicated text
  when the model restarts an answer mid-stream.

**Security**

- Signs and notarizes the macOS binary in every release, so a tarball
  downloaded in a browser is no longer refused by Gatekeeper. See
  [Verifying releases](docs/verifying-releases.md#macos-signed-and-notarized).
- Hardens how camy runs commands on your machine and what an approval card
  shows before you answer. Updating is recommended.

## 1.0.1 — 2026-09-06

This update adds a credit balance and a live run gauge to `camy status`,
brings camy to npm, and includes stability, security, and supply-chain
improvements.

**New**

- Adds your credit balance and a live gauge of context and credits to
  `camy status`, and `credits` and `run_meter` to `camy status --json`.
- Adds `/compact` to the full-screen app to summarize older context on
  demand.
- Adds a diff against the file on disk to approval cards for local file
  writes.
- Adds npm as an install method: `npm install -g @camy/cli`, or
  `npx @camy/cli` with no global install. See
  [Installation](docs/installation.md#npm).

**Improvements**

- `camy vm shell` now reconnects in place when its connection drops,
  opening a fresh shell and saying so.
- `camy update`, `camy uninstall`, and `camy doctor` now recognize an
  npm-managed install.
- Improves the durability of camy's own files: an interrupted write can no
  longer leave one truncated.

**Security**

- `camy update` now verifies each release's minisign signature with a key
  built into the binary before it downloads anything. The installer does the
  same where `minisign` is installed, and always reads the release's signed
  manifest rather than the shared index.
- Every release now ships SLSA provenance, verifiable with `slsa-verifier`.
- Hardens the local bridge's safety checks and `camy approvals --wait`.
  Updating is recommended.

For release verification, see
[Verifying releases](docs/verifying-releases.md).

## 1.0.0 — 2026-09-04

The first public release. [The documentation](docs/README.md) covers the full
command surface. Highlights:

- One static binary for macOS and Linux, arm64 and amd64. Install without
  sudo: `curl -fsSL https://camy.ai/cli/install.sh | sh` or
  `brew tap trycamy/tap && brew install camy`.
- Browser device-flow sign-in that leaves an expiring, scoped key in the OS
  keychain. No API key ever appears on a command line.
- [`camy chat`](docs/reference/camy_chat.md) for one-shot and continued
  conversations, with stdin as context, file attachments, and streamed tool
  calls. Bare `camy` opens the full-screen interactive surface.
- [Approvals](docs/approvals.md) are the safety model: anything risky pauses
  for a human, headless runs fail closed with exit code 4, and timeouts never
  approve.
- A unified inbox with triage verdicts and the sweep dial, plus jobs,
  schedules, tasks, capture, integrations, and webhooks.
- A dedicated cloud workspace:
  [`camy vm exec`](docs/reference/camy_vm_exec.md) mirrors remote exit codes
  ssh-style and [`camy vm shell`](docs/reference/camy_vm_shell.md) opens a PTY.
- An optional local bridge. The agent reads inside a project on your machine,
  and writes and runs there only with explicit trust, behind per-action
  approval cards and a secret-path denylist.
- `--json` everywhere, with built-in `--jq` and `--template`, and NDJSON for
  streams.
- Checksum-verified in-place updates with
  [`camy update`](docs/reference/camy_update.md).

## Earlier versions

Versions 0.10 through 0.13 were internal pre-releases and are not documented
here. Reinstall with the command above to move to 1.0.
