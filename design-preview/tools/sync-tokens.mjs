// Tasarım değerlerini uygulamanın kendi kaynaklarından CSS'e çevirir.
// Kaynak: MagicPaper/Assets.xcassets/Colors (renkler) ve
// MagicPaper/DesignSystem/Pastel/MPLayout.swift (boşluk, köşe, ölçü).
// Elle kopya yok: Swift tarafı değişince `node design-preview/tools/sync-tokens.mjs`
// yeniden çalıştırılır ve taslaklar kendiliğinden güncellenir.
import { readFileSync, readdirSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const colorsDir = join(root, "MagicPaper", "Assets.xcassets", "Colors");
const layoutFile = join(root, "MagicPaper", "DesignSystem", "Pastel", "MPLayout.swift");

const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const channel = (v) => {
  v = String(v).trim();
  if (v.startsWith("0x")) return parseInt(v, 16);
  const n = parseFloat(v);
  return n <= 1 && !/^\d+$/.test(v) ? Math.round(n * 255) : Math.round(n);
};
const css = (c) => {
  const [r, g, b] = [c.red, c.green, c.blue].map(channel);
  const a = parseFloat(c.alpha ?? "1");
  const hex = "#" + [r, g, b].map((x) => x.toString(16).padStart(2, "0")).join("").toUpperCase();
  return a >= 1 ? hex : `rgba(${r}, ${g}, ${b}, ${a})`;
};

const light = [], dark = [];
for (const dir of readdirSync(colorsDir).filter((d) => d.endsWith(".colorset")).sort()) {
  const json = JSON.parse(readFileSync(join(colorsDir, dir, "Contents.json"), "utf8"));
  const name = `--mp-${kebab(dir.replace(".colorset", ""))}`;
  for (const entry of json.colors ?? []) {
    if (!entry.color?.components) continue;
    const isDark = (entry.appearances ?? []).some((a) => a.value === "dark");
    (isDark ? dark : light).push(`  ${name}: ${css(entry.color.components)};`);
  }
}

const layout = [];
if (existsSync(layoutFile)) {
  const src = readFileSync(layoutFile, "utf8");
  for (const block of src.matchAll(/enum (MP\w+) \{([\s\S]*?)\n\}/g)) {
    const prefix = { MPSpacing: "space", MPRadius: "radius", MPSize: "size" }[block[1]];
    if (!prefix) continue;
    for (const m of block[2].matchAll(/static let (\w+): CGFloat = ([\d.]+)/g)) {
      layout.push(`  --mp-${prefix}-${kebab(m[1])}: ${m[2]}px;`);
    }
  }
}

const out = `/* OTOMATİK ÜRETİLDİ: elle düzenleme. Kaynak: Assets.xcassets/Colors + MPLayout.swift.
   Yeniden üret: node design-preview/tools/sync-tokens.mjs  (${new Date().toISOString().slice(0, 10)}) */
:root {
${light.join("\n")}

${layout.join("\n")}
}
${dark.length ? `@media (prefers-color-scheme: dark) {\n  :root {\n${dark.map((l) => "  " + l).join("\n")}\n  }\n}\n` : "/* Koyu varyant yok: uygulama yalnızca açık görünümde (UIUserInterfaceStyle = Light). */\n"}`;

writeFileSync(join(here, "..", "tokens.css"), out);
console.log(`tokens.css: ${light.length} renk, ${dark.length} koyu varyant, ${layout.length} ölçü`);
