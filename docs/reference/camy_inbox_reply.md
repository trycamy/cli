## camy inbox reply

Print the grounded draft; --send queues it with an undo window

```
camy inbox reply ID [flags]
```

### Examples

```
  camy inbox reply em_7f31              # draft only, never sends
  camy inbox reply em_7f31 --edit --send
  camy inbox undo ob_31f2               # inside the undo window
```

### Options

```
      --at string     schedule the reply instead of the 30s window (needs --send)
      --body string   reply text (skips the AI draft)
      --edit          open the draft in $EDITOR first
  -h, --help          help for reply
      --no-wait       don't linger after queueing (send path identical)
      --send          queue the send (30s undo window)
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

* [camy inbox](camy_inbox.md)	 - The unified inbox with triage verdicts — handled, filed, needs you

