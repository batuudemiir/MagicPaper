// Ana sayfa "Okuma köşesi" (21 Kasım 2026, İrem; GPT teslimi). SwiftUI karşılığı:
// Views/HomeView.swift + DesignSystem/Pastel/MPHomeReadingNook.swift.
// Sıra: selam + avatar, okuma köşesi sahnesi, "Bu akşam" daveti, "Başka bir dünya
// seç", "Kitaplığından" (en çok iki kitap), "Masal bul" (arama + tek öneri).
"use strict";

const NOOK = "../../MagicPaper/Assets.xcassets/Scenes/";
const WORLD_ART = { learning: NOOK + "homeWorldLearning.imageset/homeWorldLearning.png", adventure: NOOK + "homeWorldAdventure.imageset/homeWorldAdventure.png" };

VIEWS.home = () => {
  const h = new Date().getHours();
  const greet = h >= 5 && h < 11 ? "Günaydın," : h >= 11 && h < 17 ? "İyi günler," : h >= 17 && h < 22 ? "İyi akşamlar," : "İyi geceler,";
  const bedtime = h >= 19 || h < 5;
  const half = S.library.find((s) => s.half);
  const invite = half
    ? { eyebrow: "Kaldığın yerden", title: half.title, sub: "Sayfa 3 / 6", btn: "Okumaya devam et", act: `data-act="openStory" data-arg="${esc(half.title)}"` }
    : bedtime
      ? { eyebrow: "Saat 20.30", title: "Uyku masalı zamanı", btn: "Uyku masalı yaz", act: 'data-act="mode" data-arg="bedtime"' }
      : { eyebrow: "Bu akşam", title: "Bir masal daha?", btn: "Yeni masal yaz", act: 'data-act="create"' };
  const worlds = Object.entries(MODES).filter(([k]) => !(bedtime && !half && k === "bedtime"));
  const C = window.MP_CONTENT || { tales: [], originals: [] };
  const classic = C.tales.find((t) => t.cover && !t.seriesID && S.progress && S.progress[t.id] != null);
  const shelf = S.library.filter((s) => !half || s.title !== half.title).slice(0, classic ? 1 : 2);
  const pick = C.originals[0];
  const book = (cover, title, status, attrs) => `<button class="nook-book" ${attrs}>${cover}<b class="t-card-title">${esc(title)}</b><span class="t-supporting secondary">${status}</span></button>`;
  return { cls: "nook-page", html: `<div class="scroller nook">
    <div class="tab-head nook-head"><h1>${greet} ${esc(CHILD)}</h1>
      <button class="nook-av" data-go="profil" aria-label="${esc(CHILD)} profilini aç">${ic("user")}</button></div>
    <img class="nook-scene" src="${NOOK}homeReadingNook.imageset/homeReadingNook.jpg" alt="">
    <div class="nook-invite"><span class="t-card-title">${invite.eyebrow}</span><div class="t-cover">${esc(invite.title)}</div>
      ${invite.sub ? `<span class="t-supporting secondary">${invite.sub}</span>` : ""}
      <button class="btn btn-primary" style="min-height:64px;margin-top:12px" ${invite.act}>${ic("book")}${invite.btn}</button></div>
    <div class="section-h"><h2>Başka bir dünya seç</h2></div>
    <div class="nook-worlds" style="grid-template-columns:repeat(${worlds.length},1fr)">${worlds.map(([k, m]) => `
      <button class="nook-world" style="background:var(${m.soft})" data-act="createModeDirect" data-arg="${k}">
        ${WORLD_ART[k] ? `<img src="${WORLD_ART[k]}" alt="">` : `<span class="nook-world-ico" style="color:var(${m.deep})">${ic(m.icon)}</span>`}
        <span class="t-card-title">${m.title}</span></button>`).join("")}</div>
    ${shelf.length || classic ? `<div class="section-h"><h2>Kitaplığından</h2><button class="link" data-go="kitaplik">Tümünü gör ${ic("right")}</button></div>
    <div class="nook-shelf">
      ${classic ? book(`<div class="cv" style="background-image:url(${classic.cover});background-position:${classic.focus.x * 100}% ${classic.focus.y * 100}%"><span class="badge">◔ Yarım</span></div>`, classic.title, "Okumaya başladın", `data-act="readItem" data-arg="${classic.id}"`) : ""}
      ${shelf.map((s) => { const m = MODES[s.mode]; return book(`<div class="cv made" style="background:var(${m.soft});color:var(${m.deep})">${esc(s.title)}</div>`, s.title, s.half ? "Sayfa 3 / 6" : "Henüz okunmadı", `data-act="openStory" data-arg="${esc(s.title)}"`); }).join("")}
    </div>` : ""}
    <div class="section-h"><h2>Masal bul</h2></div>
    <button class="nook-find" data-act="openSearchTab">${ic("search")}<span class="t-body secondary">Masal adı veya konu</span></button>
    ${pick ? `<button class="nook-pick" data-act="openPick" data-arg="${pick.id}"><div class="cv" style="background-image:url(${pick.cover})"></div>
      <span><b class="t-card-title">${esc(pick.title)}</b><span class="t-supporting secondary" style="display:block">MagicPaper Original · ${pick.minutes} dk</span></span>${ic("right")}</button>` : ""}
  </div><div class="nook-compact" aria-hidden="true"><span class="t-section">Ana sayfa</span></div>` };
};

Object.assign(ACTIONS, {
  openSearchTab: () => { S.tab = "masallar"; S.stack = [{ view: "search", q: "" }]; render("push"); },
  openPick: (id) => { S.tab = "masallar"; S.stack = [{ view: "tale", id }]; render("push"); },
});

// Kaydırınca üstte küçük "Ana sayfa" (karusel kancasının üstüne eklenir).
{ const prev = VIEWS.after.__tab;
  VIEWS.after.__tab = () => {
    if (prev) prev();
    const sc = document.querySelector(".nook"), bar = document.querySelector(".nook-compact");
    if (!sc || !bar) return;
    sc.onscroll = () => bar.classList.toggle("on", sc.scrollTop > 60);
  }; }
