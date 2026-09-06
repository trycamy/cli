<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/camy-logo-white.png">
    <img src="docs/assets/camy-logo.png" alt="Camy" width="150">
  </picture>
</p>

<p align="center">
  <b>Camy in your terminal.</b><br>
  Triage the inbox, draft the replies, chase the invoice, hold the calendar,<br>
  review the diff, run the tests, publish the site, schedule the rest.<br>
  One binary, in every shell, pipe, and cron job you already have.
</p>

<p align="center">
  <a href="https://github.com/trycamy/cli/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/trycamy/cli?display_name=tag&sort=semver&style=flat-square&labelColor=1c1108&color=d04a1c"></a>
  <a href="https://github.com/trycamy/cli/releases/latest"><img alt="Release date" src="https://img.shields.io/github/release-date/trycamy/cli?style=flat-square&labelColor=1c1108&color=7a5f50&label=released"></a>
  <a href="https://github.com/trycamy/cli/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/trycamy/cli/ci.yml?branch=main&style=flat-square&labelColor=1c1108&label=ci"></a>
  <a href="docs/installation.md#homebrew"><img alt="Homebrew" src="https://img.shields.io/badge/brew_install-camy-1c1108?style=flat-square"></a>
  <a href="docs/installation.md"><img alt="Platforms" src="https://img.shields.io/badge/macOS_%C2%B7_Linux-arm64_%C2%B7_amd64-1c1108?style=flat-square"></a>
  <a href="docs/README.md"><img alt="Documentation" src="https://img.shields.io/badge/docs-read-1c1108?style=flat-square"></a>
  <a href="SECURITY.md"><img alt="Security policy" src="https://img.shields.io/badge/security-policy-1c1108?style=flat-square"></a>
</p>

<p align="center">
  <a href="#install">Install</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="docs/quickstart.md">Quick start</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="docs/README.md">Docs</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="docs/reference/camy.md">Reference</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="docs/scripting.md">Scripting</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="SECURITY.md">Security</a>
</p>

<br>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/camy-chat-dark.png">
    <img src="docs/assets/camy-chat.png" alt="A camy chat: the agent reads the inbox and calendar, answers, and pauses on an approval before a payment; the human types y and the turn resumes." width="760">
  </picture>
  <br>
  <sub>Ask. It reads, it answers, and it stops at the amber box until you say <code>y</code>. Real output, sample data.</sub>
</p>

<br>

## Install

```bash
# macOS and Linux, arm64 and amd64. No sudo.
curl -fsSL https://camy.ai/cli/install.sh | sh

# or, with Homebrew
brew tap trycamy/tap && brew install camy

# or, with npm
npm install -g @camy/cli
```

Nothing unpacks until its checksum matches. [Installation](docs/installation.md)
covers manual downloads, pinning a version,
[`camy update`](docs/reference/camy_update.md), and uninstalling.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/camy-install-dark.png">
    <img src="docs/assets/camy-install.png" alt="The installer: checksum verified, installed to ~/.local/bin, completions and man pages in place, ready in this terminal." width="760">
  </picture>
  <br>
  <sub>The installer, as it runs.</sub>
</p>

## Sixty seconds

```bash
camy auth login                          # browser handoff; a scoped, expiring key lands in your keychain
camy status                              # what is happening right now
camy chat "what needs me before noon?"   # one turn, streamed, with every tool call
git diff | camy chat "review this"       # stdin is context, stdout is the reply
camy approvals                           # what is waiting on you
camy inbox --needs-you                   # the rows that need a decision
camy vm exec -- pytest -q                # your cloud workspace; the exit code is mirrored
```

No `--api-key` flag exists. Sign in once; the key lives in your keychain, and
scripts read `CAMY_API_KEY`. Bare `camy` opens the full-screen app.
[Quick start](docs/quickstart.md) walks the whole minute.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/camy-status-dark.png">
    <img src="docs/assets/camy-status.png" alt="camy status: one approval waiting, two inbox rows that need you, two jobs active, the workspace running." width="640">
  </picture>
  <br>
  <sub><code>camy status</code>: what needs you, and the command that opens it.</sub>
</p>

## What it does

