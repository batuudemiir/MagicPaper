// Ana sayfa · yeni yön denemesi (23 Kasım 2026, İrem; referans: alışkanlık
// uygulaması ekranı). Üstte mor gökten beyaza inen başlık: solda menü, yanında
// bildirim ve arama (cam), büyük selam, sağda konuşan Ragi, üç bilgi kartı ve
// koyu mor "bu akşamın masalı" kartı. Altı bizim dilimiz, referansın düzeniyle:
// liste satırları. Gece/gündüz yok, tek görünüm. Eski ana sayfa: ?anasayfa=eski
"use strict";

P.menu = '<line x1="4" x2="20" y1="7" y2="7"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="17" y2="17"/>';

if (Q.get("anasayfa") !== "eski") {
  VIEWS.home = function () {
    const half = S.library.find((s) => s.half);
    const stats = [
      ["star", "Yıldız", S.stars, "yıldız", "--mp-world-yellow-soft", "--mp-world-yellow-deep"],
      ["flame", "Okuma", Math.max(1, S.finished), "gün üst üste", "--mp-world-peach-soft", "--mp-world-peach-deep"],
      ["book", "Masallarım", S.library.length, "masal", "--mp-world-lav-soft", "--mp-world-lav-deep"],
    ];
    const done = half ? 3 : 0, total = 5;
    return { cls: "home2", html: `<div class="scroller">
      <div class="h2-hero">
        <div class="h2-top">
          <button class="glass round" data-soon="Menü" aria-label="Menü">${ic("menu")}</button>
          <span class="glass pill">
            <button data-soon="Bildirimler" aria-label="Bildirimler">${ic("bell")}<i class="dot"></i></button>
            <button data-soon="Masal arama" aria-label="Masal ara">${ic("search")}</button>
          </span>
          <span class="h2-say glass">Küçük bir masalla başlayalım!</span>
        </div>
        <div class="h2-hello">
          <h1>Merhaba, ${CHILD}</h1>
          <p>Bu akşam hangi masalı okuyalım?</p>
        </div>
        <img class="h2-ragi" src="${img.ragi("Waving")}" alt="">
        <div class="h2-stats">${stats.map(([i, label, value, unit, soft, deep]) => `
          <div class="h2-stat"><span class="ic" style="background:var(${soft});color:var(${deep})">${ic(i)}</span>
            <span class="lbl">${label}</span><b>${value}</b><span class="unit">${unit}</span></div>`).join("")}</div>
      </div>

      <div class="h2-tonight">
        <img src="${img.ragi(half ? "Reading" : "Sleepy")}" alt="">
        <div class="body">
          <span class="eye">${half ? "Kaldığın yerden" : "Saat 20.30"}</span>
          <b>${half ? esc(half.title) : "Uyku masalı zamanı"}</b>
          ${half ? `<span class="bar">${Array.from({ length: total }, (_, k) => `<i class="${k < done ? "on" : ""} ${k === done - 1 ? "now" : ""}"></i>`).join("")}<span>${done}/${total}</span></span>` : ""}
          <span class="row">
            <span class="tag">${half ? "Sayfa 3 / 5" : "Kısa ve sakin"}</span>
            <button class="go" data-act="${half ? "openStory" : "mode"}" data-arg="${half ? esc(half.title) : "bedtime"}">${half ? `${ic("play")}Devam et` : `${ic("moon")}Uyku masalı yaz`}</button>
          </span>
        </div>
      </div>

      <div class="section-h"><h2>Yeni bir masal yaz</h2>
        <button class="h2-plus" data-act="create" aria-label="Masal yaz">${ic("plus")}</button></div>
      <div class="h2-list">${Object.entries(MODES).map(([k, m]) => `
        <button class="h2-row" data-act="createModeDirect" data-arg="${k}">
          <span class="tile" style="background:var(${m.soft});color:var(${m.deep})">${ic(m.icon)}</span>
          <span class="grow"><span class="t-card-title">${m.title}</span><span class="t-supporting secondary">${m.promise}</span></span>
          <span class="chev">${ic("right")}</span></button>`).join("")}</div>
    </div>` };
  };
}
