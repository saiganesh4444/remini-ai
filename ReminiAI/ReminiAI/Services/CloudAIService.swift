import Foundation
import UIKit

final class CloudAIService {
    static let shared = CloudAIService()
    
    private init() {}
    
    /// Enhance image using Cloud Neural Network (GFPGAN / Real-ESRGAN / CodeFormer)
    func enhanceViaCloud(
        image: UIImage,
        mode: EnhancementMode,
        apiKey: String,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> UIImage {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(
                domain: "CloudAI",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Please enter your Replicate / Cloud API Key in Settings to use Cloud Neural Engine."]
            )
        }
        
        progressHandler(0.2, "Uploading image to cloud neural pipeline...")
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "CloudAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image."])
        }
        
        let base64Image = "data:image/jpeg;base64," + jpegData.base64EncodedString()
        
        progressHandler(0.4, "Dispatching to GPU cluster (GFPGAN / CodeFormer)...")
        
        // Target model: GFPGAN face restoration or Real-ESRGAN super-resolution
        let modelVersion = (mode == .superRes)
            ? "42fed1c4974146d4d2414e2be2c5277c7fcf05fcc3a73abf41610695738c1d7b" // Real-ESRGAN
            : "9283608cc6b7be6b65a8e44983db012355fde4132009bf99d976b2f0896856a3" // GFPGAN
        
        var request = URLRequest(url: URL(string: "https://api.replicate.com/v1/predictions")!)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "version": modelVersion,
            "input": [
                "img": base64Image,
                "version": "v1.4",
                "scale": (mode == .superRes ? 4 : 2)
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server response."
            throw NSError(domain: "CloudAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cloud API error: \(errorText)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictionId = json["id"] as? String else {
            throw NSError(domain: "CloudAI", code: -3, userInfo: [NSLocalizedDescriptionKey: "Malformed response from AI server."])
        }
        
        // Poll for completion
        let resultUrl = try await pollPrediction(id: predictionId, apiKey: apiKey, progressHandler: progressHandler)
        
        progressHandler(0.9, "Downloading enhanced high-res image...")
        let (downloadedData, _) = try await URLSession.shared.data(from: resultUrl)
        guard let finalImage = UIImage(data: downloadedData) else {
            throw NSError(domain: "CloudAI", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode output image."])
        }
        
        progressHandler(1.0, "Ready!")
        return finalImage
    }
    
    private func pollPrediction(
        id: String,
        apiKey: String,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> URL {
        let endpoint = URL(string: "https://api.replicate.com/v1/predictions/\(id)")!
        var request = URLRequest(url: endpoint)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var attempts = 0
        while attempts < 60 {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
            attempts += 1
            
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else {
                continue
            }
            
            if status == "succeeded" {
                if let output = json["output"] as? String, let url = URL(string: output) {
                    return url
                } else if let outputArray = json["output"] as? [String], let first = outputArray.first, let url = URL(string: first) {
                    return url
                }
            } else if status == "failed" || status == "canceled" {
                let err = json["error"] as? String ?? "Prediction failed."
                throw NSError(domain: "CloudAI", code: -5, userInfo: [NSLocalizedDescriptionKey: err])
            } else {
                let p = min(0.4 + Double(attempts) * 0.01, 0.85)
                progressHandler(p, "Restoring facial textures & resolving pixels (\(status))...")
            }
        }
        throw NSError(domain: "CloudAI", code: -6, userInfo: [NSLocalizedDescriptionKey: "Prediction timed out."])
    }
}
