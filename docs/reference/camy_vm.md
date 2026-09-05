## camy vm

Your dedicated cloud workspace

```
camy vm [flags]
```

### Options

```
  -h, --help   help for vm
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
* [camy vm apps](camy_vm_apps.md)	 - What's running inside the workspace
* [camy vm exec](camy_vm_exec.md)	 - Run a command on your workspace — the remote exit code becomes your exit code
* [camy vm ls](camy_vm_ls.md)	 - Every VM you own, across roles
* [camy vm provision](camy_vm_provision.md)	 - Provision (or reconcile) your workspace
* [camy vm resize](camy_vm_resize.md)	 - Resize the workspace in place — data survives; downgrades are refused server-side
* [camy vm shell](camy_vm_shell.md)	 - A live PTY on your workspace — resize and all
* [camy vm sizes](camy_vm_sizes.md)	 - Available workspace sizes, credits, and the GPU add-on
* [camy vm start](camy_vm_start.md)	 - Start the workspace (blocks until it's actually ready)
* [camy vm status](camy_vm_status.md)	 - Workspace state
* [camy vm stop](camy_vm_stop.md)	 - Suspend the workspace (EBS preserved; async — poll vm status)
* [camy vm url](camy_vm_url.md)	 - The workspace's public URL

