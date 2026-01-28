import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
            
            CreateStoryView()
                .tabItem {
                    Label("Görselli Hikaye", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)
            
            TextOnlyStoryView()
                .tabItem {
                    Label("Metin Hikaye", systemImage: "text.book.closed")
                }
                .tag(2)
            
            DailyStoriesView()
                .tabItem {
                    Label("Günlük", systemImage: "book.pages.fill")
                }
                .tag(3)
            
            LibraryView()
                .tabItem {
                    Label("Kütüphane", systemImage: "books.vertical.fill")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .accentColor(Color(red: 0.58, green: 0.29, blue: 0.98)) // Mor - ikon rengine uygun
        .onAppear {
            print("🎯 ContentView appeared - Selected tab: \(selectedTab)")
        }
    }
}

#Preview {
    ContentView()
}
