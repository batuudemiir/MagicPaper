# Onay metni taslağı: Kendi sesin (FAZ 18)

Durum: **taslak, hukuk bekliyor.** Uygulamadaki genel metin (`ParentConsentText`, sürüm `2026-10-07`)
değişmedi.

**8 Ekim güncellemesi (faz-18):** Seçenek B uygulandı, ama genel onayı yeniden sormak yerine **ayrı bir
ses kaydı rızası** ile: kaydeden her yetişkin ilk kaydından önce `VoiceConsent.text`'i okuyup onaylar
(`families/{fid}/voiceConsents/{uid}`, sürüm `voice-2026-10`). Kayıtlar cihazda ve ailenin Storage
klasöründe; sesli paylaşım bağlantısıyla süreli olarak açılabilir. Mikrofon izni metni de buna göre
güncellendi (Info.plist). Ayrıntı: `docs/FAMILY_FEATURES.md`. Aşağıdaki seçenekler kayıt için duruyor.

## Ne değişir

Bu metin uygulanınca sürüm yükselir (ör. `2026-10-xx`) ve her ebeveyn bir kez yeniden onaylar
(`AppGate.consent`). Hesap iki kaydı da tutar.

### "Saklanmayanlar" bölümünden çıkacak cümle

> Ses kaydı yapılmaz.

### Yeni bölüm: "Ses kayıtları"

**Seçenek A, kayıtlar yalnızca cihazda (bugünkü kod):**

> Kendi sesin özelliğini kullanırsan masal sayfalarını okuyan kendi sesin bu cihazda saklanır.
> Kayıt hiçbir yere gönderilmez, cihaz yedeğine de girmez. Çocuğunun sesi kaydedilmez. Kaydı,
> masalı ya da bütün verileri Ayarlar > Gizlilik ve veri'den istediğin an silebilirsin.

**Seçenek B, kayıtlar hesapta (FAZ 18 planı, Firebase Storage):**

> Kendi sesin özelliğini kullanırsan masal sayfalarını okuyan kendi sesin, ailenin diğer
> cihazlarında da çalsın diye hesabında saklanır ve yalnızca bu hesaptan açılabilir. Çocuğunun
> sesi kaydedilmez. Kayıtlar Google Firebase sunucularında, yurt dışında olabilir; bu onay
> aktarımı da kapsar. Hesabı silince kayıtlar da kalıcı olarak silinir.

### Mikrofon izni metni (iOS, uygulandı)

> Masalı kendi sesinle okuyup kaydetmek için. Kayıt yalnızca bu cihazda kalır.

Seçenek B seçilirse bu metin de değişmeli.

## Açık sorular (hukuk)

1. Ebeveynin kendi sesi "kişisel veri" olarak açık rızada ayrıca anılmalı mı, yoksa genel onay yeter mi?
2. Seçenek B'de yurt dışı aktarım cümlesi bugünkü "Nerede" bölümüyle birleşebilir mi?
3. Kids kategorisinde mikrofon izni için ek açıklama gerekiyor mu (App Review 1.3, 5.1.4)?
