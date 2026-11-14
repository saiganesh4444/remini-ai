import Foundation
import UIKit

/// Presets for background optical depth blur
enum BlurPreset: String, CaseIterable, Identifiable, Codable {
    case off = "Off"
    case soft = "Soft"
    case portrait = "Portrait"
    case strong = "Strong"
    
    var id: String { rawValue }
    
    /// Base radius normalized to a standard 1000px image dimension
    var baseRadius: CGFloat {
        switch self {
        case .off: return 0
        case .soft: return 8
        case .portrait: return 18
        case .strong: return 32
        }
    }
    
    var subtitle: String {
        switch self {
        case .off: return "No depth blur applied"
        case .soft: return "Subtle separation (~f/4.0)"
        case .portrait: return "Classic portrait bokeh (~f/2.8)"
        case .strong: return "Defocused background blur (~f/1.4)"
        }
    }
}

/// Represents a detected human instance for selective crowd/background removal
struct DetectedPerson: Identifiable, Equatable, Hashable {
    let id: String
    let boundingBox: CGRect // Normalized (0...1) in UIKit coordinates (top-left origin)
    let isPrimarySubject: Bool
    var isSelectedForRemoval: Bool = false
    
    /// Stable deterministic identifier based on normalized bounding box coordinates
    static func makeStableId(sessionId: UUID, box: CGRect) -> String {
        let ix = Int(box.origin.x * 1000)
        let iy = Int(box.origin.y * 1000)
        let iw = Int(box.width * 1000)
        let ih = Int(box.height * 1000)
        return "person_\(sessionId.uuidString.prefix(6))_\(ix)_\(iy)_\(iw)_\(ih)"
    }
}

/// Independent enhancement controls that can be combined or toggled individually
struct CombinedEffects: Equatable {
    /// Mild face-local detail refinement (eyes, hair, mouth, identifying features)
    var faceEnhancement: Bool = true
    
    /// Optional gentle smoothing that preserves freckles, moles, and skin texture
    var faceRetouch: Bool = false
    
    /// Mild denoising & detail refinement outside the protected subject
    var backgroundEnhancement: Bool = true
    
    /// Background depth blur preset
    var backgroundBlur: BlurPreset = .off
    
    /// Selective background people removal
    var removeBackgroundPeople: Bool = false
    
    /// Stable IDs of detected people chosen for removal
    var selectedPeopleIds: Set<String> = []
    
    /// Default configuration: Natural Enhance defaults
    static let defaults = CombinedEffects(
        faceEnhancement: true,
        faceRetouch: false,
        backgroundEnhancement: true,
        backgroundBlur: .off,
        removeBackgroundPeople: false,
        selectedPeopleIds: []
    )
    
    /// True if all effects are disabled (restoring pristine original appearance)
    var isAllDisabled: Bool {
        !faceEnhancement &&
        !faceRetouch &&
        !backgroundEnhancement &&
        backgroundBlur == .off &&
        (!removeBackgroundPeople || selectedPeopleIds.isEmpty)
    }
    
    /// Count of actively enabled adjustments
    var activeCount: Int {
        var count = 0
        if faceEnhancement { count += 1 }
        if faceRetouch { count += 1 }
        if backgroundEnhancement { count += 1 }
        if backgroundBlur != .off { count += 1 }
        if removeBackgroundPeople && !selectedPeopleIds.isEmpty { count += 1 }
        return count
    }
}
