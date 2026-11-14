import SwiftUI

/// Featured Card showcasing Natural Enhance (or current selected tool)
/// Includes 24px corners, custom shadow `0 4px 16px rgba(23, 40, 34, 0.08)`,
/// and an interactive illustrative before-and-after portrait comparison.
struct FeaturedToolCard: View {
    let mode: EnhancementMode
    let onChoosePhoto: () -> Void
    
    @State private var sliderPosition: CGFloat = 0.52
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReminiDesign.space16) {
            // Header Info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.rawValue)
                            .font(.reminiSection)
                            .foregroundColor(ReminiDesign.text)
                        
                        if let badge = mode.badgeText {
                            Text(badge)
                                .font(.reminiBadge)
                                .foregroundColor(ReminiDesign.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ReminiDesign.secondarySurface)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(mode.shortDescription)
                        .font(.reminiCaption)
                        .foregroundColor(ReminiDesign.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: mode.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(ReminiDesign.primary)
                    .frame(width: 40, height: 40)
                    .background(ReminiDesign.secondarySurface)
                    .clipShape(Circle())
            }
            .padding(.horizontal, ReminiDesign.space16)
            .padding(.top, ReminiDesign.space16)
            
            // Interactive Illustrative Portrait Before/After Canvas
            IllustrativePortraitSlider(sliderPosition: $sliderPosition, isDragging: $isDragging)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
                .padding(.horizontal, ReminiDesign.space16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Illustrative before and after portrait preview for \(mode.rawValue)")
                .accessibilityValue("\(Int(sliderPosition * 100)) percent after")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        sliderPosition = min(1.0, sliderPosition + 0.1)
                    case .decrement:
                        sliderPosition = max(0.0, sliderPosition - 0.1)
                    @unknown default:
                        break
                    }
                }
            
            // Quick action prompt
            HStack {
                Text("Drag divider to compare subtle natural texture")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(ReminiDesign.secondaryText)
                
                Spacer()
                
                Button(action: onChoosePhoto) {
                    HStack(spacing: 4) {
                        Text("Apply to photo")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(ReminiDesign.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ReminiDesign.space16)
            .padding(.bottom, ReminiDesign.space16)
        }
        .background(ReminiDesign.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner24))
        .overlay(
            RoundedRectangle(cornerRadius: ReminiDesign.corner24)
                .stroke(ReminiDesign.borderSubtle, lineWidth: 1)
        )
        .shadow(
            color: ReminiDesign.featuredCardShadowColor,
            radius: ReminiDesign.featuredCardShadowRadius,
            x: 0,
            y: ReminiDesign.featuredCardShadowY
        )
    }
}

// MARK: - Illustrative Before/After Canvas
private struct IllustrativePortraitSlider: View {
    @Binding var sliderPosition: CGFloat
    @Binding var isDragging: Bool
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let splitX = max(0, min(width, width * sliderPosition))
            
            ZStack(alignment: .leading) {
                // Background Layer: Before (Original softer portrait)
                PortraitArtwork(isEnhanced: false)
                    .frame(width: width, height: height)
                
                // Foreground Layer: After (Natural subtle enhancement)
                PortraitArtwork(isEnhanced: true)
                    .frame(width: width, height: height)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: splitX)
                            Spacer(minLength: 0)
                        }
                        .frame(width: width, height: height)
                    )
                
                // Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                    .position(x: splitX, y: height / 2)
                
                // Circular Grab Handle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                    }
                }
                .position(x: splitX, y: height / 2)
                
                // Labels
                VStack {
                    HStack {
                        Text("AFTER")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(ReminiDesign.primary)
                            .clipShape(Capsule())
                            .opacity(sliderPosition > 0.15 ? 1 : 0)
                        
                        Spacer()
                        
                        Text("BEFORE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.4))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .opacity(sliderPosition < 0.85 ? 1 : 0)
                    }
                    .padding(10)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        sliderPosition = max(0.05, min(0.95, value.location.x / width))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
}

// MARK: - Procedural Portrait Artwork
private struct PortraitArtwork: View {
    let isEnhanced: Bool
    
    var body: some View {
        ZStack {
            // Studio Portrait Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: 0xE8EDE9),
                    Color(hex: 0xD3DED6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Shoulders & Silhouette
            VStack {
                Spacer()
                Ellipse()
                    .fill(Color(hex: 0x2A453B).opacity(0.85))
                    .frame(width: 260, height: 140)
                    .offset(y: 45)
            }
            
            // Neck
            Rectangle()
                .fill(Color(hex: 0xE5B898))
                .frame(width: 44, height: 60)
                .offset(y: 30)
            
            // Face Ellipse
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: isEnhanced ? 0xF8CFB0 : 0xEEC4A4),
                            Color(hex: 0xE5B898)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 105, height: 130)
                .offset(y: -15)
                .blur(radius: isEnhanced ? 0 : 0.6)
            
            // Hair
            Circle()
                .fill(Color(hex: 0x3A2618))
                .frame(width: 120, height: 110)
                .offset(y: -40)
            
            // Forehead hair shape
            Circle()
                .fill(Color(hex: 0x3A2618))
                .frame(width: 90, height: 50)
                .offset(x: -25, y: -45)
            
            // Facial Features Group
            VStack(spacing: 8) {
                // Eyes
                HStack(spacing: 28) {
                    EyeFeature(isEnhanced: isEnhanced)
                    EyeFeature(isEnhanced: isEnhanced)
                }
                
                // Nose
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 2, y: 12))
                    path.addLine(to: CGPoint(x: -4, y: 14))
                }
                .stroke(Color(hex: 0xC49272), lineWidth: 1.5)
                .frame(width: 8, height: 14)
                
                // Lips
                Capsule()
                    .fill(Color(hex: isEnhanced ? 0xD27D72 : 0xC4766C))
                    .frame(width: 26, height: 8)
            }
            .offset(y: -10)
        }
    }
}

private struct EyeFeature: View {
    let isEnhanced: Bool
    
    var body: some View {
        ZStack {
            // Eye shape
            Capsule()
                .fill(Color.white)
                .frame(width: 14, height: 7)
            
            // Iris
            Circle()
                .fill(Color(hex: 0x4A2E1B))
                .frame(width: 6, height: 6)
            
            // Catchlight (sharper on enhanced)
            if isEnhanced {
                Circle()
                    .fill(Color.white)
                    .frame(width: 2, height: 2)
                    .offset(x: 1, y: -1)
            }
        }
    }
}
