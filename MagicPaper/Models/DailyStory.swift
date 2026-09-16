import Foundation
import SwiftUI

/// Günlük hikaye modeli - Annelerin çocuklarına okuyabileceği hazır hikayeler
struct DailyStory: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var category: DailyStoryCategory
    var ageRange: String // "0-3", "4-6", "7-9", "10+"
    var readingTime: Int // dakika
    var content: String
    var moralLesson: String // Hikayenin öğretisi
    var emoji: String
    var isRead: Bool
    var lastReadDate: Date?

    /// Bu masal bu yaştaki bir çocuk için mi.
    ///
    /// `ageRange` serbest metin ("1-4", "3-6", "10+") ve tek kullanıcısı burası,
    /// o yüzden ayrıştırma da burada duruyor. Okunamayan bir aralık HERKESE
    /// uyar sayılır: elemek, tanınmayan bir yazım yüzünden bir masalı sessizce
    /// yok etmek olurdu — bu projede tekrar tekrar düzelttiğimiz kusur.
    func matches(age: Int) -> Bool {
        let text = ageRange.trimmingCharacters(in: .whitespaces)
        if text.hasSuffix("+"), let low = Int(text.dropLast()) { return age >= low }
        let parts = text.split(separator: "-").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2 else { return true }
        return (min(parts[0], parts[1])...max(parts[0], parts[1])).contains(age)
    }
    
    static func == (lhs: DailyStory, rhs: DailyStory) -> Bool {
        lhs.id == rhs.id
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        category: DailyStoryCategory,
        ageRange: String,
        readingTime: Int,
        content: String,
        moralLesson: String,
        emoji: String,
        isRead: Bool = false,
        lastReadDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.ageRange = ageRange
        self.readingTime = readingTime
        self.content = content
        self.moralLesson = moralLesson
        self.emoji = emoji
        self.isRead = isRead
        self.lastReadDate = lastReadDate
    }
}

enum DailyStoryCategory: String, CaseIterable, Codable, Identifiable {
    case bedtime = "bedtime"
    case morning = "morning"
    case educational = "educational"
    case values = "values"
    case adventure = "adventure"
    case nature = "nature"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bedtime: return "Uyku Öncesi"
        case .morning: return "Sabah Hikayeleri"
        case .educational: return "Öğretici"
        case .values: return "Değerler"
        case .adventure: return "Macera"
        case .nature: return "Doğa"
        }
    }
    
    var emoji: String {
        switch self {
        case .bedtime: return "🌙"
        case .morning: return "☀️"
        case .educational: return "📚"
        case .values: return "💝"
        case .adventure: return "🗺️"
        case .nature: return "🌳"
        }
    }
    
    var color: Color {
        switch self {
        case .bedtime: return .indigo
        case .morning: return .orange
        case .educational: return .blue
        case .values: return .pink
        case .adventure: return .green
        case .nature: return .teal
        }
    }
    
    var description: String {
        switch self {
        case .bedtime: return "Rahatlatıcı ve huzurlu hikayeler"
        case .morning: return "Güne enerjik başlamak için"
        case .educational: return "Öğretici ve bilgilendirici"
        case .values: return "Değerler ve ahlak öğreten"
        case .adventure: return "Heyecan dolu maceralar"
        case .nature: return "Doğa ve hayvanlar hakkında"
        }
    }
}
