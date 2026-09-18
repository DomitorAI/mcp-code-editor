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
- **Prompt injection.** The agent receives instructions from the chat; an adversarial prompt could try to make it modify files more than you intended. For sensitive projects, set `http.readOnly: true` — the agent can still read and search, but every write is refused.
- **Custom MCP support varies.** Check your client's docs to see whether it accepts its own MCP servers with a custom endpoint; if not, the remaining option is a local MCP client (same machine).
- **You are responsible for your prompts.** The agent acts on what you ask; you own the prompts you write and the changes they produce. Review what the agent did (diff, audit log) before keeping them.
- **Recommendation: keep the project under Git**, so any change an agent makes can be easily reviewed and undone.

## Requirements

- Windows 10/11 x64 with PowerShell
- internet access (for the public tunnel)
- nothing else — the exe is self-contained (no .NET SDK) and cloudflared is downloaded by the bootstrap

## Feedback

- [Report a bug or request a feature](https://github.com/DomitorAI/mcp-code-editor/issues) — templates included
- [Start a discussion](https://github.com/DomitorAI/mcp-code-editor/discussions)
- or press the **Feedback** button in the app (from the next release)

## Auto-update

The app checks for a newer version on startup and, if one is available, you can install it with a single click — no need to re-run the bootstrap line.

- **Startup check** — the app queries GitHub Releases (`releases/latest`) with a 10 s timeout. Any failure (offline, bad response, missing asset) just shows "Could not check for updates (offline?)" and never blocks — the app works normally.
- **The Update row** (third row in the window) — shows the state: you're on the latest version / "Version X is available - update recommended" / offline. The **Update** button is enabled only when a newer version exists **and** the server is not running (press **Stop** first).
- **Installing** — on **Update**, the app downloads the `mcp-code-editor-win-x64.zip` archive to a temp folder (progress on the Status row), then launches a small external `.cmd` script that waits for the app to close, copies the binaries over `%LOCALAPPDATA%\mcp-code-editor\` and restarts the app automatically. (The external script is needed because the running executable is locked by the OS and can't overwrite itself.)
- **What is kept** — the archive contains only the app binaries (exe + dll). `config.json`, `mcp.oauth.json` (the RSA key + OAuth tokens) and `audit.log` are **not** in the archive, so they survive the update; because the OAuth key is kept, already-authorized tokens and clients stay valid — no re-authorization needed.
- **Installed build only** — self-update works only in the installed build (under `%LOCALAPPDATA%\mcp-code-editor`). A development build (run from `bin\`) shows "Self-update is only available in the installed version."
- **Safe failure mode** — any problem (interrupted download, the script blocked by antivirus/SmartScreen) leaves the app on the old version; there is never a corrupted intermediate state. Temp folders left by an interrupted update are cleaned up on the next start.

## Uninstall

Close the app, then one line (as for install):

```powershell
irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/uninstall.ps1 | iex
```

Removes `%LOCALAPPDATA%\mcp-code-editor\` (exe, config, OAuth store, audit log), the desktop shortcut and the temp files. `cloudflared` is kept. No registry entries, no Windows service, no PATH changes.

## License

All rights reserved — see [LICENSE](LICENSE).
