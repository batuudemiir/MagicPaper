// MagicPaper gezilebilir prototip (19 Kasım 2026, İrem + Claude).
// Ekranlar gerçek uygulamanın ekran görüntülerine (../screens/real) ve SwiftUI
// kodundaki metinlere dayanır. Prototipte olmayan bir yere dokunulunca dürüstçe
// "prototipte henüz yok" denir. Masal metni örnektir, motordan gelmez.
"use strict";

// ---------- Ayarlar (önizleyiciden ?yazi=buyuk&cihaz=se) ----------
const Q = new URLSearchParams(location.search);
if (Q.get("yazi") === "buyuk") document.documentElement.style.setProperty("--type", "1.75");
if (Q.get("cihaz") === "se") document.documentElement.style.setProperty("--status", "20px");

const A = "../../MagicPaper/Assets.xcassets/";
const img = {
  night: A + "Scenes/homeSceneNight.imageset/homeSceneNight.jpg",
  ragi: (p) => A + `Brand/mascot${p}.imageset/mascot${p}.png`,
  classic: (id) => A + `Classics/classic-${id}.imageset/classic-${id}.jpg`,
  original: (id) => A + `Originals/original-${id}.imageset/original-${id}.jpg`,
};

// ---------- İkonlar (Lucide, ISC) ----------
const P = {
  home: '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  book: '<path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>',
  library: '<path d="m16 6 4 14"/><path d="M12 6v14"/><path d="M8 8v12"/><path d="M4 4v16"/>',
  profile: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="10" r="3"/><path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662"/>',
  wand: '<path d="m21.64 3.64-1.28-1.28a1.21 1.21 0 0 0-1.72 0L2.36 18.64a1.21 1.21 0 0 0 0 1.72l1.28 1.28a1.2 1.2 0 0 0 1.72 0L21.64 5.36a1.2 1.2 0 0 0 0-1.72"/><path d="m14 7 3 3"/><path d="M5 6v4"/><path d="M19 14v4"/><path d="M10 2v2"/><path d="M7 8H3"/><path d="M21 16h-4"/><path d="M11 3H9"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>',
  sparkles: '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>',
  tent: '<path d="M3.5 21 14 3"/><path d="M20.5 21 10 3"/><path d="M15.5 21 12 15l-3.5 6"/><path d="M2 21h20"/>',
  play: '<polygon points="6 3 20 12 6 21 6 3"/>',
  left: '<path d="m15 18-6-6 6-6"/>', right: '<path d="m9 18 6-6-6-6"/>', down: '<path d="m6 9 6 6 6-6"/>',
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  heart: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
  type: '<polyline points="4 7 4 4 20 4 20 7"/><line x1="9" x2="15" y1="20" y2="20"/><line x1="12" x2="12" y1="4" y2="20"/>',
  clock: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  flame: '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>',
  star: '<path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  crown: '<path d="M11.562 3.266a.5.5 0 0 1 .876 0L15.39 8.87a1 1 0 0 0 1.516.294L21.183 5.5a.5.5 0 0 1 .798.519l-2.834 10.246a1 1 0 0 1-.956.734H5.81a1 1 0 0 1-.957-.734L2.02 6.02a.5.5 0 0 1 .798-.519l4.276 3.664a1 1 0 0 0 1.516-.294z"/><path d="M5 21h14"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  bell: '<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  volume: '<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>',
  hand: '<path d="M18 11V6a2 2 0 0 0-2-2a2 2 0 0 0-2 2"/><path d="M14 10V4a2 2 0 0 0-2-2a2 2 0 0 0-2 2v2"/><path d="M10 10.5V6a2 2 0 0 0-2-2a2 2 0 0 0-2 2v8"/><path d="M18 8a2 2 0 1 1 4 0v6a8 8 0 0 1-8 8h-2c-2.8 0-4.5-.86-5.99-2.34l-3.6-3.6a2 2 0 0 1 2.83-2.82L7 15"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  sticker: '<path d="M15.5 3H5a2 2 0 0 0-2 2v14c0 1.1.9 2 2 2h14a2 2 0 0 0 2-2V8.5L15.5 3Z"/><path d="M15 3v6h6"/>',
  flag: '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/>',
};
const ic = (n, cls = "") => `<svg class="ico ${cls}" viewBox="0 0 24 24" aria-hidden="true">${P[n] || ""}</svg>`;
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

