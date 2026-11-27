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

// TEK PAYWALL (21 Kasım 2026, İrem): "C · Sade ve güven" olduğu gibi; A ve B
// seçenekleri kaldırıldı. SwiftUI karşılığı: Screens/PaywallView.swift.
// Yıllık varsayılan (İrem'in kararı). Büyükler için → Abonelik, ?ortu=paywall.
VIEWS.paywall = () => ({ html: `${closeBtn()}<div class="scroller" style="padding-bottom:20px">
    <div class="t-page" style="margin-top:56px">MagicPaper Premium</div>
    <p class="t-body secondary" style="margin:6px 0 16px">Ritüel ücretsiz kalır. Premium kitaplığı büyütür.</p>
    ${planCards("row")}
    <div class="pw-checks">${BENEFITS.map(([, , a]) => `<div>${ic("check")}<span class="t-body">${a}</span></div>`).join("")}</div>
    ${timeline()}${trust}${legal()}
  </div>${footer()}` });

Object.assign(ACTIONS, { pwPick: (k) => { S.pwPlan = k; render(); } });
