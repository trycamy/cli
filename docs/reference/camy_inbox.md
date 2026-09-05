## camy inbox

The unified inbox with triage verdicts — handled, filed, needs you

```
camy inbox [flags]
```

### Options

```
      --all             auto-paginate to the end
      --cursor string   resume from a next_cursor
  -h, --help            help for inbox
  -L, --limit int       page size
      --needs-you       only what's waiting on you
      --tab string      rail tab (needs-you|unread|people|newsletters|receipts|calendar|all)
      --unread          unread only
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
* [camy inbox archive](camy_inbox_archive.md)	 - Archive (provider write-through)
* [camy inbox mark-read](camy_inbox_mark-read.md)	 - Mark read (provider write-through)
* [camy inbox outbox](camy_inbox_outbox.md)	 - Queued sends still inside their undo window
* [camy inbox read](camy_inbox_read.md)	 - Show the email, then mark it read
* [camy inbox reply](camy_inbox_reply.md)	 - Print the grounded draft; --send queues it with an undo window
* [camy inbox restore](camy_inbox_restore.md)	 - Bring it back to the inbox
* [camy inbox send](camy_inbox_send.md)	 - Compose and send a brand-new email — synchronous, no outbox, no undo
* [camy inbox show](camy_inbox_show.md)	 - One email with its triage
* [camy inbox snooze](camy_inbox_snooze.md)	 - Hide it until later — resurfaces to the inbox automatically
* [camy inbox undo](camy_inbox_undo.md)	 - Pull a queued send back before it leaves
* [camy inbox unsnooze](camy_inbox_unsnooze.md)	 - Bring a snoozed email back now
* [camy inbox unsubscribe](camy_inbox_unsubscribe.md)	 - Act on the email's List-Unsubscribe — one-click/mailto run server-side, link prints the URL

