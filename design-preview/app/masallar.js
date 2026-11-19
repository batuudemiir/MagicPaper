// Masallar sekmesi: uygulamanın kataloğundan (content.js) beslenir.
// Kaynak düzen: GunlukView.swift (raflar, gece bölgesi, "Kendi masalını yaz"),
// ClassicDetailView, ClassicSeriesView, GunlukShelfView (raf + arama),
// GunlukCategoriesView ("Tüm raflar"). Metinler ClassicTale.swift'ten.
"use strict";

const C = window.MP_CONTENT || { tales: [], series: [], originals: [], weekly: [] };
const SHELF = {
  orijinal: { title: "MagicPaper Original", sub: "Yalnızca burada okunan masallar", chip: "Original", icon: "sparkles", tone: "lav" },
  klasikler: { title: "Dünya klasikleri", sub: "Yüz yıldır okunan masallar", chip: "Klasikler", icon: "crown", tone: "lav" },
  anadolu: { title: "Anadolu'dan", sub: "Ninelerimizin anlattığı masallar", chip: "Anadolu", icon: "home", tone: "peach" },
  fabllar: { title: "Fabllar", sub: "Hayvanların dilinden kısa dersler", chip: "Fabllar", icon: "sparkles", tone: "mint" },
  uyku: { title: "Uyku vakti", sub: "Kısa, sakin, ışıklar kısılırken", chip: "Uyku", icon: "moon", tone: "sky" },
  seriler: { title: "Seriler", sub: "Bölüm bölüm okunan masallar", chip: "Seriler", icon: "library", tone: "pink" },
  hayvanlar: { title: "Hayvanlar", sub: "Konuşan tavşanlar, akıllı tilkiler", chip: "Hayvanlar", icon: "heart", tone: "green" },
};
const DOORS = ["klasikler", "anadolu", "fabllar", "uyku", "seriler"];
const byId = (id) => C.tales.find((t) => t.id === id) || C.originals.find((t) => t.id === id) || C.series.find((s) => s.id === id);
const standalone = C.tales.filter((t) => !t.seriesID);
function items(shelf) {
  if (shelf === "orijinal") return C.originals;
  if (shelf === "seriler") return C.series;
  const list = standalone.filter((t) => t.shelves.includes(shelf)).concat(C.series.filter((s) => s.shelves.includes(shelf)));
  return shelf === "uyku" ? list.concat(C.originals.filter((o) => o.shelves.includes("uyku"))) : list;
}
const isSeries = (x) => !!x.episodes;
const meta = (x) => isSeries(x) ? `${x.byline} · ${x.episodes.length} ${x.unitName}` : `${x.byline} · ${x.minutes} dk`;
const fullMeta = (x) => `${meta(x)} · ${x.ageMin}-${x.ageMax} yaş`;
S.progress = S.progress || {}; S.fav = S.fav || new Set();
// Demo: Rapunzel yarım (uygulamanın -mpDemoLibrary kurulumu gibi)
const rap = C.tales.find((t) => t.slug === "rapunzel"); if (rap && S.progress[rap.id] == null) S.progress[rap.id] = 1;

// Kapak: görsel varsa odak noktasıyla, yoksa uygulamadaki gibi adlı yer tutucu
const TONES = ["lav", "peach", "mint", "sky", "pink", "yellow", "green"];
function cover(x, cls = "") {
  if (x.cover) return `<div class="cv ${cls}" style="background-image:url(${x.cover});background-position:${x.focus.x * 100}% ${x.focus.y * 100}%"></div>`;
  const t = TONES[[...x.title].reduce((a, c) => a + c.charCodeAt(0), 0) % TONES.length];
  return `<div class="cv made ${cls}" style="background:var(--mp-world-${t}-soft);color:var(--mp-world-${t}-deep)">${esc(x.title)}</div>`;
}
const card = (x, w = 128, dark = false) => `<button class="book" ${w ? `style="width:${w}px"` : ""} data-act="openItem" data-arg="${x.id}" aria-label="${esc(x.title)}">
  ${cover(x)}<div class="t t-card-title" style="font-size:calc(15px * var(--type));${dark ? "color:#fff" : ""}">${esc(x.title)}</div>
  <div class="t-footnote" style="font-weight:400;color:${dark ? "rgba(255,255,255,.7)" : "var(--mp-text-secondary)"}">${meta(x)}</div></button>`;
