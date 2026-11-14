import StoryEngine
import SwiftUI
import TipKit

/// 31 · Ebeveyn · Güvenlik (`IcerikGuvenligi`).
///
/// Çocuk başına içerik güvenliği (FAZ 17): korku ve gerilim iki kademe
/// (Sakin varsayılan, Biraz heyecan), kaçınılacak konular katalogdan. Motor
/// bunları süzgeç olarak uygular (`ContentSafety`): elenen içerik daha az
/// değil, hiç seçilmez. Altında akşam ve koleksiyon ayarları.
///
/// 14 Kasım 2026: sekme değil, "Büyükler için" sayfasından itilen alt sayfa.
/// Günlük okuma süresi ve uyku saati o sayfaya taşındı (`ParentReadingRules`);
/// masal onayı kalktı, masallar yazılır yazılmaz kitaplığa girer.
///
/// Prototipteki "Serbest metin" yok: masallar serbest metin olmadan yazılıyor
/// (karar 7 Ekim 2026). "Ölüm ve kayıp" bir seçenek değil: hiçbir masalda yok.
struct ParentSafetyView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var topics: [CatalogSafetyTopic] = []
    /// "Büyükler için" sayfasından itilir (14 Kasım 2026); "Geri" oraya döner.
    var onBack: (() -> Void)? = nil

    init(onBack: (() -> Void)? = nil) { self.onBack = onBack }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Masal güvenliği", subtitle: "Masallar iki kez kontrol edilir", onBack: onBack)

                if let profile = profileManager.currentProfile {
                    if profileManager.profiles.count > 1 { childPicker }
                    fearCard(profile)
                    if !topics.isEmpty { topicsCard(profile) }
                }

                // Faz 11: akşam ritüeli.
                TipView(TalkPromptsTip())
                ParentSection(title: "Akşam ve birlikte okuma") {
                    ParentToggleRow(systemImage: "checklist", tone: .lav, title: "Akşam sırası",
                                    subtitle: settings.bedtimeRoutine
                                        ? "Uyku saatinde diş, pijama, masal, ışık sırası görünür."
                                        : "Kapalı",
                                    isOn: $settings.bedtimeRoutine)
                    MPRowDivider(area: .parent)
                    ParentToggleRow(systemImage: "bubble.left.and.bubble.right", tone: .mint,
                                    title: "Konuşalım soruları",
                                    subtitle: settings.talkPrompts
                                        ? "Okurken birkaç sayfada size bir soru önerilir. Cevabı yok, kaydedilmez."
                                        : "Kapalı",
                                    isOn: $settings.talkPrompts)
                }

                // Faz 9: sakin koleksiyon. Yıldız parayla alınmaz, alınan süs kaybolmaz.
                ParentSection(title: "Yıldız ve koleksiyon") {
                    ParentToggleRow(systemImage: "sparkles", tone: .yellow, title: "Yıldızla süs alma",
                                    subtitle: settings.collectionEnabled
                                        ? "Çocuk okuyarak kazandığı yıldızlarla kitaplığını süsler. Parayla yıldız yok."
                                        : "Kapalı. Masal çıkartmaları yine albüme girer.",
                                    isOn: $settings.collectionEnabled)
                    MPRowDivider(area: .parent)
                    ParentToggleRow(systemImage: "tortoise", tone: .mint, title: "Kolay fiyatlar",
                                    subtitle: "Süsler yarı fiyat; küçük çocuklar için uzun biriktirme olmaz.",
                                    isOn: $settings.easyPrices)
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
            .padding(.top, MPSpacing.lg)
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


}

#Preview("31 · Güvenlik") {
    ParentSafetyView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
