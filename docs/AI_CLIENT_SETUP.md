# AI Client Setup

Use this MCP server from Codex:

```toml
[mcp_servers.godotMCP]
command = "node"
args = [ "C:/Users/dangp/GodotProjects/first-project/tools/mcp-godot/src/server.mjs", "--project-root", "C:/Users/dangp/GodotProjects/first-project" ]
startup_timeout_sec = 20
env = { GODOT_PROJECT_ROOT = "C:/Users/dangp/GodotProjects/first-project", GODOT_MCP_PORT = "8765" }
```

Then restart Codex and ask it to use `docs/MCP_AGENT_INSTRUCTIONS.md` and `docs/MCP_CAPABILITIES.md`.
First calls: `godot_agent_instructions`, `godot_help`, `godot_doctor`, `godot_project_scan`, `godot_check_errors`.

## Shared Rules

- Use Godot 4.x APIs only.
- Keep all file changes inside the project root.
- Never write real API keys to source files or logs.
- Use docs/MCP_AGENT_INSTRUCTIONS.md for instruction-first mode.
- Call godot_agent_instructions for the user task before larger edits.
- For complex mechanics, use godot_agent_instructions workflow research_mechanic and research GitHub, YouTube, Godot docs, and credible web sources before implementing.
- Use docs/MCP_CAPABILITIES.md as the MCP tool map for Codex, Claude, and other clients.
- Start with project scan, scene list, and error checks before larger edits.
