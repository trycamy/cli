## camy canvas

The chat's Code Canvas — files, contents, pull to disk, published sites

```
camy canvas [flags]
```

### Examples

```
  camy canvas                       # files in your last chat's canvas
  camy canvas cat index.html
  camy canvas pull ./site           # write the files locally
  camy canvas open                  # the real canvas, on the web
  camy canvas sites                 # everything you've published
```

### Options

```
      --chat string   chat id (short ids resolve; default: your last chat)
  -h, --help          help for canvas
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
* [camy canvas access](camy_canvas_access.md)	 - Who can reach a published site
* [camy canvas cat](camy_canvas_cat.md)	 - Print one canvas file — raw bytes, pipe freely
* [camy canvas domain](camy_canvas_domain.md)	 - Custom domain for a published site
* [camy canvas export](camy_canvas_export.md)	 - Download the canvas as pwa · capacitor · zip
* [camy canvas files](camy_canvas_files.md)	 - List the canvas files
* [camy canvas indexable](camy_canvas_indexable.md)	 - Search-engine indexing opt-out
* [camy canvas open](camy_canvas_open.md)	 - Open this chat's canvas at camy.ai
* [camy canvas preview](camy_canvas_preview.md)	 - Open the canvas in YOUR browser — a local checkout, no publish
* [camy canvas publish](camy_canvas_publish.md)	 - Publish the canvas as a live site — the host is confirmed before it's claimed
* [camy canvas pull](camy_canvas_pull.md)	 - Write the canvas files to a local directory
* [camy canvas restore](camy_canvas_restore.md)	 - Roll the canvas back to a checkpoint
* [camy canvas rollback](camy_canvas_rollback.md)	 - Roll a published site back — no version means one publish back
* [camy canvas sites](camy_canvas_sites.md)	 - Published sites — every canvas that shipped
* [camy canvas snapshot](camy_canvas_snapshot.md)	 - Checkpoint the canvas as it stands
* [camy canvas snapshots](camy_canvas_snapshots.md)	 - Checkpoints of this canvas, newest first
* [camy canvas versions](camy_canvas_versions.md)	 - Published versions of a site, newest first

