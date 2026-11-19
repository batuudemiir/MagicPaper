// Paywall tasarım seçenekleri (19 Kasım 2026, İrem). Karar bekleyen öneri:
// docs/PAYWALL_EKONOMI_PLANI.md (tek plan, ₺149/ay, ₺999/yıl, 7 gün deneme yıllıkta).
// Ortak kurallar: satın alma yetişkin ekranı (Ragi yok), tek birincil düğme
// altta sabit (SE'de kaydırmadan görünür), sahte aciliyet yok, yalnızca bugün
// çalışan özellikler, 3.1.2 metni ve "Aboneliği yönet" her seçenekte.
"use strict";

const PLAN = { ay: { price: "₺149", per: "/ay", note: "İstediğin ay bırak" }, yil: { price: "₺999", per: "/yıl", note: "Ayda ₺83 · günde ₺3'ten az", badge: "%44 avantajlı" } };
S.pwPlan = S.pwPlan || "yil";
const BENEFITS = [
  ["sparkles", "lav", "Gün boyu yeni masal", "Ücretsizde her akşam bir masal; Premium'da istediğin zaman."],
  ["library", "pink", "Bütün klasikler ve seriler", "22 klasik, 5 seri ve 40 bölüm, MagicPaper Original'lar."],
  ["heart", "peach", "Masal ailem", "Anneanne, kardeş, kedisi; sevdikleri masallarda yer alır."],
  ["users", "sky", "Ailedeki her çocuk", "Kardeşlerin her birine kendi kitaplığı."],
  ["sticker", "green", "PDF masal kitabı", "Masallarını yazdırılabilir bir kitapta sakla."],
];
const benefitRows = (n = 5, desc = true) => BENEFITS.slice(0, n).map(([i, t, a, b]) => `<div class="pw-ben">
  <span class="dot" style="background:var(--mp-world-${t}-soft);color:var(--mp-world-${t}-deep)">${ic(i)}</span>
  <span><b class="t-card-title">${a}</b>${desc ? `<span class="t-supporting secondary" style="display:block">${b}</span>` : ""}</span></div>`).join("");
const planCards = (layout = "stack") => `<div class="pw-plans ${layout}">${["yil", "ay"].map((k) => { const p = PLAN[k], on = S.pwPlan === k; return `
  <button class="pw-plan ${on ? "on" : ""}" data-act="pwPick" data-arg="${k}" aria-pressed="${on}">
    ${p.badge ? `<span class="pw-badge t-footnote">${p.badge}</span>` : ""}
    <span class="radio">${on ? ic("check") : ""}</span>
    <span class="grow"><b class="t-card-title">${k === "yil" ? "Yıllık" : "Aylık"}</b><span class="t-footnote secondary" style="font-weight:400">${p.note}</span></span>
    <span class="t-section">${p.price}<small class="t-footnote secondary">${p.per}</small></span></button>`; }).join("")}</div>`;
const trial = () => S.pwPlan === "yil";
const timeline = () => !trial() ? "" : `<div class="pw-time">${[["sparkles", "Bugün", "Her şey açılır, ücret alınmaz."], ["bell", "5. gün", "Deneme bitmeden sana hatırlatırız."], ["star", "7. gün", "Abonelik başlar. Öncesinde tek dokunuşla iptal."]]
  .map(([i, t, d], n) => `<div class="step"><div class="rail"><span class="node ${n ? "" : "first"}">${ic(i)}</span>${n < 2 ? '<span class="line"></span>' : ""}</div>
  <div class="txt"><b class="t-card-title">${t}</b><div class="t-supporting secondary">${d}</div></div></div>`).join("")}</div>`;
const legal = () => `<p class="t-footnote secondary pw-legal">${trial() ? "İlk 7 gün ücretsiz, sonra " : ""}${PLAN[S.pwPlan].price}${PLAN[S.pwPlan].per}. Ödeme Apple Kimliği hesabından alınır. Abonelik, dönem bitmeden en az 24 saat önce iptal edilmezse aynı fiyatla kendiliğinden yenilenir.</p>`;
const footer = () => `<div class="footer-cta pw-foot">
  <button class="btn btn-primary" data-soon="Satın alma (prototip)">${trial() ? "7 gün ücretsiz başla" : "Abone ol"}</button>
  <div class="pw-links t-footnote"><button data-act="paywallClose">Şimdi değil</button><span data-soon="Geri yükle">Geri yükle</span><span data-soon="Aboneliği yönet">Aboneliği yönet</span><span data-soon="Koşullar">Koşullar</span><span data-soon="Gizlilik">Gizlilik</span></div></div>`;
