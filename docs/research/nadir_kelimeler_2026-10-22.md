# Nadir kelime raporu · 2026-10-22

Kaynak: `Tools/nadir_kelime_raporu.py` (plan: `docs/Kelime_Plani_kitapokur.md` B). Öneridir; kelimeyi sadeleştirmeye ya da sözlüğe eklemeye yazar karar verir.

Eşikler (Zipf, altı nadir): 3-4 → 4.5 · 5-6 → 4.0 · 7-8 → 3.5 · 9-10 → 3.0. 5.0 ve üstü her bantta yaygın sayılır. Başlangıç değerleridir, kalibre edilmedi.

Okunan dosyalar: 107 (`ContentCatalogLoader` ile aynı küme).

Nadirlik, kelimenin en yaygın makul biçimiyle ölçülür (kök, eki soyulmuş adaylar, fiilin sık çekimleri); Türkçede sıklık çekimli biçimlere dağıldığı için çıplak gövde tek başına nadir görünür. Kök bulma kural tabanlıdır: bazı biçimler köke inmez ("omzuna"), bazı fiiller gövdesiyle görünür ("otur"). `sözlükte`, o bandın sözlüğünde eşleşen bir girdi olduğunu söyler; satırın o kelimeyi `words` ile açıklayıp açıklamadığını değil.

## 3-4 yaş

249 satır · 79 nadir kök · 73 açıklamasız

