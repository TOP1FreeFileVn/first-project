import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import fs from 'node:fs/promises';
import path from 'node:path';

// Small stdio MCP client for the local Godot server. Plans are project-local JSON.
const root = process.cwd();
const plan = JSON.parse(await fs.readFile(process.argv[2], 'utf8'));
const output = path.resolve(root, plan.output);
await fs.mkdir(output, { recursive: true });
const profile = path.join(output, 'profile');
await fs.mkdir(profile, { recursive: true });
const child = spawn(process.execPath, ['tools/mcp-godot/src/server.mjs', '--project-root', root], {
  cwd: root, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'],
  env: { ...process.env, GODOT_CLI: plan.godot,
    APPDATA: profile, LOCALAPPDATA: profile }
});
let next = 1;
const pending = new Map();
const lines = createInterface({ input: child.stdout });
lines.on('line', line => {
  let message;
  try { message = JSON.parse(line); } catch { return; }
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  clearTimeout(request.timer);
  if (message.error) request.reject(new Error(message.error.message));
  else request.resolve(message.result);
});
child.stderr.on('data', chunk => process.stderr.write(chunk));
function request(method, params, timeout = 90000) {
  const id = next++;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('MCP timeout: ' + method)); }, timeout);
    pending.set(id, { resolve, reject, timer });
    child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  });
}
const results = [];
try {
  const initialized = await request('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'codex-ui-review', version: '1.0.0' } });
  console.log(JSON.stringify({ initialized: initialized.serverInfo }));
  child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} }) + '\n');
  for (const call of plan.calls) {
    const result = await request('tools/call', { name: call.name, arguments: call.arguments ?? {} });
    const value = result.structuredContent ?? result;
    results.push({ name: call.name, result: value });
    await fs.writeFile(path.join(output, 'mcp-results.json'), JSON.stringify(results, null, 2));
    console.log(JSON.stringify({ name: call.name, result: value }));
  }
} finally {
  child.stdin.end();
  child.kill();
}
