// Menü sayfaları ve yeni Profil (23 Kasım 2026, İrem). Uygulamadaki
// MPSkyPage / MPSkyIntro ve yeni KidCornerView'un prototipi:
// mor gök + geri + beyaz başlık, göğün altında beyaz tanıtım kartı (Ragi
// yumuşak dairede, kısa başlık, tek cümle), içerik beyaz zeminde.
// Profil: ana sayfanın göğü, kim okuyor, kimlik kartı (arkasından Ragi),
// üç bilgi kartı, Büyükler için, açık rozet vitrini, Masal dünyam.
// Kurallar (ilke 7): sayı yalnızca toplananı söyler; ilerleme çubuğu,
// "az kaldı", kıyas yok. Kilitli rozet gri + kilit + "Kilitli" yazısı.
"use strict";

P.seal = '<path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"/>';
P.shield = '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>';
P.moonStar = P.moon;
P.pin = '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>';
P.leaf = '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>';
P.wave = '<path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>';
P.rocket = '<path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"/><path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/>';

const tone = (t) => `background:var(--mp-world-${t}-soft);color:var(--mp-world-${t}-deep)`;

// Örnek veri (DEBUG demo kitaplığıyla aynı ruhta).
const BADGES = [
  { t: "İlk masal", i: "book", tone: "yellow", on: true, s: "Kazanıldı" },
  { t: "Uyku masalcısı", i: "moon", tone: "lav", on: true, s: "2. kat" },
  { t: "İlk macera", i: "tent", tone: "peach", on: true, s: "Kazanıldı" },
  { t: "Kelime avcısı", i: "type", tone: "mint", on: false, s: "Kilitli" },
  { t: "Masal gezgini", i: "map", tone: "sky", on: false, s: "Kilitli" },
  { t: "Gizli rozet", i: "sparkles", tone: "pink", on: false, s: "Kilitli" },
  { t: "Okuma günleri", i: "clock", tone: "green", on: false, s: "Kilitli" },
  { t: "Aile masalı", i: "users", tone: "peach", on: false, s: "Kilitli" },
  { t: "Yıldız toplayıcı", i: "star", tone: "yellow", on: false, s: "Kilitli" },
];
const STICKERS = [["moon", "lav", "Uykucu Ay"], ["star", "yellow", "Yıldız Kedi"], ["leaf", "green", "Gizli Yol"], ["wave", "sky", "Denizaltı"], ["sparkles", "pink", "Bulut Ninnisi"]];
const WORDS = [["fener", "Karanlıkta yolu aydınlatan ışık.", "İrem ve Uykucu Ay", "yellow"],
  ["usulca", "Çok sessiz ve yavaşça.", "Bulutların Ninnisi", "sky"],
  ["pırıltı", "Küçük, parlak ışık.", "Yıldız Toplayan Kedi", "lav"],
  ["mağara", "Kayaların içindeki kovuk.", "Ormandaki Gizli Yol", "green"]];
const PLACES = [["Ay Köprüsü", "moon", "lav", 2, "Kaplumbağa"], ["Fısıldayan Orman", "leaf", "green", 1, "Tilki"],
  ["Mercan Bahçesi", "wave", "sky", 1, ""], ["Yıldız Limanı", "rocket", "yellow", 1, "Baykuş"]];
const FAM_CAST = [["Anneanne", "peach", 3], ["Dede", "sky", 2], ["Pamuk (kedi)", "lav", 1]];
const DECOR = [["Ahşap", "peach", 0], ["Lavanta", "lav", 8], ["Nane", "mint", 8], ["Gökyüzü", "sky", 8], ["Pembe", "pink", 8], ["Güneş", "yellow", 8]];
Object.assign(S, { wordsWeek: true, decorPick: 0, decorOwned: [0], decorOn: 0, famPick: null });

/** MPSkyPage: gök, geri, beyaz başlık, isteğe bağlı sağ öğe ve tanıtım kartı. */
function skyPage(title, { hero = "", trailing = "", body = "", footer = "" }) {
  return { cls: "home2 sky", html: `<div class="scroller">
    <div class="sk-hero">
      <div class="sk-top"><button class="h2-circle" data-act="skyBack" aria-label="Geri">${ic("left")}</button>
        <h1>${title}</h1>${trailing}</div>
      ${hero}
    </div>
    <div class="sk-body">${body}</div>
  </div>${footer}` };
}

