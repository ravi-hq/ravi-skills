export declare const MCP_SERVER_URL: "https://api.ravi.app/mcp";

export declare const ALT_MCP_SERVER_URL: "https://api.ravi.id/mcp";

export interface McpHttpServer {
  type: "http";
  url: string;
}

export interface McpServersConfig {
  mcpServers: {
    ravi: McpHttpServer;
  };
}

export declare const mcpServers: {
  ravi: McpHttpServer;
};

export declare function mcpConfig(url?: string): McpServersConfig;
