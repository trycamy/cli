## camy update

Update camy in place — signature-verified from the release channel

### Synopsis

Update camy in place from the release channel.

camy fetches the release manifest for the new version and verifies its
minisign signature against a public key built into this binary, then checks
the downloaded tarball against the hash that signed manifest carries. If the
signature is missing, or is not by camy's release key, nothing is installed
and the binary you are running stays exactly as it is.

  camy update --check          # report what's out there, install nothing
  camy update --channel stable # stable (default) or canary

Installs managed by Homebrew or npm are left to their package manager.

```
camy update [flags]
```

### Options

```
      --channel string   stable|canary (env CAMY_CHANNEL) (default "stable")
      --check            report what's out there without installing
  -h, --help             help for update
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

