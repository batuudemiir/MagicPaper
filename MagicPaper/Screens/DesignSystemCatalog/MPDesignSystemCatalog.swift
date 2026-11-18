#if DEBUG
import SwiftUI

/// Development-only gallery. Examples own transient state and never read app services.
struct MPDesignSystemCatalogView: View {
    @Environment(\.dynamicTypeSize) private var systemTextSize
    @State private var category: MPCatalogCategory
    @State private var theme: MPCatalogTheme
    @State private var textSize: MPCatalogTextSize
    @State private var lastAction = "Henüz bir işlem yok"

    /// One-time seeds for independent previews, not changing parent-owned inputs.
    init(category: MPCatalogCategory = .buttons, theme: MPCatalogTheme = .system,
         textSize: MPCatalogTextSize = .system) {
        _category = State(initialValue: category)
        _theme = State(initialValue: theme)
        _textSize = State(initialValue: textSize)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MP.S.x6) {
                introduction
                settings
                VStack(alignment: .leading, spacing: MP.S.x6) {
                    MPSectionHeader(title: category.rawValue)
                    examples
                }
                .environment(\.dynamicTypeSize, textSize.resolved(systemTextSize))
                Text("Son işlem: \(lastAction)")
                    .mpText(.footnote)
                    .foregroundStyle(MP.C.textMuted)
                    .accessibilityIdentifier("catalog.lastAction")
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.vertical, MP.S.x6)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MP.C.surfaceApp.ignoresSafeArea())
        .foregroundStyle(MP.C.textBody)
        .preferredColorScheme(theme.colorScheme)
        .environment(\.locale, Locale(identifier: "tr_TR"))
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: MP.S.x3) {
            Text("Bileşen kataloğu").mpText(.page).accessibilityAddTraits(.isHeader)
            Text("Gerçek bileşenler, geçici örnekler. Seçimler kaydedilmez.")
                .mpText(.supporting).foregroundStyle(MP.C.textMuted)
            Text("Hareketi Azalt ve VoiceOver, cihazın erişilebilirlik ayarlarından incelenir.")
                .mpText(.footnote).foregroundStyle(MP.C.textMuted)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: MP.S.x3) {
            MPCatalogPicker(title: "Kategori", selection: $category)
            MPCatalogPicker(title: "Tema", selection: $theme)
            MPCatalogPicker(title: "Örnek yazı boyutu", selection: $textSize)
        }
    }

    @ViewBuilder private var examples: some View {
        switch category {
        case .buttons: MPCatalogButtonExamples(onAction: record)
        case .controls: MPCatalogControlExamples(onAction: record)
        case .surfaces: MPCatalogSurfaceExamples(onAction: record)
        case .typography: MPCatalogTypographyExamples()
        case .states: MPCatalogStateExamples(onAction: record)
        }
    }

    private func record(_ action: String) { lastAction = action }
}

enum MPCatalogCategory: String, CaseIterable {
    case buttons = "Düğmeler", controls = "Kontroller", surfaces = "Yüzeyler"
    case typography = "Tipografi", states = "Durumlar"
}

enum MPCatalogTheme: String, CaseIterable {
    case system = "Sistem", light = "Açık", dark = "Koyu"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum MPCatalogTextSize: String, CaseIterable {
    case system = "Sistem", standard = "Standart", largest = "En büyük"

    func resolved(_ system: DynamicTypeSize) -> DynamicTypeSize {
        switch self {
        case .system: system
        case .standard: .large
        case .largest: .accessibility5
        }
    }
}

struct MPCatalogPicker<Option: RawRepresentable & CaseIterable & Hashable>: View where Option.RawValue == String {
    let title: String
    @Binding var selection: Option

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x1) {
            Text(title).mpText(.cardTitle)
            Picker(title, selection: $selection) {
                ForEach(Array(Option.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(minHeight: MP.S.tapMin)
            .accessibilityLabel(title)
        }
    }
}

/// Metadata sits outside the component; no extra hit area or corrective styling is applied.
struct MPCatalogSample<Content: View>: View {
    let title: String
    let note: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x3) {
            Text(title).mpText(.cardTitle).accessibilityAddTraits(.isHeader)
            Text(note).mpText(.footnote).foregroundStyle(MP.C.textMuted)
            content
        }
    }
}

#Preview("Katalog · Açık") {
    MPDesignSystemCatalogView(theme: .light)
        .environment(\.ragiHoldsStill, true)
}

#Preview("Katalog · Koyu") {
    MPDesignSystemCatalogView(theme: .dark)
        .environment(\.ragiHoldsStill, true)
}

#Preview("Katalog · AX5 kontroller") {
    MPDesignSystemCatalogView(category: .controls, textSize: .largest)
        .environment(\.dynamicTypeSize, .accessibility5)
        .environment(\.ragiHoldsStill, true)
}
#endif