// ---------- Örnek veri (DEBUG -mpDemo -mpDemoLibrary ile aynı çocuk ve kitaplık) ----------
let CHILD = "İrem";
const MODES = {
  bedtime: { title: "Uyku öncesi", promise: "Günü sakin bir hikâyeyle kapatalım.", icon: "moon", soft: "--mp-world-lav-soft", deep: "--mp-world-lav-deep", short: "Uyku" },
  learning: { title: "Yeni şeyler öğrenelim", promise: "Yeni bir şey keşfedelim.", icon: "sparkles", soft: "--mp-world-yellow-soft", deep: "--mp-world-yellow-deep", short: "Öğrenelim" },
  adventure: { title: "Maceraya çıkalım", promise: "Birlikte bir maceraya çıkalım.", icon: "tent", soft: "--mp-world-green-soft", deep: "--mp-world-green-deep", short: "Macera" },
};
const CLASSICS = [
  { id: "rapunzel", title: "Rapunzel", meta: "Grimm · 9 dk · 5-7 yaş", half: true },
  { id: "pamuk-prenses", title: "Pamuk Prenses", meta: "Grimm · 11 dk · 5-7 yaş", half: true },
  { id: "kirmizi-baslikli-kiz", title: "Kırmızı Başlıklı Kız", meta: "Perrault · 7 dk · 4-6 yaş", half: true },
  { id: "kulkedisi", title: "Külkedisi", meta: "Perrault · 10 dk · 5-7 yaş" },
  { id: "hansel-ile-gretel", title: "Hansel ile Gretel", meta: "Grimm · 10 dk · 5-7 yaş" },
  { id: "bremen-mizikacilari", title: "Bremen Mızıkacıları", meta: "Grimm · 8 dk · 4-6 yaş" },
  { id: "zumruduanka", title: "Zümrüdüanka", meta: "Anadolu · 12 dk · 6-8 yaş" },
];
const ORIGINALS = [
  { id: "kirmizi-atkidaki-kar-tanesi", title: "Kırmızı Atkıdaki Kar Tanesi", meta: "Original · 6 dk" },
  { id: "saatin-icindeki-ninni", title: "Saatin İçindeki Ninni", meta: "Original · 9 dk" },
];
const S = {
  tab: "home", stack: [], modal: null, stars: 1, finished: 0, libFilter: "all",
  library: [
    { title: "İrem ve Uykucu Ay", mode: "bedtime", half: true, when: "Bugün" },
    { title: "Arıların Gizli Dili", mode: "learning", half: true, when: "Bugün" },
    { title: "Yıldız Toplayan Kedi", mode: "bedtime", when: "Dün" },
    { title: "Bulutların Ninnisi", mode: "bedtime", when: "2 gün önce" },
    { title: "Yıldızlar Neden Parlar?", mode: "learning", when: "3 gün önce" },
    { title: "Ormandaki Gizli Yol", mode: "adventure", when: "5 gün önce" },
    { title: "Denizaltı Dostları", mode: "adventure", when: "6 gün önce" },
    { title: "Dinozor Vadisi", mode: "adventure", when: "7 gün önce" },
  ],
};
const COMPANIONS = ["kaplumbağa", "baykuş", "ejderha", "kelebek", "köpek", "balık", "kertenkele", "tilki"];
const FAMILY = ["Anneanne", "Kardeşi Can", "Kedisi Pamuk"];
const TOPICS = {
  bedtime: ["Ay ve yıldızlar", "Sessiz orman", "Bulut evi"],
  learning: ["Arılar", "Gökyüzü", "Meslekler", "Deniz canlıları"],
  adventure: ["Orman", "Uzay", "Deniz", "Dinozorlar"],
};
// Örnek metin: motor çıktısı değil, prototip için yazıldı.
const sampleStory = (title, companion) => [
  `Akşam olmuştu. <b class="hero">${CHILD}</b> pencerenin önüne oturdu ve gökyüzüne baktı.`,
  `Bahçeden küçük bir ses geldi: pıt pıt pıt. Çitin dibinde bir ${companion} duruyordu.`,
  `"Yolumu kaybettim," dedi ${companion} usulca. "Evim ayın tam altında."`,
  `<b class="hero">${CHILD}</b> fenerini aldı. İkisi birlikte ay ışığını izleyerek yürüdüler.`,
  `Ay, en parlak hâliyle küçük bir tepeyi aydınlatıyordu. "İşte evim!" dedi ${companion}.`,
  `<b class="hero">${CHILD}</b> gülümsedi, fenerini söndürdü ve yavaşça evine döndü. Yıldızlar ona göz kırpıyordu.`,
];

// ---------- Gezinme ----------
const app = document.getElementById("app");
function toast(msg) {
  document.querySelectorAll(".toast").forEach((t) => t.remove());
  const t = document.createElement("div"); t.className = "toast"; t.textContent = msg; app.appendChild(t);
  setTimeout(() => t.remove(), 2200);
}
const notYet = (what) => toast(`${what}: prototipte henüz yok`);
function go(tab) { S.tab = tab; S.stack = []; render("fade"); }
function push(view) { S.stack.push(view); render("push"); }
function back() { S.stack.pop(); render("fade"); }
function open(modal) { S.modal = modal; render("cover"); }
function close() { S.modal = null; render("fade"); }
window.MP = { go, push, back, open, close, toast, notYet, S };

function render(anim) {
  clearTimers();
  if (S.os === "home") { app.innerHTML = OS.springboard(); OS.bindHome(); return; }
  if (!S.onboarded) {
    const v = OS.ob[S.ob](); const c = anim === "push" ? "push-in" : anim === "launch" ? "launch-in" : anim === "fade" ? "fade-in" : "";
    app.innerHTML = `<div class="layer ${v.cls || ""} ${c}">${statusbar()}${v.html}</div>${OS.homeIndicator()}`;
    bind(); (OS.after[S.ob] || (() => {}))(); return;
  }
  let html, cls = "", parent = false, extra = "";
  if (S.modal) {
    const m = S.modal;
    const v = VIEWS[m.view](m);
    html = v.html; parent = v.parent; extra = v.cls || ""; cls = anim === "cover" ? "cover-in" : anim === "push" ? "push-in" : "";
  } else if (S.stack.length) {
    const v = S.stack[S.stack.length - 1];
    html = VIEWS[v.view](v).html + tabbar(); cls = anim === "push" ? "push-in" : "";
  } else {
    html = VIEWS[S.tab]().html + tabbar(); cls = anim === "fade" ? "fade-in" : "";
  }
  app.innerHTML = `<div class="layer ${parent ? "parent" : ""} ${extra} ${cls === "" && anim === "launch" ? "launch-in" : cls}">${statusbar()}${html}</div>${OS.homeIndicator()}`;
  bind();
  (VIEWS.after[S.modal ? S.modal.view : ""] || (() => {}))(S.modal);
}
const statusbar = () => `<div class="statusbar"><span>9:41</span><span>●●● ▮</span></div>`;
function tabbar() {
  const t = [["home", "home", "Ana sayfa"], ["masallar", "book", "Masallar"], ["kitaplik", "library", "Kitaplık"], ["profil", "profile", "Profil"]];
  return `<nav class="tabbar" aria-label="Sekmeler"><div class="tabs">${t.map(([id, i, l]) =>
    `<button data-go="${id}" class="${S.tab === id ? "on" : ""}" aria-label="${l}">${ic(i)}<span>${l}</span></button>`).join("")}</div>
    <button class="fab" data-act="create" aria-label="Masal yaz">${ic("wand")}</button></nav>`;
}
// data-* bağlama: data-go (sekme), data-act (eylem), data-push (sayfa), data-arg
function bind() {
  app.querySelectorAll("[data-go]").forEach((b) => b.onclick = () => go(b.dataset.go));
  app.querySelectorAll("[data-act]").forEach((b) => b.onclick = (e) => { e.stopPropagation(); ACTIONS[b.dataset.act](b.dataset.arg, b); });
  app.querySelectorAll("[data-soon]").forEach((b) => b.onclick = () => notYet(b.dataset.soon));
}
let timers = [];
const later = (fn, ms) => timers.push(setTimeout(fn, ms));
const clearTimers = () => { timers.forEach(clearTimeout); timers = []; };

