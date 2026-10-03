#!/usr/bin/env node
// MagicPaper "Görselli Hikaye" tanıtım videosu render'ı.
//
//   node render.js tr                     → out/magicpaper_gorselli-hikaye_tr.mp4
//   node render.js en out/video.mp4       → belirtilen dosya
//   node render.js tr 1.5,4.2,9           → yalnız bu saniyelerin PNG'leri (out/preview/)
//
// Sayfa yerel bir HTTP sunucusundan açılır, fontlar beklenir, her kare için
// draw(i / FPS) çalıştırılır ve canvas PNG'si ffmpeg'e image2pipe ile akıtılır.
'use strict';
const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn, execSync } = require('child_process');

function loadPlaywright() {
  try { return require('playwright'); } catch (_) { /* global kurulum dene */ }
  const root = execSync('npm root -g').toString().trim();
  return require(path.join(root, 'playwright'));
}

function findFfmpeg() {
  if (process.env.FFMPEG) return process.env.FFMPEG;
  try { execSync('ffmpeg -version', { stdio: 'ignore' }); return 'ffmpeg'; } catch (_) { /* yok */ }
  try {
    return execSync('python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"').toString().trim();
  } catch (_) {
    throw new Error('ffmpeg bulunamadı. `pip install imageio-ffmpeg` kurun ya da FFMPEG ortam değişkenini verin.');
  }
}

const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.woff2': 'font/woff2' };
function serve(dir) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname).replace(/^\/+/, '') || 'index.html';
      const file = path.join(dir, rel);
      if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
      res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

async function main() {
  const args = process.argv.slice(2);
  const lang = args[0] === 'en' ? 'en' : 'tr';
  const last = args[args.length - 1];
  const seconds = args.length > 1 && /^[\d.,]+$/.test(last) ? last.split(',').filter(Boolean).map(Number) : null;
  const dir = __dirname;
  const outDir = path.join(dir, 'out');
  const outFile = !seconds && args[1] ? path.resolve(args[1]) : path.join(outDir, `magicpaper_gorselli-hikaye_${lang}.mp4`);

  for (const f of ['pixelify-sans-latin-400-normal.woff2', 'pixelify-sans-latin-ext-700-normal.woff2']) {
    if (!fs.existsSync(path.join(dir, 'fonts', f))) throw new Error(`fonts/${f} yok. README'deki font adımını çalıştırın.`);
  }

  const server = await serve(dir);
  const url = `http://127.0.0.1:${server.address().port}/index.html?lang=${lang}`;
  const { chromium } = loadPlaywright();
  const launch = {};
  if (fs.existsSync('/opt/pw-browsers/chromium')) launch.executablePath = '/opt/pw-browsers/chromium';
  let browser;
  try { browser = await chromium.launch(); } catch (_) { browser = await chromium.launch(launch); }
  const page = await browser.newPage({ viewport: { width: 400, height: 700 } });
  await page.goto(url);
  await page.evaluate(() => window.ready);
  const { duration, fps } = await page.evaluate(() => ({ duration: window.DURATION, fps: window.FPS }));

  const grab = (t) => page.evaluate((tt) => {
    window.draw(tt);
    return document.getElementById('c').toDataURL('image/png').split(',')[1];
  }, t);

  if (seconds) {
    const pdir = path.join(outDir, 'preview');
    fs.mkdirSync(pdir, { recursive: true });
    for (const s of seconds) {
      const f = path.join(pdir, `${lang}_${s.toFixed(2)}.png`);
      fs.writeFileSync(f, Buffer.from(await grab(s), 'base64'));
      console.log(f);
    }
  } else {
    fs.mkdirSync(path.dirname(outFile), { recursive: true });
    const ff = spawn(findFfmpeg(), [
      '-y', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'png', '-i', '-',
      '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-preset', 'slow',
      '-movflags', '+faststart', '-r', String(fps), outFile,
    ], { stdio: ['pipe', 'inherit', 'inherit'] });
    const done = new Promise((res, rej) => ff.on('close', (c) => (c === 0 ? res() : rej(new Error(`ffmpeg ${c}`)))));
    const frames = Math.round(duration * fps);
    for (let i = 0; i < frames; i++) {
      const buf = Buffer.from(await grab(i / fps), 'base64');
      if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
      if (i % 60 === 0) process.stderr.write(`kare ${i}/${frames}\n`);
    }
    ff.stdin.end();
    await done;
    console.log(outFile);
  }
  await browser.close();
  server.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
