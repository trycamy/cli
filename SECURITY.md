# Security

`camy` runs on your machine, holds a key to your Camy account, and can be
asked to read files and run commands there. This page covers how to report a
vulnerability, what is in scope, and the safety properties the CLI is built
to hold.

## Reporting a vulnerability

Report privately, through GitHub private vulnerability reporting:

**<https://github.com/trycamy/cli/security/advisories/new>**

Do not open a public issue, pull request, or discussion for a security
problem. A report should stay private until a fix is available. Ordinary
bugs belong in public issues — see [SUPPORT.md](SUPPORT.md).

Include as much of this as you have:

- The output of [`camy version --json`](docs/reference/camy_version.md), which carries the version, OS and architecture, plus your OS version (for example macOS 15.2, Ubuntu 24.04).
- The exact commands you ran, and what you expected versus what happened.
- A minimal reproduction. Say what an attacker must already control: network position, local access to the machine, or a cooperating server.
- Your assessment of the impact.
- Any `request_id` from a `--json` error object.

Redact your API key and any private data before you attach anything.
[What to redact](#what-to-redact) lists what is safe to paste.

We acknowledge reports and keep you informed while we investigate. There is
no published response-time commitment, and no bounty program.

## Scope

In scope:

- The `camy` binary and the release artifacts published from this repository.
- The installer script served at `https://camy.ai/cli/install.sh`.
- The release channel and its artifacts: tarballs, checksums, signatures, and SBOMs.

Reports we especially want:

- Exposure of a stored key.
- An escape from the local bridge's project-root boundary or its secret-path denylist.
- Execution of a local command this CLI never witnessed an approval for.
- Terminal injection through server-supplied text.
- A way past an approval without a human decision.
- Any weakness in how a download is verified.

Out of scope here: the Camy service itself, the web app, accounts, and
billing. Take those to [camy.ai/support](https://camy.ai/support).

## Supported versions

| Version | Supported |
| --- | --- |
| Latest 1.x release | Yes |
| Anything older | No — update first |

Fixes ship as a new release on the release channel. There are no backports.
Update in place with [`camy update`](docs/reference/camy_update.md):

```bash
camy update --check
camy update
```

A Homebrew-managed install updates with `brew upgrade camy`; `camy update`
refuses to overwrite a binary Homebrew tracks.

## Credentials

[`camy auth login`](docs/reference/camy_auth_login.md) signs you in through a
browser device flow and mints an API key with a scope set, and an expiry when
the server sets one. The browser session behind it is never written to disk.
Only the minted key is stored as a credential; camy also records its scopes
and expiry date as plain metadata in the profile's state directory.

The verification URL is handed to the system browser only when it is on the
same domain as your configured `api_url`. Otherwise camy refuses to open it
and aborts the sign-in, pointing you at `camy auth login --code`.

Where the key lives:

- In the operating system keychain, under one entry per profile.
- If the keychain is unavailable, in a `credentials` file in that profile's state directory, created with mode 0600 — and camy tells you it fell back. [`camy doctor`](docs/reference/camy_doctor.md) reports the same thing as a warning, not a failure, because the file fallback genuinely works.

Both files are written defensively. `config.toml` goes to a randomly named
temporary file in the same directory and is renamed into place. The
`credentials` file is written directly, created 0600 with `O_EXCL` so its
first inode never exists at a looser mode. For both, camy refuses to write
through a path that is already a symlink.

Supplying a key without signing in:

- There is deliberately no `--api-key` flag. A key on the command line lands in shell history and in process listings.
- `CAMY_API_KEY` is the supported headless path. It wins over the keychain and is never persisted. If you also named a profile, camy prints a caution once per run, so you always know which account the output belongs to. Machine output (`--json`, `--jq`, `--template`) carries no such caution — check the `key_source` field of [`camy auth status --json`](docs/reference/camy_auth_status.md) instead.
- `camy auth login` cannot run non-interactively: it refuses `--no-input` and points at `CAMY_API_KEY`.

Ending a session, with
[`camy auth logout`](docs/reference/camy_auth_logout.md):

```bash
camy auth logout
camy auth logout --revoke
camy auth logout --revoke --confirm revoke
```

Plain `logout` removes the key from this machine. `--revoke` also revokes it
server-side, so a copy taken from a backup or a stale terminal stops working.

Revocation is irreversible, so it requires typing `revoke` at the prompt or
passing `--confirm revoke`; neither `--force` nor `--no-input` gets past that
gate. If the active key came from `CAMY_API_KEY`, `--revoke` refuses rather
than revoking a key the environment supplied.

[`camy keys`](docs/reference/camy_keys.md) manages keys server-side.
[`camy keys rotate`](docs/reference/camy_keys_rotate.md) and
[`camy keys revoke`](docs/reference/camy_keys_revoke.md) never touch the
locally stored credential, so rotating the key this machine is using means
signing in again to store the new one.

[Authentication](docs/authentication.md) has the details.

What diagnostics print:

- `camy auth status` shows the first 12 characters of the key and where it came from. Never more.
- `camy doctor` reports whether the stored key authenticates and which host answered. It prints no key material.
- `--verbose` adds one line naming the key's 12-character prefix and its source, plus agent trace lines. It prints no key material.
- Every error message, hint, and the panic handler run through a redaction pass that masks anything shaped like a `camy_live_…` or `camy_test_…` key, so a key echoed back by a server does not land intact in your terminal or your logs.

## The approval model

Anything that reaches outside the conversation — running a command on your
machine, writing a file, an action that needs a human decision — pauses and
waits for an approval.

- The prompt reads `/dev/tty` directly, never stdin. Piping `yes` into camy cannot answer an approval.
- Headless runs fail closed. With `--no-input`, with machine output (`--json`, `--jq`, `--template`), or with no controlling terminal, nothing runs: camy exits **4** and prints the checkpoint id so you can decide out of band. See [Exit codes](docs/exit-codes.md).
- A timeout is not an answer. The `/dev/tty` prompt gives up after two minutes and leaves the approval pending; the full-screen surface waits. Neither ever approves or denies for you.
- `y` or `yes` approves. `o` prints a link to the approval on the web and asks again — it decides nothing. On a local command card the CLI also offers `a` (always), which approves the command and records a standing grant for that exact command in this project; it is never offered for a command the destructive floor would refuse. Anything else, including an empty answer, rejects.
- There is no yes-to-everything flag. `--force` skips destructive-operation confirmations elsewhere in the CLI and has no effect on an approval.

Pending approvals are handled with
[`camy approvals`](docs/reference/camy_approvals.md):

```bash
camy approvals
camy approvals show <checkpoint-id>
camy approvals approve <checkpoint-id> --wait
camy approvals deny <checkpoint-id>
```

Approving a local command from a one-shot
[`camy approvals approve`](docs/reference/camy_approvals_approve.md) does not
by itself run it in that process. The process that executes must have
witnessed the approval: the session where you answered the prompt, or this
one when you pass `--wait`. [Approvals](docs/approvals.md) covers the model.

## The local bridge

When you chat from a terminal, camy can expose the current project directory
to the agent. That is the local bridge, and it is bounded.

Turning it down or off:

| Setting | Effect |
| --- | --- |
| `--json`, `--jq`, `--template` | Off entirely. No local tools are offered to the server at all. |
| `--no-local`, `CAMY_NO_LOCAL=1` | Off, in any session. |
| `--read-only`, `CAMY_LOCAL_READONLY=1` | Reads stay. Running commands and writing files are dropped. |

What holds when it is on:

- **Reads are scoped.** Reading a file, listing a directory, and searching run inside the project root without a prompt.
- **Writes and commands ask.** Writing a file always raises an approval card describing what was proposed. Running a command raises one too, with two exceptions the CLI decides for itself: a command you pre-granted with `camy local trust`, and a command the server marks as a pure read that the CLI independently re-verifies to be read-only and confined to the project root (`ls`, `git status`, `grep` and similar). That one runs without asking, and is announced as `auto-approved — read-only`.
- **One path boundary.** Every path — a read target, a command's working directory, a write target — goes through the same check: it must resolve inside the project root, and a symlink pointing outside is refused even when the path itself looked fine.
- **A secret-path denylist.** Paths that look like credentials are refused whether or not they sit inside the project: `.ssh`, `.aws`, `.gnupg`, `.kube`, `.docker`, `secrets`, `credentials` and `certs` directories, `.env` files, `.netrc`, `.npmrc`, `.git-credentials`, `.pem` and other key extensions, private-key filenames, macOS keychains, browser cookie and password stores, and camy's own state directory. `.env.example` and `.pub` files are exempt, and an ordinary source file whose name merely contains the word "secret" — `src/credentials.ts`, `docs/secrets.md` — is not blocked.
- **Output hygiene.** Two specific secret shapes — an AWS secret-key assignment and a `-----BEGIN … KEY-----` block — are replaced line-by-line before file contents, search matches, or command output reach the model. This is a narrow net over obvious key blobs, not a general secret scanner; the path denylist above is the real boundary.
- **A destructive floor that approvals cannot override.** `sudo`, `rm -rf` against a root-ish or unprovable target, `mkfs` and `diskutil erase`, `chmod -R 777` on a root-ish target, `git push --force`, the macOS keychain, Gatekeeper and SIP tools, interpreter flags that run inline code, and `curl … | sh` pipelines are all refused. The floor is checked when the command is proposed, again immediately before it runs, and once more if you try to save a standing grant — a destructive command can never become an "always allow".
- **Commands run without a shell.** The child process gets an allowlisted environment (`PATH`, `HOME`, `LANG`, `TERM`, `TMPDIR`, `SHELL`) and never inherits your API key. Output is capped per stream, the default timeout is 30 seconds with a 300-second ceiling, and a timeout kills the whole process group.
- **Nothing executes on the server's word alone.** A write or command request is refused as unapproved unless it correlates to an approval this CLI process itself witnessed. A backend that skipped the approval gets a refusal, not a slower path to the same result.

Standing grants are explicit and narrow, via
[`camy local trust`](docs/reference/camy_local_trust.md):

```bash
camy local trust list
camy local trust add -- npm test
camy local trust remove -- npm test
```

A grant matches an exact argument list unless you pass `--prefix`, and camy
prints a caution on every prefix grant, sharpest when the prefix is a bare
binary name. Writing a file has no auto-run carve-out: a write prompts every
time.

The destructive floor is a floor, not a proof. A sufficiently obfuscated
command can still get past a static check, which is why the approval card
exists. [The local bridge](docs/local-bridge.md) documents every tool and
limit.

## Output safety

Text that arrives from the server is treated as untrusted before it is
drawn. Escape sequences, control characters, bidirectional overrides, and
bare carriage returns are stripped, so a crafted message cannot repaint your
terminal, hide a line, or make a filename read backwards.

A server-suggested download filename is reduced to a plain basename. Only
`http` and `https` URLs are handed to the system opener; every other scheme
is refused, because the opener would dispatch it to whatever handler is
registered on your machine.

The one exception is [`camy vm shell`](docs/reference/camy_vm_shell.md), a
terminal passthrough to your workspace: bytes flow raw in both directions, as
they would over `ssh`. Treat that session like any other remote shell.
[Workspace](docs/workspace.md) has the details.

## Release integrity

Each release publishes:

- Per platform, a tarball — `camy_<version>_<os>_<arch>.tar.gz`, holding the binary and, when the release ships them, shell completions and man pages — and a CycloneDX SBOM for it.
- Per release, `SHA256SUMS`, plus a version-scoped checksum manifest with a cosign signature and certificate from keyless signing, and a minisign signature. From 1.0.1 on, a SLSA provenance statement over the tarballs, `camy_<version>.intoto.jsonl`, generated by the SLSA project's generator in an isolated job.

The installer and `camy update` verify a download the same way: HTTPS to the
release channel, then a SHA-256 of the tarball compared against the line in
`SHA256SUMS` for that exact filename. A missing, malformed, or mismatched
checksum installs nothing; the installer additionally refuses a `SHA256SUMS`
that carries two disagreeing lines for the same file.

The installer fetches the release's signed manifest and, where `minisign`
is installed, verifies its signature with the public key built into the
script before trusting a checksum; without minisign it says so and installs
on TLS plus checksum. From 1.0.1, `camy update` verifies the same signature
with a key built into the binary, and refuses to install anything the
release key did not sign.
[Verifying releases](docs/verifying-releases.md) has the `cosign verify-blob`
and `slsa-verifier` recipes, the channel layout, and how to read the SBOM. The minisign public key is published in
[Verifying releases](docs/verifying-releases.md), beside the cosign recipe.

The installer needs no `sudo`. It installs to `~/.local/bin` by default and
moves the binary into place with an atomic rename, and
`CAMY_NO_MODIFY_PATH=1` turns off the shell rc line and the `PATH` symlink it
would otherwise add. [Installation](docs/installation.md) has the full
walkthrough, including where completions and man pages land.

Two properties worth knowing:

- `camy update` stages the new binary in the same directory and renames it over the old one, so a failed update leaves the running binary untouched. There is no rollback step, because nothing is destroyed before the swap succeeds.
- `CAMY_DL_BASE`, the download-host override, is ignored by `camy update` on every released build — a poisoned shell profile cannot redirect an update at another host. The installer script does honor it, so treat the environment you pipe `install.sh` into as part of the trust decision.

The binary statically links open-source Go modules. The SBOM lists them with
versions; [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) reproduces their
licenses and ships inside every tarball, so a vulnerability report against a
dependency can name the exact module and version camy carries.

The GitHub Release on this repository is a verified mirror of the channel,
created by a public workflow in this repository
([release-mirror.yml](.github/workflows/release-mirror.yml)) that checks
every asset before uploading it.

## What to redact

Safe to paste as-is:

- `camy version --json` and `camy doctor` output — neither prints key material. `camy doctor` does show the account name or email the key belongs to and the full path of the binary, so redact those if the report is going somewhere public.
- The `request_id` from a `--json` error object. It helps us find the request and identifies nothing else.

Check before pasting:

- The one-time output of `camy keys rotate`, which prints a full new key. Never share it; rotate again if it leaks.
- Anything from a `--verbose` run, which includes the first 12 characters of your key.
- Command output, file contents, chat transcripts, and canvas files — those carry your own data rather than camy's.
- Your shell profile or CI configuration, if it sets `CAMY_API_KEY`.
