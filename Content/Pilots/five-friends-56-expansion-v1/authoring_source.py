"""Explicit authored event02/event03 corpus. Serialization only; no runtime activation."""
from pathlib import Path
import copy,hashlib,json,re
ROOT=Path(__file__).resolve().parent
LEGACY=ROOT.parent/'five-friends-56-v1'
def sha(v): return hashlib.sha256(v.encode() if isinstance(v,str) else v).hexdigest()
def dump(p,v): p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Eight complete, ordered pages per authored event. {name} is a controlled catalog name.
EVENTS={
('U1',2):('Ellerin Sessiz Molası',[
'Deniz yatağında oturdu, ellerini örtüsünün üstüne koydu. {name} odada kendi yerindeydi. Kapalı pencerenin önündeki ışık yumuşaktı. Akşam için bütün hazırlıkları bitmişti.',
'Deniz avuçlarını usulca birbirine sürtmeyi seçti. İncecik bir ses duydu, sonra ellerini yavaşlattı. Ses de hareketiyle birlikte hafifledi. Bu tanıdık sesi dinlemek istiyordu.',
'',
'Deniz duyduğu sese bir ad verdi. "Bu, ellerimin yumuşak sesi," dedi. Avuçlarını aynı yavaşlıkta hareket ettirdi. Sesi sürdürmek de bitirmek de kendi elindeydi.',
'Deniz avuçlarının birbirinden ayrıldığı küçük aralığa gülümsedi. Ellerini yeniden birleştirince tanıdık hışırtı duyuldu. Bu kez sesin nereden geldiğini biliyordu. Yeni bir ses aramadı.',
'Deniz ellerini ayırıp örtüsünün üstünde dinlendirdi. "Dinlemeyi bitirdim," dedi, avuçlarını yeniden sürtmedi. Ellerinin sesi kesilmişti. Sessizliğin içinde beklemesi gereken başka bir iş kalmamıştı.',
'{name} kendi yerinde uyanık ve rahattı. Deniz ellerini örtüsünün üzerinde bıraktı. İkisi de konuşmadan dinleniyordu. Odanın yumuşak ışığı yerde aynı küçük alanı aydınlatıyordu.',
'Deniz gözlerini kapattı, elleri örtüsünün üzerinde kaldı. Arkadaşı kendi yerinde dinleniyordu. Tanıdık ses bitmiş, akşam tamamlanmıştı. Yeniden başlatmaları gereken hiçbir şey kalmamıştı.']),
('U1',3):('Örtünün Son Hışırtısı',[
'Deniz yatağına oturup örtüsünü dizlerine aldı. {name} odada kendi yerindeydi. Pencere kapalıydı, içeriye yumuşak bir akşam ışığı düşüyordu. Odanın bütün eşyaları yerli yerindeydi.',
'Deniz örtünün kenarını yalnız bir kez düzeltmeyi seçti. Kumaş usulca hışırdadı, sonra yatağın üzerinde durdu. Çocuk tanıdığı bu küçük sesi dinledi. Yeniden düzeltmesi gerekmiyordu.',
'',
'Deniz örtünün sesini fısıltıyla adlandırdı. "Bu da örtümün hışırtısı," dedi. Kumaşın kenarı şimdi ellerinin altında düzdü. Aynı sesi duymak için onu yeniden oynatabilirdi.',
'Deniz düzgün duran örtüye bakıp hafifçe gülümsedi. Ses çoktan bitmişti, fakat tanıdık hışırtıyı hatırlıyordu. Örtünün yeniden ses çıkarması gerekmiyordu. Ellerini kumaşın üzerinde sakin tuttu.',
'Deniz ellerini örtünün kenarından çekti. "Bir daha düzeltmeyeceğim," dedi, sesi yeniden başlatmadı. Kumaş olduğu yerde kaldı. Çocuk artık başka bir hışırtı gelmesini beklemiyordu.',
'{name} kendi yerinde uyanık ve rahattı. Deniz de örtüsünün altında dinleniyordu. İkisi kumaşı yeniden oynatmadı. Akşamın sessizliği içinde tanıdık odalarında rahatça kaldılar.',
'Deniz gözlerini kapattı, örtüsü düz duruyordu. Arkadaşı dinlenmeyi sürdürdü. Bir kez duydukları küçük ses yeterliydi. Akşamın sonunda tekrarlanmaları gereken sesler ya da sözler kalmamıştı.']),
('U2',2):('Örtünün Düz Yeri',[
'Deniz yatağının yanında boş bir zemin hazırladı. {name} geniş açıklıkta duruyordu. Yerde düz bir örtü ve katlanmış kenarı vardı. Akşam ışığı kapalı pencereye vuruyordu.',
'Deniz örtünün katlı kenarına baktı. Katlanan bölüm, geri kalan yüzeyden yüksek duruyordu. "Nasıl bir yer istersin?" diye sordu. Arkadaşının cevabını bekleyip örtüye dokunmadı.',
'',
'Deniz örtünün katlı kenarını yavaşça açtı. Yerdeki yüzey aynı yüksekliğe geldi, geçişi açık kaldı. Çocuk kendi dizlerini geriye çekti. Arkadaşının denemesi için boşluk bıraktı.',
'',
'Deniz örtünün kenarından kalkıp kendi yatağına döndü. Arkadaşının seçtiği yere bir daha dokunmadı. "Burayı sen seçtin," dedi. Hazırlık bitmişti, artık yanına daha fazla eşya taşımayacaktı.',
'Deniz kendi yatağında uyanık dinleniyordu. Arkadaşı düz örtünün üzerinde rahatça kalmıştı. Açık zemin ikisinin arasında uzanıyordu. Çocuk yaptığı hazırlığı tekrar düzeltmeden olduğu gibi bıraktı.',
'Deniz örtüsünü çekip gözlerini kapattı. Arkadaşı seçtiği geniş yerde dinlenmeyi sürdürdü. Katlanan kenar açılmış, küçük hazırlık bitmişti. Odanın akşamı sakin biçimde tamamlanmıştı.']),
('U2',3):('Yanındaki Boşluk',[
'Deniz yatağının yanına geniş bir minder koymuştu. {name} açık zeminde duruyordu. Minderin yanında düz bir dinlenme örtüsü vardı. Odadaki akşam hazırlıkları neredeyse bitmişti.',
'Deniz minderle örtü arasındaki dar aralığı fark etti. "Yanında ne kadar boşluk istersin?" diye sordu. Minderi henüz oynatmadı. Arkadaşının kendi yerini seçmesini bekliyordu.',
'',
'Deniz minderi örtünün yanından uzaklaştırıp boş duvarın önüne aldı. Dinlenme yerine giden yol genişledi. Çocuk kendi yatağına doğru çekildi. Arkadaşına yaklaşmak için açık alan kalmıştı.',
'',
'Deniz açık aralığa bir daha eşya koymadı. "Bu boşluk senin yanında kalacak," dedi. Arkadaşını eliyle başka yere yerleştirmedi. Kendi seçtiği yerde rahatça durmasına izin verdi.',
'Deniz yatağında uyanık dinleniyordu, arkadaşı da kendi yerindeydi. Aralarındaki açık zemin artık boştu. Minder duvarın yanında kaldı. Küçük yer değişikliği ikisine de yeterli gelmişti.',
'Deniz gözlerini kapattı, örtüsünü rahatça çekti. Arkadaşı geniş alanda dinlenmeyi sürdürdü. Minder taşınmış, yer seçilmişti. Odanın içinde tamamlanması gereken başka bir hazırlık kalmamıştı.']),
('U3',2):('Durduğum Küçük An',[
'Deniz yatağında oturmuş, akşamı dinliyordu. {name} odada kendi yerindeydi. Gündüzün yürüyüşü bitmişti. Şimdi ikisi de dışarı çıkmak yerine tanıdık odalarında uyanık dinleniyordu.',
'Deniz gündüz yürürken durduğu tek bir anı seçti. O sırada gölgesi de ayaklarının yanında durmuştu. "Bugünden bunu anlatacağım," dedi. Bu görüntü yalnız aklındaydı.',
'Deniz hatırladığı küçük duruşu arkadaşına anlattı. "Ben durdum, gölgem de durdu," dedi. {name} sessizce dinledi. Odada bir yürüyüş başlamamıştı, yalnız gündüzden bir anı paylaşıyorlardı.',
'Deniz yürüyüşün geri kalanını anlatmak üzereyken durdu. "Bu akşam yalnız durduğum an," dedi. Öncesindeki ve sonrasındaki adımları eklemedi. Seçtiği ayrıntı kendi başına yeterliydi.',
'Deniz hatırladığı duruşu düşünerek hafifçe gülümsedi. Arkadaşı anlattığı küçük anı dinlemişti. İkisi de odada yerinden kalkmadı. Gündüzün görüntüsü şimdi yalnız paylaşılan bir anıydı.',
'Deniz anlatmayı bırakıp ellerini örtüsüne koydu. "Anlatacağım bu kadardı," dedi. Gündüzün adımlarını yeniden sıralamadı. Hatırladığı duruş, odada sürdürmesi gereken bir oyun haline gelmemişti.',
'Deniz yatağında uyanık ve rahattı, arkadaşı kendi yerindeydi. Gölgeyi artık konuşmuyorlardı. Hatırlanan görüntü odanın içinde belirmedi. Tanıdık akşam eşyaları arasında sessizce dinlendiler.',
'Deniz gözlerini kapattı, örtüsü dizlerinin üzerindeydi. Arkadaşı sakin yerinde kaldı. Günden seçilen küçük an anlatılmış ve bitmişti. Bu akşamın sonuna başka bir söz eklemediler.']),
('U3',3):('Avucumdan Ayrılan Yaprak',[
'Deniz akşam odasında yatağına yerleşmişti. {name} yakınındaki uygun yerde duruyordu. Gündüzün oyunları bitmişti. Pencere kapalı, ışık yumuşaktı; şimdi birlikte uyanık dinlenmek için buradaydılar.',
'Deniz gündüz avucunu açtığı tek bir anı seçti. Elindeki kuru yaprak o anda yere bırakılmıştı. "Bugünden bunu anlatacağım," dedi. Yaprak şimdi odada değildi.',
'Deniz arkadaşına gündüz açtığı avucunu anlattı. "Yaprağı elimden yere bıraktım," dedi. {name} dikkatle dinledi. Çocuğun elleri şimdi örtüsündeydi; anlattığı hareket yalnız gündüze aitti.',
'Deniz yaprağın sonraki halini anlatmaya başlamadan durdu. "Yalnız avucumdan ayrıldığı anı anlatıyorum," dedi. Yaprağın bütün yolunu eklemedi. Seçtiği küçük ayrıntıyı olduğu yerde bıraktı.',
'Deniz gündüz açılan avucunu hatırlayıp gülümsedi. Arkadaşı bu küçük anı dinlemişti. İkisi de odada hiçbir yaprak taşımıyordu. Paylaştıkları görüntü yalnız geçmişteki o kısa harekete aitti.',
'Deniz anlatmayı bitirip örtüsünü rahatça çekti. "Bu akşam anlatımım bitti," dedi. Yaprağın devamını düşünerek yeni bir söz aramadı. Seçtiği anı paylaşmış olması ona yetmişti.',
'Deniz kendi yatağında uyanık dinleniyordu. Arkadaşı uygun yerinde sessizce kaldı. Hatırlanan yaprak odada görünmüyordu. Çocuğun ellerinde yalnız tanıdık örtünün kenarı vardı; küçük anlatı artık bitmişti.',
'Deniz gözlerini kapattı, arkadaşının sakin varlığını yanında biliyordu. Gündüzden kalan ayrıntı anlatılmıştı. Odanın ışığı yumuşak kaldı. Bu akşam sessizce tamamlandı, söylenecek başka bir şey kalmadı.']),
('L1',2):('Her Sallanışta Değil',[
'Deniz patikanın yanında kuru bir yaprağın sesini duydu. {name} yanında duruyordu. Yaprak alçak dalın önünde sallanıyordu. İnce tıkırtı bazen duyuluyor, bazen hiç duyulmuyordu.',
'Deniz yaprağın her sallanışının ses çıkardığını düşündü. Sonra bir salınımı sessizce izledi. "Demek her hareket aynı değil," dedi. İlk tahminini henüz bir cevap saymadı.',
'',
'Deniz yaprakla dalın arasındaki küçük boşluğu izlemeyi seçti. "Değdiği anı dinleyeceğim," dedi. Elleri yanında durdu. Hem hareketi hem sesi bulunduğu yerden birlikte gözleyebilirdi.',
'Deniz yaprağın dala değdiğini gördü, aynı anda tıkırtıyı duydu. Yaprak geri açıldığında ses kesildi. Çocuk yerinden kıpırdamadı. Bir sonraki salınımı da aynı boşluktan izledi.',
'Deniz iki salınımı düşünerek kendi sonucunu söyledi. "Sesi yalnız değdiğinde duydum," dedi. Hareket eden yaprağı görmek tek başına yetmemişti. Temasla sesin aynı anını fark etmişti.',
'Deniz yeniden açılan boşluğu ve sonra gelen teması izledi. Temas sırasında aynı ince tıkırtı duyuldu. "Yine birlikte oldu," dedi. İkinci gözlemi ilk sonucuyla uyuşuyordu.',
'Deniz patikaya dönerken yaprağı dalında bıraktı. Arkadaşı yanında sakin biçimde ilerledi. Çocuk her sallanışın aynı olmadığını görmüştü. Sonucunu çıkarmadan önce iki ayrı anı karşılaştırmıştı.']),
('L1',3):('Ses Çıkaran Hangisi',[
'Deniz alçak dalın yanında iki kuru yaprak gördü. {name} yanında duruyordu. Yapraklar aynı esintide sallanıyordu. İnce tıkırtının hangisinden geldiği, ilk bakışta belli olmuyordu.',
'Deniz daha büyük yaprağın ses çıkardığını tahmin etti. İkisi de hareket edince kararını durdurdu. "Önce ikisini ayırarak bakacağım," dedi. Büyüklük tek başına bir kanıt değildi.',
'',
'Deniz önce uzaktaki, sonra dala yakın yaprağı izlemeyi seçti. "Hangisi değiyor, göreceğim," dedi. Dala uzanmadı. İki yaprağı bulunduğu geniş patikadan sırayla açıkça görebiliyordu.',
'Deniz uzaktaki yaprak sallanırken boşluğun açık kaldığını gördü. Sonra yakındaki yaprak dala değdi. O anda tıkırtı duyuldu. Çocuk gördüğü teması duyduğu sesle birlikte düşündü.',
'Deniz kendi gözlemlerini birleştirip cevabını söyledi. "Ses, dala değen yapraktan geldi," dedi. İki yaprak da sallanmıştı. Ancak yalnız birinin teması, tıkırtıyla aynı anda olmuştu.',
'Deniz bir esinti daha bekleyip yakındaki yaprağı izledi. Yaprak yeniden dala değince tıkırtı duyuldu. "Yine aynı yaprak," dedi. Uzakta sallanan yaprakla arasındaki farkı görebiliyordu.',
'Deniz iki kuru yaprağı yerlerinde bırakıp patikaya döndü. Arkadaşı yanında ilerledi. Çocuk en büyük olanı seçmemişti. İki adayı ayrı ayrı gözlemek, kendi cevabını bulmasını sağlamıştı.']),
('L2',2):('Örtünün İki Yanı',[
'Deniz yerde üst üste duran yaprakları gördü. {name} açık patikada yanındaydı. İki kuru yaprak, yeşil yaprağın ortasını örtüyordu. İki yanda ayrı yeşil uçlar görünüyordu.',
'Deniz yakınındaki sivri yeşil uca baktı. "Burada bir uç görüyorum," dedi. Yaprağın ortası henüz görünmüyordu. Üstündeki kuru yaprakları çekmek yerine açık geçişi gözden geçirdi.',
'',
'Deniz yaprakların çevresindeki açık zeminden diğer yana geçti. Şimdi arkadaşının gösterdiği sapı da görebiliyordu. "İki yana bakacağım," dedi. Örtücü kuru yaprakları yerlerinden oynatmadı.',
'Deniz sivri uçtaki damarla sapın yanındaki damarı karşılaştırdı. Aralıktan aynı çizginin devamı görünüyordu. Çocuk iki tarafa sırayla baktı. Görüşleri birbirinden ayrı düşünmek zorunda değildi.',
'Deniz iki görünüşü kendi sözüyle birleştirdi. "Bu uçla sap aynı yaprağa bağlı," dedi. Üstteki kuru yapraklar duruyordu. Çocuk bütün biçimi anlamak için onları kaldırmamıştı.',
'Deniz biraz yana geçip aralıktaki damar bağlantısını yeniden gördü. Sivri uç ve sap aynı yeşil yaprağa uzanıyordu. "Tek yaprak," dedi. İki görünüş artık aynı bütünü gösteriyordu.',
'Deniz açık patikaya döndü, yapraklar yerde kaldı. Arkadaşı da geçişi açık bıraktı. Çocuk ilk gördüğü uçla öteki sapı birlikte düşünmüştü. Örtüyü kaldırmadan biçimi anlamıştı.']),
('L2',3):('Kıvrımın Öteki Kenarı',[
'Deniz yerde kıvrılmış büyük bir yaprak gördü. {name} açık patikada yanında duruyordu. Yakın kenar öteki kenarı gizliyordu. Yaprağın bir yanında ince sapı açıkça görünüyordu.',
'Deniz yüksek duran yakın kenara baktı. "Öteki tarafı buradan göremiyorum," dedi. Yaprağı açmak için elini uzatmadı. Çevresindeki açık yerden başka bir bakış seçebilirdi.',
'',
'Deniz yaprağın çevresinde açık zeminden yürüyüp diğer yana geçti. Şimdi gizlenen kenarı görebiliyordu. "Buradan da bakacağım," dedi. Kıvrılan yaprağı eliyle açmadan yerinde bıraktı.',
'Deniz yeni gördüğü kenarın sapa doğru kıvrıldığını izledi. Önceki yüksek kenarı da hatırladı. İki yandan aynı sap görünüyordu. Çocuk bakışlarını bu ortak noktada birleştirdi.',
'Deniz iki kenarın aynı kıvrıma bağlandığını söyledi. "İkisi tek yaprağın kenarları," dedi. Yaprak kendi biçiminde kaldı. Çocuk onu düzleştirmek yerine bakış yerini değiştirmişti.',
'Deniz biraz yana eğilip iki kenarın sapta birleştiğini yeniden gördü. Kıvrım hâlâ yerindeydi, fakat bütün biçim anlaşılmıştı. "Şimdi tamamını düşünüyorum," dedi. Yaprağı açmasına gerek kalmamıştı.',
'Deniz patikaya döndü, kıvrılmış yaprak yerde kaldı. Arkadaşı sakin biçimde yanında ilerledi. İlk bakış yanlış değildi, yalnız eksikti. Çocuk diğer yandan bakarak gördüğünü tamamlamıştı.']),
('L3',2):('İki Damladan Birine',[
'Deniz alçak yaprağın ucuna yakın iki damla gördü. {name} düz patikada yanındaydı. Damlanın biri küçük, öteki biraz büyüktü. Aralarında ince bir su çizgisi uzanıyordu.',
'Deniz iki ayrı damlanın birbirine yaklaştığını fark etti. "Biraz daha bekleyebilirim," dedi. Yaprağa dokunmak yerine ellerini kendine çekti. Şimdi ne olacağını kendisi gözlemek istiyordu.',
'',
'Deniz aynı bakış yerinde kalmaya karar verdi. "Önce iki taneydiler," dedi, küçük damlanın yerini aklında tuttu. Yaprağı sallamadı. İki damlanın arasındaki çizgiyi izlemeyi sürdürdü.',
'Deniz iki damlanın birleşerek tek damla olduğunu gördü. Ortadaki ince aralık artık görünmüyordu. Yeni damla yaprak ucunda daha geniş duruyordu. Çocuk dokunmadan bu değişimi izlemişti.',
'Deniz önceki iki damlayla şimdiki tek damlayı karşılaştırdı. "Birleşince daha büyük göründü," dedi. Aynı yaprağa bakıyordu. Gördüğü değişikliği kendi önceki gözlemine dayanarak söylemişti.',
'Deniz birleşen damlanın uçtan ayrılıp toprağa düştüğünü gördü. Yaprak ucunda yalnız küçük bir ıslaklık kaldı. Çocuk ellerini yanında tuttu. Yaprağı hiç kimse sallamamıştı.',
'Deniz doğrulup açık patikaya döndü. Arkadaşı yanında ilerledi. Yalnız bu iki damlanın birleşmesini izlemişlerdi. Bütün damlaların aynı biçimde ya da aynı sürede değiştiğini söylemediler.']),
('L3',3):('Damar Boyunca Bir Damla',[
'Deniz alçak yaprağın ortasında duran bir damla gördü. {name} düz patikada yanındaydı. İnce yaprak damarı suyun altında görünüyordu. Damla henüz yaprağın ucuna ulaşmamıştı.',
'Deniz damlanın yerini yaprak damarıyla birlikte düşündü. "Şimdi ortasında duruyor," dedi. Parmağını uzatmak yerine geri çekti. Damlayı iterse kendi hareketini mi gördüğünü ayıramayacaktı.',
'',
'Deniz aynı damarı işaret olarak seçti. "Yerini buraya bakarak karşılaştıracağım," dedi. Yaprağa elini sürmedi. İlk damarın yanındaki damlayı aklında tutup aynı noktadan izlemeyi sürdürdü.',
'Deniz damlanın damar boyunca uca doğru ilerlediğini gördü. İlk baktığı damar artık suyun gerisindeydi. Damla hâlâ aynı yaprağın üzerindeydi. Çocuk ellerini yanında sakin tuttu.',
'Deniz damlanın önceki ve şimdiki yerini karşılaştırdı. "Önce ortadaydı, şimdi uçta," dedi. Yaprak damarı yerinde kalmıştı. Değişen yerin, gözlediği damlaya ait olduğunu anlayabiliyordu.',
'Deniz uçta toplanan damlanın yapraktan ayrıldığını gördü. Su toprağa düştü, yaprak damarı açık kaldı. Çocuk yaprağı itmemişti. Beklediği süre boyunca aynı damlanın yerini izlemişti.',
'Deniz patikaya döndü, arkadaşı yanında sakin biçimde ilerledi. Tek damlanın geçtiği yeri karşılaştırmışlardı. Bütün damlaların aynı yolu izleyeceğini söylemediler. Bu küçük gözlem tamamlanmıştı.']),
('A1',2):('Aydınlıkta Seçtiğim Mola',[
'Deniz gölgeli patikadan düz açıklığa baktı. {name} yanındaydı. Güneş alan açıklığın ötesinde geniş bir ağaç gölgesi vardı. İkisi oraya yürüyüp aynı yoldan dönmek istiyordu.',
'Deniz gölgenin bittiği yerde durdu. Önündeki kuru zemin daha aydınlık görünüyordu. "İlk adımda biraz durabilirim," dedi. Ağacın yanına bir kerede gitmesi gerekmiyordu; kendi hızını seçebilirdi.',
'',
'Deniz güneşli zeminin başında bir mola yeri seçti. "Önce şu küçük yere," dedi. Ayağını nereye koyacağını kendisi belirledi. Arkadaşı onu önden çağırmak yerine yanında bekliyordu.',
'Deniz aydınlık zemine ilk adımını atıp durdu. Toprak ayağının altında düzdü. Işığa alışırken çevresine baktı. Seçtiği mola gerçekten kendi kararıydı, daha ileri gitmek için acele etmedi.',
'Deniz mola yerinden sonraki küçük adımlarını kendisi seçti. "Şimdi devam ediyorum," dedi. Arkadaşı aynı sakin tempoda eşlik etti. Çocuk aydınlık açıklığı kendi ayaklarıyla geçip ağaca yaklaştı.',
'Deniz geniş ağacın gölgesine varıp geriye baktı. İlk mola yeri açıklığın başında kalmıştı. Işığın değiştiği yerde durabilmiş, sonra yürümüştü. Arkadaşı şimdi yanında sessizce bekliyordu.',
'Deniz aynı düz yoldan gölgeli patikaya döndü. Arkadaşı yanında ilerledi. Çocuk yolun başında mola seçmiş, sonra devam etmişti. Açıklığa yürüyüşleri bitmişti; bir yere yetişmeleri gerekmiyordu.']),
('A1',3):('Toprağın Renk Sınırı',[
'Deniz düz açıklıkta iki renk toprak gördü. {name} yanındaydı. Açık ve koyu zemin aynı yükseklikte uzanıyordu. İlerideki geniş ağaca yürüyüp patikaya geri dönmek istiyorlardı.',
'Deniz renklerin birleştiği yere yaklaşmadan iki yana baktı. "Burada yol değişmiş gibi görünüyor," dedi. Zemin yine kuru ve düzdü. Çocuk bu yeni görünüşe kendi hızında yaklaşabilirdi.',
'',
'Deniz ilk adımını renklerin birleştiği yerde bitirmeyi seçti. "Önce sınıra kadar," dedi. İki zemini de gözleriyle izledi. Arkadaşı önden çekmeden çocuğun seçtiği küçük adımı bekledi.',
'Deniz ilk adımını toprakların birleştiği yere attı. Ayağının altındaki zemin aynı düzeyde kaldı. Bir an durup baktı. Renk değişmişti, fakat yolun yüksekliği değişmemişti.',
'Deniz öteki renk toprağa sonraki adımını kendisi attı. "Şimdi buradan devam ediyorum," dedi. Kendi temposunu koruyup ağaca yürüdü. Arkadaşı sakin adımlarla yanından eşlik ediyordu.',
'Deniz ağacın geniş gölgesine varıp renk sınırına baktı. İlk durduğu yer şimdi gerideydi. Gördüğü farkı incelemiş, adımlarını kendisi seçmişti. Arkadaşı yanında rahatça durdu.',
'Deniz aynı düz zeminden patikaya geri döndü. İki renk toprağın sınırını yeniden geçti. Bu kez nerede durduğunu hatırlıyordu. Arkadaşı yanında ilerledi; küçük yürüyüşleri sakin biçimde tamamlandı.']),
('A2',2):('Dönen Parçanın Çizgisi',[
'Deniz yerdeki geniş kütükte iki hafif tahta parça gördü. {name} yanındaydı. Parçalardan birinde çizgi, diğerinde ok ucu vardı. Düz açıklığın yol işareti henüz tamamlanmamıştı.',
'Deniz ok uçlu parçanın çizgiye ters durduğunu fark etti. Parçaların kenarları birbirine yakındı, ama çizgiler birleşmiyordu. "Birini çevirmem gerekebilir," dedi. Önce iki parçayı birlikte incelemek istiyordu.',
'',
'Deniz ok ucunun yönünü çizginin ucuyla karşılaştırdı. "Bunu çevirip sonra yerleştireceğim," dedi. Hangi parçanın önce duracağını kendisi seçti. Arkadaşının katkısı onun yerine sıralama kararı vermiyordu.',
'Deniz çizgili parçayı kütüğün ilk geniş yuvasına koydu. Çizginin açık ucu ikinci yuvaya bakıyordu. Çocuk ok uçlu parçayı eline aldı. Şimdi çevireceği yönü açıkça görebiliyordu.',
'Deniz ok uçlu parçayı çevirip ikinci yuvaya yerleştirdi. Çizgi ve ok artık aynı yönde birleşiyordu. "Tamamladım," dedi. Son parçanın yönünü kendi karşılaştırmasına göre seçmişti.',
'Deniz tamamlanan okun düz açıklığı gösterdiğini gördü. Parçaların çizgisi kesintisizdi, ok ucu doğru taraftaydı. Çocuk arkadaşına teşekkür etti. Destek almakla son kararı vermek farklı işler olmuştu.',
'Deniz açıklığa yürüyüp aynı patikaya geri döndü. Arkadaşı yanında ilerledi. İşaret kütüğün üzerinde kaldı. Çocuk parçayı çevirmiş, sırasını seçmiş ve küçük işini tamamlamıştı.']),
('A2',3):('Kısa Çizginin Ardından',[
'Deniz geniş kütüğün üzerinde iki hafif işaret parçası gördü. {name} yanındaydı. Tahtalarda kısa ve uzun çizgiler vardı. Yanlarındaki düz açıklığın yönünü gösterecek ok henüz tamamlanmamıştı.',
'Deniz parçaların benzer kenarlarına bakıp durdu. İkisi de aynı yere sığabiliyordu, fakat çizgiler her sırada devam etmiyordu. "Deseni izleyeceğim," dedi. Yalnız kenarlara bakmak yeterli değildi.',
'',
'Deniz kısa çizginin ardından gelen uzun çizgiyi karşılaştırdı. "Bu sırada devam ediyor," dedi. Önce koyacağı parçayı kendisi seçti. Arkadaşının desteği çizgilerin sırasını onun yerine belirlemiyordu.',
'Deniz seçtiği ilk parçayı geniş yuvaya koydu. Kısa çizginin yanındaki uzun çizgi ikinci parçaya uzanıyordu. Çocuk öteki parçayı yaklaştırdı. Desenin devam edeceği kenarı yeniden gözledi.',
'Deniz ikinci parçayı çizgiler devam edecek biçimde yerleştirdi. Kısa ve uzun çizgilerden sonra ok ucu görünüyordu. "Sırayı tamamladım," dedi. Son kararı kendi karşılaştırmasıyla vermişti.',
'Deniz birleşen çizgileri ve açıklığı gösteren ok ucunu gördü. Artık işaret bütündü, parçalar yan yana duruyordu. Arkadaşına teşekkür etti. İkisinin katkısı aynı işi yapmak anlamına gelmemişti.',
'Deniz düz açıklığa yürüyüp patikaya geri döndü. Arkadaşı yanında ilerledi. Tahta parçalar geniş kütükte kaldı. Çocuk benzer kenarları değil, çizgilerin devamını düşünerek işareti tamamlamıştı.']),
('A3',2):('Kökün Aydınlık Yanı',[
'Deniz açıklıkta cebine bakıp mendilini bulamadı. {name} yanındaydı. Mendili az önce kısa patikada çıkarmıştı. Şimdi kendi eşyasının nerede kaldığını düşünmek için sakin biçimde durdu.',
'Deniz mendili koyduğu çatallı kökün aydınlık yanını hatırladı. "Güneş o tarafa vuruyordu," dedi. Bu görüntü henüz yalnız aklındaydı. Mendili de kökü de bulunduğu yerden göremiyordu.',
'',
'Deniz kendi geldiği kısa patikadan geri dönmeyi seçti. "Aydınlık tarafı hatırlıyorum," dedi. Benzer açıklıklardan ilkine hemen sapmadı. Kendi gördüğü yer ilişkisini kullanarak dönüş yolunu daraltmıştı.',
'Deniz patikanın yanındaki çatallı kökü görüp durdu. Güneş alan açık tarafı hatırladığı yere uyuyordu. "Tanıdığım kök bu," dedi. Arkadaşı geride beklerken çocuk açık yana yaklaştı.',
'Deniz kökün aydınlık yanında görünen mendilini kendi eliyle aldı. "İşte mendilim," dedi, kumaşı elinde tuttu. Hatırladığı yer şimdi önündeydi. Eşyayı bulmasını kendi gözlemi sağlamıştı.',
'Deniz elindeki mendili katlayıp kendi cebine koydu. Kök yerinde kaldı, hiçbir şeyi kaldırmamışlardı. Çocuk cebindeki kumaşa bir kez dokundu. Aradığı eşyanın artık yanında olduğunu biliyordu.',
'Deniz açıklığa dönerken arkadaşı yanında ilerledi. Mendili cebindeydi, küçük arama bitmişti. Kökün hangi yanında durduğunu hatırlamak işe yaramıştı. Aynı kısa patikadan sakin biçimde yürüdüler.']),
('A3',3):('Döndüğüm Yerdeki Mendil',[
'Deniz açıklıkta cebindeki mendilin eksik olduğunu fark etti. {name} yanındaydı. Biraz önce kısa patikada durmuştu. Şimdi eşyasını nereye bıraktığını düşünmek için sakin biçimde bekledi.',
'Deniz mendili koymadan önceki küçük dönüşünü hatırladı. Çatallı kökü geçmiş, sonra geri dönüp kumaşı bırakmıştı. "Önce kökü geçmiştim," dedi. Kökün görüntüsü şimdi yalnız aklındaydı.',
'',
'Deniz geldiği patikadan dönüp kendi adımlarının sırasını izlemeyi seçti. "Geçip döndüğüm yeri bulacağım," dedi. İlk benzer açıklığa sapmadı. Hatırladığı şey yalnız kökün biçimi değildi.',
'Deniz çatallı kökü görünce kendi küçük dönüşünü tanıdı. Önce geçtiği, sonra geri dönüp mendili bıraktığı açık taraf burasıydı. "O dönüş buradaydı," dedi. Mendili aramak için doğru yana yaklaştı.',
'Deniz kökün yanında görünen mendilini eliyle yerden aldı. "Mendilimi buldum," dedi, kumaşı elinde tuttu. Kendi dönüş sırasını hatırlaması onu buraya getirmişti. Arkadaşı sakin biçimde yanında bekledi.',
'Deniz elindeki mendili katlayıp cebine yerleştirdi. Kökün çevresindeki zemin olduğu gibi kaldı. Çocuk kendi eşyasına cebinden dokundu. Geri dönüp araması gereken küçük iş artık bitmişti.',
'Deniz arkadaşıyla aynı kısa patikadan açıklığa döndü. Mendili cebindeydi, yeni bir arama başlamadı. Kendi adımlarının sırasını hatırlamak yeterli olmuştu. Yürüyüşleri sakin biçimde tamamlandı.'])}
# Authored companion contributions: observation/support only; never substitute for child's resolution.
FRIEND={
'U1':{
'fox':'Tarçın dört ayağını rahatça yerleştirip sessizce dinledi. "Yavaşça dinliyorum," dedi. Deniz’in seçtiği sesi bitirmesini bekliyordu. Çocuğu yeni bir ses bulmaya ya da tekrara çağırmadı.',
'owl':'Yıldız alçak ve sağlam tüneğinde dengeli durup dinledi. "Duydum," dedi, kanatlarını kapalı tuttu. Deniz’in seçtiği küçük sese başka bir açıklama eklemedi. Sonra sessizce bekledi.',
'bear':'Böğürtlen geniş zeminindeki rahat yerinden sesi dinledi. "Buradan duyuyorum," dedi. Büyük bedenini çocuğun yatağına taşımadı. Deniz’in küçük sesini sürdürmesini istemeden sakin biçimde bekledi.'},
'U2':{
2:{
'hedgehog':'Kestane örtünün katlı kenarına bakıp tercihini söyledi. "Düz bir yüzey isterim," dedi. Dört kısa ayağını açık zeminde tuttu. Dikenlerinin çevresinde rahatça yer kalmasını bekliyordu.',
'cat':'Simit örtünün katlı kenarını merakla inceledi. "Düz yer bana uygun," dedi. Kıvrık kuyruğunu yanındaki açık alanda tuttu. Şehirden gelen konuk kendi rahatlığını söyleyebilirdi.',
'bear':'Böğürtlen geniş zemindeki örtüye bakıp tercihini söyledi. "Düz yüzeyde rahat ederim," dedi. Büyük bedenini açık alanda tuttu. Çocuğun hazırlayacağı yerin geniş kalmasını bekliyordu.'},
3:{
'hedgehog':'Kestane minderin yanındaki aralığa bakıp tercihini söyledi. "Yanımda açık yer isterim," dedi. Dört kısa ayağını sakin tuttu. Dikenleri çevresinde boşluk kalması ona uygun geliyordu.',
'cat':'Simit minderle örtü arasındaki aralığa baktı. "Yanımda boşluk isterim," dedi. Kıvrık kuyruğunu açık tarafta tuttu. Konuk olduğu odada kendi yerini yavaşça seçmek istiyordu.',
'bear':'Böğürtlen minderin yanındaki dar aralığa bakıp tercihini söyledi. "Geniş geçiş bana uygun," dedi. Büyük bedenini açık zeminde tuttu. Çocuğun minderi taşımasını sakin biçimde bekledi.'}},
'L1':{
2:{
'fox':'Tarçın bir salınım boyunca yaprağın açıkta kaldığını gördü. "Arada boşluk gördüm," dedi. Sakin biçimde aynı yerde bekledi. Sesin nedenini söylemek yerine çocuğun bakışına yer bıraktı.',
'owl':'Yıldız alçak sağlam dalından yaprağın açık salınımını gözledi. "Arada boşluk vardı," dedi. Kanatlarını kapalı tuttu. Hangi anın önemli olduğuna Deniz’in kendi gözlemiyle karar vermesini bekledi.',
'cat':'Simit hızlıca yaklaşmak yerine patikada durup yaprağı gözledi. "Aradaki boşluğu görüyorum," dedi. Kıvrık kuyruğu daldan uzaktaydı. Şehirden gelen meraklı konuk cevabı çocuğun yerine vermedi.'},
3:{
'fox':'Tarçın dala uzaktaki yaprağın hareketini sakin biçimde izledi. "Bu da sallanıyor," dedi. İki yaprağın arasında seçim yapmadı. Deniz’in sırayla bakabilmesi için yanında beklemeyi sürdürdü.',
'owl':'Yıldız alçak sağlam daldan uzaktaki yaprağın hareketini gözledi. "Bu da sallanıyor," dedi. Kanatları kapalıydı, sözü kısaydı. Hangi yaprağın ses çıkardığını Deniz’in kendi gözlemine bıraktı.',
'cat':'Simit uzaktaki yaprağı merakla izleyip yerinde durdu. "Bu yaprak da sallanıyor," dedi. Kıvrık kuyruğunu yanında tuttu. Şehirden gelen konuk iki adaydan birini çocuk adına seçmedi.'}},
'L2':{
2:{
'hedgehog':'Kestane kısa ayaklarıyla açık tarafta durup yeşil sapı gördü. "Burada sap var," dedi. Üstteki kuru yapraklara dokunmadı. Deniz’in öteki yandan bakabilmesi için geçişi açık bıraktı.',
'owl':'Yıldız alçak sağlam tüneğinden yeşil sapı gördü. "Burada sap var," dedi. Kanatlarını kapalı tutup bekledi. Üstteki yaprakları kaldırmadan çocuğun başka yerden bakmasına alan bıraktı.',
'bear':'Böğürtlen geniş patikada durup yaprağın sapını gördü. "Bu yanda sap var," dedi. Büyük pençeleri yerde kaldı. Yaprakları kaldırmak yerine Deniz’in geçebileceği alanı açık bıraktı.'},
3:{
'hedgehog':'Kestane açık tarafta kısa ayaklarıyla durup sapı gördü. "Sap bu yanda," dedi. Kıvrılmış kenarı açmaya çalışmadı. Deniz’in yaprağın çevresinden geçebilmesi için biraz geriye çekildi.',
'owl':'Yıldız alçak sağlam tüneğinden yaprağın sapını gözledi. "Sap bu yanda," dedi. Kanatlarını kapalı tuttu. Çocuğun diğer kenarı görebileceği yeri seçmesini sessizce bekledi, yaprağa dokunmadı.',
'bear':'Böğürtlen geniş patikadan yaprağın sapını gördü. "Sapı buradan görüyorum," dedi. Büyük bedenini geçişten uzakta tuttu. Yaprağı açmak yerine Deniz’in başka yandan bakmasına alan bıraktı.'}},
'L3':{
'fox':'Tarçın patikanın açık yanında sakin biçimde bekledi. "Burada durabilirim," dedi. Yaprağı oynatmadı, çocuğu acele ettirmedi. Deniz’in kendi gözlemini tamamlamasına yalnız sabırlı varlığıyla eşlik ediyordu.',
'hedgehog':'Kestane dört kısa ayağını açık zeminde sakin tuttu. "Ben de beklerim," dedi. Yaprağa yaklaşmak için acele etmedi. Deniz’in kendi gözlemini tamamlamasına yanında durarak eşlik ediyordu.',
'cat':'Simit öne atılmak yerine dört patisini patikada tuttu. "Burada bekliyorum," dedi. Kıvrık kuyruğu yapraktan uzaktaydı. Şehirden gelen meraklı konuk, Deniz’in gözlemini bitirmesine yavaşlayarak eşlik ediyordu.',
'bear':'Böğürtlen geniş patikanın yanında sakin biçimde durdu. "Beklemek için yerimiz var," dedi. Büyük pençelerini yaprağa uzatmadı. Deniz’in kendi gözlemini tamamlamasına yalnız yanında durarak eşlik ediyordu.'},
'A1':{
'fox':'Tarçın dört ayağıyla çocuğun yanında sakin durdu. "Senin hızınla yürürüm," dedi. Önden koşup çağırmadı. Deniz’in duracağı yeri kendisinin seçebilmesi için açıklığın kenarında bekledi.',
'hedgehog':'Kestane dört kısa ayağını sakin biçimde yere koydu. "Küçük adımlarla eşlik edebilirim," dedi. Önce kendisi bir yer seçmedi. Deniz’in ilk duruşunu kararlaştırmasını yanında bekledi.',
'cat':'Simit dört patisiyle çocuğun yanında yavaşlayıp durdu. "Seninle sakin yürürüm," dedi. Kıvrık kuyruğu arkasındaydı. Şehirden gelen konuk önden koşmak yerine Deniz’in kendi adımını seçmesini bekledi.'},
'A2':{
2:{
'fox':'Tarçın bir pençesini hafif çizgili parçanın kenarına koydu. "Bunu sabit tutabilirim," dedi. Öteki parçayı çevirmedi. Deniz’in yönü karşılaştırması için sakin biçimde yerinde bekledi.',
'owl':'Yıldız alçak sağlam daldan parçaların arasındaki kesik çizgiyi gözledi. "Burada çizgi kesiliyor," dedi. Kanatlarını kapalı tuttu. Parçaları yerleştirmek ve yönlerini seçmek Deniz’in kendi işi olarak kaldı.',
'bear':'Böğürtlen geniş zeminden hafif parçanın kenarını pençesiyle tuttu. "Bunu sabit tutabilirim," dedi. Parçayı zorlayıp çevirmedi. Büyük gücü yerine çocuğun karşılaştırmasına sakin bir destek sunuyordu.'},
3:{
'fox':'Tarçın seçilmeyi bekleyen hafif parçanın kenarını pençesiyle tuttu. "Kaymadan bekleyebilir," dedi. Hangi sıraya konacağını söylemedi. Deniz’in kısa ve uzun çizgileri karşılaştırması için sakin kaldı.',
'owl':'Yıldız alçak sağlam daldan parçaların üzerindeki çizgileri gözledi. "Kısa çizgiyi görüyorum," dedi. Kanatlarını kapalı tuttu. Sırayı söylemek yerine Deniz’in kendi karşılaştırmasını yapmasını sessizce bekledi.',
'bear':'Böğürtlen hafif parçanın kenarını geniş pençesiyle sabit tuttu. "Karşılaştırırken burada kalır," dedi. Parçaları sıralamadı. Büyük gücü çocuğun fikrinin yerine geçmeden küçük işe destek olmuştu.'}},
'A3':{
'hedgehog':'Kestane dört kısa ayağıyla çocuğun yanında sakin durdu. "Senin hatırladığını dinliyorum," dedi. Mendilin yerini tahmin etmedi. Deniz’in kendi gördüğü ayrıntıyı tamamlaması için açık patikada bekledi.',
'owl':'Yıldız alçak sağlam dalından çocuğun anlattığını dinledi. "Seni dinliyorum," dedi. Mendili aramak için uçmadı, kanatlarını kapalı tuttu. Deniz’in kendi hatırladığı ayrıntıyla yol seçmesini bekliyordu.',
'cat':'Simit dört patisini patikada tutup çocuğu dinledi. "Senin hatırladığın yerden gidelim," dedi. Mendilin kokusunu aramadı. Şehirden gelen konuk, kıvrık kuyruğunu yanında tutarak sakin biçimde bekledi.',
'bear':'Böğürtlen geniş patikanın açık yanında çocuğu dinledi. "Hatırladığın yerden yürüyebiliriz," dedi. Kökleri kaldırmayı önermedi, pençeleri yerde kaldı. Deniz’in kendi ayrıntısıyla karar vermesini sakin biçimde bekledi.'}}
TRIAL={
2:{
'hedgehog':'Kestane düz örtünün üzerine dört kısa ayağıyla yerleşti. "Bu yüzey rahat," dedi. Dikenlerinin çevresindeki alan açıktı. Kendi duruşunu seçti, çocuktan başka bir düzeltme istemedi.',
'cat':'Simit düz örtüyü dört patisiyle yavaşça denedi. "Bu yüzey rahat," dedi. Kıvrık kuyruğunu açık yanında tuttu. Şehirden gelen konuk artık kendi dinlenme yerini seçmişti.',
'bear':'Böğürtlen geniş örtünün üzerindeki düz yüzeyi yavaşça denedi. "Bu yüzey rahat," dedi. Büyük bedeni için yeterli yer vardı. Çocuktan başka bir düzeltme istemeden duruşunu seçti.'},
3:{
'hedgehog':'Kestane açık aralıktan geçip örtünün yanında kendi yerini seçti. "Burada rahatım," dedi. Dikenlerinin çevresinde boşluk kalmıştı. Dört kısa ayağını sakin tuttu, mindere yaklaşması gerekmiyordu.',
'cat':'Simit açık aralıktan yavaşça geçip kendi yerini seçti. "Burada rahatım," dedi. Kıvrık kuyruğuna boşluk kalmıştı. Şehirden gelen konuk, geniş örtünün yanında uyanık biçimde durdu.',
'bear':'Böğürtlen genişleyen geçişten ilerleyip örtüde kendi yerini seçti. "Burada rahatım," dedi. Büyük bedeni için açık alan kalmıştı. Minder duvarın yanında duruyor, geçişi artık daraltmıyordu.'}}
PROP={
('U1',2):('hand_rubbing_sound','çocuğun yatağı, örtü, kapalı pencere; el sürtme sesi ayrı görünür nesne değildir'),
('U1',3):('cover_rustle','çocuğun yatağı, örtü, kapalı pencere; örtünün bir kez düzeltilmesi ve ardından hareketsiz kalması'),
('U2',2):('flat_resting_cover','çocuğun yatağı; yerde katlı kenarı açılan düz geniş örtü, açık geçiş'),
('U2',3):('space_beside_rest','çocuğun yatağı; geniş minder, yerde düz dinlenme örtüsü, açılan geçiş'),
('U3',2):('remembered_stopping_shadow','odada yatak, örtü ve kapalı pencere; gündüz durmuş gölge yalnız hatırlanan görüntü'),
('U3',3):('remembered_released_leaf','odada yatak, örtü ve kapalı pencere; avuçtan bırakılan yaprak yalnız gündüz anısı'),
('L1',2):('intermittent_leaf_contact','alçak dal, ona değip ayrılan kuru yaprak, geniş patika'),
('L1',3):('two_leaves_contact','alçak dal; biri dala yakın, diğeri uzakta iki kuru yaprak; geniş patika'),
('L2',2):('leaf_occluded_by_leaves','yerde tek yeşil yaprak ve ortasını örten iki kuru yaprak; görünen sap, sivri uç, damar'),
('L2',3):('curled_leaf_views','yerde kendi kenarı kıvrılmış tek yaprak; sap ve iki kenar; açık dolaşma alanı'),
('L3',2):('merging_leaf_drops','alçak yaprakta birleşen iki damla, ince su çizgisi ve toprak; düz patika'),
('L3',3):('moving_leaf_drop','alçak yaprakta damar boyunca ilerleyen tek damla; yaprak damarı ve toprak'),
('A1',2):('light_transition_clearing','gölgeli patika, güneşli düz kuru açıklık, hedef geniş ağaç gölgesi'),
('A1',3):('color_boundary_clearing','aynı yükseklikte açık ve koyu kuru toprak, geniş hedef ağacı ve düz patika'),
('A2',2):('rotated_marker_parts','yerde geniş kütük ve iki geniş yuva; hafif çizgili ve ok uçlu iki tahta parça'),
('A2',3):('sequence_marker_parts','geniş kütük ve iki geniş yuva; kısa uzun çizgileri ve ok ucunu taşıyan iki hafif tahta parça'),
('A3',2):('child_cloth_at_root','çocuğun mendili ve çatallı kök; kısa açık patika, kökün güneş alan yanı'),
('A3',3):('child_cloth_at_root','çocuğun mendili ve çatallı kök; kısa açık patika, hatırlanan geçip dönme sırası')}