// ---------- Eylemler ----------
const ACTIONS = {
  create: () => open({ view: "createMode" }),
  surprise: () => { const k = Object.keys(MODES); startPrep(k[Math.floor(Math.random() * k.length)], {}); },
  mode: (m) => { S.modal = { view: "createWho", mode: m, comp: null, fam: [], topic: null }; render("push"); },
  pickComp: (v) => { S.modal.comp = S.modal.comp === v ? null : v; render(); },
  pickFam: (v) => { const f = S.modal.fam; f.includes(v) ? f.splice(f.indexOf(v), 1) : f.push(v); render(); },
  pickTopic: (v) => { S.modal.topic = S.modal.topic === v ? null : v; render(); },
  write: () => startPrep(S.modal.mode, S.modal),
  createBack: () => { S.modal = { view: "createMode" }; render("fade"); },
  close: () => close(),
  openStory: (title) => openReader(title),
  openClassic: (id) => { const c = CLASSICS.find((x) => x.id === id) || ORIGINALS.find((x) => x.id === id); openReader(c.title, c); },
  readerNext: () => { const m = S.modal; if (m.page < m.pages.length) { m.page++; render(); } },
  readerPrev: () => { const m = S.modal; if (m.page > 0) { m.page--; render(); } },
  finish: () => { S.stars++; S.finished++; S.modal.view = "ending"; render("fade"); },
  again: () => open({ view: "createMode" }),
  goodnight: () => { close(); go("home"); },
  libFilter: (f) => { S.libFilter = f; render(); },
  gate: () => open({ view: "gate" }),
  kidMode: () => { close(); go("profil"); },
  parentPush: (v) => { S.modal = { view: v, from: S.modal }; render("push"); },
  parentBack: () => { S.modal = S.modal.from || { view: "parent" }; render("fade"); },
  paywall: () => { S.modal = { view: "paywall", from: S.modal, plans: false }; render("cover"); },
  showPlans: () => { S.modal.plans = !S.modal.plans; render(); },
  paywallClose: () => { S.modal = S.modal.from; render("fade"); },
  toggle: (_, el) => el.classList.toggle("on"),
};
function startPrep(mode, pick) {
  const comp = pick.comp || COMPANIONS[Math.floor(Math.random() * COMPANIONS.length)];
  S.modal = { view: "prep", mode, comp, fam: pick.fam || [], topic: pick.topic, step: 0, title: titleFor(mode, comp) };
  render("fade");
}
function titleFor(mode, comp) {
  const C = comp.charAt(0).toLocaleUpperCase("tr") + comp.slice(1);
  return { bedtime: `${CHILD} ve Uykucu ${C}`, learning: `${C} Neyi Merak Etti?`, adventure: `${CHILD} ile ${C}'nın Yolu` }[mode];
}
function openReader(title, classic) {
  const own = S.library.find((s) => s.title === title);
  open({ view: "reader", title, classic, mode: own ? own.mode : "bedtime", page: 0, pages: sampleStory(title, "kaplumbağa") });
}

