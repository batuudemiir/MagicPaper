"""Offline editorial source, not a runtime composer or bundled resource.
Run to serialize the authored corpus. Runtime engine validation is separate.
"""
from pathlib import Path
import hashlib, json, re
ROOT = Path(__file__).resolve().parent
DRAFT = 'authored-internal-review-required'
CHARACTERS = {
 'fox': ('Tarçın', 'companion_fox_pilot_001', 'Sakin eşlik; acele ettirmez; çocuğun kararını bekler.', 'Dört ayak; doğal tilki ölçeği.'),
 'hedgehog': ('Kestane', 'companion_hedgehog_pilot_001', 'Küçük adımlarla cesaretlenir; her sahnede kaygılı değildir.', 'Dört kısa ayak; dikenler korunur.'),
 'owl': ('Yıldız', 'companion_owl_pilot_001', 'Az konuşur; dikkatle gözler; cevabı çocuğa bırakır.', 'Kanatlar; tünekte dengeli ayaklar; dört ayaklı gibi kıvrılmaz.'),
 'cat': ('Simit', 'companion_city_cat_001', 'Şehirden bugün ziyarete gelmiştir; meraklı; yavaşlamayı dener.', 'Kıvrık simit kuyruğu; dört ayak. Ormanın eski sakini değildir.'),
 'bear': ('Böğürtlen', 'companion_bear_001', 'Sakin ve güçlü; çocuğun fikrini dinler; güç cevap yerine geçmez.', 'Büyük beden; geniş zemin; küçük pervaz/yatak yok.')}
