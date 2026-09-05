# Contributing

This repository holds the public documentation for the `camy` CLI, a
mirror of the installer script, the [changelog](CHANGELOG.md), and the
GitHub Releases that carry each version's signed checksums. The CLI's
source is not published here, so this is not where the CLI is built.

Pull requests are welcome for two things: documentation and the installer
script, both covered below. A change to command behavior, flags, or
output cannot land here — the code that produces those lives elsewhere.
Open an [issue](https://github.com/trycamy/cli/issues/new/choose)
instead; it goes to the team that owns the source.

## Bug reports

Start with these two:

```bash
camy version --json
camy doctor
```

Paste both into a
[bug report](https://github.com/trycamy/cli/issues/new?template=bug_report.yml),
along with:

- The exact command you ran, with any placeholder values marked as such.
- What you expected to happen and what actually happened.
- The exit code. Run `echo $?` right after the command and include the
  number; the [exit codes](docs/exit-codes.md) reference explains what
  each one means.
- The `--json` output of the failing command, rather than a screenshot
  of the human-readable version. Every command accepts `--json`; the few
  that are text-only on purpose are listed in
  [Scripting](docs/scripting.md).

Neither [`camy version --json`](docs/reference/camy_version.md) nor
[`camy doctor`](docs/reference/camy_doctor.md) prints an API key.
`camy doctor` does show the install path and, when you're signed in, the
account name or email on the key — redact those if you'd rather not
share them.

If the failure is intermittent or timing-related, re-run with `--json`
and include the error object. It carries `request_id` for any REST call
the server tagged with one, and is empty for errors that arrive over the
chat WebSocket.

`--verbose` adds the credential-source line and extra detail on
chat-stream failures; include it too, though it does not print request
IDs.

[`camy api`](docs/reference/camy_api.md) prints the response without
needing `--json` — re-indented when the body is JSON, printed as-is with
terminal escape sequences stripped when it isn't, and reshaped by `--jq`
or `--template` if you pass them.

### Redacting output

Before pasting, take out anything personal: email addresses, file paths
under your home directory, workspace or chat content, and any bearer
token.

An API key appears in normal output in exactly one place.
[`camy keys rotate`](docs/reference/camy_keys_rotate.md) prints the new
key once, in human output and under `--json`. Never paste that.

[`camy auth status`](docs/reference/camy_auth_status.md) — human and
`--json` — and `--verbose` print only the first twelve characters of
your key (`auth: camy_… key from …`); drop those before you paste, and
check a raw `camy api` response the same way.

## Feature requests

Open a
[feature request](https://github.com/trycamy/cli/issues/new?template=feature_request.yml)
describing the workflow you're trying to get through, not just the flag
you want. Say what you'd run today and where it falls short.

If you have one in mind, propose the interface: the command and flag
names, and, if it should support [`--json`](docs/scripting.md) the way
most camy commands do, the shape of its JSON output. A concrete example
request/response pair is more useful than a general description.

## Documentation

Documentation lives under [`docs/`](docs/README.md). Run the link checker
before you open a pull request:

```bash
python3 scripts/check-docs.py
```

It walks every Markdown file in the repository and fails if a relative
link points at a file that doesn't exist. A few more things to know:

- Everything under `docs/reference/` is generated from the binary itself
  and should never be hand-edited — a pull request touching it will be
  closed. If a reference page is wrong or out of date, open an issue
  instead; it will be regenerated at the next release.
- Every page outside `docs/reference/` is regular Markdown and is fair
  game: fixing an unclear explanation, a broken example, a missing
  cross-link, or extending a topic that's thin.
- Match the existing voice: second person, present tense, plain words, no
  emoji, no marketing adjectives. Show commands in fenced code blocks,
  one per line. Mark placeholders clearly (`<id>`, `<chat-id>`) rather
  than using a value that looks real.
- Don't promise a feature the CLI doesn't have yet. If a command's own
  help text says something isn't available, the docs should say the same
  and no more.
- Reference pages close with a `## See also` list of cross-links. The two
  onboarding pages, [`installation.md`](docs/installation.md) and
  [`quickstart.md`](docs/quickstart.md), close with `## Next steps` and
  `## Where to go next` instead.

By opening a pull request you agree that your contribution is licensed to
CamyAI, Inc. on the terms in [LICENSE.md](LICENSE.md), and may be
published as part of this documentation.

## The installer mirror

`scripts/install.sh` in this repository is published as-is at
`https://camy.ai/cli/install.sh`. It is not templated or rewritten before
it goes live.

A CI job diffs this file against the copy served from the release channel
at `https://dl.camy.sh/install` and fails a pull request that would let
them drift apart.

The mirror follows the channel, so a pull request that changes
`scripts/install.sh` only passes once the same bytes are already served
there. Open an issue describing the change rather than a pull request
against this file.

If you're updating the mirror to match a change already published to the
channel, run the installer's own test harness first:

```bash
sh scripts/install_test.sh
```

It spins up a local fake release channel and exercises the checksum,
version-resolution, install-directory, and completion install logic the
real installer relies on.

## Code of conduct

Everyone participating in this repository — issues and pull requests — is
expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