const section = (shelf, list = items(shelf)) => !list.length ? "" : `
  <div class="section-h"><h2>${SHELF[shelf].title}</h2><button class="link" data-act="openShelf" data-arg="${shelf}">Tümü ${ic("right")}</button></div>
  <p class="t-supporting secondary section-sub">${SHELF[shelf].sub}</p>
  <div class="shelf">${list.map((x) => card(x)).join("")}</div>`;

// ---------- Masallar ana sayfa ----------
VIEWS.masallar = () => {
  const half = Object.keys(S.progress).map(byId).filter(Boolean);
  const slides = half.concat([byId(C.featuredID)], standalone.filter((t) => t.cover && t.shelves.includes("klasikler")))
    .filter((x, i, a) => x && a.indexOf(x) === i).slice(0, 5);
  const shownIds = new Set(slides.map((s) => s.id));
  const weekly = C.weekly.map(byId).filter((x) => x && !shownIds.has(x.id) && !x.seriesID);
  return { html: `<div class="scroller" style="padding-bottom:0">
    <div class="tab-head"><h1>Masallar</h1><button class="circle" data-act="openSearch" aria-label="Masal ara">${ic("search")}</button></div>
    <div class="chips">
      <button class="chip" style="background:var(--mp-world-gray-soft)" data-act="openCats">${ic("grid")}Tüm raflar</button>
      ${DOORS.map((s) => `<button class="chip" style="background:var(--mp-world-${SHELF[s].tone}-soft)" data-act="openShelf" data-arg="${s}">${ic(SHELF[s].icon)}${SHELF[s].chip}</button>`).join("")}
    </div>
    <div class="carousel" id="car">${slides.map((x) => { const p = S.progress[x.id]; return `<div class="card feature slide">
      <button data-act="openItem" data-arg="${x.id}" aria-label="${esc(x.title)}">${cover(x, "feat")}</button>
      <div class="meta"><span class="t-eyebrow" style="color:var(--mp-action-primary)">${p != null ? "Kaldığın yerden" : "Bu akşam için"}</span>
        <span class="t-section" style="font-weight:700">${esc(x.title)}</span><span class="t-supporting secondary">${fullMeta(x)}</span>
        <button class="pill-btn" data-act="readItem" data-arg="${x.id}">${ic("play")}${p != null ? "Devam et" : "Oku"}</button></div></div>`; }).join("")}</div>
    <div class="dots" id="cardots">${slides.map((_, i) => `<i class="${i ? "" : "on"}"></i>`).join("")}</div>
    ${section("orijinal")}
    ${weekly.length ? `<div class="section-h"><h2>Bu haftanın seçkisi</h2></div><p class="t-supporting secondary section-sub">Editörün bu hafta için seçtikleri</p>
      <div class="shelf">${weekly.map((x) => card(x)).join("")}</div>` : ""}
    ${section("klasikler")}${section("anadolu")}${section("fabllar")}
    <div class="night">
      <div class="section-h" style="margin-top:0"><h2 style="color:#fff;display:flex;gap:8px;align-items:center">${ic("moon")}${SHELF.uyku.title}</h2>
        <button class="link" style="color:#CDBDF5" data-act="openShelf" data-arg="uyku">Tümü ${ic("right")}</button></div>
      <p class="t-supporting section-sub" style="color:rgba(255,255,255,.7)">${SHELF.uyku.sub}</p>
      <div class="shelf">${items("uyku").map((x) => card(x, 160, true)).join("")}</div>
      <button class="promo" data-act="create" style="background-image:url(${img.night})">
        <span class="t-section" style="color:#fff">Kendi masalını yaz</span><span class="t-footnote" style="color:rgba(255,255,255,.85)">Adınla, sevdiklerinle yepyeni bir masal</span>
        <span class="pill-btn" style="background:#fff">${ic("wand")}Kahramanı sen ol</span></button>
      <div style="height:130px"></div>
    </div>
  </div>` };
};
VIEWS.after.__tab = () => {
  const car = document.getElementById("car"); if (!car) return;
  car.onscroll = () => { const i = Math.round(car.scrollLeft / car.clientWidth); document.querySelectorAll("#cardots i").forEach((d, n) => d.classList.toggle("on", n === i)); };
};

