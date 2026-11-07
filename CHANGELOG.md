# Changelog

All notable changes to the camy CLI are recorded here.

Versions follow [Semantic Versioning](https://semver.org/). The public API is
the `--json` output shapes and the [exit-code table](docs/exit-codes.md); a
change to either that is not backward compatible bumps the major version.

Each GitHub Release on this repository carries the same notes as its section
below, plus the signed checksums for that version.

## 1.0.6 — 2026-11-07

**Downloads:** `curl -fsSL https://camy.ai/cli/install.sh | sh` · `brew tap
trycamy/tap && brew install camy` · `npm install -g @camy/cli` · Camy for Mac:
`Camy_1.0.6_darwin.zip` among the release's assets. See
[Installation](docs/installation.md).

This update has approvals act exactly on what you were shown, makes exit codes
and `--json` output more exact for scripts, steadies chats, the full-screen
app and the local bridge, adds crisis lines and the legal notice to the
terminal, and hardens the local bridge and sign-in.

**Compatibility**

- `camy auth login` now asks for every scope camy's commands need, including
  the one that lets this terminal offer its local tools. A key from an earlier
  sign-in keeps its old scopes, so run `camy auth login` again after updating
  to keep every command working; local tools keep working with an older key.
  See [Scopes](docs/authentication.md#scopes).
- `api_url`, `--api-url` and `CAMY_API_URL` now take only an `https://`
  address, or `http://` for a local one such as `localhost`; anything else
  exits 2, or is ignored with a warning when it comes from your config. If
  your config or a profile sets `api_url` to an address other than
  `https://api.camy.ai` or a local one, run `camy auth login --api-url <url>`
  after updating, since commands exit 2 until you do; with `CAMY_API_KEY`,
  pass `--api-url` or set `CAMY_API_URL` on each command instead. See [Where
  your key is sent](docs/configuration.md#where-your-key-is-sent).
- Exits 2, a usage error, for a malformed `--api-url` or `CAMY_API_URL` (was
  1), for `camy help` on an unknown topic (was 0), and for a chat or schedule
  id that matches none of yours (was 1). Update scripts that test the old
  codes. See [exit 2](docs/exit-codes.md#2--usage-error).
- Exits 7, unavailable, for `camy calls search`, `camy runs search`, `camy
  jobs search` and linking a computer before that is on for your account (was
  1), and for a device command on a Mac that isn't linked (was 2). See [exit
  7](docs/exit-codes.md#7--unavailable).
- Exits 3 for an action camy.ai takes only from your signed-in Camy app or
  browser, such as `camy sweep set auto`, with a hint to do it there (was 1,
  or 6 for billing). `camy vm resize` now stops this way at once, before it
  asks anything, `--force` included; its help and `camy vm provision`'s now
  say they are refused here. Move a scripted resize or provision to the Camy
  app or camy.ai. See [Only in the Camy app or at
  camy.ai](docs/troubleshooting.md#only-in-the-camy-app-or-at-camyai-exit-3).
- Gives account refusals their own codes: an account scheduled for deletion
  exits 3 (was 1) and names the date and how to cancel, one waiting for your
  month and year of birth exits 2 and links where to answer, one closed
  because Camy is only for adults exits 3, and an age check camy.ai can't make
  just now exits 7. See [Account
  refusals](docs/troubleshooting.md#account-refusals-exit-3) and [Usage
  errors](docs/troubleshooting.md#usage-errors-exit-2).
- Reports three outcomes that used to exit 0: `camy approvals approve` on a
  checkpoint that already ran says `too late` and exits 1; a `camy feed act
  <id> approve` that camy.ai didn't carry out exits 4 when camy.ai holds it
  for another check, or 1 when it failed, expired or was stopped; and `camy
  auth logout` exits 1, and says so, when the keychain keeps your key (`camy
  uninstall` now says so too). See [Deciding](docs/approvals.md#deciding) and
  [Acting on a card](docs/inbox.md#acting-on-a-card).
- `camy api` now returns an answer up to 50 MB whole and exits 1 past that,
  instead of printing the first 10 MB as text with exit 0. On any command, a
  camy.ai answer cut off mid-way now fails as a connection error (exit 1) that
  may have gone through, never as an empty success. See [exit
  1](docs/exit-codes.md#1--runtime-or-api-error).
- `camy connectors review` with no terminal now approves only with `--yes` or
  `--force`, and otherwise exits 2; a script that piped `y` into it needs
  `--yes` now. See [Review what
  changed](docs/connectors.md#review-what-changed).
- `camy schedule create` now refuses a time it can't read whole, such as
  `9:00pm`, with exit 2, instead of scheduling 09:00 and exiting 0; write
  `21:00`. See [Creating a schedule](docs/automation.md#creating-a-schedule).
- `camy tasks add --due` now reads a time with no offset as this computer's
  local time, and a bare date as local midnight, instead of as UTC; add an
  offset or `Z` to send a UTC time. See [Tasks](docs/automation.md#tasks).
- Fixes `--json` shapes; update scripts that read the old ones. `camy config
  get --json` now prints `{"key", "value", "origin"}` instead of the bare
  value, so read `.value`; `camy keys list --json` rows use `created_at` and
  `last_used_at` in place of `createdAt` and `lastUsedAt`; and `camy ledger
  --json`, `camy alias --json` and `camy local trust list --json` print `[]`
  or `{}` for an empty list instead of `null`. See [`--json` and machine
  mode](docs/scripting.md#--json-and-machine-mode).
- `camy status --json`, `camy approvals show --json` and `camy auth status
  --json` now print only their documented fields; for your workspace's full
  record, use `camy vm status --json`. See [Listings, single things, and
  ids](docs/scripting.md#listings-single-things-and-ids).
- camy now stops with exit 1 when `HOME` isn't an absolute path, or when
  `--profile` or `CAMY_PROFILE` isn't a plain name (letters, digits, `.`, `_`,
  `-`); a `default_profile` in your config that isn't one is ignored, with a
  note. See [exit 1](docs/exit-codes.md#1--runtime-or-api-error).
- `editor` and `pager` in `config.toml` must now be a program name or an
  absolute path followed by plain arguments: `camy config set` refuses
  anything else, and a value already there is ignored, with a note each time
  camy runs. Set a plain command, such as `camy config set editor "code
  --wait"`. See [config.toml](docs/configuration.md#configtoml).
- The install script now requires `minisign` and won't install a release whose
  signature it can't check: install minisign first, CI included, or set
  `CAMY_REQUIRE_SIGNATURE=0` to skip the check. `CAMY_DL_BASE` must be an
  `https://` address (`http://` only for a local one), and `CAMY_INSTALL_DIR`
  an absolute path. Homebrew, npm and `camy update` are unaffected. See
  [Environment variables](docs/installation.md#environment-variables).
- On Linux, a sandboxed command now has no network unless it is a tool that
  fetches code or packages or connects to another machine (`git`, `npm`,
  `pip`, `curl`, `ssh` and the like); one started through a wrapper such as
  `sh -c` runs offline, and each command gets its own empty `/tmp`. See [The
  boundary, and the
  sandbox](docs/local-bridge.md#the-boundary-and-the-sandbox).
- `--sandbox enforce` now refuses to run a command on a machine that can't
  sandbox it, and says why; install bubblewrap from your distribution's
  packages (Linux) or use `--sandbox observe`. See [Local commands and the
  sandbox](docs/troubleshooting.md#local-commands-and-the-sandbox).
- A card that asks to run a local command outside the sandbox now takes typing
  `outside`; `y` refuses. Only a card where you typed `outside` runs a command
  outside the sandbox. See [The approval
  card](docs/approvals.md#the-approval-card).
- camy now asks before working in your home folder, a folder above it, or one
  that holds your shell's startup files or Camy's own settings; with no
  terminal to ask, that run goes without local tools. Start camy from a
  project folder to use them. See [The project
  root](docs/local-bridge.md#the-project-root).
- On a Mac forgotten with an earlier version, run `camy device uninstall` to
  remove the leftover LaunchAgent. If your config sets `default_profile` to
  another profile and an earlier version installed the agent for `default`,
  run `camy device install` again to tie it to `default`. See [Run it in the
  background](docs/device.md#run-it-in-the-background).

**New**

- Adds `camy crisis`, which lists the crisis lines for your country without
  signing in; when your country's lines can't be loaded it prints the US lines
  and a worldwide helpline finder, and still exits 0. When camy.ai includes
  crisis lines with a reply, camy shows them after it, on stderr, and `-q`
  doesn't hide them; under `--json` the `done` event carries them as `care`.
  See [Crisis lines](docs/chat.md#crisis-lines).
- Adds `camy legal notice` to read the current Terms of Service and Privacy
  Policy notice. Until you have read it, a command run at a terminal while
  signed in reminds you on stderr at most once a day, never under `--json` or
  `--no-input`. See [camy legal notice](docs/reference/camy_legal_notice.md).
- `camy chat`, `camy --inline` and a one-shot turn now say that Camy is an AI,
  not a person; a one-shot turn says it on stderr, never under `--json`, and
  `-q` doesn't hide it. See [One-shot chat](docs/chat.md#one-shot-chat).
- Every chat surface, the full-screen app included, now shows camy.ai's
  reminder lines when it sends them, `--json` `start` and `done` events carry
  `ai_notice` when camy.ai sends one, and `camy --help` closes with a note
  that Camy is an AI. See [NDJSON for
  streams](docs/scripting.md#ndjson-for-streams).
- `camy chat`'s trailer now names the tier that ran, or `quick → agent` when
  the turn moved, and `--json` `done` events add `tier_requested`,
  `tier_effective` and `tier_reason` when camy.ai reports them. See [Mode:
  agent or quick](docs/chat.md#mode-agent-or-quick).
- `camy auth status` now counts the scopes your key holds and lists them under
  `scopes` in `--json`; it and `camy doctor` say when the key can't run
  commands on your cloud computer. See [`camy auth
  status`](docs/authentication.md#camy-auth-status).
- `camy vm status` now names your workspace's size and what it costs in
  credits per hour, such as `plus · 15 credits/h`, or the instance type when
  it can't read the size. See [`camy vm
  status`](docs/workspace.md#camy-vm-status).
- Adds `camy profile list`; it and `camy profile` list `default` first, then
  the rest by name, a profile you signed in to with `camy auth login
  --profile NAME` included. See [List
  profiles](docs/configuration.md#list-profiles).

**Improvements**

- Approving or declining now acts on a request exactly as camy showed it to
  you, on its card, in `camy approvals show` or in a `--json` listing; if it
  has changed since, nothing runs, and camy exits 4 and points you back at the
  request to look again. An id camy never showed is answered as it stands, and
  `camy approvals --json` rows carry `action_version` when the request has
  one. See [Deciding](docs/approvals.md#deciding).
- An approval prompt now closes as soon as the card is decided elsewhere, a
  sentence typed at a `y/N` prompt is no longer taken as a no, a choice card
  takes several picks only when the question asks for several, as in the
  iPhone app and on the web, and a card that asks several questions asks
  each in turn; its `--json` `checkpoint` event lists them as `fields`. See
  [The approval card](docs/approvals.md#the-approval-card).
- `camy approvals show` now draws the whole card in plain words, numbers a
  choice card's options, and shows a local command or file change as the
  command or a diff. A card for an email draft no longer reads as a send, and
  a connector tool's name no longer ends in a stray code. See [Listing and
  reading](docs/approvals.md#listing-and-reading).
- A headless turn that stops on a question now points at `camy approvals
  answer`, in the `--json` hint too. `approve --wait` and `answer --wait` take
  the short chat id `camy chats` prints, and they and `camy chat attach` now
  end with the reply once an approved cloud action finishes. See [Streaming
  with `--wait`](docs/approvals.md#streaming-with---wait).
- Fixes chat turns that hung on a local action that never started or that you
  stopped mid-run, and `still running on your machine…` no longer lands inside
  a reply.
- A reply camy.ai corrects after streaming now prints once, and when the
  model restarts an answer, the full-screen app drops the abandoned attempt,
  or says how much above came from it once it has settled, and piped or
  accessible-mode output says so on stderr. Under `--json`, a correction that
  rewrites text already streamed is a `retry` event with reason `replace`.
  See [NDJSON for streams](docs/scripting.md#ndjson-for-streams).
- `camy chat` now works in a folder with a large `AGENTS.md` or many files,
  and stops at once with exit 3 when the key lacks `chat:read`, with `camy
  auth login --scopes +chat:read` as the hint. A key that can't let this
  computer offer local tools now says so once instead of doing nothing. See
  [Scopes](docs/authentication.md#scopes).
- A `y` to `resume?` that resumed nothing now says why when the chat was
  already running a turn or the hold was gone. A resume card answers only for
  the held turn it was drawn for, and an offer camy.ai withdraws is no longer
  drawn. See [An interrupted turn, offered
  back](docs/chat.md#an-interrupted-turn-offered-back).
- `camy chat --temp`'s help now says a temporary chat isn't saved to your
  history or memory, and when camy.ai keeps a 30-day safety copy, the chat
  says so as it starts at a terminal. See [Continuing, targeting, and
  temporary chats](docs/chat.md#continuing-targeting-and-temporary-chats).
- An `--attach` folder or file over 50 MB now stops the send with exit 2
  before a chat is created, and an unreadable one no longer leaves an empty
  chat behind; a `--chat` id camy.ai refuses no longer breaks `camy chat -c`,
  and `camy chats --all` and `-L` work as the footer suggests. A `-L` you pass
  now limits `camy chats list --json` too; without it, `--json` still returns
  every chat. See [Attachments](docs/chat.md#attachments).
- `camy chat` now cuts piped input past 2 MB at a line break and says so in
  the `stdin ·` note, except under `--json` or `-q`. See [stdin as
  context](docs/chat.md#stdin-as-context).
- Piped and accessible-mode replies leave out cards' layout lines and
  suggestion chips, and a turn waiting on a question reads `waiting for your
  answer`.
- Links in replies now print as `label (url)` under `NO_COLOR`, `CLICOLOR=0`
  or `--color never`, and a shortened table cell keeps its link and colour.
  See [Hyperlinks](docs/terminal.md#hyperlinks-osc-8).
- `--color always`, `FORCE_COLOR` and `CLICOLOR_FORCE` now give 16 colours
  when `TERM` is empty, and a 5-second wait before every command on a terminal
  that never answers colour queries, such as `docker run -t`, is gone. A camy
  command started as a background job, such as `camy status &`, no longer
  stops until you bring it back with `fg`. See
  [Color](docs/terminal.md#color).
- `camy --version` now prints one line on stdout, with the sandbox note on
  stderr, so `$(camy --version)` captures the version alone, and `camy mode`
  now prints on stdout. `-v` prints one line per request on stderr with its
  method, path, status, time and request id, `-q` also hides the notes printed
  before a command starts, and a bad flag is reported as a JSON error when
  `--json` is on the command line. See [Quiet
  mode](docs/scripting.md#quiet-mode).
- Steadies the full-screen app: a message after a stopped turn sends, even
  when the app had rejoined that turn, several slash commands no longer
  freeze or crash it, a message that can't go out says so and ↑ brings it
  back, and a `/queue` message a turn didn't use goes back to `/queue`.
  `/attach` now rejoins a turn that is still running, and `/capture` points
  you at `camy capture` instead of saving without asking. See [Slash
  commands](docs/chat.md#slash-commands).
- The full-screen app re-wraps the transcript when the window is resized,
  wraps a long URL instead of cutting it off, keeps the cursor in view and the
  masthead on screen when you scroll up, and shows the last exchange of the
  chat it resumes; Ctrl-D on an empty composer leaves. In `/approvals`, `a`
  shows each marked approval before one `y` approves them all.
- The full-screen app's status row and `camy status` no longer show `ctx 0%`
  before a turn has a reading, and in accessible mode Ctrl-C at the prompt
  leaves with the goodbye line, as Ctrl-D does.
- Camy's file changes on your computer keep a file's line endings and byte
  order mark and add no stray blank lines, the card says when only line
  endings or the final newline change, and a write that asks for a file mode
  camy can't read is refused, not written without it. See [Writes and
  edits](docs/local-bridge.md#writes-and-edits).
- The agent's local search finds matches after very long lines, names the
  dependency, build or hidden folders it skipped, searches inside one when
  pointed there, and reports no matches as an empty result, not a failure. It
  no longer reads a file with one huge line all at once, and local tools no
  longer refuse every file in a project because of its folder's name. See
  [Read-only scope](docs/local-bridge.md#read-only-scope).
- A local command that runs without asking at a terminal now also runs under
  `--no-input`, under `--json` and in pipes, instead of stopping the turn with
  exit 4, and `python3 -m <module>` can be trusted. `camy local trust remove`
  applies at once in every running session. See
  [Trust](docs/local-bridge.md#trust).
- The trace line for a call on your computer now names the file, search
  pattern or command, and says why a call failed. See [What the agent can
  touch](docs/local-bridge.md#what-the-agent-can-touch).
- Fixes sandboxed commands that all failed on a Linux machine where bubblewrap
  can't start or there is no `~/.cache`; on macOS, sandboxed commands can
  write to `/dev/null` and their own output again.
- `camy device forget` now stops this Mac's running agent and removes its
  LaunchAgent, so macOS no longer restarts it every 10 seconds after your next
  login; `--json` gains `launch_agent_removed`. `camy device install` now runs
  the profile it was installed for, `default` included. `camy stop` now holds
  even when the agent checks in with Camy just after it, and it and `camy
  device status` no longer treat an agent that crashed as running. On a Mac
  whose screen is locked, or where no one is logged in at the desktop, a
  device command that needs the Secure Enclave now says so instead of failing
  with an unexplained error. See [Take it back](docs/device.md#take-it-back).
- `camy auth login --with-key` now checks a pasted key before it replaces
  yours, so a bad key leaves you signed in, and `--scopes` refuses `-<scope>`
  for a scope it doesn't know instead of asking for the whole default set. See
  [`--with-key`](docs/authentication.md#--with-key-paste-an-existing-key).
- Says plainly when Camy or publishing isn't available in your country or
  region, instead of `blocked at the edge or forbidden` (still exit 1), and an
  error from camy.ai that already says to try again no longer repeats it.
- `camy api` with POST, PUT or PATCH no longer hangs on an open stdin that
  sends nothing. See [`camy
  api`](docs/scripting.md#camy-api-the-escape-hatch).
- `camy schedule` no longer lists a cron that runs at several hours a day as a
  single daily time, shows the next hourly run on the hour in half-hour and
  45-minute time zones, and keeps the typed time for a daily or weekly
  schedule whose first day skips it for daylight saving. At the limit on
  active schedules, `camy schedule create` and `resume` say so instead of
  `rate limited`, still with exit 5.
- `camy vm apps` now leaves out the workspace's own system processes; `--json`
  still lists them all. `camy vm exec` refuses a command over 4,096 characters
  with exit 2 before waking the workspace, a `camy vm shell` the workspace
  closed at its time limit points you at `camy vm shell` to open a new one,
  and no message suggests `camy vm provision` any more. See
  [Workspace](docs/workspace.md).
- `camy plan` and `camy status` now show the same credit balance, `camy
  status` counts the same approvals `camy approvals` lists, `camy capture`
  says where a capture went and prints its id, and `camy inbox show` finds an
  id from any `--tab` view. A `CAMY_API_KEY` that holds only whitespace no
  longer hides your stored key, and a form's number field asks again for `nan`
  or `inf`.
- `camy sweep` no longer offers `camy sweep set auto` as the next step, and
  `camy sweep set auto --dry-run` says the terminal can't make that move. See
  [Modes](docs/inbox.md#modes).
- `camy inbox reply --send` now refuses an empty reply, such as an editor
  emptied under `--edit` or a `--body` of only spaces, with exit 2, instead
  of queueing one that sends only the quoted message. See
  [Replying](docs/inbox.md#replying).
- Aliases now honour `--profile` and `--api-url` in their expansion. See
  [Aliases](docs/configuration.md#aliases).
- Ctrl-C in the editor that `--edit` opens goes to the editor, and Ctrl-C
  during `camy download`, `camy device enroll` or a `camy auth login` that
  links this Mac removes the partly written file. Ctrl-C at a prompt that
  hides what you type, such as the key prompt of `camy auth login
  --with-key`, no longer leaves your terminal that way. `camy download` saves
  files readable only by you, and a download that fails leaves an existing
  file as it was.
- `camy update --check` now works on Homebrew and npm installs and names their
  update command, as does the daily new-version note. The note tries again an
  hour after a failed check instead of going quiet for a day, and stays quiet
  after a successful `camy update` instead of naming the version just
  installed. A camy placed in `/opt/homebrew/bin` by other means is no longer
  taken for a Homebrew install. A new version that doesn't start is now
  rolled back even after an earlier update stopped part-way. See
  [Updating](docs/installation.md#updating).

**Security**

- Hardens how camy handles your key, the files it writes and the commands Camy
  runs on your computer, and masks more secrets in what it shows. A few local
  commands that ran on their own now ask first. Updating is recommended.

## 1.0.5 — 2026-09-27

This update keeps a linked Mac working on its own, makes sign-in, keys and
exit codes more predictable, has chats, mail and approvals report what
really happened, and adds a command that logs your cloud computer out of
every site.

**New**

- Adds `camy vm logout-everywhere`: forgets the logins Camy saved, clears
  your cloud computer's browser and stops its running tasks, after a
  confirmation and a fresh code. It runs only with the key `camy auth login`
  gave this terminal; sign in again first if you used `--code` before this
  update. See [camy vm logout-everywhere](docs/workspace.md#camy-vm-logout-everywhere).
- Adds `camy inbox trash` and `camy inbox unread`, each taking several ids;
  `camy inbox restore` brings trashed mail back. See
  [Batch actions](docs/inbox.md#batch-actions).
- `camy chats search`, `camy runs search` and `camy jobs search` now page
  with `--offset`; a full page names the offset for the next one. See
  [Searching past chats](docs/chat.md#searching-past-chats).
- A linked Mac now renews its own credential before it expires, including
  while the link is paused, and `camy device status` says by when to resume
  a Mac that cannot. See [Status](docs/device.md#status).
- Adds `--no-gpu` to `camy vm resize`; a resize without `--gpu` or
  `--no-gpu` now keeps the GPU add-on as it is. `camy vm sizes` marks the
  sizes your plan cannot run. See [camy vm resize](docs/workspace.md#camy-vm-resize).
- `camy keys list` now shows when each key expires, and in `camy approvals`
  a checkout hold names the amount and the merchant.

**Improvements**

- A linked Mac keeps its grants when its credential expires or its
  connection drops; only a revoke clears them. One resident agent runs per
  profile, and `camy device forget` also revokes the link on camy.ai. See
  [Run it in the background](docs/device.md#run-it-in-the-background).
- Fixes commands a linked Mac refused instead of running: read-only
  commands run under a `shell.read` grant, a grant on a single file covers
  that file, `~` means this Mac's home wherever the grant was added, and a
  clock slightly behind no longer refuses approved writes. See
  [Grant and remove scopes](docs/device.md#grant-and-remove-scopes).
- `camy auth login` now asks for the `workspace:exec` scope that
  `camy vm exec` and `camy vm shell` need. A key from an earlier version is
  refused with a hint to sign in again, so run `camy auth login` after
  updating if you use either. See
  [The workspace:exec scope](docs/workspace.md#the-workspaceexec-scope).
- `camy auth login` now retires the key this terminal held before, only
  once the new one works, and never a key you pasted or set in
  `CAMY_API_KEY`. `--code` completes a first sign-in, which used to end in
  exit 3, and a sign-in stops waiting the moment it is no longer pending.
  See [Signing in again](docs/authentication.md#signing-in-again).
- `camy keys rotate` on this terminal's own key stores the replacement, so
  the terminal keeps working, and `camy auth logout --revoke` says whether
  it revoked. See [camy keys](docs/authentication.md#camy-keys).
- Tells you why camy.ai refused a key: expired or revoked says which, a
  missing scope names the `--scopes +scope` that adds it, and a rate limit
  longer than two minutes fails at once with exit 5 and names the wait. See
  [Not signed in (exit 3)](docs/troubleshooting.md#not-signed-in-exit-3).
- `camy vm exec` now finishes waking a stopped workspace, or waits out one
  already starting or stopping, before your command runs, so the command
  gets its whole `--timeout`; `--no-wake` still exits 7. With no workspace
  it exits 255 instead of 7, and camy's own timeout exits 255 with
  `timed out after Ns` instead of 124. See
  [Exit codes](docs/workspace.md#exit-codes).
- `camy vm exec` runs a single argument after `--` as a shell line, passes
  piped standard output through byte for byte, and says when the workspace
  cut the output short. `camy vm shell` explains a refusal as it connects
  rather than showing a raw connection error, and typed or pasted input no
  longer closes the shell. See [camy vm exec](docs/workspace.md#camy-vm-exec).
- `camy canvas sites`, `camy canvas versions` and `camy vm apps` no longer
  start a stopped workspace just to list it; they exit 7 and point at
  `camy vm start`. `canvas publish` and `rollback` say before confirming
  that they start the workspace, then wait for it. See
  [Sites and your workspace](docs/canvas.md#sites-and-your-workspace).
- `camy connectors check` on a server whose tools changed now exits 2 and
  points at `review`, and `review` under `--json` or `--no-input` approves
  only with the new `--yes` or with `--force`. `check`, `pause` and
  `resume` say what the connection is, and the CHECKED column shows when
  Camy last heard from it. See
  [Review what changed](docs/connectors.md#review-what-changed).
- `camy chat` ends a failed connection on its real exit code instead of 1:
  3 for a refused key, 5 for a rate refusal or the connection cap, 7 when
  camy.ai is unavailable; after a camy.ai restart it redials and resends.
  `--tier` takes only `agent` or `quick`. See
  [After the turn](docs/chat.md#after-the-turn).
- `camy chat` picks up where the stream left off after a reconnect
  mid-turn, and says so if part of the reply may be missing. A turn that
  finished while the connection was down no longer hangs, a failed tool is
  never shown as a success, and a turn stopped for lack of credits says so
  and exits 6.
- A headless `camy chat` no longer waits on an open stdin that sends
  nothing, `--attach` accepts `.txt`, `.md` and `.csv` files, and piped
  input past 64 KB is sent as a `stdin.txt` attachment, except in a
  `--temp` chat, which never uploads piped input on its own. See
  [stdin as context](docs/chat.md#stdin-as-context).
- Ctrl-\ now exits 131 instead of dumping the runtime; `CAMY_DEBUG_DUMP=1`
  keeps the dump. See [Exit codes](docs/exit-codes.md#131--quit).
- Under `--json`, a `checkpoint` event carries the tool, risk, prompt,
  command, expiry and any choices, a `tool_call` event carries its
  parameter, a replayed card is reported once as `checkpoint_replayed`, and
  other chats' events are left out. See
  [NDJSON for streams](docs/scripting.md#ndjson-for-streams).
- Fixes approvals reported as yours when the app, the web or another
  terminal settled them first. Typing a choice's number, id or label now
  picks it, `approve` on an agent's question points at `answer`, a decision
  that lives on the web says so, and `approve --wait` no longer asks again
  for a card you just approved. See [Deciding](docs/approvals.md#deciding).
- `camy inbox unsnooze` and `restore` find a short id among your snoozed,
  archived and trashed mail, and one that matches none is a usage error.
  The list footer counts the view you asked for and names the next cursor,
  sent rows name who they went to, and `inbox show` says read or unread.
  See [The unified inbox](docs/inbox.md#the-unified-inbox).
- `camy inbox reply` says so when camy.ai did not actually queue a
  scheduled reply, and `camy inbox send` tells you to check before retrying
  a send that may have gone out. See [Replying](docs/inbox.md#replying).
- `camy integrations connect` waits for your sign-in to land and stops at
  once when it grants fewer permissions than Camy needs; a broken account
  reads `reconnect`, and a broken Microsoft sign-in names the service. See
  [Integrations](docs/automation.md#integrations).
- Steadies the full-screen app: a steer is never sent twice, the connection
  heals in place and stops retrying a refused key, and the terminal is
  restored when Camy disconnects this computer.
- `camy schedule` shows a paused job's schedule as paused, `camy tasks`
  never shows a done task as overdue, `camy jobs show` shows fractional
  credits, `camy plan` reads the daily allowance in credits, and
  `camy status` no longer counts approvals already running as waiting.
- `camy sweep restore --items` with no ids is refused instead of restoring
  the whole batch, `camy feed act` can press card actions it used to
  refuse, and `camy webhooks dead-letters` says when there are more than it
  shows. See
  [Reviewing and restoring](docs/inbox.md#reviewing-and-restoring).

**Security**

- Hardens how a linked Mac enforces the rules and grants you set, how
  sign-in keys are issued and revoked, how the workspace terminal connects,
  and how approval cards are shown. Updating is recommended.

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
