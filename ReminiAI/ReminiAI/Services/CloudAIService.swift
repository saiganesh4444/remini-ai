import Foundation
import UIKit

/// Network & AI Service for Cloud Processing via Replicate API
final class CloudAIService {
    static let shared = CloudAIService()
    
    private init() {}
    
    /// Enhance image using Cloud Neural Network (GFPGAN for Natural Enhance, Real-ESRGAN for HD Upscale)
    func enhanceViaCloud(
        image: UIImage,
        mode: EnhancementMode,
        apiKey: String,
        jobId: UUID,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> UIImage {
        // Validation 1: Unsupported Tool Routing
        guard mode.isSupportedOnCloud else {
            throw CloudAIError.unsupportedTool(mode)
        }
        
        // Validation 2: Token Check
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw CloudAIError.missingToken
        }
        
        progressHandler(0.15, "Compressing photo for cloud transfer...")
        // Compress JPEG to reasonable upload size (under 10MB)
        guard let jpegData = image.jpegData(compressionQuality: 0.88) else {
            throw CloudAIError.encodingFailed
        }
        let base64Image = "data:image/jpeg;base64," + jpegData.base64EncodedString()
        
        progressHandler(0.30, "Dispatching to Replicate GPU cluster...")
        
        // Target model configuration
        let modelVersion: String
        let inputPayload: [String: Any]
        
        if mode == .hdUpscale {
            // Real-ESRGAN (Super-Resolution, face_enhance disabled by default)
            modelVersion = "42fed1c4974146d4d2414e2be2c5277c7fcf05fcc3a73abf41610695738c1d7b"
            inputPayload = [
                "image": base64Image,
                "scale": 2,
                "face_enhance": false
            ]
        } else {
            // GFPGAN (Natural facial restoration)
            modelVersion = "9283608cc6b7be6b65a8e44983db012355fde4132009bf99d976b2f0896856a3"
            inputPayload = [
                "img": base64Image,
                "version": "v1.4",
                "scale": 1
            ]
        }
        
        guard let endpoint = URL(string: "https://api.replicate.com/v1/predictions") else {
            throw CloudAIError.invalidURL
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Token \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "version": modelVersion,
            "input": inputPayload
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CloudAIError.networkFailure(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudAIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw CloudAIError.invalidCredentials
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String
                ?? String(data: data, encoding: .utf8)
                ?? "Server error (\(httpResponse.statusCode))"
            throw CloudAIError.serverError(serverMsg)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictionId = json["id"] as? String else {
            throw CloudAIError.malformedResponse
        }
        
        // Poll for completion
        let resultURL = try await pollPrediction(
            id: predictionId,
            apiKey: trimmedKey,
            progressHandler: progressHandler
        )
        
        progressHandler(0.92, "Downloading restored high-res photo...")
        let (downloadedData, _): (Data, URLResponse)
        do {
            (downloadedData, _) = try await URLSession.shared.data(from: resultURL)
        } catch {
            throw CloudAIError.networkFailure("Failed to download output image.")
        }
        
        guard let finalImage = UIImage(data: downloadedData) else {
            throw CloudAIError.invalidResultImage
        }
        
        progressHandler(1.0, "Ready!")
        return finalImage
    }
    
    // MARK: - Polling
    private func pollPrediction(
        id: String,
        apiKey: String,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> URL {
        guard let endpoint = URL(string: "https://api.replicate.com/v1/predictions/\(id)") else {
            throw CloudAIError.invalidURL
        }
        
        var request = URLRequest(url: endpoint)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        
        var attempts = 0
        let maxAttempts = 60 // 60 * 1.5s = 90s max
        
        while attempts < maxAttempts {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 1_500_000_000)
            attempts += 1
            
            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch {
                if Task.isCancelled { throw CloudAIError.cancelled }
                continue
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                continue
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else {
                continue
            }
            
            if status == "succeeded" {
                if let outputStr = json["output"] as? String, let url = URL(string: outputStr) {
                    return url
                } else if let outputArr = json["output"] as? [String], let first = outputArr.first, let url = URL(string: first) {
                    return url
                } else {
                    throw CloudAIError.invalidResultImage
                }
            } else if status == "failed" || status == "canceled" {
                let err = json["error"] as? String ?? "Prediction failed on Replicate."
                throw CloudAIError.serverError(err)
            } else {
                let stepProgress = min(0.35 + Double(attempts) * 0.015, 0.88)
                progressHandler(stepProgress, "Neural inference running on Replicate (\(status))...")
            }
        }
        
        throw CloudAIError.timeout
    }
}

// MARK: - Cloud AI Error Types
enum CloudAIError: LocalizedError {
    case missingToken
    case invalidCredentials
    case unsupportedTool(EnhancementMode)
    case encodingFailed
    case networkFailure(String)
    case invalidResponse
    case serverError(String)
    case malformedResponse
    case timeout
    case cancelled
    case invalidResultImage
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Replicate API token is missing. Please enter your API token in Settings or switch to the On-Device Neural Engine."
        case .invalidCredentials:
            return "Authentication failed (401). Your Replicate API token appears to be invalid or expired. Please check Settings."
        case .unsupportedTool(let mode):
            return "'\(mode.rawValue)' is not available on Cloud AI. Please use On-Device mode for this tool."
        case .encodingFailed:
            return "Could not prepare photo for upload. Please try a different photo."
        case .networkFailure(let msg):
            return "Network connection error: \(msg). Check your internet connection and try again."
        case .invalidResponse:
            return "Received an unexpected response from the cloud server."
        case .serverError(let msg):
            return "Cloud AI server reported: \(msg)"
        case .malformedResponse:
            return "Malformed data received from Replicate API."
        case .timeout:
            return "Cloud processing timed out after 90 seconds. Please try again or switch to On-Device."
        case .cancelled:
            return "Cloud processing was cancelled."
        case .invalidResultImage:
            return "Cloud model did not return a valid result image."
        case .invalidURL:
            return "Invalid API URL endpoint."
        }
    }
}
