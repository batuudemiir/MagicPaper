# Codex C1–C4 uygulama planı

> REQUIRED SUB-SKILL: subagent-driven-development. Onaylı ortak plan ve 951f5ce sözleşme kabulü yürütülür. Testler önce yazılır, hat sonunda toplu koşulur.

**Goal:** Ortak P56 destek/kaynak sözleşmesini teslim etmek, gerçek legacy L/F ve A0 tanılarını ölçmek; onaylı90kitap çeşitlilik ve güvenlik/konu/aile kapsamını kanıtlı artımlar halinde büyütmek.

**Architecture:** P56 ayrı davranış olarak kalır; mevcut public request/story/ref/compose imzaları donar. Tek destek fonksiyonu router/composer nedenlerini ortaklaştırır; metadata P56'yı saklar fakat legacy çözücü unsupported görür. App bridge ve uygulama testleri Claude'a aittir.

**Tech Stack:** Swift Foundation, mevcut composer/ContentSafety/TurkishTextRenderer, offline JSON/Python export.

## İzolasyon ve kararlar

Taban951f5ce1925c04338248faa6324356601571ec83; ortakdal codex/bes-arkadas/entegrasyon, motorhattı codex/bes-arkadas/codex-motor. Mevcut bes-arkadas dalını korumak için buadlar Batuhan tarafından açıkça onaylandı. Worktree `/Users/batudemir/.codex/worktrees/magicpaper-bes-arkadas-codex-motor`. Test/build tekmevcut scratch ile yapılır, yeniDerivedData yok. Main/origin/yayın onayı yok.

## Artım A — C4 sözleşme temeli (C1–C3 planları görünürken)

Files: yeni P56Support.swift/P56Engine.swift/P56PinnedSource.swift, mevcut P56StoryComposer.swift ve ContentSourceMetadata.swift; yeni P56ContractTests/P56SourceMetadataTests.

- [ ] Testleri koddan önce yaz: ortak nedenlerde compose/support eşitliği, canonical5sıra ve desteksizyaş, manifest/payload/pin eşitliği, bozukpayload reddi.
- [ ] Request doğrulamasını P56Support.unsupportedReasons içine taşı; sortedunique nedenler tekunsupported/multiunsupportedContexts olarak aynen kullanılır. Boşsupport dizisi ageBudget/integrity/structure başarısını garanti etmez.
- [ ] companionIDs sadece gerçekmode/age/paketkapsamından canonical foxhedgehogowlcatbear sırasını döndürür.
- [ ] EnginebehaviorID ve tam payloadSHA sabiti. Buartım30kitap snapshot'ını dondurur; C2/C3 sonrakipayload/pin teslimi eski snapshot kimliğini sessiz değiştirmez.
- [ ] init(p56:)/p56Reference dörtgerçekalanla lossless zarf. P56legacy.reference=nil/statusunsupported. Bilinenbehavior bozukhash/alanmalformed; futureversionunsupported rawkorunur. Legacydecode davranışı değişmez.
- [ ] Resolver mevcutstatus yoluyla unsupported verdiğinden gereksizapp değişikliği yok; Claude'aresolverroundtrip testi notu.

## Artım B — C1 ölçüm kapıları

Files: yeni P56LegacyDiagnosticTests.swift; `docs/research/five-friends-p56-runtime/c1/`.

- [ ] L gerçekbundledlegacycatalog, F aynıcatalog constructorcopy yalnız companionlist canonical5ilekesilmiş; gerçek OfflineStoryComposer çalışır. P56setting'i legacy'ye ekleme yok.
- [ ] Günışığı exactforest; uyku legacyrestingroom için gerçekexistingID manifestte belirtilir. P56odasının legacyalias'ı değildir; bağlamfarkı raporda.
- [ ]15hücre×100aynıilkseed/kol, istekbaşına1deneme, tümfailures denominator. Pinnedcanonical girdiler L/F filtre kaybını tekbaşına ölçmez; ayrısurprisecompanion kolunda30canonicalfilter etkisi değil gerçek5filter farkı ölçülür. İkiörneklem karıştırılmaz.
- [ ] A0 5–6 scopedpilot:3syntheticprofile×100okuma; alternating3mode ve60%bedtime senaryoları ayrı. Legacy mevcutrecent/history/title girdileri kullanılır; ilkdeneme sonuçları anaölçümdür. Mevcut ReadingSequenceReport3retry anaölçüm diye kullanılmaz.
- [ ] P56A0 fixedlibrary repeatinherent rapor; unsupportedcontexts ayrı. L/F/Nbaşarıları gerçekoutput/structure/textsignatures ile ölçülür; artappbinder çalışmadıysa coverageresultuydurma.

