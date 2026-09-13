# Connectors

A connector is an account or a server Camy may act through: the mail and
calendar accounts you signed in with, and the tool servers you added. The CLI
lists them, checks them, pauses and resumes them, reviews what a server has
changed, and removes them.

```bash
camy connectors
```

Every connection in one table: its name, what kind it is, its state, and
what it may do. `--json` gives the rows.

## Add one

```bash
camy connectors add
```

Adding happens on camy.ai, where the sign-in for an account runs on the
provider's own page; the command prints the link. Servers that run on this
machine are not wired into the CLI yet.

## Review what changed

```bash
camy connectors review <name>
```

A tool server can change the tools it offers after you approved it. `review`
shows what changed since your approval and lets you approve the new shape,
or leaves it unapproved. Under `--no-input` it reports and changes nothing.

## Check, pause, resume, remove

```bash
camy connectors check <name>
camy connectors pause <name>
camy connectors resume <name>
camy connectors remove <name>
```

`check` tests the connection now. `pause` stops anything from running
through it while keeping its rules; `resume` reverses that. `remove` takes
it away.

## See also

- [`camy connectors`](reference/camy_connectors.md) in the reference
- [Approvals](approvals.md), the pauses a connector's actions can trigger
