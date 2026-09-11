import Foundation
@testable import StoryEngine

/// Builds the JSON a well-behaved model would return, so orchestrator tests
/// exercise the real parsing path rather than a shortcut.
enum ScriptedResponses {

    static func outline(beatIDs: [String], title: String = "The Clearing", settings: [String]? = nil) -> String {
        let beats = beatIDs.enumerated().map { index, beatID -> String in
            let setting = settings?[safe: index] ?? "forest clearing"
            return """
            {"templateBeatID":"\(beatID)","summary":"Something happens in beat \(index).",
             "settingKey":"\(setting)","timeOfDayKey":"afternoon","moodKey":"curious",
             "castNames":["Deniz"]}
            """
        }.joined(separator: ",")
        return #"{"title":"\#(title)","logline":"A small adventure.","beats":[\#(beats)]}"#
    }

    /// A draft whose every segment lands comfortably inside a typical budget.
    static func draft(beatCount: Int, wordsPerBeat: Int = 70) -> String {
        let segments = (0..<beatCount).map { index -> String in
            """
            {"beatIndex":\(index),"text":"\(prose(words: wordsPerBeat, seed: index))"}
            """
        }.joined(separator: ",")
        return """
        {"voiceProfile":{"narratorRegister":"warm close third person",
          "sentenceRhythm":"short sentences with occasional longer ones",
          "recurringMotifs":["lantern light"],"characterVoices":{"Deniz":"curious and direct"}},
         "segments":[\(segments)]}
        """
    }

    static func refinement(words: Int = 70, seed: Int = 0) -> String {
        #"{"title":"A page","text":"\#(prose(words: words, seed: seed))"}"#
    }

    static let noFindings = #"{"findings":[]}"#

    static func findings(pageIndex: Int, code: String, message: String, severity: String = "warning") -> String {
        #"{"findings":[{"pageIndex":\#(pageIndex),"code":"\#(code)","severity":"\#(severity)","message":"\#(message)"}]}"#
    }

    /// Plain sentences mentioning the protagonist, with no appearance claims
    /// and enough variety that the repetition validator stays quiet.
    static func prose(words: Int, seed: Int = 0) -> String {
        let openers = [
            "Deniz stepped forward carefully",
            "The lantern swayed above Deniz",
            "Somewhere nearby a branch creaked",
            "Deniz counted the stones aloud",
            "A small wind moved through the grass",
            "Deniz listened to the quiet",
            "The path bent away to the left",
            "Deniz smiled at the thought"
        ]
        let tails = [
            "and the afternoon felt wider than before",
            "which made the whole clearing seem friendly",
            "so the next few steps came more easily",
            "and something small shifted in the undergrowth",
            "while the light turned a slower shade of gold",
            "before the sound faded into the trees"
        ]

        var sentences: [String] = []
        var total = 0
        var index = seed
        while total < words {
            let opener = openers[index % openers.count]
            let tail = tails[(index / openers.count + seed) % tails.count]
            let sentence = "\(opener) \(tail)."
            sentences.append(sentence)
            total += TextMetrics.wordCount(sentence)
            index += 1
        }
        return sentences.joined(separator: " ")
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
