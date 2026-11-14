import SwiftUI

/// Accessible, Zoomable, and Pannable Split Before/After Comparison Component
///
/// Features:
/// - Before on Left, After on Right
/// - Viewport-anchored vertical divider line with 44×44 pt touch handle
/// - Strict gesture locking: moves divider OR pans photo decided once on touch-down
/// - Synchronized 1× to 5× two-finger pinch-to-zoom on both layers
/// - One-finger panning when zoomed in (dragging handle never pans photo)
/// - Visible zoom controls (+ / - / reset pill) for keyboard, mouse, and accessibility
/// - Double-tap to reset zoom and pan while preserving divider position
/// - Preserves zoom & divider during effect edits on the same photo; resets on new photo
/// - Accessible slider with percentage and VoiceOver actions
struct BeforeAfterSlider: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    
    // Divider Position (0.02 ... 0.98), anchored to viewport coordinates
    @State private var sliderPosition: CGFloat = 0.50
    @State private var isDraggingHandle: Bool = false
    
    // Gesture locking to prevent long drags from switching mid-gesture
    private enum ActiveGesture {
        case none
        case movingDivider
        case panningPhoto
    }
    @State private var activeGesture: ActiveGesture = .none
    
    // Zoom & Pan State (applied identically to both Before & After layers)
    @State private var currentScale: CGFloat = 1.0
    @State private var steadyScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var steadyOffset: CGSize = .zero
    
    // Photo Session Tracking
    var photoId: UUID = UUID()
    @State private var lastPhotoId: UUID?
    
    // Constants
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    private let handleTouchWidth: CGFloat = 56.0
    
    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let viewportHeight = geometry.size.height
            let splitX = max(0, min(viewportWidth, viewportWidth * sliderPosition))
            let activeScale = max(minScale, min(maxScale, steadyScale * currentScale))
            let activeOffset = CGSize(
                width: steadyOffset.width + currentOffset.width,
                height: steadyOffset.height + currentOffset.height
            )
            
            ZStack(alignment: .leading) {
                // Background neutral canvas
                Color.black.opacity(0.85).ignoresSafeArea()
                
                // MARK: - Layer 1: After Image (Enhanced, visible on Right of divider)
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewportWidth, height: viewportHeight)
                    .scaleEffect(activeScale)
                    .offset(activeOffset)
                
                // MARK: - Layer 2: Before Image (Original, visible on Left of divider)
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewportWidth, height: viewportHeight)
                    .scaleEffect(activeScale)
                    .offset(activeOffset)
                    // Viewport-anchored clip mask: reveals Left of splitX
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: splitX)
                            Spacer(minLength: 0)
                        }
                        .frame(width: viewportWidth, height: viewportHeight)
                    )
                
                // MARK: - Viewport-Anchored Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2.5)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 0)
                    .position(x: splitX, y: viewportHeight / 2)
                    .allowsHitTesting(false)
                
                // MARK: - Center Grab Handle (44×44 pt minimum touch target)
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(ReminiDesign.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(ReminiDesign.primary)
                    }
                }
                .position(x: splitX, y: viewportHeight / 2)
                .scaleEffect(isDraggingHandle ? 1.15 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isDraggingHandle)
                .allowsHitTesting(false)
                
                // MARK: - Viewport Badges: BEFORE (Left) and AFTER (Right)
                VStack {
                    HStack {
                        Text("BEFORE")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.60))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 3)
                            .opacity(sliderPosition > 0.10 ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: sliderPosition)
                        
                        Spacer()
                        
                        Text("AFTER")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.92))
                            .foregroundColor(ReminiDesign.primary)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 3)
                            .opacity(sliderPosition < 0.90 ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: sliderPosition)
                    }
                    .padding(ReminiDesign.space12)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // MARK: - Visible Zoom Controls (overlay for touch, mouse, and keyboard users)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            // Zoom Out
                            Button(action: {
                                zoomBy(-0.5, in: geometry.size)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.white)
                            }
                            .disabled(activeScale <= minScale + 0.05)
                            
                            // Zoom Pill / Double Tap Reset
                            Button(action: {
                                resetZoomAnimated()
                            }) {
                                Text(String(format: "%.1f×", activeScale))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .frame(height: 36)
                            }
                            
                            // Zoom In
                            Button(action: {
                                zoomBy(0.5, in: geometry.size)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.white)
                            }
                            .disabled(activeScale >= maxScale - 0.05)
                        }
                        .padding(.horizontal, 4)
                        .background(Color.black.opacity(0.70))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.25), radius: 4)
                        .padding(ReminiDesign.space12)
                    }
                }
            }
            .contentShape(Rectangle())
            // MARK: - Strictly Locked Drag Gesture
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Decide gesture mode once at start of gesture and lock it
                        if activeGesture == .none {
                            let startX = value.startLocation.x
                            let isNearHandle = abs(startX - splitX) < handleTouchWidth
                            
                            if isNearHandle || activeScale <= 1.05 {
                                activeGesture = .movingDivider
                                isDraggingHandle = true
                            } else {
                                activeGesture = .panningPhoto
                                isDraggingHandle = false
                            }
                        }
                        
                        // Execute according to locked mode
                        switch activeGesture {
                        case .movingDivider:
                            let newPos = value.location.x / viewportWidth
                            sliderPosition = max(0.02, min(0.98, newPos))
                            
                        case .panningPhoto:
                            let maxPanX = (viewportWidth * (activeScale - 1.0)) / 2.0
                            let maxPanY = (viewportHeight * (activeScale - 1.0)) / 2.0
                            
                            let proposedX = steadyOffset.width + value.translation.width
                            let proposedY = steadyOffset.height + value.translation.height
                            
                            currentOffset = CGSize(
                                width: max(-maxPanX, min(maxPanX, proposedX)) - steadyOffset.width,
                                height: max(-maxPanY, min(maxPanY, proposedY)) - steadyOffset.height
                            )
                            
                        case .none:
                            break
                        }
                    }
                    .onEnded { _ in
                        switch activeGesture {
                        case .movingDivider:
                            isDraggingHandle = false
                        case .panningPhoto:
                            steadyOffset.width += currentOffset.width
                            steadyOffset.height += currentOffset.height
                            currentOffset = .zero
                        case .none:
                            break
                        }
                        activeGesture = .none
                    }
            )
            // MARK: - Two-Finger Pinch to Zoom (1× to 5×)
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let proposed = steadyScale * scale
                        if proposed >= minScale && proposed <= maxScale {
                            currentScale = scale
                        }
                    }
                    .onEnded { scale in
                        let finalScale = max(minScale, min(maxScale, steadyScale * scale))
                        steadyScale = finalScale
                        currentScale = 1.0
                        
                        // Clamp offset after zooming
                        clampOffsetToBounds(viewportSize: geometry.size, scale: steadyScale)
                    }
            )
            // MARK: - Double-Tap to Reset Zoom & Pan
            .onTapGesture(count: 2) {
                resetZoomAnimated()
            }
            .onAppear {
                checkPhotoReset()
            }
            .onChange(of: photoId) { _ in
                resetAllForNewPhoto()
            }
            // MARK: - Accessibility Support
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Before and after comparison")
            .accessibilityValue("Showing \(Int((1.0 - sliderPosition) * 100)) percent enhanced, \(String(format: "%.1f", activeScale))x zoom")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    sliderPosition = min(0.98, sliderPosition + 0.1)
                case .decrement:
                    sliderPosition = max(0.02, sliderPosition - 0.1)
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - Zoom & Reset Helpers
    private func zoomBy(_ delta: CGFloat, in viewportSize: CGSize) {
        withAnimation(.easeOut(duration: 0.2)) {
            let newScale = max(minScale, min(maxScale, steadyScale + delta))
            steadyScale = newScale
            currentScale = 1.0
            clampOffsetToBounds(viewportSize: viewportSize, scale: newScale)
        }
    }
    
    private func resetZoomAnimated() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            steadyScale = 1.0
            currentScale = 1.0
            steadyOffset = .zero
            currentOffset = .zero
            // Preserves sliderPosition
        }
    }
    
    private func clampOffsetToBounds(viewportSize: CGSize, scale: CGFloat) {
        let maxPanX = (viewportSize.width * (scale - 1.0)) / 2.0
        let maxPanY = (viewportSize.height * (scale - 1.0)) / 2.0
        steadyOffset.width = max(-maxPanX, min(maxPanX, steadyOffset.width))
        steadyOffset.height = max(-maxPanY, min(maxPanY, steadyOffset.height))
    }
    
    private func checkPhotoReset() {
        if lastPhotoId != photoId {
            resetAllForNewPhoto()
        }
    }
    
    private func resetAllForNewPhoto() {
        lastPhotoId = photoId
        steadyScale = 1.0
        currentScale = 1.0
        steadyOffset = .zero
        currentOffset = .zero
        sliderPosition = 0.50
    }
}