// ---------- Masal detayı ----------
VIEWS.tale = (v) => {
  const x = byId(v.id), saved = S.fav.has(x.id), narr = S.narr?.[x.id] || "soft";
  const p = S.progress[x.id];
  const similar = standalone.filter((t) => t.id !== x.id && t.shelves.some((s) => x.shelves.includes(s))).slice(0, 8);
  return { html: `<div class="scroller" style="padding:0 0 140px">
    ${hero(x)}
    <div style="padding:0 var(--mp-space-screen-h)">
      <button class="btn btn-primary" style="margin-top:-8px" data-act="readItem" data-arg="${x.id}">${ic("play")}${p != null ? "Kaldığın yerden devam et" : "Okumaya başla"}</button>
      <div class="section-h"><h2>Bu masalla</h2></div>
      <div class="modes" style="margin-top:12px">
        <button class="mode" style="background:var(--mp-world-lav-soft);min-height:100px" data-soon="Sesli okuma"><span class="tile" style="color:var(--mp-world-lav-deep)">${ic("volume")}</span>Dinle</button>
        <button class="mode" style="background:var(--mp-world-sky-soft);min-height:100px" data-soon="Uyku modu"><span class="tile" style="color:var(--mp-world-sky-deep)">${ic("moon")}</span>Uyku modu</button>
        <button class="mode" style="background:var(--mp-world-peach-soft);min-height:100px" data-act="fav" data-arg="${x.id}"><span class="tile" style="color:var(--mp-world-peach-deep)">${ic(saved ? "check" : "plus")}</span>${saved ? "Listemde" : "Listeme ekle"}</button>
      </div>
      <div class="section-h"><h2>Masal hakkında</h2></div>
      <p class="t-body" style="margin:8px 0 0">${esc(x.summary)}</p>
      ${x.classic ? `<div class="t-eyebrow secondary" style="margin-top:18px">Anlatım</div>
        <div class="seg" style="margin-top:8px"><button class="${narr === "soft" ? "on" : ""}" data-act="narr" data-arg="${x.id}|soft">Yumuşak</button><button class="${narr === "classic" ? "on" : ""}" data-act="narr" data-arg="${x.id}|classic">Klasik</button></div>
        ${narr === "soft" ? '<p class="t-footnote secondary" style="margin:8px 0 0;font-weight:400">Küçükler için: korkutucu sahneler çıkarıldı.</p>' : ""}` : ""}
      <p class="t-footnote secondary" style="margin:14px 0 0;font-weight:400">${esc(x.credit)}</p>
      ${similar.length ? `<div class="section-h"><h2>Benzerleri</h2></div><div class="shelf" style="margin-top:10px">${similar.map((t) => card(t)).join("")}</div>` : ""}
    </div></div>` };
};
function hero(x) {
  return `<div class="art-hero">${cover(x, "hero-img")}<div class="scrim"></div>
    <div class="art-txt"><div class="t-cover" style="color:#fff">${esc(x.title)}</div><div class="t-supporting" style="color:rgba(255,255,255,.85)">${fullMeta(x)}</div></div>
    <button class="stage-btn" style="left:20px" data-act="back" aria-label="Geri">${ic("left")}</button>
    <button class="stage-btn" style="right:20px" data-act="gate" aria-label="Paylaş">${ic("logout")}</button></div>`;
}

