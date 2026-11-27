"""Materialize explicitly authored V4 pilot art review, not a keyword matcher.
Run from repository root: python3 Tools/story-art/build_v4_pilot_review.py
"""
import collections
import hashlib
import json
from pathlib import Path

BASE = Path('design-handoff/proposals/2026-11-26-v4-art-library')
# Page-by-page editorial observations, read against complete pinned page text.
# None means a deliberate text-only page in this first three-moment proposal.
REVIEWS = {
'u1_fox': [
('Minderde yatan, burnu hareketli ve uyanık Tarçın.', 'fox_resting_awake_cushion'),
('Ses çocuğun avuçlarından; Tarçın yalnız kulaklarını oynatır.', None),
('Başını kaldırıp minderini, ardından kendi kuyruğunu koklar.', None),
('Çocuğun durma kararını bekleyerek dinler; uyku gösterilmez.', None),
('Kuyruğunu minder üzerinde kaydırır; kulakları diktir.', 'fox_tail_sweep_cushion'),
('Kuyruk burnunun üzerindedir; gözlerin kapandığı söylenmez.', None),
('Burnu patilerinin arasında; ikisi de hareketsiz dinlenir.', 'fox_nose_between_paws_resting'),
('İyi geceler fısıldar; boyunluk minder üstünde; uyku geçişi var, boyunluk takılı varsayılmaz.', None)],
'u1_owl': [
('Tünekte uyanık Yıldız; gece mavisi tüyler. Göz benzetmesi gerçek ay değildir.', 'owl_perched_awake'),
('Başını çocuğun el sesine çevirir.', None),
('Kanatlarını birbirine sürter ama ses çıkmaz; ses efektli kanat çizilmez.', 'owl_wings_rubbing_silent'),
('Gözleri yarı kapalıdır; uyuduğu varsayılmaz.', None),
('Sessiz kanat denemesi ve göz kırpma; uçuşa geçmez.', None),
('Tüylerini kabartır; uyanık/sessiz oda.', None),
('Kanatları gövdesine toplanmış, hareketsiz durur.', 'owl_perched_wings_folded_resting'),
('Yıldız tüyü nefesle hareket eder; uyuyan çocuk, dinlenen baykuş. Baykuşa kapalı göz zorlanmaz.', None)],
'u1_bear': [
('Geniş döşekte oturur; çanta askıda, gövdede değildir.', 'bear_seated_mattress_bag_on_hook'),
('Yalnız çocuğun avuç hareketi açık; karakter hareketi eklenmez.', None),
('Kocaman patilerini sürtüp yüksek sese şaşırır; çanta askıda kalır.', 'bear_rubbing_paws_no_bag'),
('Çocuğun isimlendirmesi; ek görsel olay gerekmez.', None),
('Patilerini bu kez yavaş sürter; küçük ses. Aynı statik poz hız karşıtlığını tek başına anlatmaz.', None),
('Çocuğun elleri dinlenir; ayıya yeni hareket eklenmez.', None),
('Patiler karın üstünde; mor lekeli pati görünür, ninni mırıldanır; çanta askıda.', 'bear_paws_on_belly_no_bag'),
('Çocuk gözlerini kapar; ayı destek sözünü söyler, dinlenir; uyuyan ayı iddiası yok.', None)],
'u2_hedgehog': [
('Örtü kenarında uyanık Kestane, dikeninde gündüzden tüy; pencere ayı mevcut.', 'hedgehog_blanket_edge_feather'),
('Katlı örtü kenarında düşünüp bekler.', None),
('Katlı kenara tırmanır, sallanır ve yuvarlanır; tek karede sıra belirsiz, ilk pakette metin.', None),
('Kat açıldı; düz örtüye bir adım atar.', None),
('Düz örtüde yürür; tüy artık dikeninde değil, örtü kenarında yastıktır.', 'hedgehog_flat_blanket_feather_beside'),
('Örtü ortasına kıvrılır; tüy kenarda kalır.', None),
('Tüyün yanına kıvrılmıştır; hardal yaprak diken ucunda görünür.', 'hedgehog_curled_leaf_feather_beside'),
('Fısıltıdan sonra yuvarlak top olur; uyku açıkça söylenmez.', None)],
'u2_cat': [
('Örtüye merakla yaklaşır; tasma kırmızı, çan görünür.', 'cat_approach_blanket_bell_visible'),
('Katlı örtü kenarını koklar.', None),
('Zıplama sonrası kat çöker ve yuvarlanır; yanlış katı platform çizilmez.', None),
('Çocuk katı açar, Simit için yer bırakır; ekstra kedi hareketi eklenmez.', None),
('Düz örtüyü patileriyle yoklayıp yavaşça oturur; zıplama değildir.', 'cat_sit_flat_blanket_bell_visible'),
('Bir tur dönüp örtüye yatar.', None),
('Kıvrılmıştır; çanı patisinin altında, çan görünür/sesli çizilmez.', 'cat_curled_bell_under_paw'),
('İyi geceler mırlaması; çan önceki konumda, açık uyku iddiası yok.', None)],
'l1_fox': [
('Kuru yaprak alçak dal önünde sallanır; temas henüz doğrulanmadı.', 'leaf_branch_gap'),
('Bir salınım sessiz; Tarçın kulaklarını diker.', None),
('Burnunu uzatıp hapşırır; yaprak hareketli ama ses yok. Koku nesnesi çizilmez.', None),
('Çocuk boşluğu izlemeyi seçer, Tarçın bir kulağını o yana çevirir.', None),
('Yaprak dala değer; tık. Geri açılma sonraki an; tek kare temas anını gösterir.', 'leaf_branch_contact'),
('Çocuğun iki salınımdan çıkardığı sonuç; Tarçın kuyruğunu sallar.', None),
('Tekrar temas ve tık; doğru cevap kokusu bir metafor, fiziksel koku nesnesi yok.', None),
('Yaprak dalında kalır; Tarçın yolda gerçek çiçeği koklar, hapşırmaz.', 'fox_sniff_flower')],
'l1_owl': [
('Yaprak dal önünde, Yıldız alçak dalda; henüz temas doğrulanmadı.', 'leaf_branch_gap'),
('Sessiz salınımı dinler; fiziksel ses çizgisi gereksiz.', None),
('Başını yaprakla sallayıp başı döner; baş anatomisi korunur.', None),
('Gözü aralıktadır; çocuğun gözlemini cevaplayıp bitirmez.', None),
('Temas anında tık; Yıldız başını sabit tutar.', 'leaf_branch_contact'),
('Tüy kabartarak sessiz onay; gözlemi çocuk sonuçlandırır.', None),
('Yeniden temas, yavaş göz kırpma ve esneme; uyku değildir.', None),
('Alçaktan çocuğun yanına süzülür; uçuş bitişi veya çocuk eli uydurulmaz.', 'owl_low_glide')],
'l1_cat': [
('Alçak dalın önündeki kuru yaprak; aralık durumu.', 'leaf_branch_gap'),
('Çocuğun sessiz salınımı gözlemesi; Simit için yeni eylem yok.', None),
('Patisini kaldırır, sonra indirir; yaprağı yakalamaz. İlk pakette aksiyon tek kareye sıkıştırılmaz.', None),
('Çocuğun gözlem kararı; yaprak yerinde kalır.', None),
('Yaprak dala temas eder, tık; bıyıklar titrer.', 'leaf_branch_contact'),
('Sonuç çocuğa ait; ek fiziksel nesne yok.', None),
('Tekrar temas; şehirdeki perde yalnız anı/karşılaştırma, ormana perde eklenmez.', None),
('Yanında yürürken durup patisini havada tutar; tasma çanı görünür.', 'cat_pause_paw_raised')],
'l2_hedgehog': [
('İki kuru yaprak tek yeşil yaprağın ortasını örter; uç ve sap aynı yaprağa aittir.', 'occluded_leaf_overview'),
('Yakın sivri uç görünür; orta kapalı, Kestane kuru yaprak dibinde.', None),
('Öbür yana yürüyüp sapı görür; kuru yaprakları toplamaz.', None),
('Çocuk ve Kestane öbür yana geçer; yapraklara dokunulmaz.', None),
('Uç ve sap damarları aralıktan aynı çizgidir; bekleyen Kestane, örtücüler kaldırılmaz.', 'occluded_leaf_vein_gap'),
('Çocuk tek yaprak sonucuna varır; nesne aynı yerinde kalır.', None),
('Aralıktan tekrar doğrular; Kestane top olur. Yaprak bütünü açılmaz.', None),
('Patikada dikenine sarı yaprak takılır; sahnedeki yapraklar yerde bırakılmıştır.', 'hedgehog_walk_yellow_leaf')],
'l2_bear': [
('İki kuru yaprak tek yeşil yaprağın ortasını örter; tamamı görünmez.', 'occluded_leaf_overview'),
('Çocuk kuru yaprakları çekmez, sivri uçtan çevreye bakar.', None),
('Ayı öbür yana geçip çantasından gerçek böğürtlen çıkarır.', None),
('Çocuk öbür yana geçer; yapraklar yerinden oynatılmaz.', None),
('Aralıktan kesintisiz damar; ayı beklerken çiğner.', 'occluded_leaf_vein_gap'),
('Tek yaprak çıkarımı zihinseldir; kuru yapraklar hâlâ ortayı örter.', None),
('Yeni böğürtlen yer; aynı yaprak durumu korunur.', None),
('Yürüyen ayının ağız kenarı artık mor; mendil çocuğun elinden uzatılır. Çocuksuz kırpımda yalnız ağız lekeli yürüyüş seç.', 'bear_walk_purple_mouth')],
'a1_fox': [
('Gölgeli patika, düz güneşli açıklık, ötesinde geniş ağaç gölgesi; taş henüz seçilmedi.', 'clearing_shadow_threshold'),
('Tarçın güneşe gözlerini kısar; durak yeri henüz kararlaştırılmadı.', None),
('Güneşi koklama benzetmesi; gerçek ekmek yok.', None),
('Yuvarlak taş gerçek mola hedefi; Tarçın taşı koklar, çocuk henüz ilk adımı atmamıştır.', None),
('Çocuk taş yanına varır; Tarçın oturur ve kuyruğunu dolandırır.', 'fox_sit_curled_tail_round_stone'),
('Çocuğun yanında hafif sekiş; kuyruk ucu güneşte.', None),
('Ağaç gölgesine varılmış; mola taşı artık geride, başlangıçta.', None),
('Dönüş yolunda aynı taşı yeniden koklar; taş güneş metaforunun maddi karşılığına dönüşmez.', 'fox_sniff_round_stone')],
'a1_hedgehog': [
('Patikadan düz açıklık ve karşı ağaç gölgesi; henüz tüy yok.', 'clearing_shadow_threshold'),
('Kestane gölgede kalır; çocuğun ilk adımı onun yerine atılmaz.', None),
('Burnunu güneşe uzatırken dikenine yeni bir tüy konar.', None),
('Seçilen yuvarlak taşa yürür; tüy dikeninde süreklidir.', None),
('Taş yanında tüyünü sallayıp çevreye bakar; tüyü yaprakla değiştirme.', 'hedgehog_stone_feather_on_spines'),
('Ağaca doğru yürüyüş, tüy dikeninde rüzgârda.', None),
('Serin ağaç gölgesi, mola taşı geride kalır.', None),
('Dönüşte tüyünü dikenine yerleştirir; güneş tüyü gerçek parlayan nesne değildir.', 'hedgehog_return_feather_on_spines')],
'a1_cat': [
('Gölge–açıklık–ağaç gölgesi rotası; pencere yok.', 'clearing_shadow_threshold'),
('Çocuğun mola kararı; Simit için yeni hareket yok.', None),
('Güneşe göz kısar; şehirdeki pencere benzetme, ormana pencere eklenmez.', None),
('Çocuk mola taşını seçer, Simit taşa varınca yanına kıvrılır.', 'cat_curled_round_stone_awake'),
('Güneşte mırlama; uykuya geçtiği söylenmez.', None),
('Gerindikten sonra çocuğa gelir ve yürür; hareket sırasını tek karede çoğaltma.', None),
('Ağaç gölgesinde tüylerini yalar; taş başlangıçta kalır.', 'cat_grooming_in_shade'),
('Taşı götürmeyi sorar fakat taş yerinde kalır; taşıyan kedi çizilmez.', None)],
'a2_owl': [
('Geniş kütük üstünde ayrı çizgi ve ok ucu parçaları; Yıldız alçak dalda.', 'marker_parts_separate_reversed'),
('Ok ucu çizgiye ters; birleşik yön oku çizilmez.', None),
('Başını neredeyse ters çevirir; ok hâlâ düzeltilmemiştir.', None),
('Döndürme yalnız niyet; Yıldız başını düzeltip bekler.', None),
('Çizgili parça ilk yuvada, Yıldız kenarına pençeleriyle basar; ikinci parça çocuğun elinde.', 'owl_stabilize_line_piece'),
('Çocuk ikinci parçayı çevirip yerleştirir; tamamlanmış ok aynı yöne bakar.', None),
('Tamamlanmış ok açıklığı gösterir; Yıldız başı düz.', 'marker_parts_completed_arrow'),
('Alçaktan süzülüp gelir, ardından esner; yan yana olayları tek karede üst üste bindirme.', None)],
'a2_bear': [
('Geniş kütük üzerinde iki ayrı tahta; çizgi ve ok ucu henüz birleşmez.', 'marker_parts_separate_reversed'),
('Ok ucu ters; çevirme niyet, gerçekleşmiş değildir.', None),
('Büyük pati çizgili parçanın yarısını örter; çanta gövdede.', None),
('Pati kenara kayar; çocuk yönü karşılaştırır, parça henüz dönmemiştir.', 'bear_paw_edge_line_piece'),
('İlk parça yuvada; ikinci parça çocuğun elinde, ayının katkısı mırıltı.', None),
('Çocuk ikinci parçayı çevirip koyar; ok tamamlanır.', None),
('Ok açıklığı gösterir; ayı çantasından gerçek kutlama böğürtleni çıkarır.', 'marker_parts_completed_arrow'),
('Yanında yürürken şarkı söyler; yeni eşya eklenmez.', None)],
}