/** MPSkyIntro: Ragi yumuşak dairede, kısa başlık, tek cümle. */
const skyIntro = (pose, t, headline, message) => `<div class="sk-intro">
  <span class="sk-ragi" style="${tone(t)}"><img src="${img.ragi(pose)}" alt=""></span>
  <span class="grow"><b>${headline}</b><span class="t-supporting secondary">${message}</span></span></div>`;

const sectionH = (title, link = "") => `<div class="sk-sec"><h2>${title}</h2>${link}</div>`;

/** Açık rozet: kartsız, büyük arma, ad, durum. */
const badgeCell = (b) => `<button class="pf-badge ${b.on ? "" : "off"}" data-act="skyPage" data-arg="badges" aria-label="${b.t}, ${b.s}">
  <span class="arm" style="${b.on ? tone(b.tone) : ""}">${ic(b.on || b.t !== "Gizli rozet" ? b.i : "sparkles")}${b.on ? "" : `<i class="lk">${ic("lock")}</i>`}</span>
  <b>${b.t}</b><span>${b.s}</span></button>`;

const earnedCount = () => BADGES.filter((b) => b.on).length;

VIEWS.badges = () => skyPage("Rozetlerim", {
  hero: skyIntro("Happy", "yellow", `${earnedCount()} / 69 rozet`, "Her rozet bir masaldan geldi. Dokun, hangisi olduğunu anlatayım."),
  body: `<button class="sk-card sk-level"><span class="lv">${ic("star")}<i>2</i></span>
      <span class="grow"><span class="t-footnote secondary">Yıldız katın</span><b class="t-card-title">Parlak yıldız</b>
      <span class="t-supporting secondary">★ ${S.stars + 14} yıldız</span></span><span class="chev">${ic("right")}</span></button>
    ${sectionH("Yollar")}<div class="pf-badges">${BADGES.slice(0, 3).map(badgeCell).join("")}</div>
    ${sectionH("Keşifler")}<div class="pf-badges">${BADGES.slice(3).map(badgeCell).join("")}</div>
    ${sectionH("Masal anıları")}<div class="sk-row"><span class="tile" style="${tone("lav")}">${ic("moon")}</span>
      <span class="grow"><b class="t-card-title">İlk uyku masalı</b><span class="t-supporting secondary">İrem ve Uykucu Ay</span></span></div>`,
});

VIEWS.stickers = () => skyPage("Çıkartma albümüm", {
  hero: skyIntro("Happy", "pink", `${STICKERS.length} çıkartma`, "Her bitirdiğin masal buraya bir çıkartma bırakır."),
  body: `${sectionH("Kasım")}<div class="sk-stickers">${STICKERS.map(([i, t, name]) => `
      <button class="st" data-soon="Çıkartma penceresi" aria-label="${name} çıkartması"><span class="disc" style="${tone(t)}">${ic(i)}</span><span>${name}</span></button>`).join("")}
      <span class="st next"><span class="disc">${ic("plus")}</span><span>Sıradaki masal</span></span></div>`,
});

VIEWS.words = () => {
  const shown = S.wordsWeek ? WORDS.slice(0, 3) : WORDS;
  return skyPage("Yeni kelimelerim", {
    hero: skyIntro("Reading", "sky", `${WORDS.length} kelime topladın`, "Hangisini hatırlıyorsun? Dokun, birlikte dinleyelim."),
    body: `<div class="sk-chips"><button class="chip ${S.wordsWeek ? "on" : ""}" data-act="wordsWeek" data-arg="1">Bu hafta</button>
        <button class="chip ${S.wordsWeek ? "" : "on"}" data-act="wordsWeek" data-arg="0">Tümü</button></div>
      <div class="sk-list">${shown.map(([w, m, story, t]) => `<div class="sk-word" style="background:var(--mp-world-${t}-soft)">
        <span class="grow"><b>${w}</b><span class="t-supporting">${m}</span><span class="t-footnote secondary">${story}</span></span>
        <button class="h2-circle" data-soon="Kelimeyi dinle" aria-label="${w} kelimesini dinle">${ic("volume")}</button></div>`).join("")}</div>`,
  });
};

VIEWS.map = () => skyPage("Masal haritam", {
  hero: skyIntro("Walking", "green", `${PLACES.length} yere gittin`, "Gittiğin her yer burada. Yeniden gidince seni hatırlarlar."),
  body: `<div class="sk-grid2">${PLACES.map(([name, i, t, n, friend]) => `<div class="sk-card sk-place">
      <span class="tile" style="background:var(--mp-world-${t}-deep);color:#fff">${ic(i)}</span>
      <b class="t-card-title">${name}</b><span class="t-footnote secondary">${n} masal</span>
      ${friend ? `<span class="t-footnote secondary">${friend}</span>` : ""}</div>`).join("")}
      <div class="sk-card sk-place off"><span class="tile">${ic("pin")}</span><b class="t-card-title">Bilinmeyen yer</b>
      <span class="t-footnote secondary">Bir masal seni buraya götürecek</span></div></div>`,
});

