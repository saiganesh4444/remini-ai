import Foundation
import SwiftUI
import UIKit
import PhotosUI

@MainActor
final class EnhanceViewModel: ObservableObject {
    // MARK: - Selected Tab
    enum Tab: String, CaseIterable, Identifiable {
        case home = "Home"
        case search = "Search"
        case add = "Add"
        case activity = "Activity"
        case profile = "Profile"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .home: return "house"
            case .search: return "magnifyingglass"
            case .add: return "plus"
            case .activity: return "clock.arrow.circlepath"
            case .profile: return "person"
            }
        }
    }
    
    @Published var selectedTab: Tab = .home
    
    // MARK: - Photo & Enhancement State
    @Published var selectedImage: UIImage?
    @Published var unblendedEnhancedImage: UIImage?
    @Published var displayEnhancedImage: UIImage?
    @Published var selectedMode: EnhancementMode = .naturalEnhance
    @Published var selectedEngine: EngineType = .onDevice
    
    // MARK: - Strength Slider (0.0 → 1.0)
    @Published var strength: Float = 1.0 {
        didSet {
            updateBlendedOutput()
        }
    }
    
    // MARK: - Processing & Job Concurrency
    @Published var isProcessing: Bool = false
    @Published var isImporting: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var currentJobId: UUID?
    
    // MARK: - Search State
    @Published var searchQuery: String = ""
    
    var filteredTools: [EnhancementMode] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return EnhancementMode.allCases
        }
        return EnhancementMode.allCases.filter { mode in
            mode.rawValue.lowercased().contains(trimmed) ||
            mode.shortDescription.lowercased().contains(trimmed)
        }
    }
    
    // MARK: - Alerts & Navigation
    @Published var showComparisonView: Bool = false
    @Published var showSettingsView: Bool = false
    @Published var showAddActionSheet: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var showCameraPicker: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    @Published var offerSwitchToOnDevice: Bool = false
    @Published var saveSuccessAlert: Bool = false
    
    // MARK: - Activity History
    @Published var activityItems: [ActivityItem] = []
    
    // MARK: - PhotosPickerItem Binding
    @Published var photoPickerItem: PhotosPickerItem? {
        didSet {
            guard !isImporting else { return }
            Task {
                await loadPickedImage()
            }
        }
    }
    
    // MARK: - Services
    private let enhancerService = ImageEnhancerService.shared
    private let cloudService = CloudAIService.shared
    private let photoManager = PhotoLibraryManager.shared
    private let keychainManager = KeychainManager.shared
    private let historyManager = ActivityHistoryManager.shared
    
    // MARK: - Keychain Token Binding
    @Published var cloudApiKey: String = "" {
        didSet {
            keychainManager.saveReplicateToken(cloudApiKey)
        }
    }
    
    init() {
        self.cloudApiKey = keychainManager.getReplicateToken() ?? ""
        self.activityItems = historyManager.loadHistory()
    }
    
    // MARK: - Image Import
    func loadPickedImage() async {
        guard let item = photoPickerItem, !isImporting else { return }
        isImporting = true
        defer {
            isImporting = false
            photoPickerItem = nil
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                setImageForEnhancement(image)
            }
        } catch {
            self.errorMessage = "Failed to load selected photo from your library."
            self.showErrorAlert = true
        }
    }
    
    func setImageFromCamera(_ image: UIImage) {
        guard !isImporting else { return }
        setImageForEnhancement(image)
    }
    
    private func setImageForEnhancement(_ image: UIImage) {
        self.selectedImage = image
        self.unblendedEnhancedImage = nil
        self.displayEnhancedImage = nil
        self.strength = 1.0
        startEnhancement()
    }
    
    // MARK: - Enhancement Trigger & Concurrency Protection
    func startEnhancement() {
        guard let inputImage = selectedImage else { return }
        
        // Generate new job ID; prevents race conditions from late previous jobs
        let newJobId = UUID()
        self.currentJobId = newJobId
        
        self.isProcessing = true
        self.progress = 0.0
        self.statusMessage = "Starting \(selectedMode.rawValue)..."
        self.errorMessage = nil
        self.offerSwitchToOnDevice = false
        
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        Task {
            do {
                let result: UIImage
                if selectedEngine == .onDevice || !selectedMode.isSupportedOnCloud {
                    result = try await enhancerService.enhanceLocally(
                        image: inputImage,
                        mode: selectedMode
                    ) { [weak self] prog, msg in
                        Task { @MainActor in
                            guard self?.currentJobId == newJobId else { return }
                            self?.progress = prog
                            self?.statusMessage = msg
                        }
                    }
                } else {
                    result = try await cloudService.enhanceViaCloud(
                        image: inputImage,
                        mode: selectedMode,
                        apiKey: cloudApiKey,
                        jobId: newJobId
                    ) { [weak self] prog, msg in
                        Task { @MainActor in
                            guard self?.currentJobId == newJobId else { return }
                            self?.progress = prog
                            self?.statusMessage = msg
                        }
                    }
                }
                
                // Concurrency verification: verify this is still the active job
                guard self.currentJobId == newJobId else { return }
                
                self.unblendedEnhancedImage = result
                self.updateBlendedOutput()
                self.isProcessing = false
                self.showComparisonView = true
                
                let successHaptic = UINotificationFeedbackGenerator()
                successHaptic.notificationOccurred(.success)
            } catch {
                guard self.currentJobId == newJobId else { return }
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                
                if case CloudAIError.unsupportedTool = error {
                    self.offerSwitchToOnDevice = true
                }
                
                self.showErrorAlert = true
                let errHaptic = UINotificationFeedbackGenerator()
                errHaptic.notificationOccurred(.error)
            }
        }
    }
    
    // MARK: - Mode Switching
    func selectModeAndReprocess(_ mode: EnhancementMode) {
        self.selectedMode = mode
        if selectedImage != nil {
            startEnhancement()
        }
    }
    
    func switchToOnDeviceAndRetry() {
        self.selectedEngine = .onDevice
        self.startEnhancement()
    }
    
    // MARK: - Real-time Strength Blending
    private func updateBlendedOutput() {
        guard let original = selectedImage,
              let processed = unblendedEnhancedImage else {
            self.displayEnhancedImage = unblendedEnhancedImage
            return
        }
        
        self.displayEnhancedImage = enhancerService.blend(
            original: original,
            processed: processed,
            strength: strength,
            mode: selectedMode
        )
    }
    
    // MARK: - Save & Record Activity
    func saveEnhancedImage() {
        guard let output = displayEnhancedImage,
              let original = selectedImage else { return }
        
        Task {
            do {
                try await photoManager.saveImageToPhotos(output)
                
                // Record in activity history
                let item = historyManager.recordActivity(
                    image: output,
                    mode: selectedMode,
                    engine: selectedEngine,
                    strength: strength,
                    originalSize: original.size,
                    outputSize: output.size
                )
                self.activityItems.insert(item, at: 0)
                
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
        self.unblendedEnhancedImage = nil
        self.displayEnhancedImage = nil
        self.isProcessing = false
        self.showComparisonView = false
        self.currentJobId = nil
    }
}