ROOM='pilot56_setting_forest_edge_room_v1'
FOREST='setting_whispering_forest_001'
# Page moves are editorial state contracts, deliberately NOT StoryBeat raw values.
SHAPES={
'U1': dict(mode='bedtime', title='Odanın Yumuşak Sesleri', allowed=['fox','owl','bear'], mechanism='familiar-sound-ritual', moves=['settled_room','ritual_chosen','friend_listens','child_names_sound','soft_smile','attention_released','awake_rest','closed_calm'], obstacle='Uyku öncesi hangi sakin sese kulak verileceği.', solution='Çocuk bildiği sesleri sırayla seçip dinlemeyi bırakır.', prop='room_sounds', pages=[
'Deniz, Orman Kıyısındaki Oda’da yatağına oturdu. {name} de odadaydı. Pencere kapalıydı; akşamın soluk ışığı yerde duruyordu. Bu gece hiçbir yere gitmeleri gerekmiyordu.',
'Perdenin ucu duvara usulca değdi. Deniz bu sesi biliyordu. "Önce bunu dinleyelim," dedi. Örtüsünü dizlerine çekti; sesi aramak için kalkmadı. Odadaki her şey yerli yerindeydi.',
'',
'Deniz başını yastığa yaklaştırdı. Kendi nefesinin örtüye değen sesini duydu. "Bu da benim sesim," dedi. Bir sesi ötekinden ayırmak için acele etmesine gerek yoktu.',
'',
'',
'Deniz artık sesleri saymıyordu. Örtü omuzlarında hafifti. Arkadaşı da kendi yerinde uyanık ve rahattı. Odanın tanıdık sesleri, ilgilenmeleri gereken işler olmadan sürüp gidiyordu.',
'Orman Kıyısındaki Oda sessizce dinleniyordu. Deniz gözlerini kapattı. Arkadaşı rahat yerinde kaldı. Söylenecek son bir söz, bulunacak son bir ses yoktu. Bu akşam tamamlanmıştı.']),
'U2': dict(mode='bedtime',title='Tam Bana Göre Bir Yer',allowed=['hedgehog','cat','bear'],mechanism='comfort-choice-and-space',moves=['settled_room','comfort_need','friend_preference','child_prepares','soft_trial','child_yields_space','awake_rest','closed_calm'],obstacle='Arkadaşın kendi bedenine uygun rahatlığı henüz seçmemesi.',solution='Çocuk seçeneği hazırlar, tercihi dinler ve alan bırakır.',prop='resting_material',pages=[
'Orman Kıyısındaki Oda akşam için hazırdı. Deniz yatağında, {name} yanında duruyordu. Yerde arkadaşının rahatça dinlenebileceği boş bir alan vardı. Kapalı pencerenin önüne hiçbir yatak konmamıştı.',
'Deniz arkadaşına yer hazırlamak istedi. "Yumuşak mı olsun, düz mü?" diye sordu. İki seçeneğin de iyi olabileceğini düşündü. Arkadaşının cevabını beklerken örtüsünü yatağında bıraktı.',
'',
'Deniz yerdeki alanın kenarına oturdu. Hazırladığı yerin girişini açık bıraktı. Arkadaşı rahatça yaklaşabilsin diye dizlerini geri çekti. "Sen dene, ben burada bekleyeyim," dedi.',
'',
'',
'Arkadaşı seçtiği yerde uyanık dinleniyordu. Deniz kendi yatağına döndü. Yaptığı hazırlığı yeniden düzeltmedi; rahatlığın nasıl olacağını artık arkadaşı biliyordu. Odada geniş, sakin bir boşluk kaldı.',
'Orman Kıyısındaki Oda’da herkes kendi yerindeydi. Deniz örtüsünü çekip gözlerini kapattı. Arkadaşı rahatça dinlenmeyi sürdürdü. Yerler hazırlanmış, küçük iş bitmişti. Akşam yavaşça kapanıyordu.']),
'U3':dict(mode='bedtime',title='Günden Kalan Bir Ayrıntı',allowed=['fox','hedgehog','owl','cat'],mechanism='one-memory-then-release',moves=['settled_room','one_memory_selected','friend_receives_memory','child_limits_telling','soft_shared_memory','story_released','awake_rest','closed_calm'],obstacle='Günün bütün ayrıntılarını anlatma isteği.',solution='Çocuk bir ayrıntı seçer ve anlatının bittiğine kendisi karar verir.',prop='remembered_day_detail',pages=[
'Deniz ile {name}, Orman Kıyısındaki Oda’daydı. Deniz yatağına oturmuştu. Gündüz bitmiş, odanın ışığı azalmıştı. Şimdi dışarıdaki oyunları sürdürmek yerine birlikte dinleniyorlardı.',
'Deniz o günü düşündü. Aklına pek çok küçük an geldi. Hepsini anlatmasına gerek yoktu. "Bir tanesini seçiyorum," dedi. Hatırlayacağı şey, odada bulunan yeni bir eşya olmayacaktı.',
'',
'Deniz anlatacağı anı başından sonuna düşündü. Başka bir oyuna geçmek üzereyken durdu. "Bu akşam yalnız bu kadar," dedi. Seçtiği küçük anın kendi başına yeri vardı.',
'',
'',
'Deniz artık gündüzü anlatmıyordu. Hatırladığı şeyler odanın içinde belirmemişti. Yanında yalnız arkadaşı ve tanıdık akşam eşyaları vardı. İkisi de uyanık, söz söylemeden rahatça bekledi.',
'Orman Kıyısındaki Oda’nın ışığı yumuşaktı. Deniz gözlerini kapattı. Günün seçtiği küçük anı tamamlanmıştı. Arkadaşı dinleniyordu. Hikâyenin devam etmesi gerekmiyordu; bu akşam burada, sakince bitmişti.']),
'L1':dict(mode='learning',title='Tıkırtının İki İpucu',allowed=['fox','owl','cat'],mechanism='two-observation-causal-test',moves=['sound_noticed','first_guess','friend_one_observation','child_predicts','observe_contact','child_infers','recheck','closed_result'],obstacle='Sesin dal mı yaprak mı olduğu ilk bakışta anlaşılmıyor.',solution='Çocuk aynı anda görülen temas ve duyulan sesi birleştirir.',prop='dry_leaf_and_trunk',pages=[
'Fısıldayan Orman’da Deniz ile {name}, geniş patikanın yanında durdu. İnce bir tıkırtı duyuluyordu. Alçak bir dala takılmış kuru yaprak, ağaç gövdesinin hemen önünde sallanıyordu.',
'"Dal mı ses çıkarıyor?" dedi Deniz. Dalın ucunu izledi. Dal kıpırdıyor, fakat her kıpırdayışta ses gelmiyordu. Deniz tahminini henüz doğru saymadı. Bakması gereken başka bir ayrıntı vardı.',
'',
'Deniz kuru yaprakla gövde arasındaki boşluğa baktı. "Birbirine değince dinleyeceğim," dedi. Dala uzanmadı. Kendi bulunduğu yerden hem yaprağı görebiliyor hem sesi duyabiliyordu.',
'',
'',
'Bir esinti daha geldi. Yaprak gövdeye değdi; ince ses yine duyuldu. Deniz gülümsedi. Tahmini iki ayrı bakışta aynı sonucu vermişti. Dalın her hareketinin ses olmadığını artık ayırabiliyordu.',
'Deniz ile arkadaşı geniş patikadan ayrıldı. Kuru yaprak ağaçta kaldı. Deniz sesi yanına alamazdı, fakat nasıl çıktığını anlatabilirdi. Ormanda küçük bir ayrıntıyı dikkatle görmüş olmak ona yetti.']),
'L2':dict(mode='learning',title='İki Taraftan Bir Yaprak',allowed=['hedgehog','owl','bear'],mechanism='combine-viewpoints',moves=['partial_shape','first_view','friend_second_view','child_repositions','compare_views','child_combines','whole_seen','closed_result'],obstacle='Düşmüş dal yaprağın orta bölümünü örtüyor.',solution='Çocuk iki yan görünüşü birleştirir, nesneyi çekmez.',prop='leaf_under_branch',pages=[
'Deniz ile {name}, Fısıldayan Orman’daki düz açıklıkta durdu. Yerdeki düşmüş dalın altından yeşil bir uç görünüyordu. Dalın öte yanında da yeşil bir kıvrım vardı. Dal kıpırdamıyordu.',
'Deniz bulunduğu taraftan ince uca baktı. "Uzun bir şey görüyorum," dedi. Oradan yalnız bir bölümü seçiliyordu. Daha iyi görmek için dalı kaldırmak yerine çevresindeki açık yere baktı.',
'',
'Deniz geniş açıklıktan dolaşıp dalın diğer yanına geçti. Arkadaşı için de açık geçiş vardı. Şimdi yuvarlak kıvrımı görebiliyordu. Biraz önce gördüğü ince uç, aynı dalın arkasında kalmıştı.',
'',
'',
'Deniz biraz yana eğildi. İki yeşil parçanın ortadaki sapla birleştiği aralık görünüyordu. Dalın altında tek bir yaprak vardı. Onu yerinden çıkarmadan, iki taraftan bakarak bütününü anlamışlardı.',
'Deniz patikaya dönerken iki tarafı da düşündü. İlk gördüğü uç doğruydu; arkadaşının gördüğü kıvrım da doğruydu. Birlikte düşününce yaprak tamamlanmıştı. Yerdeki dal ve yaprak oldukları yerde kaldı.']),
'L3':dict(mode='learning',title='Damlanın Bekleme Zamanı',allowed=['fox','hedgehog','cat','bear'],mechanism='wait-and-reobserve',moves=['drop_noticed','first_observation','friend_waits','child_observation_plan','visible_change','child_compares','drop_falls','closed_result'],obstacle='Çocuk değişimi görmek istiyor; yaprağı sallamak gözlemi bozacak.',solution='Çocuk dokunmadan bekler ve aynı damlanın büyüyüp düşmesini karşılaştırır.',prop='dew_drop_on_leaf',pages=[
'Fısıldayan Orman’da Deniz ile {name}, alçak bir yaprağın yanında durdu. Sabah yağmurundan kalan su, yaprağın ucunda toplanıyordu. Küçük damla henüz yere düşmemişti. Patikanın zemini düzdü.',
'Deniz damlanın ince ucuna baktı. "Biraz uzadı mı?" diye sordu. Parmaklarını kendine çekti. Yaprağı sallarsa damla düşebilirdi, ama kendi kendine nasıl değiştiğini artık göremezdi.',
'',
'"Aynı yerden bakalım," dedi Deniz. Patikadaki yassı taşın yanına çömeldi. Yaprağa dokunmadı. İlk gördüğü küçük, yuvarlak damlayı aklında tuttu; şimdi yalnız yeniden bakmak için bekleyecekti.',
'',
'',
'Sonunda damla yapraktan ayrılıp toprağa düştü. Deniz yaprağın ucunda kalan küçücük ıslaklığı gördü. Hiç kimse dalı çekmemişti. Beklemek de değişimi görmenin bir yolu olmuştu.',
'Deniz doğrulup arkadaşına gülümsedi. Tek bir damlanın zamanını izlemişlerdi; bütün damlaların aynı sürede düşeceğini söylemediler. Yaprak yerinde kaldı. İkisi de sakin adımlarla orman patikasına döndü.']),
'A1':dict(mode='adventure',title='Açıklığın Küçük Adımları',allowed=['fox','hedgehog','cat'],mechanism='self-paced-safe-threshold',moves=['safe_goal','approach','friend_support','child_step_choice','first_step','child_crosses','goal_reached','closed_return'],obstacle='Tanıdık patikadan güneşli açıklığa geçmekteki küçük tereddüt.',solution='Çocuk adımlarının büyüklüğünü seçerek düz açıklığı kendisi geçer.',prop='sunlit_clearing',pages=[
'Deniz ile {name}, Fısıldayan Orman’daki geniş patikadaydı. Yanlarında düz, güneşli bir açıklık uzanıyordu. Karşı kıyıdaki büyük ağacın gölgesine gidip geri dönmek istediler. Uçurum ya da su yoktu.',
'Deniz açıklığın başında durdu. Güneşli yer ona patikadan daha geniş görünmüştü. Acele etmeden zemine baktı. Kuru ve düzdü. Nerede duracağını kendisi seçebilirdi; ağaca birden varması gerekmiyordu.',
'',
'Deniz önündeki açık toprağa baktı. "Önce buraya kadar," dedi. Bir adımlık yer seçti. Arkadaşı onu çekmedi, önünden çağırmadı. Açıklığın kenarı, isterse bekleyebileceği kadar yakındı.',
'',
'',
'Büyük ağacın gölgesine kendi ayaklarıyla vardığında Deniz geriye baktı. Biraz önce uzak gelen açıklık, birkaç küçük adımdan oluşmuştu. Arkadaşı yanındaydı. İkisi de ağacın serin gölgesinde durdu.',
'Deniz ile arkadaşı aynı düz yoldan patikaya döndü. Güneşli açıklık aralarında kaldı. Yarış yapmamışlardı; bir yere yetişmeleri gerekmiyordu. Deniz ne kadar ilerleyeceğine karar vermiş, istediği yere varmıştı.']),
'A2':dict(mode='adventure',title='İki Parçalı Yol İşareti',allowed=['fox','owl','bear'],mechanism='sequence-with-complementary-contribution',moves=['two_piece_goal','approach','friend_contribution','child_orders','first_piece','child_completes','route_confirmed','closed_return'],obstacle='İki gevşek işaret parçasının sırası bilinmeden yön okunamıyor.',solution='Çocuk desenin devamını seçer, arkadaşı bir parçayı yerinde tutar.',prop='two_wooden_marker_parts',pages=[
'Deniz ile {name}, Fısıldayan Orman’daki geniş patikada yürüdü. Açıklığa ayrılan yerde iki tahta işaret parçası vardı. Yuvaları yere yakın, geniş bir kütüğün üstündeydi. İşaret henüz tamamlanmamıştı.',
'Deniz parçalara baktı. Birinde kalın çizginin başı, ötekinde ok ucu vardı. Parçalar hafifti; fakat hangisinin önce geleceğini düşünmek gerekiyordu. İşaret bir geçidi açmıyordu, yalnız yönü gösterecekti.',
'',
'"Önce çizgi, sonra ok," dedi Deniz. Kütükteki iki yuvayı inceledi. Arkadaşının bildiği orman yolları bu yeni parçaların sırasını söylemezdi. Deniz çizgilerin birleşmesini kendi gözüyle deneyecekti.',
'',
'',
'Çizgi ok ucuyla birleşince işaret tamamlandı. Ok, yanlarındaki düz açıklığı gösteriyordu. Deniz arkadaşının katkısına teşekkür etti. Doğru sırayı bulmakla bir parçayı yerinde tutmak, farklı iki işti.',
'Deniz ile arkadaşı açıklığa yürüyüp patikaya geri döndü. Tahta parçalar kütükteki yuvalarında kaldı. Küçük iş bitmişti. Deniz bir yolu tamamlamak için bazen önce sırasını düşünmek gerektiğini gördü.']),
'A3':dict(mode='adventure',title='Kendi İzine Geri Bakmak',allowed=['hedgehog','owl','cat','bear'],mechanism='retrace-child-specific-observation',moves=['personal_loss','last_seen_recalled','friend_waits','child_selects_route','retrace','child_recognizes','object_recovered','closed_return'],obstacle='Çocuğun az önce bıraktığı mendilin yeri yalnız kendi hatırladığı ayrıntıyla bulunabilir.',solution='Çocuk dönüşte kendi gördüğü çatallı kökü tanır ve mendili alır.',prop='child_cloth_at_root',pages=[
'Deniz ile {name}, Fısıldayan Orman’daki açıklıkta durdu. Deniz cebine baktığında küçük mendilinin olmadığını fark etti. Biraz önce patikada yürümüşlerdi. Mendil evden getirdiği, kendine ait bir eşyaydı.',
'Deniz durup düşündü. "Ayakkabımdaki toprağı silerken çıkarmıştım," dedi. Yanında çatallı bir kök gördüğünü hatırlıyordu. Şimdi kök burada değildi; görüntüsü yalnız aklındaydı. Mendilin nerede kaldığını henüz bilmiyorlardı.',
'',
'Deniz geldikleri patikayı gösterdi. "Kökü aramak için bu taraftan döneceğim," dedi. Yavaşça yürümeye başladı. Arkadaşı yolu tahmin ederek başka yöne sapmadı. Aradıkları, yalnız bu yürüyüşte bırakılmış küçük bir eşyaydı.',
'',
'',
'Deniz mendili silkeleyip cebine koydu. Kökün üstünde başka bir şey bırakmamıştı. Arkadaşına baktı, sonra boş kalan yere. Durup hatırlamak, geçtiği yolu yeniden okumasına yardım etmişti. Arama bitmişti.',
'Deniz ile arkadaşı geniş patikadan açıklığa geri döndü. Mendil bu kez cebindeydi. Onu bulan arkadaşının orman bilgisi değil, Deniz’in hatırladığı küçük ayrıntı olmuştu. İkisi yan yana sakin bir yürüyüşü tamamladı.'])}
# Distinct contributions and child responses, not global name substitution.
TAILORED={
'U1':{
'fox':('Tarçın yere uzanmadan önce Deniz’in seçtiği sesi dinledi. "Perdeyi duydum," dedi. Başka ses aramadı. Deniz konuşmak isterse bekleyecek kadar sessizdi; odada bir soru çözmeleri gerekmiyordu.', 'Deniz perdenin ikinci yumuşak dokunuşunda gülümsedi. Tarçın da kulaklarını rahat bıraktı. Bu, cevap bekleyen bir oyun değildi. İkisi tanıdık sesi duyup olduğu yerde bırakabildi.', '"Dinlemeyi bitirdim," dedi Deniz. Tarçın geniş minderine yerleşti, gözleri açıktı. Deniz ışığı biraz kıstı. Sonra örtüsünün altına girdi; hiçbir sesi yeniden yakalamaya çalışmadı.'),
'owl':('Yıldız alçak, sağlam tüneğinde duruyordu. Kanatları doğal biçimde kapalıydı. "Perde," dedi yalnızca. Deniz başıyla onayladı. Baykuş odanın içindeydi; ne uçuyor ne dışarıdaki bir sesi arıyordu.', 'Deniz nefesini dinlerken kaşlarının gevşediğini fark etti. Yıldız başını hafifçe ona çevirdi. İkisi konuşmadan gülümsedi. Tanıdık sesleri anlatmak için uzun sözlere ihtiyaçları kalmamıştı.', 'Deniz "Bu kadarı yeter," diye fısıldadı. Yıldız tüneğinde dengeli durdu, gözleri açıktı. Kanatlarını gövdesine yakın tuttu. Deniz örtüsüne yaslandı; odada yeni bir görev başlamadı.'),
'bear':('Böğürtlen geniş yer döşeğinde oturuyordu. Büyük gövdesi kapı yolunu kapatmıyordu. "Ben de perdeyi duydum," dedi. Güçlü pençeleri dinleniyordu; odada tutması ya da kaldırması gereken hiçbir şey yoktu.', 'Deniz kendi nefesini duyunca küçük bir gülümseme belirdi. Böğürtlen ağır ağır soluk verdi. İkisi aynı sesi çıkarmaya uğraşmadı. Her birinin rahatça nefes alabileceği kadar alan vardı.', 'Deniz ışığı kıstı ve yatağına yaslandı. Böğürtlen geniş döşeğine yan yattı; gözleri açıktı. Büyük bedeni bütünüyle döşeğin üstündeydi. Deniz onun yerini yeniden düzenlemeye çalışmadı.')},
'U2':{
'hedgehog':('Kestane düz minderle katlı bezi inceledi. "Düz olanı deneyeyim," dedi. Dikenlerine takılacak püsküller istemiyordu. Deniz püskülsüz minderi açık yere koydu. Kestane kendi kısa adımlarıyla yaklaşabilecekti.', 'Kestane minderin üstüne çıktı, sonra bir adım geriye indi. "Biraz daha açık olsun," dedi. Deniz katlı bezi kenara aldı. Denemek yanlış yapmak değildi; yerin nasıl rahat olacağını gösteriyordu.', 'Deniz bir adım çekildi. Kestane açık kalan mindere yeniden yerleşti, dikenleri rahatça duruyordu. "Böyle iyi," dedi. Deniz bunu duyunca hazırlığı bitirdi; başka bir şey eklemedi.'),
'cat':('Şehirden ziyarete gelen Simit, odadaki geniş minderi kokladı. Kıvrık kuyruğu ayağına dolanmıyordu. "Düz tarafı deneyeyim," dedi. Deniz minderin üstündeki katlı bezi alıp yanına koydu.', 'Simit minderin çevresinde küçük bir tur attı, sonra durdu. Deniz gülümsedi. "Yerini seçiyorsun," dedi. Kedi son bir kez zemini kokladı; artık odada dolaşmak yerine minderi denemeye hazırdı.', 'Deniz mindere uzanmayı bıraktı. Simit minderin düz tarafına yerleşip ön ayaklarını rahatça uzattı; kıvrık kuyruğu yanında görünüyordu. Gözleri açıktı. Rahat yerini kendisi seçmiş, hareketini kendi isteğiyle yavaşlatmıştı.'),
'bear':('Böğürtlen geniş yer döşeğine baktı. "Başımın altına ince bir kat yeter," dedi. Deniz hafif bezi döşeğin başına serdi. Ayının büyük bedeni için yer genişti; küçük minder yatağı değildi.', 'Böğürtlen önce oturdu, sonra başının altındaki katı denedi. "Bir kat daha az olsun," dedi. Deniz yalnız hafif bezin üst katını açtı. Döşeği ya da ayıyı taşımaya çalışmadı.', 'Deniz döşeğin yanından çekildi. Böğürtlen geniş zeminde yan yattı, başı ince bezin üstündeydi. Gözleri açıktı. "Tam böyle," dedi. Deniz ayının tercihine güvenip kendi yatağına döndü.')},
'U3':{
'fox':('Tarçın Deniz’in anlatacağı anı bekledi. Deniz gündüz gölge çizgisinin ayakkabısına değdiğini hatırladı. "Ben durunca gölge de yanımda kaldı," dedi. O gölge şimdi odada değildi.', 'Tarçın "O anda seni dinledim," dedi. Deniz hatırladığı küçük duruşa gülümsedi. Yeni bir gündüz hikâyesine başlamadı. İki kısa cümle, seçtiği anı paylaşmak için yeterli olmuştu.', 'Deniz "Anlatmam bitti," dedi. Tarçın odadaki minderine oturdu, gözleri açıktı. Deniz ellerini örtüsünün üstüne bıraktı. Hatırladıkları gölgeyi aramak için pencereye gitmediler.'),
'hedgehog':('Kestane başını Deniz’e doğru çevirdi. Deniz gündüz yan yana attıkları üç küçük adımı hatırladı. "İkincisinde ikimiz de durduk," dedi. Şimdi o adımlar atılmıyor, yalnız anlatılıyordu.', 'Kestane "Durduğumuz anı ben de sevdim," dedi. Kestane odada rahattı. Deniz kısa bir gülümsemeyle başını salladı. Seçtiği anı başka olaylarla doldurmadı.', 'Deniz hatırladığı adımları saymayı bıraktı. Kestane düz minderinde rahatça durdu, gözleri açıktı. İkisi yeniden yürümeye kalkmadı. Paylaşılan küçük an geçmişte, sakin odaları şimdi buradaydı.'),
'owl':('Yıldız alçak tüneğinde, kapalı kanatlarıyla Deniz’e doğru baktı. Deniz gündüz bir yaprağın üstündeki yuvarlak ışığı hatırladı. "Yaprağa dokunmadım," dedi. O yaprak odanın içinde değildi.', 'Yıldız "Gördün," dedi usulca. Başka bir soru sormadı. Deniz hatırladığı ışığın küçük olduğunu elleriyle gösterdi, sonra ellerini indirdi. Günün bir ayrıntısı söylenmiş ve duyulmuştu.', 'Deniz anlatmasını bitirip yastığına yaslandı. Yıldız tüneğinde dengeli kaldı; kanatları kapalı, gözleri açıktı. Baykuş yaprak aramak için uçmadı. Hatırlanan an, odada yeni bir işe dönüşmedi.'),
'cat':('Şehirden ziyarete gelen Simit, Deniz’in anlattığı günü dinledi. Deniz patikada durup kedinin kıvrık kuyruğuna güldüğünü hatırladı. "Sen dönünce halka da döndü," dedi. Şimdi ikisi de odada duruyordu.', 'Simit kuyruğunu yanında rahat bıraktı. "Ben o sırada kuru yaprağı kokluyordum," dedi. Bu, gündüzden kalan bir sözdü; odada kuru yaprak yoktu. Deniz kısa anının tamamlandığını hissedip gülümsedi.', 'Deniz "Bu akşamki anım buydu," dedi. Simit minderine oturdu, gözleri açıktı. Kıvrık kuyruğu yanında görünüyordu. İkisi gündüz oyununu yeniden başlatmadı; şimdi yalnız dinleniyorlardı.')},
'L1':{
'fox':('Tarçın çocuğun yanında durup kuru yaprağa baktı. "Yaprak gövdeye yaklaşırken daha net duyuyorum," dedi. Cevabı bildiğini söylemedi. Deniz bu tek gözlemi kendi ilk tahminiyle birlikte düşünecekti.', 'Deniz bakışını yaprağın ucunda tuttu. Uç gövdeye dokunduğu anda tıkırtı geldi. Tarçın sessizce bekledi. Deniz "Bir daha aynı anda olacak mı?" diye sordu; kararını kontrol etmek istiyordu.', '"Ses dalın her hareketinde çıkmıyor," dedi Deniz. "Kuru yaprak gövdeye değince çıkıyor." Tarçın başını salladı. Çocuğun iki gözlemi birleştirmesi, ilk tahmininden daha açık bir cevap vermişti.'),
'owl':('Yıldız alçak sağlam bir dalda, kanatları kapalı durdu. "Aralık kapanınca ses duyuyorum," dedi. Yalnız gördüğü şeyi söyledi. Deniz aşağıdan hem aralığı hem yaprağın ucunu izleyebiliyordu.', 'Bir esinti yaprağı gövdeye yaklaştırdı. Deniz temas anında tıkırtıyı duydu. Yıldız başını aynı noktaya çevirdi; uçmadı. Çocuk ikinci bakışında sesle dokunuşun birlikte olduğunu yeniden gördü.', 'Deniz "İki ipucu aynı yerde buluşuyor," dedi. Yaprak değdiğinde ses çıkıyor, ayrıldığında susuyordu. Yıldız kısa bir "Evet" dedi. Çıkarımı baykuş açıklamamış, çocuk gözlemlerden kurmuştu.'),
'cat':('Şehirden ziyarete gelen Simit kulaklarını sese çevirdi. Bir adım yaklaşınca durdu. "Yaprak değmeden önce ses duymadım," dedi. Merak etmişti, fakat patisiyle yaprağı dürtmüyordu. Deniz gözlem için alan buldu.', 'Simit patisini yerde tuttu. Deniz yaprak gövdeye değdiğinde tıkırtıyı duydu. "Dürtmeden de görebiliyoruz," dedi. Sonraki esintiyi beklediler; çocuğun baktığı temas noktası yeniden aynı sesi verdi.', 'Deniz "Sesi kedi yapmıyor, dalın her hareketi de yapmıyor," dedi. Kuru yaprağın gövdeye vuruşunu gösterdi. Simit kıvrık kuyruğunu sakin tuttu. Merakını paylaşmış, cevabı çocuğa bırakmıştı.')},
'L2':{
'hedgehog':('Kestane kısa ayaklarıyla dalın öte yanındaki açık zemine geçti. "Buradan yuvarlak bir kıvrım görünüyor," dedi. Çekinmeden gördüğünü anlattı. Deniz ince ucu görüyordu; ikisi henüz aynı şeyi görmüyordu.', 'Deniz bir adım yana kaydı. Kestane bulunduğu açık yerden kıvrımı yeniden tarif etti. "Uç burada, kıvrım orada," dedi Deniz. İkisinin söylediklerini zihninde yan yana koydu; dal yerinde kaldı.', '"İki ayrı şey sanmıştım," dedi Deniz. "Ama aynı yaprağın iki yanı olabilir." Kestane dar aralığı gösteren yere başını çevirdi. Deniz sapın devamını görmek için kendi bakışını biraz alçalttı.'),
'owl':('Yıldız açık zemine konmuş kalın bir kökün üstünde durdu. Kanatları kapalıydı. "Bu yanda yuvarlak," dedi. Deniz öbür tarafta ince uç görmüştü. Uçmak yerine aynı alçak düzlemden karşılaştırabilirlerdi.', 'Deniz kökün yanındaki açık yere geçti. Yıldız başını çevirdi; yerini değiştirmeden kıvrıma baktı. Çocuk iki görünüşü karşılaştırdı. Baykuşun yüksekten her şeyi bildiğini varsaymadı; ikinci görüş de yalnız bir parçaydı.', 'Deniz "İkimizin gördüğü birleşiyor," dedi. Yıldız yalnız başını eğdi. Çocuk sapın göründüğü aralığa çömeldi. İki görüşten bir bütün kurmak için son bakışı kendisi seçmişti.'),
'bear':('Böğürtlen geniş gövdesiyle dala basmadan açık yerden dolaştı. "Bu yanda yuvarlak bir kenar var," dedi. Gücüyle dalı kaldırmadı. Deniz bulunduğu taraftan gördüğü ince ucu ona anlattı.', 'Deniz ayının yanında, görüşü kapanmayacak bir yere geçti. Böğürtlen bir adım geri çekildi. Çocuk yuvarlak kenarı kendi gördü. İki farklı bakışın aynı dalın altına uzandığını fark etti.', '"Senin gördüğün de benim gördüğüm de burada," dedi Deniz. Böğürtlen sessizce dinledi. Çocuk yaprağın sapını görebileceği aralığa eğildi. Bütününü anlamak için dala ya da ayının gücüne ihtiyaç duymadı.')},
'L3':{
'fox':('Tarçın çocuğun yanına oturdu. "İstersen birlikte bekleriz," dedi. Damlanın ne zaman düşeceğini söylemedi. Deniz düşünmek için zamanı olduğunu hissetti; arkadaşının sakinliği, gözlemin yerine geçmiyordu.', 'Yaprakta biriken su uca doğru süzüldü. Deniz damlanın altının uzadığını gördü. Tarçın sessizce durdu. Çocuk ilk görünüşle şimdikini karşılaştırabilmek için bakışını aynı noktada tuttu.', '"Önce yuvarlaktı, şimdi aşağı doğru uzadı," dedi Deniz. Tarçın çocuğun sözünü bitirmesini bekledi. Kimse yaprağı düzeltmedi. Deniz farkı kendi gözleriyle bulmuştu; sonucu zorlamalarına gerek kalmadı.'),
'hedgehog':('Kestane yassı taşın yanında durdu. "Ben de buradan bakabilirim," dedi. Rahattı; dikenlerini kabartmıyordu. Deniz ile aynı damlayı izleyecek, fakat değiştiğini söylemek için çocuğun bakmasını bekleyecekti.', 'Deniz damlanın altının incelip uzadığını gördü. Kestane kısa ayakları üstünde yerini korudu. Çocuk damlanın ilk yuvarlak halini anlattı. Arkadaşı dinleyince iki görünüş arasındaki fark daha belirginleşti.', '"Büyüdü, çünkü yapraktan su geliyor," dedi Deniz, ince su yolunu izleyerek. Kestane yaprağa dokunmadan başını kaldırdı. Çocuk gördüğünü anlatmıştı; her bitkinin aynı zamanda büyüdüğünü söylemiyordu.'),
'cat':('Şehirden ziyarete gelen Simit bir adım atıp durdu. "Patilerimi taşın yanında tutacağım," dedi. Kıvrık kuyruğunu yapraktan uzağa aldı. Merakını sürdürürken damlayı dürtmemek için kendine küçük bir yöntem bulmuştu.', 'Simit patilerini aynı yerde tuttu. Deniz damlanın uzayan altını gördü. "Beklerken de bir şey oluyor," dedi. Kedi başını çevirmeden izledi; çocuğun gözlemini hızlandırmak için yaprağı sallamadı.', 'Deniz ilk küçük damlayla şimdiki uzun damlayı karşılaştırdı. Simit heyecanla yaklaşmak yerine yerinde kaldı. Çocuk "Daha ağır görünüyor, hâlâ düşmedi," dedi. Henüz olmayan bir düşüşü olmuş gibi anlatmadı.'),
'bear':('Böğürtlen geniş patikanın kenarında durdu. Büyük pençelerini yapraktan uzakta tuttu. "Ben dokunmadan bekleyebilirim," dedi. Deniz çömeldi. Bu küçük değişimi ayının gücü değil, ikisinin sabrı görünür kılacaktı.', 'Yapraktaki ince su yolu damlaya katıldı. Deniz uzayan ucu gördü. Böğürtlen gövdesini kıpırdatmadan durdu; yaprağa gölge düşürmüyordu. Çocuk ilk küçük biçimle şimdikini karşılaştırmak için sözünü yavaşça kurdu.', '"Su buradan geliyor, damla burada birikiyor," dedi Deniz. Böğürtlen başını hafifçe eğdi. Hiçbir şeyi taşımadı ya da sıkmadı. Çocuğun gösterdiği küçük değişim, yalnız bekleyince görülebilmişti.')},
'A1':{
'fox':('Tarçın çocuğun yanında, patikanın kenarında durdu. "Adımını sen seç," dedi. Önden koşmadı; Deniz’in çizeceği görünmez sınırı bekledi. Çocuk gölgeye gitmek için önce yakın bir yer seçebilecekti.', 'Deniz ilk adımını attı, sonra durdu. Tarçın onun hizasında kaldı. Çocuk yere baktı; dengedeydi. Bir sonraki yer biraz ilerideydi, ama yine kendi adımı kadar yakındı. Kimse onu acele ettirmedi.', 'Deniz bir adım daha seçti. Sonra bir tane daha. Tarçın yalnız yanında yürüdü. Çocuk taşınmadan, çekilmeden, kendi ayaklarının üstünde açıklığı geçti. Ne zaman duracağına da kendisi karar verdi.'),
'hedgehog':('Kestane açıklığın başında kısa bir an durdu. "Ben de küçük başlayacağım," dedi. Deniz arkadaşını cesaretlendirmek için çekmedi. İkisinin adımları aynı büyüklükte olmak zorunda değildi; yan yana yer vardı.', 'Deniz bir adım atıp durdu. Kestane kendi kısa adımını denedi ve rahatça zemine bastı. Çocuk arkadaşını beklerken geri kaçmadı. Birlikte ilerlemek, aynı anda aynı uzaklığa sıçramak değildi.', 'Deniz sıradaki küçük yeri seçti. Kestane kendi temposuyla ona eşlik etti. İkisi de yürüyerek geçti; Deniz arkadaşını kucağına almadı. Ağacın gölgesine varmaları, ayrı ayrı attıkları küçük adımların toplamıydı.'),
'cat':('Şehirden ziyarete gelen Simit açıklığa merakla baktı. Sonra Deniz’in seçeceği adımı bekledi. Kıvrık kuyruğu yanında duruyordu. "Ben burada seninle başlayayım," dedi. Merakı bir yarış başlatmasına gerek bırakmıyordu.', 'Deniz ilk adımında durdu. Simit de patilerini yere koyup bekledi. Çocuk açık toprağın ayağının altında sağlam kaldığını gördü. Kedinin hızlı gidebilmesi, kendisinin hızlı gitmesini gerektirmiyordu.', 'Deniz "Şimdi biraz daha," dedi. Simit bu kez kısa, sakin adımlarla eşlik etti. Çocuk kendi hızını koruyarak ağaca yürüdü. Açıklığı geçen kedinin peşine sürüklenmemiş, yolu kendisi adımlamıştı.')},
'A2':{
'fox':('Tarçın kütüğün yanında durdu. "İlk parça kayarsa pençemle tutabilirim," dedi. Çizginin hangi yönde birleşeceğini söylemedi. Deniz hem parçaları görebiliyor hem yerlerine kendi eliyle erişebiliyordu.', 'Deniz çizgili parçayı ilk yuvaya koydu. Tarçın bir ön pençesini parçanın düz kenarına bastırdı; yuva görünür kaldı. Çocuk öteki parçayı çevirdi. Kalın çizgi henüz birleşmemişti, bu yüzden denemeyi bitmiş saymadı.', 'Deniz ok uçlu parçayı yarım tur çevirdi ve ikinci yuvaya yerleştirdi. Çizgi birleşince "Şimdi bırakabilirsin," dedi. Tarçın pençesini kaldırdı. Parçalar yuvalarında kaldı; çözüm çocuğun seçtiği sıraydı.'),
'owl':('Yıldız kütüğün kalın kenarına kondu, kanatlarını kapattı. "Buradan çizginin ucunu görüyorum," dedi. Parçayı taşıma sözü vermedi. Deniz göremediği kenarı sorabilir, sıralamayı yine kendisi seçebilirdi.', 'Deniz çizgili parçayı ilk yuvaya koydu. Yıldız "Ucu ikinci yuvaya bakıyor," dedi. Kanatları kapalıydı; yalnız gözlem sunuyordu. Çocuk ok uçlu parçayı elinde çevirdi ve çizginin devamına baktı.', 'Deniz ikinci parçayı doğru yönde yuvaya yerleştirdi. "Birleşti mi?" diye sordu. Yıldız kısa bir "Birleşti" dedi. Parçaları koyan ve sırayı seçen çocuktu; baykuşun uçabilmesi bu düşünme işini çözmemişti.'),
'bear':('Böğürtlen kütüğün yanına oturdu. "İlk parçanın kenarını sabit tutabilirim," dedi. Büyük pençesi ikinci yuvaya taşmayacaktı. Deniz işaretin çizgilerine baktı. Güç, parçaların hangi sırada duracağını söylemiyordu.', 'Deniz çizgili parçayı ilk yuvaya koydu. Böğürtlen pençesini yalnız düz dış kenara bastırdı; parçayı ezmedi. Çocuk ikinci parçayı elinde çevirdi. Ayı kütüğü ya da çocuğu kaldırmıyordu.', 'Deniz ok uçlu parçayı ikinci yuvaya yerleştirdi. Çizgiler birleşince arkadaşına bırakmasını söyledi. Böğürtlen pençesini çekti. Parçalar yuvalarında durdu. Çocuğun kararıyla ayının sabit tutması, aynı işe iki ayrı katkı olmuştu.')},
'A3':{
'hedgehog':('Kestane çocuğun yanında durdu. "Ne gördüğünü düşünmen için beklerim," dedi. Her kökün yerini bildiğini söylemedi. Deniz yalnız bu yürüyüşteki kendi duruşunu hatırlıyordu; arkadaşı o anda mendile bakmamıştı.', 'Deniz geniş patikadan dönerken her kökte durmadı. Kestane onun hızına uydu. Çocuk birbiriyle çatallanan iki ucu görünce yavaşladı. "Ben burada durmuştum," dedi. Kestane cevabı önden söylemeden bekledi.', 'Deniz kökün açık yanına eğildi. Küçük mendil oradaydı; şimdi gerçekten görünüyordu. Eliyle alıp açtı. Kestane rahatça gülümsedi. Çocuğun hatırladığı ayrıntı, yalnız akıldaki kökten bulunan eşyaya dönüşmüştü.'),
'owl':('Yıldız alçak kökte durup Deniz’in anlattığını dinledi. "O anda mendile bakmadım," dedi. Uçup rastgele aramaya başlamadı. Çocuğun gördüğü çatallı kök, bu yeni kaybın yerini daraltan asıl bilgiydi.', 'Deniz geldiği patikaya dönünce Yıldız kısa bir uçuşla alçak dala geçti. Kanatlarını kapatıp bekledi. Çocuk yerdeki iki çatallı ucu tanıdı. Baykuş yukarıdan başka bir yer seçerek aramayı değiştirmedi.', '"İşte burası," dedi Deniz. Kökün yanındaki mendili gördü ve kendi eliyle aldı. Yıldız alçak daldan baktı. Uçabilen arkadaş bütün ormanı taramamıştı; çocuğun hatırlaması doğru yere dönmelerini sağlamıştı.'),
'cat':('Şehirden ziyarete gelen Simit burnunu yere uzatıp sonra kaldırdı. "Sen nerede durduğunu hatırlıyorsun," dedi. Mendilin kokusunu bildiğini söylemedi. Deniz kendi gördüğü kökü anlatırken kedi sakin biçimde dinledi.', 'Simit birkaç adım sonra dönüp Deniz’e doğru baktı; önden koşmayı bıraktı. Çocuk geniş patikanın yanındaki çatallı kökü tanıdı. "Burayı görüyorum," dedi. Kedi başka izlerin peşine sapmadı.', 'Deniz kökün açık yanındaki mendili gördü. Simit patisini uzatmadı; çocuk kendi eşyasını aldı. Kıvrık kuyruk kökten uzaktaydı. Yavaşlayıp geriye bakmak, aradıkları küçük yeri kaçırmamalarını sağlamıştı.'),
'bear':('Böğürtlen çocuğun yanında durdu. "Gösterdiğin yerden dönebiliriz," dedi. Mendilin nerede kaldığını bilmiyordu. Büyük pençeleri dinleniyordu; kökleri kaldırarak aramak yerine Deniz’in hatırladığı ayrıntıyı bekledi.', 'Deniz çatallı kökü görünce elini kaldırıp durdu. Böğürtlen geniş gövdesiyle yolu kapatmamak için bir adım geride kaldı. Çocuk kökün açık yanına kendi erişebildi. Arkadaşının gücüne ihtiyaç duymuyordu.', 'Deniz kökün yanında görünen mendili aldı. Böğürtlen bulunduğu yerden baktı; hiçbir kökü ya da taşı oynatmadı. Çocuk eşyasını elinde görünce gülümsedi. Geri dönülecek yeri kendi hatırladığı ayrıntıyla bulmuştu.')}
}

