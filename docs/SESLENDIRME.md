# Kitap oluşturma akışı: seslendirme transkripti

> Kaynak: `MagicPaper/Screens/StoryCreation/LittleCreationCopy.swift` (`allLines`). Bir cümle değişirse ikisi birlikte değişir; `LittleFriendFirstTests` karşılaştırır.

Okul öncesi "önce arkadaş" akışında sesle okunan her cümle. Yeni akış tek sayfa: **Kim gelsin? → {Arkadaş} ile ne yapalım? → Kitap oluştur**; seçim yapılınca sıradaki soru altta açılır ve sayfa oraya kayar. Konu adımı ("Nereye gidelim?" / "Neyi öğrenelim?") bu yoldan kalktığı için onun cümleleri ve "Hazırsan Başla'ya dokun." artık yok.

**Toplam 29 dosya.** ⚠️ işaretli 5 satır (arkadaş tanıtımları) henüz onaylı değil; sıra da (Kestane, Böğürtlen, Tarçın, Yıldız, Simit) onay bekliyor. Onaylarsan aynen kaydet; değiştirirsen yeni cümleyi bana yaz, koddaki metni de aynı yapayım.

## Dosyalar nasıl verilecek

- Dosya adı = tablodaki **Dosya adı** sütunu + `.m4a` (ya da `.mp3`). Örnek: `ses_olustur_kim_gelsin.m4a`.
- Klasör: repoda `MagicPaper/DesignSystem/Sounds/Voice/`. Dosyaları oraya bırakmak yeterli; Xcode klasörü kendisi pakete alıyor, kod değişmiyor.
- Bir dosya yoksa o cümle bugünkü cihaz sesiyle (yedek) okunur, akış bozulmaz. Yani tek tek de ekleyebilirsin.
- Öneri: mono, 44.1 kHz, cümle başı ve sonunda en fazla 0.2 sn sessizlik, ses seviyesi bütün dosyalarda eşit (ElevenLabs'ta aynı ses + aynı ayar).
- Ses kişileri: Ragi tek ses (soruları ve son cümleyi o söyler). Beş arkadaşın her biri kendi sesi; yalnızca kendi tanıtım cümlesini söyler.

## Ragi'nin soruları

| # | Dosya adı | Kim söyler | Cümle | Ne zaman |
|---|---|---|---|---|
| 1 | `ses_olustur_kim_gelsin` | Ragi | Kim gelsin? | sayfa açılınca |
| 2 | `ses_olustur_ne_yapalim` | Ragi | Ne yapalım? | 2. bölüm, Sürpriz seçildiyse |
| 3 | `ses_olustur_ne_yapalim_kestane` | Ragi | Kestane ile ne yapalım? | 2. bölüm |
| 4 | `ses_olustur_ne_yapalim_bogurtlen` | Ragi | Böğürtlen ile ne yapalım? | 2. bölüm |
| 5 | `ses_olustur_ne_yapalim_tarcin` | Ragi | Tarçın ile ne yapalım? | 2. bölüm |
| 6 | `ses_olustur_ne_yapalim_yildiz` | Ragi | Yıldız ile ne yapalım? | 2. bölüm |
| 7 | `ses_olustur_ne_yapalim_simit` | Ragi | Simit ile ne yapalım? | 2. bölüm |

## Arkadaş tanıtımları (karoya dokununca)

| # | Dosya adı | Kim söyler | Cümle | Durum |
|---|---|---|---|---|
| 8 | `ses_olustur_tanitim_kestane` | Kestane (kirpi) | Ben Kestane! Küçük adımlarla cesaret ederim. | ⚠️ onay bekliyor |
| 9 | `ses_olustur_tanitim_bogurtlen` | Böğürtlen (ayı) | Ben Böğürtlen! Büyüğüm ama seni hep dinlerim. | ⚠️ onay bekliyor |
| 10 | `ses_olustur_tanitim_tarcin` | Tarçın (tilki) | Ben Tarçın! Acele etmem, seni beklerim. | ⚠️ onay bekliyor |
| 11 | `ses_olustur_tanitim_yildiz` | Yıldız (baykuş) | Ben Yıldız! Az konuşur, dikkatle bakarım. | ⚠️ onay bekliyor |
| 12 | `ses_olustur_tanitim_simit` | Simit (kedi) | Ben Simit! Şehirden geldim, her şeyi merak ederim. | ⚠️ onay bekliyor |
| 13 | `ses_olustur_tanitim_surpriz` | Ragi | Sürpriz! Kim gelecek, birlikte göreceğiz. | |

## Son bölüm (Kitap oluştur düğmesinin üstündeki cümle)

| # | Dosya adı | Kim söyler | Cümle |
|---|---|---|---|
| 14 | `ses_olustur_basla_kestane_uyku` | Ragi | Kestane ile uyku masalı geliyor! |
| 15 | `ses_olustur_basla_kestane_macera` | Ragi | Kestane ile maceraya çıkıyoruz! |
| 16 | `ses_olustur_basla_kestane_ogrenme` | Ragi | Kestane ile yeni şeyler öğreniyoruz! |
| 17 | `ses_olustur_basla_bogurtlen_uyku` | Ragi | Böğürtlen ile uyku masalı geliyor! |
| 18 | `ses_olustur_basla_bogurtlen_macera` | Ragi | Böğürtlen ile maceraya çıkıyoruz! |
| 19 | `ses_olustur_basla_bogurtlen_ogrenme` | Ragi | Böğürtlen ile yeni şeyler öğreniyoruz! |
| 20 | `ses_olustur_basla_tarcin_uyku` | Ragi | Tarçın ile uyku masalı geliyor! |
| 21 | `ses_olustur_basla_tarcin_macera` | Ragi | Tarçın ile maceraya çıkıyoruz! |
| 22 | `ses_olustur_basla_tarcin_ogrenme` | Ragi | Tarçın ile yeni şeyler öğreniyoruz! |
| 23 | `ses_olustur_basla_yildiz_uyku` | Ragi | Yıldız ile uyku masalı geliyor! |
| 24 | `ses_olustur_basla_yildiz_macera` | Ragi | Yıldız ile maceraya çıkıyoruz! |
| 25 | `ses_olustur_basla_yildiz_ogrenme` | Ragi | Yıldız ile yeni şeyler öğreniyoruz! |
| 26 | `ses_olustur_basla_simit_uyku` | Ragi | Simit ile uyku masalı geliyor! |
| 27 | `ses_olustur_basla_simit_macera` | Ragi | Simit ile maceraya çıkıyoruz! |
| 28 | `ses_olustur_basla_simit_ogrenme` | Ragi | Simit ile yeni şeyler öğreniyoruz! |
| 29 | `ses_olustur_basla_surpriz` | Ragi | Sürpriz bir arkadaş gelecek! |

Kayıt durumu (27 Kasım 2026): Ragi'nin 24 satırı (1-7, 13, 14-29) ElevenLabs "Çağlayan" sesiyle tek kayıttan kesildi ve klasörde. Beş arkadaş tanıtımı (8-12) kayıt bekliyor; o satırlar şimdilik cihaz sesiyle okunur.

Not: Bir arkadaş her modda yazamayabilir (o mod kartı ekranda çıkmaz); dosyanın fazla olması sorun değil.
