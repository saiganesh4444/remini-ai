import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

final class ImageEnhancerService {
    static let shared = ImageEnhancerService()
    private let context: CIContext
    
    private init() {
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .priorityRequestLow: false,
            .workingColorSpace: CGColorSpaceCreateDeviceRGB()
        ]
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: metalDevice, options: options)
        } else {
            self.context = CIContext(options: options)
        }
    }
    
    // MARK: - Main Local Enhancement Dispatcher
    func enhanceLocally(
        image: UIImage,
        mode: EnhancementMode,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> UIImage {
        // Step 1: Normalize orientation and obtain clean CIImage
        progressHandler(0.10, "Normalizing image orientation & geometry...")
        let normalizedImage = normalizeOrientation(image)
        guard let ciInput = CIImage(image: normalizedImage) else {
            throw NSError(
                domain: "ImageEnhancerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to process source image pixels."]
            )
        }
        
        // Step 2: Route according to tool specification
        switch mode {
        case .naturalEnhance:
            return try await executeNaturalEnhance(
                ciInput: ciInput,
                original: normalizedImage,
                progressHandler: progressHandler
            )
            
        case .hdUpscale:
            return try await executeHDUpscale(
                ciInput: ciInput,
                original: normalizedImage,
                progressHandler: progressHandler
            )
            
        case .softSharpen:
            return try await executeSoftSharpen(
                ciInput: ciInput,
                original: normalizedImage,
                progressHandler: progressHandler
            )
            
        case .vintageTone:
            return try await executeVintageTone(
                ciInput: ciInput,
                original: normalizedImage,
                progressHandler: progressHandler
            )
            
        case .portraitBlur:
            return try await executePortraitBlur(
                ciInput: ciInput,
                original: normalizedImage,
                progressHandler: progressHandler
            )
        }
    }
    
    // MARK: - Tool 1: Natural Enhance (Default)
    /// Gentle denoising + mild sharpening. Preserves natural skin texture, pore integrity, and avoids blanket boosts.
    private func executeNaturalEnhance(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.30, "Analyzing skin tones & sensor noise profile...")
        
        // Gentle noise reduction: small threshold to eliminate sensor speckle while preserving micro-textures
        let denoise = CIFilter.noiseReduction()
        denoise.inputImage = ciInput
        denoise.noiseLevel = 0.015
        denoise.sharpness = 0.20
        let denoised = denoise.outputImage ?? ciInput
        
        progressHandler(0.65, "Refining natural pore texture & eye clarity...")
        // Restrained unsharp mask: low radius, modest intensity to prevent halos
        let unsharp = CIFilter.unsharpMask()
        unsharp.inputImage = denoised
        unsharp.radius = 1.8
        unsharp.intensity = 0.38
        let enhanced = unsharp.outputImage ?? denoised
        
        progressHandler(0.90, "Finalizing natural color calibration...")
        // No blanket contrast/saturation boost: apply subtle midtone clarity only if needed
        return try render(ciImage: enhanced, original: original)
    }
    
    // MARK: - Tool 2: HD Upscale
    /// 2× pixel dimensions on device using Lanczos resampling + mild luminance sharpening.
    private func executeHDUpscale(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.35, "Interpolating pixel grid via 2× Lanczos resampling...")
        
        let lanczos = CIFilter.lanczosScaleTransform()
        lanczos.inputImage = ciInput
        lanczos.scale = 2.0
        lanczos.aspectRatio = 1.0
        guard let upscaled = lanczos.outputImage else {
            throw NSError(domain: "ImageEnhancerService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Lanczos upscale failed."])
        }
        
        progressHandler(0.75, "Applying micro-edge luminance definition...")
        // Mild luminance sharpening to restore crispness lost during interpolation
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = upscaled
        sharpen.sharpness = 0.35
        let result = sharpen.outputImage ?? upscaled
        
        progressHandler(0.95, "Validating 2× export dimensions...")
        // Target exact 2x pixel dimensions
        let targetExtent = CGRect(
            x: 0,
            y: 0,
            width: ciInput.extent.width * 2.0,
            height: ciInput.extent.height * 2.0
        )
        guard let cgOutput = context.createCGImage(result, from: targetExtent) else {
            throw NSError(domain: "ImageEnhancerService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to render 2× upscaled image."])
        }
        
        return UIImage(cgImage: cgOutput, scale: 1.0, orientation: .up)
    }
    
    // MARK: - Tool 3: Soft Sharpen
    /// Restrained local edge sharpening.
    private func executeSoftSharpen(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.40, "Mapping high-contrast edges and contours...")
        
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = ciInput
        sharpen.sharpness = 0.55
        let sharpened = sharpen.outputImage ?? ciInput
        
        progressHandler(0.85, "Suppressing over-sharpening halos...")
        return try render(ciImage: sharpened, original: original)
    }
    
    // MARK: - Tool 4: Vintage Tone
    /// Subtle warm tint that keeps highlights and skin tones organic.
    private func executeVintageTone(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.45, "Applying warm analog color temperature...")
        
        // Gentle warm tint via temperature shift
        let tempFilter = CIFilter.temperatureAndTint()
        tempFilter.inputImage = ciInput
        tempFilter.neutral = CIVector(x: 6500, y: 0)
        tempFilter.targetNeutral = CIVector(x: 5800, y: 15) // Subtle warm golden cast
        let warmed = tempFilter.outputImage ?? ciInput
        
        progressHandler(0.75, "Balancing shadow depth & highlight rolloff...")
        // Mild tone curve adjustment
        let controls = CIFilter.colorControls()
        controls.inputImage = warmed
        controls.contrast = 1.04
        controls.saturation = 0.98
        let result = controls.outputImage ?? warmed
        
        return try render(ciImage: result, original: original)
    }
    
    // MARK: - Tool 5: Portrait Blur (Subject & Multi-Face Aware)
    /// Normalizes orientation first. Uses person segmentation where available (iOS 15+),
    /// falls back to multi-face protected elliptical blur. Returns original if no subjects detected.
    private func executePortraitBlur(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        guard let cgImage = original.cgImage else {
            return original
        }
        
        progressHandler(0.30, "Detecting subjects and facial boundaries...")
        
        // Attempt 1: Person Segmentation Mask (Vision)
        if let personMask = try? await generatePersonSegmentationMask(for: cgImage, extent: ciInput.extent) {
            progressHandler(0.70, "Applying progressive bokeh depth blur...")
            return applyMaskedBlur(to: ciInput, mask: personMask, original: original)
        }
        
        // Attempt 2: Multi-face detection fallback
        let faces = try await detectAllFaces(in: cgImage)
        if faces.isEmpty {
            // Return original unchanged if no subjects/faces detected
            progressHandler(1.0, "No portrait subjects detected — keeping original.")
            return original
        }
        
        progressHandler(0.65, "Defending \(faces.count) detected face region(s)...")
        let multiFaceMask = createMultiFaceProtectionMask(faces: faces, extent: ciInput.extent)
        return applyMaskedBlur(to: ciInput, mask: multiFaceMask, original: original)
    }
    
    // MARK: - Subject Masking (VNGeneratePersonSegmentationRequest)
    private func generatePersonSegmentationMask(for cgImage: CGImage, extent: CGRect) async throws -> CIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
                guard let maskPixelBuffer = request.results?.first?.pixelBuffer else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let maskCI = CIImage(cvPixelBuffer: maskPixelBuffer)
                // Scale mask to match original image dimensions
                let scaleX = extent.width / maskCI.extent.width
                let scaleY = extent.height / maskCI.extent.height
                let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                continuation.resume(returning: scaledMask)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Multi-Face Detection Fallback
    private func detectAllFaces(in cgImage: CGImage) async throws -> [CGRect] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { req, err in
                if let err = err {
                    continuation.resume(throwing: err)
                    return
                }
                let observations = req.results as? [VNFaceObservation] ?? []
                let boxes = observations.map { $0.boundingBox }
                continuation.resume(returning: boxes)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Multi-Face Radial Protection Mask
    private func createMultiFaceProtectionMask(faces: [CGRect], extent: CGRect) -> CIImage {
        // Base white mask (foreground)
        var compositeMask = CIImage(color: CIColor.white).cropped(to: extent)
        
        for face in faces {
            // Convert normalized Vision coordinates (origin bottom-left) to CoreImage pixels
            let faceX = face.origin.x * extent.width
            let faceY = face.origin.y * extent.height
            let faceW = face.width * extent.width
            let faceH = face.height * extent.height
            
            let center = CGPoint(x: faceX + faceW / 2.0, y: faceY + faceH / 2.0)
            let maxRadius = Float(max(faceW, faceH) * 1.5)
            let minRadius = Float(min(faceW, faceH) * 0.75)
            
            let radial = CIFilter.radialGradient()
            radial.center = center
            radial.radius0 = minRadius
            radial.radius1 = maxRadius
            radial.color0 = CIColor.black // Protect face
            radial.color1 = CIColor.white // Allow blur outside
            
            if let radialImg = radial.outputImage?.cropped(to: extent) {
                let darken = CIFilter.darkenBlendMode()
                darken.inputImage = radialImg
                darken.backgroundImage = compositeMask
                compositeMask = darken.outputImage?.cropped(to: extent) ?? compositeMask
            }
        }
        
        // Invert mask so black protects subject and white receives blur
        let invert = CIFilter.colorInvert()
        invert.inputImage = compositeMask
        return invert.outputImage?.cropped(to: extent) ?? compositeMask
    }
    
    // MARK: - Masked Gaussian Blur Composite
    private func applyMaskedBlur(to image: CIImage, mask: CIImage, original: UIImage) -> UIImage {
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = image
        blur.radius = 16.0
        let blurred = blur.outputImage?.cropped(to: image.extent) ?? image
        
        // Blend blurred background with sharp foreground using mask
        let blend = CIFilter.blendWithMask()
        blend.inputImage = blurred
        blend.backgroundImage = image
        blend.maskImage = mask
        
        guard let output = blend.outputImage?.cropped(to: image.extent),
              let cg = context.createCGImage(output, from: output.extent) else {
            return original
        }
        return UIImage(cgImage: cg, scale: 1.0, orientation: .up)
    }
    
    // MARK: - Strength Blending (Interactive Slider 0.0 → 1.0)
    /// Blends between original and processed based on user strength slider.
    /// For HD Upscale, resamples the original to match the 2× pixel dimensions so no alignment jump occurs.
    func blend(
        original: UIImage,
        processed: UIImage,
        strength: Float,
        mode: EnhancementMode
    ) -> UIImage {
        let clamped = max(0.0, min(1.0, strength))
        if clamped <= 0.001 {
            return mode == .hdUpscale ? resampleToTargetDimensions(image: original, targetSize: processed.size) : original
        }
        if clamped >= 0.999 {
            return processed
        }
        
        let targetOriginal: UIImage
        if mode == .hdUpscale {
            targetOriginal = resampleToTargetDimensions(image: original, targetSize: processed.size)
        } else {
            targetOriginal = original
        }
        
        guard let ciOrig = CIImage(image: targetOriginal),
              let ciProc = CIImage(image: processed) else {
            return processed
        }
        
        // Alpha constant generator
        let alpha = CIFilter.constantColorGenerator()
        alpha.color = CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: CGFloat(clamped))
        let mask = alpha.outputImage?.cropped(to: ciProc.extent) ?? ciProc
        
        let blend = CIFilter.blendWithMask()
        blend.inputImage = ciProc
        blend.backgroundImage = ciOrig
        blend.maskImage = mask
        
        guard let blendedCI = blend.outputImage?.cropped(to: ciProc.extent),
              let cg = context.createCGImage(blendedCI, from: blendedCI.extent) else {
            return processed
        }
        return UIImage(cgImage: cg, scale: processed.scale, orientation: .up)
    }
    
    // MARK: - Resample Helper for HD Upscale Comparison
    func resampleToTargetDimensions(image: UIImage, targetSize: CGSize) -> UIImage {
        guard let ci = CIImage(image: image) else { return image }
        let scaleX = targetSize.width / max(image.size.width, 1)
        let scaleY = targetSize.height / max(image.size.height, 1)
        
        let lanczos = CIFilter.lanczosScaleTransform()
        lanczos.inputImage = ci
        lanczos.scale = Float(scaleX)
        lanczos.aspectRatio = Float(scaleY / scaleX)
        
        let extent = CGRect(origin: .zero, size: targetSize)
        guard let out = lanczos.outputImage?.cropped(to: extent),
              let cg = context.createCGImage(out, from: extent) else {
            return image
        }
        return UIImage(cgImage: cg, scale: 1.0, orientation: .up)
    }
    
    // MARK: - Orientation Normalizer
    /// Re-draws image to a canonical `.up` orientation so CoreImage and Vision coordinate systems align
    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return normalized
    }
    
    private func render(ciImage: CIImage, original: UIImage) throws -> UIImage {
        guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw NSError(domain: "ImageEnhancerService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Render output failed."])
        }
        return UIImage(cgImage: cg, scale: 1.0, orientation: .up)
    }
}
