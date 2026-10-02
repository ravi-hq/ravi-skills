import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { ALT_MCP_SERVER_URL, MCP_SERVER_URL, mcpConfig, mcpServers } from "./index.js";

test("default URL is api.ravi.id/mcp", () => {
  assert.equal(MCP_SERVER_URL, "https://api.ravi.id/mcp");
  assert.equal(ALT_MCP_SERVER_URL, "https://api.ravi.app/mcp");
});

test("mcpServers matches shipped mcp.json", () => {
  const shipped = JSON.parse(readFileSync(new URL("./mcp.json", import.meta.url), "utf8"));
  assert.deepEqual(shipped, { mcpServers });
  assert.deepEqual(mcpConfig(), shipped);
  assert.equal(mcpConfig(ALT_MCP_SERVER_URL).mcpServers.ravi.url, ALT_MCP_SERVER_URL);
  assert.equal(shipped.mcpServers.ravi.type, "http");
  assert.equal("headers" in shipped.mcpServers.ravi, false);
});