// ---------- Ekranlar ----------
const VIEWS = {
  after: {},
  home() {
    const night = true;
    return { html: `<div class="scroller">
      <div class="tab-head"><h1>${CHILD}</h1></div>
      <div class="tonight">
        <div class="art" style="background-image:url(${img.night})"><img src="${img.ragi("Sleeping")}" alt=""></div>
        <div class="body">
          <span class="t-footnote" style="color:var(--mp-action-primary)">Saat 20.30</span>
          <span class="t-section">Uyku masalı zamanı</span>
          <span class="t-supporting secondary">Kısa, sakin bir masalla günü kapatalım.</span>
          <button class="btn btn-primary" data-act="mode" data-arg="bedtime">Uyku masalı yaz</button>
        </div>
      </div>
      <div class="section-h"><h2>Yeni bir masal yaz</h2></div>
      <div class="modes" style="margin-top:14px">${Object.entries(MODES).map(([k, m]) => `
        <button class="mode ${k === "bedtime" && night ? "on" : ""}" style="background:var(${m.soft})" data-act="createModeDirect" data-arg="${k}">
          ${k === "bedtime" && night ? '<span class="flag">Bu akşam</span>' : ""}
          <span class="tile" style="color:var(${m.deep})">${ic(m.icon)}</span>${m.title}</button>`).join("")}</div>
      ${S.library.some((s) => s.half) ? `<div class="section-h"><h2>Kaldığın yerden</h2></div>
      <button class="card resume" data-act="openStory" data-arg="${esc(S.library.find((s) => s.half).title)}">
        <div class="cv made" style="width:64px;aspect-ratio:3/4;border-radius:8px;font-size:11px;background:var(${MODES[S.library.find((s) => s.half).mode].soft})"></div>
        <div class="grow"><span class="t-card-title">${esc(S.library.find((s) => s.half).title)}</span><span class="t-supporting secondary">Sayfa 3 / 6</span></div>
        <span class="round-play">${ic("play")}</span></button>` : ""}
    </div>` };
  },
  masallar() {
    const c = CLASSICS[0];
    return { html: `<div class="scroller">
      <div class="tab-head"><h1>Masallar</h1><button class="circle" data-soon="Masal arama" aria-label="Masal ara">${ic("search")}</button></div>
      <div class="chips">
        <button class="chip" style="background:var(--mp-world-gray-soft)" data-soon="Tüm raflar">${ic("grid")}Tüm raflar</button>
        <button class="chip" data-soon="Klasikler rafı">${ic("crown")}Klasikler</button>
        <button class="chip" style="background:var(--mp-world-peach-soft)" data-soon="Anadolu rafı">Anadolu</button>
        <button class="chip" style="background:var(--mp-world-mint-soft)" data-soon="Fabl rafı">${ic("sparkles")}Fabllar</button>
      </div>
      <div class="card feature">
        <img src="${img.classic(c.id)}" alt="">
        <div class="meta"><span class="t-eyebrow" style="color:var(--mp-action-primary)">Kaldığın yerden</span>
          <span class="t-section" style="font-weight:700">${c.title}</span><span class="t-supporting secondary">${c.meta}</span>
          <button class="pill-btn" data-act="openClassic" data-arg="${c.id}">${ic("play")}Devam et</button></div>
      </div>
      <div class="dots"><i class="on"></i><i></i><i></i><i></i><i></i></div>
      <div class="section-h"><h2>MagicPaper Original</h2><button class="link" data-soon="Original rafı">Tümü ${ic("right")}</button></div>
      <p class="t-supporting secondary section-sub">Yalnızca burada okunan masallar</p>
      <div class="shelf">${ORIGINALS.map((o) => `<button class="book" style="width:180px" data-act="openClassic" data-arg="${o.id}">
        <div class="cv" style="background-image:url(${img.original(o.id)})"></div>
        <div class="t t-body">${o.title}</div><div class="t-footnote secondary" style="font-weight:400">${o.meta}</div></button>`).join("")}</div>
      <div class="section-h"><h2>Bu haftanın seçkisi</h2></div>
      <p class="t-supporting secondary section-sub">Editörün bu hafta için seçtikleri</p>
      <div class="shelf">${CLASSICS.slice(3).map((o) => `<button class="book" data-act="openClassic" data-arg="${o.id}">
        <div class="cv" style="background-image:url(${img.classic(o.id)})"></div>
        <div class="t t-body">${o.title}</div><div class="t-footnote secondary" style="font-weight:400">${o.meta}</div></button>`).join("")}</div>
    </div>` };
  },
  kitaplik() {
    const f = S.libFilter;
    const own = S.library.filter((s) => f === "all" || s.mode === f);
    const cls = f === "all" || f === "classic" ? CLASSICS.filter((c) => c.half) : [];
    const items = f === "classic" ? [] : own;
    const count = cls.length + items.length;
    const filters = [["all", "Tümü"], ["bedtime", "Uyku"], ["learning", "Öğrenelim"], ["adventure", "Macera"], ["classic", "Klasikler"]];
    return { html: `<div class="scroller">
      <div class="tab-head"><h1>Kitaplık</h1><button class="circle" data-soon="Kitaplıkta arama" aria-label="Kitaplıkta ara">${ic("search")}</button></div>
      <div class="say"><img src="${img.ragi("Reading")}" alt=""><div class="bubble t-body">${S.library.length} masalın, 3 klasik burada.</div></div>
      <button class="card resume" data-act="openClassic" data-arg="rapunzel"><img src="${img.classic("rapunzel")}" alt="">
        <div class="grow"><span class="t-footnote" style="color:var(--mp-action-primary)">Kaldığın yerden</span><span class="t-card-title">Rapunzel</span><span class="t-supporting secondary">Okumaya başladın</span></div>
        <span class="round-play">${ic("play")}</span></button>
      <div class="chips">${filters.map(([k, l]) => `<button class="chip ${f === k ? "dark" : ""}" data-act="libFilter" data-arg="${k}">${l}</button>`).join("")}</div>
      <div class="section-h" style="margin-top:20px"><span class="t-card-title secondary">${count} kitap</span><button class="link" data-soon="Sıralama">Son okunan ${ic("down")}</button></div>
      <div class="grid3" style="margin-top:12px">
        ${cls.map((c) => `<button class="book" data-act="openClassic" data-arg="${c.id}"><div class="cv" style="background-image:url(${img.classic(c.id)})"><span class="badge">◔ Yarım</span></div>
          <div class="t t-card-title" style="font-size:calc(15px * var(--type))">${c.title}</div><div class="t-footnote secondary" style="font-weight:400">Klasik · Bugün</div></button>`).join("")}
        ${items.map((s) => { const m = MODES[s.mode]; return `<button class="book" data-act="openStory" data-arg="${esc(s.title)}">
          <div class="cv made" style="background:var(${m.soft});color:var(${m.deep})"><span class="mode-ico">${ic(m.icon)}</span>${s.half ? '<span class="badge">◔ Yarım</span>' : ""}${esc(s.title)}</div>
          <div class="t t-card-title" style="font-size:calc(15px * var(--type))">${esc(s.title)}</div><div class="t-footnote secondary" style="font-weight:400">${m.short} · ${s.when}</div></button>`; }).join("")}
      </div>
    </div>` };
  },
  profil() {
    return { html: `<div class="scroller">
      <div class="tab-head"><h1>Profil</h1></div>
      <div class="who"><button class="me" aria-label="İrem, seçili"><span class="av">İ</span>İrem ${ic("check")}</button>
        <button class="add" data-act="gate">${ic("plus")}Ekle</button></div>
      <div class="card hero-card">${bust()}
        <div style="display:grid;gap:6px"><span class="t-page">${CHILD}</span>
          <span class="t-supporting" style="display:flex;gap:6px;align-items:center"><span style="color:var(--mp-brand-star)">★</span> ${S.stars} yıldız</span>
          <button class="pill-btn" style="margin:0" data-soon="Kahraman dolabı">${ic("sparkles")}Kahramanını giydir</button></div></div>
      <div class="say"><img src="${img.ragi("Waving")}" alt=""><div class="bubble t-body">Masal okudukça rozetlerin burada toplanır.</div></div>
      <button class="card row-card" data-act="gate"><span class="tile" style="background:var(--mp-world-sky-soft);color:var(--mp-world-sky-deep)">${ic("users")}</span>
        <span class="grow"><span class="t-card-title">Büyükler için</span><span class="t-supporting secondary">Ayarlar, abonelik ve okuma özeti</span></span><span class="chev">${ic("right")}</span></button>
      <div class="section-h"><h2>Masal dünyam</h2></div>
      <button class="card row-card" style="background:var(--mp-world-yellow-soft)" data-soon="Çıkartma albümü"><span class="grow"><span class="t-card-title">Çıkartma albümüm</span><span class="t-supporting secondary">${S.finished} çıkartma</span></span>${ic("sticker")}</button>
      <button class="card row-card" data-soon="Rozetlerim"><span class="grow"><span class="t-card-title">Rozetlerim</span><span class="t-supporting secondary">${S.finished ? 1 : 0} / 69</span></span><span class="chev">${ic("right")}</span></button>
    </div>` };
  },

  // --- Masal yazma (tam ekran örtü) ---
  createMode() {
    return { html: `<div class="topbar"><button class="circle" data-act="close" aria-label="Kapat">${ic("x")}</button><span></span></div>
      <div class="scroller" style="padding-bottom:40px">
        <div class="t-page" style="margin-top:4px">${CHILD} için nasıl bir masal?</div>
        <p class="t-body secondary" style="margin:6px 0 22px">Birini seç, gerisini biz hazırlayalım.</p>
        <p class="t-supporting" style="margin:-12px 0 18px;color:var(--mp-action-primary)">Bu akşam için önerimiz: Uyku öncesi.</p>
        ${Object.entries(MODES).map(([k, m]) => `<button class="choice ${k === "bedtime" ? "on" : ""}" data-act="mode" data-arg="${k}">
          <span class="tile" style="background:var(${m.soft});color:var(${m.deep})">${ic(m.icon)}</span>
          <span class="grow"><span class="t-card-title">${m.title}</span><span class="t-supporting secondary">${m.promise}</span></span></button>`).join("")}
        <button class="btn btn-ghost" data-act="surprise">${ic("wand")}Bana sürpriz yap</button>
        <div class="say"><img src="${img.ragi("Pencil")}" alt="" style="width:72px"><div class="bubble t-body">Sen seç, masalı birlikte yazalım!</div></div>
      </div>` };
  },
  createWho(m) {
    const mode = MODES[m.mode];
    const topicQ = { bedtime: "Masal neyle ilgili olsun?", learning: "Neyi öğrenelim?", adventure: "Nereye gidelim?" }[m.mode];
    return { html: `<div class="topbar"><button class="circle" data-act="createBack" aria-label="Geri">${ic("left")}</button><span class="t-footnote secondary">${mode.title}</span></div>
      <div class="scroller" style="padding-bottom:30px">
        <div class="t-page">Masalda kimler olsun?</div>
        <p class="t-body secondary" style="margin:6px 0 18px">İstersen seç, istersen bize bırak.</p>
        <div class="pick">${COMPANIONS.map((c) => `<button class="chip ${m.comp === c ? "on" : ""}" data-act="pickComp" data-arg="${c}">${c}</button>`).join("")}</div>
        <div class="t-card-title" style="margin:26px 0 10px">Masal ailemden biri de gelsin mi?</div>
        <div class="pick">${FAMILY.map((c) => `<button class="chip ${m.fam.includes(c) ? "on" : ""}" data-act="pickFam" data-arg="${c}">${ic("heart")}${c}</button>`).join("")}</div>
        <div class="t-card-title" style="margin:26px 0 10px">${topicQ}</div>
        <div class="pick">${TOPICS[m.mode].map((c) => `<button class="chip ${m.topic === c ? "on" : ""}" data-act="pickTopic" data-arg="${c}">${c}</button>`).join("")}</div>
      </div>
      <div class="footer-cta"><button class="btn btn-primary" data-act="write">Masalı yaz</button>
        <p class="t-footnote secondary center" style="margin:4px 0 0;font-weight:400">Seçmezsen en uygun arkadaşı biz seçeriz.</p></div>` };
  },
  prep(m) {
    const lines = [
      ["Yaşına uygun kelimeler", "check"],
      [m.mode === "bedtime" ? "Uyku için yumuşak bir son yazılıyor." : m.mode === "learning" ? "Masala bir keşif saklanıyor." : "Macera için bir yol çiziliyor.", "check"],
      ["Masala yeni bir kelime saklanıyor.", "check"],
      ["Ragi masalı bir kez daha okuyor.", "check"],
    ];
    const ready = m.step >= lines.length;
    return { html: `<div class="topbar"><button class="circle" data-act="close" aria-label="Vazgeç">${ic("x")}</button></div>
      <div class="scroller" style="padding-bottom:30px">
        <div class="t-eyebrow" style="color:var(--mp-action-primary);margin-top:10px">${MODES[m.mode].title}</div>
        <div class="t-page">${ready ? "Masal hazır." : "Masal yazılıyor"}</div>
        <div class="notebook"><div class="t-section">${CHILD}'in masal defteri</div>
          <div class="t-supporting secondary">${CHILD}, ${m.comp}${m.fam.length ? " ve " + m.fam.join(", ") : ""}</div>
          ${lines.map(([t, i], n) => `<div class="ln ${m.step > n ? "on" : ""} t-body">${ic(i)}${t}</div>`).join("")}</div>
        <div style="display:flex;justify-content:center"><img src="${img.ragi(ready ? "Happy" : "Pencil")}" alt="" style="width:120px"></div>
      </div>
      <div class="footer-cta">${m.step >= 1 ? `<button class="btn btn-primary" data-act="prepOpen">${ready ? "Masalı oku" : "Masalı aç"}</button>` : '<div style="height:56px"></div>'}
        <button class="btn btn-ghost" data-act="prepLater">Sonra oku</button></div>` };
  },

  // --- Okuyucu ---
  reader(m) {
    if (m.page === 0) {
      const cover = m.classic ? `style="background-image:url(${ORIGINALS.includes(m.classic) ? img.original(m.classic.id) : img.classic(m.classic.id)})"`
        : `style="background:var(${MODES[m.mode].soft})"`;
      return { cls: "reader", html: `<div class="rbody cover-leaf">
        <button class="glass close" data-act="close" aria-label="Kapat">${ic("x")}</button>
        <div class="cv" ${cover}></div>
        <div class="t-page" style="margin-top:10px">${esc(m.title)}</div>
        <div class="t-supporting secondary">Kim okusun?</div>
        <button class="btn btn-primary" style="max-width:320px" data-act="readerNext">${ic("book")}Kendim okuyorum</button>
        <button class="btn btn-secondary" style="max-width:320px" data-soon="Ragi okusun (sesli okuma)">${ic("volume")}Ragi okusun</button>
      </div>` };
    }
    const n = m.page, total = m.pages.length, last = n === total;
    return { cls: "reader", html: `<div class="rbody">
      <button class="glass close" data-act="close" aria-label="Kapat">${ic("x")}</button>
      <div class="glass tools"><button data-soon="Favori" aria-label="Favorilere ekle">${ic("heart")}</button><button data-soon="Okuma ayarları" aria-label="Okuma ayarları">${ic("type")}</button></div>
      <button class="tapzone prev" data-act="readerPrev" aria-label="Önceki sayfa"></button>
      <button class="tapzone next" data-act="${last ? "finish" : "readerNext"}" aria-label="Sonraki sayfa"></button>
      <div class="page"><div>${m.pages[n - 1]}</div><div class="pageno">${n} / ${total}</div></div>
      <div class="glass bottom"><button data-act="readerPrev" aria-label="Önceki sayfa">${ic("left")}</button>
        <div class="track"><i style="width:${(n / total) * 100}%"></i></div>
        <button data-act="${last ? "finish" : "readerNext"}" aria-label="${last ? "Masalı bitir" : "Sonraki sayfa"}" style="${last ? "background:var(--mp-action-primary);color:#fff" : ""}">${ic(last ? "flag" : "right")}</button></div>
    </div>` };
  },
  ending(m) {
    return { cls: "reader", html: `<div class="rbody ending">
      <img src="${img.ragi("Happy")}" alt="" style="width:130px" class="ragi-jump">
      <div class="t-eyebrow" style="color:var(--mp-action-primary)">Masal bitti</div>
      <div class="t-page">Bravo, ${CHILD}!</div>
      <div class="t-body secondary">Harika bir masaldı!</div>
      <div class="award"><div>${ic("star")}<b class="t-card-title">+1 yıldız</b><span class="t-footnote secondary">${S.stars} yıldız</span></div>
        <div>${ic("sticker")}<b class="t-card-title">Çıkartma</b><span class="t-footnote secondary">albümüne eklendi</span></div></div>
      <button class="btn btn-primary" style="max-width:320px" data-act="again">${ic("wand")}Bir masal daha</button>
      <button class="btn btn-ghost" data-act="goodnight">İyi geceler</button>
    </div>` };
  },

  // --- Büyükler için ---
  gate() {
    return { html: `<div class="topbar"><button class="circle" data-act="close" aria-label="Geri">${ic("left")}</button></div>
      <div class="layer gate" style="position:relative;flex:1;background:none">
        <div class="t-page">Bu bölüm büyükler için</div>
        <p class="t-body secondary" style="margin:0">Açmak için düğmeyi iki saniye basılı tut.</p>
        <div class="hold" id="hold" role="button" aria-label="Büyükler için bölümünü aç">
          <svg class="ring" viewBox="0 0 144 144"><circle cx="72" cy="72" r="68"/></svg>${ic("hand")}</div>
        <span class="t-footnote secondary">İki saniye basılı tut</span>
      </div>` };
  },
  parent() {
    const days = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"];
    return { parent: true, html: `<div class="scroller">
      <div class="tab-head" style="align-items:flex-start"><div><h1 style="font-size:calc(30px * var(--type))">Büyükler için</h1><span class="t-footnote secondary" style="font-weight:400">Bu hafta · 16 Kasım - 22 Kasım</span></div>
        <button class="kid-mode" data-act="kidMode">${ic("logout")}Çocuk modu</button></div>
      <p class="t-body" style="margin:18px 0 0">Bu hafta ${2 + S.finished} masal.</p>
      <div class="stats">
        <div class="stat"><span class="tile" style="background:var(--mp-world-green-soft);color:var(--mp-world-green-deep)">${ic("clock")}</span><b>${S.finished * 6}<small class="t-supporting secondary"> dk</small></b><span class="t-supporting secondary">Okuma süresi</span></div>
        <div class="stat"><span class="tile" style="background:var(--mp-world-lav-soft);color:var(--mp-world-lav-deep)">${ic("book")}</span><b>${2 + S.finished}</b><span class="t-supporting secondary">Okunan masal</span></div>
        <div class="stat"><span class="tile" style="background:var(--mp-world-peach-soft);color:var(--mp-world-peach-deep)">${ic("flame")}</span><b>${S.finished ? 1 : 0}<small class="t-supporting secondary"> gün</small></b><span class="t-supporting secondary">Üst üste gün</span></div>
        <div class="stat"><span class="tile" style="background:var(--mp-world-yellow-soft);color:var(--mp-world-yellow-deep)">${ic("star")}</span><b>${S.finished}</b><span class="t-supporting secondary">Bu hafta çıkartma</span></div>
      </div>
      <div class="stat" style="margin-top:12px"><div style="display:flex;justify-content:space-between"><span class="t-section">Günlük okuma</span><span class="t-footnote secondary">dakika</span></div>
        <div class="bars">${days.map((d, i) => `<div><span class="b ${i === 2 ? "today" : ""}" style="height:${i === 2 ? 20 + S.finished * 18 : 20}px"></span><span class="t-footnote secondary">${d}</span></div>`).join("")}</div></div>
      <div class="section-h"><h2>Son masallar</h2><button class="link" data-soon="Kitap yap">Kitap yap ${ic("right")}</button></div>
      <div class="list" style="margin-top:10px">${S.library.slice(0, 3).map((s) => { const m = MODES[s.mode]; return `<button class="row" data-soon="Masal ayrıntısı">
        <span class="tile" style="background:var(${m.soft});color:var(${m.deep})">${ic(m.icon)}</span><span class="grow"><span class="t-card-title">${esc(s.title)}</span>
        <span class="t-footnote secondary" style="font-weight:400">${CHILD} · ${s.when.toLowerCase()}${s.half ? " · yarım kaldı" : ""}</span></span><span class="chev">${ic("right")}</span></button>`; }).join("")}</div>
      <div class="section-h"><h2>Daha fazlası</h2></div>
      <div class="list" style="margin-top:10px">
        <button class="row" data-act="parentPush" data-arg="settings"><span class="tile" style="background:var(--mp-world-gray-soft)">${ic("type")}</span><span class="grow"><span class="t-card-title">Ayarlar</span><span class="t-footnote secondary" style="font-weight:400">Profiller, bildirim, hesap</span></span><span class="chev">${ic("right")}</span></button>
        <button class="row" data-act="paywall"><span class="tile" style="background:var(--mp-world-yellow-soft);color:var(--mp-world-yellow-deep)">${ic("crown")}</span><span class="grow"><span class="t-card-title">Abonelik</span><span class="t-footnote secondary" style="font-weight:400">Ücretsiz plan</span></span><span class="chev">${ic("right")}</span></button>
      </div>
    </div>` };
  },
  settings() {
    const row = (icon, bg, fg, t, s, attrs) => `<button class="row" ${attrs}><span class="tile" style="background:var(${bg});color:var(${fg})">${ic(icon)}</span><span class="grow"><span class="t-card-title">${t}</span>${s ? `<span class="t-footnote secondary" style="font-weight:400">${s}</span>` : ""}</span><span class="chev">${ic("right")}</span></button>`;
    return { parent: true, html: `<div class="topbar"><button class="circle" data-act="parentBack" aria-label="Geri">${ic("left")}</button><span class="t-section">Ayarlar</span></div>
      <div class="scroller">
        <div class="section-h" style="margin-top:8px"><h2>Çocuk profilleri</h2></div>
        <div class="list" style="margin-top:10px">${row("user", "--mp-world-green-soft", "--mp-world-green-deep", CHILD, `5-6 yaş · ${S.library.length} masal`, 'data-soon="Profil düzenleme"')}${row("plus", "--mp-world-sky-soft", "--mp-world-sky-deep", "Profil ekle", "", 'data-soon="Profil ekleme"')}</div>
        <div class="section-h"><h2>Bildirimler</h2></div>
        <div class="list" style="margin-top:10px"><div class="row"><span class="tile" style="background:var(--mp-world-yellow-soft);color:var(--mp-world-yellow-deep)">${ic("bell")}</span><span class="grow"><span class="t-card-title">Masal saati hatırlatması</span><span class="t-footnote secondary" style="font-weight:400">Kapalı</span></span><button class="switch" data-act="toggle" aria-label="Masal saati hatırlatması"></button></div></div>
        <div class="section-h"><h2>Hesap</h2></div>
        <div class="list" style="margin-top:10px">${row("user", "--mp-world-yellow-soft", "--mp-world-yellow-deep", "Giriş yapılmadı", "Masalların cihazda. Bağlantı gelince giriş yapabilirsin.", 'data-soon="Giriş"')}
          ${row("crown", "--mp-world-yellow-soft", "--mp-world-yellow-deep", "Abonelik", "Ücretsiz plan", 'data-act="paywall"')}
          ${row("lock", "--mp-world-gray-soft", "--mp-text-secondary", "Gizlilik ve veri", "Ne tuttuğumuz, nasıl sildiğimiz", 'data-soon="Gizlilik ve veri"')}</div>
      </div>` };
  },
  paywall(m) {
    const benefits = [["sparkles", "lav", "Sınırsız metin masalı"], ["library", "pink", "12 masal dünyasının tamamı"], ["star", "yellow", "Aylık görselli masal hakkı"], ["volume", "sky", "Uzun masallar ve sesli okuma"], ["sticker", "green", "Yazdırılabilir PDF masal kitabı"]];
    return { html: `<div class="scroller" style="padding:0 0 20px">
        <div style="position:relative;height:270px;margin-top:-54px;background:var(--mp-world-lav-soft);border-radius:0 0 200px 200px;display:flex;justify-content:center;align-items:flex-end">
          <img src="${img.ragi("OnBook")}" alt="" style="width:190px;margin-bottom:22px">
          <span class="t-supporting" style="position:absolute;bottom:-14px;background:#fff;color:var(--mp-world-yellow-deep);border-radius:999px;padding:6px 16px;display:flex;gap:6px;align-items:center">${ic("crown")}Premium</span></div>
        <button class="circle" style="position:absolute;top:calc(var(--status) + 8px);right:20px;z-index:3" data-act="paywallClose" aria-label="Kapat">${ic("x")}</button>
        <div class="center" style="padding:28px 20px 0"><div class="t-page">Her akşam yeni bir masal</div>
          <p class="t-body secondary" style="margin:8px 0 0">Sınırsız metin masalı, tüm dünyalar açık ve her ay görselli maceralar.</p></div>
        <div style="padding:22px 24px 0;display:grid;gap:16px">${benefits.map(([i, t, l]) => `<div style="display:flex;gap:16px;align-items:center"><span style="width:42px;height:42px;border-radius:50%;display:grid;place-items:center;background:var(--mp-world-${t}-soft);color:var(--mp-world-${t}-deep)">${ic(i)}</span><span class="t-card-title">${l}</span></div>`).join("")}</div>
        <p class="t-footnote center" style="margin:22px 24px 0;color:var(--mp-status-danger)">Not (prototip): bu bugünkü Paywall. Görselli masal uygulamada kapalı; öneri için önizleyicide "Abonelik · öneri".</p>
      </div>
      <div class="footer-cta" style="border:0"><button class="btn btn-primary" data-soon="Satın alma">Planları gör</button><button class="btn btn-ghost" data-act="paywallClose">Şimdi değil</button></div>` };
  },
};

