// Profil avatarı (23 Kasım 2026, İrem): uygulamadaki ProfileAvatar ve
// ProfileAvatarPicker'ın prototipi. Profil kartına dokununca "Profilini düzenle"
// zıplayarak açılır; Ragi, Tarçın ve Kestane'nin yüzlerinden seçilir. Görseller
// uygulamanın asset kataloğundan (Avatars/*) okunur. Liste uygulamayla aynı sırada.
"use strict";

const AVATAR_TONES = {
  lav: "--mp-world-lav-soft", yellow: "--mp-world-yellow-soft", mint: "--mp-world-mint-soft",
  sky: "--mp-world-sky-soft", pink: "--mp-world-pink-soft", peach: "--mp-world-peach-soft", green: "--mp-world-green-soft",
};
const AVATARS = [
  ["ragi-happy", "Neşeli Ragi", "ragi", "yellow"], ["ragi-calm", "Sakin Ragi", "ragi", "lav"],
  ["ragi-waving", "El sallayan Ragi", "ragi", "mint"], ["ragi-curious", "Meraklı Ragi", "ragi", "sky"],
  ["ragi-reading", "Okuyan Ragi", "ragi", "pink"], ["ragi-surprised", "Şaşıran Ragi", "ragi", "peach"],
  ["ragi-front", "Gülümseyen Ragi", "ragi", "green"], ["ragi-onbook", "Kitapçı Ragi", "ragi", "yellow"],
  ["ragi-pencil", "Yazan Ragi", "ragi", "lav"], ["ragi-thinking", "Düşünen Ragi", "ragi", "mint"],
  ["ragi-peek", "Saklanan Ragi", "ragi", "sky"], ["ragi-threequarter", "Yandan Ragi", "ragi", "pink"],
  ["ragi-walking", "Yürüyen Ragi", "ragi", "peach"], ["ragi-sleepy", "Uykulu Ragi", "ragi", "green"],
  ["ragi-sleeping", "Uyuyan Ragi", "ragi", "lav"],
  ["tarcin-standing", "Tarçın", "tarcin", "mint"], ["tarcin-sitting", "Bakan Tarçın", "tarcin", "sky"],
  ["tarcin-resting", "Mutlu Tarçın", "tarcin", "lav"],
  ["kestane-neutral", "Kestane", "kestane", "yellow"], ["kestane-looking", "Merak eden Kestane", "kestane", "mint"],
  ["kestane-waiting", "Bekleyen Kestane", "kestane", "pink"],
].map(([id, name, character, tone]) => ({ id, name, character, tone }));
const AVATAR_CHARACTERS = [["ragi", "Ragi"], ["tarcin", "Tarçın"], ["kestane", "Kestane"]];
const avatarSrc = (id) => A + `Avatars/${id}.imageset/${id}.png`;
const avatarById = (id) => AVATARS.find((a) => a.id === id);

Object.assign(S, { avatar: null, avatarPick: false, avatarDraft: null, avatarTab: "ragi", avatarBump: false, avatarTile: null });

/** Yuvarlak ya da kare yüz; avatar yoksa eski büst. */
function avatarFace(av, cls = "") {
  return `<span class="ap-face ${cls}" style="background:var(${AVATAR_TONES[av.tone]})"><img src="${avatarSrc(av.id)}" alt=""></span>`;
}

const legacyBust = bust;
bust = function () {
  const av = avatarById(S.avatar);
  return av ? avatarFace(av, "round bust") : legacyBust();
};

function avatarPicker() {
  const draft = avatarById(S.avatarDraft);
  const tiles = AVATARS.filter((a) => a.character === S.avatarTab).map((a) => {
    const on = a.id === S.avatarDraft;
    return `<button class="ap-tile ${on ? "on" : ""} ${on && S.avatarTile === a.id ? "pop" : ""}" data-act="avatarPick" data-arg="${a.id}"
      aria-label="${esc(a.name)}" aria-pressed="${on}">${avatarFace(a)}${on ? `<span class="ap-check">${ic("check")}</span>` : ""}</button>`;
  }).join("");
  return `<div class="ap-scrim ${S.avatarBump ? "fade" : ""}" data-act="avatarClose" aria-hidden="true"></div>
    <div class="ap-panel ${S.avatarBump ? "bump" : ""}" role="dialog" aria-modal="true" aria-label="Profilini düzenle">
      <div class="ap-head"><h2>Profilini düzenle</h2><button class="circle" data-act="avatarClose" aria-label="Kapat">${ic("x")}</button></div>
      <div class="ap-me">${draft ? avatarFace(draft, "big") : `<span class="ap-face big">${legacyBust()}</span>`}
        <span><span class="t-page">${CHILD}</span><span class="t-supporting secondary">${draft ? esc(draft.name) : "Bir yüz seç"}</span></span></div>
      <div class="ap-tabs">${AVATAR_CHARACTERS.map(([k, t]) => `<button class="chip ${k === S.avatarTab ? "on" : ""}" data-act="avatarTab" data-arg="${k}">${t}</button>`).join("")}</div>
      <div class="ap-grid">${tiles}</div>
      <button class="btn btn-primary" data-act="avatarSave" ${!S.avatarDraft || S.avatarDraft === S.avatar ? "disabled" : ""}>Kaydet</button>
    </div>`;
}

// Profil: kimlik kartı avatar penceresini açar ("Kahramanını giydir" kalktı).
P.pencil = '<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>';

const legacyProfil = VIEWS.profil;
VIEWS.profil = function () {
  const v = legacyProfil();
  const card = `<button class="card hero-card" data-act="avatarOpen" aria-label="${CHILD}, profil resmini seç">
      <span class="hero-av">${bust()}<span class="pen">${ic("pencil")}</span></span>
      <span style="display:grid;gap:6px;text-align:left"><span class="t-page">${CHILD}</span>
        <span class="t-supporting" style="display:flex;gap:6px;align-items:center"><span style="color:var(--mp-brand-star)">★</span> ${S.stars} yıldız</span></span></button>`;
  let html = v.html.replace(/<div class="card hero-card">[\s\S]*?<\/div><\/div>/, card);
  html = html.replace('<span class="av">İ</span>', S.avatar ? avatarFace(avatarById(S.avatar), "round av") : '<span class="av">İ</span>');
  if (S.avatarPick) html += avatarPicker();
  return { ...v, html };
};

Object.assign(ACTIONS, {
  avatarOpen: () => { Object.assign(S, { avatarPick: true, avatarDraft: S.avatar, avatarTab: avatarById(S.avatar)?.character || "ragi", avatarBump: true, avatarTile: null }); render(); S.avatarBump = false; },
  avatarClose: () => {
    const panel = app.querySelector(".ap-panel");
    if (panel && !matchMedia("(prefers-reduced-motion: reduce)").matches) {
      panel.classList.add("out"); app.querySelector(".ap-scrim")?.classList.add("out");
      setTimeout(() => { S.avatarPick = false; render(); }, 170);
    } else { S.avatarPick = false; render(); }
  },
  avatarTab: (k) => { S.avatarTab = k; S.avatarTile = null; render(); },
  avatarPick: (id) => { S.avatarDraft = id; S.avatarTile = id; render(); S.avatarTile = null; },
  avatarSave: () => { S.avatar = S.avatarDraft; toast("Profilin yenilendi"); ACTIONS.avatarClose(); },
});

// ?ekran=profil&avatar=ac: pencere açık başlar (önizleme ve ekran görüntüsü).
if (Q.get("avatar") === "ac") Object.assign(S, { avatarPick: true, avatarBump: true, avatarDraft: "ragi-happy" });
