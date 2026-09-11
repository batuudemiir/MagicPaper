import Foundation
import StoryEngine

/// Converts an engine story into the app's existing `Story` model.
///
/// This is what lets the engine ship without touching a single view.
/// `LibraryView`, `StoryViewerView` and the PDF export keep reading the type
/// they already read; when the app eventually switches over, the change is at
/// this one seam rather than across every screen.
public enum StoryEngineMapper {

    /// Maps an engine story onto the app model.
    ///
    /// - Parameter themeKey: the theme the request was made with, mapped back
    ///   onto the app's enum for display. The engine itself has no theme type.
    public static func appStory(
        from story: StoryEngine.Story,
        themeKey: String,
        languageCode: String,
        childName: String,
        coverImageFileName: String? = nil
    ) -> MagicPaper.Story {
        var mapped = MagicPaper.Story(
            id: story.id,
            title: story.title,
            childName: childName,
            theme: theme(for: themeKey),
            language: language(for: languageCode),
            status: status(for: story),
            pages: story.pages
                .sorted { $0.index < $1.index }
                .map { page in appPage(from: page, in: story) },
            coverImageFileName: coverImageFileName ?? firstImageFileName(in: story)
        )
        mapped.currentProgress = story.status == .ready ? nil : story.status.rawValue
        return mapped
    }

    static func appPage(from page: StoryEngine.StoryPage, in story: StoryEngine.Story) -> MagicPaper.StoryPage {
        let asset = page.visualAssetID.flatMap { story.visualAsset(id: $0) }
        return MagicPaper.StoryPage(
            id: page.id,
            title: page.title,
            // The app model keeps a single prompt string; the engine's full
            // constraint set stays on the engine story, which is where a
            // regeneration reads it from anyway.
            text: page.text,
            imagePrompt: asset?.promptSnapshot?.positivePrompt ?? "",
            imageFileName: asset?.imageRef?.locator,
            imageUrl: asset?.imageRef?.locator
        )
    }

    static func firstImageFileName(in story: StoryEngine.Story) -> String? {
        story.pages
            .sorted { $0.index < $1.index }
            .compactMap { page in page.visualAssetID.flatMap { story.visualAsset(id: $0) }?.imageRef?.locator }
            .first
    }

    static func status(for story: StoryEngine.Story) -> StoryStatus {
        switch story.status {
        case .planning, .writing: return .writingStory
        case .illustrating: return .generatingImages
        case .validating: return .generatingImages
        case .ready: return .completed
        case .failed: return .failed
        }
    }

    /// Theme keys are free-form in the engine, so this is a display-side
    /// convenience only. An unrecognised key is a custom adventure, not an error.
    static func theme(for key: String) -> StoryTheme {
        StoryTheme(rawValue: key) ?? .custom
    }

    static func language(for code: String) -> StoryLanguage {
        StoryLanguage(rawValue: String(code.prefix(2)).lowercased()) ?? .english
    }

    /// The theme key to send for one of the app's existing themes.
    public static func themeKey(for theme: StoryTheme) -> String { theme.rawValue }

    public static func languageCode(for language: StoryLanguage) -> String { language.rawValue }
}
