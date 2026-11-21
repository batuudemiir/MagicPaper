# Kaynak haritası

Üç uzman incelemesinin ortak sonucu. Salt okunur; çalışan örneklem/benchmark değil.

| Sınır | Gerçek kaynak | Görsel çalışmasına etkisi |
|---|---|---|
| İstek ve katalog | MagicPaper/StoryEngineBridge/OfflineStoryService.swift | Seçilen yerel/uzak katalog, ad, mod, yaş, companion/aile/geçmiş intent’e girer |
| Varyant semantiği | StoryEngine/Sources/StoryEngine/Content/CatalogTemplate.swift | Trait/capability/cast/state filtreleri var; bazıları candidatesiz kalınca gevşer, anlam garantisi değildir |
| Sayfa birleştirme | StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift | Seçilmiş page-local variantIDs, role/beats/emotion ve birleşik visualScene burada bulunur |
| Oluşturma akışı | MagicPaper/Services/StoryGenerationManager.swift | compose → mapper → binder → save |
| Uygulama eşlemesi | MagicPaper/StoryEngineBridge/OfflineStoryMapper.swift | Page provenance kaybı; imagePrompt İngilizce yönerge olarak kalır, altText değildir |
| Bağlama noktası | MagicPaper/StoryEngineBridge/IllustratedBookBinder.swift | Hem composed hem app story görülebilir; yeni nötr politika B2 guard’ının dışında |
| Mevcut sahne seçimi | MagicPaper/Screens/ArtKit/SceneBook/SceneSelector.swift | Beat/emotion yalnız puan; discovery/state/variant yok, yeni spot uygunluğunu kanıtlayamaz |
| Kayıtlı model | MagicPaper/Models/Story.swift | StoryPage.art isteğe bağlı; sayfa bazında genişletilebilir |
| Okuyucu | MagicPaper/Screens/StoryReader/ReaderStory.swift ve StoryPageView.swift | Kayıtlı karar çizilir; eksik dosyada metin; B2 sahnesi öncelikli |
| Görsel yükleme | MagicPaper/Screens/StoryReader/ReaderImageLoader.swift | Stories dosyaları; bundled görsel adı varsayımı hatalı |
| Seri planı | StoryEngine/Sources/StoryEngine/Offline/Series/SeriesPlan.swift | Anchor/keepsake/setting/companion, içerik sürümü, blueprint/discovery/seed |
| Seri kalıcılığı | MagicPaper/StoryEngineBridge/StorySeries.swift | Episode pages/origin var, StoryIllustration yok |
| Seri yeniden açılışı | MagicPaper/StoryEngineBridge/SeriesManager.swift | Açılışta Story yeniden kurulur; pinler burada kaybolmamalı |
| Yerel kitaplık | MagicPaper/Services/Persistence/LibraryShelf.swift | Normal offline kitaplar; engine FileStores ayrı illustrated kayıt sistemidir |
| Uzak içerik paketi | StoryEngine/Sources/StoryEngine/Content/ContentPackage.swift | Tam replacement; schema 2, bağımlılık ve sürüm politikası |
| İmzalı feed | MagicPaper/StoryEngineBridge/RemoteContent/ContentFeed.swift | Sürüm/schema/path/hash ve replay koruması; görsel paketi henüz yok |
| Katalog etkinleştirme | MagicPaper/StoryEngineBridge/RemoteContent/CatalogSourceResolver.swift | Staged kaynak launch’ta tekrar doğrulanır |
