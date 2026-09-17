<p align="center">
  <img src="assets/logo-banner.png" alt="mcp-code-editor" width="900">
</p>

<h1 align="center">mcp-code-editor</h1>

<p align="center">
  Let an AI agent — your <strong>AI</strong> web chat or any local MCP client — <strong>read, edit, build and test your project directly on disk</strong>,
  through a local MCP server with <strong>OAuth 2.1 + PKCE</strong> and an automatic HTTPS tunnel.
  One line to install. You stay in control: the agent never commits and never pushes.
</p>

## Install (Windows 10/11 x64)

No .NET SDK, no admin rights, no installer — one line in PowerShell:

```powershell
irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/bootstrap.ps1 | iex
```

The script downloads the self-contained app + cloudflared into `%LOCALAPPDATA%` and puts the **mcp-code-editor** icon on your desktop. Double-click it to start.

## How to use it

1. Pick your project (**"Browse..."** on the **Project** row) and choose the access mode: **Read-Write** or **Read-only**.
2. Press **Start** — the app picks a free port, starts the MCP server bound to `127.0.0.1` and opens a public HTTPS tunnel (cloudflared). The public URL appears on the **Endpoint** row, with a **Copy** button.
3. Connect your AI chat (or any local MCP client) to `<public URL>/mcp`. In a web AI chat, add a custom MCP connector with that endpoint; in a local MCP client, add the endpoint as an MCP server — the OAuth 2.1 + PKCE handshake completes automatically.
4. Ask the agent what you want: *"fix the bug in X"*, *"add feature Y"*, *"run the tests"* — it reads the code, edits files, runs build/test, and reports back.
5. Review the result with `git diff` in your clone, then commit and push **yourself**.
6. Press **Stop** when you're done — the tunnel URL (a random subdomain, new on every start) is your access barrier.

## What the agent can do

| Tool | What it does |
|---|---|
| `list_projects` | lists the registered project aliases |
| `list_files` | walks the project tree (glob pattern, depth limit) |
| `read_file` | reads a text file (numbered lines, pagination) |
| `search_code` | regex search across the project |
| `edit_file` | exact snippet replacement (the match must be unique) |
| `write_file` | creates or overwrites a file (size cap, UTF-8) |
| `delete_file` | deletes a single file (never folders) |
| `run_build` | `dotnet build` in the project root |
| `run_tests` | `dotnet test` (VSTest `--filter` supported) |
| `run_command` | any command in the project root — build/test/lint for any project type (exit code + last ~20 KB of output) |

All tools take an optional `project` alias. Responses are JSON: `{"ok": true, ...}` / `{"ok": false, "error": "..."}`.

## Safety

- The agent writes freely **only inside the active project**. Any absolute path is treated as *outside the project*: reads are free, writes require **your approval in the window** (60 s timeout → auto-deny).
- `denySegments` (`.git`, `bin`, `obj`, `.vs`, `node_modules`) blocks both reads and writes — including through absolute paths and symlinks/junctions.
- Every write, delete and overwrite is recorded in an append-only **audit log** (JSONL).
- **Read-only** mode exposes the read tools only — the safe choice for sensitive projects.
- `run_command` executes as *you*, in the project root, with your OS permissions — don't point a public chat at a sensitive project.
- The server binds to `127.0.0.1` only; the public URL is a cloudflared tunnel with a random subdomain, alive only while the app is running.

## Requirements

- Windows 10/11 x64 with PowerShell
- internet access (for the public tunnel)
- nothing else — the exe is self-contained (no .NET SDK) and cloudflared is downloaded by the bootstrap

## Feedback

- [Report a bug or request a feature](https://github.com/DomitorAI/mcp-code-editor/issues) — templates included
- [Start a discussion](https://github.com/DomitorAI/mcp-code-editor/discussions)
- or press the **Feedback** button in the app (from the next release)

## Uninstall

Close the app, then one line (as for install):

```powershell
irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/uninstall.ps1 | iex
```

Removes `%LOCALAPPDATA%\mcp-code-editor\` (exe, config, OAuth store, audit log), the desktop shortcut and the temp files. `cloudflared` is kept. No registry entries, no Windows service, no PATH changes.

## License

All rights reserved — see [LICENSE](LICENSE).