// ---------- Seri ----------
VIEWS.series = (v) => {
  const s = byId(v.id), eps = s.episodes.map(byId);
  const next = eps.findIndex((e) => !S.done?.has(e.id));
  return { html: `<div class="scroller" style="padding:0 0 140px">${hero(s)}
    <div style="padding:0 var(--mp-space-screen-h)">
      <button class="btn btn-primary" style="margin-top:-8px" data-act="readItem" data-arg="${eps[Math.max(0, next)].id}">${ic("play")}${next > 0 ? `${next + 1}. masaldan devam et` : "Okumaya başla"}</button>
      <p class="t-body" style="margin:22px 0 0">${esc(s.summary)}</p>
      <div class="section-h"><h2>${eps.length} ${s.unitName}</h2></div>
      <div class="list kid" style="margin-top:10px">${eps.map((e, i) => `<button class="row" data-act="readItem" data-arg="${e.id}">
        <span class="tile" style="background:var(--mp-world-pink-soft);color:var(--mp-world-pink-deep);font:800 15px Nunito">${i + 1}</span>
        <span class="grow"><span class="t-card-title">${esc(e.title)}</span><span class="t-footnote secondary" style="font-weight:400">${e.minutes} dk${S.done?.has(e.id) ? " · Okundu" : ""}</span></span><span class="chev">${ic("right")}</span></button>`).join("")}</div>
      <p class="t-footnote secondary" style="margin:14px 0 0;font-weight:400">${esc(s.credit)}</p>
    </div></div>` };
};

// ---------- Raf ve arama ----------
VIEWS.shelf = (v) => {
  const sh = SHELF[v.shelf] || { title: "Bütün masallar", sub: "" };
  const all = v.shelf ? items(v.shelf) : standalone.concat(C.series, C.originals);
  const band = v.band || "all";
  const list = all.filter((x) => band === "all" || (x.ageMin <= +band.split("-")[1] && x.ageMax >= +band.split("-")[0]));
  return { html: `<div class="topbar"><button class="circle" data-act="back" aria-label="Geri">${ic("left")}</button><span class="t-section">${sh.title}</span></div>
    <div class="scroller"><p class="t-supporting secondary" style="margin:0">${sh.sub}</p>
      <div class="chips" style="margin-top:12px">${[["all", "Hepsi"], ["3-4", "3-4 yaş"], ["5-6", "5-6 yaş"], ["7-8", "7-8 yaş"], ["9-10", "9-10 yaş"]].map(([k, l]) =>
        `<button class="chip ${band === k ? "dark" : ""}" data-act="shelfBand" data-arg="${k}">${l}</button>`).join("")}</div>
      ${list.length ? `<div class="grid2">${list.map((x) => card(x, 0)).join("")}</div>`
        : `<div class="empty-note"><b class="t-card-title">Bu rafta henüz masal yok</b><span class="t-supporting secondary">Yeni masallar yolda.</span></div>`}
    </div>` };
};
VIEWS.search = (v) => {
  const q = (v.q || "").trim().toLocaleLowerCase("tr");
  const all = standalone.concat(C.series, C.originals);
  const list = q ? all.filter((x) => x.title.toLocaleLowerCase("tr").includes(q)) : [];
  return { html: `<div class="topbar"><button class="circle" data-act="back" aria-label="Geri">${ic("left")}</button>
      <input id="q" class="search-in" placeholder="Masal ara" value="${esc(v.q || "")}" aria-label="Masal ara" autocomplete="off"></div>
    <div class="scroller">${!q ? `<p class="t-supporting secondary">Adını hatırladığın masalı bul</p>`
      : list.length ? `<div class="grid2">${list.map((x) => card(x, 0)).join("")}</div>`
      : `<div class="empty-note"><b class="t-card-title">Bu adla bir masal bulamadık</b><span class="t-supporting secondary">Başka bir kelimeyle dene ya da raflara göz at.</span></div>`}</div>` };
};
VIEWS.categories = () => ({ html: `<div class="topbar"><span class="t-section" style="flex:1">Kategoriler</span><button class="circle" data-act="close" aria-label="Kapat">${ic("x")}</button></div>
  <div class="scroller"><div class="t-eyebrow secondary" style="margin-top:6px">Raflar</div>
    <div class="list kid" style="margin-top:10px">${Object.keys(SHELF).map((k) => `<button class="row" data-act="catShelf" data-arg="${k}">
      <span class="tile" style="background:var(--mp-world-${SHELF[k].tone}-soft);color:var(--mp-world-${SHELF[k].tone}-deep)">${ic(SHELF[k].icon)}</span>
      <span class="grow"><span class="t-card-title">${SHELF[k].title}</span><span class="t-footnote secondary" style="font-weight:400">${items(k).length} masal</span></span><span class="chev">${ic("right")}</span></button>`).join("")}</div></div>` });

