<p align="center">
  <img src="assets/logo-banner.png" alt="mcp-code-editor" width="900">
</p>

<h1 align="center">mcp-code-editor</h1>

<p align="center">
  Let an AI agent — your <strong>AI</strong> web chat or any local MCP client — <strong>read, edit, build and test your project directly on disk</strong>,
  through a local MCP server with <strong>OAuth 2.1</strong> (PKCE for public clients, client secret for confidential ones) and an automatic HTTPS tunnel (quick or named).
  One line to install. You stay in control: the agent never commits and never pushes.
</p>

## Who it's for

For people who work with an AI agent in the browser — and want that agent to work on the **real project**, not on pasted fragments:

- **One-off, no account** — try it once on a project when you need it; no sign-up involved.
- **No copy-paste** — you write the prompt; the agent reads the project as a whole — classes, data and the links between them — instead of you pasting code chunks.
- **Solutions grounded in your code** — with the full project context, the agent proposes a correct fix instead of guessing from fragments.

## Install (Windows 10/11 x64)

No .NET SDK, no admin rights, no installer — one line in PowerShell:

```powershell
irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/bootstrap.ps1 | iex
```

The script downloads the self-contained app + cloudflared into `%LOCALAPPDATA%` and puts the **mcp-code-editor** icon on your desktop. Double-click it to start.

## How to use it

1. Pick your project (**"Browse..."** on the **Project** row) and choose the access mode: **Read-Write** or **Read-only** (the window has 8 rows: **Project**, **Mode**, **Update**, **Start/Stop** + **Feedback**, **Tunnel**, **Endpoint**, **Status**, plus the **Uninstall** button at the bottom-right).

   <p align="center">
     <img src="assets/main-window.png" alt="The mcp-code-editor control window: Project and Mode rows, Update status, Start and Feedback buttons, Endpoint and Tunnel rows, Uninstall button">
   </p>

   *The control window for steps 1–2: choose the project on the **Project** row, the access mode on the **Mode** row, then press **Start**.*

2. Press **Start** — the app picks a free port, starts the MCP server bound to `127.0.0.1` and opens a public HTTPS tunnel (cloudflared). With the default *quick tunnel* the port is chosen automatically (8080–8180); with a *named tunnel* (**Tunnel** row → **Configure...**) it is fixed (default 8080). The public URL appears on the **Endpoint** row, with a **Copy** button.
3. Connect your AI chat (or any local MCP client) to `<public URL>/mcp`. In a web AI chat, add a custom MCP connector with that endpoint; in a local MCP client, add the endpoint as an MCP server — the OAuth 2.1 handshake completes automatically.

   *Web AI chat path (ChatGPT shown):*

   <p align="center">
     <img src="assets/connect-chatgpt-settings.png" alt="ChatGPT web app sidebar with the account menu open, a red arrow pointing at Settings">
   </p>

   *In the ChatGPT web app, open the account menu at the bottom-left of the sidebar and select **Settings**.*

   <p align="center">
     <img src="assets/connect-chatgpt-developer-mode.png" alt="ChatGPT settings on the Plugins page, with the Developer mode option highlighted by a red rectangle">
   </p>

   *In **Settings → Plugins**, open **Developer mode**.*

   <p align="center">
     <img src="assets/connect-chatgpt-developer-mode-toggle.png" alt="ChatGPT Security and login settings, Developer mode toggle switched on, highlighted by a red rectangle and arrow, with an ELEVATED RISK badge">
   </p>

   *Turn the **Developer mode** toggle on (it lives under **Security and login**) — this allows unverified connectors. Note the **ELEVATED RISK** warning.*

   <p align="center">
      <img src="assets/connect-chatgpt-plugins-add.png" alt="ChatGPT Plugins page with the Plugins item highlighted in the sidebar and the plus button highlighted in the top-right corner">
    </p>

    *Open **Plugins** from the sidebar and press the **+** button (top-right) to add a connector.*

   <p align="center">
     <img src="assets/connect-chatgpt-new-plugin.png" alt="New Plugin dialog with a name field, a Server URL field, OAuth authentication, and a checked I understand and want to continue box, with the mcp-code-editor window showing the public Endpoint in the background">
   </p>

   *Give the connector a name and paste the public **Server URL** (the tunnel endpoint from the mcp-code-editor **Endpoint** row, shown in the background). Keep **Authentication** on **OAuth** and tick **I understand and want to continue**.*

   <p align="center">
     <img src="assets/connect-chatgpt-oauth-consent.png" alt="OAuth consent screen reading Add your connector to ChatGPT, with the Sign in button highlighted by a red rectangle">
   </p>

   *On the consent screen, press **Sign in with your-connector** — the OAuth 2.1 handshake completes and the connector is ready to use.*
