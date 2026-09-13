# Your Mac as a device

Camy can run on your own Mac as a resident agent: a background process that
stays linked to your account, holds only the capabilities you grant it, and
keeps a local record of everything it accepted or refused. This page covers
installing it, linking it, granting it scopes, and taking it back.

Everything here needs **Camy.app**, the notarized Mac application, rather
than the `camy` you install with the one-line installer, Homebrew, or npm.
Those carry the same binary and run every other command on this site, but a
bare executable has no bundle identity, so it can hold neither a device key
nor a macOS permission grant. `camy device enroll` and `camy device install`
from one of them refuse in one sentence and point you at the download. See
[Camy for Mac](installation.md#camy-for-mac).

## Link this Mac

```bash
camy device enroll
```

The command prints a short code and a link on camy.ai. Open the link, confirm
the code, and approve the link in the browser; the command waits until you
do. It needs a terminal to talk to you, so it refuses under `--no-input`.
Linking creates a device key that never leaves this Mac, on Apple silicon
inside the Secure Enclave.

A freshly linked Mac can do nothing. Every capability is a grant you add.

## Grant and remove scopes

```bash
camy device scope add ~/Projects --read
camy device scope add ~/Projects/site --write
camy device scope add --capability terminal
camy device scope list
camy device scope remove <id>
```

A grant names a capability and, for file access, the paths it covers.
`--network` allows outbound network for that grant, `--expires` gives it an
RFC 3339 end time instead of standing, and `--mode-ceiling` sets the highest
mode the grant is honored in. `camy device scope list` shows what this Mac
may currently touch.

## Status

```bash
camy device status
```

One sentence about the link, then the mode, the scopes, and the last time
this Mac reached Camy. A link can be **active**, still **pending** setup,
**paused** with its scopes frozen but kept, in need of a **recheck** with
scopes suspended until Camy confirms it is still running genuine Camy
software, or **suspended**. A Mac that has not reached Camy for 72 hours
suspends itself and refuses every capability until it reconnects; one that
stays quiet for a long while is suspended on the server side, and
reconnecting resumes it with its scopes intact. `--json` gives the same as an
object.

## Run it in the background

```bash
camy device install
camy device logs
camy device uninstall
```

`install` registers the resident agent as a per-user LaunchAgent that runs
`camy device run` at every login; `uninstall` stops it and removes the
LaunchAgent, and nothing else. Installing before linking is harmless: the agent refuses to act
until this Mac is linked and active. `logs` shows the agent's own output.

## Stop it now

```bash
camy stop
```

Stops the resident agent on this Mac immediately. It needs no network, so it
works when nothing else does.

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
  freezes the scopes; revoking ends the link on the server.
- **`camy device forget`** erases this Mac's half of the link: the key, the
  stored credential, the record, and the ledger. It does not revoke anything
  on the server, and says so; revoke there too if the Mac is gone.
- **`camy device uninstall`** stops the background agent. The link stays.

## See also

- [Installation](installation.md#camy-for-mac), the Camy.app download
- [The local bridge](local-bridge.md), what the agent may read, write, or run inside a project, and the `--sandbox` flag
- [`camy device`](reference/camy_device.md), [`camy stop`](reference/camy_stop.md), and [`camy ledger`](reference/camy_ledger.md) in the reference
