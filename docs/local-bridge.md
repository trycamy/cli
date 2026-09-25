# The local bridge

The local bridge is what lets the agent work on this machine during a chat.
With it on, the agent can read files, and — if you let it — write and edit
files and run commands, inside the project directory you started `camy` in.
It turns on automatically for a chat run from inside a project.

Two flags scope it down for one session:

```bash
camy --read-only    # reads only: no commands, no writes or edits
camy --no-local     # off entirely: no local tools at all
```

While the bridge is on, a plain turn runs against this machine. `--cloud`
sends the turn to your workspace instead — the cloud computer described in
[Workspace](workspace.md).

Every write and edit goes through an approval card, the mechanism described
in [Approvals](approvals.md), and so does every command except a verified
read or one you trusted. The bridge does not change who approves what; it
changes where the approved action runs.

## What the agent can touch

Nine tools. The three file-reading tools are always on when the bridge is
on, and never prompt. The write, edit and command tools, plus the
background-job tools, are on by default too. `write_file`, `edit_file` and
`job_cancel` draw a card every time. `run_command` draws one except in the
two cases below. `job_status` and `job_output` run without asking.

| Tool | What it does | Approval |
|---|---|---|
| `read_file` | Read one file, a page or a stretch of lines at a time | Automatic |
| `list_dir` | List one directory, or find files by name below it | Automatic |
| `grep` | Search file contents by regular expression | Automatic |
| `run_command` | Run a program, with no shell, in the foreground or the background | Card, except in the two cases below |
| `write_file` | Create or overwrite a file | Card, every time |
| `edit_file` | Change part of an existing file with search-and-replace blocks | Card, every time |
| `job_status`, `job_output` | Check on a background command, or read its output | Automatic |
| `job_cancel` | Stop a background command | Card, every time |

You answer a `run_command` card yourself, except in two cases where the CLI
answers for you:

- **A command you pre-trusted.** See [Trust](#trust).
- **A pure read.** The CLI checks on its own, against its own copy of the
  read-only command table, that the command only reads and stays inside
  your project root (`ls`, `git status`, `grep`, `sed -n`, a `describe-` or
  `list-` call to `aws`, `gh pr view`, and similar). A command it verifies
  this way runs without asking when camy.ai sends it with no card, or with a
  card marked as a read on a turn it has marked eligible for auto-answering;
  the CLI then answers the card and notes
  `auto-approved — read-only — ran without asking` in the transcript.
  Otherwise you get an ordinary card, even for `ls`. Either way it runs on
  the CLI's own verdict, never on the server's say-so alone.

`run_command` is killed if it outlives its timeout: two minutes unless the
call asks for longer, and never more than 30 minutes. A longer request is
cut to 30 minutes, and the result tells the agent so. A background command
has no timeout. A foreground command's stdout and stderr are each captured
up to 1 MB and then truncated, with the result marked as truncated.

To stop a command while it runs, press `esc` in the camy app (`camy`, or
`camy --inline`) while the turn is busy. It stops every command running on
your machine for that session and asks camy.ai to stop the turn; when it
stopped any, the line it prints says how many. Under `camy chat`, press
`ctrl-c` twice within two seconds; a single `ctrl-c` detaches from the turn
but waits for a running local command to finish, so its result still
reaches the turn. Neither stops a background command; ask the agent to
cancel it.

### Writes and edits

`edit_file` changes part of a file: each block names the exact text to find
and what to put in its place, and either every block applies or none does.
Its approval card shows the diff the edit would make against the copy on
disk, the same way a `write_file` card does; see
[The approval card](approvals.md#the-approval-card).

Before `write_file` or `edit_file` replaces a file, camy keeps a copy of
what was there, under your profile's state directory, never in your project
or its git history. A file the write creates is recorded too. Each write
tells the agent whether its copy was kept; a file over 16 MB is written
without one. Copies are kept for 14 days and up to 256 MB per project,
oldest dropped first. What a `run_command` changes is not copied by
default.

All nine are chat-agent tool calls, reachable only from a `camy` invocation
that is holding a live chat connection: the full-screen app,
[`camy chat`](reference/camy_chat.md),
[`camy chat attach`](reference/camy_chat_attach.md), and an
[`approvals approve --wait`](reference/camy_approvals_approve.md) or
`approvals answer --wait` that re-joins a paused turn.

There is no `camy local read` or `camy local run` — the CLI has no
standalone way to invoke them directly.

## The project root

The project root is the directory you launched `camy` from, with symlinks
resolved. It never moves up to an enclosing repository. Everything the
bridge can reach lives under that directory, so start `camy` in the project
you want it to see: run it from your home directory and your home directory
is the root. `camy local trust list` prints the root it resolved.

When a chat connects, camy tells the agent where it is running, so the agent
starts in the right place instead of hunting for the project with `pwd`,
`ls`, or `find`. [What the server sees](#what-the-server-sees) lists what
that includes.

Every path the tools touch — a `read_file`, `list_dir`, or `grep` target,
`run_command`'s working directory, a `write_file` or `edit_file`
destination — is checked against that root and against a fixed denylist of
secret-shaped paths before anything happens. See
[Read-only scope](#read-only-scope) and
[The secret-path denylist](#the-secret-path-denylist).

## Turning it down, or off

The bridge is session-local. It is registered fresh on each chat connection
from your current flags and environment, so a scoping flag lasts exactly one
invocation.

| Flag | Env var | Effect |
|---|---|---|
| `--no-local` | `CAMY_NO_LOCAL=1` | Disables the bridge entirely for this session. No read tools, no write tools — the agent cannot touch this machine at all. |
| `--read-only` | `CAMY_LOCAL_READONLY=1` | Keeps the read tools; turns off `run_command`, `write_file`, and `edit_file`, and the background-job tools with them, for this session. |
| `--sandbox off\|observe\|enforce` | `CAMY_LOCAL_SANDBOX` | How `run_command` is confined by the operating system, this session only. `observe` runs commands unconfined and reports that; `enforce` lets a command write only inside the project root, the system temp directory, and your user cache directory, through Seatbelt on macOS and bubblewrap on Linux, and falls back to `observe` where the sandbox tool is missing. Left unset, it is `observe` until 6 October 2026 (00:00 UTC) and `enforce` from then on wherever the OS can fully enforce it, although the flag's own help text still says `default observe`; see [The boundary, and the sandbox](#the-boundary-and-the-sandbox). `camy --version` prints the posture, and `camy --version --json` carries it as `local_sandbox`. |
| `--cloud` | `CAMY_CLOUD=1` | Defaults a plain turn to your workspace instead of this machine. Does **not** turn the bridge off — the tools stay available to the agent if it reaches for them — but it does stop `AGENTS.md`/`CLAUDE.md` discovery (see [Project instructions](#project-instructions)). |
| `--no-project-instructions` | `CAMY_NO_PROJECT_INSTRUCTIONS=1` | Skips `AGENTS.md`/`CLAUDE.md` discovery, independent of `--cloud`. |

Either form works:

```bash
CAMY_NO_LOCAL=1 camy
```

`--no-local`, `--read-only`, and the machine output modes (`--json`, `--jq`,
`--template`) are the only things that remove tools from a session. Every
other flag above changes a default or a discovery step, not what is
registered.

`--local-write` is deprecated and does nothing. Writes are on by default.

## Trust

Trust grants are the only bridge setting that outlives an invocation.
`camy local trust` manages this project's auto-run grants; see
[camy local](reference/camy_local.md) and
[camy local trust](reference/camy_local_trust.md) for the full flag
reference.

| Command | Purpose |
|---|---|
| [`camy local trust list [--json]`](reference/camy_local_trust_list.md) | Show this project's trusted commands and paths |
| [`camy local trust add [--prefix] -- COMMAND [ARGS...]`](reference/camy_local_trust_add.md) | Trust an exact command, or every command starting with it |
| [`camy local trust remove -- COMMAND [ARGS...]`](reference/camy_local_trust_remove.md) | Revoke a trusted command |
| [`camy local trust add-path PATH`](reference/camy_local_trust_add-path.md) | Reserve a `write_file` target path for a future write carve-out |
| [`camy local trust remove-path PATH`](reference/camy_local_trust_remove-path.md) | Revoke a reserved path |

Bare `camy local` and `camy local trust` print help and do nothing else.

**What a grant does.**

```bash
camy local trust add -- npm test
```

When the agent proposes exactly the command you trusted, and the server has
marked the turn eligible for auto-answering, the CLI answers its own
approval card — no keystroke needed. The server withholds that eligibility
on a turn whose content it does not fully trust, in which case even a
trusted command draws a card.

The server still mints the approval every time. Trust only decides whether
the CLI answers it itself instead of waiting on you; the round trip is never
skipped, only the keystroke.

**What `a` records.** Pressing `a` on a `run_command` card grants that exact
command, never a prefix, in this project, and it appears in
`camy local trust list` alongside the grants you added by hand. Beside it,
`a` records a family grant for commands of the same shape: the same
program, the same leading subcommands, and the same flags with the same
values. Any other argument must be one you already approved, or a path
inside the project.

A family grant is dated: it lapses 24 hours after you last pressed `a` for
that family, and drops off `camy local trust list` once it has. It answers a
card for you only while this machine confines commands
(`--sandbox enforce`, fully supported here) and keeps copies it could undo a
command with. camy does not copy what commands change by default, so in
this release the exact grant is the one that saves you the keystroke.

```bash
camy local trust list --json
```

```json
{
  "commands": [
    {
      "argv": ["npm", "run", "build"],
      "granted_at": "2026-09-25T14:02:11Z",
      "kind": "exact"
    },
    {
      "argv": ["npm", "run", "build"],
      "expires_at": "2026-09-26T14:02:11Z",
      "granted_at": "2026-09-25T14:02:11Z",
      "id": "9f3a...",
      "kind": "pattern",
      "scope": {"bin": "npm", "flags": null, "verbs": ["run", "build"]},
      "short_id": "gr_9f3a"
    }
  ],
  "paths": null,
  "root": "/Users/you/src/app"
}
```

The human list prints both rows the same way, as `$ npm run build`; `kind`
tells them apart, and a family grant carries its `scope`, `expires_at`, and
`id`.

**What `--prefix` widens.**

```bash
camy local trust add --prefix -- npm run
```

That trusts `npm run <anything>`. A bare binary name with no arguments —
`camy local trust add --prefix -- npm` — is the broadest grant this surface
can make: it auto-runs every invocation of `npm` in the project, any
arguments at all, not just the subcommand you had in mind.

The CLI prints a caution line for any `--prefix` grant, and a stronger one
for the bare-binary case. Prefer exact grants.

A grant you add with `camy local trust add` matches argv byte for byte: the
exact argv, or, if you granted it with `--prefix`, any argv that starts with
it. There is no fuzzy or normalized matching for those. The family grant `a`
records matches on a normalized shape instead: the program's name without
its directory, lowercased (so `/usr/bin/NPM` counts as `npm`), its leading
subcommands, and the same set of flag names in any order, with the value
rules described above.

**How grants are scoped.** Grants are per project, keyed by the project's
canonicalized root path (symlinks resolved). Moving or renaming the project
directory starts a fresh, empty set of grants for the new path — the old
grants stay attached to the old one. Two symlinked paths to the same
directory resolve to the same real path, so they share one set.

**How grants are recorded.** They live in a state file scoped to your
profile, written atomically with restrictive permissions.
[`camy config list`](reference/camy_config_list.md) has no key for any of
this: the local bridge is controlled entirely by flags, environment
variables, and this trust store, never by `config.toml`.

A missing or unreadable file is treated as no grants — always prompt — never
as trust everything.

**How grants are revoked.** `camy local trust remove` matches the exact argv
only; there is no shortcut for revoking a prefix grant. Retype the exact
argv you originally granted, `--prefix` grants included. `remove` drops
every row whose recorded argv equals the one you type. A family grant shows
the last command you pressed `a` on for that family, so remove it by typing
that argv; check `camy local trust list` first.

**What `add-path` does today.** It records a path for a future write
carve-out. Writes still prompt every time in this release regardless of an
`add-path` grant — only `run_command` can ever auto-run from a trust grant,
never `write_file` or `edit_file`.

**What can never be trusted.** `trust add` refuses to grant a command that
trips the [destructive-command floor](#the-destructive-command-guard), at
grant time and not just at run time:

```bash
camy local trust add -- rm -rf /
```

That exits 2, refusing to persist it. A script file's contents are invisible
to any static check, so an invocation like `bash deploy.sh` or `python3
manage.py migrate` can never be granted "always allow" either — it runs on
an interactive approval every time, never silently from a stale grant.

## Read-only scope

Every read target passes the same project-root boundary as writes and
commands: a path that resolves outside the root, directly or through a
symlink, is refused, and so is anything matching the secret-path denylist
below. Within that boundary:

- `read_file` refuses a directory target, and refuses anything that isn't a
  regular file. One call returns up to 200 KB by default and never more
  than 1 MB; a larger file is read in pages, from a byte offset or as a
  stretch of lines, and a negative start line counts back from the end.
- `list_dir` lists one directory, or walks up to eight levels below it with
  an include or exclude glob (`**/*.tsx`) to find files by name. It caps
  the number of entries it returns at 1,000.
- `grep` skips any single file above 5 MB. An invalid regular expression is
  refused.
- A `grep` or a `list_dir` walk skips common build, dependency, and cache
  directories (`.git`, `node_modules`, `vendor`, `.venv`, `dist`, `build`,
  `.cache`, `.pytest_cache`, and similar), and skips hidden directories
  other than `.github`, `.circleci`, and `.claude` unless the call asks to
  include them.

Any line that looks like a secret — an AWS secret key pattern, a
`-----BEGIN ... KEY-----` block — is redacted before it reaches the agent,
even inside a file the denylist did not refuse. This applies to `read_file`
content (every page of it), `grep` match text, and the captured output of
`run_command` and of background commands alike.

## The secret-path denylist

A fixed set of paths is never reachable by the file tools. It is checked
case-insensitively, on every segment of a resolved path, and applies to a
`read_file`, `list_dir`, or `grep` target, a `write_file` or `edit_file`
destination, and `run_command`'s working directory.

It covers a brand-new file exactly as it covers an existing one: a fresh
`.env` `write_file` call is refused just as an existing one would be
read-refused.

| Category | Paths |
|---|---|
| Credential and key directories | `.ssh/`, `.aws/`, `.gnupg/`, `.kube/`, `.docker/`, and directories named `secrets`, `credentials`, `certs` |
| Specific credential files | `.env` and `.env.*`, `.netrc`, `.npmrc`, `.git-credentials`, `.pypirc`, `.pgpass`, `.dockercfg`, `.htpasswd`, `.s3cfg`, `.aws/credentials`, and `.git/config` — only that file, not the whole `.git` tree. The committed-safe siblings `.env.example`, `.env.sample`, `.env.template`, `.env.dist`, and `.env.defaults` are exempt. |
| Private keys | By name or extension: `id_*`, `*_rsa`, `*_ed25519`, `.pem`, `.key`, `.p12`, `.pfx`, `.jks`, `.keystore`, `.ppk`. A public key (`*.pub`) is exempt — it is not a secret. |
| Secret-sounding data files | A narrower fuzzy match on ordinary data files whose name merely contains `secret`, `credential`, or `passwd` — but not on common source or doc file extensions, so `src/credentials.ts` and `docs/secrets.md` are not blocked by this rule alone. |
| macOS and browser credential stores | Keychain files, cookie stores, the Messages and Mail folders, the browser profile folders of Chrome, Firefox, Edge, Brave, and Vivaldi, Safari's cookie store, and browser password and autofill databases wherever they sit (`Login Data`, `Web Data`, `key4.db`, `logins.json`, and similar) |
| System credential files | `/etc/shadow`, `/etc/gshadow`, `/etc/sudoers` |
| camy's own state directory | Everything under it, across every profile: the trust store, the stored credential fallback file, and the copies kept of files a write replaced. Unreadable by the bridge's own tools |

`run_command`'s arguments other than its working directory are not
re-resolved against the boundary once you approve the command — the argv
runs exactly as the card showed it. They are inspected in two narrower
places:

- The destructive guard refuses a command that pairs a read verb (`cat`,
  `head`, `grep`, `cp`, `rsync`, `curl`, `wget`, `openssl`, `jq`, `tar`, and
  similar, anywhere in the argv) with a secret-shaped path. See
  [The destructive-command guard](#the-destructive-command-guard).
- The read-only auto-run check resolves every path-shaped argument against
  the project root and this denylist, demoting anything that escapes to an
  ordinary approval card rather than auto-running it.

## The destructive-command guard

Separately from approvals and trust, a fixed floor refuses certain command
shapes outright. The design principle behind it: a sandbox is a blast-radius
control, not a consent control. Auto-run must never override this tier, and
neither can a human typing "always allow" on a card. Examples of what it
refuses:

- `sudo`, in any form
- `rm -rf` (or equivalent flag combinations) against a root-ish target —
  `/`, `~`, `$HOME`, a bare `.` or `..`, a whole top-level home subfolder,
  or no target at all
- `git push --force` (and `-f`, `--force-with-lease`) and several other git
  shapes that inject configuration or a remote helper
- `mkfs`, `diskutil erase`, `dd of=/dev/*`
- `chmod -R 777` against a root-ish target
- macOS Keychain, Gatekeeper, and SIP tools (`security`, `spctl`, `csrutil`)
- an interpreter running inline code rather than a file — `python -c`,
  `node -e`, `ruby -e`, `osascript -e`, `pwsh -Command` or
  `-EncodedCommand` (including abbreviations such as `-enc`), and similar —
  refused because this floor cannot vet arbitrary program text the way it
  can inspect an argv
- a shell `-c` script containing a fork bomb, a pipe into a shell
  interpreter — `| sh`, `| bash`, `| /bin/bash`, and the same shapes written
  with `|&`, whatever command produces the piped bytes — or an `rm` with
  both a recursive-force flag and a root-ish or missing target
- a direct read of a secret-shaped path via a plain read command (`cat
  ~/.ssh/id_rsa` and similar), even without going through `read_file`
- a read of a Mail, Messages, cookie, or browser credential store through
  `sqlite3`, `plutil`, `strings`, or `defaults`
  (`defaults read com.apple.mail`, `defaults read -app Safari`, and similar)
- a wrapper — `env`, `nice`, `timeout`, `xargs`, and similar — around any of
  the above; the guard looks through the wrapper to the command it runs

This floor is consulted at every point where a command could gain the right
to run, all of them on this machine: when a command is about to run, when a
trust grant is created, and when the keyboard shortcut that would grant one
is offered or typed.

It is checked again when the CLI decides whether to auto-answer a card the
server marked as auto-approvable, and once more on the argv the server
actually delivers, right before the command runs. A prior "always allow" or
a saved grant cannot override it.

It is a floor, not a proof: a sufficiently obfuscated command can still slip
past it, the same admitted limit the server's own scanners carry.

Running a script file — `bash deploy.sh`, `python3 manage.py migrate` — is
treated differently from inline code. It is ordinary dev workflow, so it is
not refused outright. It can never be trusted or auto-run, as
[Trust](#trust) describes.

### The boundary, and the sandbox

The project-root boundary scopes the paths the tools resolve: a read target,
a write destination, a command's working directory. On its own it does not
confine a command once you approve it: `run_command` starts a real process
under your user account, and the floor above is a blast-radius limit, not a
container.

`--sandbox enforce` (or `CAMY_LOCAL_SANDBOX=enforce`) adds an operating
system boundary on top, through Seatbelt on macOS and bubblewrap (`bwrap`,
which must be installed) on Linux. Under `enforce` a command can write only
inside the project root, the system temp directory, and your user cache
directory. On macOS it also cannot reach container-runtime sockets (Docker,
Podman, Colima). Other reads and network access are not confined. `observe`
leaves commands unconfined.

`enforce` falls back to `observe` when the sandbox tool is missing:
`sandbox-exec` on macOS, `bwrap` on Linux. On macOS `camy --version` names
the reason; on Linux it does not. On Linux camy counts a machine as able to
enforce whenever `bwrap` is installed, so if `bwrap` is present but cannot
run, for example because unprivileged user namespaces are disabled, commands
under `enforce` fail rather than run unconfined.

`camy --version` prints the posture in effect, and `camy --version --json`
carries it as `local_sandbox`. A command card states it only once per
connection, so the first command card you actually see may not carry it if
an earlier one was answered for you. `camy --version` is the dependable
place to read it.

Left unset, the dial is `observe` until 6 October 2026 (00:00 UTC). From
that date an unset dial means `enforce` on any machine that can fully
enforce it, and on such a machine camy.ai can move an unset session to
`enforce` sooner. The `--sandbox` flag's own help text, and the reference
pages that list it, still say `default observe`; the date-based default
described here is what camy does. Nothing camy.ai sends can move the dial
toward `off`, and an explicit `--sandbox observe` or
`CAMY_LOCAL_SANDBOX=observe` always stays `observe`.

The CLI never answers a card for you that asks to loosen the sandbox for a
command `enforce` blocked, whether by letting it write to more paths or by
running it unconfined once, even for a command you trusted or one that only
reads. That rule covers the card only. The widening itself arrives from
camy.ai with the command when it runs, and the CLI does not tie it to the
card you answered. The CLI does drop any widening that names `/`, your home
directory, or a secret-shaped path.

A command can also be started in the background: it keeps running after
the turn that started it ends, and the approval card says so before you
answer. Ask in the chat for a background job's status or output, or to
cancel it. Under `enforce` a background command is refused; run it in the
foreground, or under `observe`, where it runs unconfined.

The child process does get a trimmed environment. Only `PATH`, `HOME`,
`LANG`, `TERM`, `TMPDIR`, and `SHELL` are passed through, so camy's own
credentials are never visible to a command it runs.

## Project instructions

If an `AGENTS.md` or `CLAUDE.md` file exists at the project root, the bridge
reads it on each chat connection and sends its content to the server as part
of starting the chat, so the agent has your project's own instructions in
context. A mid-session reconnect re-reads the file.

Your own standing instructions come along too: a `~/.camy/AGENTS.md` holds
the conventions you want in every project, and it is sent alongside the
project's file, each labeled as what it is. The project's file is the more
specific of the two, and where the two disagree the agent is asked to say
which one it followed. At the project root `AGENTS.md` is preferred and
`CLAUDE.md` is read only when there is no `AGENTS.md`; only the root is
checked, not subdirectories, and the files are capped at 16 KB together,
with your personal file trimmed first.

Discovery fails closed rather than take a risk: a symlink — even one that
points back inside the project — or a hard-linked file is refused rather
than read. When a file is read, the CLI discloses it once per process, on
stderr, naming the file; the content itself is never echoed to your
terminal.

`--no-project-instructions` turns this off on its own. `--cloud` turns it
off too, even though the read tools stay registered, on the reasoning that a
turn explicitly sent to your workspace should not also read this machine's
disk. `--no-local` and the machine output modes (`--json`, `--jq`,
`--template`) stop it as well — there is no bridge to read the file with.

## What the server sees

The local bridge makes no network calls of its own. Every read, write, and
command is pure local filesystem or process work. The only network surface
it touches is the same chat connection every `camy chat` turn already opens.
On that connection:

- The CLI tells the server which tools are available for this session — read
  tools always, write and command tools only in write mode — and whether the
  turn's default workspace is local or cloud.
- Unless the turn defaults to the cloud (`--cloud`), it also says where it
  is running: the project root; when that sits in a git repository, the
  repository's root, branch, `origin` remote with any embedded credential
  removed, and whether the tree has uncommitted or untracked changes; the
  operating system, CPU architecture, and shell name; and the names of up to
  40 entries at the top of the project root. Names only, never file
  contents.
- On the same terms it reports this machine's sandbox posture (the dial,
  and whether the OS can enforce it). Whether it keeps copies of what a
  write replaces is reported on every session that has the write tools,
  `--cloud` included.
- Project instructions, if discovered, are sent as part of starting the
  chat, as data for the model to read rather than as instructions to the
  model itself.
- Each tool call the agent wants to run arrives as a request over that
  connection; the CLI answers with the tool's result, or a decline, on the
  same connection.
- If the connection drops before a result reaches the server, that result is
  kept for up to an hour so the next connection can deliver it, long enough
  for a command that ran to its 30-minute limit. Under `camy chat` and
  `camy chat attach` it is also written to a file under your profile's state
  directory, so a fresh process can replay it.
- The server never receives a standing credential or file access of its own.
  It can only ask, once per call, for a specific tool with specific
  arguments, and every write or command call must clear an approval, or for
  a read-only command the CLI's own check, before the CLI will run it.

A write or command call the server sends is refused unless it matches
something this CLI process itself witnessed being approved: your own `y` or
`a` on a card, a trust-store auto-run, a read-only command the CLI verified
itself (with or without a card), `camy approvals approve --wait`, or a live
re-confirm dialog for an approval made in a different open session.

A server that skips straight to requesting a tool call, without a real
approval behind it, is refused here rather than merely delayed.

[Approvals](approvals.md) owns the approval model itself: how a card is
presented, what `y`, `a`, and `n` do, the 120-second timeout, and headless
(`--no-input`) behavior. All of it applies to local-bridge cards exactly as
it does to any other approval.

No flag answers every approval automatically. `--force` skips a different,
unrelated class of destructive-operation prompts elsewhere in the CLI; it
does not touch a local-bridge approval card.
