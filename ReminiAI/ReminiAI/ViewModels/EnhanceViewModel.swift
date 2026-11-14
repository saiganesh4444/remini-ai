import Foundation
import SwiftUI
import UIKit
import PhotosUI

@MainActor
final class EnhanceViewModel: ObservableObject {
    // MARK: - App State
    @Published var selectedImage: UIImage?
    @Published var enhancedImage: UIImage?
    @Published var selectedMode: EnhancementMode = .enhance
    @Published var selectedEngine: EngineType = .onDevice
    @Published var cloudApiKey: String {
        didSet {
            UserDefaults.standard.set(cloudApiKey, forKey: "remini_cloud_api_key")
        }
    }
    
    // MARK: - Processing State
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    @Published var saveSuccessAlert: Bool = false
    
    // MARK: - Navigation / Views
    @Published var showComparisonView: Bool = false
    @Published var showSettingsView: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var showCameraPicker: Bool = false
    
    // MARK: - PhotosPickerItem Support
    @Published var photoPickerItem: PhotosPickerItem? {
        didSet {
            Task {
                await loadPickedImage()
            }
        }
    }
    
    private let enhancerService = ImageEnhancerService.shared
    private let cloudService = CloudAIService.shared
    private let photoManager = PhotoLibraryManager.shared
    
    init() {
        self.cloudApiKey = UserDefaults.standard.string(forKey: "remini_cloud_api_key") ?? ""
    }
    
    // MARK: - Image Loading
    func loadPickedImage() async {
        guard let photoPickerItem = photoPickerItem else { return }
        do {
            if let data = try await photoPickerItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.selectedImage = image
                self.enhancedImage = nil
                self.startEnhancement()
            }
        } catch {
            self.errorMessage = "Failed to load selected photo."
            self.showErrorAlert = true
        }
    }
    
    func setImageFromCamera(_ image: UIImage) {
        self.selectedImage = image
        self.enhancedImage = nil
        self.startEnhancement()
    }
    
    // MARK: - Enhancement Trigger
    func startEnhancement() {
        guard let inputImage = selectedImage else { return }
        
        isProcessing = true
        progress = 0.0
        statusMessage = "Initializing Neural Pipeline..."
        errorMessage = nil
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        Task {
            do {
                let result: UIImage
                if selectedEngine == .onDevice {
                    result = try await enhancerService.enhanceLocally(
                        image: inputImage,
                        mode: selectedMode
                    ) { [weak self] prog, msg in
                        Task { @MainActor in
                            self?.progress = prog
                            self?.statusMessage = msg
                        }
                    }
                } else {
                    result = try await cloudService.enhanceViaCloud(
                        image: inputImage,
                        mode: selectedMode,
                        apiKey: cloudApiKey
                    ) { [weak self] prog, msg in
                        Task { @MainActor in
                            self?.progress = prog
                            self?.statusMessage = msg
                        }
                    }
                }
                
                self.enhancedImage = result
                self.isProcessing = false
                self.showComparisonView = true
                
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            } catch {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }
    
    // MARK: - Re-enhance with different tool
    func reprocessWithMode(_ mode: EnhancementMode) {
        self.selectedMode = mode
        startEnhancement()
    }
    
    // MARK: - Save to Photos
    func saveEnhancedImage() {
        guard let output = enhancedImage else { return }
        Task {
            do {
                try await photoManager.saveImageToPhotos(output)
                self.saveSuccessAlert = true
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
            } catch {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    func reset() {
        self.selectedImage = nil
        self.enhancedImage = nil
        self.isProcessing = false
        self.showComparisonView = false
    }
}
