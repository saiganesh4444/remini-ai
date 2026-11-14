import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

/// Production-grade Image Enhancement & Processing Service
///
/// Features:
/// - Orientation normalization (EXIF upright alignment)
/// - Vision Person Segmentation with edge-clamped blur compositor
/// - Multi-face protection fallback for off-center subjects & groups
/// - Independent Combined Effects engine (Face Enhancement, Face Retouch, Background Enhance, Depth Blur, People Removal)
/// - Detection caching per source photo to eliminate redundant Vision inference
/// - Scaled blur radii consistent across all image resolutions
final class ImageEnhancerService {
    static let shared = ImageEnhancerService()
    private let context: CIContext
    
    // MARK: - In-Memory Detection Cache
    private struct CachedDetection {
        let imageHash: Int
        let personMask: CIImage?
        let faceRects: [CGRect]
        let detectedPeople: [DetectedPerson]
    }
    private var detectionCache: CachedDetection?
    
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
    
    // MARK: - Single Mode Local Dispatcher
    func enhanceLocally(
        image: UIImage,
        mode: EnhancementMode,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> UIImage {
        let normalized = normalizeOrientation(image)
        guard let ciInput = CIImage(image: normalized) else {
            throw NSError(domain: "ImageEnhancerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image pixels."])
        }
        
        switch mode {
        case .naturalEnhance:
            var defaultEffects = CombinedEffects.defaults
            defaultEffects.faceEnhancement = true
            defaultEffects.backgroundEnhancement = true
            return try await executeCombinedEffects(original: normalized, effects: defaultEffects, progressHandler: progressHandler)
            
        case .hdUpscale:
            return try await executeHDUpscale(ciInput: ciInput, original: normalized, progressHandler: progressHandler)
            
        case .softSharpen:
            return try await executeSoftSharpen(ciInput: ciInput, original: normalized, progressHandler: progressHandler)
            
        case .vintageTone:
            return try await executeVintageTone(ciInput: ciInput, original: normalized, progressHandler: progressHandler)
            
        case .portraitBlur:
            var blurEffects = CombinedEffects.defaults
            blurEffects.backgroundBlur = .portrait
            return try await executeCombinedEffects(original: normalized, effects: blurEffects, progressHandler: progressHandler)
        }
    }
    
