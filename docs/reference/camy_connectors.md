## camy connectors

Your connections — accounts, servers, and what each may do

```
camy connectors [flags]
```

### Options

```
  -h, --help   help for connectors
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
      --sandbox string            off|observe|enforce: OS write-confinement under run_command, this invocation only (default observe; env CAMY_LOCAL_SANDBOX)
      --template string           format --json output with a Go template
  -v, --verbose                   request ids + timings
```

### SEE ALSO

* [camy](camy.md)	 - Camy in your terminal — the same agent, memory, and cloud computer you run at camy.ai
* [camy connectors add](camy_connectors_add.md)	 - Add a connection
* [camy connectors check](camy_connectors_check.md)	 - Check a connection now
* [camy connectors list](camy_connectors_list.md)	 - Every connection, one vocabulary
* [camy connectors pause](camy_connectors_pause.md)	 - Pause a connection — nothing runs, rules are kept
* [camy connectors remove](camy_connectors_remove.md)	 - Remove a connection
* [camy connectors resume](camy_connectors_resume.md)	 - Resume a paused connection
* [camy connectors review](camy_connectors_review.md)	 - See what a server changed since you approved it, and approve the changes

