import SwiftUI

/// Geliştirici galerisi — kürasyon ekranı (§30).
///
/// Ürün ekranı değil: burada varlıklar sayfadaki hâliyle değil, *katalog
/// kaydı* olarak görünür. Elenenler de listelenir, çünkü bir varlığın neden
/// elendiğini görmek onu düzeltmenin ilk adımı.
struct StoryDecorationGallery: View {

    @State private var category: DecorationCategory?
    @State private var type: DecorationType?
    @State private var status: DecorationStatus? = .approved
    @Environment(\.dismiss) private var dismiss

    private var entries: [StoryDecorationCatalogEntry] {
        StoryDecorationCatalog.catalogEntries.filter { e in
            (category == nil || e.category == category)
            && (type == nil || e.type == type)
            && (status == nil || e.status == status)
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            header
            filters
            Divider().opacity(0.4)
            ScrollView {
                coverage
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(entries) { entry in
                        cell(entry)
                    }
                }
                .padding(MP.S.x4)
                if entries.isEmpty {
                    Text("Bu süzgeçte varlık yok.")
                        .font(MP.F.bodySM())
                        .foregroundStyle(MP.C.textMuted)
                        .padding(.top, MP.S.x8)
                }
            }
        }
        .mpScreenBackground()
    }

    private var header: some View {
        HStack {
            MPIconButton(symbol: "xmark", label: "Kapat") { dismiss() }
            Spacer(minLength: 0)
            Text("Dekorasyon galerisi")
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.textTitle)
            Spacer(minLength: 0)
            Color.clear.frame(width: 44, height: 44)
        }
        .mpGutter()
        .padding(.top, MP.S.x1)
    }

    private var filters: some View {
        VStack(spacing: MP.S.x2) {
            chipRow(DecorationStatus.allCases.map { ($0.label, $0 == status) }) { i in
                let picked = DecorationStatus.allCases[i]
                status = (status == picked) ? nil : picked
            }
            chipRow(DecorationCategory.allCases.map { ($0.label, $0 == category) }) { i in
                let picked = DecorationCategory.allCases[i]
                category = (category == picked) ? nil : picked
            }
            chipRow(DecorationType.allCases.map { ($0.label, $0 == type) }) { i in
                let picked = DecorationType.allCases[i]
                type = (type == picked) ? nil : picked
            }
        }
        .padding(.vertical, MP.S.x2)
    }

    private func chipRow(_ items: [(String, Bool)],
                         onTap: @escaping (Int) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MP.S.x2) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    MPChip(title: item.0, isSelected: item.1) { onTap(index) }
                }
            }
            .mpGutter()
        }
    }

    /// Ortam kapsamı — sistemin gerçek darboğazı burada görünür.
    private var coverage: some View {
        VStack(alignment: .leading, spacing: MP.S.x2) {
            Text("Ortam kapsamı")
                .font(MP.F.labelSM())
                .foregroundStyle(MP.C.textMuted)
            ForEach(StoryEnvironment.allCases.filter { $0 != .neutral }) { env in
                let n = StoryDecorationCatalog.approvedCount(for: env)
                HStack(spacing: MP.S.x2) {
                    Text(env.label)
                        .font(MP.F.bodySM())
                        .foregroundStyle(MP.C.textBody)
                        .frame(width: 74, alignment: .leading)
                    GeometryReader { geo in
                        Capsule()
                            .fill(n >= 6 ? MP.C.calm : MP.C.warning)
                            .frame(width: geo.size.width * min(Double(n) / 10.0, 1),
                                   height: 6)
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 12)
                    Text("\(n)")
                        .font(MP.F.caption())
                        .foregroundStyle(MP.C.textMuted)
                        .frame(width: 22, alignment: .trailing)
                }
            }
            Text("Sayfa başına 4–7 süs için ortam başına ~6 varlık gerekiyor.")
                .font(MP.F.caption(.regular))
                .foregroundStyle(MP.C.textFaint)
        }
        .mpGutter()
        .padding(.top, MP.S.x3)
    }

    private func cell(_ entry: StoryDecorationCatalogEntry) -> some View {
        VStack(spacing: MP.S.x2) {
            ZStack {
                RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous)
                    .fill(MP.C.surfaceCard)
                if let name = entry.imageName {
                    Image(name)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(MP.C.textMuted)
                        .padding(MP.S.x2)
                } else {
                    // Elenenler uygulamaya kopyalanmadığı için önizlenemez.
                    MPIcon("eye-off", size: 20)
                        .foregroundStyle(MP.C.textFaint)
                }
            }
            .frame(height: 84)

            Text(entry.id)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(MP.C.textMuted)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(entry.status.label)
                .font(MP.F.caption())
                .foregroundStyle(color(for: entry.status))

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.system(size: 8))
                    .foregroundStyle(MP.C.textFaint)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(MP.S.x2)
        .background(
            RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous)
                .fill(MP.C.surfaceSunken.opacity(0.5))
        )
    }

    private func color(for status: DecorationStatus) -> Color {
        switch status {
        case .approved:       return MP.C.success
        case .reviewRequired: return MP.C.warning
        case .rejected:       return MP.C.danger
        }
    }
}
