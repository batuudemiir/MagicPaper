# İlk spot eşleme kuralları · 19 Kasım 2026

Kullanıcı uygulama entegrasyonunu onayladı. Set app içine sürümlü dosyalar olarak taşındı; bu dosya kuralların kaynak inceleme kaydıdır, çalışan kapsama raporu değildir.

## İncelenen tam kaynak cümleler

### na_neutral_01

{{child.name}} o sabah {{setting.name}}'a erkenden gitti. Her şey her zamanki gibiydi. Sonra durdu. Tam ilerisinde {{discovery.name}} duruyordu.

### na_neutral_02

{{setting.name}}'da o gün hava çok sakindi. {{child.name}} ıslık çala çala yürüyordu. Birden ıslığı kesildi. Az ötede {{discovery.name}} bekliyordu.

Bu cümleler görünür keşfin şimdi sayfada bulunduğunu bildirir; dokunma/açma/iyileştirme veya sahip bulma sonucu yoktur. Kural yalnız bu tek varyantı, tek hook/notice_anomaly beat’ini ve aynı source fingerprint’i kabul eder. Ek beat, recall, refrain, aile veya özel gün kaynaklı metin dar dilimden çıkar.

## Konu sınırları

12 paketlenmiş resmin 10’una kural yazıldı. Açık müzik kutusu için kapak durumu, boş yuva için boşluk durumu kaynak açıklamasında kesin olmadığı için bu iki resim paketlenmiş fakat eşleştirilmemiştir. Harita yalnız forest/garden etiketli mevcut setting kimliklerinde adaydır; çizimdeki orman ayrıntısı bunun dışında kullanılamaz. Pilot deniz kabuğu kimliğine shared kabuk resmi aktarılmaz.

## Statik kapsam

17 adet 5–6 blueprint ilk-page planı uygun; 10 subject × iki varyant × 17 blueprint = 340 katı izin kaydı. Blueprint/discovery seçim kısıtları nedeniyle tüm çarpımlar çalışma zamanında erişilebilir değildir. Gerçek masal/sayfa kapsaması bu sayıdan çıkarılamaz. 3–4/7–8/9–10 ve uykuya ait farklı corpus kaynağı bu kurallara uymaz.

Source fingerprint: AuthoredSourceFingerprint.make; versioned canonical raw template ID + variant ID + text + discovery ID/name/description + sorted traits. Uzunluklar UTF-8 byte sayısıdır. StableHash/FNV yalnız kaynak eşitliği kanıtıdır, katalog güvenlik imzasının yerine geçmez. PNG dosyaları SHA-256 ile doğrulanır.

## Gerçek motor fixture sonucu

Gerçek motor audit’i 12 paketli konuyu denedi; kurallı 10 konunun tümü için uygun sayfa bulundu. Müzik kutusu/yuva kural olmadığı için seçilmedi. Her blueprint başına en çok 48 tohum; bunlar kapsam yüzdesi değildir. Seed, blueprint, setting, discovery, variant, fingerprint ve tam açılış cümlesi `2026-11-19-story-spot-fixtures.json` içinde. Örnek: Deniz / story-art-audit-23 / blueprint_absence_looking_001 / object_torn_map_001 / na_neutral_01.

## Paketleme sözleşmesi

Xcode CopyPNGFile, ham PNG baytlarını değiştirir; kaynak dosyanın SHA-256 değeri paketlenmiş PNG ile aynı kalmaz. Bu test koşusunda gerçek app bundle üzerinde doğrulandı. Bu nedenle hash ile sabitlenen PNG verisi `.mpart` uzantılı opak resource olarak paketlenir. ImageIO görüntüyü uzantıdan değil dosya içeriğinden çözer. Proposal kaynak PNG’leri değişmedi. Resolver yalnız güvenli yerel basename ve `.mpart`/eski `.png` uzantılarını kabul eder; diğer dosya yolları/URL’ler reddedilir.

## Doğrulama sonucu

- Uygulama: 145 test, 0 hata, 1 mevcut skip. Kaynak izi motor testleri ayrıca 2/0. Render testi 1/0, sekiz gerçek SwiftUI sayfa görüntüsü. 12 bundle dosyasının hash’i ve ImageIO ile saydam çözümü doğrulandı.
- Tam paket: StoryEngine 933 test/2 skip, 15 assertion hatası (8 test case); diğer hedefler EngineFoundation 17/0, CharacterEngine 89/0, VisualSystem 51/0. Aynı 8 başarısız case ve toplam 15 assertion, değişiklik öncesi 068ca47 kopyasında tekrar üretildi. Eski determinism/pinned content, trait çeşitliliği, özel gün dili, mekân/çekim ve tekrar azaltma beklentileri bu işte değiştirilmedi.
- B2 kapalı/avatar yokken gerçek spot korunuyor; B2 sahnesi varsa sahne öncelikli. Eski/bozuk metadata, checksum/missing file, hazırlanan seri pinlerinin dört günlük açılışı ve aile silinince yalnız açılmamış bölümün yeniden değerlendirilmesi test edildi.
- Yerleşim kanıtı: `2026-11-19-story-spot-renders/README.md`. Ayrı SE/Pro Max/iPad cihazları, VoiceOver ve tam okuyucu chrome/ses/gestür elle matrisi tamamlanmadı.
