## camy device scope add

Grant a capability, optionally scoped to one or more paths

```
camy device scope add [PATH...] [flags]
```

### Examples

```
  camy device scope add ~/Projects --read
  camy device scope add --capability terminal
```

### Options

```
      --capability string     capability name for anything besides files.read/files.write
      --expires string        RFC 3339 expiry — omit for a standing grant
  -h, --help                  help for add
      --mode-ceiling string   the highest mode this grant is honored in (default: watching)
      --network               allow outbound network for this grant (F6's allowlist still applies)
      --read                  grant files.read on the given path(s)
      --write                 grant files.write on the given path(s)
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

* [camy device scope](camy_device_scope.md)	 - Grant, remove, or list what a linked computer may touch

