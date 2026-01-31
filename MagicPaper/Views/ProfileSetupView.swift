import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var userName = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var isEditing: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Sabit beyaz arka plan
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text(isEditing ? L.editProfile : L.welcome)
                            .font(.title.bold())
                            .foregroundColor(.black)
                        
                        if !isEditing {
                            Text(L.createProfile)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Profile Photo
                    VStack(spacing: 16) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.58, green: 0.29, blue: 0.98),
                                                            Color(red: 0.85, green: 0.35, blue: 0.85)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 4
                                                )
                                        )
                                } else if let profileImage = profileManager.getProfileImage() {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.58, green: 0.29, blue: 0.98),
                                                            Color(red: 0.85, green: 0.35, blue: 0.85)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 4
                                                )
                                        )
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.58, green: 0.29, blue: 0.98),
                                                        Color(red: 0.85, green: 0.35, blue: 0.85),
                                                        Color(red: 1.0, green: 0.45, blue: 0.55)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 120, height: 120)
                                        
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Edit button
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 4, x: 0, y: 2)
                                .offset(x: -5, y: -5)
                            }
                        }
                        
                        Text(L.profilePhoto)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Name Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.yourName)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextField(L.enterName, text: $userName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                Group {
                                    if userName.isEmpty {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.clear, lineWidth: 2)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.58, green: 0.29, blue: 0.98),
                                                        Color(red: 0.85, green: 0.35, blue: 0.85)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 2
                                            )
                                    }
                                }
                            )
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(isEditing ? L.save : L.start)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    userName.isEmpty ? 
                                    LinearGradient(
                                        colors: [Color.gray, Color.gray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
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
                                .shadow(color: userName.isEmpty ? .clear : Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .disabled(userName.isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    if isEditing {
                        Button(L.cancel) {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 32)
            }
            }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light) // Sabit aydınlık mod
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L.close) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, photoData: .constant(nil))
        }
        .onAppear {
            if isEditing {
                userName = profileManager.profile.name
            }
        }
        .interactiveDismissDisabled(!isEditing)
    }
    
    private func saveProfile() {
        profileManager.updateProfile(name: userName, image: selectedImage)
        dismiss()
    }
}

#Preview {
    ProfileSetupView()
}