| kök | Zipf | geçiş | sözlükte | kaynak | örnek cümle |
|---|---:|---:|---|---|---|
| esne | 3.03 | 14 | **hayır** | bt3_eo_fs_01, bt3_eo_fa_02, bt3_mc_02 +11 | Kardeşi {…} yan yatakta esniyordu. |
| fısıldadı | 3.15 | 1 | evet | swc3_fam_im_02 | Sonra hayali arkadaşı {…} fısıldadı: "İyi geceler." |
| fısıltı | 3.16 | 1 | **hayır** | bts3_ra_03 | "Ona biraz özen gerek," dedi {…} fısıltıyla. |
| kırp | 3.16 | 2 | **hayır** | bts3_rs_03, bts3_rv_fi_02 | {…} sevinçle göz kırptı. |
| mışıl | 3.35 | 4 | **hayır** | bt3_rs_03, bt3_wc_ff_01 | Az sonra {…} mışıl mışıl uyuyordu. |
| üşüdüm | 3.35 | 1 | **hayır** | ra3_01 | "Üşüdüm," dedi {…}. |
| ninni | 3.40 | 4 | **hayır** | bt3_pw_02, bt3_tc_04, bt3_td_02 +1 | {…} sessizce bekledi ve ninniyi tekrarladı. |
| halleder | 3.41 | 1 | **hayır** | scm3_04 | "Ben hallederim," dedi {…}. |
| belirdi | 3.43 | 6 | **hayır** | bts3_rv_01, bts3_rv_fs_01, bts3_rv_ff_01 +3 | Pencerede {…} belirdi. |
| ört | 3.49 | 1 | **hayır** | bts3_td_01 | {…} ona yumuşak bir mendil örttü. |
| usulca | 3.55 | 15 | evet | bt3_tc_02, bt3_tc_03, bt3_wc_01 +12 | {…} yataktan usulca kalktı. |
| yumuşacık | 3.55 | 5 | **hayır** | bt3_eo_03, bt3_eo_fi_02, bt3_tc_03 +2 | {…} lamba yumuşacık yanıyordu. |
| omzuna | 3.57 | 1 | **hayır** | bt3_tc_04 | Yorganını omzuna alıp pencereye gitti. |
| yorgan | 3.59 | 19 | evet | bt3_eo_01, bt3_eo_02, bt3_eo_04 +16 | Yorganı sıcacıktı. |
| kıpırda | 3.61 | 1 | **hayır** | rs3_01 | Sonra {…} kıpırdadı. |
| uza | 3.61 | 13 | **hayır** | bt3_eo_02, bt3_eo_ff_02, bt3_eo_fi_01 +10 | {…} {…} yatağına uzandı. |
| şura | 3.65 | 1 | **hayır** | sra3_01 | "Onun yeri şurası," dedi {…}. |
| hoşça | 3.68 | 1 | **hayır** | slg3_04 | "Hoşça kal," dedi {…}. |
| doğrul | 3.69 | 4 | **hayır** | bt3_na_fs_02, bt3_na_ff_02, bts3_na_01 +1 | Kardeşi {…} doğruldu. |
| seslendi | 3.72 | 1 | **hayır** | sr3_fam_im_04 | {…} hayali arkadaşı {…} seslendi: "Hadi gidelim." |
| dökmek | 3.73 | 1 | **hayır** | td3_02 | Yavaşça döktü. |
| pijama | 3.74 | 1 | **hayır** | bts3_rv_ff_03 | {…} arkadaşı {…} ile pijamalarını giydi. |
| lamba | 3.80 | 5 | **hayır** | bt3_eo_03, bt3_eo_ff_02, bt3_td_01 +2 | {…} lamba yumuşacık yanıyordu. |
| bat | 3.85 | 1 | **hayır** | swc3_05 | Güneş battı. |
| sarın | 3.85 | 5 | **hayır** | bt3_eo_04, bt3_wc_fs_01, bts3_wc_fs_01 +2 | {…} yorganına sarındı. |
| kıs | 3.86 | 1 | **hayır** | bt3_td_01 | {…} lambayı kıstı. |
| sıkıca | 3.87 | 1 | **hayır** | wc3_fam_sib_01 | {…} kardeşi {…} sıkıca sarıldı. |
| kısık | 3.89 | 2 | **hayır** | bt3_wc_03, bts3_wc_03 | Işık kısık, yorgan sıcacıktı. |
| sar | 3.90 | 3 | **hayır** | swc3_03, swc3_fam_sib_04, wc3_fam_sib_01 | {…} {…} sarıldı. |
| sıcacık | 3.90 | 8 | evet | bt3_eo_01, bt3_wc_03, bts3_ra_01 +5 | Yorganı sıcacıktı. |
| ısınmak | 3.90 | 1 | **hayır** | rs3_02 | Iyice ısınmıştı. |
| mendil | 3.92 | 1 | **hayır** | bts3_td_01 | {…} ona yumuşak bir mendil örttü. |
| sevin | 3.92 | 5 | **hayır** | bts3_rv_ff_01, sr3_fam_sib_01, sr3_fam_fr_01 +2 | İkisi çok sevindi. |
| ılık | 3.98 | 1 | **hayır** | swc3_01 | Hava ılıktı. |
| bura | 3.99 | 3 | **hayır** | bts3_tc_03, cm3_01, cm3_03 | "Biz buradayız." |
| salla | 3.99 | 7 | **hayır** | bts3_rv_fs_01, bts3_tc_01, sfa3_01 +4 | İkisi el salladı. |
| etraf | 4.01 | 2 | **hayır** | sn3_04, std3_01 | {…} etrafına baktı. |
| gülümse | 4.06 | 24 | **hayır** | bt3_eo_fi_02, bt3_td_03, bts3_rs_02 +21 | {…}, hayali arkadaşı {…} yumuşacık gülümsedi. |
| ayırmak | 4.07 | 3 | **hayır** | stc3_03, cm3_02 | Bugün buradan ayrılmayacaktı. |
| çene | 4.07 | 3 | **hayır** | bt3_eo_02, bt3_wc_02, bts3_wc_02 | Yorganını çenesine çekti. |
| dinlenmek | 4.08 | 3 | **hayır** | swc3_fam_an_02, swc3_fam_an_03, swc3_fam_an_04 | Sonra ikisi de dinlendi. |
| kenar | 4.08 | 2 | **hayır** | bts3_na_01, bts3_na_05 | {…} pencerenin kenarını gösterdi. |
| yastık | 4.09 | 5 | **hayır** | bt3_eo_03, bt3_eo_fa_02, bt3_td_03 +1 | {…} yastığına başını koydu. |
| yavaşça | 4.10 | 12 | evet | bt3_pw_01, bts3_fa_01, bts3_pw_01 +9 | {…} yavaşça saydı: bir, iki, üç. |
| yaklaşmak | 4.14 | 2 | **hayır** | bt3_tc_03, cm3_03 | {…} usulca pencereye yaklaştı. |
| giymek | 4.15 | 1 | **hayır** | bts3_rv_ff_03 | {…} arkadaşı {…} ile pijamalarını giydi. |
| rüzgâr | 4.15 | 2 | **hayır** | std3_02, td3_03 | {…} rüzgâr gelmesin diye önüne oturdu. |
| sok | 4.15 | 3 | **hayır** | bt3_wc_fa_02, bts3_tc_03, bts3_wc_fa_02 | Yanına {…} {…} sokuldu. |
| görmez | 4.16 | 1 | **hayır** | sr3_fam_sib_03 | {…} onları görür görmez gülümsedi. |
| hatırla | 4.20 | 2 | **hayır** | bts3_rv_03, sr3_03 | {…} {…} hatırladı. |
| özen | 4.21 | 1 | **hayır** | bts3_ra_03 | "Ona biraz özen gerek," dedi {…} fısıltıyla. |
| sevinç | 4.22 | 5 | **hayır** | bt3_eo_ff_01, bts3_rs_03, srs3_03 +2 | {…} çok sevinçliydi. |
| öylece | 4.22 | 1 | **hayır** | pw3_02 | Öylece bekledi. |
| kaldırmak | 4.23 | 1 | **hayır** | mc3_04 | Başını kaldırıp {…} baktı. |
| götür | 4.27 | 1 | **hayır** | scm3_01 | "Bunu yerine götürelim," dedi {…}. |
| nöbet | 4.27 | 1 | **hayır** | bts3_wc_fi_01 | Hayali arkadaşı {…} pencerede nöbet tuttu. |
| ağlamak | 4.29 | 1 | **hayır** | ra3_04 | Ağlamadı. |
| dal | 4.29 | 6 | **hayır** | bt3_rs_02, bt3_wc_03, bt3_wc_fi_01 +3 | {…} son bir kez esnedi ve uykuya daldı. |
| sabır | 4.29 | 2 | **hayır** | bts3_pw_02, bts3_tc_02 | {…} pencerenin yanında sabırla, usulca bekledi. |
| kapa | 4.30 | 13 | **hayır** | bt3_rs_01, bt3_wc_01, bt3_wc_04 +10 | Sonunda {…} gözlerini kapadı ve uyudu. |
| otur | 4.31 | 14 | **hayır** | bt3_wc_fi_01, bts3_pw_03, bts3_wc_fi_03 +10 | Hayali arkadaşı {…} pencerenin yanında oturdu. |
| sessizce | 4.32 | 4 | evet | bt3_pw_02, bts3_pw_01, spw3_01 +1 | {…} sessizce bekledi ve ninniyi tekrarladı. |
| uyu | 4.34 | 16 | **hayır** | bt3_mc_01, bt3_mc_02, bt3_mc_03 +12 | Uyuyamıyordu. |
| yürü | 4.34 | 6 | **hayır** | sfa3_01, sfa3_03, sn3_03 +3 | {…} yavaş yavaş yürüdü. |
| pencere | 4.35 | 49 | **hayır** | bt3_eo_01, bt3_eo_04, bt3_eo_fa_02 +46 | Ay pencereden bakıyordu. |
| tanımak | 4.35 | 1 | **hayır** | bts3_rv_04 | Pencereden tanıdık bir yüz baktı. |
| avuç | 4.36 | 2 | **hayır** | bts3_td_03, td3_02 | {…} avuçlarıyla sıcak bir köşe yaptı. |
| bahçe | 4.37 | 1 | **hayır** | na3_01 | {…} o sabah bahçeye çıktı. |
| buluşmak | 4.37 | 3 | **hayır** | sr3_03, sr3_fam_im_03, wc3_fam_fr_01 | {…} yine {…} ile buluştu. |
| öbür | 4.41 | 1 | **hayır** | std3_02 | {…} öbür yanına oturdu. |
| korkmak | 4.42 | 2 | **hayır** | stc3_02, cm3_03 | "Korkma," dedi usulca. |
| say | 4.43 | 4 | **hayır** | bt3_pw_01, sfa3_01, pw3_04 | {…} yavaşça saydı: bir, iki, üç. |
| acele | 4.46 | 6 | **hayır** | bt3_pw_03, bts3_pw_03, sfa3_02 +3 | Birlikte aya baktılar, hiç acele etmeden. |
| ağız | 4.47 | 1 | **hayır** | bts3_fa_02 | {…} gülmemek için ağzını kapattı. |
| burun | 4.47 | 1 | **hayır** | bts3_na_06 | {…} burnuyla pencereyi gösterdi. |
| perde | 4.47 | 3 | **hayır** | bt3_td_04, bts3_na_02, bts3_wc_03 | {…} perdeyi yarıya çekti. |
| uyan | 4.48 | 1 | **hayır** | sr3_fam_sib_04 | {…} bu sabah kardeşi {…} ile uyandı. |
| göğüs | 4.49 | 1 | **hayır** | sfa3_03 | {…} onu göğsüne yakın tuttu. |
| ora | 4.49 | 2 | **hayır** | bts3_lg_03, bts3_ra_02 | Orası tam ona göreydi. |

