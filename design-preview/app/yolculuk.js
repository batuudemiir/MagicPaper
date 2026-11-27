// Menü ve "Okuma yolculuğum" (23 Kasım 2026, İrem; referans: alışkanlık
// uygulamasının tracker ekranı). Ana sayfanın menü düğmesi aşağıdan kayan bir
// sayfa açar; listede uygulamanın var olan sayfaları ve okuma yolculuğu.
// Kurallar (AGENTS.md ilke 7): seri sakin dille ("birlikte okudunuz"), okunmayan
// gün başarısızlık değil boş daire, "zayıf", "az kaldı", geri sayım ya da
// karşılaştırma yok. Yıldız katı asla düşmez; bir sonraki kata ilerleme gösterilmez.
"use strict";

P.list = '<line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/>';
P.map = '<path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/><path d="M15 5.764v15"/><path d="M9 3.236v15"/>';
P.palette = '<circle cx="13.5" cy="6.5" r=".5"/><circle cx="17.5" cy="10.5" r=".5"/><circle cx="8.5" cy="7.5" r=".5"/><circle cx="6.5" cy="12.5" r=".5"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>';
P.award = '<circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/>';
P.route = '<circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/>';

const JOURNEY_DAYS = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
const MENU_ITEMS = [
  ["route", "Okuma yolculuğum", "Haftan, yıldızların ve rozetlerin", "--mp-world-lav", 'data-act="journey"'],
  ["award", "Rozetlerim", "Okudukça açılan rozetler", "--mp-world-yellow", 'data-soon="Rozetlerim"'],
  ["sticker", "Çıkartma albümüm", "Her masaldan bir çıkartma", "--mp-world-pink", 'data-soon="Çıkartma albümü"'],
  ["type", "Yeni kelimelerim", "Masallarda öğrendiklerin", "--mp-world-mint", 'data-soon="Yeni kelimelerim"'],
  ["map", "Masal haritam", "Gezdiğin masal dünyaları", "--mp-world-sky", 'data-soon="Masal haritam"'],
  ["users", "Masal ailem", "Masallara katılan ailen", "--mp-world-peach", 'data-soon="Masal ailem"'],
  ["palette", "Kitaplık renklerim", "Yıldızlarınla süsle", "--mp-world-green", 'data-soon="Kitaplık renkleri"'],
];

Object.assign(S, { menuOpen: false, menuAnim: false });

function weekModel() {
  const now = new Date();
  const today = (now.getDay() + 6) % 7;
  const monday = new Date(now); monday.setDate(now.getDate() - today);
  const read = new Set([today - 2, today - 1, today].filter((d) => d >= 0));
  const minutes = JOURNEY_DAYS.map((_, i) => (read.has(i) ? [9, 14, 11, 8, 12, 15, 10][i] : 0));
  const dates = JOURNEY_DAYS.map((_, i) => { const d = new Date(monday); d.setDate(monday.getDate() + i); return d.getDate(); });
  return { today, read, minutes, dates, streak: read.size };
}

function menuSheet() {
  return `<div class="mn-scrim ${S.menuAnim ? "in" : ""}" data-act="menuClose" aria-hidden="true"></div>
    <div class="mn-sheet ${S.menuAnim ? "in" : ""}" role="dialog" aria-modal="true" aria-label="Menü">
      <span class="mn-grab" aria-hidden="true"></span>
      <div class="mn-head"><img src="${img.ragi("Waving")}" alt=""><span class="t-section">Nereye gidelim, ${CHILD}?</span>
        <button class="h2-circle" data-act="menuClose" aria-label="Kapat">${ic("x")}</button></div>
      <div class="h2-list">${MENU_ITEMS.map(([icon, title, sub, tone, act]) => `
        <button class="h2-row" ${act}><span class="tile" style="background:var(${tone}-soft);color:var(${tone}-deep)">${ic(icon)}</span>
          <span class="grow"><span class="t-card-title">${title}</span><span class="t-supporting secondary">${sub}</span></span>
          <span class="chev">${ic("right")}</span></button>`).join("")}</div>
      <button class="mn-grown" data-act="gate">${ic("lock")}Büyükler için</button>
    </div>`;
}

