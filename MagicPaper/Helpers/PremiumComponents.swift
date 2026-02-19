import SwiftUI

// MARK: - Reading Preferences (Shared across app)

enum TextSize: String, CaseIterable, RawRepresentable {
    case small = "Küçük"
    case normal = "Normal"
    case large = "Büyük"
    case extraLarge = "Çok Büyük"
    
    var multiplier: CGFloat {
        switch self {
        case .small: return 0.85
        case .normal: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "textformat.size.smaller"
        case .normal: return "textformat.size"
        case .large: return "textformat.size.larger"
        case .extraLarge: return "textformat.size.larger"
        }
    }
}

enum ReadingTheme: String, CaseIterable, RawRepresentable {
    case light = "Beyaz"
    case sepia = "Sepia"
    case dark = "Gece"
    
    func backgroundColor(highContrast: Bool) -> Color {
        switch self {
        case .light: 
            return highContrast ? .white : Color(.systemBackground)
        case .sepia: 
            return highContrast ? Color(red: 1.0, green: 0.98, blue: 0.92) : Color(red: 0.97, green: 0.94, blue: 0.87)
        case .dark: 
            return highContrast ? .black : Color(red: 0.11, green: 0.11, blue: 0.12)
        }
    }
    
    func textColor(highContrast: Bool) -> Color {
        switch self {
        case .light: 
            return highContrast ? .black : .primary
        case .sepia: 
            return highContrast ? Color(red: 0.1, green: 0.05, blue: 0.0) : Color(red: 0.2, green: 0.15, blue: 0.1)
        case .dark: 
            return highContrast ? .white : Color(red: 0.9, green: 0.9, blue: 0.9)
        }
    }
    
    func shadowOpacity(highContrast: Bool) -> Double {
        return highContrast ? 0.3 : 0.1
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .sepia: return "book.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum LineSpacingOption: String, CaseIterable, RawRepresentable {
    case compact = "Sıkı"
    case normal = "Normal"
    case relaxed = "Rahat"
    case loose = "Geniş"
    
    var spacing: CGFloat {
        switch self {
        case .compact: return 4
        case .normal: return 8
        case .relaxed: return 12
        case .loose: return 16
        }
    }
}

// MARK: - Premium Design System
// Apple Design Award 2026 Level Components

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    
    init(padding: CGFloat = 20, cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Inner top highlight
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Premium Card

struct PremiumCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    
    init(padding: CGFloat = 20, cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Premium Button

struct PremiumButton: View {
    let title: String
    let icon: String?
    let gradient: [Color]
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var isPressed = false
    @State private var shimmerPhase: CGFloat = -300
    
    init(
        title: String,
        icon: String? = nil,
        gradient: [Color] = [.purple, .pink],
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            isDisabled ?
                                LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                        )
                    
                    // Shimmer sweep
                    if !isDisabled {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.25), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 120)
                        .offset(x: shimmerPhase)
                        .clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: isDisabled ? .clear : gradient[0].opacity(0.45),
                    radius: isPressed ? 8 : 20,
                    x: 0,
                    y: isPressed ? 4 : 10
                )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            guard !isDisabled else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.linear(duration: 1.2)) {
                    shimmerPhase = 400
                }
            }
        }
    }
}

// MARK: - Premium Background

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.98, green: 0.97, blue: 1.0),
                    Color(red: 0.96, green: 0.95, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            AnimatedMeshGradient()
        }
        .ignoresSafeArea()
    }
}

struct AnimatedMeshGradient: View {
    @State private var animate = false
    @State private var animate2 = false
    
    var body: some View {
        ZStack {
            // Orb 1 — purple top-left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.14), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: animate ? -60 : -120, y: animate ? -80 : -120)
                .blur(radius: 50)
            
            // Orb 2 — pink bottom-right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pink.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 450, height: 450)
                .offset(x: animate ? 80 : 120, y: animate ? 100 : 140)
                .blur(radius: 55)
            
            // Orb 3 — blue-teal center-right (new)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.09), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: animate2 ? 40 : -20, y: animate2 ? -20 : 60)
                .blur(radius: 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate = true
            }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate2 = true
            }
        }
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    let text: String
    let icon: String?
    let colors: [Color]
    
