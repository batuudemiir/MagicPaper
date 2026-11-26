# C2 — 90 kitap olay tasarımı

25 Kasım 2026. Tasarım önerisi; uygulanmış/editoryal onaylı değildir.

15 hücre × mevcut iki mekanizma × üç olay = 90 kitap / 720 sayfa. Eski 30 kitap ve kaynakları aynen `event01` sayılır; 60 kitap/480 sayfa eklenir. Kaynaklardaki mevcut `_v2` editoryal düzeltme anlamındadır, olay anlamına gelmez. Yeni örnek: `pilot56_book_l1_fox_event02_v1`, `pilot56_source_l1_fox_event02_p01_v1`.

## Kanıt ve tercih

`Content/Pilots/five-friends-56-v1/structures.json` dokuz mekanizma/30 izinli eşleşmeyi; `books/*.json` kişilik/anatomi/çocuk eylemini belirler. `build_runtime_package.py` tek corpus, pointer ve kaynak hash zincirini kullanır. `P56StructureValidator.swift` U3 remembered nesneleri, L3 damla sırasını, A3 kök/mendil typed fact'lerini somut olarak doğrular. Bu tasarım bunları korur; kitap araştırmasına dayanan yeni pedagojik iddia içermez.

Sözcük/nesne değişimi olay çeşitliliği sağlamaz; yeni mekanizmalar motor kapsamını büyütür. Öneri: aynı mekanizmada farklı engel, karar ve sonuç zinciri. Her arkadaş için ayrı katkı/metin yazılır.

## Tam varyant matrisi

T Tarçın; K Kestane; Y Yıldız; S Simit; B Böğürtlen. İzinli arkadaşlar mevcut corpus ile aynıdır.

