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

## Command approval

With `onOutsidePath`, the following continue to require approval when detected:

- absolute/UNC paths;
- environment variables;
- nested shells;
- inline or encoded code;
- network tools;
- registry access;
- destructive verbs.

## Auto-Update

- The update downloads `mcp-code-editor-win-x64.zip` to a temporary folder.
- A temporary external `.cmd` script replaces the locked application files and restarts the application.
