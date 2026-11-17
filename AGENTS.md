<!-- Codex kuralları. Kaynak: ../CLAUDE.md (17 Kasım 2026'da aktarıldı). Yollar bu repo köküne göre. -->

> **Codex için not:** Uzmanlık ajanları `.codex/agents/*.toml` içinde (eski adı `.claude/agents/`).
> Geçmiş kararlar, fazların kaldığı yer ve bilinen tuzaklar: `docs/PROJE_HAFIZASI.md`. Bir alana dokunmadan önce ilgili bölümü oku.
> Testler ve simülatör yalnızca plan bitince bir kez çalıştırılır; ara adımlarda kodu okuyarak ilerle.

# MagicPaper

## Product Identity

MagicPaper is a premium personalized children's storybook platform.

It is not a generic AI story generator.

The core product idea is:

> Every child can have a story world that belongs to them.

The child should become a recurring character across stories.

The product should feel like a premium children's publishing experience first and an AI product second.

---

## Product Pillars

1. Child personalization
2. Story quality
3. Character consistency
4. Beautiful illustration
5. Storybook reading
6. Parent simplicity
7. Family memories
8. Privacy and safety
9. Low operating cost

---

## Current product decisions (3 Ekim 2026)

Active roadmap: `docs/MagicPaper_Faz_Plani_Ekim.md` (continues `MagicPaper_Faz_Plani.md` from Faz 9).
Where an older doc disagrees with that plan, the plan wins.

- Text stories: on-device offline engine only. No LLM for text stories.
- Modes: Uyku öncesi (`bedtime`), Yeni şeyler öğrenelim (`learning`), Maceraya çıkalım (`adventure`); "Bana sürpriz yap" is a selection strategy, not a mode.
- Creation: mode → "Masalda kimler olsun?" (catalog companions + the child's Masal ailem). No free text. Length comes from age band, tone from mode. Moda dokununca geçilir, "Bana sürpriz yap" doğrudan yazar, konu "kimler" adımında, çocuk tek satır "İrem için"; hazırlık 6-8 sn, 2 sn sonra atlanır, masal kendiliğinden açılır (karar: 7 Kasım 2026).
- Age bands: 3-4 / 5-6 / 7-8 / 9-10 (`AgeBandResolver`).
- Series: a liked story (not a surprise one) can be continued; 5 episodes, one unlocks per day, one active series per child.
- Parent account: Google + Apple sign-in, required in onboarding.
- Action color #6A47B8. Fonts: Baloo 2 + Nunito.
- Mascot: raccoon "Ragi".

---

## Engineering Principles

### 1. Inspect before changing

Never assume an architecture exists.

Before modifying a subsystem:

- inspect existing implementation
- identify dependencies
- identify persistence
- identify consumers
- identify tests
- identify shared files

Reuse existing systems when possible.

---

### 2. Do not rewrite working systems

Prefer incremental refactoring.

Never perform a large rewrite simply because a different architecture looks cleaner.

---

### 3. Domain logic must not live inside SwiftUI views

Views should render state and handle user interaction.

Business logic belongs in appropriate services/models/view models.

---

### 4. Story content must not be hard-coded inside views

Story content belongs in the Story Engine / Content Library.

---

### 5. Character identity is canonical

The Child Profile and Character Bible are the source of truth for the child's visual identity.

Do not independently redefine the child's appearance on every story page.

---

### 6. Low-cost first

MagicPaper should not require expensive remote AI generation for every basic text story.

Prefer:

- deterministic generation
- local templates
- cached content
- on-device processing

when they provide sufficient quality.

Remote AI should be used where it creates meaningful value.

---

### 7. Calm UX

MagicPaper may use lightweight reading continuity mechanisms such as `MPStreak`,
provided they reinforce reading rituals rather than compulsive engagement or
competitive gamification.

Continuity should mean reading continuity and family storytelling ritual — not
app engagement. A day counts because a family actually read a story together.

Calm milestone badges (rozet) are allowed (karar: 3 Ekim 2026). Rules:

- earned only by reading (e.g. "İlk masal", "7 uyku masalı", "10 masal"), never by time spent in the app
- never lost, never expire, no countdowns, no "almost there" pressure
- no comparison with other children or families
- shown at the end of a story and in "Benim köşem"; never announced by push notification
- Benim köşem shows all badges, unearned ones locked, with an "3 / 8" count (karar: 13 Ekim 2026); no progress bars or "2 masal kaldı" copy
- Rozet planı (karar: 15 Kasım 2026, Batuhan; `docs/ROZET_PLANI.md`): 69 rozet, 12 aile, kademeli katlar ve 4 gizli rozet; Rozetlerim sonunda "Masal anıları" (rekor değil). Okuma günü rozeti toplam farklı günü sayar, ardışık günü değil. Kilitli rozete dokununca yalnızca eylem cümlesi ("Bir macera masalı okuyunca açılır"), sayı yok. Gündüz masal sonunda tam ekran rozet anı (okuyucunun içinde sahne, yeni modal değil); gece sessiz tek satır. Rozet yıldız vermez

Stars (yıldız, karar: 13 Ekim 2026; sabah kuralı 15 Kasım 2026): one per finished story, and one morning star only on a day a story is finished (earlier passive mornings are kept, the score never drops). Spending (karar: 8 ve 11 Kasım 2026, Batuhan; `docs/VIZYON_PLANI.md` Faz 9): a calm collection, not a reward economy:

- stars are earned only by reading; a re-read gives no star; never sold for money, never linked to a plan
- stars buy optional, permanent decorations only (today: Kitaplık colours, `MPDecor`: the hard bottom edge of the covers; the shelf itself was removed on 13 Kasım 2026); nothing bought is ever lost or expires; no countdowns, no limited-time items, no random packs: every item shows its price
- the story's sticker is never bought: it enters the album when the story is finished (`MPStickerAlbum`)
- no shop on the story ending, no "N stars left" copy, no notification; Ragi never guilt-trips
- the parent sees earned/spent in the child's profile page and can turn spending off or halve prices (Güvenlik)
- Yıldız puanı (karar: 15 Kasım 2026, Batuhan; `docs/ROZET_PLANI.md` 5b): ömür boyu kazanılan yıldız çocuğun toplam puanıdır; harcama puanı düşürmez (harcanan yalnızca "cepteki yıldız"dan gider). Puan arttıkça profil 12 Yıldız katı alır (Kıvılcım → Masal göğü). Puan ve kat asla düşmez, kardeşler arasında yan yana gösterilmez, sıralanmaz, parayla alınmaz. Aşağıdaki "points" yasağının yalnızca yıldız için istisnası
- the child's hero (`HeroLook`, `HeroAvatarView`, karar: 12 Kasım 2026): Duolingo-style flat bust, no outlines, child or animal friend (kedi, ayı, tavşan, tilki, panda); identity parts (kind, skin, fur, hair, face) are free and saved without a parent gate (karar: 14 Kasım 2026, Batuhan); cosmetics (hats, outfits, sunglasses) belong to the child, some cost stars; hijab and glasses are always free. Ragi's own outfits are illustrator work

Do not introduce:

- points
- leaderboards
- competitive rankings
- reward economies
- artificial engagement loops
- social pressure
- excessive notifications
- aggressive push notifications
- unnecessary dashboards

Continuity copy should sound like:

- "3 gün üst üste birlikte okudunuz."
- "Bu hafta 4 hikâye tamamlandı."
- "Okuma yolculuğunuz devam ediyor."
- "Yarın yeni bir hikâyeye devam edebilirsiniz."

Never like:

- "Don't break your streak!"
- "Come back now!"
- "You're about to lose your streak!"
- "Only 2 hours left!"

MagicPaper should feel calm, magical and intimate.

---

### 8. Parent-first UX

The parent is the primary customer.

The child is the beneficiary.

The parent should never be asked for information that MagicPaper already knows.

---

### 9. Premium children's publishing aesthetic

Avoid:

- generic SaaS UI
- cheap sticker aesthetics
- neon
- excessive gradients
- glossy 3D
- random AI illustration styles
- excessive animation

The visual language should feel:

- warm
- editorial
- handcrafted
- poetic
- timeless
- premium

#### Design law

The adjectives above are the intent; the rules below are the law. Tokens have
one source: `MagicPaper/DesignSystem/MPTheme.swift`. Kod düzeni: `docs/ARCHITECTURE.md`. Inventory and
history: `docs/MagicPaper_Design_System.md`.

**Tipografi**
- İki aile, rolleri sabit: **Baloo 2** yalnızca başlık ve kapak (`MP.F.display*`), **Nunito** geri kalan her şey (`MP.F.body*`, `label*`, `caption`, `read`).
- Baloo 2 dosyası satır kutusu düzeltilmiş Latin kopyasıdır: `Baloo2-Latin-Variable.ttf` (`Tools/make_baloo_latin.py`). Roller sekiz (`MPTextStyle`), tablo `docs/MARKA.md`'de: `cover` 34, `page` 28, `section` 21 (Baloo 2); `cardTitle` 17 bold, `body` 17 regular, `supporting` 15, `footnote` 13, `button` 17 bold (Nunito) (karar: 7 Kasım 2026).
- Font yalnızca `MP.F`'ten. Satır içi `.custom(...)` yok, `.custom(_:fixedSize:)` hiç yok (Dynamic Type'ı öldürür).
- `.system(...)` yalnızca `MP.F.glyph(_:)` ile, boyut `MP.G`'den.
- Ölçekte olmayan boyut açılmaz. Hiyerarşi önce boşlukla, sonra boyutla, en son ağırlıkla kurulur.
- Masal metni yalnızca `MP.F.read(ReadSize.points)` + `lineSpacing = points × ReadSpacing.factor` (Normal 0.72, Rahat 0.9, Geniş 1.1; karar: 21 Ekim 2026). "Kolay okuma" yalnızca harf arasını açar, font Nunito kalır. Metindeki ses kelimeleri ("pıt pıt") yalnızca `MP.F.sound(points)`; çocuğun adı vurgu renginde ve kalın.

**Renk**
- `Color(hex:)` yalnızca `MP.Palette` içinde. Tek istisna: `MagicPaperCoverColor` (kapak sanatının paleti).
- Bileşenler `MP.C` okur; `MP.Palette`'i yalnızca `World`, `ReadTheme`, `C.avatarAccents` okur.
- Saf siyah ve soğuk gri yok: `.black.opacity(...)` yerine `MP.Palette.murekkep900.opacity(...)` ya da bir `MP.C` token'ı.
- `sepya` yalnızca okuyucu kâğıdında. Dünya aksanları arayüzde tek başına kullanılmaz.

**Boşluk ve biçim**
- Boşluk yalnızca `MP.S`; `.padding(12)` gibi çıplak sayı yok. Ekran kenarı `MP.S.screenGutter`, dokunma alanı ≥ `MP.S.tapMin` (48).
- Okul öncesi ölçüleri (karar: 11 Kasım 2026, `docs/VIZYON_PLANI.md`; Sesame 2012, NN/g): çocuk ekranının tek birincil öğesi `MPSize.minTouchHero` 64 (`MPButton(size: .hero)`); çocuk akışında seçim çipi `chipHeightKid` 44, seçenek satırı `choiceRowKid` 72; alt kenarda aktif hedef yok. Sayfa düzenlerinde kıvrım ~700 pt: başlık + kahraman alan + ikinci bölümün ilk satırı görünür.
- Ebeveyn kapısı tek yerden: `app.router.requestGate(then:)` (karar: 11 Kasım 2026); ekran kendi `ParentalGateView` kapağını tutmaz.
- Köşe yarıçapı `MP.R`, önce semantik olan (`card`, `button`, `sheet`, `input`).

**Derinlik**
- Sistemin imzası sert alt kenar: `mpEdge`. Kart derinliği gölgeden gelmez. Dokunulan kart ve birincil düğme kenar taşır.
- Düğme yalnızca `MPButton` ve `MPCircleButton` (karar: 7 Kasım 2026): `primary` 56 pt, ekranda bir tane, basınca yüzü kenarın üstüne iner (`MPPressStyle.onEdge`); `secondary` lavanta 52; `ghost` 48; `danger` yalnızca ebeveyn alanı; `outline` yalnızca giriş sağlayıcısı. Devre dışı düz gri ve kenarsız, saydamlık yok.
- Gölge yalnızca `mpShadow(MP.Sh.*)`; çıplak `.shadow(...)` yok.
- Gradient arayüz yüzeyinde ve butonda yok. Yalnızca malzeme taklidinde: kâğıt gölgelemesi, sayfa kıvrımı, kapak sanatı, parlaklık maskesi — ve illüstrasyon üstü metnin karartması (`MP.Scrim`, yalnızca `MPArtHero`; metin `MP.C.textOnArt*`).
- Cam (Liquid Glass) yalnızca içeriğin üstünde yüzen gezinme kontrollerinde: alt sekme çubuğu ve okuyucunun yüzen kontrolleri: kapat, favori/ayarlar kapsülü, alt çubuk ve sayfa kaydırıcısı (karar: 21 Ekim 2026). Yalnızca sistemin `glassEffect`'i, ayarı `MP.Glass`'tan; elle yapılmış cam taklidi yok. Çocuk alanının alt çubuğu bütün sürümlerde kendi çubuğumuz (`KidTabBar`; karar: 13 Kasım 2026, Batuhan, 22 Ekim'deki "iOS 26'da sistemin `TabView`'ı" kararının yerine): dört sekme cam kapsülde, "Masal yaz" yanında ayrı, marka renginde sert kenarlı dairede (cam değil), seçilmez, masal yazmayı açar; sürükleyerek seçme bizde, lavanta seçim yastığı parmağı izleyerek kayar. Kart, sayfa, sheet ve içerik butonu cam olmaz. iOS 26 öncesi yedek `.ultraThinMaterial` + `MP.C.edgeGlass`; Saydamlığı Azalt açıkken opak `MP.C.surfaceCard`. Üst başlıklar henüz bu kurala dahil değil.

**Hareket**
- Süre ve eğri yalnızca `MP.M` (`press`, `easeOut`, `base`, `slow`, `page`). Tek spring: `MP.M.spring`.
- Her animasyon Reduce Motion'dan geçer (`MP.M.gated(...)` ya da `accessibilityReduceMotion`) ve kapalıyken anlamı koruyan bir alternatifi olur (çapraz geçiş), boşluk değil.
- Basma davranışı yalnızca `MPPressStyle`. Sürüklerken hiçbir şey zıplamaz, parlamaz, titremez.

**Dokunsallık**
- Titreşim yalnızca `MPHaptics` üzerinden (kullanıcı ayarına bağlı); doğrudan `UIFeedbackGenerator` ya da `.sensoryFeedback` yok.
- Tamamlanan eylem başına en fazla bir titreşim; sürükleme sırasında hiç.

**Erişilebilirlik** (her yeni ya da değişen ekran)
- Her etkileşimli öğenin Türkçe `accessibilityLabel`'ı var; süs öğeleri `accessibilityHidden(true)`.
- En büyük Dynamic Type boyutunda kesilme ve yatay taşma yok.
- Bilgi yalnızca renkle verilmez.
- Gövde metni beş okuma kâğıdında da (`Gündüz`, `Krem`, `Sepya`, `Akşam`, `Gece`) kâğıda karşı ≥ 4.5:1 kontrast.

**Üst başlık** (karar: 22 Ekim 2026)
- Ebeveyn alanında yalnızca `MPParentHeader`. Kök sayfa tek: "Büyükler için" (`ParentOverviewView`, eski Özet) `MPParentHeader(title:subtitle:)`: büyük başlık + "Çocuk modu". Masal güvenliği ve Ayarlar artık sekme değil, oradan itilen alt sayfa (karar: 14 Kasım 2026, Batuhan). Alt sayfa `MPParentHeader(title:subtitle:onBack:)`: "Geri" + küçük başlık; "Çocuk modu" alt sayfada görünmez.
- Çocuk alanının alt sayfalarında `MPTopBar`. Çocuk kök sekmelerinde yalnızca `MPKidTabHeader` (karar: 7 Kasım 2026): başlık solda, sayfanın üst boşluğu `MPSpacing.lg`. Ana sayfa'nın selamı (`eyebrow`) ile Masallar'ın (eski adı Günlük, kodda `GunlukView`; karar: 7 Kasım 2026) vitrini ve araması (`accessory`) istisna değil.
- Alt çubuk (karar: 7 Kasım 2026, Batuhan; ad: 13 Kasım 2026): Ana sayfa · Masallar · Kitaplık · Profil + "Masal yaz". Profil (eski adları Odam ve Benim köşem, kodda `KidCornerView`) sekme çünkü profil değiştirme sık yapılır: "Kim okuyor?" sayfanın en üstünde, tek dokunuş. Sekme başlıklarında avatar yok. Klasik detayın illüstrasyonlu üst bölgesi henüz bu kurala dahil değil; hedef `MPArtHero` (`docs/BUTUNLUK_DENETIMI.md`).
- Sayfa açılışı (karar: 7 Kasım 2026, `design-handoff/docs/SCREENS.md`): bir seviye derin sayfa push, alt çubuk görünür, çıkış "Geri" ve kenardan kaydırma (`MPKidRoute`, `MPParentRoute`). Kısa iş yalnızca sistem sheet'i (`mpSheet`; içerik düzeni `MPSheet`), kendi çizdiğimiz katman yok. Çok adımlı ya da sürükleyici akış (okuyucu, masal yazma, uyku, ilk açılış, kapı, paywall) `fullScreenCover`, çıkış X. "Geri" yalnızca push'ta.
- Bir modal açıkken başka modal açılmaz (karar: 7 Kasım 2026). İstisna: ebeveyn kapısı ve sistemin paylaşım penceresi. Sheet kapandıktan sonra modal açılacaksa `app.closeSheet(then:)`.
- Ebeveyn odası (karar: 7 Kasım 2026, 23 Ekim'deki kilit kararının yerine; `docs/SAYFA_MIMARISI.md`): uygulama çocuğundur, ebeveyn alanı üstüne açılan bir odadır. Tek giriş Profil sekmesinde, kimlik bloğunun hemen altında tam bir "Büyükler için" satırı (karar: 14 Kasım 2026, Batuhan; en alttaki küçük yazıyı bulan olmuyordu); çocuk sekmelerinin başlığında kilit yok, gizli hareket yok. Odaya giriş iki saniye basılı tutmayla açılır (`ParentalGateView(kind: .hold)`); çarpma sorusu yalnızca dışarı çıkan ya da geri alınamayan işlerde: silme, paylaşma, dışa aktarma, giriş, profil ekleme, satın alma, Masal ailem'e ekleme/düzenleme (ad yazılır). Kahraman ve kitap karakterinin görünüşü kapısız. Oda tek sayfa, sekme çubuğu yok; sağda yazılı "Çocuk modu" odayı kapatır ve çocuk bıraktığı yerde olur. Masal onayı yok (karar: 14 Kasım 2026): yazılan masal doğrudan kitaplığa girer. Simgeli mod anahtarı yok.
- Geri her yerde `MPCircleButton("chevron.left")` + "Geri"; başlık metni `isHeader` trait'i taşır.
- Başlık kendi kenar boşluğunu eklemez: yatay boşluk `screenGutter`, üst boşluk sayfanın. Ekran kendi başlık satırını yazmaz, negatif boşlukla başlığı kaydırmaz.

**Bölüm başlığı ve boş durum** (karar: 22 Ekim 2026)
- Bölüm başlığı yalnızca `MPSectionHeader`: rol `section`, alan `area:` ile; "Tümü ›" `link:`, sayaç `note:`, ekranın kendi denetimi `trailing:`. `HomeSection`, `ParentSection` ve `GunlukSection` bunun üstüne kurulu; yalnızca Masallar'ın gece bölgesi (`surface: false`) kendi simgeli başlığını taşır.
- Bölümü boşluk ayırır, panel ya da kart değil (karar: 7 Kasım 2026). Kart yalnızca kendi başına dokunulan öğede; kart içinde kart yok. Lavanta (`cardSoft`) yalnızca bu akşamın kartında, seçili öğede ve ikincil düğmede; bölüm zemini olmaz.
- Boş ve hata durumu yalnızca `MPStateView`: Ragi + bir başlık + bir cümle + tek eylem; yalnızca çocuk alanında. Ebeveyn alanında boş durum liste satırı (`MPListRow`) dilinde, Ragi'siz. Ekranda Ragi zaten görünüyorsa (Kitaplık'ta "Eşleşen kitap yok") ikinci Ragi konmaz, yalnızca söz kalır.

**Ragi** (karar: 16 ve 23 Ekim 2026)
- Her çocuk ekranında bir Ragi (karar: 16 Ekim 2026): karşılama, konuşma balonu (`MascotSays`) ya da sahne. Ekran başına en fazla bir Ragi, tek duygu; ebeveyn alanında Ragi yok.
- İstisnalar (karar: 23 Ekim 2026): okuyucu sayfaları (masal sonunda var), klasik detay ve seri sahnesi (boyalı sahne ekranın kahramanı), ebeveyn kapısı, ve bir akışın Ragi'li adımından hemen sonraki seçim adımı ("Masalda kimler olsun?").
- Ragi yalnızca `MascotImage` / `MascotSays` / `MPStateView` ile; poz `Mascot` kataloğundan, ekrana göre (`Mascot.usage`).
- Hareket yalnızca `MascotImage`'ın kuklası (`RagiMotion`, `docs/RAGI.md`); ekran Ragi'ye kendi nefesini eklemez. Zıplama yalnızca gündüz masal sonu ve dokununca. Ses yalnızca `MPSound`; uyku vaktinde ve masal okunurken çalmaz (karar: 7 Kasım 2026).

**İkon**
- İkon yalnızca `MPIcon`, boyut `MP.G`'den.

**Dil** (karar: 20 Ekim 2026)
- Masal **yazılır, hazırlanır, ciltlenir**; "üretilmez", "oluşturulmaz", "generate" edilmez. Profil, PDF, davet ve hesap için "oluştur" serbesttir.
- Hız bir özellik olarak sunulmaz: "saniyeler içinde", "anında", "hızlı" ve "hemen" masal anlatısında geçmez.
- "Yapay zeka" arayüzde ve masal metninde geçmez.

**Doğrulama** — bir ekran "bitti" sayılmadan önce, değiştirilen dosyalarda bu kontroller boş döner ve simülatörde açık + koyu, en büyük Dynamic Type, iPhone SE + Pro Max ekran görüntüsü alınır:

```bash
grep -rn "Color(hex:" --include='*.swift' MagicPaper | grep -v -e MPTheme.swift -e MagicPaperCoverPalette.swift
grep -rn "\.shadow(" --include='*.swift' MagicPaper | grep -v "func mpShadow"
grep -rnE "\.padding\((\.[a-z]+, )?[0-9]" --include='*.swift' MagicPaper
grep -rn "fixedSize:" --include='*.swift' MagicPaper
grep -rn -e "UIImpactFeedbackGenerator" -e "sensoryFeedback" --include='*.swift' MagicPaper | grep -v MPHaptics.swift
grep -rnE "\"[^\"]*([Üü]ret|[Oo]luştur|saniyeler içinde|anında|[Yy]apay zeka)[^\"]*\"" --include='*.swift' MagicPaper | grep -v -e "///" -e "#Preview" -e "print(" -e "logger\." -e "[Pp]rofil" -e PDF -e "[Dd]avet" -e hesab
```

Dil grep'inin bilinen, canlı olmayan isabetleri (20 Ekim 2026): `Story.swift`'teki `displayName`'ler, `MPMascot` katalog notu, örnek masal metinleri ve `ClassicsCatalog` doğrulama mesajı.

Mevcut ihlaller (2026-09-30 ölçümü) ve açık tasarım soruları: `docs/DESIGN_LAW_DRAFT.md`. Eski koddaki ihlaller dosya sahibi ajanla, ayrı turda düzeltilir; yeni kod bu kurallara uyar.

---

### 10. Privacy by design

Never log:

- child photos
- sensitive child information
- private family content
- raw prompts containing sensitive information

Minimize collected data.

Do not retain raw child photos unnecessarily.

---

## Agent Rules

Specialized agents exist under:

`.claude/agents/`

Each agent has a narrow responsibility.

Agents must:

1. inspect relevant code first
2. stay within their scope
3. avoid unrelated refactoring
4. report changed files
5. report tests
6. report architectural decisions
7. report conflicts
8. preserve existing functionality

Do not allow multiple agents to modify the same core files concurrently unless the task explicitly requires it.

---

## Shared File Rule

Before editing a shared file, determine whether another active agent owns it.

Prefer creating small focused components rather than modifying giant shared files.

If a shared file must change:

1. document why
2. keep the change minimal
3. inform the lead agent

---

## Değişiklik günlüğü (karar: 13 Ekim 2026)

Tamamlanan her işten sonra, kim istemese ya da hatırlatmasa bile,
`design-handoff/reference/DEMO_CHANGELOG.md` dosyasının
**Değişiklik günlüğü** bölümüne bir kayıt eklenir. Bu kural uygulama kodu, tasarım
canvas'ı, içerik ve belgeler dahil her iş için geçerlidir.

- Kayıt en üste eklenir (en yeni en üstte).
- Başlık: `### YYYY-MM-DD · <sürüm> · <kısa başlık>`. Sürüm, canvas işinde canvas
  sürümüdür (`v22`); uygulama işinde dal ve commit'tir (`main@ab6f02c`, commit
  yoksa `main, commit yok`).
- Altında maddeler halinde: ne değişti, ne bilerek değişmedi, test sonucu ve
  etkilenen dosyalar.
- İş, günlük kaydı yazılmadan bitmiş sayılmaz (bkz. Definition of Done).

**Gelişim bu dosyadan takip edilir (Batuhan, 14 Ekim 2026).** Bu yüzden:

- **Her biten iş yazılır**, küçüğü de: tek bir düzeltme, bir tasarım turu, bir içerik
  düzeltmesi, bir birleştirme ya da gönderim. Bir sohbette birden fazla iş bittiyse
  her biri ayrı kayıt olur ya da tek kayıtta ayrı maddeler olarak yazılır.
- **Kayıt ertelenmez.** Dosyada başka bir oturumun commit edilmemiş değişikliği varsa
  bile kendi kaydın yazılır: onların satırlarına dokunmadan en üste eklenir ve
  yalnızca kendi kaydın commit'lenir (`git add -p` ile yalnızca kendi hunk'ın).
  Bunu yapmak mümkün değilse kayıt metni kullanıcıya verilir ve sohbet "bitti"
  denmeden önce bunu açıkça söyler.
- **Sıra:** iş biter → kayıt yazılır → commit → (istendiyse) gönderilir. Gönderim
  kaydın içindeki commit'i de içerir.
- **Dürüst kayıt:** test çalıştırılmadıysa "test çalıştırılmadı" yazılır; cihazda
  ya da simülatörde görülmediyse yazılır. Yapılmayan doğrulama yapılmış gibi yazılmaz.
- Önceden kaydı eksik kalan işler fark edildiğinde geriye dönük kayıt eklenir
  (başlıkta gerçek tarih ve commit).

---

## Definition of Done

A task is not complete when code compiles.

It is complete when:

- implementation works
- relevant tests pass
- existing flows still work
- architecture remains coherent
- UI follows MagicPaper design language
- no unnecessary duplication was introduced
- documentation is updated when architecture changed
- a Değişiklik günlüğü entry was added

---

## Product Direction

The long-term product architecture is:

Family
→ Child Profile
→ Character
→ Story Engine
→ Story
→ Illustration
→ Storybook Reader
→ Library
→ Story Memory
→ Future Stories

Future systems may include:

- story series
- audio
- read together
- photo → story
- drawing → story
- family sharing
- gift books
- physical books

Do not implement future features prematurely.

Build foundations that allow them later.
