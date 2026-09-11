import Foundation

/// Loads the story templates shipped with the package.
///
/// Templates are JSON, not Swift. Adding a kind of story — a new arc, a new
/// visual style, different word budgets — is a file, reviewable on its own,
/// with no engine change and no recompile of anything that matters.
public enum BuiltInTemplates {
    private struct Bundled: Codable { let templates: [StoryTemplate] }

    /// Every template shipped with the package. Empty rather than fatal if the
    /// resources are missing: the resolver will then report the template id the
    /// caller asked for, which is a far more useful failure than a crash.
    ///
    /// SwiftPM's `.process` rule flattens `Resources/templates/*.json` to the
    /// bundle root, so the lookup is deliberately flat. Files that are not
    /// templates simply fail to decode and are skipped.
    public static let all: [StoryTemplate] = {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        return urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url -> [StoryTemplate]? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                if let bundled = try? decoder.decode(Bundled.self, from: data) { return bundled.templates }
                if let single = try? decoder.decode(StoryTemplate.self, from: data) { return [single] }
                return nil
            }
            .flatMap { $0 }
    }()

    public static var repository: StaticTemplateRepository { StaticTemplateRepository(all) }

    public static func template(id: String) -> StoryTemplate? {
        all.filter { $0.id == id }.max { $0.version < $1.version }
    }
}
