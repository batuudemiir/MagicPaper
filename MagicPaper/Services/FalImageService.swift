import Foundation
import UIKit

/// Clean Fal.ai service - Flux Schnell model
/// Returns image URL string after generation
class FalImageService {
    
    static let shared = FalImageService()
    
    private let apiKey = "f811abd1-cc51-4c25-89df-67b0ba81ba40:8b88b0e64cdc64161bbc6957e71e2788"
    private let endpoint = "https://queue.fal.run/fal-ai/flux/schnell"
    
    private init() {}
    
    /// Generate image and return URL string
    func generateImage(prompt: String, referenceImageUrl: String?) async throws -> String {
        print("🚀 Fal.ai: Starting generation...")
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        // Build prompt
        let fullPrompt = """
        Children's book illustration, Pixar style, vibrant colors.
        Scene: \(prompt)
        Preserve child's facial features from reference photo.
        High-quality, child as central focus.
        """
        
        // Parameters for Schnell (4 steps)
        var parameters: [String: Any] = [
            "prompt": fullPrompt,
            "negative_prompt": "different person, wrong face, distorted, blurry, low quality",
            "image_size": "landscape_4_3",
            "num_inference_steps": 4,
            "guidance_scale": 3.5,
            "strength": 0.55
        ]
        
        if let refUrl = referenceImageUrl {
            parameters["image_url"] = refUrl
        }
        
        // POST request to queue
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let requestId = json["request_id"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        print("✅ Fal.ai: Queued with ID: \(requestId)")
        
        // Poll for result
        return try await pollForCompletion(requestId: requestId)
    }
    
    /// Poll for completion using GET requests
    private func pollForCompletion(requestId: String) async throws -> String {
        // CORRECT: Use /requests/{id}/status endpoint
        let statusUrl = "\(endpoint)/requests/\(requestId)/status"
        
        guard let url = URL(string: statusUrl) else {
            throw URLError(.badURL)
        }
        
        print("🔄 Fal.ai: Polling at \(statusUrl)")
        
        // Poll up to 180 times (6 minutes)
        for attempt in 1...180 {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }
                
                if attempt <= 3 || attempt % 20 == 0 {
                    print("📡 Fal.ai: Attempt \(attempt) - HTTP \(httpResponse.statusCode)")
                }
                
                guard httpResponse.statusCode == 200 else {
                    continue
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = json["status"] as? String else {
                    continue
                }
                
                if status == "COMPLETED" {
                    // Extract image URL
                    if let images = json["images"] as? [[String: Any]],
                       let imageUrl = images.first?["url"] as? String {
                        print("✅ Fal.ai: Image ready!")
                        return imageUrl
                    }
                }
                
                if status == "FAILED" {
                    throw URLError(.badServerResponse)
                }
                
            } catch {
                if attempt == 180 {
                    throw error
                }
                continue
            }
        }
        
        throw URLError(.timedOut)
    }
}
