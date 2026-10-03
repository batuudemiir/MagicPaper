// Renders magicpaper-film.html frame-by-frame with Playwright and encodes an H.264 MP4.
// usage: node render.mjs [--lang tr|en] [--fps 60] [--stills 1,4.5,9] [--out file.mp4]
import { createRequire } from 'node:module';
import { execSync as _x } from 'node:child_process';
const require = createRequire(import.meta.url);
let pw; try { pw = require('playwright'); } catch { pw = require(_x('npm root -g').toString().trim() + '/playwright'); }
const { chromium } = pw;
import { spawn, execSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const args = Object.fromEntries(process.argv.slice(2).reduce((a, v, i, arr) => (v.startsWith('--') && a.push([v.slice(2), arr[i + 1]]), a), []));
const lang = args.lang || 'tr';
const fps = +(args.fps || 60);
const dir = path.dirname(fileURLToPath(import.meta.url));
const ffmpeg = process.env.FFMPEG || execSync(`python3 -c "import imageio_ffmpeg as f; print(f.get_ffmpeg_exe())"`).toString().trim();

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
await page.goto('file://' + path.join(dir, 'magicpaper-film.html') + '?lang=' + lang);
await page.evaluate(() => window.ready);
const duration = args.seconds ? +args.seconds : await page.evaluate(() => window.DURATION);

if (args.stills) {
  for (const t of args.stills.split(',').map(Number)) {
    await page.evaluate(t => window.render(t), t);
    await page.screenshot({ path: path.join(args.dir || dir, `still_${lang}_${t.toFixed(2)}.png`) });
  }
  await browser.close();
  process.exit(0);
}

const out = args.out || path.join(dir, `magicpaper-film-${lang}.mp4`);
const ff = spawn(ffmpeg, ['-y', '-f', 'image2pipe', '-framerate', String(fps), '-i', '-',
  '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out],
  { stdio: ['pipe', 'ignore', 'inherit'] });
const total = Math.round(duration * fps);
for (let f = 0; f < total; f++) {
  await page.evaluate(t => window.render(t), f / fps);
  const buf = await page.screenshot({ type: 'jpeg', quality: 96 });
  if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
  if (f % fps === 0) process.stderr.write(`\r${lang}: ${f}/${total}`);
}
ff.stdin.end();
await new Promise(r => ff.on('close', r));
await browser.close();
console.log('\nwrote', out);
