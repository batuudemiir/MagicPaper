# Gerçek SwiftUI okuyucu renderları

19 Kasım 2026. Geçen `StorySpotReaderRenderingTests` testinden sekiz PNG. Bunlar iPhone 17 Pro simülatöründe sabit SE/Pro Max/iPad **viewport ölçüleri** verilerek StoryPageView’den alınmıştır; ayrı fiziksel cihaz veya tam chrome/gestür testi değildir. Gerçek motorun `story-art-audit-23`, Deniz, `blueprint_absence_looking_001`, `object_torn_map_001` çıktısı ve gerçek bundle resmi kullanılır. Büyük erişilebilirlik yazısında spot kaldırılır, uzun metin kaydırılabilir kalır.

Gündüz, gece ve en büyük yazı örnekleri gözle incelendi. İlk soğuk renderdaki resim yükleme yarışı için testte aynı piksel boyutu önceden çözüldü ve animasyonun yerleşmesi beklendi; burada yalnız son başarılı çıktı tutulur. Tam uygulamada ses/kelime/gestür davranışının elle cihaz matrisi yapılmadı.

![story-spot-ipad-landscape-night.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-ipad-landscape-night.png)

![story-spot-se-ax5-text-priority.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-se-ax5-text-priority.png)

![story-spot-pro-max-night.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-pro-max-night.png)

![story-spot-se-night.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-se-night.png)

![story-spot-se-dusk.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-se-dusk.png)

![story-spot-se-sepia.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-se-sepia.png)

![story-spot-se-cream.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-se-cream.png)

![story-spot-se-light.png](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/research/2026-11-19-story-spot-renders/story-spot-se-light.png)
