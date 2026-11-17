# Motor ve havuz genişletme planı (H0-H5)

17 Kasım 2026. Batuhan: "motor engineyi ve havuzu genişletmeliyiz, sonra diğer işlere bakarız". `docs/EVREN_PLANI.md`'nin E7-E8'i bu planın arkasına kaldı.

## Bugünkü havuz (main@69d9649, katalog JSON'undan sayıldı)

Standart arklı blueprint sayısı, bant ve moda göre. Parantez içi: en korumacı ayarda (`ContentSafety.level == .calm`, gergin sayfalı blueprint düşer) kalan.

| Bant | Macera | Öğrenme | Uyku | Seri devamı |
|---|---|---|---|---|
| 3-4 | **0** | 2 (2) | 2 | 4 |
| 5-6 | 4 (**2**) | 12 (12) | 3 | 4 |
| 7-8 | 2 (2) | 2 (2) | 2 | **0** |
| 9-10 | 2 (2) | 2 (2) | 2 | **0** |

Sonuçlar:

- Konu çipi en az 3 farklı mekanizma ister (`CatalogStoryTopic.minimumMechanisms`). Varsayılan ayar en korumacı olduğu için **bugün hiçbir bantta macera konusu görünmüyor**; "Gökyüzü ve uzay" de dahil (E5'te bulundu).
- 3-4 yaşta macera modu hiç yok.
- 7-10 yaşta her mod iki blueprint'le dönüyor: aynı iki olay örgüsü sırayla gelir.
- 7-10 yaşta biten masal devam ettirilemez.
- 5-6 dışındaki bantlarda öğrenme modunun konuları (Meslekler, Sporlar, Hayvanlar, Bilim, Tarih) aynı kapıya takılıyor.

## Hedef

Her bantta, en korumacı ayarda: macera ≥ 4, öğrenme ≥ 4, uyku ≥ 3 blueprint ve en az 3 mekanizma; her bantta seri devamı. Motor değişikliği yalnızca içeriğin istediği kadar.

## Fazlar

| Faz | Amaç | Büyüklük |
|---|---|---|
| H0 | Kapsam raporu: bant × mod × güvenlik × konu matrisi, test olarak | K |
| H1 | Sakin macera, her bantta (3-4 sıfırdan) | B (içerik) |
| H2 | Öğrenme 3-4 ve 7-10 | B (içerik) |
| H3 | Uyku çeşitliliği 3-4 ve 7-10 | O (içerik) |
| H4 | Seri devamı 7-8 ve 9-10 | O |
| H5 | Cümle tekrarı ölçümü, ince satır havuzlarını kalınlaştırma | O |

### H0: Kapsam raporu

Motor paketinde saf bir rapor (`CoverageReport`): her bant, mod, güvenlik seviyesi ve konu için kurulabilen blueprint, mekanizma ve konu görünürlüğü. Testte iki iş: matrisi yazdırır (insan okur), ve hedefleri **taban** olarak kilitler: bir içerik değişikliği bir hücreyi düşürürse test kırılır. Hedefe henüz ulaşmamış hücreler bugünkü değerde kilitlenir, her faz kendi hücresini hedefe çeker.

**Uygulanan (17 Kasım 2026).** `StoryEngine/Sources/StoryEngine/Offline/CoverageReport.swift`: her bant × mod × ayar (en korumacı, süzgeçsiz) için `BlueprintSelector.admissible` + `OfflineContentBinder` ile kurulabilen blueprint'ler, mekanizmalar (`CatalogBlueprint.mechanismKey`; konu kapısı da artık bunu sayıyor, tek tanım), `availableTopics`'in teklif ettiği konular ve seri devamı var mı (`SeriesPlanner.continuations`). `CoverageReportTests` matrisi yazdırır ve en korumacı ayardaki tabanları kilitler; H0 tabanları bugünkü tablo. Testler henüz koşulmadı: ilk koşuda yazdırılan tablo bu belgeye geçirilmeli.

### H1: Sakin macera

Gergin sayfası olmayan (`unease`, `hesitation` yok) macera blueprint'leri. Merak, keşif, yardım, bulmak; korku ve kaybolma yok.

- 3-4: 4 yeni (macera bu bantta sıfırdan; 6 sayfa).
- 5-6: 2 yeni sakin (eşik geçmenin sakin biçimi dahil).
- 7-8 ve 9-10: her birine 2 yeni (eşik ya da yeni bir aile).

Mevcut beat ve satır mimarisiyle; yeni aile gerekirse motorun `NarrativeFamily` sözlüğüne eklenir. Yeni kayıtlar dizilerin sonuna.

### H2-H5

Her faz H0 raporundan başlar, hedef hücreyi gösterir, biter. Ayrıntı başladığında buraya yazılır.

## Kurallar

- Mevcut kayıtlar değişmez, yalnızca sona ekleme. Sabit seed'li altın testler kırılırsa neden yazılır ve fikstür güncellenir (kayıtlı masallar metni saklar).
- Bütün yeni metin taslaktır, Batuhan okur. Dil kuralları CLAUDE.md'de.
- Testler plan sonunda bir kez; her faz derlenir.