# Explicit scene inventories: objects mentioned as memories/plans are separate from
# visible objects. No keyword-to-pose mapping or runtime safety claims are made.
PROP_LABELS={
'room_sounds': 'perde, kapalı pencere, çocuğun yatağı, örtü ve karaktere uygun dinlenme yeri; ses ayrıca görünür nesne değildir',
'resting_material':'çocuğun yatağı, örtü; püskülsüz düz minder (kirpi), geniş minder (kedi), geniş yer döşeği ve ince bez (ayı)',
'remembered_day_detail':'yalnız hatırlanan gündüz ayrıntısı; odada yeniden görünmez',
'dry_leaf_and_trunk':'alçak dala takılı kuru yaprak ve değdiği ağaç gövdesi',
'leaf_under_branch':'düşmüş sabit dal ve altındaki tek yeşil yaprak; iki görünüş iki ayrı yaprak değildir',
'dew_drop_on_leaf':'yaprağın ucundaki yağmur suyu damlası, yapraktaki ince su yolu, yassı taş',
'sunlit_clearing':'düz kuru açıklık, geniş patika, büyük ağacın gölgesi; köprü/uçurum/su yok',
 'two_wooden_marker_parts':'yerdeki geniş kütük üstünde iki yuva, hafif çizgili parça, hafif ok uçlu parça',
 'child_cloth_at_root':'çocuğun küçük mendili ve çatallı kök; iz takip eden hayvan yok'}