VIEWS.family = () => {
  const pick = S.famPick != null ? FAM_CAST[S.famPick] : null;
  return skyPage("Masal ailem", {
    hero: `<div class="sk-intro"><span class="sk-av">${bust()}</span>
      <span class="grow"><span class="t-footnote" style="color:var(--mp-action-primary);font-weight:800">KAHRAMAN</span><b>${CHILD}</b>
      <span class="t-footnote secondary">Her masalda</span></span></div>`,
    body: `${sectionH("Masallarında tekrar görünen karakterler")}
      <div class="sk-grid2">${FAM_CAST.map(([name, t, n], k) => `<button class="sk-fam ${S.famPick === k ? "on" : ""}" style="background:var(--mp-world-${t}-soft)" data-act="famPick" data-arg="${k}" aria-pressed="${S.famPick === k}">
        <span class="ini" style="color:var(--mp-world-${t}-deep)">${name[0]}</span><b class="t-card-title">${name}</b><span class="t-footnote secondary">${n} masalda</span></button>`).join("")}
        <button class="sk-fam add" data-act="gate">${ic("plus")}<b class="t-card-title">Yeni karakter</b></button></div>
      <div class="say"><img src="${img.ragi("Waving")}" alt="" style="width:72px"><div class="bubble t-body">Masallarına kimler katılsın? Bir büyüğünle ekleyebilirsin.</div></div>`,
    footer: pick ? `<div class="sk-foot"><span class="t-supporting secondary">${pick[0]} seçili</span>
      <button class="btn btn-primary" data-soon="Bu karakterle masal yaz">${ic("wand")}Bu karakterle masal yaz</button></div>` : "",
  });
};

VIEWS.decor = () => {
  const balance = S.stars + 10;
  const sel = DECOR[S.decorPick];
  const owned = S.decorOwned.includes(S.decorPick), on = S.decorOn === S.decorPick;
  return skyPage("Kitaplık renklerim", {
    trailing: `<span class="sk-bal" aria-label="${balance} yıldızın var">${ic("star")}${balance}</span>`,
    hero: skyIntro("Happy", sel[1], "Kitaplığını süsle", "Okudukça kazandığın yıldızlarla kitaplığına renk seç."),
    body: `${sectionH("Kitaplığının rengi")}
      <div class="sk-shelf" style="background:var(--mp-world-${sel[1]}-soft);border-bottom-color:var(--mp-world-${sel[1]}-deep)">
        ${["lav", "yellow", "mint", "pink", "sky"].map((t) => `<i style="background:var(--mp-world-${t}-deep)"></i>`).join("")}</div>
      <div class="sk-decor">${DECOR.map(([name, t, price], k) => `<button class="${k === S.decorPick ? "on" : ""}" data-act="decorPick" data-arg="${k}" aria-pressed="${k === S.decorPick}">
        <span class="sw" style="background:var(--mp-world-${t}-soft);border-bottom-color:var(--mp-world-${t}-deep)"></span><b>${name}</b>
        <span class="t-footnote secondary">${S.decorOn === k ? "Kullanılıyor" : S.decorOwned.includes(k) ? "Senin" : "★ " + price}</span></button>`).join("")}</div>
      <p class="t-footnote secondary">Yıldızlar yalnızca okuyarak kazanılır: her sabah 1, her masal 1. Aldığın süs hep senin.</p>`,
    footer: `<div class="sk-foot">${on ? `<button class="btn btn-secondary" disabled>Kullanılıyor</button>`
      : owned ? `<button class="btn btn-primary" data-act="decorUse">Kullan</button>`
      : `<button class="btn btn-primary" data-act="decorBuy">★ ${sel[2]} ile al</button>`}</div>`,
  });
};

