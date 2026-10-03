// RETIRED 2026-09-30 (Faz 4.5) — not compiled. Moved out of
// StoryGenerationManager.swift together with DevStoryTestView, its only caller.
// The development-only offline template provider it held is superseded by
// OfflineStoryService + StoryEngine. Kept for reference; restore by moving it
// back into a compiled folder.

import Foundation
import StoryEngine

// MARK: - Offline Metin Hikaye Motoru

struct TestOfflineStoryRequest: Sendable {
    let childName: String
    let childAge: Int
    let genre: String
    let theme: String?
    let settingId: String?
    let companionId: String?
    let length: MPStoryLength
    let tone: MPStoryTone
    let language: StoryLanguage
    let seed: UInt64
    let readBlueprintIDs: [String]
}

struct TestV2LibraryResponse: Codable {
    let blueprints: [TestV2Blueprint]
    let settings: [TestV2Setting]
    let companions: [TestV2Companion]
    let objects: [TestV2Object]
    let events: [TestV2Event]
    let challenges: [TestV2Challenge]
    let templates: [TestV2Template]
}

struct TestV2Blueprint: Codable {
    let id: String; let genre: String; let theme: String; let ageRange: String
    let pageCount: Int; let pageRoles: [TestV2PageRole]
}
struct TestV2PageRole: Codable { let pageNumber: Int; let role: String }
struct TestV2Setting: Codable { let id: String; let name: String; let compatibleThemes: [String]?; let possessiveStem: Bool? }
struct TestV2Companion: Codable { let id: String; let name: String; let type: String; let compatibleThemes: [String]?; let typePossessiveStem: Bool? }
struct TestV2Object: Codable { let id: String; let name: String; let compatibleThemes: [String]? }
struct TestV2Event: Codable { let id: String; let type: String; let compatibleThemes: [String]?; let stateChanges: [String]? }
struct TestV2Challenge: Codable { let id: String; let description: String; let compatibleThemes: [String]?; let stateChanges: [String]? }
struct TestV2Template: Codable { let id: String; let role: String; let compatibleThemes: [String]?; let variants: [TestV2Variant] }
struct TestV2Variant: Codable { let id: String; let text: String; let visualScene: String }

struct TestLCG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}

enum TestOfflineGenerationError: Error, LocalizedError {
    case noBlueprintsFound(String)
    case missingSharedLibrary
    case insufficientVariants
    case unresolvedPlaceholders(String)
    
    var errorDescription: String? {
        switch self {
        case .noBlueprintsFound(let msg): return msg
        case .missingSharedLibrary: return "shared_content_library_v2.json bulunamadı"
        case .insufficientVariants: return "Şablonda varyant eksik"
        case .unresolvedPlaceholders(let text): return "Çözülmemiş yer tutucu: \(text)"
        }
    }
}

final class TestOfflineTemplateStoryProvider {
    
    private func loadV2Library() throws -> TestV2LibraryResponse {
        var url = Bundle.main.url(forResource: "shared_content_library_v2", withExtension: "json", subdirectory: "templates/offline/v2")
        
        if url == nil {
            for bundle in Bundle.allBundles + Bundle.allFrameworks {
                if let u = bundle.url(forResource: "shared_content_library_v2", withExtension: "json", subdirectory: "templates/offline/v2") ?? 
                          bundle.url(forResource: "shared_content_library_v2", withExtension: "json") {
                    url = u
                    break
                }
            }
        }
        
        if url == nil {
            let devPath = "/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/StoryEngine/Sources/StoryEngine/Resources/templates/offline/v2/shared_content_library_v2.json"
            if FileManager.default.fileExists(atPath: devPath) { url = URL(fileURLWithPath: devPath) }
        }
        
        guard let finalURL = url else { throw TestOfflineGenerationError.missingSharedLibrary }
        let data = try Data(contentsOf: finalURL)
        return try JSONDecoder().decode(TestV2LibraryResponse.self, from: data)
    }
    
    private func ageGroupString(for age: Int) -> String {
        switch age {
        case ...4: return "3-4"
        case 5...6: return "5-6"
        case 7...8: return "7-8"
        case 9...10: return "9-10"
        default: return "11-12"
        }
    }
    
