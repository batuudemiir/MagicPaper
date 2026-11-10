import XCTest
import StoryEngine
@testable import MagicPaper

/// Alt kategori ile "Masalda kimler olsun?" ekranı arasındaki sözleşme
/// (30 Ekim 2026).
///
/// Motorun kuralı tek cümle ve `BlueprintSelector.companionCandidates`'ın
/// kendi yorumunda yazılı: *çocuğun gördüğü her kart seçilebilir olmalı.*
/// Seçildiğinde çalışmayan bir kart, verilen sözü sessizce başka bir masala
/// çevirir.
///
/// Kural motorda vardı, boru hattı bağlanmamıştı: ekran adayları konuyu
/// geçmeden istiyordu. Ölçüldüğünde "Meslekler" seçiliyken teklif edilen üç
/// karttan ikisi (ayı ve kedi) masalı hiç kurdurmuyordu — ebeveyn konuyu
/// seçiyor, kartı seçiyor, ve "masal yazılamadı" ekranını görüyordu.
@MainActor
final class StoryTopicCardTests: XCTestCase {

    private let service = OfflineStoryService.shared

    /// Konu seçiliyken teklif edilen HER kart masal kurabilmeli.
    func testEveryCardOfferedUnderATopicCanBuildAStory() throws {
        for age in [4, 6] {
            for mode in service.availableModes(forAge: age) {
                for topic in service.topicChoices(forAge: age, mode: mode) {
                    let cards = service.companionChoices(
                        forIdeaID: nil, mode: mode, age: age,
                        topicID: topic.id, family: nil)
                    XCTAssertFalse(cards.isEmpty,
                                   "\(topic.name) ekranda duruyor ama hiç kart teklif etmiyor")
                    for card in cards {
                        XCTAssertNoThrow(try service.compose(
                            childName: "Yeliz", ideaID: nil, companionID: card.id,
                            mode: mode, age: age,
                            seed: "card-\(topic.id)-\(card.id)", subOption: topic.id),
                            "\(topic.name) + \(card.id): kart teklif ediliyor ama masal kurulamıyor")
                    }
                }
            }
        }
    }

    /// Konu adayları gerçekten süzüyor: "Meslekler" hayvan teklif etmez.
    ///
    /// Bu testi bir kez YANLIŞ yöne düzelttim ve demet beni durdurdu. İnsanlar
    /// meslek dışı blueprint'lerden dışlandığı için "konusuz listede insan
    /// olmamalı" diye kurmuştum. Ölçüm tersini söyledi, ve ölçüm haklı:
    /// ekranın sorduğu soru "bu arkadaşı kabul eden kurulabilir bir şekil var
    /// mı", ve meslek şekilleri öğrenelimin parçası. Yani konu seçilmemişken
    /// de fırıncı teklif ediliyor — ebeveyn onu seçerse motor zaten meslek
    /// şekline düşüyor, çünkü insanı kabul eden tek şekil o. Sızıntı değil,
    /// akışın kendisi.
    ///
    /// Sayıya değil ilişkiye bakıyor: içerik büyüdükçe sayılar değişir.
    func testATopicChangesWhichCompanionsAreOffered() throws {
        let all = service.companionCandidates(forIdeaID: nil, mode: .learning, age: 6)
        let jobs = service.companionCandidates(forIdeaID: nil, mode: .learning, age: 6,
                                               topicID: "topic_learning_jobs")
        XCTAssertFalse(jobs.isEmpty)
        XCTAssertTrue(jobs.allSatisfy { $0.nature == .person && $0.occupation != nil },
                      "Meslekler yalnızca mesleği yazılı insanları teklif etmeli")
        XCTAssertTrue(Set(jobs.map(\.id)).isSubset(of: Set(all.map(\.id))),
                      "konu listesi konusuz listenin dışına çıkıyor")
        XCTAssertLessThan(jobs.count, all.count,
                          "Meslekler konusu hiçbir arkadaşı dışarıda bırakmıyor")
        XCTAssertTrue(all.contains { $0.nature == .animal },
                      "konusuz liste hayvan da içermeli")
    }

    /// Konu verilmediğinde liste daralmaz: eski akış aynı kalıyor.
    func testNoTopicMeansNoNarrowing() {
        let withoutArgument = service.companionCandidates(forIdeaID: nil, mode: .learning, age: 6)
        let withNilTopic = service.companionCandidates(forIdeaID: nil, mode: .learning, age: 6,
                                                       topicID: nil)
        XCTAssertEqual(withoutArgument.map(\.id), withNilTopic.map(\.id))
    }
}