// Ana sayfa: menü düğmesi menüyü açar.
const homeWithoutMenu = VIEWS.home;
VIEWS.home = function () {
  const v = homeWithoutMenu();
  let html = v.html.replace('data-soon="Menü"', 'data-act="menuOpen"');
  if (S.menuOpen) html += menuSheet();
  return { ...v, html };
};

VIEWS.journey = function () {
  const w = weekModel();
  const max = Math.max(...w.minutes, 1);
  const days = JOURNEY_DAYS.map((d, i) => {
    const on = w.read.has(i), now = i === w.today, future = i > w.today;
    return `<span class="jr-day ${now ? "now" : ""}"><span class="lbl">${d}</span>
      <span class="dot ${on ? "on" : ""} ${future ? "future" : ""}">${on ? ic("check") : future ? w.dates[i] : ""}</span></span>`;
  }).join("");
  const bars = w.minutes.map((m, i) => `<span class="bar"><i style="height:${Math.max(8, (m / max) * 100)}%" class="${m ? "on" : ""}"></i><b>${JOURNEY_DAYS[i][0]}</b></span>`).join("");
  return { cls: "journey", html: `<div class="scroller">
    <div class="jr-hero">
      <div class="jr-top"><button class="h2-circle" data-act="journeyBack" aria-label="Geri">${ic("left")}</button>
        <h1>Okuma yolculuğum</h1></div>
      <div class="jr-card">
        <span class="jr-glow"><img src="${A}Brand/mascotCheer.imageset/mascotCheer.png" alt=""></span>
        <b class="jr-big">${w.streak} gün üst üste</b>
        <span class="t-supporting secondary">Birlikte okudunuz. Okuma yolculuğunuz devam ediyor.</span>
        <div class="jr-week">${days}</div>
        <span class="t-footnote secondary">${w.read.size ? `Bu hafta ${w.read.size} gün birlikte okudunuz` : "Bu hafta ilk masalı birlikte okuyalım"}</span>
      </div>
    </div>
    <div class="jr-two">
      <div class="jr-tile"><span class="t-card-title">Okuma zamanı</span><div class="jr-bars">${bars}</div>
        <span class="t-footnote secondary">Bu hafta ${w.minutes.reduce((a, b) => a + b, 0)} dakika</span></div>
      <div class="jr-tile center"><span class="jr-level">${ic("star")}</span><span class="t-card-title">Parlak yıldız</span>
        <span class="t-footnote secondary">${S.stars} yıldız</span></div>
    </div>
    <div class="jr-row"><span class="tile" style="background:var(--mp-world-mint-soft);color:var(--mp-world-mint-deep)">${ic("type")}</span>
      <span class="grow"><span class="t-card-title">Yeni kelimelerim</span>
        <span class="jr-words"><i>fener</i><i>usulca</i><i>pırıltı</i></span></span>
      <span class="jr-count">3 kelime</span></div>
    <div class="jr-row"><span class="tile" style="background:var(--mp-world-yellow-soft);color:var(--mp-world-yellow-deep)">${ic("award")}</span>
      <span class="grow"><span class="t-card-title">Son rozetim: İlk masal</span>
        <span class="t-supporting secondary">Okudukça yenileri açılır.</span></span></div>
  </div>` };
};

Object.assign(ACTIONS, {
  menuOpen: () => { S.menuOpen = true; S.menuAnim = true; render(); S.menuAnim = false; },
  menuClose: () => {
    const sheet = app.querySelector(".mn-sheet");
    if (sheet && !matchMedia("(prefers-reduced-motion: reduce)").matches) {
      sheet.classList.add("out"); app.querySelector(".mn-scrim")?.classList.add("out");
      setTimeout(() => { S.menuOpen = false; render(); }, 200);
    } else { S.menuOpen = false; render(); }
  },
  journey: () => { S.menuOpen = false; push({ view: "journey" }); },
  journeyBack: () => back(),
});

// ?ekran=home&menu=ac · ?yolculuk=ac
if (Q.get("menu") === "ac") Object.assign(S, { menuOpen: true, menuAnim: true });
if (Q.get("yolculuk") === "ac") S.stack.push({ view: "journey" });
