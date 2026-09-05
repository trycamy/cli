# Quick start

Five minutes: install, sign in, send a chat, and see what's waiting on you.

## Install

```bash
curl -fsSL https://camy.ai/cli/install.sh | sh
```

See [Installation](installation.md) for Homebrew, manual downloads, and updating.

## Sign in

```bash
camy auth login
```

camy prints a short code and a verification link to your terminal, opens
the link — camy.ai/p/device — in your browser, and waits while you confirm
the code there. On approval, an expiring, scoped API key lands in your OS
keychain, or in a locked-down file if no keychain is available. Nothing to
copy or paste.

The "signed in" summary — who you are, the key's prefix, its scopes, when
it expires — prints to stderr, so stdout stays clean if you ever wrap this
in a script.

Two other ways in exist if the browser handoff doesn't fit:

| Flag | Does |
|---|---|
| `--code` | Sends an email one-time code instead. |
| `--with-key` | Takes a key you already have. |

Details, scopes, profiles, and key management live in
[Authentication](authentication.md).

Reference: [`camy auth login`](reference/camy_auth_login.md).

## Check your status

```bash
camy status
```

One glance at what's happening right now: pending approvals, inbox items
that need you, running jobs, and your workspace state.

Reference: [`camy status`](reference/camy_status.md).

## Send a chat

A one-shot chat runs, prints the reply, and exits:

```bash
camy chat "what needs me before noon?"
```

Continue the same conversation with `-c`:

```bash
camy chat -c "and the second one?"
```

Pipe something in as context:

```bash
git diff | camy chat "review this"
```

If a message could be mistaken for a flag or another command, use `--`:

```bash
camy chat -- "$UNTRUSTED"
```

stdout carries only the reply; every tool call, spinner, and approval card
streams to stderr. More in [Chat](chat.md) — attachments, temp chats, and
project instructions.

Reference: [`camy chat`](reference/camy_chat.md).

## The full-screen app

Run `camy` with no arguments in a terminal and it opens the full-screen app
instead of a one-shot chat. Type a message and press enter to start a turn,
or use a slash command:

```text
/status      pending approvals, inbox, jobs, workspace — inline
/inbox       your unified inbox
/approvals   pick a pending checkpoint
/jobs        your running and recent jobs
/vm          workspace status
/chats       switch between chats
/new         start a new chat
/help        list everything
/quit        leave — jobs keep running
```

`--accessible` (or `CAMY_ACCESSIBLE=1`) keeps the interaction linear instead —
no redraws, one line at a time. The same thing happens automatically when
your terminal reports `TERM=dumb`. See [Chat](chat.md) for the full picture.

Reference: [`camy`](reference/camy.md).

## Approvals

Anything the agent wants to do that carries real risk — running a command,
writing a file, sending a message — pauses first. So does a question it
needs you to answer. Either pause is a checkpoint.

List what's pending and approve one from your shell:

```bash
camy approvals
camy approvals approve <id>
```

Add `--wait` to stream the resumed turn to completion right here instead of
switching back to the chat that's waiting on it:

```bash
camy approvals approve <id> --wait
```

Full model, deny/answer, and headless behavior: [Approvals](approvals.md).

Reference: [`camy approvals`](reference/camy_approvals.md),
[`camy approvals approve`](reference/camy_approvals_approve.md).

## What needs you in the inbox

```bash
camy inbox --needs-you
```

Lists only what camy triaged as needing you — unread mail that wasn't filed
away as newsletter, marketing, or other bulk.

The inbox spans the mail accounts you have connected to your Camy account,
and is empty with none connected. Connect them at camy.ai/p/connections;
[`camy integrations`](reference/camy_integrations.md) shows what is
connected.

The full inbox, triage verdicts, and the sweep dial are covered in
[Inbox, sweep, and feed](inbox.md).

Reference: [`camy inbox`](reference/camy_inbox.md).

## Run something on your workspace

Your workspace is a dedicated cloud computer the agent uses when it needs to
run code outside your machine. Run a command on it directly:

```bash
camy vm exec -- pytest -q
```

The remote command's exit code (0-254) becomes your shell's exit code, the
same way `ssh` behaves; camy's own failures for this command exit 255. See
[Workspace](workspace.md).

Reference: [`camy vm exec`](reference/camy_vm_exec.md).

## Where to go next

- [Configuration](configuration.md) — config.toml, precedence, every environment variable
- [The local bridge](local-bridge.md) — what camy may read, write, or run on this machine
- [Scripting with camy](scripting.md) — `--json`, `--jq`, `--template`, `--no-input`, cron
- [Exit codes](exit-codes.md) — the frozen table
- [Command reference](reference/camy.md) — every command and flag
