import SwiftUI

struct CreateStoryView: View {
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var aiService = AIService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var adManager = AdMobManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var childName = ""
    @State private var age = ""
    @State private var selectedGender = Gender.other
    @State private var selectedTheme = StoryTheme.fantasy
    @AppStorage("defaultLanguage") private var defaultLanguageRaw = "tr"
    @State private var selectedLanguage = StoryLanguage.turkish
    @State private var customTitle = ""
    @State private var selectedPhoto: UIImage?
    @State private var photoData: Data?
    @State private var uploadedPhotoURL: String? // New: Store Firebase URL
    @State private var scenePhoto: UIImage?
    @State private var scenePhotoData: Data?
    @State private var showingImagePicker = false
    @State private var showingScenePicker = false
    @State private var isUploadingPhoto = false // New: Track upload state
    
    @State private var isGenerating = false
    @State private var generationProgress = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Bilgi"
    @State private var showingPremiumSheet = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        photoSection
                        basicInfoSection
                        themeSection
                        generateButton
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, DeviceHelper.horizontalPadding)
                    .padding(.top)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom + 20, 40))
                    .frame(minHeight: geometry.size.height)
                }
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        // İkon renklerine uygun gradient
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98), // Mor
                                Color(red: 0.85, green: 0.35, blue: 0.85), // Pembe
                                Color(red: 1.0, green: 0.45, blue: 0.55)   // Kırmızı-pembe
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.08)
                        
                        // Beyaz overlay
                        Color.white.opacity(0.92)
                    }
                    .ignoresSafeArea()
                )
            }
            .navigationTitle(localizationManager.localized(.createStory))
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack) // iPad'de split view'ı devre dışı bırak
        .onAppear {
            // Varsayılan dili yükle
            selectedLanguage = StoryLanguage(rawValue: defaultLanguageRaw) ?? .turkish
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            SimpleSubscriptionView()
        }
        .overlay(
            loadingOverlay
        )
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localized(.childPhoto))
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(localizationManager.localized(.photoDescription))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingImagePicker = true
            }) {
                if let selectedPhoto = selectedPhoto {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedPhoto)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Upload progress overlay
                        if isUploadingPhoto {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                        Text("Yükleniyor...")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                    }
                                )
                        }
                        
                        // Success indicator
                        if uploadedPhotoURL != nil && !isUploadingPhoto {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                )
                                .padding(12)
                        }
                        
                        // Change photo button
                        if !isUploadingPhoto {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.indigo)
                                            .frame(width: 36, height: 36)
                                    )
                            }
                            .padding(12)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.indigo)
                        
                        VStack(spacing: 4) {
                            Text(localizationManager.localized(.addPhoto))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(localizationManager.localized(.photoDescription))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.indigo.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundColor(.indigo.opacity(0.3))
                            )
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedPhoto, photoData: $photoData)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(localizationManager.localized(.basicInfo))
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // İsim
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localized(.name))
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField(localizationManager.localized(.childName), text: $childName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Yaş
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localized(.age))
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField(localizationManager.localized(.age) + " (1-12)", text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Cinsiyet - Modern Segmented Control
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localized(.gender))
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedGender = gender
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: gender.icon)
                                        .font(.system(size: 18))
                                    Text(gender.displayName)
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(selectedGender == gender ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedGender == gender ? 
                                              LinearGradient(
                                                colors: [
                                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                              ) : 
                                              LinearGradient(
                                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                              )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localized(.storyTheme))
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(localizationManager.localized(.selectAdventure))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Ücretsiz Temalar
            VStack(alignment: .leading, spacing: 12) {
                Text(localizationManager.localized(.freeThemes))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(StoryTheme.freeThemes, id: \.self) { theme in
                        themeCard(theme: theme)
                    }
                }
            }
            
            // Premium Temalar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizationManager.localized(.premiumThemes))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("👑")
                        .font(.caption)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(StoryTheme.premiumThemes, id: \.self) { theme in
                        themeCard(theme: theme)
                    }
                }
            }
            
            if selectedTheme == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localized(.customStoryTopic))
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField(localizationManager.currentLanguage == .turkish ? "Örn: Dinozorlarla macera" : "e.g: Adventure with dinosaurs", text: $customTitle)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func themeCard(theme: StoryTheme) -> some View {
        Button(action: {
            // Premium tema kontrolü
            if theme.isPremium && !subscriptionManager.isPremium {
                showingPremiumSheet = true
                return
            }
            
            withAnimation(.spring(response: 0.3)) {
                selectedTheme = theme
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Text(theme.emoji)
                        .font(.system(size: 40))
                    
                    Text(theme.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(selectedTheme == theme ? .white : .primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedTheme == theme ? theme.color : Color(.systemGray6))
                        .shadow(color: selectedTheme == theme ? theme.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.isPremium && !subscriptionManager.isPremium ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                )
                
                // Premium badge
                if theme.isPremium && !subscriptionManager.isPremium {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Text("👑")
                            .font(.system(size: 14))
                    }
                    .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(theme.isPremium && !subscriptionManager.isPremium ? 0.7 : 1.0)
    }
    
    
    private var generateButton: some View {
        VStack(spacing: 16) {
            // Hikaye Kulübü durumu bilgisi
            subscriptionStatusBanner
            
            Button(action: generateStory) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    
                    Text(isGenerating ? generationProgress : localizationManager.localized(.generateStory))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if isGenerating {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.58, green: 0.29, blue: 0.98),
                                            Color(red: 0.85, green: 0.35, blue: 0.85),
                                            Color(red: 1.0, green: 0.45, blue: 0.55)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                )
            }
            .disabled(isGenerating || !isFormValid)
            .scaleEffect(isGenerating ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isGenerating)
            
            // Form durumu göstergesi
            if !isFormValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(localizationManager.localized(.fillAllFields))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(.top, 8)
    }
    
    private var subscriptionStatusBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Durum ikonu
                ZStack {
                    Circle()
                        .fill(subscriptionManager.isPremium ? Color.yellow.opacity(0.2) : 
                              subscriptionManager.freeTrialCount > 0 ? Color.green.opacity(0.2) : 
                              Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(subscriptionManager.isPremium ? "👑" : 
                         subscriptionManager.freeTrialCount > 0 ? "🎁" : "✨")
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if subscriptionManager.isPremium {
                        Text(subscriptionManager.subscriptionTier.displayName)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 6) {
                            Text("\(subscriptionManager.remainingImageStories)")
                                .font(.title2.bold())
                                .foregroundColor(.indigo)
                            
                            Text("görselli hikaye kaldı")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    } else if subscriptionManager.freeTrialCount > 0 {
                        Text("Ücretsiz Deneme")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 6) {
                            Text("\(subscriptionManager.freeTrialCount)")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                            
                            Text("deneme kaldı")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Kulüp Üyeliği Gerekli")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Text("☕️ Günde 3₺")
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            
            // Hikaye Kulübü gerekiyorsa uyarı
            if !subscriptionManager.canCreateStory(type: .image) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Görselli hikaye oluşturmak için kulüp üyeliği gerekiyor.")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: {
                        showingPremiumSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Text("☕️")
                                .font(.caption2)
                            Text("Kulübe Katıl")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var loadingOverlay: some View {
        Group {
            if isGenerating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text(generationProgress)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                    )
            }
        }
    }
    
    private var isFormValid: Bool {
        !childName.isEmpty &&
        !age.isEmpty &&
        Int(age) != nil &&
        Int(age)! >= 1 &&
        Int(age)! <= 12 &&
        photoData != nil
    }
    
    private func generateStory() {
        guard isFormValid else {
            alertTitle = "⚠️ \(localizationManager.localized(.missingInfo))"
            alertMessage = localizationManager.localized(.fillAllFields)
            showingAlert = true
            return
        }
        
        // Hikaye Kulübü kontrolü
        if !subscriptionManager.canCreateStory(type: .image) {
            alertTitle = "⚠️ \(localizationManager.localized(.clubMembershipRequired))"
            alertMessage = localizationManager.currentLanguage == .turkish ? 
                "Görselli hikaye oluşturmak için kulüp üyeliği gerekiyor.\n\n☕️ Günde sadece 3₺ ile sınırsız hikaye!" :
                "Club membership required to create illustrated stories.\n\n☕️ Only $1/day for unlimited stories!"
            showingAlert = true
            showingPremiumSheet = true
            return
        }
        
        guard let photo = selectedPhoto else {
            alertTitle = "⚠️ \(localizationManager.localized(.photoRequired))"
            alertMessage = localizationManager.localized(.selectPhotoFirst)
            showingAlert = true
            return
        }
        
        // Üyelik/deneme hakkını kullan
        guard subscriptionManager.useStory(type: .image) else {
            alertTitle = "⚠️ \(localizationManager.localized(.clubMembershipRequired))"
            alertMessage = localizationManager.currentLanguage == .turkish ?
                "Görselli hikaye oluşturmak için kulüp üyeliği gerekiyor." :
                "Club membership required to create illustrated stories."
            showingAlert = true
            return
        }
        
        isGenerating = true
        generationProgress = "Hikaye oluşturuluyor..."
        
        Task {
            // Create story with StoryGenerationManager
            let _ = await StoryGenerationManager.shared.createCustomStory(
                childName: childName,
                age: Int(age) ?? 5,
                gender: selectedGender,
                theme: selectedTheme,
                language: selectedLanguage,
                image: photo,
                customTitle: selectedTheme == .custom ? customTitle : nil
            )
            
            await MainActor.run {
                self.isGenerating = false
                self.generationProgress = ""
                
                // Ücretsiz kullanıcılara reklam göster
                if !subscriptionManager.isPremium {
                    // Reklamı göster
                    adManager.showInterstitialAd()
                }
                
                // Başarı mesajı
                self.alertTitle = "✨ \(localizationManager.localized(.storyGenerating))"
                self.alertMessage = localizationManager.localized(.storyGeneratingMessage)
                self.showingAlert = true
                
                // Formu temizle
                self.childName = ""
                self.age = ""
                self.selectedPhoto = nil
                self.photoData = nil
                self.uploadedPhotoURL = nil
                self.scenePhoto = nil
                self.scenePhotoData = nil
            }
        }
    }
}

#Preview {
    CreateStoryView()
}

// iOS 15 uyumlu ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var photoData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.photoData = image.jpegData(compressionQuality: 0.8)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}