| Mekanizma / eşleşmeler | event02: olay, engel, çocuk kararı, sonuç | event03: olay, engel, çocuk kararı, sonuç | Koşul ve somut inceleme |
|---|---|---|---|
| U1 tanıdık ses ritüeli / T,Y,B | Çocuk sakin el sürtme sesini seçer. Ses hareket sürdükçe sürer. Arkadaş dinler; çocuk hareketi durdurur, ses biter, dikkatini bırakır. | Çocuk yorganı bir kez düzeltmenin hışırtısını seçer. Sesi yinelemek yerine kumaşı bırakır. Arkadaş sessiz kalır; çocuk artık ses beklememeyi seçer. | Birinde sürdürülen eylemi durdurma, diğerinde tekrarı başlatmama var. Çocuk sesi adlandırır. Korkutucu dış ses/kaynak arayışı yok. Ani ses ancak gerçek metinde varsa risk incelemesine girer. |
| U2 rahatlık ve alan / K,S,B | Katlı örtü dinlenme yüzeyinde çıkıntı yapar. Arkadaş düz alan ister; çocuk örtüyü zemine serer. Arkadaş deneyince çocuk yeniden düzeltmekten vazgeçer. | Minder açık geçişi daraltır. Arkadaş yanında boş alan ister; çocuk minderi yana alır. Arkadaş kendi yerini seçer; çocuk onu yeniden konumlandırmaz. | Yüzey engeli ile mesafe engeli farklıdır. B geniş zeminde, K dikenleri/S kuyruğu serbest. Sıkışma yazılmaz; dar alan sözü tek başına sıkışma etiketi değildir. |
| U3 tek anı ve bırakma / T,K,Y,S | Çocuk gündüz gölgesinin kendisi durunca durduğu anı seçer. Bütün yürüyüş yerine yalnız durma anını söyler; arkadaş dinler, çocuk anlatmayı bitirir. | Çocuk gündüz yaprağın avucundan ayrıldığı anı seçer. Sonraki yolunu anlatmak yerine yalnız bırakma anını söyler; arkadaş kabul eder, çocuk ayrıntıyı bırakır. | U3 yeni sorun, kayıp arayışı, ertesi gün sözü veya kanca taşımaz. Gölge/yaprak remembered, odada fiziksel nesne değil. Gölgeye korku verilmediği ve hatıranın şimdiki eylem olmadığı incelenir. |
| L1 iki gözlemle neden testi / T,Y,S | Bir yaprak her sallandığında ses çıkarmıyor. Arkadaş sessiz bir salınım görür; çocuk temaslı ve temassız salınımı karşılaştırır. Sesi hareketle değil temasla eşler, tekrar doğrular. | İki yaprak aynı dalın yanında sallanır, yalnız biri değer. Arkadaş uzaktakinin hareketini gösterir; çocuk iki adayı sırayla gözler, sesi değen yaprakla eşler ve yeniden doğrular. | Zaman karşılaştırması ile iki aday karşılaştırması farklıdır. P5 gerçek temas/P6 çocuk çıkarımı/P7 yeniden gözlem. Yeni observedAbsence exact-quote istisnası gerektirmeyen pozitif gözlem seçilir. Dala çekme/tırmanma yok. |
| L2 görüş birleştirme / K,Y,B | Yerdeki yaprağın ortasını iki dökülmüş yaprak örter. Arkadaş sapı görür; çocuk diğer yana geçip sivri ucu ve aynı damarı izler. Uçları tek yaprak olarak birleştirir; örtüyü çekmez. | Kıvrılmış yaprağın yakın kenarı uzak kenarını gizler. Arkadaş sapı bir yandan görür; çocuk çevresinde yürüyüp diğer kenarın aynı kıvrıma bağlandığını görür. Yaprağı açmadan biçimi birleştirir. | Dış örtüşme ile nesnenin kendi kıvrımı farklıdır. P7 bütün biçim iki görüşten anlaşılır; gizleyen nesne kendiliğinden yok olmaz. Y alçak dengeli tünekte; B geniş yerde; K aşağı bakış verir. |
| L3 bekle ve gözle / T,K,S,B | Aynı yaprakta iki damla yaklaşır. Çocuk sallamak yerine birleşmeyi bekler; iki küçük damlayla oluşan büyük damlayı karşılaştırır. Birleşen damla uçtan düşer. | Aynı damla yaprak damarında ilerler. Çocuk damarı sabit referans seçer, itmek yerine bekler. Önce ortada sonra uçta olduğunu karşılaştırır; damla düşer. | Birleşme/büyüme ile konum değişimi farklıdır. P5 değişim/P6 karşılaştırma/P7 düşüş; arkadaş bekleme desteğidir, kanıt çocuğun gözlemidir. Su içme/su kenarı yok; damla için güvenlik politikası ayrıca okunur. |
| A1 güvenli eşiği kendi hızında geç / T,K,S | Çocuk gölgeli başlangıçtan düz güneşli hedefe ilerler. İlk adımda aydınlık yüzeyi fark edip mola yerini seçer, ardından kısa adımlarla varır ve döner. | Düz zemindeki doğal renk sınırı yolu yeniymiş gibi gösterir. Çocuk iki yanı gözler, ilk adımı sınırda bitirir; sağlam zemini görünce devamını kendi seçer, varıp döner. | Duyusal geçişte mola ile görünen sınırda adım yerleştirme farklıdır. Yanma, boşluk, su, köprü, tehlike yok. Başlangıç/hedef/ilk duruş yeri metinde açık olmalı. |
| A2 tamamlayıcı katkıyla iki parçayı sırala / T,Y,B | İşaret parçalarından birinin yönü terstir. Arkadaş birini sabit tutar; çocuk kesik çizgilerin birleşmesi için ötekini döndürüp sıralar. Ok tanıdık geniş dönüş yolunu gösterir. | Parça kenarları benzerdir fakat kısa-uzun çizgi dizisi yalnız bir sırada devam eder. Arkadaş bir parçayı tutar; çocuk devam desenini karşılaştırıp sırayı seçer, okunur işaretle dönerler. | Yön çevirme ile sıra seçimi farklıdır. Y yalnız çizgileri gözler; parça tutmaz, kanatlarına insan eli işlevi verilmez. B güçle çözmez. Kaybolma eklenmez. |
| A3 kendi gözlemini izleyerek dön / K,Y,S,B | Çocuk mendili çatallı kökün güneş alan tarafına koyduğunu hatırlar. Benzer iki açıklığı kendi gördüğü ışıklı taraftan ayırt eder; kısa yoldan döner, kökü tanır, mendili alıp cebine koyar. | Çocuk mendili koyarken kökün önünden geçip geri dönerek yerleştirdiğini hatırlar. İlk benzer köke yönelmek yerine kendi dönüş sırasını izler; doğru kökü tanır, mendili alıp cebine koyar. | Yer ilişkisi ile kişisel eylem sırası farklı kanıttır. P5 kök görünür/P6 mendil elde/P7 cepte. Mendil/çatallı kök korunur; typed fact adı yalan olmaz. Arkadaş kokuyla/uçarak çözmez. Nesne kaybı var; çocuk kaybolması/panik yok. |

