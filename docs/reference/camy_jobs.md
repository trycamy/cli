## camy jobs

Durable multi-day jobs — list, show, cancel, run-now

```
camy jobs [flags]
```

### Options

```
      --all             auto-paginate to the end
  -h, --help            help for jobs
  -L, --limit int       page size (default 100)
      --offset int      page offset
      --status string   filter by status (active|suspended|blocked|completed|failed|cancelled|needs_attention)
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

* [camy](camy.md)	 - Camy in your terminal — the same agent, memory, and cloud computer you run at camy.ai
* [camy jobs cancel](camy_jobs_cancel.md)	 - Cancel a job (its schedule too)
* [camy jobs run-now](camy_jobs_run-now.md)	 - Pull the next fire to now
* [camy jobs show](camy_jobs_show.md)	 - One job + its firing history