## 5-6 yaş

594 satır · 125 nadir kök · 112 açıklamasız

| kök | Zipf | geçiş | sözlükte | kaynak | örnek cümle |
|---|---:|---:|---|---|---|
| okşa | 3.02 | 2 | **hayır** | bt_na_fa_02, bts_rv_fa_02 | {…}, yorganın üstündeki {…} {…} okşuyordu. |
| esne | 3.03 | 12 | **hayır** | bt_eo_fs_01, bt_mc_02, bt_na_04 +7 | Kardeşi {…} yan yatakta çoktan esnemeye başlamıştı. |
| esneme | 3.03 | 1 | **hayır** | bt_rs_02 | Bir esneme daha, bir kıpırtı daha, sonra derin bir sessizlik. |
| küçüldü | 3.03 | 1 | **hayır** | pr_s_02 | Hazırlanınca korkusu da küçüldü. |
| kabar | 3.08 | 5 | **hayır** | bt_na_02, bt_na_fa_01, bts_na_05 +2 | {…} kulak kabarttı. |
| kaynaş | 3.09 | 1 | evet | sr_fam_an_02 | Üçü hemen tanışıp kaynaştı. |
| kırgınlık | 3.10 | 1 | **hayır** | rs_views_02 | Artık kimsenin kırgınlığı kalmamıştı, hiç kimsenin. |
| süzülerek | 3.11 | 1 | **hayır** | mc_guide_03 | {…} adlı {…} süzülerek indi. |
| yavaşla | 3.11 | 2 | **hayır** | na_fam_sib_01, pr_s_08 | Sonra {…} adımlarını yavaşlattı. |
| üstlenecek | 3.11 | 1 | **hayır** | tc_s_02 | Bunu üstlenecek bir tek kendisi vardı ve üstlendi. |
| parıltı | 3.12 | 2 | evet | na_light_01 | Gözünün ucuyla bir parıltı yakaladı {…}. |
| havalandı | 3.13 | 1 | **hayır** | bt_td_03 | Yastıktan küçük bir tüy havalandı. |
| sızla | 3.13 | 1 | **hayır** | lg_s_06 | Burnu biraz sızladı ama gülümsedi. |
| övünmek | 3.13 | 1 | **hayır** | rs_any_05 | Bunu yapan {…} olmuştu ama hiç övünmedi. |
| fısılda | 3.15 | 2 | evet | bt_na_fi_02, wc_fam_an_p02 | {…} yorganın altından hayali arkadaşı {…} fısıldıyordu. |
| fısıldadı | 3.15 | 6 | evet | bt_na_fs_01, bts_lg_01, bts_rv_fs_02 +3 | Kardeşi {…} yan yataktan fısıldadı: "Duydun mu?" |
| tuhaflık | 3.15 | 1 | **hayır** | na_fam_an_02 | Burada bir tuhaflık vardı. |
| fısıltı | 3.16 | 5 | **hayır** | bt_pw_01, bts_ra_01, spw_04 +2 | Sonra {…} yıldızları fısıltıyla saymaya başladı: bir, iki, üç. |
| kırp | 3.16 | 5 | **hayır** | bt_eo_fi_02, bts_rs_04, bts_rv_05 +2 | {…} yorganına sarınırken hayali arkadaşı {…} göz kırptı. |
| koklamak | 3.24 | 1 | **hayır** | bts_ex_02 | {…} burnunu yaklaştırıp kokladı ve memnun memnun başını salladı. |
| gülümser | 3.27 | 2 | **hayır** | bt_eo_04, bt_eo_fi_02 | Ay, pencereden içeri gülümser gibi bakıyordu. |
| çoğaldı | 3.28 | 1 | **hayır** | ex_s_any_01 | Sorusu daha da çoğaldı. |
| sıva | 3.29 | 1 | **hayır** | cm_p_10 | {…} kollarını sıvadı ve yerinden doğruldu. |
| sarın | 3.30 | 8 | **hayır** | bt_eo_fi_02, bts_rv_fi_01, bts_wc_04 +5 | {…} yorganına sarınırken hayali arkadaşı {…} göz kırptı. |
| bilmece | 3.31 | 1 | **hayır** | ex_s_any_02 | {…} hâlâ bir bilmeceydi. |
| gülüş | 3.31 | 1 | **hayır** | ev_s_08 | İkisi birden söyleyince gülüştüler. |
| mışıl | 3.35 | 4 | **hayır** | swc_03, swc_fam_sib_03 | Mışıl mışıl uyudu. |
| canlandırdı | 3.36 | 1 | evet | pr_s_02 | Önce durdu, baktı, nasıl olacağını kafasında canlandırdı. |
| anlaşılma | 3.39 | 1 | **hayır** | rs_views_02 | Yanlış anlaşılma bitince iş kolaydı. |
| süzülen | 3.39 | 2 | **hayır** | bt_eo_fa_02, bt_wc_02 | {…} sessizdi; pencereden süzülen ay ışığı ikisinin üstüne düşüyordu. |
| gömmek | 3.40 | 1 | **hayır** | bt_rs_01 | Sonunda {…} başını göğsüne gömdü ve uykuya daldı. |
| ninni | 3.40 | 4 | **hayır** | bt_pw_03, bts_td_02, bt_tc_02 +1 | Bildiği en yavaş ninniyi bir kez daha mırıldandı. |
| halleder | 3.41 | 1 | **hayır** | tc_s_03 | "Ben hallederim." |
| nazikçe | 3.41 | 1 | **hayır** | scm_01 | {…} onu nazikçe tuttu. |
| titre | 3.41 | 5 | **hayır** | ah_s_05, cm_p_07, mc_care_03 +2 | Sesi biraz titredi ama sorusunu sonuna kadar sordu, yarıda bırakmadı. |
| sapasağlam | 3.42 | 1 | evet | ss_s_06 | Ellerine baktı, ikisi de sapasağlamdı. |
| belirdi | 3.43 | 5 | **hayır** | bts_rv_01, bts_rv_fs_01, bts_rv_ff_02 +2 | O sırada pencerenin önünde tanıdık bir yüz belirdi. |
| toparlamak | 3.43 | 1 | **hayır** | srs_03 | Az sonra küçük şey kendini toparladı. |
| yanıl | 3.43 | 10 | evet | bf_p_03, ev_s_04, rv_s_01 +2 | {…} yanılmıştı ama bunda utanılacak bir şey yoktu, herkes yanılabilirdi. |
| birleşince | 3.45 | 1 | **hayır** | ce_s_07 | İki fikir birleşince iş tamam oldu. |
| yum | 3.45 | 1 | **hayır** | cm_p_05 | {…} avuçlarını sıkıca yumdu. |
| ayıracakla | 3.47 | 1 | **hayır** | stc_01 | Bugün bütün günü buna ayıracaklardı. |
| sön | 3.47 | 2 | **hayır** | swc_fam_im_04, ex_s_light_01 | {…} ışığı söndürmeden önce hayali arkadaşı {…} iyi geceler diledi. |
| sakince | 3.49 | 1 | **hayır** | mc_calm_05 | Sonra {…} yanına geçti ve sakince oturdu. |
| ört | 3.49 | 4 | **hayır** | bt_rs_04, bts_td_01, bts_wc_04 +1 | {…} perdeyi yarıya kadar usulca örttü. |
| doymak | 3.51 | 1 | **hayır** | bt_rs_03 | Küçük yüzü öyle rahattı ki {…} bakmaya doyamadı. |
| sıkıldı | 3.52 | 1 | **hayır** | ps_s_04 | Sıkıldı ama durmadı. |
| tıkır | 3.53 | 1 | **hayır** | na_sound_02 | Sonra {…} bir tıkırtı duydu. |
| sofra | 3.54 | 2 | **hayır** | swc_fam_sib_01, wc_fam_sib_p01 | Akşam {…} kardeşi {…} ile sofraya oturdu. |
| süz | 3.54 | 1 | **hayır** | bt_eo_fs_02 | Pencereden odaya tatlı bir ay ışığı süzülüyordu. |
| şura | 3.54 | 1 | **hayır** | ce_s_02 | "Sen şuradan, ben buradan," dedi {…}. |
| usulca | 3.55 | 32 | evet | bt_mc_01, bt_rs_01, bt_rs_04 +29 | "Uykum var ama uyuyamıyorum," dedi usulca. |
| yumuşacık | 3.55 | 11 | evet | bt_eo_01, bt_eo_fs_01, bt_eo_ff_02 +8 | Lamba yumuşacık yanıyordu. |
| birleşti | 3.56 | 1 | **hayır** | in_s_01 | Birden {…} kafasında iki şey birleşti. |
| omzuna | 3.57 | 2 | **hayır** | bt_pw_04, bts_pw_01 | {…} yorganını omzuna aldı ve pencerenin yanına oturdu. |
| ezbere | 3.59 | 2 | **hayır** | sr_02, mc_guide_06 | {…} yolu artık ezbere biliyordu. |
| sabret | 3.59 | 2 | evet | sc_wait_02 | Sabretmek kolay değildi ama {…} sabretti. |
| yorgan | 3.59 | 41 | **hayır** | bt_eo_01, bt_eo_02, bt_eo_03 +38 | {…} {…} yorganını çenesine kadar çekti. |
| şaşırdı | 3.59 | 10 | **hayır** | ce_s_02, ex_s_light_01, fc_s_04 +6 | Böyle bölüşünce iş birden kolaylaştı, ikisi de şaşırdı. |
| anlaşmak | 3.61 | 1 | **hayır** | ev_s_03 | Konuşmadan anlaşmak mümkün değilmiş. |
| kıpır | 3.61 | 4 | **hayır** | bt_rs_02, mc_care_01, wc_p_succeed_05 | Bir esneme daha, bir kıpırtı daha, sonra derin bir sessizlik. |
| kıpırda | 3.61 | 2 | **hayır** | bts_pw_02, ce_s_06 | Perde hafifçe kıpırdadı, bulutlar yavaşça geçti. |
| uza | 3.61 | 23 | **hayır** | bt_eo_04, bt_eo_ff_02, bt_eo_fi_01 +19 | {…} o akşam {…} yatağına erkenden uzandı. |
| utan | 3.62 | 4 | **hayır** | ah_s_03, bf_p_03, ra_p_07 +1 | Bu utanılacak bir şey değildi, kimse öyle demezdi. |
| saklambaç | 3.64 | 1 | **hayır** | na_fam_fr_01 | {…} ile arkadaşı {…} {…} saklambaç oynuyordu. |
| şaşır | 3.65 | 1 | **hayır** | mc_calm_03 | {…} görünce hiç şaşırmadı. |
| geceki | 3.66 | 1 | **hayır** | bts_rv_fi_03 | Pencerenin önünde {…} yine oradaydı, tıpkı o ilk geceki gibi. |
| yor | 3.66 | 5 | **hayır** | fa_s_04, ps_s_02, sc_any_05 +2 | Kolları yoruldu, nefesi kesildi. |
| uyur | 3.67 | 1 | **hayır** | bts_ra_03 | "Sonra rahat rahat uyur." |
| hoşça | 3.68 | 2 | **hayır** | slg_04, lg_s_08 | {…} onu yerine bıraktı ve "Hoşça kal," diye fısıldadı. |
| aksa | 3.69 | 1 | **hayır** | td_s_06 | Büyük bir şey yapmadı ama hiçbirini aksatmadı. |
| doğrul | 3.69 | 6 | **hayır** | bt_na_04, bts_na_02, bts_rv_ff_02 +3 | Ne olduğunu görmek için yatakta doğruldu ve perdeyi biraz araladı. |
| kızar | 3.69 | 1 | **hayır** | wc_p_succeed_03 | {…} bir şey demedi, sadece kulakları kızardı. |
| ıslık | 3.69 | 2 | **hayır** | na_neutral_02 | {…} ıslık çala çala yürüyordu. |
| seslendi | 3.72 | 1 | **hayır** | mc_care_04 | Yanına çömeldi ve usulca seslendi. |
| çat | 3.73 | 2 | **hayır** | in_s_06, lg_s_03 | {…} kaşlarını çattı, sonra gözleri kocaman açıldı. |
| minicik | 3.74 | 5 | **hayır** | bt_na_01, bt_na_fs_02, bt_rs_01 +2 | Ses yine geldi: minicik, yumuşacık, biraz da üzgün. |
| pijama | 3.74 | 2 | **hayır** | bt_eo_ff_01, bts_rv_ff_03 | İkisi de pijamalarını giymiş, yorganlarının altına girmişti. |
| sıkıl | 3.74 | 1 | **hayır** | pw_s_01 | Acele etmedi, sıkılmadı, kalkıp gitmedi. |
| telaş | 3.74 | 1 | **hayır** | mc_calm_05 | Hiç telaşlı değildi. |
| aydınlan | 3.75 | 1 | **hayır** | rv_s_08 | Gerçek ortaya çıkınca {…} yüzü aydınlandı. |
| alışkın | 3.77 | 1 | **hayır** | mc_calm_06 | {…} buraya alışkındı. |
| belir | 3.78 | 2 | **hayır** | bts_rv_fs_03, bts_rv_fa_03 | Sonra ikisi de sustu, çünkü pencerenin önünde {…} belirmişti. |
| dosdoğru | 3.80 | 1 | **hayır** | ah_s_08 | {…} bunu saklamadı, dosdoğru söyledi ve yardım istedi. |
| lamba | 3.80 | 11 | **hayır** | bt_eo_01, bt_eo_fs_01, bt_eo_ff_02 +8 | Lamba yumuşacık yanıyordu. |
| bölmek | 3.81 | 1 | **hayır** | ce_s_02 | Böyle bölüşünce iş birden kolaylaştı, ikisi de şaşırdı. |
| epeyce | 3.81 | 3 | **hayır** | ob_wait_01, sr_p_03, sc_any_05 | Beklemek gerekiyordu, hem de epeyce. |
| ilgilenmek | 3.81 | 1 | **hayır** | td_s_05 | {…} sabahtan akşama kadar ilgilendi. |
| gülme | 3.82 | 1 | **hayır** | rv_s_03 | Gülmesi uzun sürdü, iyi bir gülmeydi. |
| yerleşti | 3.82 | 2 | **hayır** | bt_td_03, stc_02 | {…} yastığa yerleşti ve hapşırdı: hapşu! |
| üstlendi | 3.82 | 3 | **hayır** | tc_s_02, tc_p_01, tc_p_03 | Bunu üstlenecek bir tek kendisi vardı ve üstlendi. |
| korkutucu | 3.83 | 1 | **hayır** | rv_s_02 | Bambaşka bir şeydi ve hiç de korkutucu değildi. |
| ooo | 3.83 | 1 | **hayır** | rv_s_02 | "Ooo," dedi {…} usulca. |
| akıllıca | 3.84 | 1 | **hayır** | rv_s_07 | {…} yanılmıştı ama akıllıca yanılmıştı. |
| bat | 3.85 | 1 | **hayır** | swc_04 | Güneş batarken ikisi de evine döndü. |
| onaylamak | 3.85 | 1 | **hayır** | std_04 | {…} onaylarcasına göz kırptı. |
| sar | 3.85 | 3 | **hayır** | swc_04, swc_fam_fr_01, swc_fam_sib_04 | {…} {…} sarılıp teşekkür etti. |
| kıs | 3.86 | 4 | **hayır** | bts_wc_04, bt_tc_02, bt_td_01 +1 | Lamba kısıldı, perde yarıya kadar örtüldü. |
| battaniye | 3.87 | 1 | **hayır** | wc_fam_sib_s01 | {…} ile kardeşi {…} aynı battaniyenin altına girdi. |
| onuncu | 3.87 | 1 | **hayır** | ps_s_05 | Onuncuda haklı çıktı ve buldu. |
| sıkıca | 3.87 | 4 | **hayır** | swc_fam_sib_04, cf_p_05, cm_p_05 +1 | Eve dönünce {…}, kardeşi {…} sıkıca sarıldı. |
| uzaklaşmak | 3.87 | 2 | **hayır** | lg_s_02, rs_ready_01 | Uzaklaşana kadar da gözünü ayırmadı. |
| kapa | 3.89 | 4 | **hayır** | bt_mc_02, bt_na_01, bts_na_01 +1 | Esniyor, esniyor ama gözlerini bir türlü kapatamıyordu. |
| kısık | 3.89 | 2 | **hayır** | bts_wc_ff_02, bt_wc_04 | {…} lamba kısıktı, yorgan sıcacıktı. |
| parla | 3.90 | 4 | **hayır** | bts_ex_01, bts_rv_fa_02, swc_fam_sib_01 +1 | Ay ışığı üstüne düşmüş, onu gümüş gibi parlatıyordu. |
| saklamak | 3.90 | 3 | **hayır** | ah_s_08, gs_s_07, mc_care_06 | {…} bunu saklamadı, dosdoğru söyledi ve yardım istedi. |
| siper | 3.90 | 1 | evet | na_light_03 | {…} elini gözlerine siper etti. |
| sıcacık | 3.90 | 15 | **hayır** | bt_eo_02, bt_eo_fa_01, bt_rs_01 +12 | Yastığı serin, yorganı sıcacıktı. |
| ısınmak | 3.90 | 2 | **hayır** | bts_rs_04, srs_03 | {…} bunu görünce içi ısındı. |
| mendil | 3.92 | 2 | **hayır** | bts_td_01, std_04 | {…} yastığının yanından yumuşak bir mendil aldı ve üstünü örttü. |
| peş | 3.92 | 1 | **hayır** | cm_p_01 | Ne olursa olsun bunun peşini bırakmayacaktı. |
| sevin | 3.92 | 8 | **hayır** | sr_fam_sib_01, sr_fam_sib_02, sr_fam_an_03 +5 | {…} ikisini görünce sevindi. |
| açıklık | 3.93 | 1 | **hayır** | rv_s_01 | Yaklaşınca her şey açıklığa kavuştu. |
| hafifçe | 3.93 | 2 | **hayır** | bts_pw_02, mc_care_03 | Perde hafifçe kıpırdadı, bulutlar yavaşça geçti. |
| vazgeç | 3.93 | 9 | evet | cm_s_03, fa_p_04, mc_hesitant_p05 +5 | Vazgeçmek için bin tane sebep vardı. |
| çök | 3.94 | 3 | **hayır** | bts_ap_03, bt_tc_04, ex_s_trace_01 | {…} pencerenin önüne usulca diz çöktü. |
| apaçık | 3.95 | 2 | evet | na_neutral_03, sc_retrace_02 | {…} tam oradaydı, apaçık. |
| atla | 3.95 | 1 | **hayır** | sf_s_02 | Baştan sona, hiçbir şeyi atlamadan, hiçbir şeyi büyütmeden. |
| dip | 3.97 | 1 | **hayır** | bt_na_03 | Sonra pencerenin dibinden {…} yükseldi, bir kere, iki kere. |
| düzeltme | 3.97 | 1 | **hayır** | ev_s_03 | Ama o birkaç cümle aradaki her şeyi düzeltmeye yetti. |
| düzeltmek | 3.97 | 1 | **hayır** | bts_lg_03 | Üstünü düzeltti, sonra yavaşça geri çekildi. |
| seyret | 3.97 | 1 | **hayır** | sc_any_02 | Uzun uzun seyretti. |
| davranmak | 3.98 | 1 | **hayır** | td_s_03 | Kırılacak bir şey tutuyormuş gibi davrandı, çünkü gerçekten öyleydi. |
| bura | 3.99 | 3 | **hayır** | bts_tc_03, mc_guide_01, wc_p_succeed_03 | "Biz buradayız." |
| salla | 3.99 | 25 | **hayır** | bts_ex_02, bts_lg_03, bts_na_02 +22 | {…} burnunu yaklaştırıp kokladı ve memnun memnun başını salladı. |