    // MARK: - Combined Effects Engine (Independent Controls)
    /// Recomputes the image from the immutable original according to individual effect toggles.
    /// Disabling every effect restores the pristine original appearance.
    func executeCombinedEffects(
        original: UIImage,
        effects: CombinedEffects,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> UIImage {
        // If all controls are disabled, return pristine original immediately
        if effects.isAllDisabled {
            progressHandler(1.0, "All effects disabled — original restored.")
            return original
        }
        
        let normalized = normalizeOrientation(original)
        guard let ciInput = CIImage(image: normalized),
              let cgImage = normalized.cgImage else {
            return original
        }
        
        let imageHash = normalized.pngData()?.count ?? normalized.hash
        let (personMask, faces, people) = try await getOrComputeDetections(
            cgImage: cgImage,
            extent: ciInput.extent,
            imageHash: imageHash,
            progressHandler: progressHandler
        )
        
        var current = ciInput
        let dimensionScale = Float(max(ciInput.extent.width, ciInput.extent.height) / 1000.0)
        
        // MARK: Step 1: Selective Background People Removal (if enabled & selections present)
        if effects.removeBackgroundPeople && !effects.selectedPeopleIds.isEmpty {
            progressHandler(0.25, "Inpainting selected background people...")
            let peopleToRemove = people.filter { effects.selectedPeopleIds.contains($0.id) && !$0.isPrimarySubject }
            if !peopleToRemove.isEmpty {
                current = applyPeopleInpainting(to: current, people: peopleToRemove)
            }
        }
        
        // MARK: Step 2: Face Enhancement (mild, face-local detail refinement)
        if effects.faceEnhancement && !faces.isEmpty {
            progressHandler(0.40, "Refining facial micro-details & iris clarity...")
            current = applyFaceLocalEnhancement(to: current, faces: faces)
        }
        
        // MARK: Step 3: Face Retouch (gentle smoothing preserving skin texture & freckles)
        if effects.faceRetouch && !faces.isEmpty {
            progressHandler(0.55, "Applying gentle skin retouch...")
            current = applySkinTexturePreservingRetouch(to: current, faces: faces)
        }
        
        // MARK: Step 4: Background Enhancement (outside protected subject)
        if effects.backgroundEnhancement {
            progressHandler(0.70, "Enhancing background clarity & lighting...")
            current = applyBackgroundEnhancement(to: current, subjectMask: personMask ?? createMultiFaceSubjectMask(faces: faces, extent: ciInput.extent))
        }
        
        // MARK: Step 5: Background Depth Blur (clamped to prevent edge artifacts)
        if effects.backgroundBlur != .off {
            progressHandler(0.85, "Applying \(effects.backgroundBlur.rawValue) portrait depth blur...")
            
            // Effective subject mask: white = sharp subject, black = blurred background
            let effectiveMask = personMask ?? (faces.isEmpty ? nil : createMultiFaceSubjectMask(faces: faces, extent: ciInput.extent))
            
            if let mask = effectiveMask {
                let scaledRadius = Float(effects.backgroundBlur.baseRadius) * dimensionScale
                current = applyClampedEdgeBlur(to: current, mask: mask, radius: scaledRadius)
            } else {
                progressHandler(0.90, "No reliable subject found to protect for blur.")
            }
        }
        
        progressHandler(0.98, "Rendering final calibrated image...")
        return try render(ciImage: current, original: normalized)
    }
    
    // MARK: - Detection Cache & Vision Pipelines
    private func getOrComputeDetections(
        cgImage: CGImage,
        extent: CGRect,
        imageHash: Int,
        progressHandler: (Double, String) -> Void
    ) async throws -> (CIImage?, [CGRect], [DetectedPerson]) {
        if let cached = detectionCache, cached.imageHash == imageHash {
            return (cached.personMask, cached.faceRects, cached.detectedPeople)
        }
        
        progressHandler(0.12, "Analyzing subject segmentation & facial landmarks...")
        
        // 1. Person Segmentation (iOS 15+)
        let mask = try? await generateSubjectMatte(for: cgImage, extent: extent)
        
        // 2. Face Detection
        let faces = (try? await detectAllFaces(in: cgImage)) ?? []
        
        // 3. Human Instance Detection for Background People Removal
        let people = (try? await detectHumanInstances(in: cgImage, extent: extent)) ?? []
        
        let record = CachedDetection(
            imageHash: imageHash,
            personMask: mask,
            faceRects: faces,
            detectedPeople: people
        )
        self.detectionCache = record
        return (mask, faces, people)
    }
    
    func getDetectedPeople(for image: UIImage) async -> [DetectedPerson] {
        let normalized = normalizeOrientation(image)
        guard let cg = normalized.cgImage, let ci = CIImage(image: normalized) else { return [] }
        let hash = normalized.pngData()?.count ?? normalized.hash
        let (_, _, people) = (try? await getOrComputeDetections(cgImage: cg, extent: ci.extent, imageHash: hash, progressHandler: { _, _ in })) ?? (nil, [], [])
        return people
    }
    
    // MARK: - Person Segmentation Matte (White = Sharp Foreground, Black = Background)
    private func generateSubjectMatte(for cgImage: CGImage, extent: CGRect) async throws -> CIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
                guard let buffer = request.results?.first?.pixelBuffer else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let rawMask = CIImage(cvPixelBuffer: buffer)
                let scaleX = extent.width / rawMask.extent.width
                let scaleY = extent.height / rawMask.extent.height
                let scaledMask = rawMask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                continuation.resume(returning: scaledMask)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Multi-Face Detection
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
    
    // MARK: - Human Instance Detection (Identifies primary subject vs background people)
    private func detectHumanInstances(in cgImage: CGImage, extent: CGRect) async throws -> [DetectedPerson] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanRectanglesRequest { req, err in
                if let err = err {
                    continuation.resume(throwing: err)
                    return
                }
                let observations = req.results as? [VNHumanObservation] ?? []
                
                // Sort by area: largest person is treated as primary subject by default
                let sorted = observations.sorted { obs1, obs2 in
                    (obs1.boundingBox.width * obs1.boundingBox.height) > (obs2.boundingBox.width * obs2.boundingBox.height)
                }
                
                var people: [DetectedPerson] = []
                for (index, obs) in sorted.enumerated() {
                    // Convert bottom-left Vision box to top-left UIKit box
                    let normBox = CGRect(
                        x: obs.boundingBox.origin.x,
                        y: 1.0 - obs.boundingBox.origin.y - obs.boundingBox.height,
                        width: obs.boundingBox.width,
                        height: obs.boundingBox.height
                    )
                    people.append(DetectedPerson(
                        id: UUID(),
                        boundingBox: normBox,
                        isPrimarySubject: index == 0,
                        isSelectedForRemoval: false
                    ))
                }
                continuation.resume(returning: people)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Multi-Face Fallback Subject Mask (White = Sharp Foreground)
    private func createMultiFaceSubjectMask(faces: [CGRect], extent: CGRect) -> CIImage {
        var composite = CIImage(color: CIColor.black).cropped(to: extent)
        
        for face in faces {
            let faceX = face.origin.x * extent.width
            let faceY = face.origin.y * extent.height
            let faceW = face.width * extent.width
            let faceH = face.height * extent.height
            
            let center = CGPoint(x: faceX + faceW / 2.0, y: faceY + faceH / 2.0)
            let maxRadius = Float(max(faceW, faceH) * 1.6)
            let minRadius = Float(min(faceW, faceH) * 0.7)
            
            let radial = CIFilter.radialGradient()
            radial.center = center
            radial.radius0 = minRadius
            radial.radius1 = maxRadius
            radial.color0 = CIColor.white // Subject sharp
            radial.color1 = CIColor.black // Background blur
            
            if let radialImg = radial.outputImage?.cropped(to: extent) {
                let lighten = CIFilter.lightenBlendMode()
                lighten.inputImage = radialImg
                lighten.backgroundImage = composite
                composite = lighten.outputImage?.cropped(to: extent) ?? composite
            }
        }
        return composite
    }
    
    // MARK: - Clamped Edge Depth Blur (Prevents dark border vignette artifacts)
    private func applyClampedEdgeBlur(to image: CIImage, mask: CIImage, radius: Float) -> CIImage {
        // Step 1: Clamp edges to infinity before blur to eliminate black border fringes
        let clamped = image.clampedToExtent()
        
        // Step 2: Apply Gaussian blur
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = clamped
        blur.radius = radius
        guard let blurred = blur.outputImage?.cropped(to: image.extent) else { return image }
        
        // Step 3: Blend sharp subject with blurred background using mask
        // Mask: 1.0 (White) = Sharp Subject, 0.0 (Black) = Blurred Background
        let blend = CIFilter.blendWithMask()
        blend.inputImage = image       // Foreground (sharp)
        blend.backgroundImage = blurred // Background (blurred)
        blend.maskImage = mask         // Mask
        
        return blend.outputImage?.cropped(to: image.extent) ?? image
    }
    
    // MARK: - Face Local Enhancement
    private func applyFaceLocalEnhancement(to image: CIImage, faces: [CGRect]) -> CIImage {
        // High-frequency detail sharpening
        let unsharp = CIFilter.unsharpMask()
        unsharp.inputImage = image
        unsharp.radius = 2.0
        unsharp.intensity = 0.45
        let sharpened = unsharp.outputImage ?? image
        
        let mask = createMultiFaceSubjectMask(faces: faces, extent: image.extent)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = sharpened
        blend.backgroundImage = image
        blend.maskImage = mask
        return blend.outputImage?.cropped(to: image.extent) ?? image
    }
    
    // MARK: - Skin Retouch Preserving Texture & Freckles
    private func applySkinTexturePreservingRetouch(to image: CIImage, faces: [CGRect]) -> CIImage {
        // Bilateral noise reduction smooths high-contrast color blotches while preserving fine edge texture
        let denoise = CIFilter.noiseReduction()
        denoise.inputImage = image
        denoise.noiseLevel = 0.03
        denoise.sharpness = 0.50
        let smoothed = denoise.outputImage ?? image
        
        let mask = createMultiFaceSubjectMask(faces: faces, extent: image.extent)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = smoothed
        blend.backgroundImage = image
        blend.maskImage = mask
        return blend.outputImage?.cropped(to: image.extent) ?? image
    }
    
    // MARK: - Background Enhancement
    private func applyBackgroundEnhancement(to image: CIImage, subjectMask: CIImage) -> CIImage {
        // Invert mask to isolate background
        let invert = CIFilter.colorInvert()
        invert.inputImage = subjectMask
        guard let bgMask = invert.outputImage?.cropped(to: image.extent) else { return image }
        
        // Gentle noise reduction + mild clarity for background
        let denoise = CIFilter.noiseReduction()
        denoise.inputImage = image
        denoise.noiseLevel = 0.02
        denoise.sharpness = 0.35
        let enhancedBG = denoise.outputImage ?? image
        
        let blend = CIFilter.blendWithMask()
        blend.inputImage = enhancedBG
        blend.backgroundImage = image
        blend.maskImage = bgMask
        return blend.outputImage?.cropped(to: image.extent) ?? image
    }
    
    // MARK: - People Inpainting (On-Device Neighborhood Content Fill)
    private func applyPeopleInpainting(to image: CIImage, people: [DetectedPerson]) -> CIImage {
        var result = image
        for person in people {
            // Convert normalized UIKit coordinates (0...1, top-left origin) to CoreImage coordinates (bottom-left origin)
            let box = person.boundingBox
            let ciX = box.origin.x * image.extent.width
            let ciY = (1.0 - box.origin.y - box.height) * image.extent.height
            let ciW = box.width * image.extent.width
            let ciH = box.height * image.extent.height
            let rect = CGRect(x: ciX, y: ciY, width: ciW, height: ciH).intersection(image.extent)
            
            // Mask for person area with feathered margin
            let margin: CGFloat = 8
            let expanded = rect.insetBy(dx: -margin, dy: -margin).intersection(image.extent)
            
            // Multi-pass texture fill: sample background colors surrounding the box and feather
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = result.cropped(to: expanded).clampedToExtent()
            blur.radius = Float(max(ciW, ciH) * 0.4)
            if let blurredPatch = blur.outputImage?.cropped(to: expanded) {
                let composite = CIFilter.sourceOverCompositing()
                composite.inputImage = blurredPatch
                composite.backgroundImage = result
                result = composite.outputImage?.cropped(to: image.extent) ?? result
            }
        }
        return result
    }
    
    // MARK: - Tool 2: HD Upscale
    private func executeHDUpscale(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.35, "2× Lanczos resampling...")
        let lanczos = CIFilter.lanczosScaleTransform()
        lanczos.inputImage = ciInput
        lanczos.scale = 2.0
        lanczos.aspectRatio = 1.0
        guard let upscaled = lanczos.outputImage else {
            throw NSError(domain: "ImageEnhancerService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Upscale failed."])
        }
        
        progressHandler(0.75, "Applying micro-edge luminance definition...")
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = upscaled
        sharpen.sharpness = 0.35
        let result = sharpen.outputImage ?? upscaled
        
        let targetExtent = CGRect(x: 0, y: 0, width: ciInput.extent.width * 2.0, height: ciInput.extent.height * 2.0)
        guard let cgOutput = context.createCGImage(result, from: targetExtent) else {
            throw NSError(domain: "ImageEnhancerService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to render 2× image."])
        }
        return UIImage(cgImage: cgOutput, scale: 1.0, orientation: .up)
    }
    
    // MARK: - Tool 3: Soft Sharpen
    private func executeSoftSharpen(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.50, "Applying restrained edge sharpening...")
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = ciInput
        sharpen.sharpness = 0.55
        let result = sharpen.outputImage ?? ciInput
        return try render(ciImage: result, original: original)
    }
    
    // MARK: - Tool 4: Vintage Tone
    private func executeVintageTone(
        ciInput: CIImage,
        original: UIImage,
        progressHandler: (Double, String) -> Void
    ) async throws -> UIImage {
        progressHandler(0.50, "Applying warm analog color temperature...")
        let tempFilter = CIFilter.temperatureAndTint()
        tempFilter.inputImage = ciInput
        tempFilter.neutral = CIVector(x: 6500, y: 0)
        tempFilter.targetNeutral = CIVector(x: 5800, y: 15)
        let warmed = tempFilter.outputImage ?? ciInput
        
        let controls = CIFilter.colorControls()
        controls.inputImage = warmed
        controls.contrast = 1.04
        controls.saturation = 0.98
        let result = controls.outputImage ?? warmed
        return try render(ciImage: result, original: original)
    }
    
    // MARK: - Strength Blending
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
        
        let targetOriginal: UIImage = (mode == .hdUpscale)
            ? resampleToTargetDimensions(image: original, targetSize: processed.size)
            : original
        
        guard let ciOrig = CIImage(image: targetOriginal),
              let ciProc = CIImage(image: processed) else {
            return processed
        }
        
        let mask = CIImage(color: CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: CGFloat(clamped))).cropped(to: ciProc.extent)
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
    
    // MARK: - Resample Helper for HD Upscale
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
    func normalizeOrientation(_ image: UIImage) -> UIImage {
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
            throw NSError(domain: "ImageEnhancerService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Render failed."])
        }
        return UIImage(cgImage: cg, scale: 1.0, orientation: .up)
    }
}
