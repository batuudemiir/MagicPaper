# Uyku arkı

21 Ekim 2026'da Batuhan onayladı. Uyku öncesi (`bedtime`) modu artık charge ailesini ödünç kullanmıyor; kendi masal yapısı var.

## Ne

- **Masalın yolu:** masal yatakta başlar. Pencerede uyuyamayan küçük biri vardır. Çocuk, her akşam kendisine yapılanı ona yapar. O uyur, çocuk da aynı odada, aynı yorganın altında uykuya dalar.
- **Duygu eğrisi** (motorun 0-3 ölçeği):
  - 5-6 bandı: `0,1,1,1,1,0,0,0`, doruk s.5'te (%62,5).
  - 3-4 bandı: `0,1,1,1,0,0`, doruk s.4'te.
  - Doruk merak ya da gülümseten bir şaşkınlıktır: hıçkırık, hapşırık, ninni söylerken esneme.
- **Başa dönüş:** ilk ve son sayfa aynı odayı adıyla söyler (`{{setting.name}}`). Çerçeveyi oda ayarı taşır ve bunun için ayrı bir eşleşme alanı yoktur.
- **Kanıt:** kitap araştırması `c_bedtime_closes_circle` (LOW, 6 kitabın 4'ü) başa dönüşü destekler. Erken doruk ise kitaplardan değil, privacy-safety'nin koşulundan gelir.

## Nasıl (motor)

- **`NarrativeArc` (`standard | bedtime`):** blueprint'te ve şablonda bulunur. Alan yoksa `standard` sayılır.
  - Mod bir blueprint'i ailesi **ve** arkı tutuyorsa alır (`StoryModeProfile.arcs`).
  - Uyku modunun ayarı: `families: [charge], arcs: [bedtime]`.
  - Mod verilmeyen istek yalnızca `standard` arka gider.
- **Şablonlar** ark bazında ayrılır (`OfflineStoryComposer.templates`).
  - Uyku satırları yalnızca `templates/bedtime/` altındadır (`arc: bedtime`).
  - Standart masal bu satırları görmez, uyku masalı da standart satırları görmez. Bu yüzden diğer modlarda tohum kayması olmaz.
- **Yer:** `SettingTrait.isRestingPlace` taşıyan yerler (Ay Pencereli Oda, Mavi Perdeli Oda).
  - Bu yerler yalnızca uyku arkına bağlanır; uyku arkı da yalnızca bu yerlere bağlanır (`OfflineContentBinder.bind`).
  - Yaşam alanları `garden, forest` olduğu için kirpi, tavşan ve baykuş gelebilir.
- **Denetleyici** (`BeatSequenceValidator`, `arc: .bedtime`). Aşağıdaki kurallar ihlal edildiğinde masal reddedilir (fatal):
  - doruk ≤ ceil(2n/3) ve ≤ n−2
  - son sayfa 0
  - doruk tedirginlik, kaygı, kuşku, hayal kırıklığı ya da duraksama olamaz
  - son sayfada `carry_forward` yok
  - 3-4 bandında tavan 1
- **Son sayfa** `CalmEnding`'den geçer: soru, "yarın", "acaba", "birden" yok. Bu kural bugüne kadar yalnızca seri bölümlerine uygulanıyordu.
- **Bütünlük denetimi** (`checkArcs`):
  - Uyku masalı için uygun yer vardır.
  - Her uyku beat'i için kendi bandında satır vardır.
  - Hiçbir uyku satırı ya da yeri `darkness`, `alone` ya da `fear` konusuna değmez.
- **Masal ailem:** `familyMoments` listesine `establish_ordinary` eklendi; aile karakteri ilk sayfada da yer alır. Bu beat'i yalnızca uyku blueprint'leri kullanır.

## Seri

21 Ekim 2026'dan beri odada açılan bir uyku masalına da "Devam ettir" sunulur. Seri, arkını ilk masalın yerinden okur (`SeriesPlanner.arc(of:)`): odada açılan masal yalnızca `arc: bedtime` devam bölümleriyle, bahçe/orman masalı (21 Ekim öncesi uyku masalları dahil) yalnızca standart bölümlerle sürer.

- **Bölümün yolu:** uyku saati gelir, yol arkadaşı pencereye yine gelir (tanıştırılmaz). Pencerenin önünde bakıma muhtaç küçük bir şey vardır. Çocuk uyumadan önce ona bakar, o rahat eder, çocuk aynı odada uykuya dalar.
- **İki mekanizma, A-B-A-B:**
  - `bp_cont_bedtime_staying_001` / `_age3_001` (bekleyen çocuk): revisit, notice_anomaly, (5-6: approach), take_charge, tend, patient_wait, restore, warm_close.
  - `bp_cont_bedtime_settling_001` / `_age3_001` (yer açan çocuk): revisit, notice_anomaly, (5-6: examine), commit + receive_appeal, first_attempt, let_go, restore, warm_close.
  - Eğri 5-6'da `0,1,1,1,1,0,0,0` (doruk s.5), 3-4'te `0,1,1,1,0,0` (doruk s.4); doruk yumuşak bir şaşkınlık (`surprise`). Kontur `BeatSequenceValidator.checkBedtimeContour` ile denetlenir.
- **Keşif nesneleri:** odanın yaşam alanında (`garden, forest`) `impliesNeed` taşıyan 4 nesne var: ince ses, düşmüş yuva, solan fide, kayıp eldiven. İnce ses her zaman ilk masalın hatırasıdır (`keepsake`), o yüzden bölümlerde 3 yeni nesne kalır; dördüncü bölümde biri geri gelir, ama hiçbir zaman üst üste iki bölümde değil. Bekleyen çocuk `impliesNeed` ister; yer açan çocuk ayrıca `isVisible` ister (ses bir köşeye konamaz).
- **Yeni nesne eklenmedi**, bilerek: nesne listesi standart masalların keşif seçimine de girer, yeni bir nesne bahçe/orman masallarının tohumlarını kaydırırdı.
- **Satırlar** `templates/bedtime/beat_bedtime_series_*.json` (`arc: bedtime`, `series: true`). Şablon kimliği `series_bedtime_<bant>_<beat>`, standart bölüm satırlarıyla çakışmaz. Aile anları (revisit, warm_close) için her ilişkide en az 2 satır var. Son sayfa `CalmEnding`'den geçer ve odayı adıyla söyler.

## Bilerek değişmeyen

- Öğrenme ve macera modları ile onların masalları. Tohumlar ve aile fixture'ının bu modlardaki kayıtları birebir aynı.
- Eski üç charge blueprint'i katalogda duruyor ama hiçbir moda girmiyor; kayıtlı masallar için gerekli.
- 7-8 ve 9-10 bantları hâlâ en yakın banttan sunuluyor.