4. Ask the agent what you want: *"fix the bug in X"*, *"add feature Y"*, *"run the tests"* — it reads the code, edits files, runs build/test, and reports back.
5. Review the result with `git diff` in your clone, then commit and push **yourself**.
6. Press **Stop** when you're done — the tunnel URL (a random subdomain, new on every start, with the quick tunnel) is your access barrier.

## Tunnels: quick vs named

The **Tunnel** row (5th in the window) switches between the two modes; **Configure...** saves the settings in the local `config.json` (the Cloudflare token stays on your machine only). Leaving the fields empty uses the quick tunnel.

| | Quick tunnel (default — **Tunnel** row empty) | Named tunnel (token + hostname set) |
|---|---|---|
| Cloudflare account | not needed | your own (free) — Zero Trust → Tunnels + a Public Hostname pointing at `http://localhost:8080` |
| Public URL | random `*.trycloudflare.com` subdomain, **new on every start** | **stable** — your own domain, the same on every run |
| Local port | free port picked automatically (8080–8180) | fixed (default 8080; an error if the port is busy) |
| Setup | none — press **Start** | once: create the tunnel + Public Hostname in your account, then paste the token/hostname on the **Tunnel** row |
| Best for | testing, occasional use | a **permanent** AI chat connection (one MCP connector configured once, with a URL that never changes) |

With the quick tunnel, on every start you only copy the new URL into your client's config (**Endpoint** row → **Copy**) — no new connection is needed: the registered client (DCR) and its refresh tokens stay valid in `mcp.oauth.json`; only the previous run's access token is rejected (tokens are bound to their origin URL) and the client re-authorizes automatically.

## Authentication (OAuth 2.1)

- The server implements **OAuth 2.1 natively** — no external authorization service. Clients self-register (**DCR**, `POST /oauth/register`), authorization is **auto-approved**, and tokens are **JWT (RS256, 1 hour)** with **one-shot refresh tokens**.
- Both **public clients** (PKCE — the typical web chat; loopback redirect for local clients) and **confidential clients** (`client_secret_basic` / `client_secret_post`) are supported.
- **CIMD** (RFC 9728, as adopted by the 2025-11-25 MCP spec): the client id can also be the URL of a public metadata document; the server fetches it with strict limits (public hosts only, no redirects, size/time caps) as an anti-SSRF guard.
- Every token is **bound to the URL (origin) it was issued for** — a token from a previous quick-tunnel URL is rejected on the new URL.

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
- The server binds to `127.0.0.1` only; the public URL is a cloudflared tunnel — a random subdomain with the quick tunnel, or your own fixed domain with a named tunnel (**Tunnel** row) — alive only while the app is running.
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
- **Installing** — on **Update**, the app downloads the `mcp-code-editor-win-x64.zip` archive to a temp folder (progress on the Status row), then closes and launches a small external `.cmd` script that waits for the process to exit, copies the binaries over `%LOCALAPPDATA%\mcp-code-editor\` and restarts the app automatically — the window comes back within a few seconds with the new version; you do nothing in between. (The external script is needed because the running executable is locked by the OS and can't overwrite itself.)
- **If the window doesn't come back** — the new version is already installed: start the app manually. On startup, the Status row shows that the last update did not restart the app automatically; each step of the script is logged in `%TEMP%\mcp-code-editor-update.log`.
- **What is kept** — the archive contains only the app binaries (exe + dll). `config.json`, `mcp.oauth.json` (the RSA key + OAuth tokens) and `audit.log` are **not** in the archive, so they survive the update; because the OAuth key is kept, already-authorized tokens and clients stay valid — no re-authorization needed.
- **Installed build only** — self-update works only in the installed build (under `%LOCALAPPDATA%\mcp-code-editor`). A development build (run from `bin\`) shows "Self-update is only available in the installed version."
- **Safe failure mode** — any problem (interrupted download, the script blocked by antivirus/SmartScreen) leaves the app on the old version; the binary copy is retried up to 3 times. If a copy is still interrupted mid-way, repeat **Update** (a fresh archive is downloaded) or re-run the bootstrap. Temp folders left by an interrupted update are cleaned up on the next start.

## Uninstall

1. **From the app** (recommended) — the **Uninstall** button at the bottom-right. It is enabled only while the server is not running (press **Stop** first) and only in the installed build. On confirmation the app launches a small external script that waits for the window to close and then removes the items below — the same mechanism as the auto-update, needed because the running executable is locked by the OS and cannot delete itself.
2. **With the script** (if the app no longer opens) — close it, then one line (as for install):

   ```powershell
   irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/uninstall.ps1 | iex
   ```
3. **What is removed** (both ways): `%LOCALAPPDATA%\mcp-code-editor\` (exe, config, OAuth store, audit log), the desktop shortcut and the temp files. `cloudflared` is kept, and your project code is never touched. If an item stays locked (explorer open in the folder, antivirus), rerun the script.

No registry entries, no Windows service, no PATH changes.

## License

All rights reserved — see [LICENSE](LICENSE).