## Arkadaş ve metin sözleşmesi

Tarçın acele ettirmez. Kestane küçük adımları sever, sürekli korkulu değildir. Yıldız az konuşur, ipucu verir; cevap çocuğundur, kanat/dengeli ayak korunur. Simit her kitapta şehirden bugün ziyarete geldiği bilgisiyle yerleşir; ormanın eski sakini/uzmanı değildir, kıvrık kuyruğu korunur. Böğürtlen geniş yerde durur; gücü çocuk fikrinin yerine geçmez. P3 her arkadaş için bu kimlikle ayrı yazılır.

Her yeni kitap tam sekiz sayfa, sayfa başına 18–38 kelime, cümle başına en fazla 14 kelime; kişiselleştirilmiş metinde de geçerli. Aynı beat sırası/çocuk çözümü korunur. Sayfa ve cümle source ID, SHA, subject, temporal durum, action evidence, causal quote ve art handoff gerçek yeni metinden çıkarılır. Art onayı false/runtimeArt null; bağımsız editoryal onay beklenir.

## Çoklu varyant için şema önerisi

- Eski authored corpus değişmez. Ayrı `Content/Pilots/five-friends-56-expansion-v1/`: manifest, sources, 60 kitap, ek causal map. Yeni manifest kaydı `id,file,sha256FileBytes,baseBookID,variantID` taşır. `baseBookID` köken bağıdır, metin yerine kullanılamaz.
- Runtime v1 paket ve SHA tarihsel snapshot olarak korunur. Geniş pakete yeni packageVersion verilir. P56Request/P56SourceReference sözleşmesi değişmez; eski snapshot için current fallback yok.
- Önerilen runtime `schemaVersion=2`: `authoredCorpora:[{id,sourceJSON,sourceSHA256}]`; kitapta `authoredCorpusID,variantID,baseBookID`; sayfada `parentCorpusID`. Parent pointer corpus içindeki `sources.json#/sources/N` olarak kalır. Bir corpus indeksi ötekine uygulanamaz. V1 loader/validator aynen korunur, v2 açık decode edilir. Nihai tip kararı motor sahibinindir.
- Kaynak ID kümesi global tekil; corpus+pointer+sourceID+digest+text zinciri doğrulanır. Attribution kaynağı aynı kitabın corpus ve sayfalarındadır. 480 yeni causal kayıt; birleşik 720. Her `(bookID,pageNumber)` tekil ve 1...8 eksiksiz olmalı.
- Sabit 30/240 beklentisi v1'de kalır; v2 tam 90/720 ve 15 hücre×2 izinli yapı×3 olay doğrular. 30 izinli yapı/arkadaş eşleşmesi değişmez. Her eşleşmede event01/02/03 bulunur; yanlış dağıtılmış toplam sayı yetmez.
- Seçim sabit kitap ID sırasından yapılır; aynı seed+paket aynı sonuç. Yeni paket seed çıktısı değişebilir; eski snapshot+seed değişmez. N1500 kitap/yapı/olay bazında raporlanır; 90 sayısı düşük tekrar garantisi değildir.
- Discovery ID yalnız anlamı aynıysa korunur; yeni nesneye yeni ID/subject gerekir. L2 metadata eski dal açıklamasını kopyalamaz. L3 damla ve A3 mendil/kök korunarak fakt genişlemesi önlenir.

## Güvenlik ve konu kanıtı

Risk etiketleri her son yazılmış anlatıya göre ayrı değerlendirilir; tablo etiket enum'u icat etmez. Mevcut ContentSafety gerçek key listesi okunmadan toplu boş risk listesi, blanket safeForAll veya bütün kitaplara aynı risk etiketleri atanmaz. Her karar kitap/sayfa/source quote kanıtıyla kaydedilir. Olumsuzlanan tehlike mevcut olay değildir. Yukarıdaki somut inceleme koşulları nihai metin incelemesine yol gösterir.

Topic ID tahmin edilmez. Güncel topic katalog kaydı, yaş/mod uygunluğu ve metinde gerçekten işlenen konu kanıtı gerekir; kapsam yoksa destek reddi sürer.

## Durum

Yalnız tasarım belgesi. Kod, corpus, payload ve test değişmedi; test çalıştırılmadı. Ortak durum/changelog liderin sahipliğinde. Sonraki adım: motor sahibinin çoklu corpus sözleşmesiyle uzlaştırma, ardından 60 kitabın kaynaklı yazımı ve metin bazlı editoryal/güvenlik incelemesi.
