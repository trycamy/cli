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
  your project root (`ls`, `git status`, `grep`, `sed -n`, most `describe-`
  and `list-` calls to `aws`, `gh pr view`, and similar). It looks at the
  command's options and arguments and at which program would actually run,
  so a command that only looks read-only gets a card: one that could write
  a file, start another program, reach outside the project, or hand back a
  credential, and a program that isn't the system's own. A command it
  verifies this way runs without asking when camy.ai sends it with no card,
  or with a card marked as a read on a turn it has marked eligible for
  auto-answering; the CLI then answers the card and notes
  `auto-approved — read-only — ran without asking` in the transcript.
  Otherwise you get an ordinary card, even for `ls`. Either way it runs on
  the CLI's own verdict, never on the server's say-so alone.

A command that runs without asking at a terminal also runs without asking
under `--no-input` and with no terminal attached, instead of stopping the
turn with exit 4.

A git read, such as `git status`, `git diff`, or `git log`, runs with the
repository's own hooks, filters, external diff tools, and credential
helpers turned off, whether it ran on its own or you approved its card. A
diff comes back as plain text even if you use an external diff tool, and
`git remote show` can't use your credential helper.

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
reaches the turn. A command you stop still sends its result to camy.ai, so
the turn isn't left waiting on it. Neither stops a background command; ask
the agent to cancel it.

In the transcript, each call on your machine shows as a trace line that
names the file, search pattern, or command it acted on, and a call that
failed says `failed:` and why.

### Writes and edits

`edit_file` changes part of a file: each block names the exact text to find
and what to put in its place, and either every block applies or none does.
Its approval card shows the diff the edit would make against the copy on
disk, the same way a `write_file` card does; see
[The approval card](approvals.md#the-approval-card).

A rewrite keeps the file's own conventions: when every line break in the
existing file is CRLF and the new content has none, it is written with
CRLF, and a byte order mark the file starts with is kept. The card diffs
the bytes that will land, so adding one line to a CRLF file shows as one
added line. An edit whose search text matched only loosely, for example
ignoring trailing whitespace, gives its new lines the line ending the
replaced lines share and adds no stray blank line.

A `write_file` that asks for a file mode camy can't read is refused before
anything is written, rather than written with the default mode; a mode is
an octal string such as `"0755"`. A mode that sets the setuid or setgid
bit is refused too.

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

With several camy sessions open on one account, each one runs local tools
only for the chats it started or attached to, and for the chat on its
screen. A request for any other chat is refused without running anything.

There is no `camy local read` or `camy local run` — the CLI has no
standalone way to invoke them directly.

## The project root

The project root is the directory you launched `camy` from, with symlinks
resolved. It never moves up to an enclosing repository. Everything the
bridge can reach lives under that directory, so start `camy` in the project
you want it to see. `camy local trust list` prints the root it resolved.

camy asks before it works in a folder that holds your shell's startup
files or Camy's own settings: your home folder, any folder above it, a
folder with a `.zshrc`, `.bashrc`, `.profile`, or similar of its own, or a
folder that holds Camy's own config, state, or cache folder (for example
`~/.config` or `~/.cache`). At a terminal it says what the folder holds and
asks once per run, before the full-screen app draws its first screen:

```text
! ~ holds your shell's startup files and Camy's own settings — Camy could read or change them from here.
Work in this folder anyway? [y/N]
```

In a folder that holds only Camy's own folders, such as `~/.config`, the
line reads `~/.config holds Camy's own settings and sign-in key — Camy could
read or change them from here.`