    func generateStory(request: TestOfflineStoryRequest) async throws -> (Story, String) {
        let library = try loadV2Library()
        
        let requestedAge = ageGroupString(for: request.childAge)
        let requestedPages = request.length.pageCount
        let requestedGenre = request.genre
        
        var candidates = library.blueprints.filter { $0.genre == requestedGenre }
        if candidates.isEmpty { candidates = library.blueprints }
        
        let ageFiltered = candidates.filter { $0.ageRange == requestedAge }
        if !ageFiltered.isEmpty { candidates = ageFiltered }
        
        let pageFiltered = candidates.filter { $0.pageCount == requestedPages }
        if !pageFiltered.isEmpty { candidates = pageFiltered }
        
        var unreadCandidates = candidates.filter { !request.readBlueprintIDs.contains($0.id) }
        if unreadCandidates.isEmpty { unreadCandidates = candidates }
        
        var rng = TestLCG(seed: request.seed)
        let selectedBlueprint = unreadCandidates.randomElement(using: &rng)!
        let theme = request.theme ?? selectedBlueprint.theme
        
        func getCompatible<T>(from items: [T], preferredId: String?, extract: (T) -> [String]?) -> T {
            if let pref = preferredId, let match = items.first(where: { 
                if let s = $0 as? TestV2Setting { return s.id == pref }
                if let c = $0 as? TestV2Companion { return c.id == pref }
                return false
            }) { return match }
            
            let filtered = items.filter { (extract($0) ?? []).contains(theme) }
            return (filtered.isEmpty ? items : filtered).randomElement(using: &rng)!
        }
        
        let selectedSetting = getCompatible(from: library.settings, preferredId: request.settingId) { $0.compatibleThemes }
        let selectedCompanion = getCompatible(from: library.companions, preferredId: request.companionId) { $0.compatibleThemes }
        let selectedObject = getCompatible(from: library.objects, preferredId: nil) { $0.compatibleThemes }
        
        let variables: [String: String] = [
            "child.name": request.childName,
            "child.age": "\(request.childAge)",
            "setting.name": selectedSetting.name,
            "companion.name": selectedCompanion.name,
            "companion.type": selectedCompanion.type,
            "object.name": selectedObject.name
        ]
        
        let title = "\(request.childName) ve \(selectedCompanion.name)"
        
        // Settings whose name already ends in a third-person possessive take a
        // buffer -n- before case endings ("Bulut Krallığı'nda"). It cannot be
        // inferred from spelling, so content declares it.
        var possessiveSlots: Set<String> = []
        if selectedSetting.possessiveStem == true { possessiveSlots.insert("setting.name") }
        // "ateşböceği" is a compound possessive: dative is "ateşböceğine", not
        // "ateşböceğiye". It is the only companion type in the library affected,
        // which is exactly why it would have shipped unnoticed.
        if selectedCompanion.typePossessiveStem == true { possessiveSlots.insert("companion.type") }

        var pages: [StoryPage] = []
        var renderDefects: [String] = []
        
        for roleInfo in selectedBlueprint.pageRoles {
            let roleTemplates = library.templates.filter { $0.role == roleInfo.role }
            var validTemplates = roleTemplates.filter { ($0.compatibleThemes ?? []).contains(theme) }
            if validTemplates.isEmpty { validTemplates = roleTemplates }
            
            guard let selectedTemplate = validTemplates.randomElement(using: &rng),
                  let variant = selectedTemplate.variants.randomElement(using: &rng) else {
                throw TestOfflineGenerationError.insufficientVariants
            }
            
            let text = TurkishSuffixResolver.render(variant.text, variables: variables, possessiveStemSlots: possessiveSlots)
            let scene = TurkishSuffixResolver.render(variant.visualScene, variables: variables, possessiveStemSlots: possessiveSlots)

            // A missing slot or an unrecognised suffix is a content defect. The
            // old check only looked for a leftover "{{", so a substituted token
            // carrying a bad suffix passed silently — which is how ungrammatical
            // Turkish reached readers.
            for slot in text.missingSlots + scene.missingSlots {
                renderDefects.append("çözülmemiş yer tutucu: {{\(slot)}} (\(variant.id))")
            }
            for suffix in text.unrecognisedSuffixes + scene.unrecognisedSuffixes {
                renderDefects.append("tanınmayan ek: '\(suffix) (\(variant.id))")
            }

            pages.append(StoryPage(id: UUID(), title: "", text: text.text, imagePrompt: scene.text))
        }
        
        if !renderDefects.isEmpty { throw TestOfflineGenerationError.unresolvedPlaceholders(renderDefects.joined(separator: "; ")) }
        
        let story = Story(id: UUID(), title: title, childName: request.childName, theme: .jungle, language: request.language, status: .completed, pages: pages)
        return (story, selectedBlueprint.id)
    }
}

/// Adapter onto `StoryEngine.TurkishTextRenderer`.
///
/// The previous implementation lived here and had its own morphology, which is
/// why `{{setting.name}}'nde` shipped as "Fısıldayan Orman'nde": unrecognised
/// suffixes were emitted verbatim. Morphology now has one home, in the engine,
/// with tests. This type only knows which slots are proper nouns — a content
/// fact the renderer cannot infer.
struct TurkishSuffixResolver {

    /// Slots holding proper nouns take an apostrophe before a case ending;
    /// `companion.type` and `object.name` are common nouns and must not.
    private static let properNounSlots: Set<String> = ["child.name", "companion.name", "setting.name"]

    /// Loanwords that keep a hard final consonant ("robot" → "robotu").
    private static let softeningBlocked: Set<String> = ["robot"]

    static func slots(
        variables: [String: String],
        possessiveStemSlots: Set<String> = []
    ) -> [String: TurkishTextRenderer.Slot] {
        variables.reduce(into: [:]) { result, entry in
            let (key, value) = entry
            result[key] = TurkishTextRenderer.Slot(
                value,
                isProperNoun: properNounSlots.contains(key),
                hasPossessiveEnding: possessiveStemSlots.contains(key),
                blocksSoftening: softeningBlocked.contains(value.lowercased())
            )
        }
    }

    static func render(
        _ template: String,
        variables: [String: String],
        possessiveStemSlots: Set<String> = []
    ) -> TurkishTextRenderer.Result {
        TurkishTextRenderer.render(
            template,
            slots: slots(variables: variables, possessiveStemSlots: possessiveStemSlots)
        )
    }

    /// Back-compatible entry point for callers that only want the text.
    static func apply(to text: String, variables: [String: String]) -> String {
        render(text, variables: variables).text
    }
}
