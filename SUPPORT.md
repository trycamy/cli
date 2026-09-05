# Support

Where to take a problem with the `camy` CLI, and what to bring with it.

| What you have | Where it goes |
| --- | --- |
| Something is broken in the CLI | [Bug report](https://github.com/trycamy/cli/issues/new?template=bug_report.yml) |
| You want a command, flag, or behavior | [Feature request](https://github.com/trycamy/cli/issues/new?template=feature_request.yml) |
| A security concern | [SECURITY.md](SECURITY.md) — never a public issue |
| Account, billing, or the Camy product itself | [camy.ai/support](https://camy.ai/support) |

## Filing a bug

[Troubleshooting](docs/troubleshooting.md) covers the common failures; start
there. If yours is not one of them, include the output of
[`camy version --json`](docs/reference/camy_version.md) and
[`camy doctor`](docs/reference/camy_doctor.md) in the report. Neither prints
secrets.

## Docs and release notes

[The documentation](docs/README.md) covers installation, authentication,
scripting with `--json`, and every command. Release notes are in
[CHANGELOG.md](CHANGELOG.md).