<table>
<tr>
<td width="33%" valign="top">
<b><a href="docs/chat.md">Chat</a></b><br>
Ask; watch every tool call stream. Anything risky stops for you. <code>-c</code> continues, stdin is context.
</td>
<td width="33%" valign="top">
<b><a href="docs/approvals.md">Approvals</a></b><br>
The pauses. Approve, deny, or answer from anywhere; <code>--wait</code> streams the resumed turn.
</td>
<td width="33%" valign="top">
<b><a href="docs/inbox.md">Inbox</a></b><br>
A verdict on every message: needs you, handled, filed. Reply, undo, restore. A sweep dial from off to auto.
</td>
</tr>
<tr>
<td width="33%" valign="top">
<b><a href="docs/workspace.md">Workspace</a></b><br>
Your cloud computer. <code>vm exec</code> hands you the exit code, ssh-style; <code>vm shell</code> is a live PTY.
</td>
<td width="33%" valign="top">
<b><a href="docs/local-bridge.md">Local bridge</a></b><br>
The same agent in the project you are standing in. One card per action; secrets and destructive commands refused.
</td>
<td width="33%" valign="top">
<b><a href="docs/automation.md">Automation</a></b><br>
Schedules, durable jobs, tasks, capture, webhooks. The same binary, in cron or CI.
</td>
</tr>
<tr>
<td width="33%" valign="top">
<b><a href="docs/canvas.md">Canvas</a></b><br>
What a chat built, on disk: files, snapshots, published sites.
</td>
<td width="33%" valign="top">
<b><a href="docs/scripting.md">Scripts</a></b><br>
<code>--json</code> everywhere, <code>--jq</code> and <code>--template</code> built in, NDJSON streams, frozen exit codes.
</td>
<td width="33%" valign="top">
<b><a href="docs/terminal.md">Terminal</a></b><br>
Truecolor to plain. <code>NO_COLOR</code>, <code>--accessible</code>, hyperlinks and inline images where supported.
</td>
</tr>
</table>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/camy-inbox-dark.png">
    <img src="docs/assets/camy-inbox.png" alt="camy inbox: four rows, each with a verdict: two need you, one handled, one filed." width="760">
  </picture>
  <br>
  <sub><code>camy inbox</code>: a verdict on every row.</sub>
</p>

## The leash

Anything risky pauses for a human. The pause is the safety model, not a setting.

- **It fails closed.** Headless, with `--no-input`, `--json`, or no terminal, the approval stays pending and the exit is `4` with its id. Timeouts never approve and never deny.
- **It reads `/dev/tty`, never stdin.** Piped input cannot answer a prompt. There is no yes-to-everything flag.
- **The local bridge asks per action.** Reads run; every write and every command shows the exact command or diff first. `.env`, `~/.ssh`, keys, credential stores, `sudo`, and `rm -rf` on root-like targets are refused, whatever anyone approved.

[Approvals](docs/approvals.md) · [The local bridge](docs/local-bridge.md) · [SECURITY.md](SECURITY.md)

## Scripts

stdout is data. stderr is everything else. `--json` on any command, `--jq`
and `--template` built in, streams as NDJSON. Exit codes, frozen for 1.x:

| `0` | `1` | `2` | `3` | `4` | `5` | `6` | `7` | `8` | `255` |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| ok | runtime | usage | auth | approval pending | rate limited | plan | unavailable | approval denied | `vm exec` itself failed |

```bash
camy inbox --needs-you --json --jq '.[].subject'
camy api GET /v1/jobs --jq '.[].id'
camy chat --no-input "post the nightly summary"   # exit 4: waiting on you, not a failure
```

[Scripting](docs/scripting.md) · [Exit codes](docs/exit-codes.md)

## Documentation

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/camy-help-dark.png">
    <img src="docs/assets/camy-help.png" alt="camy --help: the core commands, the system commands, and the contract line: every command takes --json, exit codes are a public API." width="640">
  </picture>
</p>

Every guide is in [docs](docs/README.md); every command and flag is in the
[reference](docs/reference/camy.md), generated from the binary. `camy docs`
carries the topics offline, and every command answers `--help`.

<br>

<p align="center">
  <a href="SUPPORT.md">Support</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="SECURITY.md">Security</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="CHANGELOG.md">Changelog</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="CODE_OF_CONDUCT.md">Conduct</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="THIRD-PARTY-NOTICES.md">Third-party notices</a>&nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="LICENSE.md">License</a>
</p>

<p align="center">
  <sub>© 2026 CamyAI, Inc. All rights reserved.</sub>
</p>
