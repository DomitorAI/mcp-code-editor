# mcp-code-editor — technical reference

Implementation details referenced by the [user guide](../README.md).

## OAuth 2.1

The server implements OAuth 2.1 natively; no external authorization service is required.

- Clients self-register through Dynamic Client Registration: `POST /oauth/register`.
- Authorization is automatically approved.
- Access tokens are JWTs using **RS256** and expire after **1 hour**.
- Refresh tokens are one-shot.
- **Public clients** use Proof Key for Code Exchange (**PKCE**); loopback redirects are supported for local clients.
- **Confidential clients** support `client_secret_basic` and `client_secret_post`.
- **CIMD** (Client ID Metadata Document) is supported. A client ID may be the URL of a public metadata document.
- CIMD fetching uses public hosts only, no redirects, and size/time limits as an SSRF protection.
- Protected-resource metadata is published at `/.well-known/oauth-protected-resource`.
- Tokens are bound to the endpoint origin. A token issued for a previous quick-tunnel URL is rejected when the endpoint URL changes.

## Configuration and Local Data

Local application data is stored under:

```text
%LOCALAPPDATA%\mcp-code-editor\
```

Important files include:

| File | Purpose |
|---|---|
| `config.json` | Project aliases, default project, tunnel and command policy configuration. |
| `state\<project-key>\mcp.oauth.json` | Per-project OAuth RSA key, registered clients, tokens. |
| `state\<project-key>\audit.log` | Per-project append-only JSONL audit log. |
| `state\<project-key>\instance.lock` | File lock while the project is served; one instance per project. |

`<project-key>` = first 16 hex chars of SHA-256 over the normalized absolute path (trailing separators stripped; case-insensitive on Windows). State folders inactive for 90+ days are removed at startup; the active folder is kept. A legacy top-level `mcp.oauth.json` / `audit.log` is moved into the started project's state directory on first start after an update (skipped for explicit `http.oauthStorePath` / `auditLogPath`, or when the legacy state does not belong to the started project).

Audit timestamps (`ts`) are local time with UTC offset, e.g. `2026-09-24T13:53:59+03:00`; entries written by older versions are UTC (`...Z`).

## Command approval

With `onOutsidePath`, the following continue to require approval when detected:

- absolute/UNC paths;
- environment variables;
- nested shells;
- inline or encoded code;
- network tools;
- registry access;
- destructive verbs.

## Code intelligence

- **C#**: `MSBuildWorkspace` loads the root `.sln` / `.slnx` (alphabetical first) or the single `.csproj`. The loaded solution is an in-memory snapshot — `TryApplyChanges` is never called, so nothing is saved to disk. Changed, added and removed `.cs` files are synchronized on every call; a changed `.csproj` / `.sln` reloads the workspace. A failed load or missing SDK is retried after 30 s.
- **LSP**: one server process per project and language (`pyright-langserver`, `typescript-language-server`, `vscode-html-language-server`, `vscode-css-language-server`, found on `PATH`). Open documents are synchronized with `didOpen` / `didChange` / `didClose`; other files of the language with `workspace/didChangeWatchedFiles`. Diagnostics are pulled (`textDocument/diagnostic`) when the server advertises `diagnosticProvider`, otherwise awaited from `publishDiagnostics`.
- Server URIs are normalized to local paths (servers answer `file:///c%3A/...`).
- A crashed language server is restarted on the next call; an unavailable toolchain is re-checked after 60 s.

## .gitignore filtering

`list_files` and `search_code` use Git as the oracle: `git ls-files -z --cached --others --exclude-standard` for files, `git check-ignore` for directories that have no visible file (checked level by level; ignored subtrees are not traversed). Without Git or outside a repository, no filter is applied. Nested repositories and submodules are listed as opaque directories.

## Tool responses

Tool responses are JSON with relaxed escaping: quotes, `<`, `>`, `+`, `&` and non-ASCII characters are kept as-is instead of `"`-style escapes, reducing the text returned to the agent.

## Auto-Update

- The update downloads `mcp-code-editor-win-x64.zip` to a temporary folder.
- A temporary external `.cmd` script replaces the locked application files and restarts the application.
