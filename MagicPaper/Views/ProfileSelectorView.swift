import SwiftUI

/// Premium Profile Selector - Apple Design Award Level UX
struct ProfileSelectorView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var showingProfileCreation = false
    @State private var showingParentalGate = false
    @State private var selectedProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    
    let allowDismiss: Bool
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var cardsAppeared = false
    @Namespace private var animation
    
    init(allowDismiss: Bool = false) {
        self.allowDismiss = allowDismiss
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                premiumBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Animated header
                        headerSection
                            .opacity(headerOpacity)
                            .offset(y: headerOffset)
                        
                        // Profiles grid with staggered animation
                        profilesGrid
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if allowDismiss {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfileCreation) {
                ProfileCreationView()
            }
            .sheet(isPresented: $showingParentalGate) {
                ParentalGateView(onSuccess: {
                    if let profile = selectedProfile {
                        profileManager.switchProfile(to: profile)
                        dismiss()
                    }
                })
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            animateEntrance()
        }
    }
    
    // MARK: - Premium Background
    
    private var premiumBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.98, green: 0.97, blue: 1.0),
                    Color(red: 0.96, green: 0.95, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated mesh gradient overlay
            MeshGradientOverlay()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.1),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: cardsAppeared)
            }
            
            VStack(spacing: 8) {
                Text(L.whoIsUsing)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(L.selectOrCreateProfile)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Profiles Grid
    
    private var profilesGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 20
        ) {
            ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                PremiumProfileCard(
                    profile: profile,
                    isSelected: profileManager.currentProfile?.id == profile.id,
                    index: index,
                    appeared: cardsAppeared
                ) {
                    selectProfile(profile)
                }
            }
            
            // Add Profile Card
            PremiumAddProfileCard(
                index: profileManager.profiles.count,
                appeared: cardsAppeared
            ) {
                showingProfileCreation = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectProfile(_ profile: UserProfile) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Check if parental gate needed
        if let currentProfile = profileManager.currentProfile,
           currentProfile.profileType == .child && profile.profileType == .parent {
            selectedProfile = profile
            showingParentalGate = true
        } else {
            profileManager.switchProfile(to: profile)
            dismiss()
        }
    }
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            headerOpacity = 1
            headerOffset = 0
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            cardsAppeared = true
        }
    }
}

// MARK: - Premium Profile Card

struct PremiumProfileCard: View {
    let profile: UserProfile
    let isSelected: Bool
    let index: Int
    let appeared: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 16) {
                // Avatar with premium effects
                ZStack {
                    // Glow effect for selected
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.green.opacity(0.3),
                                        Color.green.opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 10)
                    }
                    
                    // Avatar
                    avatarView
                    
                    // Selected indicator
                    if isSelected {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 88, height: 88)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 32, height: 32)
                            )
                            .offset(x: 32, y: -32)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                
                // Info
                VStack(spacing: 8) {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Type badge
                    HStack(spacing: 4) {
                        Image(systemName: profile.profileType.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(profile.profileType.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: profile.profileType == .child ?
                                        [.blue, .purple] : [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    
                    Text("\(profile.age) \(L.years)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: isSelected ? Color.green.opacity(0.2) : Color.black.opacity(0.08),
                        radius: isSelected ? 20 : 12,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected ?
                                [.green.opacity(0.5), .green.opacity(0.2)] :
                                [.white.opacity(0.5), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(Double(index) * 0.1),
                value: appeared
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var avatarView: some View {
        Group {
            if let profileImage = ProfileManager.shared.getProfileImage(for: profile) {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: profile.profileType == .child ?
                                    [.blue.opacity(0.8), .purple.opacity(0.8)] :
                                    [.orange.opacity(0.8), .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Premium Add Profile Card

struct PremiumAddProfileCard: View {
    let index: Int
    let appeared: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.1),
                                    Color.blue.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: isHovering)
                }
                
                VStack(spacing: 8) {
                    Text(L.addProfile)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(L.new)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.3),
                                Color.blue.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(Double(index) * 0.1),
                value: appeared
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1) {
            isHovering.toggle()
        }
    }
}

// MARK: - Mesh Gradient Overlay

struct MeshGradientOverlay: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.15),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? -50 : -100, y: animate ? -50 : -100)
                .blur(radius: 60)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.15),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? 50 : 100, y: animate ? 50 : 100)
                .blur(radius: 60)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    ProfileSelectorView()
}