ACTION_TABLE={
'U1': [('child','yatağa oturur'),('child','tanıdık perde sesini seçer'),('companion','türe uygun yerde uyanık dinler'),('child','kendi nefesini fark eder'),('child','gülümser; sesi çözülmesi gereken sorun saymaz'),('child','dinlemeyi bırakıp ışığı kısar'),('both','uyanık dinlenir'),('child','gözlerini kapatır; uykuya daldığı iddia edilmez')],
'U2': [('both','odada uygun geniş alanda durur'),('child','rahatlık tercihini sorar'),('companion','dinlenme yeri tercihini söyler'),('child','yaklaşma alanını açık bırakır'),('companion','yeri dener ve değişiklik ister'),('child','alanı bırakır; arkadaş kendi yerleşir'),('both','kendi yerlerinde uyanık dinlenir'),('child','gözlerini kapatır; arkadaş uyanık dinlenir')],
'U3': [('both','odada uyanık durur'),('child','gündüzden tek an seçer'),('both','geçmiş anı konuşur; sahne hâlâ odadır'),('child','anlatıyı sınırlar'),('both','geçmiş küçük anı paylaşır; odada oyun başlamaz'),('child','anlatıyı bırakır'),('both','uyanık dinlenir; geçmiş nesne odada yok'),('child','gözlerini kapatır; kapalı son')],
'L1': [('both','patikadan kuru yaprağın sesini duyar'),('child','dal hipotezini gözler'),('companion','yalnız bir gözlem sunar'),('child','teması bekleme planı seçer'),('child','temasla eşzamanlı sesi gözler'),('child','iki ipucundan çıkarım yapar'),('child','aynı eşleşmeyi tekrar gözler'),('both','nesneyi yerinde bırakarak ayrılır')],
'L2': [('both','dal altındaki kısmi yaprağı görür'),('child','ilk taraftan ince ucu gözler'),('companion','diğer yöndeki kıvrımı tarif eder'),('child','düz açık yerden dolaşır'),('child','iki görünüşü karşılaştırır'),('child','görünüşleri birleştirir; son bakışı seçer'),('child','aralıktan ortak sapı görür'),('both','dala dokunmadan patikaya döner')],
'L3': [('both','damlayı yerinde gözler'),('child','dokunmayı bırakır'),('companion','bekleme katkısını seçer'),('child','aynı bakış noktasını seçer'),('child','damlanın uzadığını gözler'),('child','önce ve şimdiyi karşılaştırır'),('both','damlanın kendiliğinden düştüğünü görür'),('both','tek gözlemden genel biyolojik zaman iddiası kurmadan ayrılır')],
'A1': [('both','düz açıklıktaki güvenli hedefi seçer'),('child','zemini gözler'),('companion','çocuğun hızına eşlik etmeyi seçer'),('child','bir adımlık sınırı seçer'),('child','ilk adımı atıp durur'),('child','kendi ayaklarıyla geçer'),('both','ağaç gölgesine varır'),('both','aynı düz yoldan döner')],
'A2': [('both','iki parçalı işarete yaklaşır'),('child','çizgi ve ok ucunu inceler'),('companion','kitaba özgü katkı sunar'),('child','sırayı kararlaştırır'),('child','çizgili parçayı ilk yuvaya yerleştirir'),('child','ok uçlu parçayı çevirip ikinci yuvaya yerleştirir'),('both','birleşmiş işareti görür'),('both','açıklığa yürüyüp patikaya döner')],
'A3': [('child','cebindeki mendilin eksikliğini fark eder'),('child','önceki kökü hatırlar; henüz burada görmez'),('companion','bilmediğini kabul edip eşlik eder'),('child','kendi önceki yolunu seçer'),('child','önceden gördüğü kökü tanır'),('child','görünen mendili kendi eliyle alır'),('child','mendili silkeleyip cebine koyar'),('both','aramanın bittiği yürüyüşü tamamlar')]}

