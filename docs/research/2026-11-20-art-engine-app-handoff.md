# Motor ve sanat havuzu iş bölümü

20 Kasım2026. Kullanıcı Claude’un provenance ve içerik anlam şeması işine başladığını iletti. Aynı şemanın iki ayrı uygulaması yapılmayacak.

## Claude’un sahipliği

- ComposedPage sıralı kaynak parçaları, kaynak türü/ID/digest/bağlam.
- StoryPage.provenance kalıcı modeli ve OfflineStoryMapper aktarımı; model/mapping testleri.
- Motor içerik satırlarında görsel anlam (visualKeys/visualState veya kesinleşen eşdeğer şema), içerik doğrulayıcısı ve etiketleme.

Bu dosyalara bu audit turunda dokunulmadı. İçeriklerin metni, seed/varyant dağılımı ve kişiselleştirme korunacak. Nakarat, recall ve beat kaynak türleri ayrılmalı; aile/özel gün bağlamı beat ile birlikte bulunabilir.

## ChatGPT’nin sahipliği

- `Tools/story_art_coverage_audit.py` ve `Tools/test_story_art_coverage_audit.py`: salt okunur authored kaynak çıkarımı, exact kaynak/pointer/ID/hash denetimi.
- `docs/research/2026-11-20-art-anchor-audit.{json,md}`: kaynak audit’i; editoryal notlar yeni motor alanlarının yerine geçmez.
- `docs/research/2026-11-20-authored-art-source-inventory.json`: geniş ham id/text envanteri ve audit kaynak doğrulaması. Runtime seçilebilirlik veya görsel kapsam sertifikası değildir.
- `docs/research/2026-11-20-art-asset-bridge.json`: mevcut12 asset’in kanonik konu/durum/sürüm/digest tablosu. `visualKeys` alanı özellikle null: Claude’un isimlerini ikinci kez uydurmamak için yeni sözleşme beklenir.
- Sonraki dilim: motor şeması gelince uygulama sanat kataloğu/matcher/binder ve reader gösterimi. Bu tur yeni binding veya uygulama davranışı eklenmedi.

## Değişim kontrolü

Yalnız satır metni hash’i yeterli değil: aynı söz farklı ID, yaş, koşul veya bağlamla anlam değiştirir. Denetim hem dosya hash’ini hem kaynak pointer’daki ID/metin hash’ini kontrol eder. Kaynak değişirse sonuç hata olur; eski inceleme geçerli sayılmaz. Anlam doğrulaması ve bütün-kitap ulaşılabilirlik kanıtı bu araçta otomatik yapılmaz.

6 araç testi ilk nihai koşuda geçti. Bağımsız incelemenin dosya/kimlik stale riski bulgusu düzeltildi. Repo güncellemesi sonrası eski audit830 kayıtta kaynak değişimi yakaladı; bu, eski eşlemeyi sessizce kullanmama kontrolünün gerçek örneğidir. Güncel kaynak çıkarımı tamamlandığında son doğrulama ayrıca kaydedilir.

## Birleştirme sonrası kabul

1. Claude’un commit’i ve kesin visualKey/state şeması okunur; burada paralel bir engine şeması eklenmez.
2. Envanter aynı kaynak revision’ında yeniden çalıştırılır; eski pointer/hash onayları otomatik yeni kaynağa taşınmaz.
3. Visual key → uyumlu asset/state eşlemesi ayrı app kataloğunda hazırlanır. `StoryPage.picture` eklenmez; mevcut `StoryPage.art` kullanılır.
4. Bütün sayfalardaki uygun anlamlar değerlendirilir, metin veya seçimler değiştirilmez. Pin kitapla saklanır; eski kitaplar yeniden üretilmez.
5. Küçük yaşta daha fazla resimli sayfa hedefi gerçek kapsamayla doğrulanır.3/2 ve4/3 önerileri henüz evrensel garanti değildir.

Kullanıcı tarafından aktarılan bu iş bölümü dışında başka sohbetlere mesaj gönderilmedi. Audit için app build/test veya telefon kurulumu gerekmedi; telefonun mevcut sürümü değişmedi.


## Güncel teslim doğrulaması

HEADa7685ca kaynağında238dosya/3016authored kayıt;973yeni kayıt var. Önceki kayıtlardan830unun dosya bağlamı değişti; aynı pointer’daki önceki metinler değişmedi. Yine de bütün dosya hash’i politikasıyla49eski anchor incelemesi geçersizleştirildi,2korundu;3014kayıt unresolved,0onaylı art binding. Geniş ham kaynak aracı3304id/text nesnesi çıkarıyor; fazladan nesneler nedeniyle bu sayı authoredvaryant sayısı değildir. Güncel3016pointer+ID+metin+dosya hash’i0hatayla doğrulandı.6araçtesti ve mevcut12assetdigest kontrolü geçti. Evrensel kapsama henüz kanıtlanmadı.
