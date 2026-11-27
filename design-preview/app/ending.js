// Masal sonu · yeni tasarım (23 Kasım 2026, İrem; referans: oyunlardaki "Level up"
// ekranı, bizim dilimizle). Mor zemin, ışık hüzmeleri önünde sevinçli Ragi,
// "Bravo, <ad>!", tek eylem "Bir masal daha", yatay kayan kazanılanlar (masalın
// rozeti, çıkartması, haftalık okuma dakikası, yıldız) ve "Ana sayfaya dön".
// Yalnızca kazanılan gösterilir; sayı baskısı, "az kaldı" yok (ilke 7).
"use strict";

P.clock2 = '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>';

VIEWS.ending = function () {
  const cards = [
    ["sticker", "Çıkartma", "Albümüne eklendi", "--mp-world-pink"],
    ["award", "Yeni rozet", "İlk masal", "--mp-world-yellow"],
    ["clock2", "+9 dakika", "Bu hafta 34 dakika", "--mp-world-mint"],
    ["star", "+1 yıldız", `Toplam ${S.stars} yıldız`, "--mp-world-lav"],
  ];
  return { cls: "ending2", html: `<div class="en-wrap">
    <h1 class="en-title">Masal bitti!</h1>
    <div class="en-mid">
    <div class="en-hero" aria-hidden="true">
      <span class="en-rays"></span><span class="en-glow"></span>
      <i class="en-spark s1">✦</i><i class="en-spark s2">✦</i><i class="en-spark s3">✦</i>
      <img src="${A}Brand/mascotCheer.imageset/mascotCheer.png" alt="">
    </div>
    <h2 class="en-bravo">Bravo, ${CHILD}!</h2>
    <button class="en-again" data-act="again">${ic("wand")}Bir masal daha</button>
    <div class="en-cards" role="list" aria-label="Kazandıkların">${cards.map(([i, t, s, tone]) => `
      <div class="en-card" role="listitem"><span class="tile" style="background:var(${tone}-soft);color:var(${tone}-deep)">${ic(i)}</span>
        <b>${t}</b><span>${s}</span></div>`).join("")}</div>
    </div>
    <button class="en-home" data-act="goodnight">${ic("home")}Ana sayfaya dön</button>
  </div>` };
};

// Masalın rozeti ortada başlar; yanlarda diğer kartlar kısmen görünür.
VIEWS.after.ending = () => {
  const row = app.querySelector(".en-cards"), card = row?.children[1];
  if (card) row.scrollLeft = card.offsetLeft - (row.clientWidth - card.clientWidth) / 2;
};
