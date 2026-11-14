import SwiftUI

/// Accessible, Zoomable, and Pannable Split Before/After Comparison Component
///
/// Features:
/// - Before on Left, After on Right
/// - Viewport-anchored vertical divider line with 44×44 pt touch handle
/// - Synchronized 1× to 5× two-finger pinch-to-zoom on both layers
/// - One-finger panning when zoomed in (drag handle moves divider, drag photo pans both layers)
/// - Constrained pan bounds
/// - Double-tap to reset zoom and pan while preserving divider position
/// - VoiceOver accessibility with adjustable percentage
struct BeforeAfterSlider: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    
    // Divider Position (0.02 ... 0.98), anchored to viewport width
    @State private var sliderPosition: CGFloat = 0.50
    @State private var isDraggingHandle: Bool = false
    
    // Zoom & Pan State (applied identically to both Before & After layers)
    @State private var currentScale: CGFloat = 1.0
    @State private var steadyScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var steadyOffset: CGSize = .zero
    
    // Track photo ID to reset zoom on new photo imports
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
                    // Mask Before image to only show left of splitX
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
                        .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 2)
                    
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
                        // BEFORE badge on Left
                        Text("BEFORE")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.60))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 3)
                            .opacity(sliderPosition > 0.12 ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: sliderPosition)
                        
                        Spacer()
                        
                        // AFTER badge on Right
                        Text("AFTER")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.92))
                            .foregroundColor(ReminiDesign.primary)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 3)
                            .opacity(sliderPosition < 0.88 ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: sliderPosition)
                    }
                    .padding(ReminiDesign.space12)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // Zoom Indicator (shows when zoomed in)
                if activeScale > 1.05 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(String(format: "%.1f×", activeScale))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.65))
                                .clipShape(Capsule())
                                .padding(ReminiDesign.space12)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            // MARK: - Combined Gesture System: Handle Drag vs Photo Pan
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        let startX = value.startLocation.x
                        let isNearHandle = abs(startX - splitX) < handleTouchWidth
                        
                        if isNearHandle || activeScale <= 1.05 {
                            // Dragging Divider Handle
                            isDraggingHandle = true
                            let newPos = value.location.x / viewportWidth
                            sliderPosition = max(0.02, min(0.98, newPos))
                        } else {
                            // Panning Photo (when zoomed in)
                            isDraggingHandle = false
                            let maxPanX = (viewportWidth * (activeScale - 1.0)) / 2.0
                            let maxPanY = (viewportHeight * (activeScale - 1.0)) / 2.0
                            
                            let proposedX = steadyOffset.width + value.translation.width
                            let proposedY = steadyOffset.height + value.translation.height
                            
                            currentOffset = CGSize(
                                width: max(-maxPanX, min(maxPanX, proposedX)) - steadyOffset.width,
                                height: max(-maxPanY, min(maxPanY, proposedY)) - steadyOffset.height
                            )
                        }
                    }
                    .onEnded { _ in
                        if isDraggingHandle {
                            isDraggingHandle = false
                        } else {
                            steadyOffset.width += currentOffset.width
                            steadyOffset.height += currentOffset.height
                            currentOffset = .zero
                        }
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
                        
                        // Constrain offset after zooming
                        let maxPanX = (viewportWidth * (steadyScale - 1.0)) / 2.0
                        let maxPanY = (viewportHeight * (steadyScale - 1.0)) / 2.0
                        steadyOffset.width = max(-maxPanX, min(maxPanX, steadyOffset.width))
                        steadyOffset.height = max(-maxPanY, min(maxPanY, steadyOffset.height))
                    }
            )
            // MARK: - Double-Tap to Reset Zoom & Pan
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    steadyScale = 1.0
                    currentScale = 1.0
                    steadyOffset = .zero
                    currentOffset = .zero
                    // Note: sliderPosition is preserved!
                }
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
            .accessibilityValue("Showing \(Int((1.0 - sliderPosition) * 100)) percent enhanced, \(Int(activeScale))x zoom")
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
