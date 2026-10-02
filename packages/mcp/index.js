/** Canonical Ravi HTTP MCP endpoint. */
export const MCP_SERVER_URL = "https://api.ravi.id/mcp";

/** Same MCP server; api.ravi.app still dual-serves. */
export const ALT_MCP_SERVER_URL = "https://api.ravi.app/mcp";

/** Sample `mcpServers` entry for Cursor and Claude. */
export const mcpServers = {
  ravi: {
    type: "http",
    url: MCP_SERVER_URL,
  },
};

/**
 * Full mcp.json document. Pass `ALT_MCP_SERVER_URL` to pin the ravi.app host.
 * @param {string} [url]
 */
export function mcpConfig(url = MCP_SERVER_URL) {
  return {
    mcpServers: {
      ravi: {
        type: "http",
        url,
      },
    },
  };
}