// Ana sayfadaki mod kartı: masal yazma akışının ikinci adımına doğrudan.
ACTIONS.createModeDirect = (k) => { S.modal = { view: "createWho", mode: k, comp: null, fam: [], topic: null }; render("cover"); };

// Hazırlık: 6-8 sn, 2 sn sonra atlanabilir, bitince masal kendiliğinden açılır (karar 7 Kasım 2026).
VIEWS.after.prep = (m) => {
  if (m.step < 4) later(() => { if (S.modal === m) { m.step++; render(); } }, 1600);
  else later(() => { if (S.modal === m) ACTIONS.prepOpen(); }, 1200);
};
ACTIONS.prepOpen = () => {
  const m = S.modal;
  if (!S.library.find((s) => s.title === m.title)) S.library.unshift({ title: m.title, mode: m.mode, when: "Bugün" });
  S.modal = { view: "reader", title: m.title, mode: m.mode, page: 1, pages: sampleStory(m.title, m.comp) };
  render("fade");
};
ACTIONS.prepLater = () => {
  const m = S.modal;
  if (!S.library.find((s) => s.title === m.title)) S.library.unshift({ title: m.title, mode: m.mode, when: "Bugün" });
  close(); go("kitaplik"); toast("Masal kitaplığına eklendi");
};
// Ebeveyn kapısı: iki saniye basılı tutma.
VIEWS.after.gate = () => {
  const h = document.getElementById("hold"); let t;
  const start = (e) => { e.preventDefault(); h.classList.add("go"); t = setTimeout(() => { S.modal = { view: "parent" }; render("fade"); }, 2000); };
  const stop = () => { h.classList.remove("go"); clearTimeout(t); };
  h.addEventListener("pointerdown", start); ["pointerup", "pointerleave", "pointercancel"].forEach((ev) => h.addEventListener(ev, stop));
};
// Okuyucu klavye: ← →
document.addEventListener("keydown", (e) => {
  if (!S.modal || S.modal.view !== "reader") return;
  if (e.key === "ArrowRight") (S.modal.page === S.modal.pages.length ? ACTIONS.finish : ACTIONS.readerNext)();
  if (e.key === "ArrowLeft") ACTIONS.readerPrev();
  if (e.key === "Escape") close();
});

