// Telefonun ana ekranı ve uygulamanın ilk açılışı (19 Kasım 2026).
// Ana ekran iOS'un bir taklidi değil, yalnızca sahne: genel simgeler, gerçek
// uygulama adları yok. Uygulama simgesi MagicPaper'ın kendi AppIcon'u.
// İlk açılış sırası ve metinleri koddan: OnboardingView, AccountCopy,
// AccountSignInView, ParentConsentView, ProfileCreationView, FirstRunView.
// (Sıra: MagicPaperApp.swift → AppGate: karşılama → giriş → onay → profil → ilk masal.
// "Neleri sever" adımı uygulamada şu an gizli olduğu için burada da yok.)
"use strict";

const OS = {};
const APP_ICON = "../../MagicPaper/Assets.xcassets/AppIcon.appiconset/AppIcon.png";
const OB_ORDER = ["welcome", "signin", "consent", "profile"];

// Türkçe ilgi eki: İrem → İrem'in, Ali → Ali'nin, Duru → Duru'nun
function gen(name) {
  const v = (name.match(/[aeıioöuüAEIİOÖUÜ]/g) || ["e"]).pop().toLocaleLowerCase("tr");
  const suf = { a: "ın", ı: "ın", e: "in", i: "in", o: "un", u: "un", ö: "ün", ü: "ün" }[v];
  return /[aeıioöuü]$/i.test(name) ? `${name}'n${suf}` : `${name}'${suf}`;
}

// ---------- Ana ekran ----------
const GENERIC = [
  ["Takvim", "clock", "#E86A5C"], ["Fotoğraflar", "sparkles", "#F2B84B"], ["Kamera", "profile", "#7A7F8C"], ["Hava", "moon", "#4E8FE0"],
  ["Notlar", "type", "#F4C542"], ["Haritalar", "tent", "#5BB36A"], ["Müzik", "volume", "#E35B7A"], ["Saat", "clock", "#2E2A35"],
  ["Kitaplar", "book", "#F08A3C"], ["Sağlık", "heart", "#EF5D73"], ["Ayarlar", "grid", "#8E8E99"],
];
const DOCK = [["Telefon", "bell", "#4CC46A"], ["Mesajlar", "users", "#4CC46A"], ["Tarayıcı", "search", "#3F8CF0"], ["Posta", "sticker", "#3F8CF0"]];
const tile = ([name, icon, color], label = true) => `<button class="ios-app" data-os="noop" aria-label="${name}">
  <span class="ios-ico" style="background:${color}">${ic(icon)}</span>${label ? `<span class="ios-lbl">${name}</span>` : ""}</button>`;
OS.springboard = () => `<div class="ios-home ${S.closing ? "fade-in" : ""}">
  <div class="statusbar light"><span>9:41</span><span>●●● ▮</span></div>
  <div class="ios-grid">
    ${GENERIC.slice(0, 6).map((a) => tile(a)).join("")}
    <button class="ios-app" id="mp-icon" data-os="launch" aria-label="MagicPaper">
      <span class="ios-ico mp"><img src="${APP_ICON}" alt=""></span><span class="ios-lbl">MagicPaper</span></button>
    ${GENERIC.slice(6).map((a) => tile(a)).join("")}
  </div>
  <div class="ios-search">${ic("search")}Ara</div>
  <div class="ios-dock">${DOCK.map((a) => tile(a, false)).join("")}</div>
</div>`;
OS.bindHome = () => {
  app.querySelectorAll('[data-os="launch"]').forEach((b) => b.onclick = () => {
    const r = b.querySelector(".ios-ico").getBoundingClientRect(), a = app.getBoundingClientRect();
    app.style.setProperty("--ox", `${r.left - a.left + r.width / 2}px`);
    app.style.setProperty("--oy", `${r.top - a.top + r.height / 2}px`);
    S.os = "app"; S.closing = false; render("launch");
  });
  app.querySelectorAll('[data-os="noop"]').forEach((b) => b.onclick = () => {
    b.animate([{ transform: "scale(1)" }, { transform: "scale(.9)" }, { transform: "scale(1)" }], { duration: 220 });
  });
};
// Ev çizgisi: dokununca uygulama küçülerek ana ekrana döner; durum korunur (gerçek iOS gibi).
OS.homeIndicator = () => `<button class="home-ind" data-act="osHome" aria-label="Ana ekrana dön"><i></i></button>`;
ACTIONS.osHome = () => {
  const layer = app.querySelector(".layer");
  const done = () => { S.os = "home"; S.closing = true; render(); };
  if (!layer || matchMedia("(prefers-reduced-motion: reduce)").matches) return done();
  layer.classList.add("launch-out"); setTimeout(done, 260);
};

