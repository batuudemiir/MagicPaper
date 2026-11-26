# V4 motor pin geçişi — 26 Kasım 2026

Kullanıcının uygulama hattını açmak için istediği sonraki pin commit'i kapsamında etkin P56 kaynağı `five-friends-56-runtime-v4` yapıldı. Tam SHA256: `c06a5dfc3f586eae5d837926cab915be6b22480c20e11e02c9ea7fd5894990d6`.

Önkoşul: 5a64646 adayının 630/630 ad denemesi, 1500/1500 örnekleme ve 15 hatasız Release testi. Bu geçiş yalnız etkin sürüm/hash sabitlerini ve sürüm kimliği testlerini değiştirir. V3 hash'i `v3SHA256` olarak korunur; v1/v2/v3/v4 payload baytları 5a64646 ile birebir aynıdır.

Uygulama hattı bu commit'ten sonra aynı V4 baytlarını uygulama paketine ekleyebilir; uygulama testleri, simülatörde bayrak açık/kapalı kontrolü ve yerel main birleşmesinden sonraki snapshot kayıtları uygulama hattının işidir. Bu commit uygulama/simülatör doğrulaması yaptığını iddia etmez. `productionEnabled=false`, `artApproved=false` değişmez; dalga runtime kapsamı açılmaz.

Aday REPORT.md ve verification-summary.json, pin geçişinden önceki aday kabulünün tarihsel kaydıdır; etkin pin için bu kayıt ve P56PinnedSource esas alınır.


Doğrulama: yeniden derlenmiş Release üzerinde P56PinTransition ve P56SourceMetadata seçimi, 7 test/0 hata. Dört sürümün tam hash/loader kimlikleri, etkin V4 en korumacı compose ve kaynakla JSON round-trip kontrol edildi.
