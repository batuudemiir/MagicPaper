# İş tanımı: v4 metin sürümü ve iki dalganın güncel metni (Codex, motor hattı)

Batuhan 26 Kasım 2026'da 270 kitabın tamamında benzerlik düzeltmesini onayladı ("hata payı istemiyorum"). v3 `024b8a5` ile pinlendiği için v3'e dokunulmadı; düzeltilmiş hali **v4** olarak geliyor.

## Girdi
- `v4/{mod}-{hayvan}.json`: 90 kitap, v3 ile aynı `sourceBookID` ve başlıklar. 155 sayfa arkadaşa özel yeniden yazıldı, kalıp cümleler çeşitlendi.
- `dalga1/kitaplar/*.json`, `dalga2/kitaplar/*.json`: iki dalganın güncel metni. Kimlikler ve başlıklar aynı, sayfa metinleri değişti. Daha önce çıkardığın girdi envanterini bu dosyalarla yenile.
- `v4/v4-okuma.md`, `dalga1/dalga1-okuma.md`, `dalga2/dalga2-okuma.md`: değişen sayfalar ✎ ile işaretli.
- `p56_text_lint.py`: yeni kapılar eklendi:
  - `--pool <dosyalar>`: başka kitapta harfi harfine geçen sayfa en fazla %5, havuzda aynı cümle en fazla 25, bir hücrede aynı cümle en fazla 3.
  - Kitap içinde aynı cümlenin tekrarı artık hata.
  - Gülme işaretleri genişledi (güldür, gülme, kahkaha, kıkırtı).

## Doğrulama (benim çalıştırdığım)
- `python3 p56_text_lint.py --pool v4/*.json dalga1/kitaplar/*.json dalga2/kitaplar/*.json` → geçiyor: aynı sayfa %0, aşan cümle 0.
- Her dosya tek tek: 270/270 temiz (sayfa 18-38 kelime, cümle en fazla 14 kelime).
- Hücre içi kitaplar arası öbek örtüşmesi en fazla %17. Başka arkadaşın adı geçen sayfa yok. Nefes tutma ifadesi yok.

## İstenen
1. v4'ü yeni bir korpus/runtime sürümü olarak ekle. v1, v2 ve v3 baytları değişmez; pin v3'te kalır.
2. v4 için semantik, causal evidence, art handoff ve C3 güvenlik etiketlerini yeniden çıkar (hash'e bağlı; eski etiketler fail closed). Önceki gibi review alıntıları değişen sayfalarda bayatlayacak; yeniden bağla.
3. İki dalgada da aynı etiket işi güncel metinle yapılmalı.
4. 630 kitap×ad denemesi, N1500 örnekleme ve Release testlerini v4 ile tekrarla.
5. v4'e pin geçişi ayrı bir adım; Batuhan'ın onayını bekler.

`productionEnabled=false`, `artApproved=false` aynen kalır. Metinde sorun bulursan sayfa kimliği ve öneriyle durum dosyasına yaz; metni Claude düzeltir.
