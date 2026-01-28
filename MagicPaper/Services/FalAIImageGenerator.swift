import Foundation
import UIKit

/// FAL.AI IMAGE GENERATOR - GEMINI 2.5 FLASH IMAGE EDIT
/// 
/// Fixed polling logic for queue-based API
/// Uses correct fal.run endpoint (not queue.fal.run)
class FalAIImageGenerator {
    
    static let shared = FalAIImageGenerator()
    
    // ✅ CORRECT ENDPOINT - fal.run (not queue.fal.run)
    private let endpoint = "https://fal.run/fal-ai/gemini-25-flash-image/edit"
    private let apiKey = "f811abd1-cc51-4c25-89df-67b0ba81ba40:8b88b0e64cdc64161bbc6957e71e2788"
    
    private init() {}
    
    // MARK: - Style Helper
    
    private func getStyleDescription(for theme: String?) -> String {
        let baseStyle = "children's storybook illustration, 3d pixar style render, cute, vibrant colors, soft volumetric lighting, masterpiece, 8k"
        
        switch theme?.lowercased() {
        case "fantasy":
            return "\(baseStyle), magical forest, glowing dust, enchanted atmosphere"
        case "space":
            return "\(baseStyle), spaceship, stars, galaxy background, cosmic wonder"
        case "jungle":
            return "\(baseStyle), lush jungle, sunlight filtering through trees, cute animals"
        case "hero":
            return "\(baseStyle), superhero suit, dynamic pose, cape flowing, heroic"
        case "underwater":
            return "\(baseStyle), underwater scene, coral reef, bubbles, marine life"
        default:
            return "\(baseStyle), warm lighting, magical atmosphere"
        }
    }
    
    // MARK: - Image Generation
    
    func generateImage(
        prompt: String,
        referenceImageUrl: String?,
        style: String? = "fantasy",
        seed: Int? = nil
    ) async throws -> String {
        
        print("🚀 ========================================")
        print("🚀 GEMINI 2.5 FLASH IMAGE EDIT")
        print("🚀 Using fal.run endpoint (queue-based)")
        print("🚀 ========================================")
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        let styleDescription = getStyleDescription(for: style)
        
        // ✅ Identity-preserving prompt
        let fullPrompt = """
        Transform this image: show the child \(prompt), \(styleDescription). Keep the child's face and identity exactly the same, only change the scene, pose, and style.
        """
        
        print("📝 Prompt: \(fullPrompt.prefix(100))...")
        
        // ✅ GEMINI 2.5 FLASH PARAMETERS
        var parameters: [String: Any] = [
            "prompt": fullPrompt,
            "seed": seed ?? Int.random(in: 1...1000000),
            // 🔥 ULTRA STRONG NEGATIVE PROMPT - Aggressively blocks ALL text
            "negative_prompt": "text, writing, letters, words, alphabet, numbers, digits, watermark, signature, logo, brand, trademark, subtitles, credits, captions, labels, title, heading, speech bubble, dialogue box, font, typography, written language, handwriting, calligraphy, graffiti, sign, banner, poster text, book text, newspaper, magazine text, ugly, bad anatomy, distorted face, blurry, low quality, crop, out of frame, deformed, disfigured, mutated, extra limbs, bad proportions"
        ]
        
        print("🚫 ULTRA NEGATIVE PROMPT: Aggressively blocking ALL text and watermarks")
        
        // ✅ Use same image 3x for stronger identity
        if let refUrl = referenceImageUrl {
            parameters["image_urls"] = [refUrl, refUrl, refUrl]
            print("📸 ========================================")
            print("📸 IDENTITY REFERENCE ATTACHED")
            print("📸 Using 3x same reference for maximum identity")
            print("📸 URL: \(refUrl.prefix(60))...")
            print("📸 ========================================")
        }
        
        if let seed = seed {
            print("🎲 Seed: \(seed) for consistency")
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        print("⏳ Submitting to queue...")
        
        // Submit to queue
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ ========================================")
            print("❌ SUBMISSION ERROR")
            print("❌ Status: \(httpResponse.statusCode)")
            print("❌ Response: \(errorText)")
            print("❌ ========================================")
            throw URLError(.badServerResponse)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response")
            throw URLError(.cannotParseResponse)
        }
        
        print("📦 Response keys: \(json.keys)")
        
        // Check if we got request_id (queue mode)
        if let requestId = json["request_id"] as? String {
            print("✅ Queued with ID: \(requestId)")
            print("⏳ Polling for result...")
            return try await pollForCompletion(requestId: requestId)
        }
        
        // Check if we got direct result (sync mode)
        if let images = json["images"] as? [[String: Any]],
           let imageUrl = images.first?["url"] as? String {
            print("✅ Got direct result (sync mode)")
            return imageUrl
        }
        
        print("❌ Unexpected response format")
        print("❌ Full response: \(json)")
        throw URLError(.cannotParseResponse)
    }
    
