# Changelog

All notable changes to the camy CLI are recorded here.

Versions follow [Semantic Versioning](https://semver.org/). The public API is
the `--json` output shapes and the [exit-code table](docs/exit-codes.md); a
change to either that is not backward compatible bumps the major version.

Each GitHub Release on this repository carries the same notes as its section
below, plus the signed checksums for that version.

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
