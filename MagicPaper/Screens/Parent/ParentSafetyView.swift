import SwiftUI

/// 31 · Ebeveyn · Güvenlik (`IcerikGuvenligi`).
///
/// Yalnızca gerçekten işleyen ayarlar burada: günlük okuma süresi
/// (`MPReadingBudget`), uyku saati (`MPBedtime`) ve masal onayı. Prototipteki "Serbest metin"
/// yok: masallar çevrimdışı motorla, serbest metin olmadan yazılıyor (karar
/// 7 Ekim 2026). "Korku ve gerilim" ile "Kaçınılacak konular" motorda içerik
/// etiketi gelince eklenir; işlemeyen bir anahtar göstermek, hiç
/// göstermemekten kötüdür (bkz. `MPReadingBudget`).
struct ParentSafetyView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Güvenlik", subtitle: "Masallar iki kez kontrol edilir")
                    .padding(.horizontal, -MPSpacing.screenH)

                MPGroupedList(area: .parent) {
                    readingLimitRow
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
                            ? "\(MPReminder.clockLabel(hour: settings.bedtimeHour, minute: settings.bedtimeMinute)) ve sonrasında yalnızca uyku masalı"
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
                    MPRowDivider(area: .parent)
                    ParentToggleRow(
                        systemImage: "eye.slash",
                        tone: .lav,
                        title: "Masalları onayla",
                        subtitle: settings.approve
                            ? "Yeni masallar sen onaylayana kadar kitaplıkta görünmez"
                            : "Yeni masallar hemen kitaplığa girer",
                        isOn: Binding(get: { settings.approve }, set: setApproval)
                    )
                }

                HStack(alignment: .top, spacing: MPSpacing.sm) {
                    Image(systemName: "checkmark.shield")
                        .font(.mp(.footnote))
                        .foregroundStyle(MPColor.statusSuccess)
                        .accessibilityHidden(true)
                    Text("Masallar cihazda, çocuklar için yazılmış parçalardan kurulur. Her masal gösterilmeden önce bir kez daha kontrol edilir.")
                        .mpText(.footnote)
                        .foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, MPSpacing.xs)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
    }

    private var readingLimitRow: some View {
        ParentToggleRow(
            systemImage: "clock",
            tone: .peach,
            title: "Günlük okuma süresi",
            subtitle: settings.screenLimit
                ? "\(settings.screenLimitMinutes) dakika, sonra \u{201C}Yarın devam\u{201D}"
                : "Sınır yok",
            isOn: $settings.screenLimit
        )
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

    private func setApproval(_ on: Bool) {
        settings.approve = on
        guard on else { return }
        // Kapı ileriye doğru çalışır: açıklaması `approveStories` üzerinde.
        settings.approveStories(storyManager.stories.map(\.id))
        app.showToast("Yeni masallar onayını bekleyecek", symbol: "eye.slash")
    }
}

#Preview("31 · Güvenlik") {
    ParentSafetyView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
