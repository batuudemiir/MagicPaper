import SwiftUI
import UIKit

/// Destek penceresi (vizyon planı düzen 12): bize yaz, adresi kopyala, sık
/// sorulanlar ve sürüm bilgisi. Mail kurulu değilse "Bize yaz" adresi kopyalar;
/// hiçbir şey sessizce boşa düşmez. Ebeveyn alanı: Ragi yok.
struct SupportSheet: View {
    static let email = "support@magicpaperkids.com"

    @EnvironmentObject private var app: MPAppState
    let onClose: () -> Void

    /// Yalnızca doğru olanlar (Faz 8 güven bloğu ile aynı dil).
    private let questions: [(String, String)] = [
        ("Masallar nerede yazılıyor?",
         "Masallar cihazda, çocuklar için yazılmış parçalardan kurulur. Masal metni için internet gerekmez."),
        ("Yıldızlar satın alınır mı?",
         "Hayır. Yıldızlar yalnızca okuyarak kazanılır, parayla alınmaz ve kaybolmaz."),
        ("Hatırlatma ne zaman gelir?",
         "Seçtiğiniz saatte, akşamları. Masal okunan akşam hatırlatma gelmez."),
        ("Verilerimizi nasıl sileriz?",
         "Ayarlar'ın en altındaki \"Tüm verileri sil\" çocuk profillerini, masalları ve kayıtları siler.")
    ]

    var body: some View {
        MPSheet(title: "Destek", onClose: onClose) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                ParentSection(title: "Bize ulaşın") {
                    ParentRowButton(systemImage: "message", tone: .lav, title: "Bize yaz",
                                    subtitle: Self.email, action: write)
                    MPRowDivider(area: .parent)
                    ParentRowButton(systemImage: "doc.on.doc", tone: .sky, title: "Adresi kopyala",
                                    action: copy)
                }
                ParentSection(title: "Sık sorulanlar") {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, item in
                        if index > 0 { MPRowDivider(area: .parent) }
                        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                            Text(item.0).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                            Text(item.1).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(MPSpacing.md)
                        .accessibilityElement(children: .combine)
                    }
                }
                Text(versionLine)
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .textSelection(.enabled)
            }
        } footer: { EmptyView() }
        .mpSheet(.full, area: .parent)
    }

    /// "MagicPaper 1.2 (45) · iOS 18.2": destek yazışmasında ilk sorulan.
    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "MagicPaper \(version) (\(build)) · iOS \(UIDevice.current.systemVersion)"
    }

    private func write() {
        let subject = "MagicPaper destek".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = versionLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(Self.email)?subject=\(subject)&body=\(body)") else {
            copy()
            return
        }
        // Mail kurulu değilse açılmaz; o zaman adres kopyalanır.
        UIApplication.shared.open(url) { opened in
            if !opened { Task { @MainActor in copy() } }
        }
    }

    private func copy() {
        UIPasteboard.general.string = Self.email
        MPHaptics.success()
        app.showToast("Adres kopyalandı", symbol: "doc.on.doc")
    }
}