// ---------- Eylemler ----------
Object.assign(ACTIONS, {
  openItem: (id) => { const x = byId(id); if (!x) return; if (x.seriesID) return ACTIONS.readItem(id); push(isSeries(x) ? { view: "series", id } : { view: "tale", id }); },
  openShelf: (shelf) => push({ view: "shelf", shelf }),
  openSearch: () => push({ view: "search", q: "" }),
  openCats: () => open({ view: "categories" }),
  catShelf: (k) => { close(); push({ view: "shelf", shelf: k }); },
  shelfBand: (b) => { S.stack[S.stack.length - 1].band = b; render(); },
  back: () => back(),
  fav: (id) => { const now = !S.fav.has(id); now ? S.fav.add(id) : S.fav.delete(id); render(); toast(now ? "Listene eklendi" : "Listenden çıkarıldı"); },
  narr: (arg) => { const [id, n] = arg.split("|"); S.narr = S.narr || {}; S.narr[id] = n; render(); },
  readItem: (id) => {
    const x = byId(id); const pages = (x.classic && S.narr?.[id] === "classic" ? x.classic : x.soft) || [];
    open({ view: "reader", title: x.title, taleID: id, coverImg: x.cover, mode: "bedtime",
           page: S.progress[id] != null ? S.progress[id] : 0, pages: pages.map((ps) => ps.map((p) => `<p>${esc(p)}</p>`).join("")) });
  },
});
// Okuma ilerlemesi ve okunanlar (Masallar vitrini ve seri sayfası için)
const _next = ACTIONS.readerNext, _finish = ACTIONS.finish;
ACTIONS.readerNext = () => { _next(); const m = S.modal; if (m && m.taleID) S.progress[m.taleID] = m.page; };
ACTIONS.finish = () => { const m = S.modal; if (m && m.taleID) { delete S.progress[m.taleID]; (S.done = S.done || new Set()).add(m.taleID); } _finish(); };
// Ana sayfa ve Kitaplık'taki eski Rapunzel bağlantısı katalogdaki masala gider
ACTIONS.openClassic = (slug) => { const x = C.tales.find((t) => t.slug === slug) || C.originals.find((t) => t.slug === slug); if (x) ACTIONS.readItem(x.id); };
// Arama kutusu: yazdıkça süz, odak kaybolmasın
VIEWS.after.__push = () => {
  const q = document.getElementById("q"); if (!q) return;
  q.focus(); q.setSelectionRange(q.value.length, q.value.length);
  q.oninput = () => { S.stack[S.stack.length - 1].q = q.value; render(); };
};

// ?sayfa=tale:rapunzel | series:keloglan | shelf:anadolu | search:kedi  (kontrol ve tasarım için)
{ const sp = new URLSearchParams(location.search).get("sayfa");
  if (sp) { const [k, v] = sp.split(":"); const x = C.tales.concat(C.series, C.originals).find((t) => t.slug === v);
    S.os = "app"; S.onboarded = true; S.tab = "masallar";
    S.stack = [k === "shelf" ? { view: "shelf", shelf: v } : k === "search" ? { view: "search", q: v } : { view: k, id: x && x.id }]; } }
