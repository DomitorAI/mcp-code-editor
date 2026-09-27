# mcp-code-editor — advanced configuration

For users who want to adjust settings by hand or connect their own MCP client. The [user guide](../README.md) covers everything needed for normal use.

## Local files

Everything lives under `%LOCALAPPDATA%\mcp-code-editor\`:

| File | Purpose |
|---|---|
| `config.json` | Settings (see below). |
| `state\<project>\audit.log` | Audit log of the project: one JSON line per change, deletion or command. |
| `state\<project>\mcp.oauth.json` | Sign-in data of the project's clients. Keep it private. |

Each project has its own `state` folder. Folders of projects not used for 90 days are removed at startup; their clients sign in again next time.

## `config.json`

Most settings are managed from the application window. These can be changed by hand while the application is stopped (key names are case-insensitive):

| Key | Default | Meaning |
|---|---|---|
| `commands.approval` | `always` | `always`, `onOutsidePath` or `never` — see *Command approval* in the user guide. |
| `denyFilePatterns` | `.env`, `.env.*`, `*.pem`, `*.key`, `*.pfx`, `*.p12`, `*.jks`, `*.keystore`, `*.kdbx`, `*.publishsettings`, `id_rsa*`, `id_dsa*`, `id_ecdsa*`, `id_ed25519*`, `.netrc`, `_netrc`, `.git-credentials`, `.npmrc`, `.pypirc`, `secrets.json`, `credentials.json` | File names hidden from the agent. `*.example`, `*.sample`, `*.template`, `*.dist` and `*.pub` always stay visible. `[]` disables the list. |
| `denySegments` | `.git`, `bin`, `obj`, `.vs`, `node_modules` | Folder names the agent cannot enter. |
| `maxWriteBytes` | `1048576` (1 MB) | Largest file the agent can write. |

An invalid `commands.approval` value, or a `config.json` that is not valid JSON, stops the application at **Start** with an error message.

## Limits

| Limit | Value |
|---|---|
| Text file read or edited in one call | 25 MB |
| File searched when searching a folder | 2 MB (larger files are skipped and counted) |
| Image | 3.75 MB, 8,000 px per side |

## Connecting your own MCP client

The server implements OAuth 2.1 itself; no external authorization service is used.

- Dynamic Client Registration: `POST /oauth/register`.
- Public clients use PKCE; loopback redirects are supported for local clients.
- Confidential clients: `client_secret_basic` and `client_secret_post`.
- Client ID Metadata Documents (CIMD) are supported.
- Protected-resource metadata: `/.well-known/oauth-protected-resource`.
- Access tokens expire after 1 hour; refresh tokens are single-use.
- Tokens are tied to the endpoint URL: after a quick-tunnel restart, the client must sign in again.
