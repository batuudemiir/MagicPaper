# Claude Code promptları — Faz 9 ve sonrası

Kullanım: her faz **yeni bir oturumda**. Oturumu `MagicPaperAPP/` klasöründe aç (CLAUDE.md ve
`.claude/agents/` orada). Plan modunda başlat (Shift+Tab ile). Planı okuyup onayla, sonra uygulasın.
Faz bitince oturumu kapat; sonraki faz temiz bağlamla başlar. Faz 10-13 sırayla; Faz 15 Faz 9'dan
sonra ayrı bir oturumda paralel yürüyebilir.

Başlamadan önce bir kez: `MagicPaper/` reposunu GitHub'a push'la (yerel kod 50 commit ileride).

---

## Ortak prompt (her faz için, N'yi değiştir)

```
MagicPaper/docs/MagicPaper_Faz_Plani_Ekim.md belgesindeki FAZ N'i uygula.

Önce oku: CLAUDE.md, bu plan belgesinin "Değişmeyen kurallar" ve "Kararların özeti" bölümleri,
FAZ N'in tamamı ve FAZ N'in dokunduğu kodla ilgili docs/ belgeleri.

Çalışma biçimi:
1. Kodu incele: ilgili dosyalar, bağımlılıklar, kalıcı veri, testler, paylaşılan dosyalar.
   Planla kod arasında çelişki varsa uygulamadan önce bana raporla.
2. Bana uygulama planı sun: değişecek dosyalar, yeni dosyalar, veri modeli değişiklikleri,
   geriye dönük uyumluluk, testler, hangi agent'ın hangi işi yapacağı. Onayımı bekle.
3. Onaydan sonra uygula. faz-N adlı bir branch'te çalış, anlamlı küçük commit'ler at.
4. Doğrula: app build, uygulama testleri, paket testleri (hata tabanı 18'i aşmamalı),
   UI değiştiyse CLAUDE.md doğrulama komutları ve ekran görüntüsü kontrolleri.
5. Bitir: plan belgesinde FAZ N başlığını ✅ yap, kabul kriterlerinin her birinin nasıl
   karşılandığını fazın altına "Kapanış notu" olarak yaz, mimari değiştiyse ilgili docs/ belgesini
   güncelle.
6. Rapor: değişen dosyalar, test sonuçları (sayılarla), alınan kararlar, açık kalanlar,
   benim vermem gereken kararlar.

Kurallar: kararlaştırılmamış bir ürün kararını kendin verme, sor. Çalışan sistemi yeniden yazma.
Çocuk verisini log'a yazma. Kaydedilmiş masallar açılmaya devam etmeli.
```

---

## Faza özel ekler (ortak promptun sonuna ekle)

**Faz 9:**
```
Silmeden önce envanteri çıkar ve bana göster; envanter onaylanmadan hiçbir dosya silme.
Üst klasördeki AuthKey_*.p8 dosyasına dokunma, yalnızca raporla.
```

**Faz 10:**
```
growth → learning geçişinde kaydedilmiş masalların çözülmesi için önce başarısız olan bir test yaz.
Hangi mod hangi bantta içeriğe ulaşıyor, bir tablo olarak raporla; içerik eksiklerini içerik hattı listesine yaz.
```

**Faz 11:**
```
Ek çekimi için Türkçe ünlü uyumu ve ünsüz yumuşaması test tablosu hazırla (en az 20 ad).
İlişki türü varyantı olmayan blueprint'leri listele; bunlar içerik hattına gider.
```

**Faz 13:**
```
Seri planlamasını kodlamadan önce SeriesPlan veri modelini ve bölüm açılma kuralını bana göster.
StoryGenerationManager bu fazda yalnızca senin oturumunda değişir.
```

**Faz 15:**
```
Barındırma için Firebase projesinin mevcut yapılandırmasını incele. Firebase Analytics ekleme.
Statik akış dosyasının örneğini ve yayın betiğinin kullanımını docs/'a yaz.
```

**Faz 16:**
```
Firebase Auth/Firestore/Storage dışında SDK ekleme; Analytics yok. Güvenlik kurallarını ve
emülatör testlerini repoya koy. Firestore bölgesini bana sor, kendin seçme.
```

**Faz 17:**
```
UI referansı İrem'in demo canvas'ı ve "MagicPaper ürün ve arayüz mimarisi" belgesi; renk ve
yazı tipinde CLAUDE.md tasarım yasası ve MPTheme geçerli (demo ile çelişirse yasa kazanır, raporla).
```
