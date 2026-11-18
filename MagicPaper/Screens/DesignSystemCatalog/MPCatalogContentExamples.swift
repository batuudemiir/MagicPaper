#if DEBUG
import SwiftUI

struct MPCatalogSurfaceExamples: View {
    let onAction: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            cards
            rows
            headers
            notices
        }
    }

    private var cards: some View {
        MPCatalogSample(title: "MPCard", note: "Çocuk / ebeveyn yüzeyleri") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPCard { Text("Çocuk kartı").mpText(.body) }
                MPCard(area: .parent) { Text("Ebeveyn kartı").mpText(.body) }
            }
        }
    }

    private var rows: some View {
        MPCatalogSample(title: "Liste satırları", note: "MPListRow salt sunumdur; MPRowButton eylemdir.") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPListRow(systemImage: "book", title: "Başlık", subtitle: "İkincil açıklama")
                MPRowButton(systemImage: "book", title: "Dokunulabilir satır", subtitle: "Yalnız yerel sonuç gösterir",
                            action: { onAction("Liste satırı") }) { MPChevron() }
                MPRowButton(systemImage: "trash", title: "Silme satırı örneği", isDestructive: true) {
                    onAction("Silme satırı örneği; veri silinmedi")
                }
            }
        }
    }

    private var headers: some View {
        MPCatalogSample(title: "MPSectionHeader", note: "Başlık / sayaç / bağlantı / ebeveyn alanı") {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                MPSectionHeader(title: "Bölüm başlığı", subtitle: "Kısa bölüm açıklaması")
                MPSectionHeader(title: "Sayaç örneği", note: "3 / 8")
                MPSectionHeader(title: "Bağlantı örneği", link: ("Tümü", { onAction("Bölüm bağlantısı") }))
                MPSectionHeader(title: "Ebeveyn bölümü", area: .parent)
            }
        }
    }

    private var notices: some View {
        MPCatalogSample(title: "MPNotice", note: "info / success / warning / danger; durum metinde de belirtilir.") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPNotice(kind: .info, text: "Bilgi mesajı örneği", systemImage: "info.circle")
                MPNotice(kind: .success, text: "Başarılı işlem örneği", systemImage: "checkmark.circle")
                MPNotice(kind: .warning, text: "Uyarı mesajı örneği", systemImage: "exclamationmark.triangle")
                MPNotice(kind: .danger, text: "Hata mesajı örneği", systemImage: "exclamationmark.circle")
            }
        }
    }
}

struct MPCatalogTypographyExamples: View {
    private var roles: [MPCatalogTextRole] {
        MPTextStyle.allCases.map { MPCatalogTextRole(style: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            ForEach(roles, id: \.name) { role in
                MPCatalogSample(title: role.name, note: "\(role.style.family) · \(Int(role.style.size)) pt · temel ölçü") {
                    Text("Birlikte güzel bir gün")
                        .mpText(role.style)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct MPCatalogTextRole {
    let style: MPTextStyle
    var name: String { String(describing: style) }
}

struct MPCatalogStateExamples: View {
    let onAction: (String) -> Void
    @State private var scene = MPCatalogStateScene.empty

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            MPCatalogPicker(title: "Durum örneği", selection: $scene)
            MPCatalogSample(title: "MPStateView", note: "Aynı anda tek durum ve tek Ragi gösterilir.") {
                MPStateView(mascot: scene == .empty ? .reading : .surprised,
                            title: scene == .empty ? "Henüz bir şey yok" : "Bu adım tamamlanamadı",
                            message: scene == .empty ? "Burada bir boş durum örneği görüyorsun." : "Yeniden deneme eylemini burada inceleyebilirsin.") {
                    MPButton(title: scene == .empty ? "Örnek eylem" : "Yeniden dene", fullWidth: true) {
                        onAction(scene == .empty ? "Boş durum eylemi" : "Hata durumu eylemi")
                    }
                }
            }
        }
    }
}

private enum MPCatalogStateScene: String, CaseIterable {
    case empty = "Boş", error = "Hata"
}
#endif
