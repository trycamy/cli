# camy documentation

camy is Camy in your terminal: the same agent, memory, and cloud computer
you use at [camy.ai](https://camy.ai), as one static binary you can pipe,
script, and schedule.

Every guide is here, in reading order.

## Start here

- [Installation](installation.md) — the one-line installer, Homebrew, manual downloads, updating, uninstalling
- [Quick start](quickstart.md) — sign in and do something useful in five minutes
- [Authentication](authentication.md) — device-flow sign-in, keys, scopes, the keychain, profiles
- [Configuration](configuration.md) — `config.toml`, precedence, profiles, aliases, every environment variable

## Using camy

- [Chat](chat.md) — one-shot and continued chats, stdin as context, attachments, the full-screen app
- [Approvals](approvals.md) — how a pause for a human works: approve, deny, answer, `--wait`, headless behavior
- [The local bridge](local-bridge.md) — what the agent may read, write, or run on your machine, and how you control it
- [Workspace](workspace.md) — your cloud workspace: `camy vm exec`, `camy vm shell`, lifecycle
- [Inbox, sweep, and feed](inbox.md) — the unified inbox, triage verdicts, the sweep dial, cards
- [Jobs, schedules, tasks, and data](automation.md) — durable jobs, `camy schedule`, tasks, capture, integrations, webhooks
- [Canvas](canvas.md) — files and published sites from a chat's Code Canvas

## Scripting and integration

- [Scripting with camy](scripting.md) — the stdout/stderr contract, `--json`, `--jq`, `--template`, `--no-input`, cron
- [Exit codes](exit-codes.md) — the frozen table and the JSON error shape
- [Command reference](reference/camy.md) — every command and flag, generated from the binary

## Terminal, troubleshooting, trust

- [Terminal output and accessibility](terminal.md) — color, `NO_COLOR`, `--accessible`, paging, links, inline images
- [Troubleshooting](troubleshooting.md) — [`camy doctor`](reference/camy_doctor.md), common errors, update problems
- [Verifying releases](verifying-releases.md) — checksums, signatures, SBOMs, the release channel layout
