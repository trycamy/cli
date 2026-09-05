# Terminal output and accessibility

`camy` adapts to the terminal it runs in. Color, hyperlinks, inline images,
paging, and width all follow what your terminal and your environment
variables advertise. Every one of these is best-effort and degrades quietly
— a wrong guess never breaks a command, it just draws less.

Read on when the output looks wrong: escape codes in a log file, no color
in CI, an image that won't draw, or a surface that needs to be linear for a
screen reader. Start with the `terminal` check in `camy doctor`, which
names what this terminal does and doesn't support.

```bash
camy doctor
```

Machine output (`--json`, `--jq`, or `--template`) is never affected by any
of this. It is always plain, unstyled data. See [Scripting with
camy](scripting.md).

## Color

```bash
camy status --color never                      # off
FORCE_COLOR=1 camy status | cat                # on through a pipe
FORCE_COLOR=1 TERM=xterm-256color camy status  # on in a TERM-less CI job
```

Color is decided in two steps: whether it is on at all, then which rung it
uses — truecolor, 256-color, 16-color, or none.

`--color` is checked first. `never` means off; `always` skips the TTY and
environment checks below and goes straight to the rung table. With no
`--color` flag, `camy` walks, in order:

1. `NO_COLOR` (any non-empty value), `CLICOLOR=0`, or `TERM=dumb` — color
   off.
2. `FORCE_COLOR` (any non-empty value) or `CLICOLOR_FORCE` (any non-empty
   value) — color on, even when stdout is piped or redirected.
3. Otherwise: color on only if stdout is a real terminal.

Once color is on, the rung comes from `COLORTERM` and `TERM`:

| Signal | Rung |
| --- | --- |
| `COLORTERM=truecolor` or `COLORTERM=24bit` | truecolor (24-bit) |
| `TERM` contains `256color` | 256-color |
| `TERM` is set and isn't `dumb` | 16-color |
| `TERM` unset or `dumb` | no color |

`--color` (`auto`, `always`, or `never`; default `auto`) sits above all of
this.

The config key `color` accepts `auto`, `always`, `never`, and `off`, but
only `never` and `off` have an effect — both force color off; `always` in
config is accepted and ignored, so use `--color always` (or `FORCE_COLOR`)
to force color on. An explicit `--color always`/`--color never` wins over
the config key. See [camy config](reference/camy_config.md).

Forcing color on cannot invent a rung out of `TERM` alone — the rung still
comes from the table above. `COLORTERM=truecolor` (or `24bit`) is read
first, so it yields truecolor even with `TERM` unset.

With no `COLORTERM` and no usable `TERM`, `--color always`, `FORCE_COLOR`,
and `CLICOLOR_FORCE` all still produce plain output. Set `TERM` as well —
`TERM=xterm-256color`, say — when you want color in a `TERM`-less
environment such as a CI job or cron.

Under `TERM=dumb`, `FORCE_COLOR` and `CLICOLOR_FORCE` are overruled
outright by step 1 above; only `--color always` gets as far as the rung
table.

Stdout and stderr are judged independently. If you redirect stderr to a
file (`2> log`) while stdout stays an interactive terminal, the stderr
chrome (notes, hints, spinners) is written unstyled to that file even
though stdout is still painted — so `2> file` never captures escape codes
by accident.

