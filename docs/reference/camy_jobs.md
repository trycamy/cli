## camy jobs

long-running work — list, show, cancel

```
camy jobs [flags]
```

### Examples

```
camy jobs                        live and needs-you jobs
camy jobs show jb_aab2           one job, its history, what it's stuck on
camy jobs cancel jb_aab2         cancel it — its schedule too
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
      --sandbox string            off|observe|enforce: OS write-confinement under run_command, this invocation only (default observe; env CAMY_LOCAL_SANDBOX)
      --template string           format --json output with a Go template
  -v, --verbose                   request ids + timings
```

### SEE ALSO

* [camy](camy.md)	 - Camy in your terminal — the same agent, memory, and cloud computer you run at camy.ai
* [camy jobs cancel](camy_jobs_cancel.md)	 - Cancel a job (its schedule too)
* [camy jobs run-now](camy_jobs_run-now.md)	 - Pull the next fire to now
* [camy jobs show](camy_jobs_show.md)	 - One job + its firing history