def main():
    source = json.loads((BASE/'inventory.json').read_text())
    selected = {p['bookID'] for p in source['pilotBooks']}
    reviews=[]
    for page in source['pages']:
        if page['bookID'] not in selected:
            continue
        key=page['bookID'].removeprefix('pilot56_book_').removesuffix('_event02_v1')
        note, need=REVIEWS[key][page['number']-1]
        assert hashlib.sha256(page['templateText'].encode()).hexdigest()==page['templateSHA256']
        reviews.append({k:page[k] for k in ('bookID','mode','companionID','number','templateID','templateSHA256','parentSourceID','parentSHA256','templateText')} | {
            'reviewType':'authored-page-by-page-art-planning','reviewDate':'2026-11-27',
            'visualReading':note,'proposedNeedID':need,'proposalStatus':'candidate-not-asset-authorized' if need else 'text-only-first-pilot',
            'childRendering':'omitted; crop companion/object without implying absent child',
            'assetRuleApproval':False,'runtimeArt':None})
    counts=collections.Counter(r['proposedNeedID'] for r in reviews if r['proposedNeedID'])
    assert len(reviews)==120 and sum(counts.values())==45
    assert len({r['bookID'] for r in reviews})==15
    perbook=collections.Counter(r['bookID'] for r in reviews if r['proposedNeedID'])
    assert set(perbook.values())=={3}
    result={'packageVersion':source['packageVersion'],'payloadSHA256':source['payloadSHA256'],
            'scope':'15 selected event02 books only; not all V4 structures',
            'coverageMeaning':'45 proposed illustration moments, zero published bindings; not achieved runtime coverage',
            'counts':{'reviewedPages':120,'proposedMoments':45,'uniqueNeeds':len(counts),'textOnlyPages':75},
            'needs':[{'needID':k,'pageCount':v,'sources':[{'templateID':r['templateID'],'templateSHA256':r['templateSHA256']} for r in reviews if r['proposedNeedID']==k]} for k,v in sorted(counts.items())],
            'pages':reviews}
    (BASE/'pilot-page-review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(result['counts'])

if __name__=='__main__':
    main()
