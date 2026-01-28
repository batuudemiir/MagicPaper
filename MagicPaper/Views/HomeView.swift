import SwiftUI

struct HomeView: View {
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var dailyStoryManager = DailyStoryManager.shared
    @State private var selectedStory: Story?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Bölümü
                    heroSection
                        .padding(.horizontal, 20)
                    
                    // Günün Hikayesi
                    dailyStorySection
                        .padding(.horizontal, 20)
                    
                    // Nasıl Çalışır
                    howItWorksSection
                        .padding(.horizontal, 20)
                    
                    // Örnek Hikayeler (Önizleme)
                    sampleStoriesSection
                    
                    // Hızlı İşlemler
                    quickActionsSection
                        .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(
                ZStack {
                    // Ana arka plan - İkon renklerine uygun gradient
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.29, blue: 0.98), // Mor
                            Color(red: 0.85, green: 0.35, blue: 0.85), // Pembe
                            Color(red: 1.0, green: 0.45, blue: 0.55)   // Kırmızı-pembe
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.08) // Çok hafif, sadeleşmeyi bozmaz
                    
                    // Beyaz overlay (temiz görünüm için)
                    Color.white.opacity(0.92)
                    
                    // Dekoratif yıldızlar ve şekiller
                    GeometryReader { geometry in
                        // Yıldızlar - ikon temasına uygun
                        Text("⭐️")
                            .font(.system(size: 30))
                            .position(x: 50, y: 100)
                            .opacity(0.3)
                        
                        Text("✨")
                            .font(.system(size: 25))
                            .position(x: geometry.size.width - 40, y: 150)
                            .opacity(0.4)
                        
                        Text("🌟")
                            .font(.system(size: 35))
                            .position(x: geometry.size.width - 60, y: 400)
                            .opacity(0.3)
                        
                        Text("⭐️")
                            .font(.system(size: 28))
                            .position(x: 40, y: 600)
                            .opacity(0.35)
                        
                        // Bulutlar
                        Text("☁️")
                            .font(.system(size: 40))
                            .position(x: geometry.size.width - 80, y: 80)
                            .opacity(0.25)
                        
                        Text("☁️")
                            .font(.system(size: 35))
                            .position(x: 70, y: 350)
                            .opacity(0.2)
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle("MagicPaper")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.light)
        }
        .sheet(item: $selectedStory) { story in
            StoryViewerView(story: story)
        }
    }
    
    private var heroSection: some View {
        ZStack {
            // Arka plan - İkon renklerine uygun gradient (mor → pembe → kırmızı-pembe)
            LinearGradient(
                colors: [
                    Color(red: 0.58, green: 0.29, blue: 0.98), // Mor (#9449FA)
                    Color(red: 0.85, green: 0.35, blue: 0.85), // Pembe (#D959D9)
                    Color(red: 1.0, green: 0.45, blue: 0.55)   // Kırmızı-pembe (#FF738C)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Dekoratif elementler
            GeometryReader { geometry in
                // Sol üst daire
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .offset(x: -60, y: -40)
                
                // Sağ alt daire
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .offset(x: geometry.size.width - 70, y: geometry.size.height - 60)
                
                // Orta parlama efekti
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            
            // İçerik
            VStack(spacing: 20) {
                // İkon ve başlık grubu
                VStack(spacing: 14) {
                    // İkon
                    ZStack {
                        // Arka plan halka
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 76, height: 76)
                        
                        // İç daire
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 64, height: 64)
                        
                        // İkon
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Başlık
                    VStack(spacing: 5) {
                        Text("Sihirli Hikayeler")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Çocuğunuz Kahramanı Olsun")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))
                    }
                }
                .padding(.top, 32)
                
                // Özellikler - Horizontal pills
                HStack(spacing: 12) {
                    featurePill(icon: "photo.fill", text: "Fotoğraf")
                    featurePill(icon: "paintbrush.fill", text: "Tema")
                    featurePill(icon: "sparkles", text: "Sihir")
                }
                
                // CTA Butonu
                NavigationLink(destination: CreateStoryView()) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                        Text("Hemen Başla")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98)) // Mor
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
        }
        .frame(height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.35), radius: 18, x: 0, y: 8)
    }
    
    // Kompakt özellik pill
    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Günün Hikayesi Section
    
    private var dailyStorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Günün Hikayesi 🌟")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                    Text("Çocuğunuza her gün yeni bir hikaye okuyun")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                
                Spacer()
            }
            
            if let todaysStory = dailyStoryManager.todaysStory {
                NavigationLink(destination: DailyStoriesView()) {
                    HStack(spacing: 16) {
                        // Sol taraf - Emoji ve kategori
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [todaysStory.category.color.opacity(0.6), todaysStory.category.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Text(todaysStory.category.emoji)
                                .font(.system(size: 32))
                        }
                        
                        // Sağ taraf - İçerik
                        VStack(alignment: .leading, spacing: 6) {
                            Text(todaysStory.title)
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .lineLimit(2)
                            
                            HStack(spacing: 8) {
                                Label(todaysStory.category.displayName, systemImage: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(todaysStory.category.color)
                                
                                Label("\(todaysStory.readingTime) dk", systemImage: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.caption)
                                Text("Oku")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(todaysStory.category.color)
                            .cornerRadius(8)
                            .padding(.top, 2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: todaysStory.category.color.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nasıl Çalışır? 🎯")
                .font(.title2.bold())
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                stepView(
                    icon: "camera.fill",
                    title: "1. Fotoğraf Ekle",
                    description: "Çocuğunuzun fotoğrafını seçin",
                    color: .blue
                )
                
                stepView(
                    icon: "paintpalette.fill",
                    title: "2. Tema Seç",
                    description: "Macera türünü belirleyin",
                    color: .purple
                )
                
                stepView(
                    icon: "sparkles",
                    title: "3. Kendi Hikayesini Oluştur",
                    description: "Kişiselleştirilmiş hikayeniz hazır!",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private func stepView(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
        )
    }
    
    private var featuredStoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hikayelerim")
                    .font(.title2.bold())
                
                Spacer()
                
                NavigationLink(destination: LibraryView()) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(storyManager.stories.prefix(5)) { story in
                        featuredStoryCard(story: story)
                    }
                }
            }
        }
    }
    
    // MARK: - Sample Stories Section
    
    private var sampleStoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Örnek Hikayeler 📖")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                Text("Nasıl hikayeler oluşturabileceğinizi keşfedin")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(getSampleStories()) { story in
                        sampleStoryCard(story: story)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func sampleStoryCard(story: Story) -> some View {
        Button(action: {
            selectedStory = story
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Kapak
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [story.theme.color.opacity(0.6), story.theme.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 220, height: 160)
                        .overlay(
                            // Emoji ortada
                            Text(story.theme.emoji)
                                .font(.system(size: 56))
                        )
                    
                    // "Örnek" badge
                    Text("ÖRNEK")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                        .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    Text("\(story.childName)'in Hikayesi")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    
                    if let firstPage = story.pages.first {
                        Text(firstPage.text)
                            .font(.caption)
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Text(story.theme.emoji)
                                .font(.caption)
                            Text(story.theme.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(story.theme.color.opacity(0.1))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                            Text("Önizle")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.indigo)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 220)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getSampleStories() -> [Story] {
        return [
            Story(
                title: "Luna'nın Yıldız Yolculuğu",
                childName: "Luna",
                theme: .space,
                language: .turkish,
                status: .completed,
                pages: [
                    StoryPage(title: "Yıldızlara Bakış", text: "Luna her gece penceresinden yıldızları izlerdi. Gökyüzündeki sayısız ışık noktası onu büyülerdi. 'Acaba oralarda neler var?' diye düşünürdü. Bir gece, bahçede garip bir ışık gördü. Dışarı çıktığında, küçük ama parlak bir uzay gemisi buldu. Geminin kapısı açıktı ve içeriden davetkar bir ışık sızıyordu.", imagePrompt: ""),
                    StoryPage(title: "İlk Gezegen", text: "Luna ilk gezegenine indi. Her yer mor ve pembe renklerle doluydu. Ağaçlar kristalden, çiçekler ışık saçıyordu. Birden, üç gözlü yeşil bir yaratık belirdi. 'Merhaba! Ben Zyx,' dedi dostça. 'Hoş geldin gezegenmize!' Luna başta korkmuştu ama Zyx'in gülümsemesi onu rahatlattı.", imagePrompt: ""),
                    StoryPage(title: "Asteroid Fırtınası", text: "Bir sonraki gezegene giderken, Luna büyük bir sorunla karşılaştı. Önünde dev bir asteroid fırtınası vardı. Kayalar her yöne savruluyordu. 'Ne yapacağım?' diye düşündü endişeyle. Geminin bilgisayarı devreye girdi. 'Sakin ol Luna. Sensörlerini kullan ve kayaların arasından geç.'", imagePrompt: ""),
                    StoryPage(title: "Uzay İstasyonu", text: "Luna büyük bir uzay istasyonuna vardı. İçerisi farklı gezegenlerden gelen yaratıklarla doluydu. Herkes barış içinde yaşıyor, bilgi paylaşıyor ve birlikte çalışıyordu. Luna bir robot, bir peri ve bir bulut yaratığıyla tanıştı. Hepsi ona kendi dünyalarından bahsetti.", imagePrompt: ""),
                    StoryPage(title: "Kayıp Gezegen", text: "Uzay istasyonunda bir alarm çaldı. Bir gezegen yardım istiyordu. Güneşleri sönmek üzereydi ve her yer karanlığa gömülüyordu. 'Yardım etmeliyiz!' dedi Luna. Arkadaşları da katıldı. Hep birlikte o gezegene gittiler. Robot teknik bilgisini, peri sihirini, bulut yaratığı enerjisini kullandı.", imagePrompt: ""),
                    StoryPage(title: "Yıldız Festivali", text: "Gezegeni kurtardıkları için büyük bir festival düzenlendi. Tüm uzaydan yaratıklar geldi. Müzik, dans, ışık gösterileri... Her şey muhteşemdi. Luna hiç bu kadar mutlu olmamıştı. Yeni arkadaşlarıyla dans etti, uzay yemekleri tattı ve yıldızların altında şarkılar söyledi.", imagePrompt: ""),
                    StoryPage(title: "Dünya'ya Dönüş", text: "Luna Dünya'ya dönerken, pencereden gezegenini izledi. Mavi ve yeşil, bulutlarla kaplı... Ne kadar güzeldi. Bahçeye yumuşak bir şekilde indi. Gemi ışıklarını söndürdü. 'Teşekkürler Luna,' dedi bilgisayar. 'Harika bir pilottun. İstediğin zaman geri gel.' Luna yatağına uzandığında, tüm macera bir rüya gibi geldi.", imagePrompt: "")
                ]
            ),
            Story(
                title: "Efe'nin Orman Macerası",
                childName: "Efe",
                theme: .jungle,
                language: .turkish,
                status: .completed,
                pages: [
                    StoryPage(title: "Orman Gezisi", text: "Efe ailesiyle birlikte büyük bir ormana gezi yapmaya gitti. Ağaçlar o kadar yüksekti ki gökyüzünü görmek zordu. Her yerden kuş sesleri geliyordu. Renkli kelebekler uçuşuyordu. 'Bu orman sihirli gibi,' dedi Efe heyecanla. Annesi gülümsedi. 'Kim bilir, belki de öyle!'", imagePrompt: ""),
                    StoryPage(title: "Kaybolma", text: "Efe güzel bir kelebeği takip ederken, ailesinden uzaklaştı. Etrafına bakındığında kimseyi göremedi. Ama korkmadı. Çünkü orman ona dostça geliyordu. Ağaçlar fısıldıyor, çiçekler gülümsüyor gibiydi. Birden, parlak bir patika gördü. 'Bu yol beni bir yerlere götürecek,' diye düşündü.", imagePrompt: ""),
                    StoryPage(title: "Maymun Arkadaş", text: "Patikada ilerlerken, bir ağaçtan küçük bir maymun atladı. 'Merhaba! Ben Ciko,' dedi maymun. Efe şaşırmıştı. 'Sen konuşabiliyorsun!' Ciko güldü. 'Tabii ki! Bu sihirli ormanda herkes konuşabilir. Gel, sana harika bir yer göstereyim!' İkili birlikte yürümeye başladı.", imagePrompt: ""),
                    StoryPage(title: "Antik Tapınak", text: "Ciko, Efe'yi asma yapraklarla kaplı eski bir tapınağa götürdü. Duvarlar gizemli sembollerle doluydu. 'Bu tapınak yüzlerce yıllık,' dedi Ciko. 'İçinde bir hazine var ama onu bulmak için bir bilmeceyi çözmen gerek.' Efe heyecanlandı. Bilmeceleri çok severdi!", imagePrompt: ""),
                    StoryPage(title: "Bilmece Çözme", text: "Tapınağın kapısında bir yazı vardı: 'Güneş doğarken doğar, gün boyunca büyür, akşam kaybolur. Nedir?' Efe düşündü. Sonra gülümsedi. 'Gölge!' dedi. Kapı yavaşça açıldı. İçeride altın bir ağaç vardı. Yaprakları pırıl pırıl parlıyordu. 'Bu ağaç ormanı koruyor,' dedi Ciko.", imagePrompt: ""),
                    StoryPage(title: "Ormanın Hediyesi", text: "Altın ağaç, Efe'ye küçük bir tohum verdi. 'Bu tohumu evinde dik,' dedi ağaç. 'Seni her zaman ormana bağlı tutacak.' Efe tohumunu özenle cebine koydu. Ciko ve diğer hayvanlar Efe'yi uğurladılar. Herkes ona el salladı. 'Tekrar gel!' diye bağırdılar.", imagePrompt: ""),
                    StoryPage(title: "Aileyle Buluşma", text: "Ciko, Efe'yi ailesinin olduğu yere geri götürdü. Annesi ve babası onu görünce çok sevindiler. 'Neredeydin?' diye sordular. Efe gülümsedi. 'İnanılmaz bir macera yaşadım!' O gece evde, Efe tohumunu bir saksıya dikti. Yarın ne olacağını merakla bekliyordu. Belki de küçük bir sihirli ağaç büyüyecekti!", imagePrompt: "")
                ]
            )
        ]
    }
    
    private func featuredStoryCard(story: Story) -> some View {
        Button(action: {
            if story.status == .completed {
                selectedStory = story
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Kapak Resmi
                ZStack {
                    if let coverImageFileName = story.coverImageFileName,
                       let uiImage = FileManagerService.shared.loadImage(fileName: coverImageFileName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 220, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [story.theme.color.opacity(0.6), story.theme.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 160)
                            .overlay(
                                Text(story.theme.emoji)
                                    .font(.system(size: 56))
                            )
                    }
                    
                    // Status overlay for generating stories
                    if story.status != .completed {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 220, height: 160)
                            .overlay(
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text(story.status.displayName)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text("\(story.childName)'in Hikayesi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // İlk sayfa metni önizlemesi
                    if let firstPage = story.pages.first {
                        Text(firstPage.text)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Text(story.theme.emoji)
                                .font(.caption)
                            Text(story.theme.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(story.theme.color.opacity(0.1))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        if story.status == .completed {
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.caption2)
                                Text("\(story.pages.count) sayfa")
                                    .font(.caption2)
                            }
                            .foregroundColor(.indigo)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 220)
            .padding(.bottom, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hızlı İşlemler ⚡️")
                .font(.title2.bold())
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    NavigationLink(destination: CreateStoryView()) {
                        quickActionButton(
                            icon: "plus.circle.fill",
                            title: "Yeni Hikaye",
                            color: .indigo
                        )
                    }
                    
                    NavigationLink(destination: LibraryView()) {
                        quickActionButton(
                            icon: "books.vertical.fill",
                            title: "Kütüphanem",
                            color: .green
                        )
                    }
                }
                
                HStack(spacing: 12) {
                    NavigationLink(destination: DailyStoriesView()) {
                        quickActionButton(
                            icon: "book.pages.fill",
                            title: "Günlük Hikayeler",
                            color: .orange
                        )
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        quickActionButton(
                            icon: "gearshape.fill",
                            title: "Ayarlar",
                            color: .purple
                        )
                    }
                }
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    HomeView()
}