## Artım C — C2 90kitap çeşitlilik

Files: ayrıvaryanttasarımı C2_VARIANT_DESIGN.md; yeni authoredvariantfiles/sourceIDs, runtimeexport/countdoğrulama ve P56testleri.

- [ ] Batuhan'ınonaylıhedefi15hücre×2mekanizma×3olayvaryantı=90kitap/720sayfa. Mekanizma9kalır;90mekanizmadiye sunulmaz.
- [ ] Herikimekanizmanın2ekolayı obstacle/childaction/observations/result bağlamında değişir; synonyms/namechangevaryantsayılmaz. Tasarımöncebağımsızinceleme.
- [ ] Eski30metin/source/payloadsnapshot korunur. HernewsourcekalıcıID/SHA,parentlineage,gerçekpagecausalquote/actor/temporal/anatomy/prop sahipliğiyle yazılır.
- [ ] Loaderhardcoded30/240/2 varsayımları sourceformat/schemadesteği korunarak manifestdeclaredcoverage'ye geçirilir; unknownschemanondestructiverejection. FrozenpublicAPIbozulmaz.
- [ ] N1500aynıseedmanifest yeniden; source/text/structurefirstrepeat ve önce/sonrafaildenominators.90kitaphedefi sırf sayıylakabuldeğil.

## Artım D — C3 güvenlik, konu, aile

- [ ] ÖnceContentSafety: tümbook/page/topic/emotion etiketleri tammetinbağımsızincelemeye dayanır. Intensitytekbaşınacalmkanıtıdeğil. Calmunease/hesitation ve avoidednilherkonu davranışı mevcutContentSafetyileaynı. Excludedbookaslatüretilmez, havuzboşsadesteknedenidöner.
- [ ] Sonrakonu: canonicalstorytopicIDs+gerçekkurgununkonuvaadi birebiruyumu incelenir. Requestfrozencontexts'den parameterliIDokumaya tekbaşınageçilmez; gerekiyorsasözleşmedeöneri/Claudeveürünkabulügerekir. Ozamana dek topicunsupported açık.
- [ ] SonraMasalailem: katılımcırolü/sayfabütçesi/isimçakışması/çocukeleyicilik/visualidentity/sourceözneleri tasarımı. Frozenrequestfamilydata taşımıyor; yeniAPIgerekiyorsasözleşmeyoluyla. Desteklenmiyorken familyaçıkunsupported.
- [ ] Recall/seri/özelgün bukapsamdasonrakitur, asla sessizceyoksayılmaz. C5yaşlar C2/C3kabulündenöncebaşlamaz.

## Son kapı

- [ ] Specvekaliteincelemesi, eleştirileridüzeltsonratekfinalfocusedtestkoşusu. Legacy252hash0değişim; publicrequest/output/refimzaları0breakingchange. Appspec/testClaude.
- [ ] Durumdosyasıtamcommit+gerçekkanıt, kendiDEMO_CHANGELOG, yalnızkendidosyalarıcommit. C4karşıincelemesindenönceentegrasyonnomerge; ortakplana göre --no-ff ile teslim. Main/originyok.

Buplan C1–C4'ü tekseferdebittidiyeetiketlemez. Herartımkendioutput/kabulüileayrıdır; bekleyengüvenlik/editoryal/görsel/çeşitlilik/yayınkapıları raporlanır.
