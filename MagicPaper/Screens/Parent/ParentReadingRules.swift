import SwiftUI

/// "Büyükler için" sayfasının "Okuma ve uyku" bölümü (14 Kasım 2026).
///
/// Ebeveynin en sık dokunduğu iki aile kuralı: günlük okuma süresi
/// (`MPReadingBudget`) ve uyku saati (`MPBedtime`). Eskiden Güvenlik
/// sekmesindeydi; oda tek sayfa olunca ilk bakışta görünsün diye buraya taşındı.
struct ParentReadingRules: View {
    @EnvironmentObject private var settings: MPSettingsStore

    var body: some View {
        ParentSection(title: "Okuma ve uyku") {
            ParentToggleRow(
                systemImage: "clock",
                tone: .peach,
                title: "Günlük okuma süresi",
                subtitle: settings.screenLimit
                    ? "\(settings.screenLimitMinutes) dakika, sonra \u{201C}Yarın devam\u{201D}"
                    : "Sınır yok",
                isOn: $settings.screenLimit
            )
            if settings.screenLimit {
                MPFlowLayout(spacing: MPSpacing.sm) {
                    ForEach(MPReadingBudget.choices, id: \.self) { minutes in
                        MPChip(title: "\(minutes) dk",
                               isSelected: settings.screenLimitMinutes == minutes) {
                            settings.screenLimitMinutes = minutes
                        }
                        .accessibilityLabel("Günde \(minutes) dakika")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MPSpacing.lg)
                .padding(.bottom, MPSpacing.md)
            }
            MPRowDivider(area: .parent)
            ParentToggleRow(
                systemImage: "moon",
                tone: .lav,
                title: "Uyku saati",
                subtitle: settings.bedtime
                    ? "\(MPReminder.clockLabel(hour: settings.bedtimeHour, minute: settings.bedtimeMinute)) ve sonrasında uyku masalı öne çıkar"
                    : "Kapalı",
                isOn: $settings.bedtime
            )
            if settings.bedtime {
                MPRowDivider(area: .parent)
                MPListRow(systemImage: "clock", tone: .lav, title: "Uyku saati başlangıcı") {
                    DatePicker("Uyku saati başlangıcı", selection: bedtimeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(MPColor.actionPrimary)
                }
            }
        }
    }

    private var bedtimeTime: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = settings.bedtimeHour
                c.minute = settings.bedtimeMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                settings.bedtimeHour = c.hour ?? 20
                settings.bedtimeMinute = c.minute ?? 30
            }
        )
    }
}
