import XCTest
@testable import MagicPaper

/// E4: one hero identity. `HeroLook` is the source; the illustrated book's
/// `AvatarSpec` is derived from it, a parent's old book character moves into
/// it once, and the hero and the star wallet travel with the account.
@MainActor
final class HeroIdentityTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var avatarFolder: String!
    private var heroes: HeroLookStore!
    private var avatars: AvatarStore!
    private let kit = AvatarKit.bundled

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "HeroIdentityTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        avatarFolder = "HeroIdentityAvatars-\(UUID().uuidString)"
        heroes = HeroLookStore(defaults: defaults)
        avatars = AvatarStore(subdirectory: avatarFolder)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        AvatarStore.eraseAll(subdirectory: avatarFolder)
        try await super.tearDown()
    }

    private func spec(_ look: HeroLook) throws -> AvatarSpec {
        try XCTUnwrap(HeroBookCharacter.spec(for: look, kit: kit))
    }

    // MARK: - The mapping table

    func testEverySkinToneMaps() throws {
        let expected = ["skin_light", "skin_light", "skin_olive", "skin_brown", "skin_brown", "skin_dark"]
        for (index, tone) in expected.enumerated() {
            XCTAssertEqual(try spec(HeroLook(skin: index)).skinTone, tone, "ten \(index)")
        }
        XCTAssertEqual(try spec(HeroLook(skin: 99)).skinTone, kit?.defaults["skinTone"], "tanınmayan ten varsayılana")
    }

    func testEveryHairStyleMaps() throws {
        let expected: [HeroLook.Hair: String] = [
            .short: "hair_short", .buzz: "hair_short", .spiky: "hair_short", .none: "hair_short",
            .curly: "hair_curly", .afro: "hair_curly", .long: "hair_shoulder", .bob: "hair_shoulder",
            .ponytail: "hair_ponytail", .buns: "hair_ponytail", .braids: "hair_braided",
        ]
        XCTAssertEqual(Set(expected.keys), Set(HeroLook.Hair.allCases), "her saç biçimi tabloda")
        for (hair, style) in expected {
            XCTAssertEqual(try spec(HeroLook(hair: hair)).hairStyle, style, hair.rawValue)
        }
    }

    func testEveryHairColorMaps() throws {
        let expected = ["haircolor_black", "haircolor_brown", "haircolor_auburn", "haircolor_blonde",
                        "haircolor_red", "haircolor_blonde"]
        for (index, color) in expected.enumerated() {
            XCTAssertEqual(try spec(HeroLook(hairColor: index)).hairColor, color, "saç rengi \(index)")
        }
        for index in [6, 7, 42] {
            XCTAssertEqual(try spec(HeroLook(hairColor: index)).hairColor, kit?.defaults["hairColor"],
                           "kitte karşılığı olmayan renk \(index) varsayılana")
        }
    }

    func testEveryTopColorMaps() throws {
        let expected = ["outfit_blue", "outfit_green", "outfit_yellow", "outfit_orange",
                        "outfit_purple", "outfit_red", "outfit_purple", "outfit_blue"]
        for (index, outfit) in expected.enumerated() {
            for top in HeroLook.Top.allCases {
                XCTAssertEqual(try spec(HeroLook(top: top, topColor: index)).outfit, outfit, "üst \(top) \(index)")
            }
        }
    }

    func testAccessories() throws {
        XCTAssertEqual(try spec(HeroLook(glasses: .round)).accessory, "acc_glasses")
        XCTAssertEqual(try spec(HeroLook(glasses: .square, headwear: .beanie)).accessory, "acc_glasses")
        XCTAssertEqual(try spec(HeroLook(headwear: .beanie)).accessory, "acc_beanie")
        XCTAssertNil(try spec(HeroLook(glasses: .sun)).accessory)
        XCTAssertNil(try spec(HeroLook(headwear: .crown)).accessory)
    }

    /// Every result is something the kit draws.
    func testEveryDerivedSpecIsResolvedAgainstTheKit() throws {
        let kit = try XCTUnwrap(self.kit)
        for look in HeroLook.samples where look.kind == .child && look.headwear != .hijab {
            let derived = try spec(look)
            XCTAssertEqual(derived, kit.resolved(derived))
        }
    }

    func testAnimalsAndHijabAreNotDrawn() {
        for kind in HeroLook.Kind.allCases where kind.isAnimal {
            XCTAssertNil(HeroBookCharacter.spec(for: HeroLook(kind: kind), kit: kit), kind.rawValue)
        }
        XCTAssertNil(HeroBookCharacter.spec(for: HeroLook(headwear: .hijab), kit: kit))
    }

    // MARK: - The reverse and the one-time migration

    /// Every kit combination survives the round trip, except the parts a
    /// hero does not hand out (beanie, backpack).
    func testEveryKitCombinationRoundTrips() throws {
        let kit = try XCTUnwrap(self.kit)
        for skin in kit.options(.skinTone) {
            for hair in kit.options(.hairStyle) {
                for color in kit.options(.hairColor) {
                    for outfit in kit.options(.outfit) {
                        for accessory in [nil, "acc_glasses"] as [String?] {
                            let original = AvatarSpec(skinTone: skin.id, hairStyle: hair.id, hairColor: color.id,
                                                      outfit: outfit.id, accessory: accessory)
                            let back = HeroBookCharacter.spec(for: HeroBookCharacter.look(from: original, kit: kit), kit: kit)
                            XCTAssertEqual(back, kit.resolved(original))
                        }
                    }
                }
            }
        }
        let beanie = HeroBookCharacter.look(from: AvatarSpec(
            skinTone: "skin_dark", hairStyle: "hair_curly", hairColor: "haircolor_black",
            outfit: "outfit_red", accessory: "acc_beanie"), kit: kit)
        XCTAssertEqual(beanie.headwear, .none, "yıldızla alınan bere taşımayla verilmez")
        XCTAssertEqual(beanie.kind, .child)
    }

    func testTheMigrationMakesAHeroFromTheSavedCharacterOnce() async throws {
        let id = UUID()
        try await avatars.save(AvatarSpec(skinTone: "skin_dark", hairStyle: "hair_braided",
                                          hairColor: "haircolor_red", outfit: "outfit_green"), for: id)
        let migration = HeroIdentityMigration(heroes: heroes, avatars: avatars, kit: kit)

        let made = await migration.migrateIfNeeded(profileID: id)
        XCTAssertTrue(made)
        let look = try XCTUnwrap(heroes.look(for: id))
        XCTAssertEqual(look.skin, 5)
        XCTAssertEqual(look.hair, .braids)
        XCTAssertEqual(look.hairColor, 4)
        XCTAssertEqual(look.topColor, 1)
        XCTAssertTrue(heroes.isUnchangedSinceMigration(for: id))

        let again = await migration.migrateIfNeeded(profileID: id)
        XCTAssertFalse(again)

        var edited = look
        edited.hair = .afro
        heroes.save(edited, for: id)
        XCTAssertFalse(heroes.isUnchangedSinceMigration(for: id), "çocuk değiştirdi: artık taşınmış sayılmaz")
    }

    func testTheMigrationNeverWritesOverAnExistingHero() async throws {
        let id = UUID()
        let own = HeroLook(kind: .panda, fur: 3)
        heroes.save(own, for: id)
        try await avatars.save(AvatarSpec(skinTone: "skin_light", hairStyle: "hair_short",
                                          hairColor: "haircolor_black", outfit: "outfit_blue"), for: id)

        let made = await HeroIdentityMigration(heroes: heroes, avatars: avatars, kit: kit).migrateIfNeeded(profileID: id)
        XCTAssertFalse(made)
        XCTAssertEqual(heroes.look(for: id), own)
    }

    func testWithoutASavedCharacterNothingIsMigrated() async {
        let id = UUID()
        let made = await HeroIdentityMigration(heroes: heroes, avatars: avatars, kit: kit).migrateIfNeeded(profileID: id)
        XCTAssertFalse(made)
        XCTAssertNil(heroes.look(for: id))
    }

    // MARK: - Where the book reads the character

    func testTheBookReadsTheHeroFirstThenTheSavedCharacter() async throws {
        let withHero = UUID(), animal = UUID(), oldInstall = UUID()
        let saved = AvatarSpec(skinTone: "skin_light", hairStyle: "hair_short",
                               hairColor: "haircolor_blonde", outfit: "outfit_red")
        for id in [withHero, animal, oldInstall] { try await avatars.save(saved, for: id) }
        let look = HeroLook(skin: 3, hair: .curly, hairColor: 0, topColor: 2)
        heroes.save(look, for: withHero)
        heroes.save(HeroLook(kind: .bunny), for: animal)

        let source = BookCharacterSource(heroes: heroes, avatars: avatars, kit: kit)
        let fromHero = await source.avatar(for: withHero)
        let fromAnimal = await source.avatar(for: animal)
        let fromOld = await source.avatar(for: oldInstall)
        XCTAssertEqual(fromHero, HeroBookCharacter.spec(for: look, kit: kit))
        XCTAssertNil(fromAnimal, "hayvan kahraman: metin kitabı, eski karaktere düşülmez")
        XCTAssertEqual(fromOld, saved)
    }

    // MARK: - Account sync

    func testTheHeroAndTheWalletTravelAsRecords() {
        let id = UUID()
        let wallets = MPStarWalletStore(defaults: defaults)
        XCTAssertTrue(AppFamilyLocalStore.heroRecords(for: id, heroes: heroes, wallets: wallets).isEmpty)

        heroes.save(HeroLook(hair: .curly), for: id)
        var wallet = MPStarWallet()
        _ = wallet.buy(itemIDs: ["hero.top.hoodie"], total: 8, earned: 10)
        wallets.save(wallet, for: id)

        let records = AppFamilyLocalStore.heroRecords(for: id, heroes: heroes, wallets: wallets)
        XCTAssertEqual(Set(records.map(\.key)), [SyncKey(collection: .heroes, id: id.uuidString),
                                                  SyncKey(collection: .starWallets, id: id.uuidString)])
        XCTAssertNil(records.first { $0.key.collection == .heroes }?.changedAt)
    }

    /// A hero the migration made carries the oldest time, so a hero the child
    /// made on another device wins.
    func testAMigratedHeroLosesToARealOneFromAnotherDevice() throws {
        let id = UUID()
        let migrated = HeroLook(skin: 2)
        heroes.save(migrated, for: id)
        heroes.markMigrated(migrated, for: id)
        let local = AppFamilyLocalStore.heroRecords(for: id, heroes: heroes, wallets: MPStarWalletStore(defaults: defaults))
        let heroRecord = try XCTUnwrap(local.first { $0.key.collection == .heroes })
        XCTAssertEqual(heroRecord.changedAt, Date(timeIntervalSince1970: 0))

        let real = try SyncCoding.encode(HeroLook(kind: .cat, fur: 1))
        let remote = RemoteSyncRecord(key: heroRecord.key, payload: real, updatedAt: 1_759_780_000_000,
                                      serverUpdatedAt: Date(timeIntervalSince1970: 1_759_780_000))
        let plan = SyncPlanner.plan(local: [heroRecord], remote: [remote], ledger: SyncLedger(),
                                    now: Date(timeIntervalSince1970: 1_759_790_000))
        XCTAssertEqual(plan.apply.map(\.payload), [real])
        XCTAssertTrue(plan.push.isEmpty)
    }

    /// Last writer wins for the hero.
    func testTheNewerHeroWins() throws {
        let key = SyncKey(collection: .heroes, id: UUID().uuidString)
        let older = try SyncCoding.encode(HeroLook(hair: .short))
        let newer = try SyncCoding.encode(HeroLook(hair: .afro))
        let local = LocalSyncRecord(key: key, payload: older, changedAt: Date(timeIntervalSince1970: 1_759_780_000))
        let remote = RemoteSyncRecord(key: key, payload: newer, updatedAt: 1_759_780_500_000,
                                      serverUpdatedAt: Date(timeIntervalSince1970: 1_759_780_500))
        let plan = SyncPlanner.plan(local: [local], remote: [remote], ledger: SyncLedger(),
                                    now: Date(timeIntervalSince1970: 1_759_790_000))
        XCTAssertEqual(plan.apply.map(\.payload), [newer])
    }

    func testAppliedHeroReplacesAndWalletsMerge() throws {
        let id = UUID()
        let wallets = MPStarWalletStore(defaults: defaults)
        heroes.save(HeroLook(hair: .short), for: id)
        try AppFamilyLocalStore.applyHeroRecord(
            RemoteSyncRecord(key: SyncKey(collection: .heroes, id: id.uuidString),
                             payload: try SyncCoding.encode(HeroLook(hair: .braids)), updatedAt: 1, serverUpdatedAt: nil),
            heroes: heroes, wallets: wallets)
        XCTAssertEqual(heroes.look(for: id)?.hair, .braids)

        // Two devices bought different things; both purchases stay.
        var here = MPStarWallet()
        _ = here.buy(itemIDs: ["hero.top.hoodie"], total: 8, earned: 20, now: Date(timeIntervalSince1970: 10))
        wallets.save(here, for: id)
        var there = MPStarWallet()
        _ = there.buy(itemIDs: ["hero.headwear.crown"], total: 14, earned: 20, now: Date(timeIntervalSince1970: 20))
        try AppFamilyLocalStore.applyHeroRecord(
            RemoteSyncRecord(key: SyncKey(collection: .starWallets, id: id.uuidString),
                             payload: try SyncCoding.encode(there), updatedAt: 2, serverUpdatedAt: nil),
            heroes: heroes, wallets: wallets)
        let merged = wallets.wallet(for: id)
        XCTAssertTrue(merged.owns(itemID: "hero.top.hoodie"))
        XCTAssertTrue(merged.owns(itemID: "hero.headwear.crown"))
        XCTAssertEqual(merged.spent, 22)
    }

    func testDeletionsRemoveTheHeroTheMarkerAndTheWallet() throws {
        let id = UUID()
        let wallets = MPStarWalletStore(defaults: defaults)
        let look = HeroLook(skin: 4)
        heroes.save(look, for: id)
        heroes.markMigrated(look, for: id)
        var wallet = MPStarWallet()
        _ = wallet.buy(itemIDs: ["hero.top.hoodie"], total: 8, earned: 8)
        wallets.save(wallet, for: id)

        for collection in [SyncCollection.heroes, .starWallets] {
            try AppFamilyLocalStore.applyHeroRecord(
                RemoteSyncRecord(key: SyncKey(collection: collection, id: id.uuidString),
                                 payload: nil, updatedAt: 3, serverUpdatedAt: nil),
                heroes: heroes, wallets: wallets)
        }
        XCTAssertNil(heroes.look(for: id))
        XCTAssertFalse(heroes.isUnchangedSinceMigration(for: id))
        XCTAssertNil(defaults.data(forKey: HeroLookStore.migratedPrefix + id.uuidString))
        XCTAssertNil(wallets.storedWallet(for: id))
        // "Tüm verileri sil" removes by prefix; the marker shares the hero's.
        XCTAssertTrue(HeroLookStore.migratedPrefix.hasPrefix(HeroLookStore.keyPrefix))
    }

    // MARK: - A collection the server refuses

    func testThePushIsCutSoTheIsolatedCollectionsGoAlone() {
        let records = [SyncCollection.children, .heroes, .stories, .starWallets, .heroes].enumerated().map { index, collection in
            RemoteSyncRecord(key: SyncKey(collection: collection, id: "\(index)"), payload: "{}", updatedAt: 1, serverUpdatedAt: nil)
        }
        let split = SyncPushPlan.split(records)
        XCTAssertEqual(split.core.map(\.key.collection), [.children, .stories])
        XCTAssertEqual(split.isolated.map(\.0), [.heroes, .starWallets])
        XCTAssertEqual(split.isolated.first?.1.count, 2)
    }

    /// Until the rules are deployed the server refuses `heroes`; the child,
    /// the story and everything else still sync, and the hero waits.
    func testARefusedCollectionDoesNotStopTheOthers() async throws {
        let server = RefusingFamilyRemote()
        let local = FakeFamilyLocal()
        let folder = "SyncTest-\(UUID().uuidString)"
        defer { SyncLedgerStore(subdirectory: folder).erase() }
        var tick = 0.0
        let sync = FamilySyncService(local: local, ledgerStore: SyncLedgerStore(subdirectory: folder), clock: {
            tick += 1
            return Date(timeIntervalSince1970: 1_759_780_000 + tick)
        })
        defer { sync.stop() }
        sync.start(uid: "parent", remote: server)

        let child = SyncKey(collection: .children, id: "c1")
        let hero = SyncKey(collection: .heroes, id: "c1")
        local.records[child] = "{\"name\":\"Ada\"}"
        local.records[hero] = "{\"kind\":\"child\"}"
        let first = await sync.syncNow()
        XCTAssertTrue(first, "reddedilen koleksiyon eşitlemeyi düşürmemeli")
        let storedChild = await server.document(child)
        let storedHeroBefore = await server.document(hero)
        XCTAssertNotNil(storedChild)
        XCTAssertNil(storedHeroBefore)
        XCTAssertTrue(sync.hasUnsentChanges, "kahraman cihazda bekliyor")

        await server.deployRules()
        let second = await sync.syncNow()
        XCTAssertTrue(second)
        let storedHero = await server.document(hero)
        XCTAssertEqual(storedHero?.payload, "{\"kind\":\"child\"}")
        XCTAssertFalse(sync.hasUnsentChanges)
    }
}

