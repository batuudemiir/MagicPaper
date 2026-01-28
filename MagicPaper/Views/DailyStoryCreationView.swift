import SwiftUI
import PhotosUI

struct DailyStoryCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var storyManager = StoryGenerationManager.shared
    
    let category: DailyStoryCategory
    
    @State private var childName: String = ""
    @State private var childAge: Int = 5
    @State private var childGender: Gender = .other
    @State private var selectedImage: UIImage?
    @State private var photoData: Data?
    @State private var showingImagePicker = false
    @State private var showingSuccessAlert = false
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Kategori Header
                    categoryHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Fotoğraf Seçimi
                    photoSection
                        .padding(.horizontal, 20)
                    
                    // Çocuk Bilgileri
                    childInfoSection
                        .padding(.horizontal, 20)
                    
                    // Oluştur Butonu
                    createButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.94),
                        Color(red: 0.98, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Hikaye Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, photoData: $photoData)
        }
        .alert("✨ Hikaye Oluşturuluyor", isPresented: $showingSuccessAlert) {
            Button("Tamam") {
                dismiss()
            }
        } message: {
            Text("Hikayeniz oluşturuluyor! Uygulamayı kapatmayın. Kütüphaneden ilerlemeyi takip edebilirsiniz.")
        }
        .onAppear {
            // Profil bilgilerini otomatik doldur
            if !profileManager.profile.name.isEmpty {
                childName = profileManager.profile.name
            }
        }
    }
    
    // MARK: - Category Header
    
    private var categoryHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color.opacity(0.6), category.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(category.emoji)
                    .font(.system(size: 50))
            }
            
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.title2.bold())
                    .foregroundColor(.black)
                
                Text(category.description)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Çocuğunuzun Fotoğrafı")
                .font(.headline)
                .foregroundColor(.black)
            
            Button(action: {
                showingImagePicker = true
            }) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(category.color, lineWidth: 3)
                        )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(category.color)
                        
                        Text("Fotoğraf Seç")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text("Çocuğunuzun net bir fotoğrafını seçin")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(category.color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [10])
                                    )
                                    .foregroundColor(category.color)
                            )
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Child Info Section
    
    private var childInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Çocuk Bilgileri")
                .font(.headline)
                .foregroundColor(.black)
            
            // İsim
            VStack(alignment: .leading, spacing: 8) {
                Text("İsim")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                
                TextField("Çocuğunuzun adı", text: $childName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    )
            }
            
            // Yaş
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Yaş")
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(childAge) yaş")
                        .font(.subheadline)
                        .foregroundColor(category.color)
                }
                
                Slider(value: Binding(
                    get: { Double(childAge) },
                    set: { childAge = Int($0) }
                ), in: 1...12, step: 1)
                .tint(category.color)
            }
            
            // Cinsiyet
            VStack(alignment: .leading, spacing: 8) {
                Text("Cinsiyet")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                
                HStack(spacing: 12) {
                    ForEach([Gender.boy, Gender.girl, Gender.other], id: \.self) { gender in
                        Button(action: {
                            childGender = gender
                        }) {
                            Text(gender.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(childGender == gender ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(childGender == gender ? category.color : Color(red: 0.95, green: 0.95, blue: 0.97))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button(action: createStory) {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text("Hikayeyi Oluştur")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: canCreate ? [category.color.opacity(0.8), category.color] : [Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: category.color.opacity(0.3), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(!canCreate || isGenerating)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var canCreate: Bool {
        !childName.isEmpty && selectedImage != nil && !isGenerating
    }
    
    // MARK: - Create Story
    
    private func createStory() {
        guard let image = selectedImage else { return }
        
        isGenerating = true
        
        Task {
            // Kategoriye özel hikaye oluştur
            _ = await storyManager.createCategoryBasedStory(
                childName: childName,
                age: childAge,
                gender: childGender,
                category: category,
                language: .turkish,
                image: image
            )
            
            // Günlük kullanımı artır
            subscriptionManager.incrementDailyStoryUsage()
            
            await MainActor.run {
                isGenerating = false
                showingSuccessAlert = true
            }
        }
    }
}

#Preview {
    DailyStoryCreationView(category: .bedtime)
}
