import SwiftUI

/// 15 · Yeni kelimelerim (`YeniKelimeler`).
///
/// Okunmuş sayfalarda geçen sözlük kelimeleri (`MPVocabulary.collectedWords`),
/// anlamı ve geçtiği masalla. "Bu hafta" ya da "Tümü". Her kartın dinle
/// düğmesi kelimeyi ve anlamını sesli okur. Sayaç yalnızca toplananı söyler;
/// hedef, kıyas ya da "az kaldı" yok (CLAUDE.md ilke 7).
struct NewWordsView: View {
    let profile: UserProfile
    let onClose: () -> Void

    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var speech = MPSpeech.shared
    @State private var thisWeekOnly = true
    @State private var speakingID: String?

    private static let tones: [MPWorldTone] = [.yellow, .sky, .lav, .green, .pink, .mint, .peach]

    private var all: [MPVocabulary.CollectedWord] {
        MPVocabulary.collectedWords(in: storyManager.stories.filter { $0.belongs(to: profile) })
    }

    var body: some View {
        let words = all
        let shown = thisWeekOnly ? MPVocabulary.collectedThisWeek(words) : words
        VStack(spacing: 0) {
            MPTopBar(title: "Yeni kelimelerim",
                     subtitle: words.isEmpty ? nil : "\(words.count) kelime topladın",
                     onBack: close) { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            HStack(spacing: MPSpacing.sm) {
                MPChip(title: "Bu hafta", isSelected: thisWeekOnly) { thisWeekOnly = true }
                MPChip(title: "Tümü", isSelected: !thisWeekOnly) { thisWeekOnly = false }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.vertical, MPSpacing.md)

            if shown.isEmpty {
                empty(hasAny: !words.isEmpty)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: MPSpacing.md) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { index, item in
                            card(item, tone: Self.tones[index % Self.tones.count])
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onDisappear { if speakingID != nil { speech.stop() } }
    }

    private func card(_ item: MPVocabulary.CollectedWord, tone: MPWorldTone) -> some View {
        let isSpeaking = speakingID == item.id && speech.isSpeaking
        return HStack(alignment: .center, spacing: MPSpacing.md) {
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(item.word.term).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                Text(item.word.meaning).mpText(.body).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let sentence = item.sentence {
                    Text(Self.marked(sentence, surface: item.word.surface))
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, MP.S.x1)
                        .accessibilityLabel("Masalda: \(sentence)")
                }
                Text(item.storyTitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button {
                if isSpeaking {
                    speech.stop()
                    speakingID = nil
                } else {
                    speakingID = item.id
                    speech.speak(["\(item.word.term).", item.word.meaning, item.sentence]
                        .compactMap { $0 }.joined(separator: " "))
                }
            } label: {
                MPIcon("speaker.wave.2", size: 22, weight: .semibold)
                    .foregroundStyle(isSpeaking ? MPColor.textOnAction : MPColor.actionPrimary)
                    .frame(width: MPSize.minTouchKid, height: MPSize.minTouchKid)
                    .background(isSpeaking ? MPColor.actionPrimary : MPColor.backgroundSurface, in: Circle())
                    .mpShadow(.card)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("\(item.word.term) kelimesini dinle")
        }
        .padding(MPSpacing.lg)
        .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
    }

    /// Masal cümlesi; kelime sayfadaki yazılışıyla kalın (renk tek başına
    /// bilgi taşımaz). Arama okuyucudakiyle aynı (`ReaderWords`).
    private static func marked(_ sentence: String, surface: String) -> AttributedString {
        var out = AttributedString(sentence)
        out.font = MP.F.bodySM()
        if let range = out.range(of: surface, options: [.caseInsensitive], locale: Locale(identifier: "tr_TR")) {
            out[range].font = MP.F.bodySM(.bold)
            out[range].foregroundColor = MP.C.textBody
        }
        return out
    }

    private func empty(hasAny: Bool) -> some View {
        VStack(spacing: MPSpacing.lg) {
            Spacer(minLength: 0)
            MascotImage(mascot: .reading, width: 140).accessibilityHidden(true)
            Text(hasAny ? "Bu hafta yeni kelime yok" : "Kelimeler masallarda saklı")
                .mpText(.title3).foregroundStyle(MPColor.textPrimary)
            Text("Masal okurken altı noktalı kelimelere dokun. Okuduğun kelimeler burada toplanır.")
                .mpText(.body).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MPSpacing.xxxl)
    }

    private func close() {
        speech.stop()
        onClose()
    }
}