    // MARK: - Polling
    
    private func pollForCompletion(requestId: String) async throws -> String {
        // ✅ CORRECT STATUS ENDPOINT - fal.run/fal-ai/requests/{id}
        let statusUrl = "https://fal.run/fal-ai/requests/\(requestId)"
        
        guard let url = URL(string: statusUrl) else {
            throw URLError(.badURL)
        }
        
        print("📡 Status URL: \(statusUrl)")
        
        // Poll up to 60 times (2 minutes)
        for attempt in 1...60 {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 30
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("⚠️ Attempt \(attempt): No HTTP response")
                    continue
                }
                
                if attempt % 5 == 0 {
                    print("📡 Polling attempt \(attempt)/60... (status: \(httpResponse.statusCode))")
                }
                
                guard httpResponse.statusCode == 200 else {
                    if attempt % 5 == 0 {
                        print("⚠️ Status code: \(httpResponse.statusCode)")
                    }
                    continue
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("⚠️ Attempt \(attempt): Failed to parse JSON")
                    continue
                }
                
                // Debug: Print response structure every 10 attempts
                if attempt % 10 == 0 {
                    print("🔍 Response keys: \(json.keys)")
                    if let status = json["status"] as? String {
                        print("🔍 Status: \(status)")
                    }
                }
                
                // Check for explicit status field
                if let status = json["status"] as? String {
                    if status == "COMPLETED" {
                        print("🎉 ========================================")
                        print("🎉 STATUS: COMPLETED")
                        print("🎉 Extracting image URL...")
                        print("🎉 ========================================")
                        return try extractImageUrl(from: json)
                    }
                    
                    if status == "FAILED" {
                        let error = json["error"] as? String ?? "Unknown error"
                        print("❌ ========================================")
                        print("❌ GENERATION FAILED")
                        print("❌ Error: \(error)")
                        print("❌ ========================================")
                        throw URLError(.badServerResponse)
                    }
                    
                    // IN_PROGRESS or IN_QUEUE - continue polling
                    continue
                }
                
                // Check if images array exists (implicit completion)
                if json["images"] != nil {
                    print("🎉 ========================================")
                    print("🎉 Images found (implicit completion)")
                    print("🎉 Extracting image URL...")
                    print("🎉 ========================================")
                    return try extractImageUrl(from: json)
                }
                
            } catch {
                if attempt == 60 {
                    print("❌ Max attempts reached")
                    throw error
                }
                print("⚠️ Attempt \(attempt) error: \(error.localizedDescription)")
                continue
            }
        }
        
        print("❌ Timeout after 2 minutes (60 attempts)")
        throw URLError(.timedOut)
    }
    
    // MARK: - Image URL Extraction
    
    private func extractImageUrl(from json: [String: Any]) throws -> String {
        print("🔍 Extracting image URL from response...")
        print("🔍 Available keys: \(json.keys)")
        
        // Try multiple possible formats
        
        // Format 1: images[0].url
        if let images = json["images"] as? [[String: Any]],
           let firstImage = images.first,
           let imageUrl = firstImage["url"] as? String {
            print("✅ Found image at: images[0].url")
            print("✅ URL: \(imageUrl)")
            return imageUrl
        }
        
        // Format 2: image.url
        if let imageDict = json["image"] as? [String: Any],
           let imageUrl = imageDict["url"] as? String {
            print("✅ Found image at: image.url")
            print("✅ URL: \(imageUrl)")
            return imageUrl
        }
        
        // Format 3: url
        if let imageUrl = json["url"] as? String {
            print("✅ Found image at: url")
            print("✅ URL: \(imageUrl)")
            return imageUrl
        }
        
        // Format 4: output.images[0].url
        if let output = json["output"] as? [String: Any],
           let images = output["images"] as? [[String: Any]],
           let firstImage = images.first,
           let imageUrl = firstImage["url"] as? String {
            print("✅ Found image at: output.images[0].url")
            print("✅ URL: \(imageUrl)")
            return imageUrl
        }
        
        // Format 5: data.images[0].url
        if let data = json["data"] as? [String: Any],
           let images = data["images"] as? [[String: Any]],
           let firstImage = images.first,
           let imageUrl = firstImage["url"] as? String {
            print("✅ Found image at: data.images[0].url")
            print("✅ URL: \(imageUrl)")
            return imageUrl
        }
        
        // If we get here, print full JSON for debugging
        print("❌ ========================================")
        print("❌ Could not find image URL in response")
        print("❌ Full JSON: \(json)")
        print("❌ ========================================")
        throw URLError(.cannotParseResponse)
    }
}
