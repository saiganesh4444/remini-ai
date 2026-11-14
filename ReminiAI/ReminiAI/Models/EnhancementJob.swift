import Foundation
import UIKit

struct EnhancementJob: Identifiable {
    let id = UUID()
    let originalImage: UIImage
    var enhancedImage: UIImage?
    let mode: EnhancementMode
    let engine: EngineType
    var progress: Double = 0.0
    var statusMessage: String = "Preparing..."
    var isCompleted: Bool = false
    var error: String?
    let timestamp = Date()
}
