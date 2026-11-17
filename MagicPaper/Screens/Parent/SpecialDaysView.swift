import SwiftUI

/// Özel günler (E6, 17 Kasım 2026). Çocuk profil sayfasından itilen alt sayfa.
///
/// Dört gün, gün başına bir kayıt: isteğe bağlı tarih, "Yeni kardeş" için
/// isteğe bağlı olarak Masal ailem'den bir kardeş. Ad yazdırılmaz, serbest
/// metin yok; ekleme odanın içinde, kaldırma kapıdan geçer. Ragi yok.
struct SpecialDaysView: View {
    let profile: UserProfile
    var store: SpecialDayStore = SpecialDayStore()

    @EnvironmentObject private var app: MPAppState
    @State private var days: [SpecialDay] = []
    @State private var siblings: [FamilyCharacter] = []
    @State private var pendingRemoval: SpecialDayKind?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: SpecialDayCopy.title, subtitle: profile.name,
                               onBack: { app.router.parentRoute = nil })

                Text(SpecialDayCopy.intro(profile.name))
                    .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if days.isEmpty {
                    MPGroupedList(area: .parent) {
                        MPListRow(systemImage: "calendar", tone: .peach, title: SpecialDayCopy.emptyTitle,
                                  subtitle: SpecialDayCopy.emptySubtitle) { EmptyView() }
                    }
                }

                ForEach(days) { day in
                    ParentSection(title: day.kind.title) { rows(for: day) }
                }

                let missing = SpecialDayKind.allCases.filter { kind in !days.contains { $0.kind == kind } }
                if !missing.isEmpty {
                    ParentSection(title: SpecialDayCopy.addSection) {
                        ForEach(Array(missing.enumerated()), id: \.element) { index, kind in
                            if index > 0 { MPRowDivider(area: .parent) }
                            ParentRowButton(systemImage: kind.symbol, tone: .peach, title: kind.title,
                                            subtitle: SpecialDayCopy.addSubtitle) {
                                save(SpecialDay(kind: kind))
                            }
                            .accessibilityLabel(SpecialDayCopy.addAccessibility(kind))
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .onAppear(perform: reload)
        .confirmationDialog(
            SpecialDayCopy.removeTitle,
            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
            titleVisibility: .visible
        ) {
            Button(SpecialDayCopy.removeButton, role: .destructive) {
                guard let kind = pendingRemoval else { return }
                app.router.requestGate { remove(kind) }
            }
            Button(SpecialDayCopy.cancel, role: .cancel) {}
        } message: {
            Text(SpecialDayCopy.removeMessage)
        }
    }

    @ViewBuilder
    private func rows(for day: SpecialDay) -> some View {
        ParentToggleRow(systemImage: "calendar", tone: .peach, title: SpecialDayCopy.dateToggle,
                        subtitle: SpecialDayCopy.dateHint, isOn: hasDate(day))
        if day.day != nil {
            MPRowDivider(area: .parent)
            MPListRow(systemImage: "calendar.badge.clock", tone: .peach, title: SpecialDayCopy.dateRow) {
                DatePicker(SpecialDayCopy.dateRow, selection: date(day), displayedComponents: .date)
                    .labelsHidden()
                    .accessibilityLabel(SpecialDayCopy.dateAccessibility(day.kind))
            }
        }
        if day.kind == .newSibling {
            MPRowDivider(area: .parent)
            MPListRow(systemImage: "person.2", tone: .peach, title: SpecialDayCopy.siblingRow,
                      subtitle: siblings.isEmpty ? SpecialDayCopy.siblingNone : nil) {
                if !siblings.isEmpty {
                    Picker(SpecialDayCopy.siblingRow, selection: sibling(day)) {
                        Text(SpecialDayCopy.siblingUnchosen).tag(UUID?.none)
                        ForEach(siblings) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    .labelsHidden()
                    .accessibilityLabel(SpecialDayCopy.siblingRow)
                }
            }
        }
        MPRowDivider(area: .parent)
        ParentRowButton(systemImage: "trash", title: SpecialDayCopy.removeButton, isDestructive: true) {
            pendingRemoval = day.kind
        }
        .accessibilityLabel(SpecialDayCopy.removeAccessibility(day.kind))
    }

    // MARK: - Bindings

    private func hasDate(_ day: SpecialDay) -> Binding<Bool> {
        Binding(
            get: { day.day != nil },
            set: { on in
                var next = day
                next.day = on ? SpecialDayWindow.dayString(Date()) : nil
                save(next)
            })
    }

    private func date(_ day: SpecialDay) -> Binding<Date> {
        Binding(
            get: { day.day.flatMap(Self.date(from:)) ?? Date() },
            set: { picked in
                var next = day
                next.day = SpecialDayWindow.dayString(picked)
                save(next)
            })
    }

    private func sibling(_ day: SpecialDay) -> Binding<UUID?> {
        Binding(
            get: { day.siblingID.flatMap { id in siblings.contains { $0.id == id } ? id : nil } },
            set: { id in
                var next = day
                next.siblingID = id
                save(next)
            })
    }

    /// Noon of the stored day, so a time zone change does not move it a day.
    private static func date(from stored: String) -> Date? {
        let parts = stored.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar(identifier: .gregorian).date(
            from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    // MARK: - Store

    private func reload() {
        days = store.days(for: profile.id)
        siblings = FamilyCharacterStore().characters(for: profile.id).filter { $0.relation.kind == .sibling }
    }

    private func save(_ day: SpecialDay) {
        store.save(day, for: profile.id)
        reload()
    }

    private func remove(_ kind: SpecialDayKind) {
        store.delete(kind, for: profile.id)
        reload()
        app.showToast(SpecialDayCopy.removedToast, symbol: "checkmark")
    }
}

/// Özel günler ekranının ve satırının metinleri. Taslak, Batuhan okuyacak.
enum SpecialDayCopy {
    static let rowTitle = "Özel günler"
    static let rowSubtitle = "Doğum günü, okulun ilk günü, yeni kardeş, ilk düşen diş"
    static let title = "Özel günler"
    static func intro(_ name: String) -> String {
        "\(name) için yaklaşan ya da yeni geçen bir özel gün ekleyin. O günün çevresinde masal yazarken bir çip olarak görünür."
    }
    static let emptyTitle = "Henüz özel gün yok"
    static let emptySubtitle = "Aşağıdan bir gün ekleyebilirsiniz."
    static let addSection = "Ekle"
    static let addSubtitle = "Ekle"
    static func addAccessibility(_ kind: SpecialDayKind) -> String { "\(kind.title) ekle" }
    static let dateToggle = "Tarihi var"
    static let dateHint = "Tarihsiz gün her zaman görünür; tarihli gün 14 gün önce ile 7 gün sonra arasında."
    static let dateRow = "Gün"
    static func dateAccessibility(_ kind: SpecialDayKind) -> String { "\(kind.title) günü" }
    static let siblingRow = "Kardeşi"
    static let siblingUnchosen = "Seçilmedi"
    static let siblingNone = "Masal ailem'de kardeş yok; masal \"küçük kardeşi\" der."
    static let removeTitle = "Özel günü kaldır"
    static let removeButton = "Kaldır"
    static func removeAccessibility(_ kind: SpecialDayKind) -> String { "\(kind.title) kaldır" }
    static let removeMessage = "Bu gün listeden kalkar. Yazılmış masallar kitaplıkta kalır."
    static let cancel = "Vazgeç"
    static let removedToast = "Özel gün kaldırıldı"
    /// Masal yazmada çiplerin üstündeki başlık.
    static let stepSection = "Özel bir gün"
    static let stepHint = "Seçersen masal o gün için yazılır."
}
