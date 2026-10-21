import XCTest
@testable import StoryEngine

/// FAZ 15: a remote content package goes through the bundle's own road, and
/// only a newer package that brings no new error replaces the bundle.
final class ContentPackageTests: XCTestCase {

    private var bundled: ContentCatalogLoader.Result!
    private var sources: (libraries: [ContentPackage.File], beats: [ContentPackage.File])!

    override func setUpWithError() throws {
        bundled = try ContentCatalogLoader().load()
        sources = ContentPackage.bundledSources()
    }

    // MARK: - Helpers

    /// The bundled sources with the first library's JSON edited.
    private func package(
        version: String? = nil,
        editLibrary: ((inout [String: Any]) -> Void)? = nil,
        editPilot: ((inout [String: Any]) -> Void)? = nil,
        beats: [ContentPackage.File]? = nil
    ) throws -> Data {
        var libraries = sources.libraries
        func edit(_ index: Int, _ change: (inout [String: Any]) -> Void) throws {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: libraries[index].data) as? [String: Any])
            change(&object)
            libraries[index] = .init(name: libraries[index].name, data: try JSONSerialization.data(withJSONObject: object))
        }
        if let editLibrary { try edit(0, editLibrary) }
        if let editPilot { try edit(1, editPilot) }
        let declared = try version ?? {
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: libraries[0].data) as? [String: Any])
            return try XCTUnwrap(object["version"] as? String)
        }()
        return try ContentPackage.build(version: declared, libraries: libraries, beats: beats ?? sources.beats)
    }

    private func bump(_ object: inout [String: Any]) { object["version"] = "2.1.1" }

    private func verdict(_ data: Data) -> RemoteCatalogPolicy.Verdict? {
        guard let result = try? ContentCatalogLoader().load(package: data) else { return nil }
        return RemoteCatalogPolicy.evaluate(package: result, bundled: bundled)
    }

    // MARK: - The same road

    func testThePackageCarriesEveryBundledDocument() {
        XCTAssertEqual(sources.libraries.map(\.name), ["shared_content_library_v2.json", "pilot_library_v1.json"])
        XCTAssertEqual(sources.beats.count, bundled.report.mergedSources.count - 2)
    }

    func testAPackageOfTheBundledSourcesBuildsTheSameCatalog() throws {
        let loaded = try ContentCatalogLoader().load(package: try package())
        let (a, b) = (loaded.catalog, bundled.catalog)

        XCTAssertEqual(a.version, b.version)
        XCTAssertEqual(a.blueprints.map(\.id), b.blueprints.map(\.id))
        XCTAssertEqual(a.templates.map(\.id), b.templates.map(\.id))
        XCTAssertEqual(a.templates.map(\.variants.count), b.templates.map(\.variants.count))
        XCTAssertEqual(a.series.continuations.map(\.id), b.series.continuations.map(\.id))
        XCTAssertEqual(a.series.templates.map(\.id), b.series.templates.map(\.id))
        XCTAssertEqual(a.storyIdeas.map(\.id), b.storyIdeas.map(\.id))
        XCTAssertEqual(a.interests.count, b.interests.count)
        XCTAssertEqual(loaded.report.integrity, bundled.report.integrity)
        XCTAssertEqual(loaded.report.source, .remotePackage(b.version))
    }

    func testBuildingIsDeterministic() throws {
        XCTAssertEqual(try package(), try package())
    }

    // MARK: - Refused before it loads

    func testAnUnknownSchemaIsRefused() throws {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: try package()) as? [String: Any])
        object["schemaVersion"] = ContentPackage.currentSchemaVersion + 1
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try ContentCatalogLoader().load(package: data)) { error in
            guard case CatalogLoadError.unsupportedSchema(let found, _) = error else {
                return XCTFail("Expected unsupportedSchema, got \(error)")
            }
            XCTAssertEqual(found, ContentPackage.currentSchemaVersion + 1)
        }
    }

    /// Yeni uygulama da ESKİ bir paketi okumaz.
    ///
    /// Karşılaştırma eşitlik olduğu için bu iki yönlü: eski uygulama yeni
    /// paketi indirmez (alanı bilmiyor), yeni uygulama eski paketi yüklemez.
    /// İkincisi önemsiz görünür ama `refrain` gibi bir alanın yokluğu ile
    /// "nakaratsız" olmak aynı şey değil — eski bir paketi yeni motorla
    /// okumak, kaydı olmayan bir kolu kontrol sanmak olurdu.
    func testAnOlderSchemaIsRefusedToo() throws {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: try package()) as? [String: Any])
        object["schemaVersion"] = ContentPackage.currentSchemaVersion - 1
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try ContentCatalogLoader().load(package: data)) { error in
            guard case CatalogLoadError.unsupportedSchema(let found, let supported) = error else {
                return XCTFail("Expected unsupportedSchema, got \(error)")
            }
            XCTAssertEqual(found, ContentPackage.currentSchemaVersion - 1)
            XCTAssertEqual(supported, ContentPackage.currentSchemaVersion)
        }
    }

    /// Nakarat taşıyabilen bir paket, nakaratı bilmeyen bir uygulamaya
    /// gitmemeli: şema sürümü bunun tek işareti (`Content/Experiments/README.md`).
    func testTheSchemaVersionCoversTheRefrainField() {
        XCTAssertGreaterThanOrEqual(ContentPackage.currentSchemaVersion, 2,
                                     "refrain alanı eklendiğinde şema sürümü artırılmış olmalı")
    }

    func testAPackageWithoutLibrariesIsRefused() throws {
        let data = try ContentPackage.build(version: "2.1.1", libraries: [], beats: sources.beats)
        XCTAssertThrowsError(try ContentCatalogLoader().load(package: data))
    }

    func testAPackageThatIsNotJSONIsRefused() {
        XCTAssertThrowsError(try ContentCatalogLoader().load(package: Data("garbage".utf8)))
    }

    func testADeclaredVersionTheDocumentsDoNotCarryIsRefused() throws {
        XCTAssertThrowsError(try ContentCatalogLoader().load(package: try package(version: "9.9.9")))
    }

    func testAPackageWithNoBlueprintsIsRefused() throws {
        let data = try package(editLibrary: { $0["blueprints"] = [] }, editPilot: { $0["blueprints"] = [] })
        XCTAssertThrowsError(try ContentCatalogLoader().load(package: data))
    }

    // MARK: - Policy

    func testTheSameVersionAsTheBundleIsNotUsed() throws {
        XCTAssertEqual(verdict(try package()), .notNewer(package: "2.1.0", bundled: "2.1.0"))
    }

    func testAnOlderVersionIsNotUsed() throws {
        let data = try package(editLibrary: { $0["version"] = "1.9.0" })
        XCTAssertEqual(verdict(data), .notNewer(package: "1.9.0", bundled: "2.1.0"))
    }

    func testANewerCleanPackageIsUsed() throws {
        XCTAssertEqual(verdict(try package(editLibrary: bump)), .accept)
    }

    func testANewErrorKeepsTheBundle() throws {
        let data = try package(editLibrary: bump, editPilot: { pilot in
            var blueprints = pilot["blueprints"] as! [[String: Any]]
            blueprints[0]["aggregateWeight"] = -1
            pilot["blueprints"] = blueprints
        })
        guard case .newIssues(let issues) = verdict(data) else {
            return XCTFail("A package with a broken weight must not be used")
        }
        XCTAssertTrue(issues.contains { $0.hasPrefix("blueprint_aggregate_weight_invalid") }, "\(issues)")
    }

    func testAPackageMissingItsBeatFilesKeepsTheBundle() throws {
        let data = try package(editLibrary: bump, beats: [])
        XCTAssertNotEqual(verdict(data), .accept)
    }

    func testAnUnreadableBeatFileKeepsTheBundle() throws {
        var beats = sources.beats
        beats[0] = .init(name: beats[0].name, data: Data(#"{"beat":"not_a_beat","variants":[]}"#.utf8))
        let data = try package(editLibrary: bump, beats: beats)
        XCTAssertNotEqual(verdict(data), .accept)
    }
}
