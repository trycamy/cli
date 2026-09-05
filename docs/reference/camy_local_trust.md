## camy local trust

Pre-approved commands for this project (auto-run without a prompt)

### Options

```
  -h, --help   help for trust
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

* [camy local](camy_local.md)	 - The local-capability bridge — what Camy may touch on THIS machine
* [camy local trust add](camy_local_trust_add.md)	 - Trust a command in this project — it auto-runs with no prompt
* [camy local trust add-path](camy_local_trust_add-path.md)	 - Trust a write_file target path (held for a future write carve-out)
* [camy local trust list](camy_local_trust_list.md)	 - Show this project's trusted commands and paths
* [camy local trust remove](camy_local_trust_remove.md)	 - Revoke a trusted command
* [camy local trust remove-path](camy_local_trust_remove-path.md)	 - Revoke a trusted path

