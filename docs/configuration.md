# Configuration

`camy` takes its settings from three places: per-invocation flags,
environment variables, and one config file. A flag beats an environment
variable, which beats the config file.

To see every setting, its effective value, and which of the three produced
it:

```bash
camy config list --show-origin
```

```text
api_url = https://api.camy.ai	default
color = auto	default
editor = vi	default
pager = less -FRX	default
default_profile = default	default
```

The second column is the rung the value came from. This page covers where
the files live, every `config.toml` key, how the pieces combine into an
effective value, and the environment variables that change how `camy`
behaves.

## Where things live

`camy` follows the XDG base directory variables when they are set, and
falls back to defaults under your home directory otherwise. For these
three directories it uses an XDG variable only when its value is an
absolute path; a relative value is ignored and the default under your home
directory is used instead. If that leaves any of them without an absolute
path, because `HOME` itself is not one, every command stops with an error
asking you to set `HOME` (or all three XDG variables) to an absolute path.

| What | Default path | XDG override |
|---|---|---|
| Config file | `~/.config/camy/config.toml` | `$XDG_CONFIG_HOME/camy/config.toml` |
| Per-profile state | `~/.local/state/camy/<profile>/` | `$XDG_STATE_HOME/camy/<profile>/` |
| Cache | `~/.cache/camy/` | `$XDG_CACHE_HOME/camy/` — reserved; nothing is written here today, but [camy uninstall](reference/camy_uninstall.md) removes it when you ask it to also remove config and state |

Per-profile state is deliberately kept out of `~/.config`. `config.toml` is
the kind of file people sync between machines or check into a dotfiles
repo; the state directory is not. It holds what belongs to one machine and
one profile:

- the credential fallback file (`credentials`)
- the local bridge's trust store (`local_trust.json`)
- granted scopes and key expiry
- the last chat id and the chat mode
- the update-check stamp
- when `camy` last checked for a Terms of Service and Privacy Policy
  notice, and which notice you have read with
  [camy legal notice](reference/camy_legal_notice.md)
- your chat input history (`history`)
- any local-tool results still waiting to be replayed (`pending_tool_results.json`)

That is why it lives under `~/.local/state` (or `$XDG_STATE_HOME`)
instead, away from anything you'd want to sync or share.

File modes matter here. None of them are configurable; they are how `camy`
protects files that may hold your API key.

| Path | Mode | How it is enforced |
|---|---|---|
| `config.toml` | `0600` | Written atomically — temp file, fsync, rename. |
| State directory | `0700` | Created at that mode; files `camy` creates inside it are created at `0600`. |
| `credentials`, `local_trust.json` | `0600` | Re-hardened on every write, whatever mode they were left in. |
| `history` | `0600` | Checked and re-hardened when a chat session opens it, and refused outright if something has replaced it with a symlink. |

Where your key is actually stored (keychain vs. file fallback), and how
[camy auth](reference/camy_auth.md) manages it, is covered in
[Authentication](authentication.md).

## config.toml

`config.toml` holds five top-level settings, an `[aliases]` table, and one
`[profile.<name>]` table per profile:

```toml
api_url = "https://api.camy.ai"
color = "auto"
editor = "vim"
pager = "less -FRX"
default_profile = "work"

[aliases]
jj = "jobs"

[profile.work]
api_url = "https://api.camy.ai"
editor = "code --wait"
```

