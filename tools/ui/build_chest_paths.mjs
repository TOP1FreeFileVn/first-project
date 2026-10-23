// Compatibility entry point: the selected B artwork is raster, not native paths.
// Regenerate its source-preserving layers, then publish the generic reward icons.
// node tools/ui/build_chest_paths.mjs
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
const root = process.cwd();
const build = spawnSync('python', [path.join(root, 'tools/ui/build_strongbox_chests.py')], {
  cwd: root, stdio: 'inherit', windowsHide: true,
});
if (build.error) throw build.error;
if (build.status !== 0) process.exit(build.status ?? 1);
const assets = path.join(root, 'game/ui/art/chests/strongbox-b/wood');
for (const size of [128, 96, 64, 48, 32]) {
  const filename = size === 128 ? 'icon_chest.png' : `icon_chest_${size}.png`;
  const target = path.join(root, 'game/ui/art', filename);
  fs.copyFileSync(path.join(assets, `icon_${size}.png`), target);
  console.log(`Published ${path.relative(root, target)}`);
}