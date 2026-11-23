import SwiftUI

/// Profil'deki "Okuma yolculuğum" kartı (24 Kasım 2026, İrem): sayfanın
/// küçük önizlemesi, widget gibi. Solda el sallayan Ragi, çerçevesiz (Profil'in
/// tek Ragi'si); sağda başlık, "N gün üst üste"
/// ve bu haftanın yedi günü. Kartın tamamı Okuma yolculuğum'u açar.
///
/// Kurallar `ReadingJourney`'de (ilke 7): okunmayan gün boş daire, başarısızlık
/// işareti değil; "az kaldı", geri sayım ya da kıyas yok.
struct ReadingJourneyWidget: View {
    let journey: ReadingJourney
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private static let ragiWidth: CGFloat = MPSize.minTouchHero + MPSpacing.xl

    var body: some View {
        Button {
            MPHaptics.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                HStack(alignment: .center, spacing: MPSpacing.md) {
                    // Ekranın tek Ragi'si: el sallayan, çerçevesiz, doğrudan
                    // beyaz kartta (24 Kasım 2026, İrem).
                    if !typeSize.isAccessibilitySize {
                        MascotImage(mascot: .waving, width: Self.ragiWidth)
                    }
                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                        Text("Okuma yolculuğum").mpText(.footnote).fontWeight(.bold)
                            .foregroundStyle(MPColor.actionPrimary)
                        Text(journey.headline).mpText(.section).foregroundStyle(MPColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(journey.weekSummary).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    MPIcon("chevron.right", size: MP.G.sm, weight: .semibold)
                        .foregroundStyle(MPColor.textSecondary)
                        .frame(width: MPSize.circleButton - MPSpacing.sm, height: MPSize.circleButton - MPSpacing.sm)
                        .overlay(Circle().strokeBorder(MPColor.borderKid, lineWidth: 2))
                        .accessibilityHidden(true)
                }
                weekStrip
            }
            .padding(MPSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Okuma yolculuğum, \(journey.headline)")
        .accessibilityValue(journey.weekSummary)
        .accessibilityHint("Okuma yolculuğunu açar")
        .accessibilityAddTraits(.isButton)
    }

    /// Bu haftanın yedi günü: okunan mor tik, bugün halkalı, okunmayan boş
    /// daire, gelecek gün tarih. Sayfadaki şeridin küçüğü.
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(journey.days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: MPSpacing.xxs) {
                    Text(day.label).mpText(.footnote).fontWeight(.bold)
                        .foregroundStyle(day.isToday ? MPColor.actionPrimary : MPColor.textSecondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    mark(day)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, MPSpacing.xs)
        .background(MP.C.surfaceSunken, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func mark(_ day: ReadingJourney.Day) -> some View {
        let size = MPSize.circleButton - MPSpacing.md
        Group {
            if day.read {
                MPIcon("checkmark", size: MP.G.xs, weight: .bold)
                    .foregroundStyle(MPColor.textOnAction)
                    .frame(width: size, height: size)
                    .background(MPColor.actionPrimary, in: Circle())
            } else if day.isFuture {
                Text("\(day.dayOfMonth)").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .frame(width: size, height: size)
            } else {
                Circle().strokeBorder(MPColor.borderKid, lineWidth: 2)
                    .background(MPColor.backgroundSurface, in: Circle())
                    .frame(width: size, height: size)
            }
        }
        .overlay {
            if day.isToday {
                Circle().strokeBorder(MPColor.actionPrimary, lineWidth: 2)
                    .frame(width: size + MPSpacing.xs, height: size + MPSpacing.xs)
            }
        }
    }
}
