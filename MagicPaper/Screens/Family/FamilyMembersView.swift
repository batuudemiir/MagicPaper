import SwiftUI

/// 34 · Aile üyeleri (`AileUyeleri`, FAZ 18): kim neyi yönetebilir.
///
/// Yetişkinler rolleriyle, çocuklar yaş bandı ve masal sayısıyla. Davet eden
/// yalnızca kurucu (yönetici). Teslimdeki "bu iPad ve iPhone" satırı yok:
/// cihaz bilgisi tutulmuyor. "Apple Aile Paylaşımı" kartı abonelik ertelendiği
/// için yok. Sunucu işi `AccountService` ve `FamilyDirectory`'de.
struct FamilyMembersView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    @State private var members: [FamilyMember] = []
    @State private var invites: [FamilyInvite] = []
    @State private var loading = true
    @State private var loadFailed = false
    @State private var showInvite = false
    @State private var showJoin = false
    @State private var editing: FamilyMember?
    @State private var confirmLeave = false

    let onClose: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                ParentHeader(title: "Aile", subtitle: "Kim neyi yönetebilir", onBack: onClose)

                if account.account == nil {
                    MPNotice(kind: .info, text: "Aile üyeleri için önce giriş yap.", systemImage: "person.crop.circle")
                } else {
                    if loadFailed {
                        MPNotice(kind: .warning, text: "Aile bilgisi alınamadı. İnternet bağlantını kontrol edip yeniden dene.",
                                 systemImage: "wifi.slash")
                    }
                    adultsSection
                    if account.isFounder && !invites.isEmpty { invitesSection }
                    childrenSection
                    if account.isFounder && members.filter({ $0.uid != account.account?.uid }).isEmpty {
                        joinRow
                    }
                    if !account.isFounder { leaveRow }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if account.isFounder && account.account != nil {
                MPButton(title: "Yetişkin davet et", systemImage: "person.badge.plus", fullWidth: true) { showInvite = true }
                    .padding(.horizontal, MPSpacing.xxxl)
                    .padding(.vertical, MPSpacing.md)
                    .background(MPColor.backgroundParent)
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .onAppear { if account.pendingInviteCode != nil { showJoin = true } }
        .sheet(isPresented: $showInvite, onDismiss: { Task { await load() } }) {
            InviteAdultSheet()
        }
        .sheet(isPresented: $showJoin, onDismiss: { account.pendingInviteCode = nil }) {
            JoinFamilySheet(initialCode: account.pendingInviteCode, onJoined: {
                showJoin = false
                onClose()
            })
        }
        .confirmationDialog(editing.map { $0.displayName } ?? "", isPresented: Binding(
            get: { editing != nil }, set: { if !$0 { editing = nil } }), titleVisibility: .visible) {
            if let member = editing {
                ForEach(FamilyRole.invitable, id: \.self) { role in
                    if role != member.role {
                        Button("\(role.title) yap") { Task { await setRole(role, for: member) } }
                    }
                }
                Button("Aileden çıkar", role: .destructive) { Task { await remove(member) } }
                Button("Vazgeç", role: .cancel) {}
            }
        } message: {
            Text("Aileden çıkan kişi masalları artık göremez.")
        }
        .confirmationDialog("Aileden ayrıl", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Ayrıl", role: .destructive) { Task { await leave() } }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu ailenin masalları bu cihazdan kaldırılır. Aile verisi silinmez, aile kurucusunda kalır.")
        }
    }

    // MARK: - Bölümler

    private var adultsSection: some View {
        ParentSection(title: "Yetişkinler") {
            if loading && members.isEmpty {
                ProgressView().frame(maxWidth: .infinity, minHeight: MPSize.minTouchParent).padding(MPSpacing.md)
            }
            ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                if index > 0 { MPRowDivider(area: .parent) }
                memberRow(member)
            }
        }
    }

    /// Önce sen, sonra kurucu, sonra katılanlar.
    private var sortedMembers: [FamilyMember] {
        let me = account.account?.uid
        var list = members
        if let me, !list.contains(where: { $0.uid == me }), let role = account.role {
            list.append(FamilyMember(uid: me, displayName: "", role: role))
        }
        return list.sorted { lhs, rhs in
            if lhs.uid == me { return true }
            if rhs.uid == me { return false }
            if lhs.role == .admin { return true }
            if rhs.role == .admin { return false }
            return lhs.displayName.localizedCompare(rhs.displayName) == .orderedAscending
        }
    }

    @ViewBuilder
    private func memberRow(_ member: FamilyMember) -> some View {
        let isMe = member.uid == account.account?.uid
        let name = isMe ? "Sen" : (member.displayName.isEmpty ? member.role.title : member.displayName)
        let subtitle = "\(member.role.title) · \(member.role.summary)"
        if account.isFounder && !isMe {
            Button { editing = member } label: {
                MPListRow(systemImage: "person", tone: tone(for: member), title: name, subtitle: subtitle)
            }
            .buttonStyle(MPPressStyle(.highlight))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Rolü değiştir ya da aileden çıkar")
        } else {
            MPListRow(systemImage: "person", tone: tone(for: member), title: name, subtitle: subtitle) { EmptyView() }
                .accessibilityElement(children: .combine)
        }
    }

    private func tone(for member: FamilyMember) -> MPWorldTone {
        switch member.role {
        case .admin: return .sky
        case .parent: return .green
        case .reader: return .pink
        }
    }

    private var invitesSection: some View {
        ParentSection(title: "Bekleyen davetler") {
            ForEach(Array(invites.enumerated()), id: \.element.id) { index, invite in
                if index > 0 { MPRowDivider(area: .parent) }
                MPListRow(systemImage: "envelope", tone: .lav, title: invite.code,
                          subtitle: "\(invite.role.title) · \(FamilyCopy.expiry(invite.expiresAt))") {
                    Button("Geri al") { Task { await revoke(invite) } }
                        .mpText(.callout)
                        .foregroundStyle(MPColor.statusDanger)
                        .frame(minHeight: MPSize.minTouchParent)
                        .accessibilityLabel("\(invite.code) davetini geri al")
                }
            }
        }
    }

    private var childrenSection: some View {
        ParentSection(title: "Çocuklar") {
            if profileManager.profiles.isEmpty {
                Text("Henüz çocuk profili yok.").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .padding(MPSpacing.md)
            }
            ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                if index > 0 { MPRowDivider(area: .parent) }
                MPListRow(systemImage: "face.smiling", tone: index % 2 == 0 ? .green : .pink, title: profile.name,
                          subtitle: "\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(profile)) masal") { EmptyView() }
                    .accessibilityElement(children: .combine)
            }
        }
    }

    private func storyCount(_ profile: UserProfile) -> Int {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: profile) }.count
    }

    private var joinRow: some View {
        MPGroupedList(area: .parent) {
            ParentRowButton(systemImage: "envelope.open", tone: .lav, title: "Davet kodum var",
                            subtitle: "Başka bir ailenin masallarına katıl") { showJoin = true }
        }
    }

    private var leaveRow: some View {
        MPGroupedList(area: .parent) {
            ParentRowButton(systemImage: "rectangle.portrait.and.arrow.right", title: "Aileden ayrıl",
                            isDestructive: true) { confirmLeave = true }
        }
    }

    // MARK: - İşler

    private func load() async {
        guard let familyID = account.familyID else { loading = false; return }
        loading = true
        defer { loading = false }
        await account.refreshMembership()
        do {
            members = try await account.directory.members(of: familyID)
            invites = account.isFounder
                ? try await account.directory.invites(of: familyID).filter { $0.isValid() }
                : []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func setRole(_ role: FamilyRole, for member: FamilyMember) async {
        guard let familyID = account.familyID else { return }
        do {
            try await account.directory.setRole(role, for: member.uid, in: familyID)
            MPHaptics.success()
            app.showToast("\(member.displayName) artık \(role.title.lowercased(with: Locale(identifier: "tr_TR")))", symbol: "person")
            await load()
        } catch {
            app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
        }
    }

    private func remove(_ member: FamilyMember) async {
        guard let familyID = account.familyID else { return }
        do {
            try await account.directory.remove(uid: member.uid, from: familyID)
            app.showToast("\(member.displayName) aileden çıkarıldı", symbol: "person")
            await load()
        } catch {
            app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
        }
    }

    private func revoke(_ invite: FamilyInvite) async {
        do {
            try await account.directory.deleteInvite(code: invite.code)
            await load()
        } catch {
            app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
        }
    }

    private func leave() async {
        do {
            try await account.leaveFamily()
            onClose()
        } catch {
            app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
        }
    }
}

enum FamilyCopy {
    static let failed = "Olmadı. Bağlantını kontrol edip yeniden dene."
    static let readOnly = "Bu ailede masalları okuyabilirsin; yeni masal ebeveynlerden gelir."

    /// "5 gün kaldı", "bugün bitiyor", "süresi doldu".
    static func expiry(_ date: Date, now: Date = Date()) -> String {
        guard date > now else { return "süresi doldu" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now),
                                                   to: Calendar.current.startOfDay(for: date)).day ?? 0
        return days <= 0 ? "bugün bitiyor" : "\(days) gün kaldı"
    }
}

