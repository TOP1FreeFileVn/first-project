import fs from 'node:fs/promises';
import path from 'node:path';

const output = path.resolve('docs/ui_review/2026-10-19/nav-footer-compact');
const read = async file => JSON.parse(await fs.readFile(file, 'utf8'));
const before = await read(path.join(output, 'before/manifest.json'));
const after = await read(path.join(output, 'manifest.json'));
const failures = [];
const checks = [];
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

for (const current of after.captures) {
  const previous = before.captures.find(capture => capture.file === current.file);
  if (!previous) {
    failures.push(`Missing baseline: ${current.file}`);
    continue;
  }
  const screenBottom = 1280;
  // The selected SVG begins at y=6 inside the cell, matching its unchanged rounded top.
  const visibleColoredHeight = screenBottom - current.selected_cell.design_rect[1] - 6;
  const beforeVisible = screenBottom - previous.footer.design_rect[1];
  const afterVisible = screenBottom - current.footer.design_rect[1];
  const ratio = afterVisible / visibleColoredHeight;
  const result = {
    file: current.file,
    icon_rect_unchanged: same(previous.selected_cell.icon.design_rect, current.selected_cell.icon.design_rect),
    cell_rects_unchanged: same(previous.cells.map(c => c.design_rect), current.cells.map(c => c.design_rect)),
    bar_rect_unchanged: same(previous.bar.design_rect, current.bar.design_rect),
    minimum_height_unchanged: previous.bar.minimum_size[1] === current.bar.minimum_size[1],
    footer_visible_before_design: beforeVisible,
    footer_visible_after_design: afterVisible,
    footer_visible_after_render: afterVisible * current.render_scale[1],
    footer_fraction_before: beforeVisible / visibleColoredHeight,
    footer_fraction_after: ratio,
    footer_fraction_target: ratio >= 0.25 && ratio <= 0.28,
    caption_size_unchanged: previous.caption.font_size === current.caption.font_size,
    caption_dark_and_unoutlined: current.caption.font_color === '583f21ff' && current.caption.outline_size === 0,
    caption_fits_width: current.caption.fits_width,
    caption_fully_visible: current.caption.design_rect[1] >= current.footer.design_rect[1]
      && current.caption.design_rect[1] + current.caption.design_rect[3] <= screenBottom,
    requested_size_rendered: same(current.requested, current.actual),
  };
  for (const [key, value] of Object.entries(result)) {
    if (typeof value === 'boolean' && !value) failures.push(`${current.file}: ${key}`);
  }
  checks.push(result);
}

if (after.captures.length !== 10) failures.push('Expected 10 captures');
if (after.routes.length !== 10 || after.routes.some(route => !route.passed)) failures.push('Expected 10 passing pointer routes');
if (after.persist !== false || before.persist !== false) failures.push('Player saves must remain disabled');
if (after.profile === before.profile) failures.push('Before and after must have separate profiles');
if (after.failures !== 0 || before.failures !== 0) failures.push('Capture fixture reported failures');

const result = { checks, pointer_routes: after.routes.length, profiles_isolated: after.profile !== before.profile,
  persisted: after.persist, failures };
await fs.writeFile(path.join(output, 'verification.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result, null, 2));
process.exitCode = failures.length ? 1 : 0;
