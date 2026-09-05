## camy vm exec

Run a command on your workspace — the remote exit code becomes your exit code

### Synopsis

Runs on your dedicated cloud workspace. stdout/stderr come home on their own
streams and the remote exit code (0-254) is mirrored to your shell, ssh-style.
camy's own failures for this command exit 255 with the reason on stderr.

```
camy vm exec -- CMD... [flags]
```

### Examples

```
  camy vm exec -- pytest -q
  camy vm exec --cwd ~/app -- make test && echo green
```

### Options

```
      --cwd string    working directory on the workspace
  -h, --help          help for exec
      --no-wake       exit 7 instead of waking a stopped workspace
      --timeout int   in-container wall clock in seconds (1-600; server default 120)
      --vm string     run on a specific VM id (not available yet; exec runs on your primary workspace)
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

* [camy vm](camy_vm.md)	 - Your dedicated cloud workspace