Only `y` or `yes` goes ahead. Under `--no-input`, or with no terminal to
ask on, camy says the folder holds them, so Camy is not touching this
computer on this run, and the chat goes on without local tools. Start
`camy` from a project folder to use them.

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
| `--sandbox off\|observe\|enforce` | `CAMY_LOCAL_SANDBOX` | How `run_command` is confined by the operating system, this session only. `observe` runs commands unconfined and reports that; `enforce` lets a command write only inside the project root, a temp directory, and your user cache directory, through Seatbelt on macOS and bubblewrap on Linux, and refuses to run a command on a machine that can't sandbox it. Left unset, it is `observe` until 6 October 2026 (00:00 UTC) and `enforce` from then on wherever the OS can fully enforce it, as the flag's own help text says; see [The boundary, and the sandbox](#the-boundary-and-the-sandbox). `camy --version` prints the posture on stderr, and `camy --version --json` carries it as `local_sandbox`. |
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
`camy local trust list` alongside the grants you added by hand. camy saves
it once camy.ai accepts the approval; an approval camy.ai refuses saves no
grant. Beside it, `a` records a family grant for commands of the same
shape: the same program, the same leading subcommands, and the same flags
with the same values. Any other argument must be one you already approved,
or name something already in the project; a command whose new arguments
don't gets a card.

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
  "paths": [],
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

A removal applies at once in every running camy session, including ones
started before it. Each trust decision reads the store as it is on disk,
so pressing `a` in an older session never brings a removed grant back.

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
Running a module, as in `python3 -m unittest`, is a runner like `go test`
and `npm test`, and can be trusted.

## Read-only scope

Every read target passes the same project-root boundary as writes and
commands: a path that resolves outside the root, directly or through a
symlink, is refused, and so is anything matching the secret-path denylist
below. Within that boundary:

- `read_file` refuses a directory target, and refuses anything that isn't a
  regular file. One call returns up to 200 KB by default and never more
  than 1 MB; a larger file is read in pages, from a byte offset or as a
  stretch of lines, and a negative start line counts back from the end. A
  single line longer than one page, such as a minified bundle's, comes back
  a page at a time, marked truncated, with the offset to read on from.
- `list_dir` lists one directory, or walks up to eight levels below it with
  an include or exclude glob (`**/*.tsx`) to find files by name. It caps
  the number of entries it returns at 1,000.
- `grep` skips any single file above 5 MB, and finds matches on any line
  within that, however long. Each matched line's text is cut to 2,000
  bytes and ends in `…`. An invalid regular expression is refused.
- A `grep` or a `list_dir` walk skips common build, dependency, and cache
  directories (`.git`, `node_modules`, `vendor`, `.venv`, `dist`, `build`,
  `.cache`, `.pytest_cache`, and similar), and skips hidden directories
  other than `.github`, `.circleci`, and `.claude` unless the call asks to
  include them. The result names the folders it skipped, up to 25 with a
  count of the rest (`.git` is never named), so the agent knows what it
  didn't search. A search or listing that starts inside such a folder,
  such as a path under `vendor/`, covers that whole folder; `.git` is
  always skipped.
- A search with no matches, or a recursive listing that finds nothing,
  comes back to the agent as an empty result, not as a failed call.

Secrets in what the tools return are masked before they reach the agent,
even inside a file the denylist did not refuse. A line that sets an AWS
secret key, or the line that opens a private key (`-----BEGIN ... KEY-----`),
is replaced whole, and a token or password inside an ordinary line, such as a password in a URL or
a well-known API token, is replaced in place with `«redacted»`, keeping the
rest of the line. This applies to `read_file` content (every page of it),
`grep` match text, and the captured output of `run_command` and of
background commands alike.

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
| Specific credential files | `.env` and every other dotenv-style secrets file, `.netrc`, `.npmrc`, `.git-credentials`, `.pypirc`, `.pgpass`, `.dockercfg`, `.htpasswd`, `.s3cfg`, `.aws/credentials`, and the config files git reads inside a `.git` folder — only those, not the whole `.git` tree. The committed-safe siblings `.env.example`, `.env.sample`, `.env.template`, `.env.dist`, and `.env.defaults` are exempt. |
| Private keys | By name or extension: `id_*`, `*_rsa`, `*_ed25519`, `.pem`, `.key`, `.p12`, `.pfx`, `.jks`, `.keystore`, `.ppk`. A public key (`*.pub`) is exempt — it is not a secret. |
| Secret-sounding data files | A narrower fuzzy match on ordinary data files whose name merely contains `secret`, `credential`, or `passwd` — but not on common source or doc file extensions, so `src/credentials.ts` and `docs/secrets.md` are not blocked by this rule alone. |
| macOS and browser credential stores | Keychain files, cookie stores, the Messages and Mail folders, the browser profile folders of Chrome, Firefox, Edge, Brave, Vivaldi, and other browsers, Safari's cookie store, and browser password and autofill databases wherever they sit (`Login Data`, `Web Data`, `key4.db`, `logins.json`, and similar). These match whole folder and file names, so a project folder such as `Web Data Pipeline/` is not refused. |
| Other credential stores | Password managers and keyrings, the sign-in stores of cloud, deploy, and package-registry command-line tools, coding assistants' credential files, and shell and REPL histories |
| System credential files | `/etc/shadow`, `/etc/gshadow`, `/etc/sudoers` |
| camy's own directories | Its config, state, and cache directories, across every profile: the settings camy acts on, the trust store, the stored credential fallback file, and the copies kept of files a write replaced. Unreadable by the bridge's own tools |

The denylist is checked from your home folder as well as from the project
root, so a credential store stays refused even when you start `camy`
inside the folder that holds it, such as `~/.kube`. A `grep` or
`list_dir` walk skips these paths and never walks into such a folder.

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
- `git push` in any form that force-updates a remote, and several other git
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
- a wrapper — `env`, `nice`, `timeout`, `xargs`, and similar — or a shell
  script around any of the above, however it is written; the guard looks
  through to the command that runs, and refuses a script it can't read
  with confidence

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
installed system-wide) on Linux. Under `enforce` a command can write only
inside the project root, a temp directory, and your user cache directory.

- On macOS the temp directory is the system's. A command can still write to
  `/dev/null`, the terminal, and its own output streams, so `cmd
  2>/dev/null` works. It cannot reach container-runtime sockets (Docker,
  Colima), and it cannot open or script other apps. Reads and
  network access are not confined.
