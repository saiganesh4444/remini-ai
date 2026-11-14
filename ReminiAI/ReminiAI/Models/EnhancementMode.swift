import Foundation
import SwiftUI

/// The 5 core enhancement tools supported by ReminiAI
enum EnhancementMode: String, CaseIterable, Identifiable, Codable {
    case naturalEnhance = "Natural Enhance"
    case hdUpscale = "HD Upscale"
    case softSharpen = "Soft Sharpen"
    case vintageTone = "Vintage Tone"
    case portraitBlur = "Portrait Blur"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .naturalEnhance: return "sparkles"
        case .hdUpscale: return "arrow.up.left.and.down.right.magnifyingglass"
        case .softSharpen: return "camera.filters"
        case .vintageTone: return "sun.max"
        case .portraitBlur: return "person.crop.circle"
        }
    }

    var shortDescription: String {
        switch self {
        case .naturalEnhance:
            return "Gentle denoising and mild sharpening that preserves skin texture"
        case .hdUpscale:
            return "Double pixel dimensions on device using Lanczos resampling"
        case .softSharpen:
            return "Improve local edge definition with restrained sharpening"
        case .vintageTone:
            return "Apply a subtle warm tint to shadows and midtones"
        case .portraitBlur:
            return "Subject & face-aware background blur with edge protection"
        }
    }
    
    var detailedDescription: String {
        switch self {
        case .naturalEnhance:
            return "Removes high-ISO sensor grain while keeping natural pores, hair strands, and iris reflections intact. Avoids blanket contrast or saturation boosts."
        case .hdUpscale:
            return "Upscales the image 2× in width and height (4× total pixels) using high-precision bicubic/Lanczos interpolation and luminance crispness."
        case .softSharpen:
            return "Applies localized edge enhancement to gently recover soft focus without producing harsh white halos or brittle artifacts."
        case .vintageTone:
            return "Infuses subtle warmth and classic tonal harmony into midtones without crushing highlight details or oversaturating skin."
        case .portraitBlur:
            return "Extracts a subject segmentation mask or multi-face geometry to defend foreground subjects, applying progressive lens defocus to the background."
        }
    }

    var badgeText: String? {
        switch self {
        case .naturalEnhance: return "DEFAULT"
        case .hdUpscale: return "2× RES"
        case .portraitBlur: return "DEPTH"
        default: return nil
        }
    }
    
    /// Whether this tool can run on Cloud AI (GFPGAN / Real-ESRGAN) or is device-only
    var isSupportedOnCloud: Bool {
        switch self {
        case .naturalEnhance, .hdUpscale:
            return true
        case .softSharpen, .vintageTone, .portraitBlur:
            return false
        }
    }
}

enum EngineType: String, CaseIterable, Identifiable, Codable {
    case onDevice = "On-Device Neural Engine"
    case cloudAI = "Cloud AI (Replicate)"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .onDevice:
            return "Runs 100% locally on your iPhone 13 Apple Neural Engine (A15 Bionic) via CoreImage and Vision. Private, instant, and requires zero network access."
        case .cloudAI:
            return "Uploads the selected photo to Replicate servers (GFPGAN for Natural Enhance, Real-ESRGAN for HD Upscale). Requires an API token."
        }
    }
}