`TERM=dumb` does double duty: it forces color off and switches `camy` into
[accessible mode](#accessible-mode).

## Accessible mode

```bash
camy status --accessible
```

`--accessible` (or `CAMY_ACCESSIBLE=1`, or a plain `TERM=dumb`) asks for
linear output: no spinners, no redrawn boxes, no cursor movement. Every
line is written once, in order, and stays in scrollback — the shape a
screen reader or a dumb terminal needs.

Accessible mode also turns off:

- the pager (long output prints straight through instead)
- inline images
- the full-screen app — bare `camy` in an accessible terminal runs the
  plain-line REPL instead

Glyphs degrade too, to the ASCII fallbacks below.

## Glyphs and Unicode

`✓`, `●`, and `…` become `OK`, `*`, and `...` whenever accessible mode is
on, or when your locale doesn't name UTF-8.

The locale comes from `LC_ALL`, then `LC_CTYPE`, then `LANG` — the first
one set wins. A value that mentions neither `UTF-8` nor `UTF8` switches
spinners, box-drawing, and the ellipsis to plain ASCII. With none of the
three set at all, `camy` assumes a modern UTF-8 terminal and uses the
Unicode glyphs.

## The full-screen app and `--inline`

Bare `camy` with no command, in a real terminal, opens the full-screen
app — the same surface described in [Chat](chat.md).

`--inline` (or `CAMY_INLINE=1`) keeps the same app — same composer, same
slash commands — but renders into your terminal's native scrollback
instead of taking over the screen with an alternate-screen layout, so what
the session prints stays in your terminal's history.

`--accessible` always wins over both: an accessible terminal gets the
plain-line REPL regardless of `--inline`.

## Paging

```bash
camy docs scripting --no-pager
CAMY_PAGER="less -FX" camy docs approvals
```

Long output — [`camy docs <topic>`](reference/camy_docs.md) is the common
case — is sent through a pager when all of these hold:

- stdout is a real terminal
- accessible mode is off
- `--no-pager` wasn't passed
- the output is taller than your terminal's height

Anything shorter than one screen, or any of those conditions being false,
prints straight to stdout instead.

The pager command itself is chosen in order:

1. `CAMY_PAGER`
2. the config key `pager`
3. `PAGER`
4. `less -FRX`

A blank or whitespace-only value at any rung is skipped, not treated as
"no pager" — it falls through to the next one. Setting the pager to `off`
or `cat` disables paging outright, same as `--no-pager`. If the chosen
pager command fails to run, `camy` falls back to printing unpaged rather
than losing the output.

## Hyperlinks (OSC 8)

Where the terminal is recognized as hyperlink-capable, a link `camy` prints
is wrapped as a clickable OSC 8 hyperlink — the camy.ai link from [`camy
status -w`](reference/camy_status.md), or the workspace URL from [`camy vm
url`](reference/camy_vm_url.md). The visible text stays the plain URL, so a
wrong guess costs nothing: you still see it and can copy it.

Markdown links inside agent prose and feed bodies are the one exception.
There the link text stays the label, and when the terminal isn't recognized
the URL is printed after it in parentheses.

`camy` recognizes:

- `TERM_PROGRAM` of `iTerm.app`, `WezTerm`, or `vscode`
- `TERM` containing `kitty`
- a non-empty `VTE_VERSION` (VTE-based terminals)
- a non-empty `WT_SESSION` (Windows Terminal)

Hyperlinks are off in accessible mode and whenever stdout isn't a terminal.

## Inline images

Two places draw an image straight into the terminal instead of just naming
it:

- the last image an agent generates during a [`camy
  chat`](reference/camy_chat.md) turn
- [`camy download`](reference/camy_download.md)'s post-save preview, when
  the saved file is an image

For a chat turn, the CLI only fetches images hosted on Camy's own CDN over
HTTPS, never an arbitrary host named in server text, and a fetch that fails
or times out just leaves the link line standing.

Both draw only in terminals that speak one of two protocols:

- **iTerm2** (also WezTerm, and any terminal reporting `LC_TERMINAL=iTerm2`)
  — any format the terminal can decode: PNG, JPEG, GIF, WebP.
- **kitty** (`TERM` containing `kitty`, or a non-empty `KITTY_WINDOW_ID`)
  — PNG only; other formats draw nothing extra, but the path/URL line
  already printed still stands.

Both previews are capped at 8 MB — a larger image is named but not drawn.
The chat-turn preview belongs to the one-shot `camy chat` surface only;
both the full-screen app and `--inline` print the image's link line instead
of drawing it.

Inline images never draw inside `tmux` (it re-frames the escape sequences,
so a half-drawn image would be worse than none), and never draw when
output is piped, paged, or in accessible mode. Set `CAMY_NO_INLINE_IMAGES=1`
to disable them outright — checked before any terminal detection.

## Width

`COLUMNS` comes first: when it is set to a positive integer, that is the
width `camy` uses, even inside a real terminal. Otherwise `camy` measures
the terminal itself, and falls back to 80 columns when there is nothing to
measure.

Not every surface uses the full width:

| Surface | Width |
| --- | --- |
| Streamed agent prose | terminal width minus 2, capped at 88, never below 20 |
| Approval cards (interior) | terminal width minus 6, capped at 64, never below 24 |

Widening `COLUMNS` past those caps changes tables, list rows, and `camy
docs` body text — not streamed agent prose or cards.

## What `camy doctor` reports

[`camy doctor`](reference/camy_doctor.md) includes a `terminal` check. It
never fails the command — the exit code isn't affected — but it warns when
either hyperlinks or inline graphics aren't available.

```text
$ camy doctor
  ...
  ! terminal   hyperlinks no · graphics no — iTerm2/kitty unlock inline image previews
```

The fix text names the graphics-capable terminals; in this CLI the graphics
it unlocks are the inline image previews described above.

The `graphics` half of that line is `yes` only when `TERM_PROGRAM` is
`iTerm.app` or `TERM` contains `kitty` — narrower than the full
inline-image detection above. WezTerm, for instance, draws images but
doesn't count as `graphics: yes` in this specific check. When a capability
you expect is missing, see [Troubleshooting](troubleshooting.md).

## Environment variables

| Variable | Effect |
| --- | --- |
| `NO_COLOR` | any non-empty value forces color off |
| `FORCE_COLOR` | any non-empty value forces color on |
| `CLICOLOR` | `0` forces color off |
| `CLICOLOR_FORCE` | any non-empty value forces color on |
| `COLORTERM` | `truecolor`/`24bit` selects the truecolor rung |
| `TERM` | `dumb` forces color off and accessible mode; `*256color*` selects the 256-color rung |
| `CAMY_ACCESSIBLE` | `1` forces accessible (linear) output |
| `CAMY_INLINE` | `1` keeps the classic scrollback app instead of full-screen |
| `CAMY_PAGER` | pager command, highest-precedence rung |
| `PAGER` | pager command, fallback rung |
| `COLUMNS` | width override; when set to a positive integer it wins over the measured terminal width |
| `TERM_PROGRAM` | drives hyperlink and inline-image terminal detection |
| `VTE_VERSION`, `WT_SESSION` | additional hyperlink-capable-terminal signals |
| `LC_TERMINAL` | `iTerm2` selects the iTerm2 inline-image protocol |
| `KITTY_WINDOW_ID` | non-empty selects the kitty inline-image protocol |
| `TMUX` | any non-empty value disables inline images |
| `CAMY_NO_INLINE_IMAGES` | `1` disables inline image rendering outright |
| `LC_ALL`, `LC_CTYPE`, `LANG` | first non-empty one sets the UTF-8/ASCII glyph fallback |

The full variable list, including the ones that control auth, profiles, and
update behavior rather than rendering, is in
[Configuration](configuration.md).
