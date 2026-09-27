# Your Mac as a device

Camy can run on your own Mac as a resident agent: a background process that
stays linked to your account, holds only the capabilities you grant it, and
keeps a local record of everything it accepted or refused. This page covers
installing it, linking it, granting it scopes, and taking it back.

You can link this Mac from any install of `camy`: `camy device enroll`, and
linking as you sign in with `camy auth login`, work from the one-line
installer, Homebrew, npm, or a downloaded tarball. Only `camy device install`,
which runs the resident agent in the background, needs **Camy.app**, the
notarized Mac application. The other installs carry the same binary and run
every other command on this site, but a bare executable has no bundle
identity, so it can't hold a macOS permission grant. From one of them,
`camy device install` refuses with:

```text
camy: Linking a computer only works from the Camy app — download it at https://github.com/trycamy/cli/releases/latest and try again from there.
```

Despite that wording, linking works from any install; only the background
agent needs the app. See [Camy for Mac](installation.md#camy-for-mac).

## Link this Mac

The quickest way is to sign in. On an interactive terminal, `camy auth login`
signs you in and links this Mac in the same browser approval; see
[Linking this Mac as you sign in](authentication.md#linking-this-mac-as-you-sign-in).
To link it on its own, for example after signing in with `--no-device`:

```bash
camy device enroll
```

The command prints a short code and a link on camy.ai. Open the link, confirm
the code, and approve the link in the browser; the command waits until you
do. Under `--no-input` it refuses, because linking needs a browser approval:

```text
camy: linking a computer needs a browser approval
      run it without --no-input
```

`--label` gives this Mac a name other than its host name. A Mac that is
already linked refuses (`This Mac is already linked as <name>.`); run
`camy device forget` first to link it again. A link this Mac already knows
was revoked doesn't count: linking again replaces it. `camy device enroll`
treats a link whose credential expired the same way, but only once the
resident agent has run and recorded the expiry. `camy auth login` links this
Mac again as soon as the expiry date it has on record has passed. When the
old link is still listed at Camy, camy revokes it with your terminal's
sign-in, or tells you to revoke it under Settings, then Your computers. If linking isn't available for your account, the command says
`Linking a computer isn't on for your account yet.`

Linking leaves two things on this Mac. The first is a signing key, made on
this Mac, that never leaves it. This release keeps that key in a file, and
says so before you approve:

```text
  ⋮ key made on this Mac (software) · never leaves it · reads only, for good
```

A Mac whose signing key is kept in a file can only ever be granted reading.

The second is this Mac's own Camy credential, which the approval returns.
camy stores it the way it stores your terminal's key, and this Mac uses it
whenever it talks to Camy for itself. The credential expires. It is renewed
only while the resident agent, which `camy device install` starts from
Camy.app, is running during the last days before the expiry (see
[Run it in the background](#run-it-in-the-background)). Without the agent,
the link expires and `camy auth login` links this Mac again (see
[Status](#status)). `camy device forget` removes both.

A freshly linked Mac can do nothing. Every capability is a grant you add.

## Grant and remove scopes

```bash
camy device scope add ~/Projects --read
camy device scope list
camy device scope remove <id>
```

A grant names a capability and the paths it covers. `add` needs one of
`--read`, `--write`, or `--capability NAME`, and at least one PATH. `--read`
grants `files.read`, `--write` grants `files.write`, and `--capability` names
any other capability; it wins if you also give `--read` or `--write`.
`--read` and `--write` together are refused
(`pick one of --read/--write, or use --capability for anything else`). With
no capability flag, `add` refuses with
`say what it may do: --read, --write, or --capability NAME`; with a flag but
no path, it refuses with `which folders? give at least one PATH`.
`--network` allows outbound network for that grant, `--expires` gives it an
RFC 3339 end time instead of standing, and `--mode-ceiling` sets the highest
mode the grant is honored in (`watching` unless you set it).

A PATH can be a folder, which covers everything beneath it, or a single
file, which covers only that file. `~` means your home folder on this Mac,
whether you add the grant here or in Settings. The resident agent skips a
single-file grant whose path is a link, and a command grant on a file,
since commands run in folders, and says so in its log.

A Mac whose signing key is kept in a file can only be granted reading. camy
refuses anything more before it asks Camy:

```text
camy: MacBook Air's key isn't hardware-backed, so it can only be granted reading — files.write needs a Secure Enclave key.
```

`camy device scope list` shows what this Mac may currently touch: each live
grant's capability, paths, and id. Revoked and expired grants are left out.

`camy device scope remove` takes a grant's id, or a prefix of it that matches
only one live grant, and asks before it removes anything. Give the exact id
of a grant that is already revoked or expired and camy reports
`<id> was already off.` and sends nothing. A prefix only matches live grants,
so a prefix of a revoked or expired grant, like an id this Mac has no grant
for, is a usage error (`<name> has no grant "<prefix>"`) that points you at
`camy device scope list`.

## Status

```bash
camy device status
```

One sentence about the link, then the mode, what this Mac can do (each
capability with the folders it covers, such as
`files.read on /Users/you/Projects`), the last time this Mac reached Camy
(`last talked`, shown only when Camy answered this status read), its offline
lease, and whether the resident agent is running, with its process id while
it is. A link can be **active**, still **pending** setup, **paused** with its
scopes frozen but kept, in need of a **recheck** with scopes suspended until
Camy confirms it is still running genuine Camy software, **suspended**, or
**revoked**. A Mac that has not reached Camy for 72 hours, or for the
shorter limit Camy sets for it, suspends itself and refuses every capability
until it reconnects; one that stays quiet for a long while is suspended on
the server side, and reconnecting resumes it with its scopes intact. `--json`
gives the same as an object, with `agent_running` and, while the agent runs,
`agent_pid`. It also carries `key_expired`, `key_renewal_blocked`, and, once
this Mac knows it, `key_expires_at`, the expiry of this Mac's own
credential.

The resident agent renews that credential on its own as its expiry nears,
while the link is active or paused. A suspended Mac, or one waiting on a
recheck, can't renew, and `status` says by when to resume it:

```text
  MacBook Air can't renew its link while it isn't active — resume it by Oct 20, 3:04pm or it will need linking again.
```

If the credential expires anyway, for example because the agent wasn't
running, nothing is wiped. The agent stops instead of running on it, and
`status` says:

```text
  MacBook Air's link expired — its grants are kept. camy auth login (or camy device enroll) links it again.
```

When only `status` has seen the expiry, as when the agent wasn't running,
use `camy auth login`. `camy device enroll` refuses with
`This Mac is already linked as <name>.` until the agent has run once and
recorded the expiry, or until you run `camy device forget`.

`status` asks Camy with this Mac's own credential, so an expired sign-in in
your terminal doesn't make the Mac look revoked. When Camy can't be reached,
it says so and shows what this Mac last reported: the cached mode and grants,
the offline lease, and the agent row, with no last-contact time. If linking
isn't on for your account, the sentence about the link is
`Linking a computer isn't on for your account yet.` instead.

## Run it in the background

```bash
camy device install
camy device logs
camy device uninstall
```

`install` registers the resident agent as a per-user LaunchAgent that runs
`camy device run` at every login, and starts it now. It needs Camy.app and a
linked Mac, and refuses without either. `uninstall` stops the agent and
removes the LaunchAgent, and nothing else. The agent acts only while the link
is active.

`logs` shows the last 200 lines of the agent's own log. The log lives in
`~/Library/Logs/Camy/` and rotates at 5 MB, keeping three older files, so it
never grows without bound. When the agent exits with an error, the log keeps
the reason, with the one exception below.

Only one agent runs per profile. A second `camy device run`, the command the
LaunchAgent starts (`camy device --help` doesn't list it), stops before it
contacts Camy and exits 0 without printing anything in the terminal, so the
LaunchAgent doesn't restart it. It writes this line to the agent's log, where
`camy device logs` shows it:

```text
  ⋮ MacBook Air is already being watched by another camy device run (pid 4812) — this one stops.
```

The agent refuses to start, without touching the network, when this Mac was
stopped with [`camy stop`](#stop-it-now), its link is already known to be
revoked, or an earlier run already recorded that its credential expired. The
first start after an expiry no run has recorded reaches Camy once, learns of
the expiry, records it, and stops without wiping anything. If Camy answers the agent's first
connection by saying it could not confirm which Mac is connecting, the agent
exits with an error instead of running without a device's protections. It writes nothing to its log that
explains why. Under `install`, the LaunchAgent starts it again about every 10
seconds, and each start repeats the check.

While it runs, the agent checks in with Camy every 30 seconds. Each check-in
carries this Mac's current grants, so a change reaches a connected Mac
without a restart. A change that takes something away, such as a grant
removed or expired, or a new Off rule, applies at once and stops anything
still running under the old grants. A change that only adds lets running
commands finish first, for up to two minutes; meanwhile a new call is
refused with `<name> is picking up a change to what it may do — try again in a moment.`

With each check-in the agent also reads the folder and command rules set for
this Mac in Settings, and refuses anything set to Off on its own: a file tool
refuses a path in a folder set to Off, searches and listings skip that
folder, and a command set to Off is refused before it runs, even behind a
wrapper such as `env`, `nice`, `xargs`, or `nohup`, or inside an `sh -c`
script. So is a command that names a path in a folder set to Off. A rule
value this Mac doesn't recognize counts as Off. If one read of the rules
fails, the agent keeps the rules it last read, and a start with no network
uses them too. If Camy won't let this Mac's own credential read the rules,
the agent says so once in its log and refuses only the Off rules it last
read.

A rule set to Allow never adds a grant. A Mac whose signing key is kept in a
file, which is every Mac this release links, skips every `files.write` and
`shell.exec` grant, so no write runs under an Allow rule there. On a Mac
with a hardware-backed key, when Camy approves a write or a command under an
Allow rule without asking you, this Mac runs it on Camy's
signed approval, as it would your own yes, and only inside the grants it
already holds. For a folder's Allow rule, this Mac first follows every link
on the way to the target. A write or command that a link leads outside that
folder, or into a folder set to Ask or Off, is refused and nothing runs;
asking again shows you a card.

## Stop it now

```bash
camy stop
```

Stops the resident agent on this Mac immediately. It needs no network, so it
works when nothing else does:

```text
✓ stopped — the agent isn't watching this Mac anymore.
```

On a linked Mac the stop also holds: the agent refuses to start again, even
at your next login, until you run `camy device install`. Each time it
refuses, its log reads
`<name> is paused — Camy won't run anything on it until you resume it.`
Despite that wording, resuming this Mac in Settings doesn't undo the stop;
only `camy device install` does. `camy device status` doesn't mention the
stop either: it shows the link's status from Camy, such as active, with the
agent `not running`. If camy can't record the stop, it still stops the agent
first and then says what it couldn't record. When no agent is running, it
says `the agent on this Mac isn't running.`

## The ledger

```bash
camy ledger
```

This Mac's own record: every call the agent accepted or refused, kept
locally as a chain the command verifies before it shows anything. A chain
that does not verify is shown with a warning and should be treated as
untrusted until the cause is found.

## Take it back

Three actions, deliberately separate:

- **Pause or revoke** on camy.ai, under Settings, then Your computers. Pausing
  freezes the scopes; revoking ends the link on the server. The resident
  agent acts on a revoke as soon as it hears of it, and a Mac that was asleep
  or offline hears of it when it next reaches Camy. It clears the grants it
  had cached and this Mac's own credential, notes the revoke in the ledger,
  writes `<name> was revoked — stopping.` to its log, and does not start
  again. `camy auth login` or `camy device enroll` then links the Mac again,
  with no `camy device forget` first.
- **`camy device forget`** erases this Mac's half of the link: the key, the
  stored credential, the record, and the ledger. When this terminal is
  signed in to your account, it also revokes the link on the server
  (`✓ this Mac forgot its link to Camy, and <name> is revoked.`); otherwise
  it says to revoke it there too.
- **`camy device uninstall`** stops the background agent. The link stays.

A revoke is the only answer from Camy that clears this Mac's grants. An
expired credential, a suspended account, or a server error leaves them in
place, and a credential Camy stops recognizing counts as revoked only once
that has held for three minutes.

A `camy` chat session that offers this computer through
[the local bridge](local-bridge.md) is taken back when Camy disconnects it:
the session stops offering this computer at once, does not reconnect, and
ends. The resident agent does the same: it writes
`<name> was disconnected from Camy — stopping.` to its log and stops, and the
link and its grants stay.

## See also

- [Installation](installation.md#camy-for-mac), the Camy.app download
- [Authentication](authentication.md#linking-this-mac-as-you-sign-in), linking this Mac as you sign in
- [The local bridge](local-bridge.md), what the agent may read, write, or run inside a project, and the `--sandbox` flag
- [`camy device`](reference/camy_device.md), [`camy stop`](reference/camy_stop.md), and [`camy ledger`](reference/camy_ledger.md) in the reference
