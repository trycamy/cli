## camy auth login

Sign in from the browser — one click there, an expiring key here

```
camy auth login [flags]
```

### Examples

```
  camy auth login              # browser handoff (default)
  camy auth login --code       # email + one-time code instead
  camy auth login --with-key   # paste an existing key
  camy auth login --scopes +datasets:write,-jobs:write
```

### Options

```
      --code            email + one-time code instead of the browser
  -h, --help            help for login
      --scopes string   scope grammar: +add,-remove relative to the default set, or 'all'
      --with-key        paste an existing key
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

* [camy auth](camy_auth.md)	 - Sign in, inspect, sign out