const closeBtn = (light) => `<button class="circle pw-x ${light ? "light" : ""}" data-act="paywallClose" aria-label="Kapat">${ic("x")}</button>`;
const trust = `<div class="pw-trust t-footnote">${ic("lock")}Reklam yok · Veriler satılmaz · İnternetsiz çalışır</div>`;

// A · Kitaplık: sahiplik. Çocuğun gerçek kapakları ve "kitaplığı büyüsün".
VIEWS.payA = () => {
  const covers = (window.MP_CONTENT ? MP_CONTENT.tales.filter((t) => t.cover && !t.seriesID).slice(0, 2).map((t) => t.cover) : []);
  return { html: `${closeBtn()}<div class="scroller" style="padding-bottom:20px">
    <div class="pw-shelf" aria-hidden="true">
      ${covers.map((c) => `<div class="cv" style="background-image:url(${c})"></div>`).join("")}
      ${S.library[0] ? `<div class="cv made" style="background:var(--mp-world-lav-soft);color:var(--mp-world-lav-deep)">${esc(S.library[0].title)}</div>` : ""}
      <div class="cv next">${ic("plus")}</div></div>
    <div class="center"><div class="t-eyebrow" style="color:var(--mp-action-primary)">${esc(CHILD)}'in kitaplığı</div>
      <div class="t-page" style="margin-top:4px">Her akşamın masalı bir kitaplığa dönüşsün</div>
      <p class="t-body secondary" style="margin:8px 0 0">Bu hafta ${Math.max(2, S.library.length)} masal okudunuz. Premium'la ${esc(CHILD)}'in dünyası gün boyu açık.</p></div>
    <div class="pw-list">${benefitRows(5, false)}</div>
    ${planCards()}${timeline()}${trust}${legal()}
  </div>${footer()}` };
};

// B · Akşam ritüeli: kimlik ve duygu. Gece sahnesi, haftanın gerçeği, dürüst karşılaştırma.
VIEWS.payB = () => ({ html: `<div class="scroller" style="padding:0 var(--mp-space-screen-h) 20px">
    <div class="pw-night" style="background-image:url(${img.night})">${closeBtn(true)}
      <div class="pw-night-txt"><div class="t-cover" style="color:#fff">Her akşam,<br>birlikte bir masal</div>
        <div class="t-supporting" style="color:rgba(255,255,255,.88)">Bu hafta 4 akşam birlikte okudunuz.</div></div></div>
    <table class="pw-compare"><thead><tr><th></th><th>Ücretsiz</th><th class="pro">Premium</th></tr></thead><tbody>
      ${[["Akşam masalı", "Her akşam 1", "Gün boyu"], ["Kendi masallarını okuma", "✓", "✓"], ["Sesli okuma", "✓", "✓"], ["Klasikler ve seriler", "Seçkiler", "Hepsi"], ["Masal ailem", "1 kişi", "Herkes"], ["Çocuk profili", "1", "Her çocuk"], ["PDF masal kitabı", "–", "✓"]]
        .map(([a, f, p]) => `<tr><td>${a}</td><td>${f}</td><td class="pro">${p}</td></tr>`).join("")}
    </tbody></table>
    <p class="t-footnote secondary" style="font-weight:400;margin:8px 2px 0">Yıldızlar, rozetler ve çocuğun yazdığı masallar her planda onun.</p>
    ${planCards("row")}${trust}${legal()}
  </div>${footer()}` });

// C · Sade ve güven: Apple'ın kendi ekranları gibi kısa; fiyat en üstte, deneme takvimi.
VIEWS.payC = () => ({ html: `${closeBtn()}<div class="scroller" style="padding-bottom:20px">
    <div class="t-page" style="margin-top:56px">MagicPaper Premium</div>
    <p class="t-body secondary" style="margin:6px 0 16px">Ritüel ücretsiz kalır. Premium kitaplığı büyütür.</p>
    ${planCards("row")}
    <div class="pw-checks">${BENEFITS.map(([, , a]) => `<div>${ic("check")}<span class="t-body">${a}</span></div>`).join("")}</div>
    ${timeline()}${trust}${legal()}
  </div>${footer()}` });

Object.assign(ACTIONS, {
  pwPick: (k) => { S.pwPlan = k; render(); },
  payOpen: (v) => { S.modal = { view: v, from: S.modal }; render("cover"); },
});
// Derin bağlantı: ?ortu=payA|payB|payC
{ const o = new URLSearchParams(location.search).get("ortu");
  if (["payA", "payB", "payC"].includes(o)) { S.os = "app"; S.onboarded = true; S.modal = { view: o, from: { view: "parent" } }; } }