    init(text: String, icon: String? = nil, colors: [Color] = [.purple, .pink]) {
        self.text = text
        self.icon = icon
        self.colors = colors
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - Premium Section Header

struct PremiumSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Premium Empty State

struct PremiumEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var floating = false
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(floating ? 1.08 : 0.95)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.12), .pink.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: floating ? -6 : 6)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    floating = true
                }
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PremiumButton(
                    title: actionTitle,
                    icon: "plus.circle.fill",
                    action: action
                )
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Spring Press Style

struct SpringPressStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Bounce Animation

struct BounceAnimation: ViewModifier {
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.05 : 1.0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
    }
}

extension View {
    func bounceAnimation() -> some View {
        modifier(BounceAnimation())
    }
}

// MARK: - Appear Animation

struct AppearAnimation: ViewModifier {
    @State private var appeared = false
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimation(delay: delay))
    }
}

// MARK: - Pulsing Glow

struct PulsingGlow: ViewModifier {
    let color: Color
    @State private var pulse = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulse ? 0.6 : 0.2), radius: pulse ? 16 : 6, x: 0, y: 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

extension View {
    func pulsingGlow(color: Color) -> some View {
        modifier(PulsingGlow(color: color))
    }
}


// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Reading Settings View

struct ReadingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    @Binding var textSize: TextSize
    @Binding var readingTheme: ReadingTheme
    @Binding var lineSpacing: LineSpacingOption
    @Binding var autoPlayEnabled: Bool
    
    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }
    
    var body: some View {
        NavigationView {
            List {
                // High Contrast Info (if enabled)
                if isHighContrast {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Yüksek Kontrast Aktif")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Daha iyi okunabilirlik için renkler optimize edildi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Text Size Section
                Section {
                    ForEach(TextSize.allCases, id: \.self) { size in
                        Button(action: {
                            textSize = size
                        }) {
                            HStack {
                                Image(systemName: size.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.purple)
                                    .frame(width: 32)
                                
                                Text(size.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if textSize == size {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Yazı Boyutu")
                } footer: {
                    Text("Hikaye metninin boyutunu ayarlayın")
                }
                
                // Reading Theme Section
                Section {
                    ForEach(ReadingTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            readingTheme = theme
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(theme.backgroundColor(highContrast: isHighContrast))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(isHighContrast ? 0.5 : 0.3), lineWidth: isHighContrast ? 2 : 1)
                                        )
                                    
                                    Image(systemName: theme.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.textColor(highContrast: isHighContrast))
                                }
                                
                                Text(theme.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if readingTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Okuma Teması")
                } footer: {
                    Text(isHighContrast ? 
                         "Gözlerinize uygun arka plan rengini seçin. Yüksek kontrast modu aktif." : 
                         "Gözlerinize uygun arka plan rengini seçin")
                }
                
                // Line Spacing Section
                Section {
                    ForEach(LineSpacingOption.allCases, id: \.self) { spacing in
                        Button(action: {
                            lineSpacing = spacing
                        }) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 20))
                                    .foregroundColor(.purple)
                                    .frame(width: 32)
                                
                                Text(spacing.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if lineSpacing == spacing {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Satır Aralığı")
                } footer: {
                    Text("Satırlar arasındaki boşluğu ayarlayın")
                }
                
                // Auto Play Section
                Section {
                    Toggle(isOn: $autoPlayEnabled) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Otomatik Oynat")
                                    .foregroundColor(.primary)
                                
                                Text("Her 8 saniyede bir sayfa")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.orange)
                } footer: {
                    Text("Hikaye sayfaları otomatik olarak ilerler")
                }
                
                // Preview Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Önizleme")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: lineSpacing.spacing) {
                            Text("Bir zamanlar uzak bir diyarda,")
                                .font(.system(size: 17 * textSize.multiplier))
                            Text("küçük bir kahraman yaşardı.")
                                .font(.system(size: 17 * textSize.multiplier))
                            Text("Maceraları efsanelere konu oldu.")
                                .font(.system(size: 17 * textSize.multiplier))
                        }
                        .foregroundColor(readingTheme.textColor(highContrast: isHighContrast))
                        .multilineTextAlignment(.leading)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(readingTheme.backgroundColor(highContrast: isHighContrast))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isHighContrast ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 1)
                                )
                        )
                        
                        if isHighContrast {
                            Text("✓ Yüksek kontrast ile optimize edildi")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Önizleme")
                }
            }
            .navigationTitle("Okuma Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bitti") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