// ---------- Profil (yeni) ----------
VIEWS.profil = function () {
  const av = typeof avatarById === "function" ? avatarById(S.avatar) : null;
  const face = (cls) => (av ? avatarFace(av, "round " + cls) : cls === "big" ? bust() : '<span class="av">İ</span>');
  const stats = [["star", "Yıldız", S.stars, "yıldız", "yellow"], ["book", "Masallarım", S.library.length, "masal", "lav"],
    ["award", "Rozetler", earnedCount(), "rozet", "peach"]];
  const shown = BADGES.slice(0, 6);
  const world = [["route", "lav", "Okuma yolculuğum", "Haftan ve okuma günlerin", "journey"],
    ["seal", "pink", "Çıkartma albümüm", `${STICKERS.length} çıkartma`, "stickers"],
    ["type", "mint", "Yeni kelimelerim", `${WORDS.length} kelime topladın`, "words"],
    ["map", "sky", "Masal haritam", "Gezdiğin masal dünyaları", "map"],
    ["users", "peach", "Masal ailem", "Anneanne, Dede, Pamuk", "family"],
    ["palette", "green", "Kitaplık renklerim", "Yıldızlarınla süsle", "decor"]];
  let html = `<div class="scroller">
    <div class="h2-hero pf-hero">
      <h1 class="pf-title">Profil</h1>
      <div class="pf-who" aria-label="Kim okuyor?"><button class="me" aria-label="${CHILD}, seçili">${face("av")}${CHILD} ${ic("check")}</button>
        <button class="add" data-act="gate">${ic("plus")}Ekle</button></div>
      <div class="pf-id">
        <img class="pf-ragi" src="${img.ragi("Waving")}" alt="">
        <button class="pf-card" data-act="avatarOpen" aria-label="${CHILD}, Parlak yıldız katı. Profil resmini seçmeyi açar">
          <span class="pf-av">${face("big")}<span class="pen">${ic("pencil")}</span><span class="lv">${ic("star")}</span></span>
          <span class="grow"><span class="t-page">${CHILD}</span><span class="t-supporting secondary" style="font-weight:700">Parlak yıldız katı</span>
            <span class="pf-edit">${ic("pencil")}Profilini düzenle</span></span></button>
      </div>
      <div class="h2-stats">${stats.map(([i, label, value, unit, t]) => `
        <div class="h2-stat"><span class="ic" style="${tone(t)}">${ic(i)}</span>
          <span class="lbl">${label}</span><b>${value}</b><span class="unit">${unit}</span></div>`).join("")}</div>
    </div>
    <div class="sk-body">
      <button class="h2-row" data-act="gate"><span class="tile" style="${tone("sky")}">${ic("shield")}</span>
        <span class="grow"><span class="t-card-title">Büyükler için</span><span class="t-supporting secondary">Ayarlar, abonelik ve okuma özeti</span></span>
        <span class="chev">${ic("right")}</span></button>
      ${sectionH("Rozetlerim", `<button class="link" data-act="skyPage" data-arg="badges">Tümü ${ic("right")}</button>`)}
      <div class="pf-badges">${shown.map(badgeCell).join("")}</div>
      ${sectionH("Masal dünyam")}
      <div class="h2-list">${world.map(([i, t, title, sub, page]) => `
        <button class="h2-row" data-act="skyPage" data-arg="${page}"><span class="tile" style="${tone(t)}">${ic(i)}</span>
          <span class="grow"><span class="t-card-title">${title}</span><span class="t-supporting secondary">${sub}</span></span>
          <span class="chev">${ic("right")}</span></button>`).join("")}</div>
    </div>
  </div>`;
  if (S.avatarPick && typeof avatarPicker === "function") html += avatarPicker();
  return { cls: "home2", html };
};

// Menü satırları artık sayfaları açar.
const MENU_PAGES = { "Rozetlerim": "badges", "Çıkartma albümüm": "stickers", "Yeni kelimelerim": "words",
  "Masal haritam": "map", "Masal ailem": "family", "Kitaplık renklerim": "decor" };
MENU_ITEMS.forEach((item) => { if (MENU_PAGES[item[1]]) item[4] = `data-act="skyPage" data-arg="${MENU_PAGES[item[1]]}"`; });

Object.assign(ACTIONS, {
  skyPage: (v) => { S.menuOpen = false; push({ view: v }); },
  skyBack: () => back(),
  wordsWeek: (a) => { S.wordsWeek = a === "1"; render(); },
  famPick: (k) => { S.famPick = S.famPick === +k ? null : +k; render(); },
  decorPick: (k) => { S.decorPick = +k; render(); },
  decorBuy: () => { S.decorOwned.push(S.decorPick); S.decorOn = S.decorPick; toast("Kitaplığın yeni renginde"); render(); },
  decorUse: () => { S.decorOn = S.decorPick; render(); },
});

// ?sayfa=badges|stickers|words|map|family|decor: menü sayfası açık başlar.
const sayfa = Q.get("sayfa");
if (sayfa && Object.values(MENU_PAGES).includes(sayfa)) { S.tab = "profil"; S.stack.push({ view: sayfa }); }
