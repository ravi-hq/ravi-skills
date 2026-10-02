# @ravi-hq/mcp

Config helper for the Ravi HTTP MCP server. The server is remote. This package does not run a local stdio process, does not embed credentials, and does not ship a Connect card.

## Endpoint

| | URL |
| --- | --- |
| Default | `https://api.ravi.app/mcp` |
| Also available | `https://api.ravi.id/mcp` |

Use `https://api.ravi.app/mcp` unless you need the `ravi.id` host.

## Install

```bash
npm install @ravi-hq/mcp
```

You can also copy the JSON below without installing the package.

## Cursor

Project file `.cursor/mcp.json`, or global `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "ravi": {
      "type": "http",
      "url": "https://api.ravi.app/mcp"
    }
  }
}
```

## Claude

Project file `.mcp.json`:

```json
{
  "mcpServers": {
    "ravi": {
      "type": "http",
      "url": "https://api.ravi.app/mcp"
    }
  }
}
```

Or from a terminal:

```bash
claude mcp add --transport http ravi https://api.ravi.app/mcp
```

Leave headers out of the config. Do not commit API keys.

## Helper

```js
import { MCP_SERVER_URL, mcpServers } from "@ravi-hq/mcp";

MCP_SERVER_URL;
// "https://api.ravi.app/mcp"

mcpServers;
// { ravi: { type: "http", url: "https://api.ravi.app/mcp" } }
```

`ALT_MCP_SERVER_URL` is `https://api.ravi.id/mcp`. `mcpConfig(url)` returns the full `{ mcpServers }` document (`mcp.json` in this package is the default).

## Publish

This repo does not publish the package from GitHub Actions. From a checkout, with an npm account that can publish to the `@ravi-hq` org:

```bash
cd packages/mcp
npm publish --access public
```

`publishConfig.access` is already `public`. `prepublishOnly` runs `npm test` before upload.

## Connect card

This package does not enable or implement a Connect card. That UX stays off until a separate go-ahead.
