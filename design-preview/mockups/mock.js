// Önizleyiciden gelen ayarlar: ?yazi=buyuk, ?cihaz=se, ?durum=<ad>
(function () {
  const p = new URLSearchParams(location.search);
  const r = document.documentElement.style;
  if (p.get("yazi") === "buyuk") r.setProperty("--type", "1.75");
  if (p.get("cihaz") === "se") r.setProperty("--status", "20px");
  document.documentElement.dataset.durum = p.get("durum") || "";
  document.documentElement.dataset.cihaz = p.get("cihaz") || "";
  // Ekran içi gezinme (ör. "Planları gör") önizleyicinin seçimini de değiştirir.
  window.mpGo = (durum) => {
    p.set("durum", durum);
    location.search = p.toString();
    try { parent.postMessage({ mpDurum: durum }, "*"); } catch (e) {}
  };
})();
