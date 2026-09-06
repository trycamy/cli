# Changelog

All notable changes to the camy CLI are recorded here.

Versions follow [Semantic Versioning](https://semver.org/). The public API is
the `--json` output shapes and the [exit-code table](docs/exit-codes.md); a
change to either that is not backward compatible bumps the major version.

Each GitHub Release on this repository carries the same notes as its section
below, plus the signed checksums for that version.

## 1.0.1 — unreleased

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
  built into the binary before it downloads anything.
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