def sha(text): return hashlib.sha256(text.encode('utf-8')).hexdigest()
def dump(path, value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n', encoding='utf-8')

EDITORIAL_REVISED_PAGES={('U3','fox',1),('U3','hedgehog',1),('U3','owl',1),('U3','cat',1),('U3','hedgehog',5),('U2','cat',6),('A2','owl',7),('A3','owl',3)}

CORRECTION_REVISED_PAGES={('U1','fox',1),('U1','owl',1),('U2','bear',7),('L2','bear',6)}
U2_PROPS={
 'hedgehog':'çocuğun yatağı ve örtüsü; püskülsüz düz minder ve katlı bez',
 'cat':'çocuğun yatağı ve örtüsü; geniş minder ve minderden alınan katlı bez',
 'bear':'çocuğun yatağı ve örtüsü; geniş yer döşeği ve ince bez'}

def export():
    sources=[]; books=[]; contracts=[]
    for shape, spec in SHAPES.items():
        bp='pilot56_blueprint_'+shape.lower()+'_v1'
        contracts.append({'blueprintID':bp,'planLabel':shape,'mode':spec['mode'],'mechanismKey':spec['mechanism'],
          'obstacle':spec['obstacle'],'solution':spec['solution'],
          'allowedCompanionIDs':[CHARACTERS[c][1] for c in spec['allowed']],
          'pageMoves':spec['moves'],'engineBeatMapping':None,
          'engineStateContractStatus':'not-implemented; do not coerce to existing beat raw values'})
        for key in spec['allowed']:
            name,cid,personality,anatomy=CHARACTERS[key]
            bid=f'pilot56_book_{shape.lower()}_{key}_v1'
            texts=[s.format(name=name) for s in spec['pages']]
            for index, text in zip([2,4,5],TAILORED[shape][key]): texts[index]=text
            if shape=='A2' and key=='owl':
                texts[6]='Çizgi ok ucuyla birleşince işaret tamamlandı. Ok, yanlarındaki düz açıklığı gösteriyordu. Deniz iki parçayı doğru sıraya koymuştu. Yıldız’ın yandan gördüğü aralığı söylemesi, çocuğun parça yönünü seçmesine yardım etmişti.'
            if shape=='U1' and key in ('fox','owl'):
                texts[0]=texts[0].replace(name+' de odadaydı',name+' da odadaydı')
            if shape=='U2' and key=='bear':
                texts[6]=texts[6].replace('Deniz kendi yatağına döndü.', 'Deniz kendi yatağında rahattı.')
            # Simit forest visit must be known before a local-context implication.
            if key=='cat' and not shape.startswith('U'):
                texts[0]+=' Simit şehirden bugün ziyarete gelmişti.'
            setting=ROOM if shape.startswith('U') else FOREST
            context={'ageBand':'5-6','mode':spec['mode'],'arc':'charge-bedtime-editorial' if shape.startswith('U') else 'editorial-'+spec['mode'],
              'companionID':cid,'settingID':setting,'worldID':'pilot56_world_whispering_forest_v1',
              'discoveryID':'pilot56_discovery_'+spec['prop']+'_v1','family':[],'guest':None,'occasion':None,'series':None,'recall':None,
              'syntheticChildID':'pilot56_synthetic_child_deniz','syntheticChildName':'Deniz'}
            pages=[]
            for n,text in enumerate(texts,1):
                revision=2 if (shape,key,n) in EDITORIAL_REVISED_PAGES | CORRECTION_REVISED_PAGES else 1
                sid=f'pilot56_source_{shape.lower()}_{key}_p{n:02}_v{revision}'
                # Segments are orthographic sentence units, not reusable grammar slots.
                segments=re.split(r'(?<=[.!?])\s+(?=[^\s])',text)
                sentence_ids=[]
                for j,sentence in enumerate(segments,1):
                    sentid=sid+f'_s{j:02}'
                    sentence_ids.append(sentid)
                    sources.append({'id':sentid,'kind':'authoredSentenceSegment','parentSourceID':sid,'text':sentence,'sha256UTF8':sha(sentence)})
                sources.append({'id':sid,'kind':'authoredFullPage','text':text,'sha256UTF8':sha(text),'sentenceSourceIDs':sentence_ids,
                  'blueprintID':bp,'bookID':bid,'pageNumber':n,'context':context})
                present=[{'subjectID':'pilot56_synthetic_child_deniz','presence':'present','states':['awake'] if n<8 or not shape.startswith('U') else ['eyes-closed','sleep-not-asserted']},
                  {'subjectID':cid,'presence':'present','states':['awake','species-anatomy-preserved']}]
                if shape.startswith('U') and n>=6: present[1]['states'].append('resting-awake')
                memories=[]; intentions=[]
                propid='pilot56_discovery_'+spec['prop']+'_v1'
                if shape=='U3':
                    if 2<=n<=7:
                        memories=[{'subjectID':propid,'presence':'remembered','states':['not-in-current-room']},
                          {'subjectID':'pilot56_synthetic_child_deniz','presence':'remembered','states':['daytime-account-not-current-action']}]
                        if n in (3,5): memories.append({'subjectID':cid,'presence':'remembered','states':['daytime-account-distinct-from-present-companion']})
                    present.extend([{'subjectID':'pilot56_object_room_furnishings_v1','presence':'present','states':['bed','cover','species-appropriate-resting-place']}])
                elif shape=='A3':
                    if n<=5: intentions=[{'subjectID':propid,'presence':'intended','states':['cloth-location-not-yet-known','not-available-as-visible-prop']}]
                    else: present.append({'subjectID':propid,'presence':'present','states':['cloth-in-child-hand','recovered-from-visible-root'] if n==6 else ['cloth-in-child-pocket']})
                    if n==2: memories=[{'subjectID':'pilot56_object_forked_root_v1','presence':'remembered','states':['not-yet-currently-visible']}, {'subjectID':'pilot56_synthetic_child_deniz','presence':'remembered','states':['earlier-shoe-wiping-action']}]
                    if 5<=n<=7: present.append({'subjectID':'pilot56_object_forked_root_v1','presence':'present','states':['fixed-on-ground']})
                    if n==8: present.append({'subjectID':'pilot56_object_forked_root_v1','presence':'off-scene','states':['left-at-search-location','not-current-clearing-prop']})
                    if key=='owl' and n==3:
                        present.append({'subjectID':'pilot56_object_current_rest_root_v1','presence':'present','states':['owl-current-perch','distinct-from-sought-forked-root']})
                        memories.append({'subjectID':'pilot56_object_forked_root_v1','presence':'remembered','states':['not-yet-currently-visible','distinct-from-current-perch']})
                    if key=='cat' and n==3: intentions.append({'subjectID':propid,'presence':'intended','states':['smell-knowledge-explicitly-not-asserted']})
                else:
                    state=['scene-prop']
                    if shape=='L3': state=['drop-on-leaf'] if n<7 else ['drop-fallen-to-ground','wet-leaf-tip-remains']
                    if shape=='A2': state=['two-separate-parts'] if n<5 else (['first-piece-in-slot','second-piece-in-child-hand'] if n==5 else ['two-parts-joined-in-slots'])
                    present.append({'subjectID':propid,'presence':'present','states':state})
                actor,action=ACTION_TABLE[shape][n-1]
                concrete=text if n in (3,5,6) else action
                actor_ids=['pilot56_synthetic_child_deniz',cid] if actor=='both' or n in (3,5,6) else ['pilot56_synthetic_child_deniz' if actor=='child' else cid]
                if (shape,key,n) in {('U1','fox',3),('U1','bear',3),('L3','hedgehog',3),('A3','bear',3)}: actor_ids=[cid]
                roles={'child':'pilot56_synthetic_child_deniz','companion':cid,'both':'pilot56_synthetic_child_deniz + '+cid}
                no_draw=['No unmentioned prop or extra character.','An intention or memory must not become a current physical action.']
                if key=='owl': no_draw.append('No four-legged curl, hands, or unsupported flight; flight only explicit A3 p5. A2 p3 landing is explicit.')
                if key=='bear': no_draw.append('Preserve large bear scale. No tiny window/bed; no carrying child. A2 p5-6 only edge stabilization, not lifting.')
                if key=='cat': no_draw.append('Same city cat on a new visit; curled tail visible when composition permits; no invented forest residency.')
                if shape=='U3': no_draw.append('No daytime memory object rendered as a present room prop.')
                pages.append({'pageNumber':n,'role':spec['moves'][n-1],'orderedBeatIDs':['pilot56_beat_'+shape.lower()+'_'+str(n)+'_v1'],
                  'text':text,'context':context,'previousPageNumber':n-1 if n>1 else None,'nextPageNumber':n+1 if n<8 else None,
                  'stateBefore':spec['moves'][n-2] if n>1 else 'not-started','stateAfter':spec['moves'][n-1],
                  'provenance':{'complete':True,'partCount':1,'parts':[{'order':0,'sourceKind':'pilotAuthoredFullPage','sourceID':sid,
                    'sourceTextDigest':sha(text),'templateID':bp,'sourcePointer':'sources.json#/sources/'+str(len(sources)-1), 'contexts':context}]},
                  'sentenceSourceIDs':sentence_ids,'semantics':{'annotationStatus':'author-reviewed-not-independently-approved','inventoryScope':'All named/pronominal story actors; prop groups enumerated, not a render whitelist.',
                    'metadataRevision':2,'subjects':present+memories+intentions,'propDescription':U2_PROPS[key] if shape=='U2' else PROP_LABELS[spec['prop']],
                    'actions':[{'actorSubjectIDs':actor_ids,'description':concrete,'evidenceSourceID':sid,'evidenceText':text,'scope':'page-context; multiple actors on tailored pages; not atomic executable action','atomicActionMappingApproved':False}],
                    'temporalNote':'Past recollection stays remembered; potential actions and explicit negations are not present actions.'},
                  'artHandoff':{'contentMeaningStatus':'author-reviewed','visualIdentityStatus':'not-reviewed-for-this-page','assetRuleApproval':False,
                    'runtimeArt':None,'actionNeed':concrete,'anatomyAndScale':anatomy,'doNotDraw':no_draw},
                  'editorialIntensity':([0,1,1,1,1,0,0,0][n-1] if shape.startswith('U') else [0,1,1,1,1,1,0,0][n-1])})
            book={'id':bid,'title':spec['title'],'blueprintID':bp,'planLabel':shape,'mechanismKey':spec['mechanism'],
              'status':DRAFT,'context':context,'fixedCompanionRole':{'U1':'R','U2':'N','U3':'R','L1':'G','L2':'R','L3':'R','A1':'H' if key=='hedgehog' else 'R','A2':'R','A3':'R'}[shape],
              'personalityContract':personality,'physicalContract':anatomy,'childAgency':spec['solution'],
              'pages':pages,'runtimeCompatible':False,'independentEditorialApproval':False}
            path=ROOT/'books'/f'{bid}.json'; dump(path,book)
            books.append({'bookID':bid,'file':'books/'+path.name,'sha256FileBytes':hashlib.sha256(path.read_bytes()).hexdigest(),
              'planLabel':shape,'companionID':cid,'pageCount':8,'wordCountWhitespace':sum(len(t.split()) for t in texts)})
    dump(ROOT/'sources.json',{'schema':'magicpaper.pilot-authoring-sources.v1','digestConvention':'SHA-256, exact UTF-8 text, no normalization, lowercase hex','sources':sources})
    dump(ROOT/'structures.json',{'schema':'magicpaper.pilot-editorial-structures.v1','structures':contracts})
    dump(ROOT/'manifest.json',{'schema':'magicpaper.internal-authored-pilot.v1','packageID':'five-friends-56-v1','status':DRAFT,
      'productionEnabled':False,'runtimePackage':False,'ageBands':['5-6'],'worldID':'pilot56_world_whispering_forest_v1',
      'settings':[{'id':FOREST,'mode':['learning','adventure'],'relationship':'existing exact setting identity; no mutation'},
        {'id':ROOM,'displayName':'Orman Kıyısındaki Oda','mode':['bedtime'],'isRestingPlace':True,'relationship':'new pilot-only room; not legacy room rename'}],
      'companions':[{'id':v[1],'name':v[0],'personality':v[2],'anatomy':v[3],'legacyRecordMutated':False} for v in CHARACTERS.values()],
      'supportedContext':{'guest':False,'family':False,'occasion':False,'series':False,'recall':False,'topic':'nil-only','personalization':'fixed synthetic Deniz fixture only'},
      'unsupportedResult':'unsupported-in-pilot; never silently remove request context',
      'books':books,'structuresFile':'structures.json','sourcesFile':'sources.json',
      'sourcePayloadSHA256FileBytes':hashlib.sha256((ROOT/'sources.json').read_bytes()).hexdigest(),
      'acceptance':{'authoredPairs':30,'authoredPages':240,'randomFirstAttemptSeedsRun':0,'runtimeBooksComposed':0,'artPagesApproved':0,
        'engineStateMappingApproved':False,'independentEditorialReviewComplete':False,'releaseApproved':False}})

if __name__=='__main__': export()