/// A server whose rules do not know the isolated collections yet: it stores
/// everything else and refuses those, the way `FirestoreFamilyRemote` reports
/// a refusal.
actor RefusingFamilyRemote: FamilyRemote {
    private var documents: [SyncKey: RemoteSyncRecord] = [:]
    private var deployed = false
    private var clock = Date(timeIntervalSince1970: 1_759_780_000)

    func deployRules() { deployed = true }
    func document(_ key: SyncKey) -> RemoteSyncRecord? { documents[key] }

    func pull(since highWater: [String: Date]) async throws -> [RemoteSyncRecord] {
        documents.values.filter { record in
            if record.key.collection.isIsolated && !deployed { return false }
            guard let mark = highWater[record.key.collection.rawValue] else { return true }
            return (record.serverUpdatedAt ?? .distantPast) > mark
        }
    }

    func push(_ records: [RemoteSyncRecord]) async throws {
        let (core, isolated) = SyncPushPlan.split(records)
        for record in core { store(record) }
        var refused: Set<SyncCollection> = []
        for (collection, group) in isolated {
            if deployed { for record in group { store(record) } } else { refused.insert(collection) }
        }
        if !refused.isEmpty { throw SyncRejection(collections: refused) }
    }

    private func store(_ record: RemoteSyncRecord) {
        clock = clock.addingTimeInterval(1)
        documents[record.key] = RemoteSyncRecord(
            key: record.key, payload: record.payload, updatedAt: record.updatedAt, serverUpdatedAt: clock)
    }

    func deleteEverything() async throws { documents = [:] }
    func recordConsent(_ record: ConsentRecord) async throws {}
    func consent(version: String) async throws -> ConsentRecord? { nil }
}
