import SwiftUI

// MARK: - 24 · Okuma ayarları (`OkumaAyarlari`)

/// Okuyucunun kendi sayfası: tema, yazı boyutu, kim okusun, okuma hızı,
/// sesli okuma. Okuyucu tam ekran sunulduğu için onun içinden `.sheet` ile
/// açılır. "Kim okusun?" yalnızca Kendi sesin (FAZ 18) bayrağı açıkken.
struct ReaderSettingsSheet: View {
    /// Bu masalın ailenin sesiyle kaydı var mı (FAZ 18).
    var hasFamilyVoice = false
    var textLayout: ReaderTextLayout = .paragraphs
    let onClose: () -> Void

    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    /// Ses, hız ve titreşim "Daha fazla"nın altında.
    @State private var showsMore = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private let sizes = MP.ReadSize.allCases

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xl) {
                HStack(spacing: MP.S.x3) {
                    Text("Okuma ayarları").mpText(.section).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: MP.S.x2)
                    MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat",
                                   size: MP.S.tapMin, action: onClose)
                }

                readingSample

                group("Yazı") {
                    HStack {
                        Text("Yazı boyutu").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        Spacer()
                        Text(app.readSize.rawValue).mpText(.footnote).fontWeight(.bold)
                            .foregroundStyle(MPColor.actionPrimary)
                    }
                    sizeSlider
                    Text("Satır aralığı").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    MPSegmented(options: MP.ReadSpacing.allCases.map { ($0, $0.label) },
                                selection: Binding(get: { settings.readSpacing },
                                                   set: { settings.readSpacing = $0 }),
                                track: MPColor.backgroundSunken)
                    easyReadingRow
                }

                group("Kâğıt") {
                    paperSwatches
                    if settings.autoNight && MPBedtime.isBedtime(settings: settings) {
                        Text("Şu an uyku saati: kâğıt Gece.")
                            .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    }
                    MPGroupedList(area: .kid) {
                        toggleRow(icon: "circle.grid.3x3", tone: .peach, title: "Kâğıt dokusu",
                                  subtitle: nil, isOn: $settings.paperGrain)
                        MPRowDivider(area: .kid)
                        toggleRow(icon: "moon", tone: .lav, title: "Uyku saatinde Gece",
                                  subtitle: "Uyku saatinden sonra kâğıt kendiliğinden kararır",
                                  isOn: $settings.autoNight)
                    }
                }

                moreSection
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.md)
            .padding(.bottom, MPSpacing.lg)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: "Okumaya dön", fullWidth: true, action: onClose)
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.md)
                .background(MPColor.backgroundKid)
        }
        // Yarım sayfa açılır: masal arkada görünür kalır, kâğıt ve yazı
        // değişince arkada hemen döner. Kalan ayarlar için yukarı çekilir.
        // Arka plan kâğıt, cam değil (CLAUDE.md, Derinlik: sheet cam olmaz).
        .mpSheet(.half)
    }

    /// Ayar değişince masalın sayfasıyla aynı tipografi hemen görünür.
    /// Yükseklik sabit değil; en büyük yazıda örnek ve ayarlar kaydırılır.
    private var readingSample: some View {
        let theme = settings.readingTheme(chosen: app.readTheme)
        let points = (textLayout == .breath ? app.readSize.larger : app.readSize).points
        let gap = textLayout == .breath ? max(settings.readSpacing.factor, MP.ReadSpacing.rahat.factor) : settings.readSpacing.factor
        return VStack(alignment: .leading, spacing: MP.S.x2) {
            Text("Yazı önizlemesi").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            Text("Birlikte okuyalım.\nBir sayfa daha.")
                .font(MP.F.read(points))
                .lineSpacing(points * gap)
                .tracking(ReaderText.tracking(points, easyReading: settings.easyReading))
                .foregroundStyle(theme.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MP.S.x2)
                .background(theme.paper)
                .accessibilityLabel("Okuma yazısı örneği. Birlikte okuyalım. Bir sayfa daha.")
        }
    }

    private var easyReadingRow: some View {
        Toggle(isOn: $settings.easyReading) {
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text("Kolay okuma").mpText(.supporting).fontWeight(.heavy)
                    .foregroundStyle(MPColor.textPrimary)
                Text("Harflerin arası açılır").mpText(.footnote)
                    .foregroundStyle(MPColor.textSecondary)
            }
        }
        .toggleStyle(MPSwitchStyle())
        .frame(minHeight: MP.S.tapMin)
    }

    // MARK: - Kâğıt

    /// Beş kâğıt, her biri "Aa" yazan küçük bir sayfa. Seçili olan çerçeveli
    /// ve adı kalın: seçim yalnızca renkle verilmez.
    private var paperSwatches: some View {
        LazyVGrid(columns: typeSize.isAccessibilitySize
                  ? [GridItem(.adaptive(minimum: MP.S.x10 * 2), spacing: MP.S.x2)]
                  : Array(repeating: GridItem(.flexible(), spacing: MP.S.x2), count: 5),
                  spacing: MPSpacing.sm) {
            ForEach(MP.ReadTheme.allCases) { theme in
                let on = app.readTheme == theme
                Button { app.readTheme = theme } label: {
                    VStack(spacing: MPSpacing.xxs) {
                        Text("Aa")
                            .font(MP.F.bodyLG(.bold))
                            .foregroundStyle(theme.foreground)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: MP.S.tapMin)
                            .padding(.vertical, MP.S.x1)
                            .background(theme.paper, in: RoundedRectangle(cornerRadius: MPRadius.sm))
                            .overlay(RoundedRectangle(cornerRadius: MPRadius.sm)
                                .strokeBorder(on ? MPColor.actionPrimary : MPColor.borderKid,
                                              lineWidth: on ? 2 : 1))
                            .overlay(alignment: .bottomTrailing) {
                                if on {
                                    MPIcon("checkmark", size: MP.G.xs, weight: .heavy)
                                        .foregroundStyle(theme.highlight)
                                        .padding(MP.S.x1)
                                        .accessibilityHidden(true)
                                }
                            }
                        Text(theme.label)
                            .font(MP.F.caption(on ? .heavy : .semibold))
                            .foregroundStyle(on ? MPColor.textPrimary : MPColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel("\(theme.label) kâğıt")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    // MARK: - Yazı

    /// Dört duraklı sürgü: iki ucunda küçük ve büyük "A".
    private var sizeSlider: some View {
        HStack(spacing: MPSpacing.md) {
            Text("A").font(MP.F.labelSM(.heavy)).foregroundStyle(MPColor.textPrimary)
                .accessibilityHidden(true)
            Slider(value: Binding(
                get: { Double(sizes.firstIndex(of: app.readSize) ?? 1) },
                set: { value in
                    let size = sizes[min(sizes.count - 1, max(0, Int(value.rounded())))]
                    guard size != app.readSize else { return }
                    app.readSize = size
                    settings.readSize = size
                    settings.readSizeChosen = true
                }),
                   in: 0...Double(sizes.count - 1), step: 1)
                .tint(MPColor.actionPrimary)
                .accessibilityLabel("Yazı boyutu")
                .accessibilityValue(app.readSize.rawValue)
            Text("A").font(MP.F.displaySM()).foregroundStyle(MPColor.textPrimary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: MP.S.tapMin)
    }

    // MARK: - Daha fazla

    @ViewBuilder
    private var moreSection: some View {
        Button { showsMore.toggle() } label: {
            HStack {
                Text("Daha fazla").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                Spacer()
                MPIcon("chevron.down", size: MP.G.sm, weight: .bold)
                    .foregroundStyle(MPColor.textSecondary)
                    .rotationEffect(.degrees(showsMore ? 180 : 0))
            }
            .frame(minHeight: MP.S.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel("Daha fazla ayar")
        .accessibilityValue(showsMore ? "Açık" : "Kapalı")
        .animation(MP.M.gated(MP.M.easeOut), value: showsMore)

        if showsMore {
            // "Ailenin sesi" yalnızca bu masalın kaydı varsa (24 · teslim notu).
            if hasFamilyVoice {
                group("Kim okusun?") {
                    MPSegmented(options: [(false, "Masal anlatıcısı"), (true, "Ailenin sesi")],
                                selection: $settings.familyVoice)
                }
            }

            group("Okuma hızı") {
                MPSegmented(options: MPSpeechRate.allCases.map { ($0, $0.label) },
                            selection: Binding(get: { settings.speechRate },
                                               set: { settings.speechRate = $0 }))
            }

            MPGroupedList(area: .kid) {
                toggleRow(icon: "speaker.wave.2", tone: .sky, title: "Sesli okuma",
                          subtitle: "Sayfa açılınca kendiliğinden okunur", isOn: $settings.readAloud)
                MPRowDivider(area: .kid)
                toggleRow(icon: "sparkles", tone: .lav, title: "Dokunsal geri bildirim",
                          subtitle: "Sayfa çevrilince hafif bir dokunuş", isOn: $settings.haptics)
                MPRowDivider(area: .kid)
                toggleRow(icon: "music.note", tone: .peach, title: "Sesler",
                          subtitle: "Masal sonunda ve sayfa çevrilince kısa sesler. Uyku vaktinde çalmaz.", isOn: $settings.sounds)
            }
        }
    }

    private func toggleRow(icon: String, tone: MPWorldTone, title: String, subtitle: String?,
                           isOn: Binding<Bool>) -> some View {
        MPListRow(systemImage: icon, tone: tone, title: title, subtitle: subtitle) {
            Toggle(isOn: isOn) { EmptyView() }
                .toggleStyle(MPSwitchStyle()).fixedSize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isOn.wrappedValue ? "Açık" : "Kapalı")
        .accessibilityAction { isOn.wrappedValue.toggle() }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
            content()
        }
    }
}

