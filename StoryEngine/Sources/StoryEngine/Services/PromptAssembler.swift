import Foundation
import CharacterEngine

/// Builds the instruction blocks every AI stage shares.
///
/// One rule shapes all of it: the model is told the cast's names, ages and
/// pronouns, and nothing about how they look. Appearance reaches the image
/// model through `VisualConstraintSet` and never passes through a text prompt,
/// so there is no path by which a language model could be asked to invent — or
/// even to echo — a child's appearance.
public struct PromptAssembler: Sendable {
    private let template: StoryTemplate

    public init(template: StoryTemplate) { self.template = template }

    /// Instructions common to every stage.
    public func systemInstructions(extra: [String] = []) -> [String] {
        var blocks: [String] = []
        let narrative = template.narrative

        if let audience = narrative.promptSlot("audience") { blocks.append(audience) }
        if let craft = narrative.promptSlot("craft") { blocks.append(craft) }
        if let safety = narrative.promptSlot("safety") { blocks.append(safety) }
        if let continuity = narrative.promptSlot("continuity") { blocks.append(continuity) }

        // Non-negotiable, and appended last so it is the final word.
        blocks.append(narrative.promptSlot(NarrativeTemplate.appearanceLockdownSlot) ?? Self.fallbackAppearanceLockdown)
        blocks.append(contentsOf: extra)
        return blocks
    }

    /// The default lockdown, used if a template forgets to declare one.
    ///
    /// A template with no lockdown slot is an authoring mistake, but the safe
    /// failure is to lock down anyway rather than to let the model improvise.
    static let fallbackAppearanceLockdown = """
    Never describe how any character looks. Do not mention hair, eyes, skin, \
    height, build, clothing or accessories. Appearance is supplied separately \
    and is not yours to invent or vary.
    """

    /// The cast, as the model is allowed to know them.
    public func castBlock(_ characters: [StoryCharacter]) -> String {
        let lines = characters.map { character -> String in
            let role = character.role.rawValue
            let pronouns = character.identity.pronouns
            return "- \(character.displayName) (\(role), age \(character.identity.ageYears), "
                + "pronouns \(pronouns.subject)/\(pronouns.object)/\(pronouns.possessive))"
        }
        return (["CAST — refer to them by name; their appearance is not yours to describe:"] + lines)
            .joined(separator: "\n")
    }

    public func settingsBlock(themeKey: String, languageCode: String, toneKey: String?) -> String {
        var lines = [
            "THEME KEY: \(themeKey)",
            "LANGUAGE: write everything in \(languageCode)"
        ]
        if let toneKey { lines.append("TONE: \(toneKey)") }
        return lines.joined(separator: "\n")
    }

    /// The planned beats, numbered, with the template's own instructions.
    public func beatBlock(_ plan: BeatPlan) -> String {
        let lines = plan.beats.map { planned -> String in
            let instructions = planned.beat.instructions.map { "   - \($0)" }.joined(separator: "\n")
            return """
            \(planned.ordinal). [\(planned.beat.id)] \(planned.beat.title) (\(planned.beat.role.rawValue))
            \(instructions)
            """
        }
        return (["BEATS — one page each, in this order:"] + lines).joined(separator: "\n")
    }

    public func outlineBlock(_ outline: StoryOutline) -> String {
        let lines = outline.beats.sorted { $0.ordinal < $1.ordinal }.map { beat in
            "\(beat.ordinal). [\(beat.templateBeatID)] \(beat.summary) — \(beat.settingKey), \(beat.timeOfDayKey), \(beat.moodKey)"
        }
        return (["OUTLINE:", "Title: \(outline.title)", "Logline: \(outline.logline)"] + lines)
            .joined(separator: "\n")
    }

    public func voiceBlock(_ voice: VoiceProfile) -> String {
        var lines = [
            "VOICE — match this exactly; it is the book's established voice:",
            "- Narrator: \(voice.narratorRegister)",
            "- Rhythm: \(voice.sentenceRhythm)"
        ]
        if !voice.recurringMotifs.isEmpty {
            lines.append("- Motifs: \(voice.recurringMotifs.joined(separator: ", "))")
        }
        for (name, description) in voice.characterVoices.sorted(by: { $0.key < $1.key }) {
            lines.append("- \(name) speaks: \(description)")
        }
        return lines.joined(separator: "\n")
    }
}
