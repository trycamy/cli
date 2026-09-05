# Canvas

Code Canvas is what a chat's agent builds when it writes files instead of
just replying — a small site or app, kept as part of that chat.

From the CLI you can list what it built, read or download the files, roll
the canvas back to an earlier checkpoint, and publish it as a live site
with its own URL and custom domain. The command is `camy canvas`.

```bash
camy canvas
camy canvas cat index.html
camy canvas pull ./site
camy canvas sites
```

Bare `camy canvas` is the same as [`camy canvas files`](#camy-canvas-files).

Editing file contents is not something `camy canvas` does — that happens in
the chat (ask the agent to change a file) or in the web editor. The CLI's
job is getting files out of a canvas and sites out into the world, not
editing what's in them.

See [`camy canvas`](reference/camy_canvas.md) for the full command tree.

## Which chat's canvas

Most subcommands act on one chat's canvas, so they take a `--chat` flag:

```bash
camy canvas --chat abc12345 files
```

`--chat` accepts a full chat id, or a short id — anything four characters
or longer that uniquely prefixes one of your chats.

Leave it out and the CLI falls back to the chat you last used, the same
anchor [`camy chat -c`](reference/camy_chat.md) continues. With no chat to
fall back to either, it exits 2 asking which chat's canvas you meant and
points you at [`camy chats`](reference/camy_chats.md).

A short id that matches nothing is passed straight through, and left to the
server to reject. One that matches more than one chat is refused
client-side (exit 2) rather than guessed at. A ref under four characters is
refused outright as too short to identify a chat.

`--chat` only matters for the commands that read a canvas's files or work
with checkpoints: `files`, `cat`, `pull`, `open`, `publish`, `snapshot`,
`snapshots`, `restore`, `preview`, and `export`.

The site-management commands (`sites`, `domain`, `access`, `indexable`,
`rollback`, `versions`) act on an already-published site by name, and need
no chat at all.

## Files and contents

### `camy canvas files`

```bash
camy canvas files
```

Lists the files currently in the canvas: a mark, the filename, its
language, and a human-readable size. An empty canvas says so rather than
printing nothing.

`--json` gives one object per file. This is a shape the CLI builds, not a
passthrough of the server's file list, and it does not carry file contents:

```json
[{"filename": "index.html", "language": "html", "bytes": 1834, "updated_at": "..."}]
```

See [`camy canvas files`](reference/camy_canvas_files.md).

### `camy canvas cat`

```bash
camy canvas cat FILE
```

Prints one file's contents. `FILE` must match a filename in the canvas
exactly — no globbing, no prefix matching. A filename that isn't in the
canvas exits 1 and points you at `camy canvas files`.

When stdout is piped, the bytes go out unsanitized, exactly as the server
holds them, except that `cat` adds a trailing newline when the file doesn't
already end in one. So a redirect is a faithful checkout of that one file,
up to that final newline:

```bash
camy canvas cat app.js > app.js
```

When stdout is a real terminal instead, the content is sanitized first, the
same as everywhere else server text reaches your screen.

See [`camy canvas cat`](reference/camy_canvas_cat.md).

## Getting the files onto your machine

### `camy canvas pull`

```bash
camy canvas pull [DIR]
```

Writes every file in the canvas to a local directory: `DIR` if you give
one, else `canvas-<shortid>` using the chat's own short id. An empty canvas
exits 1.

Before writing anything, `pull` checks every destination path across the
whole file set, so a conflict found late in the list can't leave earlier
files already written. Two safety rules apply per file:

- A filename the server sends containing `..`, starting with `/`, or empty
  is silently dropped from the pull — never trusted as a local path.
- A destination that already exists as a **symlink**, live or dangling, is
  refused unconditionally, even with `--force`. Remove it first, or pull
  into a fresh directory.

If any destination already exists as an ordinary file, `pull` refuses the
whole operation with exit 2 and writes no files; `-f`/`--force` overwrites
instead. The destination directory itself is created up front, so a refused
pull can leave it behind, empty.

`--json`:

```json
{"ok": true, "chat_id": "<full chat id>", "dir": "./site", "files": 6}
```

See [`camy canvas pull`](reference/camy_canvas_pull.md).

### `camy canvas preview`

```bash
camy canvas preview
```

Writes the canvas to a fresh temporary directory and opens it in your own
browser as a local file. Nothing is published. It picks `index.html` if
present, otherwise the first `.html` file it finds; a canvas with no HTML
file at all exits 1.

Because this runs model-generated HTML and JavaScript the moment it opens —
code that hasn't been reviewed, executing locally on your machine — it asks
for confirmation first, worded around exactly that risk. This is one place
`--force`/`--no-input` genuinely need to mean it: headless without
`--force` refuses rather than silently opening a browser.

The temporary directory is left on disk afterward, not cleaned up. It is
written before the prompt, so declining still leaves that copy on disk.

See [`camy canvas preview`](reference/camy_canvas_preview.md).

### `camy canvas open`

```bash
camy canvas open
```

Opens the real canvas at camy.ai in your browser — the web editor, not a
local checkout. It prints the URL as well as opening it, so the link is
still the output on a machine with no browser.

See [`camy canvas open`](reference/camy_canvas_open.md).

## Checkpoints

A snapshot is a checkpoint of the canvas as it stands. Restoring one
replaces the canvas's current files with that checkpoint's.

### `camy canvas snapshot`

```bash
camy canvas snapshot
camy canvas snapshot "before the redesign"
```

Creates a snapshot, with an optional free-text label. See
[`camy canvas snapshot`](reference/camy_canvas_snapshot.md).

### `camy canvas snapshots`

```bash
camy canvas snapshots
```

Lists snapshots, newest first: a mark, the snapshot's short id, its label
(or a dim placeholder when there isn't one), and roughly how long ago it
was taken. See
[`camy canvas snapshots`](reference/camy_canvas_snapshots.md).

### `camy canvas restore`

```bash
camy canvas restore SNAPSHOT
```

Rolls the canvas back to a snapshot. `SNAPSHOT` is a short id or a full id,
resolved the same way `--chat` is; an ambiguous or too-short prefix is
refused client-side. It asks for confirmation first — see
[Confirmation and `--force`](#confirmation-and---force).

Human output reports how many files came back. See
[`camy canvas restore`](reference/camy_canvas_restore.md).

## Publishing a site

### `camy canvas publish`

```bash
camy canvas publish
```

Publishes the canvas as a live site. Before claiming anything, `publish`
looks up the exact host the site would get and shows it to you in the
confirmation prompt — you see the real URL before agreeing, not after.

If the host isn't claimable at all (already taken, for example), `publish`
fails with the server's reason and never reaches the confirmation prompt.

Human output links the new site's URL and reports how many files were
published. See [`camy canvas publish`](reference/camy_canvas_publish.md).

### `camy canvas sites`

```bash
camy canvas sites
```

Lists every site you've published: a mark, the site's name, a link to its
custom domain if it has one (else its default URL), and which chat it came
from. With no sites yet, it prints a plain note instead of an empty list.
See [`camy canvas sites`](reference/camy_canvas_sites.md).

### `camy canvas sites rm`

```bash
camy canvas sites rm NAME
```

Unpublishes a site: its URL stops serving. It asks for confirmation, worded
around the fact that the URL goes dark.

`--json`:

```json
{"ok": true, "site": "NAME", "deleted": true}
```

See [`camy canvas sites rm`](reference/camy_canvas_sites_rm.md).

### `camy canvas versions`

```bash
camy canvas versions SITE
```

Lists a site's archived publish versions, newest first, with each version's
id and when it was created. With no archived versions — only the current
live publish exists — it prints a note rather than an empty list. See
[`camy canvas versions`](reference/camy_canvas_versions.md).

### `camy canvas rollback`

```bash
camy canvas rollback SITE
camy canvas rollback SITE VERSION
```

Rolls a published site back to an earlier version: one publish back if you
leave `VERSION` off (the server picks "one back," not the CLI), or to a
specific version if you name one from `camy canvas versions`. It asks for
confirmation, worded around exactly what it's about to do.

Human output confirms the site is now serving the older version. See
[`camy canvas rollback`](reference/camy_canvas_rollback.md).

## Custom domain

### `camy canvas domain`

```bash
camy canvas domain SITE
```

Shows a site's domain state:

- No custom domain attached: it says so, and tells you how to set one.
- A domain attached: it prints the domain.
- A domain still pending verification: it prints the pending domain, the
  exact DNS TXT record name and value you need to add, and a reminder to
  run `camy canvas domain verify` once the record is in place.

Anything else the server has to say about the domain — a note about
certificate issuance, or DNS instructions — is printed too. See
[`camy canvas domain`](reference/camy_canvas_domain.md).

### `camy canvas domain set`

```bash
camy canvas domain set SITE DOMAIN
camy canvas domain set SITE --clear
```

Attaches a custom domain to a site, or removes one with `--clear` (which
takes no `DOMAIN`). Human output reports the new status, then renders the
domain state exactly as plain `camy canvas domain` does — including the TXT
record, if one is now pending.

See [`camy canvas domain set`](reference/camy_canvas_domain_set.md).

### `camy canvas domain verify`

```bash
camy canvas domain verify SITE
```

Checks the pending DNS TXT challenge. The server can answer with an
ordinary success response that still says "not verified" — a miss doesn't
have to look like a failure.

So read the result, not just whether the command exited cleanly: a genuine
pass prints an "ok" line naming the verified domain, anything else prints a
"not yet" line with the reason. See
[`camy canvas domain verify`](reference/camy_canvas_domain_verify.md).

## Access control

### `camy canvas access`

```bash
camy canvas access SITE
```

Shows a site's access mode, whether a passcode is set, and whether the site
is allowed to be indexed by search engines.

If the mode isn't `public` but the server hasn't switched enforcement on
for that mode yet, the CLI adds a loud NOT ENFORCED warning: the site is
still reachable by anyone, despite the mode you set. The `mode:` line is
still printed, but never on its own over a site the server is still
serving publicly.

See [`camy canvas access`](reference/camy_canvas_access.md).

### `camy canvas access set`

```bash
camy canvas access set SITE public
camy canvas access set SITE passcode --passcode-stdin
```

Sets a site's access mode. `MODE` must be `public`, `passcode`, or
`unlisted` — but the command's own help text is explicit that only `public`
is available today. `passcode` and `unlisted` aren't, even though the CLI
accepts the value and sends it on.

A passcode is never taken as a command-line argument or flag value — that
would land in your shell history. For `MODE=passcode`, give it one of two
ways:

- `--passcode-stdin` — read up to 4096 bytes from stdin, trimmed.
- Otherwise, an interactive prompt on your terminal (not stdin). Running
  headless without `--passcode-stdin` exits 2 asking for one.

A passcode must be at least 6 characters, however it arrives — typed at the
prompt or piped in with `--passcode-stdin`. Leaving it blank at the prompt,
or piping nothing, means "keep the current one." `--clear-passcode` removes
a stored passcode, but only takes effect when `MODE` is `public`.

The NOT ENFORCED warning above applies after `access set` too, when it is
relevant. See
[`camy canvas access set`](reference/camy_canvas_access_set.md).

### `camy canvas indexable`

```bash
camy canvas indexable SITE on
camy canvas indexable SITE off
```

Turns search-engine indexing for a published site on or off. The second
argument must be literally `on` or `off`. See
[`camy canvas indexable`](reference/camy_canvas_indexable.md).

## Exporting the canvas

### `camy canvas export`

```bash
camy canvas export zip
camy canvas export pwa -o my-app-pwa.zip
```

Downloads the canvas as a packaged app instead of individual files.
`FORMAT` must be `pwa`, `capacitor`, or `zip`.

`-o`/`--output` sets the destination path. Leave it out and the CLI uses
the filename the server suggests, sanitized and stripped of any path
components first. If the server suggests nothing usable, the CLI falls back
to `FORMAT.zip` in the current directory: `zip.zip`, `pwa.zip`,
`capacitor.zip`.

The destination is protected the same way
[`camy download`](reference/camy_download.md) protects a download. A target
that already exists as a symlink is refused outright, and `--force` doesn't
override that; an ordinary existing file is refused unless you pass
`--force`.

`--json`:

```json
{"ok": true, "format": "zip", "chat_id": "<full chat id>", "path": "camy-canvas.zip", "bytes": 48213}
```

See [`camy canvas export`](reference/camy_canvas_export.md).

## Examples

Look at a canvas, then pull it down and open one file:

```bash
camy canvas --chat abc12345 files
camy canvas --chat abc12345 pull ./my-app
cat ./my-app/index.html
```

Snapshot before letting the agent make a risky change, then roll back if it
goes wrong:

```bash
camy canvas snapshot "before the redesign"
camy canvas restore <snapshot-id> --force
```

Publish, check what's live, then roll back to the previous version:

```bash
camy canvas publish
camy canvas sites
camy canvas rollback my-app --force
```

Attach a custom domain and verify it once DNS is in place:

```bash
camy canvas domain set my-app example.com
camy canvas domain my-app
camy canvas domain verify my-app
```

Export a zip in CI, overwriting any previous build (the output directory
must already exist):

```bash
camy canvas --chat abc12345 export zip -o build/app.zip --force
```

## Confirmation and `--force`

A handful of `camy canvas` commands are destructive enough to ask first —
current files replaced, a live URL going dark, unreviewed code about to
run.

All of them follow the same rule: on a real terminal, they prompt `y/N`;
`-f`/`--force` skips the prompt; running headless (`--no-input`, or no
controlling terminal) without `--force` fails closed with exit 2 rather
than guessing.

| Command | What you're confirming |
| --- | --- |
| `camy canvas restore` | current canvas files are replaced by the snapshot |
| `camy canvas preview` | unreviewed, model-generated code runs locally, immediately |
| `camy canvas publish` | the exact host it's about to claim (shown to you first) |
| `camy canvas sites rm` | the site's URL goes dark |
| `camy canvas rollback` | the site starts serving an older version — one publish back, or the one you named |

Every other `camy canvas` command — `files`, `cat`, `pull`, `open`, `sites`,
`snapshot`, `snapshots`, `versions`, `domain`, `domain set`,
`domain verify`, `access`, `access set`, `indexable`, `export` — runs
without asking, though `pull` and `export` each still refuse to silently
overwrite a file unless you pass `--force`.

## `--json` output

`snapshots`, `sites`, and `versions` emit the raw row array the server
returned. `files`, `pull`, `sites rm`, and `export` emit a shape the CLI
builds, shown with each of those commands above.

Everything else that takes `--json` emits the server's response object
as-is: `snapshot`, `restore`, `publish`, `rollback`, `domain`,
`domain set`, `domain verify`, `access`, `access set`, and `indexable`.
Three fields in those objects are worth naming:

| Command | Field |
| --- | --- |
| `publish` | `site_url` and `files_published` |
| `access` | `enforcement_ready`, which the human view's NOT ENFORCED warning reads |
| `domain verify` | `verified` — the one to check, since the command can exit cleanly and still report a domain as unverified |

`cat` and `preview` have no `--json` form: `cat` always prints the file
itself, and `preview` is an interactive action, not a data command.

## Exit codes

`camy canvas` commands use the CLI's normal exit-code table — see
[Exit codes](exit-codes.md). The cases specific to this area:

| Situation | Exit |
| --- | --- |
| No `--chat`, and no last chat to fall back to | 2 |
| A `--chat` or snapshot ref under four characters | 2 |
| An ambiguous chat or snapshot prefix | 2 |
| A bad `MODE` or `FORMAT` | 2 |
| A missing passcode, or one under six characters | 2 |
| `domain set` given both `--clear` and a `DOMAIN`, or neither | 2 |
| A symlink destination refused by `pull` or `export` | 2 |
| A filename `cat` can't find | 1 |
| An empty canvas | 1 |
| No HTML entry point for `preview` | 1 |

## See also

- [Chat](chat.md) — where a canvas gets built in the first place
- [Authentication](authentication.md) — the `deploys:write` scope publishing needs
- [Scripting with camy](scripting.md) — `--json`, `--force`, `--no-input`
- [`camy canvas`](reference/camy_canvas.md) — full command and flag reference
