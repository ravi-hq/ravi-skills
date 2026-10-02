/** Default Ravi HTTP MCP endpoint. */
export const MCP_SERVER_URL = "https://api.ravi.app/mcp";

/** Same MCP server on the ravi.id host. */
export const ALT_MCP_SERVER_URL = "https://api.ravi.id/mcp";

/** Sample `mcpServers` entry for Cursor and Claude. */
export const mcpServers = {
  ravi: {
    type: "http",
    url: MCP_SERVER_URL,
  },
};

/**
 * Full mcp.json document. Pass `ALT_MCP_SERVER_URL` to pin the ravi.id host.
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
