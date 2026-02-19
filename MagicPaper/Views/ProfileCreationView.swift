import SwiftUI
import PhotosUI

/// Premium Profile Creation - Apple Design Award Level UX
struct ProfileCreationView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var profileName: String = ""
    @State private var profileAge: Int = 6
    @State private var profileType: ProfileType = .child
    @State private var selectedImage: UIImage?
    @State private var photoData: Data?
    @State private var showingImagePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Animation states
    @State private var headerScale: CGFloat = 0.8
    @State private var headerOpacity: Double = 0
    @State private var formOffset: CGFloat = 30
    @State private var formOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    @State private var buttonOpacity: Double = 0
    
    let editingProfile: UserProfile?
    
    init(editingProfile: UserProfile? = nil) {
        self.editingProfile = editingProfile
        if let profile = editingProfile {
            _profileName = State(initialValue: profile.name)
            _profileAge = State(initialValue: profile.age)
            _profileType = State(initialValue: profile.profileType)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                premiumBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Animated header
                        headerSection
                            .scaleEffect(headerScale)
                            .opacity(headerOpacity)
                        
                        // Photo section
                        photoSection
                            .offset(y: formOffset)
                            .opacity(formOpacity)
                        
                        // Form section
                        formSection
                            .offset(y: formOffset)
                            .opacity(formOpacity)
                        
                        // Action button
                        actionButton
                            .scaleEffect(buttonScale)
                            .opacity(buttonOpacity)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, photoData: $photoData)
            }
            .alert(L.error, isPresented: $showingError) {
                Button(L.ok, role: .cancel) { }
            } message: {
                Text(errorMessage)
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
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.98, green: 0.97, blue: 1.0),
                    Color(red: 0.96, green: 0.95, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated orbs
            AnimatedOrbs()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.1),
                                Color.pink.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
            }
            
            Text(editingProfile == nil ? L.addNewProfile : L.editProfile)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showingImagePicker = true
            }) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Photo or placeholder
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                    } else if let profile = editingProfile,
                              let existingImage = profileManager.getProfileImage(for: profile) {
                        Image(uiImage: existingImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .symbolEffect(.bounce, value: showingImagePicker)
                                
                                Text(L.addPhoto)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.3),
                                            Color.pink.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                )
                        )
                    }
                    
                    // Edit badge
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        .offset(x: 40, y: 40)
                }
            }
            
            Text(L.profilePhoto)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Name field
            PremiumTextField(
                title: L.profileName,
                placeholder: L.enterProfileName,
                text: $profileName,
                icon: "person.fill"
            )
            
            // Age slider
            PremiumSlider(
                title: L.profileAge,
                value: $profileAge,
                range: 3...12,
                icon: "calendar"
            )
            
            // Profile type selector
            PremiumTypeSelector(
                title: L.selectProfileType,
                selectedType: $profileType
            )
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: saveProfile) {
            HStack(spacing: 12) {
                Image(systemName: editingProfile == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text(editingProfile == nil ? L.create : L.save)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if profileName.isEmpty {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.gray.opacity(0.3))
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                }
            )
        }
        .disabled(profileName.isEmpty)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: profileName.isEmpty)
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        guard !profileName.isEmpty else {
            errorMessage = L.enterProfileName
            showingError = true
            return
        }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if let profile = editingProfile {
            profileManager.updateProfile(profile, name: profileName, age: profileAge, image: selectedImage)
        } else {
            profileManager.createProfile(name: profileName, age: profileAge, profileType: profileType, image: selectedImage)
        }
        
        dismiss()
    }
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            headerScale = 1.0
            headerOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            formOffset = 0
            formOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            buttonScale = 1.0
            buttonOpacity = 1.0
        }
    }
}

// MARK: - Premium Text Field

struct PremiumTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 17, weight: .medium))
                .focused($isFocused)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ?
                                    [.purple.opacity(0.5), .pink.opacity(0.5)] :
                                    [.white.opacity(0.5), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(
                    color: isFocused ? .purple.opacity(0.1) : .clear,
                    radius: isFocused ? 12 : 0,
                    x: 0,
                    y: isFocused ? 4 : 0
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
    }
}

// MARK: - Premium Slider

struct PremiumSlider: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(value) \(L.years)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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

// MARK: - Premium Type Selector

struct PremiumTypeSelector: View {
    let title: String
    @Binding var selectedType: ProfileType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                TypeButton(
                    type: .child,
                    isSelected: selectedType == .child
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedType = .child
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                
                TypeButton(
                    type: .parent,
                    isSelected: selectedType == .parent
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedType = .parent
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
        }
    }
}

struct TypeButton: View {
    let type: ProfileType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(
                        isSelected ?
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: type == .child ? [.blue, .purple] : [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(type.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(type == .child ? L.restrictedAccess : L.fullAccess)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: type == .child ? [.blue, .purple] : [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.white, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(
                        color: isSelected ?
                            (type == .child ? Color.blue.opacity(0.3) : Color.orange.opacity(0.3)) :
                            Color.black.opacity(0.05),
                        radius: isSelected ? 16 : 8,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected ?
                                [.clear, .clear] :
                                [.white.opacity(0.5), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animated Orbs

struct AnimatedOrbs: View {
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
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                        )
                )
                .frame(width: 300, height: 300)
                .offset(
                    x: animate ? 100 : -100,
                    y: animate ? -100 : 100
                )
                .blur(radius: 40)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.pink.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300)
                .offset(
                    x: animate ? -100 : 100,
                    y: animate ? 100 : -100
                )
                .blur(radius: 40)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    ProfileCreationView()
}