// MARK: - Davet

/// Kurucu bir yetişkini davet eder: rol, kendi görünen adı, sonra kod.
struct InviteAdultSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var account = AccountService.shared
    @AppStorage("mp_family_inviterName") private var inviterName = ""
    @State private var role: FamilyRole = .parent
    @State private var invite: FamilyInvite?
    @State private var working = false
    @State private var failed = false
    @State private var shareText: ShareText?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xl) {
                Text("Yetişkin davet et").mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let invite { created(invite) } else { form }
            }
            .padding(MPSpacing.screenH)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if let invite {
                    MPButton(title: "Daveti paylaş", systemImage: "square.and.arrow.up", fullWidth: true) {
                        shareText = ShareText(text: FamilyInviteCode.message(code: invite.code, inviterName: invite.inviterName))
                    }
                } else {
                    MPButton(title: "Davet oluştur", fullWidth: true, isLoading: working) { Task { await create() } }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .sheet(item: $shareText) { ShareSheet(items: [$0.text]) }
    }

    private var trimmedName: String { inviterName.trimmingCharacters(in: .whitespacesAndNewlines) }

    @ViewBuilder
    private var form: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("Ne yapabilsin?").mpText(.headline).foregroundStyle(MPColor.textPrimary)
            ForEach(FamilyRole.invitable, id: \.self) { option in
                Button { role = option } label: {
                    MPListRow(systemImage: option == role ? "checkmark.circle.fill" : "circle",
                              tone: option == role ? .lav : .gray, title: option.title,
                              subtitle: FamilyCopy.roleDetail(option)) { EmptyView() }
                        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.md))
                }
                .buttonStyle(MPPressStyle(.highlight))
                .accessibilityAddTraits(option == role ? [.isButton, .isSelected] : .isButton)
            }
        }
        MPTextField(label: "Seni nasıl görsünler?", placeholder: "Örneğin Anne, Baba, Batu",
                    text: Binding(get: { inviterName }, set: { inviterName = String($0.prefix(40)) }),
                    helper: "Davette ve aile listesinde bu ad görünür.")
        if failed {
            MPNotice(kind: .danger, text: FamilyCopy.failed, systemImage: "wifi.slash")
        }
    }

    private func created(_ invite: FamilyInvite) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            MPCard(area: .parent, padding: MPSpacing.lg) {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Davet kodu").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    Text(invite.code)
                        .font(.mp(.largeTitle)).monospaced()
                        .foregroundStyle(MPColor.textPrimary)
                        .textSelection(.enabled)
                        .accessibilityLabel(invite.code.map(String.init).joined(separator: " "))
                    Text("\(invite.role.title) · 7 gün geçerli · tek kişilik")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            Text("Davet ettiğin kişi MagicPaper'ı kendi telefonuna kurup giriş yapar, sonra bu kodu yazar. Masalları ve okuma ilerlemesini görür; çocuğun fotoğrafı hiçbir yere gitmez.")
                .mpText(.footnote).fontWeight(.regular)
                .foregroundStyle(MPColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func create() async {
        guard let familyID = account.familyID, !trimmedName.isEmpty else { return }
        working = true
        defer { working = false }
        do {
            try await account.directory.ensureFounder(familyID: familyID, displayName: trimmedName)
            invite = try await account.directory.createInvite(familyID: familyID, role: role,
                                                              inviterName: trimmedName, now: Date())
            failed = false
            MPHaptics.success()
        } catch {
            failed = true
        }
    }
}

extension FamilyCopy {
    static func roleDetail(_ role: FamilyRole) -> String {
        switch role {
        case .admin:  return "Abonelik, onaylar, güvenlik ve aile üyeleri"
        case .parent: return "Masal yazar, okur, sesini kaydeder, paylaşır"
        case .reader: return "Masalları okur ve dinler, değiştirmez"
        }
    }
}

/// Paylaşım sayfasına giden düz metin.
struct ShareText: Identifiable {
    let text: String
    var id: String { text }
}

// MARK: - Katıl

/// Davet koduyla bir aileye katılma. Hesabın kendi ailesinde veri varsa
/// silineceği açıkça söylenir.
struct JoinFamilySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared

    var initialCode: String?
    let onJoined: () -> Void

    @State private var code = ""
    @State private var name = ""
    @State private var invite: FamilyInvite?
    @State private var working = false
    @State private var message: String?
    @State private var confirmReplace = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xl) {
                Text("Bir aileye katıl").mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let invite {
                    MPCard(area: .parent, padding: MPSpacing.lg) {
                        VStack(alignment: .leading, spacing: MPSpacing.xs) {
                            Text("\(invite.inviterName) seni ailesine davet etti").mpText(.cardTitle)
                                .foregroundStyle(MPColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(invite.role.title) · \(FamilyCopy.roleDetail(invite.role))")
                                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    MPTextField(label: "Seni nasıl görsünler?", placeholder: "Örneğin Babaanne, Murat",
                                text: Binding(get: { name }, set: { name = String($0.prefix(40)) }))
                    if hasOwnData {
                        MPNotice(kind: .warning,
                                 text: "Bu hesabın kendi masalları ve çocuk profilleri silinir. Bir hesap tek bir ailede olabilir.",
                                 systemImage: "exclamationmark.triangle")
                    }
                } else {
                    MPTextField(label: "Davet kodu", placeholder: "8 harf ya da rakam",
                                text: Binding(get: { code }, set: { code = String($0.prefix(12)) }),
                                helper: "Kodu sana davet eden kişiden alırsın.")
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                if let message { MPNotice(kind: .danger, text: message, systemImage: "xmark.circle") }
            }
            .padding(MPSpacing.screenH)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if invite != nil {
                    MPButton(title: "Aileye katıl", fullWidth: true, isLoading: working) {
                        if hasOwnData { confirmReplace = true } else { Task { await join() } }
                    }
                    .disabled(trimmedName.isEmpty)
                } else {
                    MPButton(title: "Devam et", fullWidth: true, isLoading: working) { Task { await lookUp() } }
                        .disabled(FamilyInviteCode.normalize(code) == nil)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .confirmationDialog("Kendi verilerin silinsin mi?", isPresented: $confirmReplace, titleVisibility: .visible) {
            Button("Sil ve katıl", role: .destructive) { Task { await join() } }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu hesaptaki masallar ve çocuk profilleri sunucudan ve bu cihazdan silinir. Bu işlem geri alınamaz.")
        }
        .onAppear {
            if let initialCode, code.isEmpty {
                code = initialCode
                Task { await lookUp() }
            }
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var hasOwnData: Bool {
        account.isFounder && (!profileManager.profiles.isEmpty || !storyManager.stories.isEmpty)
    }

    private func lookUp() async {
        guard let normalized = FamilyInviteCode.normalize(code) else { return }
        working = true
        defer { working = false }
        do {
            guard let found = try await account.directory.invite(code: normalized), found.isValid() else {
                message = "Bu kod geçerli değil ya da süresi dolmuş. Davet edenden yeni bir kod iste."
                return
            }
            guard found.familyID != account.familyID else {
                message = "Bu davet zaten içinde olduğun aileye."
                return
            }
            message = nil
            invite = found
        } catch {
            message = FamilyCopy.failed
        }
    }

    private func join() async {
        guard let invite, !trimmedName.isEmpty else { return }
        working = true
        defer { working = false }
        do {
            try await account.joinFamily(invite, displayName: trimmedName)
            MPHaptics.success()
            dismiss()
            onJoined()
        } catch {
            message = FamilyCopy.failed
        }
    }
}