// ---------- İlk açılış ----------
OS.form = { name: "", band: "5-6", color: 0, agree: false, share: false };
const AV = ["#4E9A4A", "#6A47B8", "#E0663E", "#3F7FD1", "#D3487A", "#C9932A"];
const obNext = () => { const i = OB_ORDER.indexOf(S.ob); S.ob = OB_ORDER[i + 1]; render("push"); };
const obBack = () => { const i = OB_ORDER.indexOf(S.ob); S.ob = OB_ORDER[Math.max(0, i - 1)]; render("fade"); };
Object.assign(ACTIONS, {
  obNext, obBack,
  obAgree: () => { OS.form.agree = !OS.form.agree; render(); },
  obShare: () => { OS.form.share = !OS.form.share; render(); },
  obBand: (b) => { OS.form.band = b; render(); },
  obColor: (i) => { OS.form.color = +i; render(); },
  obSignIn: () => { toast("Prototip: giriş yapılmış sayıldı"); setTimeout(obNext, 500); },
  obProfileDone: () => {
    CHILD = OS.form.name.trim().replace(/^./, (c) => c.toLocaleUpperCase("tr"));
    S.onboarded = true;
    S.library = []; S.stars = 0; S.finished = 0; S.tab = "home";
    S.modal = { view: "prep", firstRun: true, mode: "bedtime", comp: "kaplumbağa", fam: [], step: 0, title: `${CHILD} ve Uykucu Kaplumbağa` };
    render("push");
  },
  toReminder: () => { S.modal = { view: "reminder" }; render("fade"); },
  reminderDone: (ok) => { close(); go("home"); if (ok === "1") toast("Her akşam 20.30'da hatırlatırız"); },
});
OS.after = {
  profile: () => {
    const inp = document.getElementById("ob-name");
    if (!inp) return;
    inp.value = OS.form.name;
    inp.oninput = () => { OS.form.name = inp.value; const b = document.getElementById("ob-go"); b.disabled = !inp.value.trim(); };
  },
};
OS.ob = {
  welcome: () => ({ html: `<div class="scroller ob-center" style="padding-bottom:30px">
      <img src="${img.ragi("OnBook")}" alt="" style="width:160px;margin-top:24px">
      <div class="t-cover center">Her çocuğun kendi masal dünyası</div>
      <p class="t-body secondary center" style="margin:0">Kahramanı çocuğun olan masallar. Her akşam yeniden yazılır, kitaplığında kalır.</p>
      <div style="width:100%;display:grid;gap:8px;margin-top:8px">
        <button class="btn btn-primary" style="min-height:64px" data-act="obNext">Başlayalım</button>
        <p class="t-footnote secondary center" style="margin:0">Reklam yok, satın alma çocuğa kapalı. Masallar cihazda yazılır.</p></div>
    </div>` }),
  signin: () => ({ html: `<div class="topbar"><button class="circle" data-act="obBack" aria-label="Geri">${ic("left")}</button></div>
    <div class="scroller ob-center" style="padding-bottom:30px">
      <img src="${APP_ICON}" alt="" style="width:88px;border-radius:20px;margin-top:20px">
      <div class="t-page center">Ebeveyn hesabını oluştur</div>
      <p class="t-body secondary center" style="margin:0">Hesap senin adına açılır. Çocuğun hiçbir zaman giriş yapmaz, şifre ya da e-posta girmez.</p>
      <div style="width:100%;display:grid;gap:12px;margin-top:12px">
        <button class="btn" style="min-height:54px;background:var(--mp-text-primary);color:#fff" data-act="obSignIn">Apple ile devam et</button>
        <button class="btn" style="min-height:54px;background:#fff;box-shadow:inset 0 0 0 2px var(--mp-border-outline)" data-act="obSignIn"><b style="color:#4285F4">G</b>&nbsp;Google ile devam et</button></div>
      <p class="t-footnote secondary center" style="margin:6px 0 0;font-weight:400">Devam ederek <u>Kullanım koşulları</u> ve <u>Gizlilik politikası</u>'nı kabul etmiş olursun.</p>
    </div>` }),
  consent: () => {
    const f = OS.form;
    const row = (icon, t, b) => `<div class="ob-row"><span class="tile">${ic(icon)}</span><span><b class="t-card-title">${t}</b><span class="t-supporting secondary" style="display:block">${b}</span></span></div>`;
    return { html: `<div class="topbar"><button class="circle" data-act="obBack" aria-label="Geri">${ic("left")}</button><span class="t-section">Ebeveyn onayı</span></div>
      <div class="scroller" style="padding-bottom:20px">
        <div class="t-page" style="margin-top:6px">Çocuğunun verileri güvende</div>
        <p class="t-body secondary" style="margin:6px 0 18px">Masal yazabilmek için çok az şey bilmemiz gerekiyor. Neyi neden tuttuğumuz aşağıda.</p>
        <div class="card" style="padding:4px 16px">
          ${row("user", "Sadece ad ve yaş aralığı", "Fotoğraf, konum ya da ses kaydı istemiyoruz.")}
          ${row("lock", "Reklam ve takip yok", "Uygulamada reklam ve üçüncü taraf takip aracı yok.")}
          ${row("x", "İstediğin an silebilirsin", "Ayarlar'dan tüm verileri tek dokunuşla silersin.")}</div>
        <div class="card ob-row" style="margin-top:14px;padding:14px 16px"><span style="flex:1"><b class="t-card-title">Okuma bilgisini paylaş</b>
          <span class="t-supporting secondary" style="display:block">Hangi masalların bitirildiği; ad, yaş ve hesap bilgisi olmadan.</span></span>
          <button class="switch ${f.share ? "on" : ""}" data-act="obShare" aria-label="Okuma bilgisini paylaş"></button></div>
        <button class="link-btn" data-soon="Aydınlatma metni">Aydınlatma metni</button>
        <button class="ob-check" data-act="obAgree" aria-pressed="${f.agree}"><span class="box ${f.agree ? "on" : ""}">${f.agree ? ic("check") : ""}</span><span class="t-card-title">Onaylıyorum</span></button>
      </div>
      <div class="footer-cta"><button class="btn btn-primary" data-act="obNext" ${f.agree ? "" : "disabled"}>Onayla ve devam et</button></div>` };
  },
  profile: () => {
    const f = OS.form;
    return { html: `<div class="topbar"><button class="circle" data-act="obBack" aria-label="Geri">${ic("left")}</button><span class="t-section">Çocuk profili</span></div>
      <div class="scroller" style="padding-bottom:20px">
        <div class="t-page" style="margin-top:6px">Çocuğunun adı ne?</div>
        <input id="ob-name" class="ob-input" placeholder="Örn. Elif" autocomplete="off" aria-label="Çocuğun adı">
        <p class="t-footnote secondary" style="margin:6px 4px 0;font-weight:400">Masallarda bu isim geçecek</p>
        <div class="t-card-title" style="margin:26px 0 10px">Yaş aralığı</div>
        <div class="pick">${["3-4", "5-6", "7-8", "9-10"].map((b) => `<button class="chip ${f.band === b ? "on" : ""}" data-act="obBand" data-arg="${b}">${b} yaş</button>`).join("")}</div>
        <p class="t-footnote secondary" style="margin:8px 4px 0;font-weight:400">Masalın dili ve uzunluğu yaşa göre ayarlanır.</p>
        <div class="t-card-title" style="margin:26px 0 10px">Avatar rengi</div>
        <div style="display:flex;gap:12px;flex-wrap:wrap">${AV.map((c, i) => `<button class="ob-color ${f.color === i ? "on" : ""}" style="background:${c}" data-act="obColor" data-arg="${i}" aria-label="Renk ${i + 1}"></button>`).join("")}</div>
      </div>
      <div class="footer-cta"><button id="ob-go" class="btn btn-primary" data-act="obProfileDone" ${f.name.trim() ? "" : "disabled"}>Devam et</button></div>` };
  },
};