## Bantsız satırlar (4.5 eşiğiyle)

225 satır · 54 nadir kök · 45 açıklamasız

| kök | Zipf | geçiş | sözlükte | kaynak | örnek cümle |
|---|---:|---:|---|---|---|
| zıplayarak | 3.01 | 1 | **hayır** | c_r_1_v3 | Minik {…} {…} zıplayarak yanına geldi. |
| beceremiyorum | 3.20 | 1 | **hayır** | pilot_t_receive_appeal_v1 | "Tek başıma beceremiyorum." |
| bilmece | 3.31 | 1 | **hayır** | pilot_t_insight_v2 | {…} bir bilmece değildi; sadece eksik bir yarısı vardı. |
| yöneltti | 3.36 | 4 | **hayır** | template_hook_1_v1, template_hook_3_v1, template_hook_3_v2 +1 | Büyük bir merakla yola çıkan {…}, adımlarını {…} doğru yöneltti. |
| zifiri | 3.36 | 1 | **hayır** | p_r_1_v2 | Yolun sonu zifiri karanlıktı. |
| belirdi | 3.43 | 10 | **hayır** | template_discovery_0_v2, template_discovery_1_v0, template_discovery_1_v2 +7 | Ağaçların arasından sevimli bir şekilde {…} belirdi. |
| yanıl | 3.43 | 1 | evet | pilot_t_belief_fails_v2 | Yaklaşınca anladı ki yanılmıştı. |
| şaşkınlık | 3.54 | 1 | **hayır** | pilot_t_belief_fails_v3 | "Olmuyor," dedi {…} şaşkınlıkla. |
| usulca | 3.55 | 2 | evet | pilot_t_hesitate_v3, pilot_t_receive_appeal_v2 | "Biraz duraksadım," dedi {…} usulca. |
| birleşti | 3.56 | 1 | **hayır** | pilot_t_form_belief_v3 | Kafasında her şey birleşti. |
| kıpır | 3.61 | 1 | **hayır** | pilot_t_meet_companion_v1 | Tam o sırada yakınında bir kıpırtı oldu. |
| yor | 3.66 | 1 | **hayır** | pilot_t_persist_v2 | Yorulmuştu ama durmadı. |
| dahaki | 3.74 | 1 | **hayır** | pilot_t_carry_forward_v2 | Bir dahaki sefere ne yapacağını artık biliyordu. |
| keşfetmek | 3.76 | 1 | **hayır** | h_r_1_v2 | Yeni yerler keşfetmeyi seven {…}, adımlarını hızlandırıp {…} doğru yürüdü. |
| belir | 3.78 | 1 | **hayır** | pilot_t_form_belief_v1 | Aklında bir fikir belirmişti. |
| kıs | 3.86 | 1 | **hayır** | pilot_t_insight_v3 | {…} gözlerini kıstı ve anladı. |
| saklamak | 3.90 | 1 | **hayır** | pilot_t_hesitate_v2 | İçinde küçük bir çekingenlik vardı ve bunu saklamadı. |
| ferahla | 3.92 | 1 | **hayır** | pilot_t_reveal_truth_v3 | {…} anladığında içi ferahladı. |
| dolaşmak | 3.93 | 10 | **hayır** | h_r_1_v1, template_hook_2_v0, template_hook_4_v1 +7 | Güneşli bir sabah, {…} dışarıda dolaşırken kendini {…} girişinde buldu. |
| karşılaştı | 3.93 | 13 | **hayır** | template_discovery_0_v0, template_discovery_0_v1, template_discovery_2_v2 +10 | Etrafı incelerken bir ses duydu ve arkasını döndüğünde {…} ile karşılaştı. |
| vazgeç | 3.93 | 1 | evet | pilot_t_persist_v1 | Vazgeçmedi. |
| etraf | 3.94 | 8 | **hayır** | h_r_1_v2, template_discovery_0_v0, template_discovery_0_v1 +5 | Etrafta tatlı bir sessizlik vardı. |
| eğlenmek | 3.94 | 90 | **hayır** | template_companion_0_v0, template_companion_0_v1, template_companion_0_v2 +87 | {…} ve {…} birlikte çok eğlendi. |
| apaçık | 3.95 | 1 | evet | pilot_t_reveal_truth_v3 | Meğer her şey apaçıkmış. |
| salla | 3.99 | 1 | **hayır** | pilot_t_companion_offers_v3 | {…} başını salladı. |
| meğer | 4.02 | 1 | **hayır** | pilot_t_reveal_truth_v3 | Meğer her şey apaçıkmış. |
| durakla | 4.04 | 2 | **hayır** | p_r_1_v2, pilot_t_self_recognize_v2 | {…} korkuyla durakladı ve ilerlemek istemedi. |
| gülümse | 4.06 | 1 | **hayır** | pilot_t_succeed_v3 | {…} {…} yanına vardı ve gülümsedi. |
| azal | 4.08 | 1 | **hayır** | pilot_t_obstacle_raises_v1 | Aradaki mesafe hiç azalmıyordu. |
| kaybolmak | 4.08 | 1 | **hayır** | pilot_t_approach_v3 | {…} hâlâ oradaydı, kaybolmamıştı. |
| üzüntü | 4.08 | 1 | **hayır** | p_r_1_v3 | "Önümüzü göremiyoruz," dedi {…} üzüntüyle. |
| neşe | 4.10 | 14 | **hayır** | template_hook_1_v0, template_hook_1_v2, template_hook_2_v1 +11 | {…} her zamanki gibi neşeyle oynarken, gözüne {…} ilişti. |
| yavaşça | 4.10 | 5 | evet | pilot_t_approach_v2, pilot_t_small_step_v2, pilot_t_find_own_courage_v2 +2 | {…} yavaşça {…} doğru yürüdü ve {…} daha yakından fark etti. |
| yaklaşmak | 4.14 | 7 | **hayır** | pilot_t_approach_v1, pilot_t_approach_v3, pilot_t_examine_v3 +3 | {…} bir adım yaklaştı, sonra bir adım daha. |
| sevinç | 4.22 | 9 | **hayır** | template_resolution_0_v1, template_resolution_1_v0, template_resolution_1_v1 +6 | Birlikte başarmış olmanın verdiği sevinçle, {…} neşeyle güldüler. |
| sessizlik | 4.28 | 1 | evet | h_r_1_v2 | Etrafta tatlı bir sessizlik vardı. |
| kapla | 4.29 | 1 | **hayır** | p_r_1_v3 | Karanlık her yeri kaplamıştı. |
| sabır | 4.29 | 1 | evet | pilot_t_persist_v2 | Aynı şeyi sabırla yeniden yaptı. |
| sessizce | 4.32 | 2 | evet | pilot_t_approach_v3, pilot_t_warm_close_v3 | Ayaklarını sessizce oynatarak yaklaştı {…}. |
| sade | 4.33 | 1 | **hayır** | pilot_t_reveal_truth_v2 | {…} çok daha sade bir şeydi. |
| sandık | 4.33 | 2 | **hayır** | pilot_t_examine_v1, pilot_t_belief_fails_v2 | {…} sandığından daha tuhaftı. |
| bura | 4.34 | 2 | **hayır** | pilot_t_companion_offers_v1, pilot_t_companion_offers_v3 | "Ben burayı bilirim," dedi {…} yumuşak bir sesle. |
| epey | 4.34 | 1 | **hayır** | pilot_t_first_attempt_v3 | İlk denemesinde {…} epey yol aldı. |
| yürü | 4.34 | 4 | **hayır** | h_r_1_v2, pilot_t_approach_v2, pilot_t_warm_close_v1 +1 | Yeni yerler keşfetmeyi seven {…}, adımlarını hızlandırıp {…} doğru yürüdü. |
| ilerlemek | 4.36 | 4 | **hayır** | p_r_1_v2, pilot_t_hesitate_v2, pilot_t_small_step_v2 +1 | {…} korkuyla durakladı ve ilerlemek istemedi. |
| macera | 4.40 | 3 | **hayır** | template_resolution_2_v1, template_resolution_3_v2, template_resolution_4_v2 | Bu unutulmaz macera, ikisi için de harika bir anı olarak kaldı. |
| öbür | 4.41 | 1 | **hayır** | pilot_t_cooperative_effort_v1 | {…} bir yanını tuttu, {…} öbür yanını. |
| korkmak | 4.42 | 3 | **hayır** | pilot_t_companion_offers_v2, pilot_t_find_own_courage_v1, pilot_t_reveal_truth_v1 | "Korkacak bir şey yok," dedi {…}. |
| zorlu | 4.42 | 4 | **hayır** | template_challenge_0_v0, template_challenge_1_v0, template_challenge_1_v1 +1 | Birden karşılarına geçmeleri gereken zorlu bir yol çıktı. |
| otur | 4.43 | 1 | **hayır** | c_r_1_v2 | Bir taşın üzerinde oturan {…} ile karşılaştılar. |
| belirgin | 4.44 | 1 | **hayır** | pilot_t_approach_v1 | Yaklaştıkça {…} daha da belirginleşti. |
| ihtimal | 4.44 | 1 | evet | pilot_t_form_belief_v2 | {…} bir ihtimal düşündü. |
| perde | 4.47 | 1 | **hayır** | pilot_t_reveal_truth_v2 | Perde aralanınca {…} rahatladı. |
| incelemek | 4.48 | 1 | **hayır** | h_r_1_v3 | Kuşların şarkı söylediği o gün, {…} heyecanla {…} incelemeye karar verdi. |

## Gereksiz açıklama

Sözlükte olup o bant için çok yaygın olanlar (Zipf ≥ bant eşiği + 1).

Yok.

## Bant dışı açıklama

Satır bir sözlük girdisini açıklıyor ama girdinin `bands` alanında bu bant yok.

Yok.
