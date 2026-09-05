## camy local trust add

Trust a command in this project — it auto-runs with no prompt

### Synopsis

Trust an exact command for THIS project. When the agent proposes exactly this
command on a clean turn, the CLI answers its own approval card — no keystroke.
--prefix trusts every command that STARTS WITH the given argv. That is the
single largest blast-radius lever here: `--prefix -- npm` trusts `npm run
<anything>`. A BARE binary name with no arguments after it (like that npm
example) is the broadest case of all: it grants EVERY invocation of that
binary in this project, any arguments at all, not just the one subcommand
you have in mind right now. Prefer exact grants.
Destructive commands (rm -rf on roots, sudo, curl|sh, secret reads, ...) can
never be granted — the floor holds at grant time too.

```
camy local trust add [--prefix] -- COMMAND [ARGS...] [flags]
```

### Options

```
  -h, --help     help for add
      --prefix   match every command starting with this argv (largest blast radius — prefer exact grants)
```

### Options inherited from parent commands

```
      --accessible                linear output: no spinners, boxes, or redraws
      --api-url string            API origin override (env CAMY_API_URL)
      --cloud                     use the cloud VM as the default workspace even when the local bridge is live (env CAMY_CLOUD=1)
      --color string              auto|always|never (default "auto")
  -f, --force                     skip destructive-operation prompts (headless)
      --inline                    classic scrollback app instead of the full-screen surface (env CAMY_INLINE=1)
      --jq string                 filter --json output with a jq expression (built in)
      --json                      machine output: stable JSON / NDJSON streams
      --no-input                  never prompt: checkpoints fail closed (exit 4), other prompts exit 2
      --no-local                  disable the local bridge entirely for this session (env CAMY_NO_LOCAL=1)
      --no-pager                  never page output
      --no-project-instructions   never read this project's AGENTS.md/CLAUDE.md into the chat session (env CAMY_NO_PROJECT_INSTRUCTIONS=1)
      --profile string            profile to use (env CAMY_PROFILE)
  -q, --quiet                     suppress non-data stderr
      --read-only                 local bridge reads only: no run_command/write_file this session (env CAMY_LOCAL_READONLY=1)
      --template string           format --json output with a Go template
  -v, --verbose                   request ids + timings
```

### SEE ALSO

* [camy local trust](camy_local_trust.md)	 - Pre-approved commands for this project (auto-run without a prompt)

