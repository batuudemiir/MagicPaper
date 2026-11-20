// Uygulamanın masal kataloğunu prototip verisine çevirir (elle kopya yok).
// Kaynak: MagicPaper/Screens/Gunluk/Model/classics_catalog.json ve
// Content/Originals/published/*/tale.json; kapaklar Assets.xcassets'ten.
// Çıktı: design-preview/app/content.js  (window.MP_CONTENT)
// Yeniden üret: node design-preview/tools/sync-content.mjs
import { readFileSync, readdirSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const assets = join(root, "MagicPaper", "Assets.xcassets");
const catalog = JSON.parse(readFileSync(join(root, "MagicPaper/Screens/Gunluk/Model/classics_catalog.json"), "utf8"));

// app/ klasörüne göre kapak yolu; görseli henüz olmayan kapak null (prototip yer tutucu çizer).
function coverPath(folder, name) {
  const dir = join(assets, folder, `${name}.imageset`);
  if (!existsSync(dir)) return null;
  const file = readdirSync(dir).find((f) => /\.(jpg|jpeg|png)$/i.test(f));
  return file ? `../../MagicPaper/Assets.xcassets/${folder}/${name}.imageset/${file}` : null;
}
const paras = (pages) => (pages || []).map((p) => p.split(/\n\n+/).map((s) => s.trim()).filter(Boolean));

const tales = catalog.tales.map((t) => ({
  id: t.id, slug: t.slug, title: t.title, byline: t.byline, ageMin: t.ageMin, ageMax: t.ageMax,
  minutes: t.minutes, summary: t.summary, shelves: t.shelves || [],
  cover: coverPath("Classics", t.cover), focus: t.coverFocus || { x: 0.5, y: 0.4 },
  credit: [t.attribution, t.coverCredit].filter(Boolean).join(" "),
  soft: paras(t.soft && t.soft.pages), classic: t.classic ? paras(t.classic.pages) : null,
  seriesID: t.seriesID || null, episode: t.episode || null,
}));
const series = catalog.series.map((s) => ({
  id: s.id, slug: s.slug, title: s.title, byline: s.byline, ageMin: s.ageMin, ageMax: s.ageMax,
  summary: s.summary, shelves: s.shelves || [], cover: coverPath("Classics", s.cover), focus: s.coverFocus || { x: 0.5, y: 0.4 },
  credit: [s.attribution, s.coverCredit].filter(Boolean).join(" "), unitName: s.unitName || "masal",
  episodes: tales.filter((t) => t.seriesID === s.id).sort((a, b) => a.episode - b.episode).map((t) => t.id),
}));

const pubDir = join(root, "Content", "Originals", "published");
const originals = existsSync(pubDir) ? readdirSync(pubDir).filter((d) => existsSync(join(pubDir, d, "tale.json"))).map((d) => {
  const t = JSON.parse(readFileSync(join(pubDir, d, "tale.json"), "utf8"));
  return { id: t.id, slug: t.slug, title: t.title, byline: "Original", ageMin: t.ageMin, ageMax: t.ageMax, minutes: t.minutes,
           summary: t.summary, mode: t.mode, shelves: ["orijinal"].concat(t.mode === "bedtime" ? ["uyku"] : []),
           cover: coverPath("Originals", `original-${t.slug}`), focus: { x: 0.5, y: 0.4 }, credit: "MagicPaper Original.",
           soft: paras(t.pages), classic: null, original: true };
}) : [];

const out = { generated: new Date().toISOString().slice(0, 10), featuredID: catalog.featuredID,
              weekly: (catalog.weeklyPicks && catalog.weeklyPicks.ids) || [], tales, series, originals };
writeFileSync(join(here, "..", "app", "content.js"),
  `// OTOMATİK ÜRETİLDİ: elle düzenleme. Kaynak: classics_catalog.json + Content/Originals.\n` +
  `// Yeniden üret: node design-preview/tools/sync-content.mjs\nwindow.MP_CONTENT = ${JSON.stringify(out)};\n`);
const noCover = tales.filter((t) => !t.cover && !t.seriesID).length + series.filter((s) => !s.cover).length;
console.log(`content.js: ${tales.length} masal (${tales.filter((t) => t.seriesID).length} seri bölümü), ${series.length} seri, ${originals.length} Original, kapaksız ${noCover}`);
