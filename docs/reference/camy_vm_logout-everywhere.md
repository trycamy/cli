## camy vm logout-everywhere

Log your computer out of every site: forget saved logins, clear its browser, stop its tasks

### Synopsis

Camy forgets every login it saved and clears your computer's browser (cookies and
open sign-ins); any task running on the computer stops. The sites themselves aren't
touched — you sign in again the next time a task needs one.

It asks you to confirm (--yes skips that), then for a fresh check that it's you: your
authenticator's code, or Enter for a code emailed to your account (--code passes the
code up front, for scripts). It runs only with the key `camy auth login` gave this
terminal (the browser sign-in or --code). Any other key (a pasted one, CAMY_API_KEY,
one made on camy.ai) is refused (exit 3); so is a sign-in key from before camy.ai
marked them, until `camy auth login` signs this terminal in again.

Saved logins are gone when it answers. A running computer's browser is cleared right
after; one that's off is cleared the next time it starts, before Camy uses it.
--json prints the receipt: vault_entries_deleted, sessions_stopping, boxes_clearing,
boxes_pending.

Exit codes: 0 done · 1 camy.ai couldn't do it · 2 not confirmed / bad flags ·
3 this key can't, or the code didn't confirm it's you.

```
camy vm logout-everywhere [flags]
```

### Examples

```
  camy vm logout-everywhere                        # asks, then asks for a code
  camy vm logout-everywhere --yes --code 123456 --json
```

### Options

```
      --code string   your authenticator's code, or a code camy.ai emailed you (else it asks)
  -h, --help          help for logout-everywhere
      --yes           don't ask to confirm (scripts; --force does too)
```

### Options inherited from parent commands

```
      --accessible                linear output: no spinners, boxes, or redraws
      --api-url string            API origin override (env CAMY_API_URL)
      --cloud                     use the cloud VM as the default workspace even when the local bridge is live (env CAMY_CLOUD=1)
      --color string              auto|always|never (default "auto")
  -f, --force                     skip destructive-operation prompts (headless)
      --ground string             the palette's ground: dark or light (default: detected — CAMY_GROUND, COLORFGBG, the terminal)
      --ids string                hex: print the old untyped 8-hex ids instead of typed ones (1.0.3 compat)
      --inline                    classic scrollback app instead of the full-screen surface (env CAMY_INLINE=1)
      --jq string                 filter --json output with a jq expression (built in)
      --json                      machine output: stable JSON / NDJSON streams
      --no-input                  never prompt: checkpoints fail closed (exit 4), other prompts exit 2
      --no-local                  disable the local bridge entirely for this session (env CAMY_NO_LOCAL=1)
      --no-pager                  never page output
      --no-project-instructions   never read this project's AGENTS.md/CLAUDE.md into the chat session (env CAMY_NO_PROJECT_INSTRUCTIONS=1)
      --no-truncate               never truncate table/list cells (may overflow narrow terminals)
      --profile string            profile to use (env CAMY_PROFILE)
  -q, --quiet                     suppress non-data stderr
      --raw                       --json on a listing emits the endpoint's own envelope, not the normalised array
      --read-only                 local bridge reads only: no run_command/write_file this session (env CAMY_LOCAL_READONLY=1)
      --sandbox string            off|observe|enforce: OS write-confinement under run_command, this invocation only (default observe until 6 Oct 2026, then enforce where the OS can confine writes; env CAMY_LOCAL_SANDBOX)
      --template string           format --json output with a Go template
  -v, --verbose                   request ids + timings
```

### SEE ALSO

* [camy vm](camy_vm.md)	 - your cloud workspace — exec, shell, status