| Key | Meaning | Built-in default |
|---|---|---|
| `api_url` | The API origin `camy` talks to. Must be an `https://` address; plain `http://` is allowed only for a local address such as `localhost` or `127.0.0.1`. | `https://api.camy.ai` |
| `color` | `auto`, `always`, `never`, or `off`. Only `never` and `off` change anything — they turn color off everywhere; `always` is accepted but does not force color on (use `--color always` or `FORCE_COLOR` for that). See [Terminal output and accessibility](terminal.md). | `auto` |
| `editor` | The command used to open files interactively — `camy config edit` and any other `--edit` flow. A program name or an absolute path, then plain arguments; see below. | `vi` |
| `pager` | The command output is piped through when paging applies. Set it to `off` (or `cat`) to disable paging permanently — the persistent form of `--no-pager`. A program name or an absolute path, then plain arguments; see below. | `less -FRX` |
| `default_profile` | Which `[profile.<name>]` table is active when nothing else picks one. Must be a plain profile name; see [Profiles](#profiles). | `default` |
| `aliases` | A table of user-defined shorthands; see [Aliases](#aliases) below. | — |
| `profile.<name>` | Per-profile overrides for `api_url`, `editor`, and `pager`. A profile doesn't need a table here to exist — see [Profiles](#profiles). | — |

Only `api_url`, `color`, `editor`, `pager`, and `default_profile` are
settings `camy config` knows how to read and write. `aliases` are managed
with `camy alias` instead, and no command writes a `[profile.<name>]` table
at all.

`editor` and `pager` are run as programs, so each must be a program name or
an absolute path, followed by plain arguments such as `--wait` or `-FRX`.
`camy config set editor` and `camy config set pager` refuse any other value
and say why. A value already in `config.toml` or a profile table that
doesn't fit is ignored, with a note each time `camy` runs: files then open
in `$EDITOR` or `vi`, and output pages through `CAMY_PAGER`, `PAGER` or
`less -FRX`. If you see that note after updating, set a plain command, for
example:

```bash
camy config set editor "code --wait"
```

Hand-written comments in `config.toml` survive as long as you only edit the
file with `camy config edit` or a text editor. `camy config set`, `camy
config unset`, `camy profile use`, `camy alias set`, and a successful `camy
alias rm` all rewrite the file by re-encoding it, which does not preserve
comments. A failed `alias rm` leaves the file untouched.

## Precedence

For each setting, `camy` resolves a value by walking a fixed ladder and
taking the first rung that has one:

1. **flag** — a command-line flag for this invocation, e.g. `--api-url`
2. **env** — an environment variable, e.g. `CAMY_API_URL`
3. **profile** — the value in the active `[profile.<name>]` table
4. **config** — the top-level value in `config.toml`
5. **default** — the built-in default

`--show-origin` names the winning rung. It works on `camy config get` as
well as `camy config list`:

```bash
camy config get api_url --show-origin
```

```text
https://api.camy.ai	default
```

The `env` rung shows up when the environment sets the value:

```bash
CAMY_API_URL=https://api.example.com camy config get api_url --show-origin
```

```text
https://api.example.com	env
```

Not every setting has a flag or an env rung. `editor` has no dedicated
flag. `pager`'s config-ladder value has no env rung at all — the
`CAMY_PAGER` variable works differently, described under
[Environment variables](#environment-variables) below.

`color` is not resolved through this ladder for the purpose of `camy config
get color`. That command reports only what is written in `config.toml`,
defaulting to `auto`. The runtime color decision — which also looks at
`--color`, `NO_COLOR`, and friends — is a separate mechanism, documented in
[Terminal output and accessibility](terminal.md).

Which profile is active is itself resolved by a shorter ladder: the
`--profile` flag, then `CAMY_PROFILE`, then `default_profile` in
`config.toml`, then the profile named `default`.

`camy config get default_profile` reports the same two rungs `color` does —
`config` or `default`, never `flag` or `env` — even though `--profile` and
`CAMY_PROFILE` resolve which profile is active elsewhere.

A bad `api_url`, one that isn't an `https://` address or `http://` to a
local address, behaves differently depending on where it comes from. A bad
`--api-url` flag or `CAMY_API_URL` value is a hard error: `camy` refuses to
run and exits with a usage error (2).

A bad `api_url` sitting in `config.toml` or a profile table is not. `camy`
ignores it, falls back to the built-in default, and prints a warning — once
per command run, until you fix the value — telling you to fix it with
`camy config set api_url`. `-q` hides the warning. An `editor`, `pager` or
`default_profile` in the file that `camy` can't use is handled the same
way: ignored, with a note that names it. A bad `default_profile` is
ignored and `default` is used, but `camy config get` and `camy config list`
still print the value written in `config.toml`, with origin `config`. Fix
it with `camy profile use NAME`.

That asymmetry is deliberate. The config ladder is resolved before every
command runs, including `camy config set` itself, so a hard failure there
would lock `camy config set` and `camy config edit` out of repairing the
file.

## Where your key is sent

Changing `api_url` does not move your key with it. `camy` sends a key only
to the Camy it belongs to:

- A key `camy` stores when you sign in is tied to the `api_url` you signed
  in at. `camy` never sends it to another address, even with `--api-url`.
- A key from `CAMY_API_KEY`, or one stored by an earlier version of `camy`,
  is tied to no address. `camy` sends it to `https://api.camy.ai`, to a
  local address, or to the address `--api-url` or `CAMY_API_URL` names for
  that command, but not to another address set only by the `api_url`
  setting in `config.toml` or a profile table.

When the key and the address don't match, `camy` sends nothing and stops
with a usage error (2) whose hint names the command that fixes it.

If `config.toml` or a profile table points `api_url` at an address other
than `https://api.camy.ai` or a local address, sign in again at that
address after updating:

```bash
camy auth login --api-url https://camy.example.com
```

Until you do, pass `--api-url` or set `CAMY_API_URL` on each command that
should go there. See [Authentication](authentication.md) for how keys are
stored.

## The config command

```bash
camy config set editor "code --wait"
camy config get editor
camy config unset editor
camy config list --json
```

[camy config](reference/camy_config.md) has five subcommands:

| Command | Does |
|---|---|
| [camy config get KEY](reference/camy_config_get.md) | Print one setting's effective value. `--show-origin` appends which rung produced it; `--json` prints one `{"key", "value", "origin"}` object. |
| [camy config set KEY VALUE](reference/camy_config_set.md) | Write a setting to `config.toml`. Checks the value first; one `camy` can't use is a usage error, and nothing is written. |
| [camy config unset KEY](reference/camy_config_unset.md) | Remove a setting from `config.toml`, reverting it to its default. |
| [camy config list](reference/camy_config_list.md) | Print every settable key's effective value. `--show-origin` appends origins; `--json` emits an array of `{"key", "value", "origin"}`. |
| [camy config edit](reference/camy_config_edit.md) | Open `config.toml` in the resolved `editor` (`$EDITOR`, then the `editor` setting, then `vi`). Interactive only — refuses under `--no-input` with a hint to use `config set` in scripts. On a machine with no `config.toml` yet, it creates one containing `color = "auto"` so the editor has a file to open — after which `camy config get color --show-origin` reports `config` instead of `default`. |

`config get` and `config set` only recognize the five keys listed above; an
unknown key is a usage error. `config get` and `config list` show the
active profile's resolved value; pass the global `--profile NAME` to read
another profile's settings without changing your default.

`camy config get KEY --json` prints an object, not the bare value. A
script that read the bare value from it needs updating: read `.value`, or
drop `--json`, since plain `camy config get KEY` still prints the value
alone.

```bash
camy config get api_url --json --jq .value
```

```text
https://api.camy.ai
```

## Profiles

A profile is a named set of credentials and settings: its own keychain
entry, its own state directory, and optionally its own `api_url`, `editor`,
and `pager` in a `[profile.<name>]` table. Profiles let you keep more than
one Camy account, or an account against a different `api_url`, without them
stepping on each other.

```bash
camy profile list
camy profile use work
```

### List profiles

```bash
camy profile list
```

```text
  default
  personal
✓ work

  camy profile use NAME · switches the default
  camy auth login --profile NAME · adds one
```

[camy profile list](reference/camy_profile_list.md), or bare
[camy profile](reference/camy_profile.md), shows `default`, each
profile that has a `[profile.<name>]` table in `config.toml`, and each
profile you have signed in to with `camy auth login --profile NAME`, even
with no table: `default` first, then the rest sorted by name, each once, in
the same order every run. A profile with no table that you have signed out
of is not listed. It marks the one recorded as `default_profile`. The mark
follows `config.toml` only: a `--profile` flag or `CAMY_PROFILE` changes
which profile the invocation uses, but not which row is marked. With
`--json` it prints the same rows, in the same order, as an array of
`{"name", "current"}` objects.

### Switch profiles

[camy profile use NAME](reference/camy_profile_use.md) persists `NAME` as
`default_profile` in `config.toml`. It does not itself check that a
`[profile.NAME]` table exists, and a profile doesn't need one.

To use a profile for a single command without switching your default:

```bash
camy --profile work status
CAMY_PROFILE=work camy status
```

### Add a profile

The first time you sign in under a new profile name — with `--profile NAME`
or `CAMY_PROFILE=NAME` — that profile gets its own keychain entry and state
directory automatically.

Add a `[profile.NAME]` table only if you also want that profile to override
`api_url`, `editor`, or `pager`. Write it by hand with `camy config edit`
or any text editor; no command writes it for you.

A profile name is a plain name: letters, digits, `.`, `_` or `-`, starting
with a letter or digit, up to 64 characters. `--profile` or `CAMY_PROFILE`
with any other name stops with an error, `camy profile use` and
`camy config set default_profile` refuse it, and a `default_profile` in
`config.toml` that doesn't fit is ignored with a note, so `camy` uses
`default`. If you used a name outside this rule, pick a plain name and sign
in under it with `camy auth login --profile NAME`.

See [Authentication](authentication.md) for how credentials are stored per
profile.

## Aliases

```bash
camy alias set jj jobs
camy alias
camy alias rm jj
```

[camy alias](reference/camy_alias.md) manages shorthands for longer command
lines. Two are built in and need no configuration: `in` for `inbox`, and
`x` for `vm exec`. User-defined aliases live in `config.toml`'s `[aliases]`
table, and one of them takes precedence over a built-in with the same
name.

[camy alias set NAME EXPANSION...](reference/camy_alias_set.md) refuses to
shadow a real command name — `camy alias set inbox foo` is a usage error.
[camy alias rm NAME](reference/camy_alias_rm.md) errors if no such alias
exists.

Expansion only looks at the first word of the command line, and only when
it doesn't start with `-`. A match — built-in or user-defined — is replaced
by its expansion, splitting on whitespace, followed by whatever arguments
you typed after it. Expansion happens once; an alias that expands to
another alias's name is not expanded again.

Global flags inside an expansion work as if you had typed them, including
`--profile`, so an alias in `config.toml` can pin a profile:

```toml
[aliases]
wj = "jobs --profile work"
```

## Global flags

These flags are accepted by every `camy` command. Some have an environment
variable equivalent, which is useful for scripting — see
[Scripting with camy](scripting.md) for `--json`, `--jq`, `--template`,
and `--no-input` in more depth.

| Flag | Env equivalent | Effect |
|---|---|---|
| `--json` | — | Machine output: stable JSON or NDJSON streams. Errors come back as a JSON object on stderr, including an unknown or mistyped flag, wherever `--json` sits on the line. |
| `--jq EXPR` | — | Filter `--json` output with a built-in jq expression. |
| `--template TEXT` | — | Format `--json` output with a Go template. |
| `--raw` | — | With `--json` on a listing, print the endpoint's own body instead of the normalized array. [Scripting with camy](scripting.md) lists the exceptions. |
| `--ids hex` | — | Print the pre-1.0.3 eight-character ids in human output instead of typed short ids. A compatibility flag; don't build new scripts on it. |
| `-q`, `--quiet` | — | Suppress non-data stderr chrome, including the notes `camy` prints before a command starts. |
| `-v`, `--verbose` | — | Print one line on stderr for each API request most commands make, with the method, path, status, time taken and request ID. `camy api`, file uploads and downloads, and streamed chat and terminal sessions print none. Also shows where the active API key came from. |
| `--no-input` | — | Never prompt. A checkpoint fails closed (exit 4); any other prompt exits with a usage error (exit 2). |
| `-f`, `--force` | — | Skip a destructive-operation confirmation prompt. Does not bypass the stronger, typed-word confirmation `camy auth logout --revoke` uses. |
| `--color VALUE` | — | `auto`, `always`, or `never`. |
| `--ground VALUE` | `CAMY_GROUND` | `dark`, `light`, or `auto`: the palette's ground. `auto`, or leaving it off, lets `camy` detect it; see [Terminal output and accessibility](terminal.md#ground-dark-or-light). |
| `--accessible` | `CAMY_ACCESSIBLE=1` | Linear output: no spinners, boxes, or redraws. |
| `--no-pager` | — | Never page output. |
| `--no-truncate` | — | Never truncate table or list cells; long values may overflow a narrow terminal. |
| `--profile NAME` | `CAMY_PROFILE` | Profile to use for this invocation. |
| `--api-url URL` | `CAMY_API_URL` | API origin override. |
| `--no-local` | `CAMY_NO_LOCAL=1` | Disable the local bridge entirely for this session. |
| `--read-only` | `CAMY_LOCAL_READONLY=1` | Local bridge reads only — no `run_command`/`write_file` this session. |
| `--sandbox MODE` | `CAMY_LOCAL_SANDBOX` | `off`, `observe`, or `enforce`: how the operating system confines commands the local bridge runs, for this invocation only. Left unset, it is `enforce` where the OS can fully enforce it and `observe` elsewhere; see [The local bridge](local-bridge.md#the-boundary-and-the-sandbox). |
| `--cloud` | `CAMY_CLOUD=1` | Use your cloud workspace as the default, even with the local bridge live. |
| `--inline` | `CAMY_INLINE=1` | Classic scrollback app instead of the full-screen surface. |
| `--no-project-instructions` | `CAMY_NO_PROJECT_INSTRUCTIONS=1` | Never read this project's `AGENTS.md`/`CLAUDE.md` into a chat session. |
| `-h`, `--help` | — | Show help for the command. |

`-V`/`--version` is accepted on the bare `camy` command only (it prints
the same thing as [camy version](reference/camy_version.md): the version
on one line of stdout, with the sandbox note on stderr); every other row
above works on any command.

## Environment variables

### Authentication

| Variable | Effect |
|---|---|
| `CAMY_API_KEY` | Use this key instead of whatever is in the keychain or state fallback file. Wins over any stored credential whenever it holds a key; a value of only spaces, tabs or newlines counts as unset, so your profile's stored key is used. Never written to disk by `camy`. Not tied to an address; see [Where your key is sent](#where-your-key-is-sent). [camy auth logout](reference/camy_auth_logout.md) `--revoke` refuses to run when the active key came from this variable. |

See [Authentication](authentication.md) for the full credential model.

### API and profile

| Variable | Effect |
|---|---|
| `CAMY_API_URL` | Overrides `api_url` at the env rung of the [precedence ladder](#precedence). |
| `CAMY_PROFILE` | Selects the active profile, at the env rung of the profile-selection ladder. Must be a plain profile name; see [Profiles](#profiles). |
| `XDG_CONFIG_HOME` | Relocates `config.toml` to `$XDG_CONFIG_HOME/camy/config.toml`, and is also where the fish completion (`$XDG_CONFIG_HOME/fish/completions/camy.fish`) and the fish PATH line are written. |
| `XDG_STATE_HOME` | Relocates the per-profile state directory to `$XDG_STATE_HOME/camy/<profile>/`. |
| `XDG_CACHE_HOME` | Names the cache directory `camy uninstall` removes; nothing writes to it today. |

### Output and terminal

| Variable | Effect |
|---|---|
| `NO_COLOR` | Non-empty disables colored output and terminal hyperlinks; a link in a reply prints as `label (url)`. |
| `CLICOLOR=0` | Same effect as `NO_COLOR`. |
| `TERM=dumb` | Same effect as `NO_COLOR`, and also forces accessible (linear) output. |
| `FORCE_COLOR` | Non-empty lifts the "not a terminal" rule, so color survives a pipe or redirect. The level still comes from `COLORTERM`/`TERM`, with 16 colors when `TERM` is empty; a `dumb` `TERM` still yields no color, and `NO_COLOR`/`CLICOLOR=0` still win. |
| `CLICOLOR_FORCE` | Same effect as `FORCE_COLOR`. |
| `COLORTERM` | `truecolor` or `24bit` selects 24-bit color; otherwise `TERM` decides — a `256color` TERM gives 256 colors, an empty or `dumb` TERM gives none, anything else gives 16. When color is forced (`--color always`, `FORCE_COLOR` or `CLICOLOR_FORCE`), an empty TERM gives 16 instead. |
| `CAMY_ACCESSIBLE=1` | Linear output: no spinners, boxes, or redraws. Env equivalent of `--accessible`. |
| `CAMY_GROUND` | `light` or `dark` picks the palette's ground. Env equivalent of `--ground`, which wins over it. |
| `COLORFGBG` | Read as a hint for the palette's ground when neither `--ground` nor `CAMY_GROUND` is set. |
| `COLUMNS` | Overrides the output width camy uses — it wins over the measured terminal width, and supplies the width when there is no terminal (fallback 80). |
| `CAMY_PAGER` | Pager command, tried before the configured `pager` setting and before `PAGER`. |
| `PAGER` | Pager command, tried after `CAMY_PAGER` and the configured `pager` setting, before the built-in default `less -FRX`. Setting `CAMY_PAGER` or `PAGER` to `off` or `cat` disables paging for that invocation, same as the `pager` config value. |
| `EDITOR` | Editor command, used at the env rung of the `editor` setting's ladder. A whitespace-only value is treated as unset, not as an override. |
| `CAMY_NO_INLINE_IMAGES=1` | Disables inline terminal image rendering (generated images, [camy download](reference/camy_download.md) previews). |
| `TMUX` | Non-empty disables inline image protocol detection. |
| `KITTY_WINDOW_ID` | Non-empty selects the kitty inline-image protocol. |
| `LC_TERMINAL` | `iTerm2` selects the iTerm2 inline-image protocol. |
| `TERM_PROGRAM` | `iTerm.app` or `WezTerm` selects the iTerm2 inline-image protocol. |
| `TERM` | Containing `kitty` selects the kitty inline-image protocol. |
| `VTE_VERSION`, `WT_SESSION` | Additional signals `camy` uses to detect a hyperlink-capable terminal. |
| `LC_ALL`, `LC_CTYPE`, `LANG` | First non-empty variable is checked for UTF-8, to decide between Unicode and ASCII glyph fallback. |
| `XDG_SESSION_TYPE` | Presence makes `camy` shell out to `xdg-open` instead of `open` when opening a browser link. |

Full detail on color, paging, hyperlinks, and inline images lives in
[Terminal output and accessibility](terminal.md).

### Local bridge

| Variable | Effect |
|---|---|
| `CAMY_NO_LOCAL=1` | Disables the local capability bridge entirely for this invocation. Env equivalent of `--no-local`. |
| `CAMY_LOCAL_READONLY=1` | Keeps the bridge's write and exec tools off; reads only. Env equivalent of `--read-only`. |
| `CAMY_LOCAL_SANDBOX` | `off`, `observe`, or `enforce`: how the operating system confines commands the bridge runs. Env equivalent of `--sandbox`, which wins over it. |
| `CAMY_CLOUD=1` | Defaults a chat turn to your cloud workspace even with a live local bridge. Env equivalent of `--cloud`. |

See [The local bridge](local-bridge.md) for what these tools can and cannot do.

### Updates and installer

| Variable | Effect |
|---|---|
| `CAMY_CHANNEL` | Default update channel (`stable` or `canary`) for [camy update](reference/camy_update.md) `--channel`. |
| `CAMY_NO_UPDATE_NOTE=1` | Silences the once-daily "update available" note printed after a command. `CAMY_NO_UPDATE_CHECK=1` is accepted as an alias. |
| `CAMY_DL_BASE` | Overrides the release-channel base URL. `camy update` honors it only on an unstamped development build and only as a well-formed `https://` URL — a released binary ignores it and warns. The install script uses it only when it is an `https://` address, or plain `http://` to a local address, and stops with an error otherwise. |
| `CAMY_REQUIRE_SIGNATURE` | Install script only: the script won't install a release unless `minisign` is installed to check its signature. Set this to `0` to skip the check; the install is then protected by TLS and a checksum only. |
| `CAMY_INSTALL_DIR` | Install script only: overrides the install directory (default `$HOME/.local/bin`). Must be a plain absolute path; the script stops with an error otherwise. |
| `CAMY_NO_MODIFY_PATH=1` | Install script only: skips creating the `PATH` symlink and editing your shell rc file. |
| `CAMY_VERSION` | Install script only: pins an exact version to install instead of fetching the channel's latest. |
| `SHELL` | Installer: selects which shell rc file to edit for the `PATH` line. `camy` also passes it through to commands the local bridge runs. |
| `ZDOTDIR` | Install script only: when the shell is zsh, the directory holding the `.zshrc` that gets the `PATH` line (default `$HOME`). |
| `TMPDIR` | Installer: base directory for its temporary working directory. `camy` also passes it through to commands the local bridge runs. |
| `NO_COLOR` | Install script only: disables its own colored output. |
| `XDG_DATA_HOME` | Base directory for the bash/zsh completions and man pages (default `$HOME/.local/share`), written by both the install script and `camy update`; the fish completion goes under `XDG_CONFIG_HOME` instead. |

See [Installation](installation.md) for the installer walkthrough and
[Verifying releases](verifying-releases.md) for the channel layout.

### Chat

| Variable | Effect |
|---|---|
| `CAMY_INLINE=1` | Uses the classic scrollback app instead of the full-screen surface. Env equivalent of `--inline`. |
| `CAMY_NO_PROJECT_INSTRUCTIONS=1` | Never reads this project's `AGENTS.md`/`CLAUDE.md` into a chat session. Env equivalent of `--no-project-instructions`. |

See [Chat](chat.md) for project-instruction discovery and the full-screen app.

### Diagnostics

| Variable | Effect |
|---|---|
| `CAMY_APP_DEBUG` | Names a file the full-screen chat app appends turn-lifecycle timing breadcrumbs to. Diagnostic only. |
| `PATH` | Read by [camy doctor](reference/camy_doctor.md) to check whether the running binary's directory is on your `PATH`. `camy` also passes it through to commands the local bridge runs — `PATH`, `HOME`, `LANG`, `TERM`, `TMPDIR` and `SHELL` are the only variables such a command ever sees. |

## See also

- [Authentication](authentication.md) — how keys are stored, and what each profile keeps separately
- [Scripting with camy](scripting.md) — `--json`, `--jq`, `--template`, `--no-input`, and exit codes in scripts
- [Terminal output and accessibility](terminal.md) — color, paging, hyperlinks, and inline images in full
- [Exit codes](exit-codes.md) — what a usage error (2) or auth error (3) from these commands means
- [Installation](installation.md) — the installer-only variables in the table above
- [Command reference](reference/camy.md) — every command and flag, generated from the binary
