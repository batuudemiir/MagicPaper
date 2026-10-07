// MPMascot.swift
// The raccoon mascot (brand kit). Rules (see docs/BRAND_AND_MASCOT.md):
// - at most one mascot per screen, never inside the parent area,
// - one feeling per screen, picked from the table below,
// - speech bubble copy is short, warm, second person, never blames.

import SwiftUI

enum Mascot: String, CaseIterable {
    // expressions (bust)
    case happy, curious, calm, sleepy, surprised, thinking
    // poses (full body)
    case onBook, waving, pencil, reading, sleeping, walking, front, threeQuarter

    /// Asset name inside Assets.xcassets/Brand.
    var assetName: String {
        switch self {
        case .happy: "Brand/mascotHappy"
        case .curious: "Brand/mascotCurious"
        case .calm: "Brand/mascotCalm"
        case .sleepy: "Brand/mascotSleepy"
        case .surprised: "Brand/mascotSurprised"
        case .thinking: "Brand/mascotThinking"
        case .onBook: "Brand/mascotOnBook"
        case .waving: "Brand/mascotWaving"
        case .pencil: "Brand/mascotPencil"
        case .reading: "Brand/mascotReading"
        case .sleeping: "Brand/mascotSleeping"
        case .walking: "Brand/mascotWalking"
        case .front: "Brand/mascotFront"
        case .threeQuarter: "Brand/mascotThreeQuarter"
        }
    }

    /// Where the prototype uses it (keep this mapping when adding screens).
    var usage: String {
        switch self {
        case .happy: "Masal sonu, rozet kazanınca"
        case .curious: "Ana sayfa dünya sorusu, Neleri sever"
        case .calm: "Ebeveyn onayı"
        case .sleepy: "Bildirim izni, Yıldız bitti"
        case .surprised: "Üretim başarısız"
        case .thinking: "İnternet yok"
        case .onBook: "Karşılama 1, Abonelik"
        case .waving: "Masal sonu, Okundu kartı"
        case .pencil: "Masal yazılıyor, İlk masal"
        case .reading: "Boş kitaplık"
        case .sleeping: "Uyku modu, Uyku kartı"
        case .walking: "Karşılama 3"
        case .front, .threeQuarter: "Yedek (rehber, pazarlama)"
        }
    }
}

struct MascotImage: View {
    let mascot: Mascot
    var width: CGFloat
    var body: some View {
        Image(mascot.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .accessibilityHidden(true)
    }
}

/// White bubble with a small tail on the lower left, pointing at the mascot.
struct SpeechBubble: View {
    let text: String
    var style: MPTextStyle = .bodyStrong
    var body: some View {
        Text(text)
            .mpText(style)
            .foregroundStyle(MPColor.textPrimary)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 3).fill(MPColor.backgroundSurface)
                    .frame(width: 14, height: 14).rotationEffect(.degrees(45)).offset(x: -6, y: -16)
            }
            .mpShadow(.control)
    }
}

/// Mascot + bubble row: "Bu gece hangi dünyaya gidelim?" on Ana sayfa, "Elif neleri sever?" on Neleri sever.
struct MascotSays: View {
    let mascot: Mascot
    let text: String
    var mascotWidth: CGFloat = 64
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            MascotImage(mascot: mascot, width: mascotWidth)
            SpeechBubble(text: text).padding(.bottom, 8)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// Empty and error states (Boş kitaplık, Üretim başarısız, Yıldız bitti, Bildirim izni):
/// pastel blob, mascot, title, one sentence, actions.
struct MPStateView<Actions: View, Extra: View>: View {
    let mascot: Mascot
    var tone: MPWorldTone = .lav
    let title: String
    let message: String
    @ViewBuilder var extra: Extra
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                Ellipse().fill(tone.soft).frame(width: 200, height: 150)
                MascotImage(mascot: mascot, width: 190).padding(.bottom, 10)
            }
            .frame(height: 200)
            Text(title).mpText(.title2).multilineTextAlignment(.center).foregroundStyle(MPColor.textPrimary)
            Text(message).mpText(.body).multilineTextAlignment(.center).foregroundStyle(MPColor.textSecondary).frame(maxWidth: 300)
            extra
            VStack(spacing: 6) { actions }.padding(.top, 6)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension MPStateView where Extra == EmptyView {
    init(mascot: Mascot, tone: MPWorldTone = .lav, title: String, message: String, @ViewBuilder actions: () -> Actions) {
        self.init(mascot: mascot, tone: tone, title: title, message: message, extra: { EmptyView() }, actions: actions)
    }
}

#Preview("State views") {
    MPStateView(mascot: .reading, tone: .lav, title: "Kitaplığın henüz boş", message: "İlk masalını yarat, burada seni beklesin.") {
        MPButton(title: "İlk masalını yarat", systemImage: "wand.and.sparkles") {}
    }
    .background(MPColor.backgroundKid)
}
