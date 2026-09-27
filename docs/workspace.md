# Workspace

Your workspace is a dedicated cloud computer that the Camy agent uses when it
needs to run code, install dependencies, or work with files outside your own
machine. It persists between chats, keeps its disk even when it is stopped,
and it is reachable from any device you sign in on. The CLI reaches it with
[`camy vm`](reference/camy_vm.md).

```bash
camy vm exec -- CMD...   # run one command; its exit code becomes yours
camy vm shell            # an interactive shell on the workspace
camy vm status           # what state the workspace is in
```

Bare `camy vm` is the same as [`camy vm status`](#camy-vm-status). Every
`camy vm` command uses the CLI's normal [exit codes](exit-codes.md), with one
exception: `camy vm exec` mirrors your remote command's own code instead.

## `camy vm exec`

```bash
camy vm exec -- pytest -q
camy vm exec -- 'make build && make test'
camy vm exec -- sh -c 'make build && make test'
```

Runs a command on your workspace and hands you back the whole result when it
finishes: stdout and stderr come home on their own streams — nothing is
printed while the command is still running — and the remote command's exit
code becomes your exit code, ssh-style.

Everything after `--` is the command, and it follows ssh's rule. A single
argument is handed to the workspace shell as written, so shell syntax of your
own (`&&`, pipes, redirects) works inside it, as in the second example above.
Several arguments are quoted one by one, so the workspace sees exactly the
argv you typed: the third example runs `sh` with two arguments, `-c` and
`make build && make test`. Leading `NAME=value` words stay variable
assignments, so `camy vm exec -- FOO=1 make` runs `make` with `FOO` set.

stdin is not forwarded, and the command runs with no input. If data is
already waiting on stdin (a redirected file, or a pipe that has already
written), `camy vm exec` leaves it unread and warns
`stdin isn't forwarded to the workspace — the command runs with no input`.
The data is never forwarded either way.

Because the whole result comes home in one response, the workspace caps how
much output it sends back. A command that prints more keeps the beginning and
the end of its output, with a marker where the middle was dropped, and camy
warns on stderr, even under `--quiet`, for example
`output truncated — 2.0 KB omitted from the middle (the workspace caps what exec sends back)`.
Under `--json`, the object's `truncated` and `omitted_bytes` say so instead.
A response too big for camy's own 50MB limit fails with exit 255. Redirect
chatty output to a file on the workspace
(`-- 'make build > build.log 2>&1'`) and fetch or tail it separately.

### Flags

| Flag | Effect |
|---|---|
| `--cwd DIR` | working directory on the workspace; camy passes the value through unchanged, so give an absolute workspace path — a bare `~/app` is expanded by your local shell into a path from your own machine, and quoting it (`--cwd '~/app'`) sends a literal tilde the workspace may not expand either |
| `--timeout N` | wall-clock seconds to allow in the container, though the workspace stops the command a few seconds sooner (see [Exit codes](#exit-codes)); must be 1-3600 (up to an hour), or omit it (or pass 0) for the server default of 120. A whole number outside 1-3600 other than 0 is refused with `--timeout must be between 1 and 3600 seconds`. A value that isn't a whole number is refused as an invalid argument. Both exit 2 before anything is sent |
| `--no-wake` | refuse to wake a workspace you have that is stopped, stopping, starting or being provisioned; exits 7 immediately instead of starting it, which can take a few minutes. With no workspace, a terminated one, or one mid-resize, exec exits 255 whether or not you pass `--no-wake` |
| `--vm ID` | not available yet — the flag exists, but any value is refused; `exec` only ever runs on your primary workspace |

Build with a specific working directory and a tight timeout, without waking a
stopped workspace:

```bash
camy vm exec --cwd /path/to/app --timeout 30 --no-wake -- make build
```

See [`camy vm exec`](reference/camy_vm_exec.md) for the full flag reference.

### The `workspace:exec` scope

`camy vm exec` and [`camy vm shell`](#camy-vm-shell) need a key with the
`workspace:exec` scope. `camy auth login` asks for it by default, so the key
it gives this terminal has it. A key minted before that scope existed
doesn't, and is refused with `this key lacks a required scope` and a hint to
run `camy auth login` again: `vm exec` exits 255, as it does for all of
camy's own failures, and `vm shell` exits 3.

### Waking a stopped workspace

Before running the command, `camy vm exec` checks whether the workspace is
running. If it is not, and you passed `--no-wake`, the command exits
immediately without starting anything.

Otherwise it prints `waking your workspace… (this can take a few minutes)`
and starts the workspace the way [`camy vm start`](#camy-vm-start) does,
waiting up to 30 minutes for it to be ready. A workspace that is already
stopping, starting or being provisioned is waited out rather than started a
second time. Only then does your command run, with its whole `--timeout` to
itself. If the start is refused (you're out of credits, for example), the
command never runs and `vm exec` exits 255 with the reason.

When camy knows this terminal's key lacks the
[`workspace:exec` scope](#the-workspaceexec-scope), it refuses before waking
anything, so that key doesn't pay for a boot. With `CAMY_API_KEY`, or a key
whose scopes weren't recorded when you signed in, camy can't tell. The
workspace is woken, and then the command is refused.

`camy vm exec` never creates a workspace. If you don't have one at all, it
exits 255 with `you don't have a workspace yet — exec won't create one` and
points you at [`camy vm provision`](#camy-vm-provision). A workspace whose
instance was terminated gets the same answer, starting
`your workspace is gone`. A new workspace costs credits, so it is only made
when you ask for it by name; [`camy vm sizes`](#camy-vm-sizes) lists what
each size costs. A workspace in the middle of a resize isn't woken either:
exec exits 255 and says it can run once the workspace is back.

### Exit codes

`vm exec` has its own exit-code contract:

| Exit code | Meaning |
|---|---|
| 0-254 | the remote command's own exit code, mirrored exactly |
| 2 | usage error caught before any network call: `--vm` given, or a non-zero `--timeout` outside 1-3600 (`--timeout 0` means the same as omitting the flag); or a `--jq` / `--template` that doesn't parse, caught only after the command has run |
| 7 | `--no-wake` was set and the workspace is stopped, stopping, starting or being provisioned |
| 255 | camy's own failure — not a remote exit code: not signed in, the workspace was unreachable, you have no workspace or it is mid-resize, it couldn't be woken, the key lacks `workspace:exec`, the service turned the command down, the command outlived `--timeout`, no exit code came back, or the workspace agent itself failed |

The mirrored code drives your own shell, so a local follow-up chains off it:

```bash
camy vm exec -- pytest -q && echo green
```

A remote command that exits 255 or higher is reported as 254, so a mirrored
code can never be mistaken for camy's own 255.

The workspace stops a command a few seconds before `--timeout` (120 seconds
when you leave it out): about five seconds early, and after one second for a
limit of six or less. camy then exits 255 with `timed out after 120s`, naming
the limit you set. Whatever output came back is still printed. A command that
exits 124 by its own choice well inside the limit, such as
`timeout 30 ./flaky.sh` under the default 120, is not taken for a timeout:
its 124 is mirrored like any other code. A result that comes back with no
exit code at all is never read as success either; camy exits 255 with
`no exit code from the workspace`.

A mirrored nonzero exit code (1-254) is not treated as a camy error: camy adds
no error message of its own, because the remote command already said what it
had to say on its own streams. Your stderr carries the remote command's stderr
and the one-line note below, plus the warnings above when output was
truncated or stdin was dropped.

Once the command has actually run, 255 is reserved for camy's own failure, so
a script can tell "your command failed" (0-254) from "camy couldn't run your
command or see it finish" (255).

The pre-flight refusals above are the exception: exits 2 and 7 come from camy
before the remote command runs, and they look the same to `$?` as a remote
command exiting 2 or 7. They are distinguishable by the `camy:` error line on
stderr, which mirrored codes never print. One 2 comes after the run: a `--jq`
or `--template` that doesn't parse is caught only when the result is rendered,
once the remote command has already run.

Whenever the remote command's own exit code is mirrored (0-254), `vm exec`
prints one line to stderr — `exit N — mirrored to your shell`, including
`exit 0` on success. Pre-flight refusals (2, 7) and camy's own failures (255,
including a timeout) print a `camy:` error line instead, never this one.

That exit line is chrome, not data: it goes to stderr whether or not stderr is
a terminal, and it is suppressed by `--quiet` and by `--json` (and `--jq` /
`--template`).

### Output

In human mode, stdout and stderr each go to their own stream, handled
according to where they are going:

- stdout to a pipe or a file gets the remote bytes exactly as the workspace
  sent them, with no newline added, so
  `camy vm exec -- cat app.log > app.log` is a faithful copy, within the
  output cap above.
- stdout on a terminal is sanitized first (escape sequences and other
  terminal-control bytes are defused), with a trailing newline added if the
  command's own output didn't end in one.
- stderr is sanitized when it is a terminal, and always ends its line,
  because camy's exit line follows it on the same stream.

Under `--json`, the whole result comes back as one object instead, with the
raw bytes exactly as the workspace sent them — byte-true, unsanitized, even if
stdout is a terminal:

```json
{
  "stdout": "...",
  "stderr": "...",
  "exit_code": 0,
  "truncated": false,
  "omitted_bytes": 0,
  "timed_out": false
}
```

`truncated` and `omitted_bytes` say whether the workspace cut the output and
by how many bytes. `timed_out` is true only when the command outlived
`--timeout`.

## `camy vm shell`

```bash
camy vm shell
```

Opens a live PTY session on your workspace — a real interactive shell, with
terminal resize following your window. It needs a real terminal on stdin; run
it from an interactive session, not from a script or a pipe (use
[`camy vm exec`](#camy-vm-exec) for scripted commands instead). There is no
`--json` mode: it is an interactive passthrough, not a data command.

The shell connects only to a running workspace and never starts one, so run
[`camy vm start`](#camy-vm-start) first. It also needs a key with the
[`workspace:exec` scope](#the-workspaceexec-scope). Whatever you type or
paste reaches the remote shell byte for byte; only a window resize travels
as a control message.

Exit the session the way you'd exit any shell: `exit` or Ctrl-D. Ctrl-C inside
the session goes to the remote shell, the way it would over ssh — it
interrupts whatever is running on the workspace, it does not end the session.

When the shell exits, camy prints `the workspace closed the shell` (unless
`--quiet`) and exits 0. A workspace that stops under you may end the session
the same way. If the workspace ends the session with a reason of its own,
camy exits 7 with `shell disconnected: <reason>` and suggests
`camy vm status`. It doesn't reconnect.

A signal sent to the camy process from outside (SIGINT, SIGTERM) or a terminal
hangup unwinds the session cleanly, restoring your local terminal to normal
(non-raw) mode.

A dropped network connection does not end `camy vm shell`: it redials in
place instead of exiting. A reconnect opens a new shell and says so —
nothing from the old session carries over, including anything you typed as
it dropped, so retype it once you're back.

A connection that keeps dropping is not given up on. After ten reconnects
within five minutes, camy waits a little before each further try, longer
each time up to 30 seconds, and keeps going. Each reconnect makes up to
eleven attempts, with growing waits between them. If they all fail, the
command stops with `connection lost — could not reconnect: …` (exit 7), or,
when the last attempt was turned away before the connection opened, with that
refusal's own message: exit 5 for a rate limit, 7 otherwise.

A refusal no reconnect can change ends the command at once, on connect or
when a reconnect meets it: a stopped workspace exits 7 and points at
`camy vm start`, no workspace exits 7 and points at `camy vm provision`,
running out of credits or a plan without the terminal exits 6, and a key the
terminal refuses exits 3.

Too many connection attempts in a short time are turned away before the
connection opens: camy exits 5 (naming the wait when the service gives
one), or 7 with
`the workspace terminal refused the connection — too many attempts? try again shortly`.
A slow link that keeps the terminal waiting too long for your key exits 7 on
connect with `the terminal gave up waiting for the key (a slow connection?)`.
Mid-session, a reconnect retries through all three, within its eleven
attempts.

`camy vm shell` is the one place where human-facing output is not sanitized:
the PTY stream carries real terminal-control sequences that programs inside
the shell (an editor, a pager, anything using ncurses) legitimately need, so
bytes go straight from the socket to your screen.

Everywhere else, server-originated text is sanitized before it is rendered
for a human; machine output (`--json`) is always the raw bytes, as described
above.

Bring the workspace up, confirm it's ready, then work interactively:

```bash
camy vm start
camy vm status
camy vm shell
```

See [`camy vm shell`](reference/camy_vm_shell.md).

## Lifecycle

When the service turns `start`, `stop`, `exec` or `apps` down with a sentence
of its own (for `start`, a resize still in progress), camy prints that
sentence as the error: exit 255 for `exec`, exit 1 for the others. When the
sentence says no workspace was found, the error also points you at
[`camy vm provision`](#camy-vm-provision). One exception: `camy vm start`
refused for lack of credits prints `you're out of credits` and exits 6 (see
[exit codes](exit-codes.md)); `camy vm exec` prints the same and keeps its
255.

### `camy vm status`

```bash
camy vm status
```

Reports whether the workspace is running. Human output opens with one line:
a status dot, the workspace's state, and its instance id. Under it come a
`size` row and an `address` row when the service reports them, then the
commands that apply next: `camy vm exec`, `shell`, `apps` and `stop` while it
runs; `camy vm provision` and `camy vm sizes` when you have no workspace or
its instance was terminated; `camy vm status` again while a resize is in
progress, since the workspace restarts on its own; and `camy vm start` and
`camy vm sizes` otherwise. The size is the machine's instance type (a tier
key such as `plus` only while a resize is in progress), and the address is
the workspace's public IP. `camy vm ls` and
`camy vm sizes` show which size tier you are on. `--json` returns the
server's status object as-is. See
[`camy vm status`](reference/camy_vm_status.md).

### `camy vm start`

```bash
camy vm start
```

Starts the workspace and blocks until it is actually ready — a cold boot can
take a few minutes, so this can run for a while before it returns.

It waits up to 30 minutes; past that the call gives up with a runtime error
(exit 1) even though the workspace may still be coming up — `camy vm status`
tells you where it got to. The same ceiling applies to `stop`, `provision`,
and `resize`. See [`camy vm start`](reference/camy_vm_start.md).

### `camy vm stop`

```bash
camy vm stop
```

Suspends the workspace. Its disk is preserved; nothing is deleted. This asks
for confirmation first (skip it with `--force` in a script). The stop itself
is asynchronous, so use `camy vm status` afterward to confirm it happened. See
[`camy vm stop`](reference/camy_vm_stop.md).

### `camy vm provision`

```bash
camy vm provision
camy vm provision --size SIZE
```

Provisions the workspace if it doesn't exist yet, or reconciles it if it does.
`--size` takes one of the tier keys [`camy vm sizes`](#camy-vm-sizes) prints;
leave it out to use the default.

This runs in the background — poll `camy vm status` to watch it come up.
Unlike `stop` and `resize`, `provision` does not ask for confirmation. See
[`camy vm provision`](reference/camy_vm_provision.md).

### `camy vm ls`

```bash
camy vm ls
```

Lists every VM you own, across roles — not just your primary workspace. Each
row shows a status dot, id, role, state, and size tier. With none, it says so
and points you at `camy vm provision`. See
[`camy vm ls`](reference/camy_vm_ls.md).

### `camy vm apps`

```bash
camy vm apps
```

Shows what's running inside the workspace. It checks the workspace's state
first and never starts it: a workspace that isn't running exits 7 with, for
example, `workspace stopped — nothing is running in it` and `camy vm start`
as the next step, and with no workspace it exits 7 and points you at
`camy vm provision`. When camy.ai can answer for a workspace that isn't
running itself, `apps` shows that answer and the next step instead, and
exits 0. If a running workspace reports nothing, it says so instead of
printing nothing. See
[`camy vm apps`](reference/camy_vm_apps.md).

### `camy vm url`

```bash
camy vm url
```

Prints the workspace's public URL, if it has one right now, along with its
status. If there's no public URL, it tells you rather than printing nothing —
check that the workspace is running. See
[`camy vm url`](reference/camy_vm_url.md).

### `camy vm sizes`

```bash
camy vm sizes
```

Lists every workspace size tier with its vCPUs, memory, disk and credits per
hour (blank when the service reports none).

The tier your workspace is running right now is marked `running now`. When
the service says a tier isn't available on your plan, that row is marked
`not on your plan`. The default tier is labelled `the default` unless one of
those marks applies. When no workspace is running, nothing is marked
`running now`.

When the service reports it, a closing `gpu` line names the GPU add-on, says
whether you can add it, and gives what it adds per hour:
`gpu <label> · available on <sizes> (camy vm resize SIZE --gpu) · +N credits/h`.
When you can't add it, the middle part says `not on your plan` instead, or
`not available yet` when the add-on isn't offered at all. The line is about
what you can turn on, not whether your own workspace has a GPU. See
[`camy vm sizes`](reference/camy_vm_sizes.md).

### `camy vm resize`

```bash
camy vm resize SIZE
camy vm resize SIZE --gpu
camy vm resize SIZE --no-gpu
```

Resizes the workspace in place: stop, resize, start again, with your disk
preserved throughout. SIZE is one of the tier keys
[`camy vm sizes`](#camy-vm-sizes) prints — the CLI does not carry its own
list.

`--gpu` turns the GPU add-on on as part of the same resize, and `--no-gpu`
turns it off. With neither, the add-on stays as it is: camy reads whether it
is on now and keeps it that way. If it can't read that, the resize stops
before anything changes and asks you to say which with `--gpu` or
`--no-gpu`. Passing both is a usage error (exit 2).

This takes a confirmation (or `--force`) because it means a few minutes of
downtime. Downgrades are refused by the server, not the CLI.

Check available sizes before resizing, then resize non-interactively:

```bash
camy vm sizes
camy vm resize SIZE --force
```

See [`camy vm resize`](reference/camy_vm_resize.md).

### `--json` output

Every lifecycle command above returns the server's object as-is under
`--json`, with one shape change: `vm ls` unwraps the server's envelope and
prints a plain JSON array of VM rows. The CLI does not otherwise reshape the
payload, so the exact fields you get can vary by command and over time.

`vm status`, `vm start`, `vm provision`, and `vm resize` build their human
line from a `status` or `state` field in the response; `vm stop` prints a
fixed acknowledgement instead, which is why it tells you to poll
`camy vm status`.

`vm sizes` normally renders a table; if the server's response ever doesn't
have the shape the CLI expects, it falls back to printing the raw JSON object
even without `--json`, rather than showing nothing.

## `camy vm logout-everywhere`

```bash
camy vm logout-everywhere
camy vm logout-everywhere --yes --code 123456 --json
```

Logs your cloud computer out of every site. Camy forgets every login it saved
and clears your computer's browser (cookies and open sign-ins), and any task
running on the computer stops. The sites themselves aren't touched: you sign
in again the next time a task needs one. It does what Log out everywhere
under Settings → Privacy & data on camy.ai does.

It asks you to confirm first. `--yes` (or `--force`) answers for a script;
with `--no-input` or no terminal and neither flag, it exits 2 and names
`--yes`. Answering no exits 2 with `cancelled — nothing was changed`.

Then it asks for a fresh check that it's you: your authenticator's code, or
Enter to have a code emailed to your account. A mistyped code gets another
try, up to three. `--code CODE` passes the code up front for a script, either
your authenticator's or one camy.ai emailed you; a code given that way is
final, so a wrong one exits 3 with
`that code didn't confirm it's you — nothing was changed` and no prompt.
With `--yes` and `--no-input` but no `--code`, there is nobody to ask for a
code, so it exits 3 and points at `--code`.

It runs only with the key `camy auth login` gave this terminal, from the
browser sign-in or `camy auth login --code`. Any other key (a pasted one,
`CAMY_API_KEY`, one made on camy.ai) is refused with exit 3 before any code
is asked for or emailed, and so is a sign-in key from before camy.ai marked
them. Running `camy auth login` again signs this terminal in with a key that
can.

Your saved logins are gone by the time it answers. A running computer's
browser is cleared right after; one that is off is cleared the next time it
starts, before Camy uses it. The receipt says which, without calling an
unfinished wipe done:

```text
✓ logged out everywhere — removed 3 saved logins
  your computer's browser is being cleared now — if that can't finish, it clears the next time it starts, before Camy uses it
  1 task it was running is stopping
```

`--json` prints the receipt as camy.ai sent it, with `vault_entries_deleted`,
`sessions_stopping`, `boxes_clearing` and `boxes_pending`.

| Exit code | Meaning |
|---|---|
| 0 | done |
| 1 | camy.ai couldn't do it, or couldn't be reached |
| 2 | not confirmed, or bad flags (an empty `--code`, for example) |
| 3 | this key can't run it, or the code didn't confirm it's you |

Anything else follows the normal [exit codes](exit-codes.md), such as 5 when
you're rate-limited.

See [`camy vm logout-everywhere`](reference/camy_vm_logout-everywhere.md).