function bust() {
  return `<svg class="bust" viewBox="0 0 104 104" aria-hidden="true"><circle cx="52" cy="52" r="52" fill="var(--mp-world-lav-soft)"/>
    <path d="M22 104c2-18 14-26 30-26s28 8 30 26z" fill="#2F8F87"/><circle cx="52" cy="50" r="22" fill="#F6C9A5"/>
    <path d="M30 46c0-16 10-22 22-22s22 6 22 22c-4-6-12-9-22-9s-18 3-22 9z" fill="#7A4B2A"/>
    <circle cx="44" cy="52" r="2.4" fill="#2E1E3E"/><circle cx="60" cy="52" r="2.4" fill="#2E1E3E"/>
    <circle cx="40" cy="58" r="3" fill="#F2A3A3" opacity=".6"/><circle cx="64" cy="58" r="3" fill="#F2A3A3" opacity=".6"/>
    <path d="M47 61c3 3 7 3 10 0" stroke="#2E1E3E" stroke-width="2" fill="none" stroke-linecap="round"/></svg>`;
}

// Başlangıç: ?ekran=kitaplik gibi bir derin bağlantıyla da açılabilir.
S.os = "home"; S.onboarded = false; S.ob = "welcome";
const start = Q.get("ekran");
if (start && VIEWS[start] && ["home", "masallar", "kitaplik", "profil"].includes(start)) S.tab = start;
// ?ortu=createMode|createWho|prep|reader|ending|gate|parent|settings|paywall: tam ekran sayfaya doğrudan.
const ortu = Q.get("ortu");
const DEMO = {
  createMode: { view: "createMode" },
  createWho: { view: "createWho", mode: "bedtime", comp: "kaplumbağa", fam: ["Anneanne"], topic: null },
  prep: { view: "prep", mode: "bedtime", comp: "kaplumbağa", fam: [], step: 2, title: "İrem ve Uykucu Kaplumbağa" },
  reader: { view: "reader", title: "İrem ve Uykucu Ay", mode: "bedtime", page: 2, pages: sampleStory("", "kaplumbağa") },
  cover: { view: "reader", title: "Rapunzel", classic: CLASSICS[0], mode: "bedtime", page: 0, pages: sampleStory("", "kaplumbağa") },
  ending: { view: "ending" }, gate: { view: "gate" }, parent: { view: "parent" },
  settings: { view: "settings", from: { view: "parent" } }, paywall: { view: "paywall", from: { view: "parent" } },
};
if (DEMO[ortu]) S.modal = DEMO[ortu];
if (start || DEMO[ortu]) { S.os = "app"; S.onboarded = true; }
addEventListener("DOMContentLoaded", () => render());