def contribution(shape,event,char):
    spec=FRIEND[shape]
    return spec[event][char] if event in spec else spec[char]

def serialize():
    ROOT.mkdir(parents=True,exist_ok=True);(ROOT/'books').mkdir(exist_ok=True)
    legacy_manifest=json.loads((LEGACY/'manifest.json').read_text())
    structures={v['planLabel']:v for v in json.loads((LEGACY/'structures.json').read_text())['structures']}
    characters={v['id']:v for v in legacy_manifest['companions']}
    sources=[];items=[];causals=[]
    for olditem in legacy_manifest['books']:
        base=json.loads((LEGACY/olditem['file']).read_text());shape=base['planLabel']
        char=base['id'].split('_')[-2];comp=characters[base['context']['companionID']];name=comp['name'];cid=comp['id']
        for event in (2,3):
            title,draft=EVENTS[(shape,event)];texts=[v.format(name=name) for v in draft]
            if shape in FRIEND:texts[2]=contribution(shape,event,char)
            if shape=='U2':texts[4]=TRIAL[event][char]
            if char=='cat':texts[0]+=' Simit şehirden bugün ziyarete gelmişti.'
            if char=='owl':texts[0]+=' Yıldız alçak sağlam tünekteydi.'
            bookid=f'pilot56_book_{shape.lower()}_{char}_event{event:02d}_v1'
            propkey,propdesc=PROP[(shape,event)]
            discovery=base['context']['discoveryID'] if shape=='A3' else f'pilot56_discovery_{propkey}_v1'
            context=copy.deepcopy(base['context']);context['discoveryID']=discovery
            book={k:copy.deepcopy(v) for k,v in base.items() if k!='pages'}
            book.update(id=bookid,title=title,baseBookID=base['id'],variantID=f'event{event:02d}',
                context=context,status='authored-internal-review-required',runtimeCompatible=False,independentEditorialApproval=False)
            book['childAgency']=structures[shape]['solution'] if shape not in ('A2','L2','L3') else {
                'A2':'Çocuk parçaların yönünü ve sırasını karşılaştırıp işareti kendi tamamlar.',
                'L2':'Çocuk iki bakış yerini seçer, görünüşleri birleştirir; yaprağı veya örtücüyü oynatmaz.',
                'L3':'Çocuk dokunmadan bekler, önceki ve sonraki damla durumunu kendi karşılaştırır.'}[shape]
            book['pages']=[]
            for i,text in enumerate(texts,1):
                role=structures[shape]['pageMoves'][i-1]
                sid=f'pilot56_source_{shape.lower()}_{char}_event{event:02d}_p{i:02d}_v1'
                # Full sentences are retained as separately identifiable source segments.
                sentences=re.findall(r'.+?(?:[.!?](?:[\"”])?(?=\s|$)|$)',text)
                sentences=[s.strip() for s in sentences if s.strip()]
                sentenceids=[]
                for j,s in enumerate(sentences,1):
                    ssid=f'{sid}_s{j:02d}';sentenceids.append(ssid)
                    sources.append(dict(id=ssid,kind='authoredSentenceSegment',parentSourceID=sid,text=s,sha256UTF8=sha(s)))
                parentindex=len(sources)
                sources.append(dict(id=sid,kind='authoredFullPage',text=text,sha256UTF8=sha(text),sentenceSourceIDs=sentenceids,
                    blueprintID=base['blueprintID'],bookID=bookid,pageNumber=i,context=copy.deepcopy(context)))
                subjects=[dict(subjectID=context['syntheticChildID'],presence='present',states=['awake']),
                    dict(subjectID=cid,presence='present',states=['awake','species-anatomy-preserved'])]
                presence='remembered' if shape=='U3' else ('intended' if shape=='A3' and i<6 else 'present')
                states=['remembered-day-detail'] if shape=='U3' else ['scene-prop']
                if shape=='A3' and i==6:states=['cloth-in-child-hand']
                if shape=='A3' and i>=7:states=['cloth-in-child-pocket']
                if shape=='L3' and i>=7:states=['drop-fallen-to-soil']
                subjects.append(dict(subjectID=discovery,presence=presence,states=states))
                if shape=='A3' and 2<=i<=7:
                    subjects.append(dict(subjectID='pilot56_object_forked_root_v1',presence='remembered' if i<5 else 'present',states=['fixed-ground-root']))
                # New prop subjects are scoped to these new narratives, never aliases of old text IDs.
                if shape=='L2' and event==2:
                    subjects.append(dict(subjectID='pilot56_object_two_covering_dry_leaves_v1',presence='present',states=['two-dry-leaves','unmoved']))
                if shape=='L2' and event==3:
                    subjects.append(dict(subjectID='pilot56_object_curled_leaf_v1',presence='present',states=['one-leaf','curled','unmoved']))
                if shape=='L1' and event==3:
                    subjects.append(dict(subjectID='pilot56_object_two_dry_leaf_candidates_v1',presence='present',states=['two-leaves','one-contacts-branch']))
                if shape=='A1' and event==3:
                    subjects.append(dict(subjectID='pilot56_object_ground_color_boundary_v1',presence='present',states=['flat','dry','equal-height']))
                if char=='owl':
                    subjects.append(dict(subjectID='pilot56_object_stable_low_perch_v1',presence='present',states=['stable','species-appropriate-rest']))
                friendrole=(role in ('friend_listens','friend_preference','friend_one_observation','friend_second_view','friend_waits','friend_support','friend_contribution') or role=='soft_trial' or(shape=='U1' and role=='awake_rest'))
                actor=cid if friendrole else 'child';actorname=name if friendrole else 'Deniz'
                evidence=dict(bookID=bookid,pageNumber=i,actorID=actor,quote=sentences[0],attributionQuote=actorname,
                    attributionSourceID=sid,parentSourceID=sid,kind='sourceStatement',quoteSHA256=sha(sentences[0]))
                causals.append(evidence)
                # Metadata remains page-context evidence, not approved atomic annotation.
                actionactors=[cid] if friendrole else [context['syntheticChildID']]
                page=dict(pageNumber=i,role=role,orderedBeatIDs=copy.deepcopy(base['pages'][i-1]['orderedBeatIDs']),text=text,
                    context=copy.deepcopy(context),previousPageNumber=i-1 if i>1 else None,nextPageNumber=i+1 if i<8 else None,
                    stateBefore='not-started' if i==1 else structures[shape]['pageMoves'][i-2],stateAfter=role,
                    provenance=dict(complete=True,partCount=1,parts=[dict(order=0,sourceKind='pilotAuthoredFullPage',sourceID=sid,
                        sourceTextDigest=sha(text),templateID=base['blueprintID'],sourcePointer=f'sources.json#/sources/{parentindex}',contexts=copy.deepcopy(context))]),
                    sentenceSourceIDs=sentenceids,
                    semantics=dict(annotationStatus='authored-draft-independent-review-required',inventoryScope='Named story actors and narrative prop groups; not render authorization.',metadataRevision=1,
                        subjects=subjects,propDescription=propdesc,actions=[dict(actorSubjectIDs=actionactors,description=text,evidenceSourceID=sid,evidenceText=text,
                            scope='page-context; not atomic executable action',atomicActionMappingApproved=False)],
                        temporalNote='Remembered events remain past; intentions are not present actions. Closed eyes never establish actual sleep.'),
                    artHandoff=dict(contentMeaningStatus='independent-review-required',visualIdentityStatus='not-reviewed-for-this-page',assetRuleApproval=False,runtimeArt=None,
                        actionNeed=text,anatomyAndScale=base['physicalContract'],doNotDraw=['No unmentioned prop or extra character.','Do not render memories or intentions as current physical actions.',
                            'Preserve species anatomy and child ownership of the resolution.']+(['Simit is a city visitor today, never a forest resident.'] if char=='cat' else [])),
                    editorialIntensity=0 if shape.startswith('U') else 1)
                book['pages'].append(page)
            path=ROOT/'books'/f'{bookid}.json';dump(path,book)
            items.append(dict(bookID=bookid,file=f'books/{bookid}.json',sha256FileBytes=sha(path.read_bytes()),baseBookID=base['id'],variantID=f'event{event:02d}',
                planLabel=shape,companionID=cid,pageCount=8,wordCountWhitespace=sum(len(t.split()) for t in texts)))
    manifest={k:copy.deepcopy(v) for k,v in legacy_manifest.items() if k not in ('books','packageID','acceptance','sourcePayloadSHA256FileBytes','structuresFile')}
    manifest.update(packageID='five-friends-56-expansion-v1',books=items,basePackageID='five-friends-56-v1',
        expansionOnly=True,independentEditorialApproval=False,runtimePackage=False,productionEnabled=False)
    manifest['supportedContext']['topic']='not-reviewed; no topic support claim'
    manifest['structuresFile']='../five-friends-56-v1/structures.json'
    manifest['acceptance']=dict(authoredPairs=60,authoredPages=480,randomFirstAttemptSeedsRun=0,runtimeBooksComposed=0,artPagesApproved=0,engineStateMappingApproved=False,independentEditorialReviewComplete=False,releaseApproved=False)
    dump(ROOT/'sources.json',dict(schema='magicpaper.pilot-authoring-sources.v1',digestConvention='SHA-256, exact UTF-8 text, no normalization, lowercase hex',sources=sources))
    manifest['sourcePayloadSHA256FileBytes']=sha((ROOT/'sources.json').read_bytes())
    dump(ROOT/'manifest.json',manifest)
    dump(ROOT/'causal-evidence.json',dict(schema='magicpaper.p56-editorial-causal-evidence.v1',status='authored-span-map-independent-review-required',records=causals))
if __name__=='__main__':serialize()