// İlk masal: hazırlık başlığı "<ad>'ın ilk masalı yazılıyor", vazgeçme "Sonra oku".
const basePrep = VIEWS.prep;
VIEWS.prep = (m) => {
  const v = basePrep(m);
  if (m.firstRun) v.html = v.html.replace("Masal yazılıyor", `${gen(CHILD)} ilk masalı yazılıyor`).replace('data-act="close" aria-label="Vazgeç"', 'data-act="prepLater" aria-label="Sonra oku"');
  return v;
};
const basePrepOpen = ACTIONS.prepOpen;
ACTIONS.prepOpen = () => { const first = S.modal.firstRun; basePrepOpen(); if (first) S.modal.firstRun = true; };
// İlk masalın sonu: hatırlatma bir kez, masal bittikten sonra sorulur (FirstRunView).
const baseEnding = VIEWS.ending;
VIEWS.ending = (m) => {
  const v = baseEnding(m);
  if (m.firstRun) v.html = v.html.replace(/<button class="btn btn-primary"[\s\S]*<\/button>\s*<\/div>\s*$/, `<button class="btn btn-primary" style="max-width:320px" data-act="toReminder">Devam et</button></div>`);
  return v;
};
const baseFinish = ACTIONS.finish;
ACTIONS.finish = () => { const first = S.modal.firstRun; baseFinish(); S.modal.firstRun = first; render(); };
VIEWS.reminder = () => ({ html: `<div class="scroller ob-center" style="padding-bottom:30px;justify-content:center">
    <img src="${img.ragi("Sleepy")}" alt="" style="width:140px">
    <div class="t-page center">Masal saatini hatırlatalım mı?</div>
    <p class="t-body secondary center" style="margin:0">Her akşam seçtiğin saatte tek bir hatırlatma. Başka bildirim göndermeyiz.</p>
    <div style="width:100%;display:grid;gap:6px;margin-top:10px">
      <button class="btn btn-primary" data-act="reminderDone" data-arg="1">Hatırlat</button>
      <button class="btn btn-ghost" data-act="reminderDone" data-arg="0">Şimdi değil</button></div>
    <p class="t-footnote secondary center" style="margin:0;font-weight:400">İzni sonra Ebeveyn bölümünden değiştirebilirsin.</p>
  </div>` });

// ?ilk=welcome|signin|consent|profile: ilk açılışın bir adımına doğrudan (kontrol ve tasarım için).
{ const ilk = new URLSearchParams(location.search).get("ilk");
  if (OS.ob[ilk]) { S.os = "app"; S.onboarded = false; S.ob = ilk; }
  if (ilk === "reminder") { S.os = "app"; S.onboarded = true; S.modal = { view: "reminder" }; } }
