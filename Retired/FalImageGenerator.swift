import Foundation
import UIKit

class FalImageGenerator: ObservableObject {
    static let shared = FalImageGenerator()
    
    // Anahtar Secrets.xcconfig -> Info.plist üzerinden gelir; koda yazılmaz.
    // "Key " ön ekini buraya koyma, aşağıda kod otomatik ekliyor.
    private let apiKey = (APIKeys.fal ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Flux Dev Endpoint
    private let baseURL = "https://queue.fal.run/fal-ai/flux/dev"
    
    private init() {}
    
    // MARK: - Public Methods
    
    func generateImage(
        prompt: String,
        childPhotoURL: String,
        progressCallback: @escaping (String) -> Void = { _ in }
    ) async throws -> Data? {
        
        // 1. Validasyon
        guard !apiKey.isEmpty else {
            print("❌ HATA: API Key boş!")
            throw FalGeneratorError.missingAPIKey
        }
        
        print("🚀 Fal.ai işlemi başlıyor...")
        
        progressCallback("İllüstrasyon hazırlanıyor...")
        
        // 2. İsteği Gönder (Submit)
        // Bize bir Request ID ve takip etmemiz için Status URL dönecek
        let submission = try await submitImageGeneration(prompt: prompt, imageURL: childPhotoURL)
        
        print("✅ İstek sıraya alındı. ID: \(submission.requestId)")
        print("zzz Bekleniyor... (Status URL: \(submission.statusUrl))")
        
        progressCallback("Çizim yapılıyor...")
        
        // 3. Sırayı Bekle (Poll)
        // Fal.ai'nin bize verdiği statusUrl'i dinliyoruz
        let resultImageURL = try await pollForResult(statusUrl: submission.statusUrl, progressCallback: progressCallback)
        
        progressCallback("Resim indiriliyor...")
        
        // 4. Resmi İndir
        return try await downloadImage(from: resultImageURL)
    }
    
    // MARK: - Private Methods
    
    /// İsteği Fal.ai kuyruğuna gönderir
    private func submitImageGeneration(prompt: String, imageURL: String) async throws -> (requestId: String, statusUrl: String) {
        guard let url = URL(string: baseURL) else { throw FalGeneratorError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // ÖNEMLİ: Authorization header formatı "Key <API_KEY>" olmalı
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Flux Dev Parametreleri
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "image_url": imageURL,
            // strength: 1.0 fotoğrafın aynısı olur, 0.0 tamamen hayal ürünü olur.
            // 0.5 - 0.6 arası hikaye arka planı oluşturmak için idealdir.
            "strength": 0.55, 
            "guidance_scale": 7.5,
            "num_inference_steps": 28,
            "enable_safety_checker": true,
            "image_size": "landscape_4_3", // Kitap formatı için yatay
            "output_format": "jpeg"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Hata Kontrolü
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Bilinmeyen Hata"
            print("❌ Fal.ai Submit Hatası (\(httpResponse.statusCode)): \(errorMsg)")
            throw FalGeneratorError.apiError(httpResponse.statusCode, errorMsg)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let requestId = json["request_id"] as? String,
              let statusUrl = json["status_url"] as? String else {
            print("❌ JSON Parse Hatası (Submit): \(String(data: data, encoding: .utf8) ?? "")")
            throw FalGeneratorError.invalidResponse
        }
        
        return (requestId, statusUrl)
    }
    
    /// Sonucu bekler (Polling)
    private func pollForResult(statusUrl: String, progressCallback: @escaping (String) -> Void) async throws -> String {
        guard let url = URL(string: statusUrl) else { throw FalGeneratorError.invalidURL }
        
        let maxAttempts = 60 // 60 saniye bekle
        
        for attempt in 1...maxAttempts {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("⚠️ Polling uyarısı: \(httpResponse.statusCode)")
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            
            let status = json["status"] as? String ?? "UNKNOWN"
            
            if status == "COMPLETED" {
                // İşlem bitti, resim URL'ini al
                if let images = json["images"] as? [[String: Any]],
                   let firstImage = images.first,
                   let finalUrl = firstImage["url"] as? String {
                    print("✅ Resim başarıyla oluşturuldu: \(finalUrl)")
                    return finalUrl
                }
            } else if status == "FAILED" {
                let error = json["error"] as? String ?? "Bilinmeyen Hata"
                print("❌ Fal.ai İşlemi Başarısız: \(error)")
                throw FalGeneratorError.generationFailed(error)
            } else {
                // IN_QUEUE veya IN_PROGRESS
                if let logs = json["logs"] as? [[String: Any]], let lastLog = logs.last, let message = lastLog["message"] as? String {
                     print("🔄 Durum: \(status) - \(message)")
                } else {
                     print("🔄 Durum: \(status) (Deneme \(attempt)/\(maxAttempts))")
                }
                
                // 1 saniye bekle
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        throw FalGeneratorError.timeout
    }
    
    private func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw FalGeneratorError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

// MARK: - Error Types
enum FalGeneratorError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case imageUploadFailed
    case invalidResponse
    case apiError(Int, String)
    case generationFailed(String)
    case timeout
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .apiError(let code, let message): return "Fal.ai Hatası (\(code)): \(message)"
        case .generationFailed(let msg): return "Oluşturma Başarısız: \(msg)"
        default: return "Beklenmeyen bir hata oluştu."
        }
    }
}