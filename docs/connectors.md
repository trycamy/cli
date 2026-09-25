# Connectors

A connector is an account or a server Camy may act through: the accounts
you signed in with (mail, calendar, and others such as GitHub or Slack),
and the tool servers you added. The CLI lists them, checks them, pauses and
resumes them, reviews what a server has changed, and removes them.

```bash
camy connectors
```

Every connection in one table: its name, what kind it is, its status, its
tools, and when it was last checked. `camy connectors list` prints the same
table. `--json` gives the rows, and `--json --raw` the whole answer from
camy.ai, including whether part of it couldn't be read.

A row marked `!` needs you: its sign-in expired, its tools changed, or
the server stopped answering. The status column says which:

| Status | What it means |
| --- | --- |
| `connected` | working; followed by the account, or by `reads only` when it can't write |
| `sign-in expired` | sign in to it again with `camy integrations connect PROVIDER`, or on camy.ai |
| `tools changed — review` | the server's tools changed since you approved them; run `camy connectors review` on it. It reads `N tools changed — review` when camy.ai says how many changed |
| `unreachable since …` | the server stopped answering; the checked column shows when Camy tries again, if it knows |
| `couldn't check just now` | Camy couldn't check it this time; not marked as needing you |
| `paused` | nothing runs through it until you resume it |

For a connected server, the tools column reads like `3 always · 9 more`:
the tools Camy keeps ready on every turn, then the rest that are on, which
load when a task needs them.
Otherwise it counts the tools that are on (`4 of 6 on`), or the ones kept
while paused (`9 kept`).

Accounts and servers you haven't connected aren't listed; a last line
counts them and links to camy.ai. If Camy couldn't read part of your
connections, a line above the table says so, so a short list doesn't pass
for a complete one.

## Add one

```bash
camy connectors add
```

`camy connectors add` prints the camy.ai link. To connect an account, or
sign in to one again after it expired, from the terminal, run
`camy integrations connect PROVIDER` (see
[Integrations](automation.md#integrations)). Tool servers are still added
on camy.ai. Servers that run on this machine are not wired into the CLI
yet.

## Review what changed

```bash
camy connectors review <name>
```

A tool server can change the tools it offers after you approved it, and
what changed stays off until you look. `review` shows what changed since
your approval; when Camy can't tell which tools changed, it lists the
server's current tools instead. Then it asks `approve changes? [y/N]`. Yes
approves the new set and turns every tool you kept back on; anything else
leaves the changes off. A server with nothing to review says so and asks
nothing.

Under `--no-input` it reports and changes nothing. Under `--json` it
doesn't list or ask: it approves the server's current tools and prints the
connection as camy.ai returns it.

## Check, pause, resume, remove

```bash
camy connectors check <name>
camy connectors pause <name>
camy connectors resume <name>
camy connectors remove <name>
```

`check` tests the connection now. On a tool server, it also approves the
server's current tools, the same step `review` ends with, so review a
changed server before you check it. `pause` stops anything from running
through it while keeping its rules; `resume` reverses that. `remove` takes
it away.

`pause`, `resume`, and `remove` work on tool servers you added. An account
you signed in with can't be paused or removed here; camy.ai refuses, and
you disconnect it from its own row in Settings → Connections on camy.ai.

Removing a server asks you to confirm it's you first:

```text
Removing Linear needs a fresh check that it's you.
authenticator code (Enter to get a code by email):
```

Type a code from your authenticator app, or press Enter and Camy emails a
code to your account's address, then type that one. A code that doesn't
match leaves the server connected and exits 3. Under `--no-input`, or with
no terminal to type into, `remove` refuses, also with exit 3; you can
remove the server from Settings → Connections on camy.ai instead.

## See also

- [`camy connectors`](reference/camy_connectors.md) in the reference
- [Approvals](approvals.md), the pauses a connector's actions can trigger
