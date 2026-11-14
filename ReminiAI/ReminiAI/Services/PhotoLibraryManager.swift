import Foundation
import UIKit
import Photos

final class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()
    
    private init() {}
    
    func saveImageToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(
                domain: "PhotoLibraryManager",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Photo library access denied. Please allow access in iPhone Settings."]
            )
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
