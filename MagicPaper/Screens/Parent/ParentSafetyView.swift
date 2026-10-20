import StoryEngine
import SwiftUI

/// 31 · Ebeveyn · Güvenlik (`IcerikGuvenligi`).
///
/// Çocuk başına içerik güvenliği (FAZ 17): korku ve gerilim iki kademe
/// (Sakin varsayılan, Biraz heyecan), kaçınılacak konular katalogdan. Motor
/// bunları süzgeç olarak uygular (`ContentSafety`): elenen içerik daha az
/// değil, hiç seçilmez. Altında aile geneli kurallar: günlük okuma süresi
/// (`MPReadingBudget`), uyku saati (`MPBedtime`), masal onayı.
///
/// Prototipteki "Serbest metin" yok: masallar serbest metin olmadan yazılıyor
/// (karar 7 Ekim 2026). "Ölüm ve kayıp" bir seçenek değil: hiçbir masalda yok.
struct ParentSafetyView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var topics: [CatalogSafetyTopic] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Güvenlik", subtitle: "Masallar iki kez kontrol edilir")
                    .padding(.horizontal, -MPSpacing.screenH)

                if let profile = profileManager.currentProfile {
                    if profileManager.profiles.count > 1 { childPicker }
                    fearCard(profile)
                    if !topics.isEmpty { topicsCard(profile) }
                }

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
                    MPRowDivider(area: .parent)
                    ParentToggleRow(
                        systemImage: "eye.slash",
                        tone: .lav,
                        title: "Masalları onayla",
                        subtitle: settings.approve
                            ? "Yeni masallar sen onaylayana kadar kitaplıkta görünmez"
                            : "Yeni masallar doğrudan kitaplığa girer",
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
        .onAppear { topics = OfflineStoryService.shared.safetyTopics() }
    }

    // MARK: - Çocuk başına

    private var childPicker: some View {
        MPFlowLayout(spacing: MPSpacing.sm) {
            ForEach(profileManager.profiles) { child in
                MPChip(title: child.name, isSelected: child.id == profileManager.currentProfile?.id) {
                    profileManager.switchProfile(to: child)
                }
                .frame(minHeight: MPSize.minTouchParent)
                .accessibilityLabel("\(child.name) için güvenlik ayarları")
            }
        }
    }

    private func fearCard(_ profile: UserProfile) -> some View {
        let safety = profile.effectiveSafety
        return MPCard(area: .parent, padding: MPSpacing.xl) {
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text("Korku ve gerilim").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Masallardaki heyecanın üst sınırı.").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
                MPSegmented(options: [(ContentSafety.Level.calm, "Sakin"),
                                      (ContentSafety.Level.someExcitement, "Biraz heyecan")],
                            selection: Binding(
                                get: { safety.level },
                                set: { level in
                                    profileManager.setSafety(ContentSafety(level: level, avoided: safety.avoided),
                                                             for: profile.id)
                                }),
                            track: MPColor.borderParent)
                Text(safety.level == .calm
                     ? "Tedirginlik ya da tereddüt anı olan masallar seçilmez."
                     : "Biraz merak ve heyecan olabilir. Hiçbir masal korkutmaz, hepsi sakin biter.")
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Seçili çip = kaçınılan konu. Hiç ayarlanmamış ayar her konuyu kaçınır.
    private func topicsCard(_ profile: UserProfile) -> some View {
        let safety = profile.effectiveSafety
        return MPCard(area: .parent, padding: MPSpacing.xl) {
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text("Kaçınılacak konular").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Seçilen konular hiçbir masalda geçmez.").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
                MPFlowLayout(spacing: MPSpacing.sm) {
                    ForEach(topics) { topic in
                        let avoided = safety.avoids(topic.id)
                        MPChip(title: topic.name, isSelected: avoided) {
                            toggle(topic.id, in: safety, profile: profile)
                        }
                        .frame(minHeight: MPSize.minTouchParent)
                        .accessibilityHint(topic.summary ?? "")
                    }
                }
            }
        }
    }

    private func toggle(_ topic: SafetyTopic, in safety: ContentSafety, profile: UserProfile) {
        var avoided = safety.avoided ?? Set(topics.map(\.id))
        if avoided.contains(topic) { avoided.remove(topic) } else { avoided.insert(topic) }
        profileManager.setSafety(ContentSafety(level: safety.level, avoided: avoided), for: profile.id)
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
