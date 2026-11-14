import Foundation
import SwiftUI

enum EnhancementMode: String, CaseIterable, Identifiable {
    case enhance = "Face Enhance"
    case superRes = "HD 4x Upscale"
    case deblur = "Unblur & Sharpen"
    case colorize = "Vintage Colorize"
    case portrait = "Portrait Depth"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .enhance: return "sparkles"
        case .superRes: return "arrow.up.left.and.down.right.magnifyingglass"
        case .deblur: return "camera.filters"
        case .colorize: return "paintpalette.fill"
        case .portrait: return "person.crop.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .enhance: return "Recover facial micro-details & skin textures"
        case .superRes: return "4K ultra-sharp resolution enhancement"
        case .deblur: return "Eliminate motion blur & camera shake"
        case .colorize: return "Turn black & white memories to vibrant color"
        case .portrait: return "Professional bokeh background defocus"
        }
    }

    var badge: String? {
        switch self {
        case .enhance: return "POPULAR"
        case .superRes: return "PRO"
        case .colorize: return "NEW"
        default: return nil
        }
    }
}

enum EngineType: String, CaseIterable, Identifiable {
    case onDevice = "On-Device Neural Engine"
    case cloudAI = "Cloud AI (GFPGAN / CodeFormer)"

    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .onDevice:
            return "Fast, 100% private, runs directly on iPhone 13 Apple Neural Engine (A15 Bionic) via CoreImage/Vision."
        case .cloudAI:
            return "Server-grade cloud GPU models (GFPGAN, Real-ESRGAN, CodeFormer) for extreme restoration."
        }
    }
}
