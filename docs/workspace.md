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
camy vm exec -- sh -c 'make build && make test'
```

Runs a command on your workspace and hands you back the whole result when it
finishes: stdout and stderr come home on their own streams — nothing is
printed while the command is still running — and the remote command's exit
code becomes your exit code, ssh-style.

Everything after `--` is the command, and each argument is quoted before it is
handed to the workspace shell. Shell syntax of your own (`&&`, pipes,
redirects) has to go inside an explicit shell, as in the second example above.
Passing `"make build && make test"` as a single argument does not work; it
arrives quoted and is treated as one command name.

Because the whole result comes home in one response, output is capped. A
command whose stdout and stderr together exceed 10MB fails with exit 255 and
`response from /v1/workspaces/exec exceeds the 10MB cap`. Redirect chatty
output to a file on the workspace (`-- sh -c 'make build > build.log 2>&1'`)
and fetch or tail it separately.

### Flags

| Flag | Effect |
|---|---|
| `--cwd DIR` | working directory on the workspace; camy passes the value through unchanged, so give an absolute workspace path — a bare `~/app` is expanded by your local shell into a path from your own machine, and quoting it (`--cwd '~/app'`) sends a literal tilde the workspace may not expand either |
| `--timeout N` | wall-clock seconds to allow in the container; must be 1-600, or omit it (or pass 0) for the server default of 120 |
| `--no-wake` | refuse to wake a stopped workspace; exits 7 immediately instead of spending the command's timeout budget on an auto-start |
| `--vm ID` | not available yet — the flag exists, but any value is refused; `exec` only ever runs on your primary workspace |

Build with a specific working directory and a tight timeout, without waking a
stopped workspace:

```bash
camy vm exec --cwd /path/to/app --timeout 30 --no-wake -- make build
```

See [`camy vm exec`](reference/camy_vm_exec.md) for the full flag reference.

### Waking a stopped workspace

Before running the command, `camy vm exec` checks whether the workspace is
running. If it is not, and you passed `--no-wake`, the command exits
immediately without starting anything.

Otherwise it prints a note that it is waking the workspace and waits — but
only within the same budget the command itself gets: `--timeout` seconds (120
when you leave it out) plus about 30 seconds of margin.

A cold boot can take longer than that, in which case exec gives up with 255.
Run [`camy vm start`](#camy-vm-start) first, or raise `--timeout`, when the
workspace may be stopped.

### Exit codes

`vm exec` has its own exit-code contract:

| Exit code | Meaning |
|---|---|
| 0-254 | the remote command's own exit code, mirrored exactly |
| 2 | usage error caught before any network call: `--vm` given, or a non-zero `--timeout` outside 1-600 (`--timeout 0` means the same as omitting the flag) |
| 7 | the workspace is not running and `--no-wake` was set |
| 255 | camy's own failure — not a remote exit code: not signed in, the workspace was unreachable, or the workspace agent itself failed (for example a remote timeout) |

The mirrored code drives your own shell, so a local follow-up chains off it:

```bash
camy vm exec -- pytest -q && echo green
```

A remote command that exits 255 or higher is reported as 254, so a mirrored
code can never be mistaken for camy's own 255.

A mirrored nonzero exit code (1-254) is not treated as a camy error: camy adds
no error message of its own, because the remote command already said what it
had to say on its own streams. Your stderr carries the remote command's stderr
and the one-line note below, nothing more.

Once the command has actually run, 255 is reserved for camy's own failure, so
a script can tell "your command failed" (0-254) from "camy could not run your
command" (255).

The pre-flight refusals above are the exception: exits 2 and 7 come from camy
before the remote command runs, and they look the same to `$?` as a remote
command exiting 2 or 7. They are distinguishable by the `camy:` error line on
stderr, which mirrored codes never print.

Whenever the remote command actually runs, `vm exec` prints one line to
stderr — `exit N — mirrored to your shell`, including `exit 0` on success. The
pre-flight refusals (2 and 7) and camy's own failures (255) print a `camy:`
error line instead, never this one.

That exit line is chrome, not data: it goes to stderr whether or not stderr is
a terminal, and it is suppressed by `--quiet` and by `--json` (and `--jq` /
`--template`).

### Output

In human mode, stdout and stderr are sanitized before they hit your terminal
(escape sequences and other terminal-control bytes are defused) and printed to
their respective streams, each with a trailing newline added if the command's
own output didn't end in one.

That sanitizing happens whether stdout is a terminal, a pipe, or a file —
human mode is never byte-exact. To capture bytes verbatim, use `--json` and
read the `stdout` field.

Under `--json`, the whole result comes back as one object instead, with the
raw bytes exactly as the workspace sent them — byte-true, unsanitized, even if
stdout is a terminal:

```json
{
  "stdout": "...",
  "stderr": "...",
  "exit_code": 0
}
```

## `camy vm shell`

```bash
camy vm shell
```

Opens a live PTY session on your workspace — a real interactive shell, with
terminal resize following your window. It needs a real terminal on stdin; run
it from an interactive session, not from a script or a pipe (use
[`camy vm exec`](#camy-vm-exec) for scripted commands instead). There is no
`--json` mode: it is an interactive passthrough, not a data command.

Exit the session the way you'd exit any shell: `exit` or Ctrl-D. Ctrl-C inside
the session goes to the remote shell, the way it would over ssh — it
interrupts whatever is running on the workspace, it does not end the session.

A signal sent to the camy process from outside (SIGINT, SIGTERM) or a terminal
hangup unwinds the session cleanly, restoring your local terminal to normal
(non-raw) mode.

A dropped network connection does not end `camy vm shell`: it redials in
place instead of exiting. A reconnect opens a new shell and says so —
nothing from the old session carries over, including anything you typed as
it dropped, so retype it once you're back. After three reconnects within a
minute, a fourth drop is not retried: the command stops with a
`connection lost — could not reconnect` error.

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

### `camy vm status`

```bash
camy vm status
```

Reports whether the workspace is running. Human output is one line: a status
dot, the workspace's name, and its state. `--json` returns the server's status
object as-is. See [`camy vm status`](reference/camy_vm_status.md).

### `camy vm start`

```bash
camy vm start
```

Starts the workspace and blocks until it is actually ready — a cold boot can
take a few minutes, so this can run for a while before it returns.

It waits up to 12 minutes; past that the call gives up with a runtime error
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
row shows a status dot, id, role, and state. See
[`camy vm ls`](reference/camy_vm_ls.md).

### `camy vm apps`

```bash
camy vm apps
```

Shows what's running inside the workspace. If nothing is running, or the
workspace isn't up, it says so instead of printing nothing. See
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

Lists the available workspace size tiers, their specs, and their credit cost,
along with whether the GPU add-on is on for your current workspace. The
current size is marked. See [`camy vm sizes`](reference/camy_vm_sizes.md).

### `camy vm resize`

```bash
camy vm resize SIZE
camy vm resize SIZE --gpu
```

Resizes the workspace in place: stop, resize, start again, with your disk
preserved throughout. SIZE is one of the tier keys
[`camy vm sizes`](#camy-vm-sizes) prints — the CLI does not carry its own
list. `--gpu` turns the GPU add-on on as part of the same resize.

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
