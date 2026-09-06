## camy

Camy in your terminal — the same agent, memory, and cloud computer you run at camy.ai

```
camy [flags]
```

### Options

```
      --accessible                linear output: no spinners, boxes, or redraws
      --api-url string            API origin override (env CAMY_API_URL)
      --cloud                     use the cloud VM as the default workspace even when the local bridge is live (env CAMY_CLOUD=1)
      --color string              auto|always|never (default "auto")
  -f, --force                     skip destructive-operation prompts (headless)
  -h, --help                      help for camy
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
  -V, --version                   print version
```

### SEE ALSO

* [camy alias](camy_alias.md)	 - User-defined command aliases
* [camy api](camy_api.md)	 - Any endpoint, authenticated — the escape hatch for what the tree hasn't wrapped
* [camy approvals](camy_approvals.md)	 - Pending checkpoints — list, approve, deny, answer
* [camy auth](camy_auth.md)	 - Sign in, inspect, sign out
* [camy canvas](camy_canvas.md)	 - The chat's Code Canvas — files, contents, pull to disk, published sites
* [camy capture](camy_capture.md)	 - Anything on stdin (or argv) lands in Camy's memory intake
* [camy chat](camy_chat.md)	 - Talk to your agent — streams the reply and every tool call
* [camy chats](camy_chats.md)	 - Sessions: list, show, export
* [camy config](camy_config.md)	 - Settings — get, set, unset, list, edit
* [camy docs](camy_docs.md)	 - The reference, in your terminal
* [camy doctor](camy_doctor.md)	 - Diagnostics with fixes — exit 1 if anything fails
* [camy download](camy_download.md)	 - Save a chat attachment to disk — the handle every 📎 receipt prints
* [camy feed](camy_feed.md)	 - The cards feed — what Camy surfaced for you, actionable by id
* [camy inbox](camy_inbox.md)	 - The unified inbox with triage verdicts — handled, filed, needs you
* [camy integrations](camy_integrations.md)	 - Connected accounts, with health
* [camy jobs](camy_jobs.md)	 - Durable multi-day jobs — list, show, cancel, run-now
* [camy keys](camy_keys.md)	 - List, rotate, revoke API keys
* [camy local](camy_local.md)	 - The local-capability bridge — what Camy may touch on THIS machine
* [camy mode](camy_mode.md)	 - How deep Camy thinks — agent (full tools) or quick (fast, few tools)
* [camy profile](camy_profile.md)	 - Profiles: list, use
* [camy schedule](camy_schedule.md)	 - Cron for your agent — daily, hourly, weekly
* [camy status](camy_status.md)	 - What's happening right now — approvals, needs-you, jobs, workspace
* [camy sweep](camy_sweep.md)	 - The inbox dial — off · shadow · suggest · auto
* [camy tasks](camy_tasks.md)	 - Quick to-dos, tracked by the same mind that reads your calendar
* [camy uninstall](camy_uninstall.md)	 - Remove the binary; asks before touching config, state, or your keychain
* [camy update](camy_update.md)	 - Update camy in place — signature-verified from the release channel
* [camy version](camy_version.md)	 - Print version
* [camy vm](camy_vm.md)	 - Your dedicated cloud workspace
* [camy webhooks](camy_webhooks.md)	 - Endpoints, deliveries, synthetic triggers, dead-letter replay