- On Linux each command gets its own empty `/tmp` and runtime folder
  instead of the system's. It cannot reach other local services, such as
  the container daemon, the session bus, or the ssh and gpg agents, and it
  has no network access, except when the command itself is a program that
  fetches code or packages or connects to another machine (`git`, `npm`,
  `pip`, `go`, `curl`, `ssh`, `rsync`, and the like). Every other command
  runs offline, including a wrapper such as `sh -c "npm ci"`. Reads are not
  confined.

`observe` leaves commands unconfined.

An unset dial counts as `enforce` only where this machine can fully
enforce it. On macOS that takes `sandbox-exec`. On Linux it takes a `bwrap`
installed for the whole system, such as your distribution's package, that
can really start a sandbox: camy checks that it starts before relying on
it, so a machine where unprivileged user namespaces are restricted stays at
`observe` rather than failing every command. A `bwrap` installed only in
your home folder, for example under `~/.local/bin` or by Linuxbrew, is not
used; install the system package to keep the sandbox. On macOS,
`camy --version` names why the sandbox is unavailable only when you ask for
`enforce` explicitly (`--sandbox enforce` or `CAMY_LOCAL_SANDBOX=enforce`).
With the dial unset it prints the generic "No OS sandbox is in effect" line.
On either OS, `camy --version --json` reports `enforcement` as
`unavailable`.

An explicit `--sandbox enforce` or `CAMY_LOCAL_SANDBOX=enforce` on a
machine that can't sandbox a command refuses the command rather than run it
unconfined, and the refusal says this machine cannot contain a command, and
why. Install the sandbox tool, or pass `--sandbox observe` to run commands
unconfined.

`camy --version` prints the posture in effect on stderr, under the version
line, and `camy --version --json` carries it as `local_sandbox`. A command
card states it only once per connection, so the first command card you
actually see may not carry it if an earlier one was answered for you.
`camy --version` is the dependable place to read it.

Left unset, the dial is `observe` until 6 October 2026 (00:00 UTC). From
that date an unset dial means `enforce` on any machine that can fully
enforce it, and on such a machine camy.ai can move an unset session to
`enforce` sooner. The `--sandbox` flag's own help text, and the reference
pages that list it, give the same date. Nothing camy.ai sends can move the
dial toward `off`, and an explicit `--sandbox observe` or
`CAMY_LOCAL_SANDBOX=observe` always stays `observe`.

When `enforce` stops a command, camy.ai can ask again with a card that
loosens the sandbox for that one run: either letting it write to more
folders, or running it outside the sandbox. The card says so in an amber
line under the command:

```text
the sandbox also lets it write to ~/.npm
runs outside the sandbox: it can change any file you can and reach any site
```

A run outside the sandbox is approved only by typing the word:

```text
run it outside the sandbox? type outside to approve, anything else to refuse
```

`outside`, in any case, approves; `y`, `a`, and an empty line refuse, and
no `a` grant is offered. A run that only gains folders keeps the usual
`y`/`N`/`a` prompt.

The CLI never answers such a card for you, even for a command you trusted
or one that only reads. A widening applies only when the card you approved
showed it: a command approved any other way, with
`camy approvals approve --wait` or answered for you, runs inside the
sandbox. The CLI drops any widening that names `/`, your home folder or a
folder above it, a top-level system folder, a folder that holds the
project, or a secret-shaped path.

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

camy.ai accepts an opening message of up to 64 KB. When the project's
instructions and folder details would make it larger, camy leaves out
context until it fits: first the list of top-level names, then the end of
the instructions, then the rest of where it is running. Your tools,
sign-in, and sandbox posture are never left out.

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
  repository's root, branch, and `origin` remote with any embedded
  credential removed, which camy reads from the repository's own files
  without running any program; the operating system, CPU architecture, and
  shell name; and the names of up to 40 entries at the top of the project
  root. Names only, never file contents.
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
something this CLI process itself witnessed being approved: your own `y`,
`a`, or `outside` on a card, a trust-store auto-run, a read-only command the
CLI verified itself (with or without a card),
`camy approvals approve --wait`, or a live re-confirm dialog for an
approval made in a different open session. An approval covers only the
exact command, folder, file mode, and job the card showed.

A server that skips straight to requesting a tool call, without a real
approval behind it, is refused here rather than merely delayed.

Offering local tools takes a key with the `bridge:register` scope, which
`camy auth login` asks for. A key from an earlier `camy auth login` still
works, so you don't need to sign in again. If camy.ai says your key can't
offer local tools, camy says so once per run, in camy.ai's words or as:

```text
This API key can't register local tools. Run camy auth login to sign in with a key that can.
```

The chat then goes on without local tools.

[Approvals](approvals.md) owns the approval model itself: how a card is
presented, what `y`, `a`, and `n` do, the 120-second timeout, and headless
(`--no-input`) behavior. All of it applies to local-bridge cards exactly as
it does to any other approval.

No flag answers every approval automatically. `--force` skips a different,
unrelated class of destructive-operation prompts elsewhere in the CLI; it
does not touch a local-bridge approval card.
