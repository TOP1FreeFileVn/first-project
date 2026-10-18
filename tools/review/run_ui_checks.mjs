import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';

const root = process.cwd();
const plan = JSON.parse(await fs.readFile('docs/ui_review/2026-10-19/capture-plan.json', 'utf8'));
const out = path.join(root, 'docs/ui_review/2026-10-19/test-results');
await fs.mkdir(out, { recursive: true });
const tests = process.argv.slice(2);
if (!tests.length) throw new Error('Provide test names: DeploymentTest, PinMeshTest, FishSkillTest, PopupCloseTest, SoundCheck, UiTapRoutingTest');
const allowed = new Set(['DeploymentTest', 'PinMeshTest', 'FishSkillTest', 'PopupCloseTest', 'SoundCheck', 'UiTapRoutingTest']);
const results = await Promise.all(tests.map(async name => {
  if (!allowed.has(name)) throw new Error('Unknown test: ' + name);
  const profile = path.join(out, 'profiles', name);
  await fs.mkdir(profile, { recursive: true });
  const scene = `res://tests/${name === 'DeploymentTest' ? 'ui_review/' : ''}${name}.tscn`;
  return await new Promise(resolve => {
    const child = spawn(plan.godot, ['--headless', '--path', root, scene], {
      cwd: root, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env, APPDATA: profile, LOCALAPPDATA: profile }
    });
    let log = '';
    let timedOut = false;
    const timer = setTimeout(() => { timedOut = true; child.kill(); }, 30000);
    child.stdout.on('data', chunk => { log += chunk; });
    child.stderr.on('data', chunk => { log += chunk; });
    child.on('error', error => { log += String(error); });
    child.on('close', async code => {
      clearTimeout(timer);
      await fs.writeFile(path.join(out, `${name}.log`), log);
      const passed = !timedOut && code === 0 && !/\bFAIL\b|SCRIPT ERROR|Parse Error/.test(log)
        && /PASS|0 failures|0 to check/.test(log);
      resolve({ name, code, timedOut, passed, summary: log.split(/\r?\n/).filter(line => /PASS|FAIL|checks|failures/.test(line)) });
    });
  });
}));
await fs.writeFile(path.join(out, 'latest-checks.json'), JSON.stringify(results, null, 2));
for (const result of results) console.log(JSON.stringify(result));
if (results.some(result => !result.passed)) process.exitCode = 1;
