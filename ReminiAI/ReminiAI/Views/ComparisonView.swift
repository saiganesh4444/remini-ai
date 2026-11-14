import SwiftUI

/// Before / After Result Screen with Interactive Strength Slider
struct ComparisonView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @State private var showShareSheet: Bool = false
    
    var body: some View {
        ZStack {
            ReminiDesign.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: {
                        viewModel.showComparisonView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                            .frame(width: ReminiDesign.minTouchTarget, height: ReminiDesign.minTouchTarget)
                            .background(ReminiDesign.secondarySurface)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Back to Home")
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(viewModel.selectedMode.rawValue)
                            .font(.reminiSection)
                            .foregroundColor(ReminiDesign.text)
                        
                        Text(viewModel.selectedEngine == .onDevice ? "On-Device Engine" : "Cloud AI")
                            .font(.reminiCaption)
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    
                    Spacer()
                    
                    if let imageToShare = viewModel.displayEnhancedImage {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ReminiDesign.primary)
                                .frame(width: ReminiDesign.minTouchTarget, height: ReminiDesign.minTouchTarget)
                                .background(ReminiDesign.secondarySurface)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Share Enhanced Photo")
                    } else {
                        Spacer().frame(width: ReminiDesign.minTouchTarget)
                    }
                }
                .padding(.horizontal, ReminiDesign.space16)
                .padding(.top, ReminiDesign.space8)
                .padding(.bottom, ReminiDesign.space12)
                
                // Interactive Before / After Slider
                if let before = comparisonBeforeImage, let after = viewModel.displayEnhancedImage {
                    BeforeAfterSlider(beforeImage: before, afterImage: after)
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
                        .padding(.horizontal, ReminiDesign.space16)
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                
                // Bottom Controls & Tuning Panel
                VStack(spacing: ReminiDesign.space16) {
                    
                    // MARK: - Enhancement Strength Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Strength")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ReminiDesign.text)
                            
                            Spacer()
                            
                            Text("\(Int(viewModel.strength * 100))%")
                                .font(.reminiBadge)
                                .foregroundColor(ReminiDesign.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ReminiDesign.secondarySurface)
                                .clipShape(Capsule())
                        }
                        
                        Slider(value: $viewModel.strength, in: 0.0...1.0)
                            .tint(ReminiDesign.primary)
                            .accessibilityLabel("Enhancement strength slider")
                            .accessibilityValue("\(Int(viewModel.strength * 100)) percent")
                        
                        HStack {
                            Text("Original (0%)")
                                .font(.system(size: 11))
                                .foregroundColor(ReminiDesign.secondaryText)
                            Spacer()
                            Text("Full Effect (100%)")
                                .font(.system(size: 11))
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                    }
                    .padding(.horizontal, ReminiDesign.space16)
                    .padding(.top, ReminiDesign.space12)
                    
                    // Quick Tool Switcher
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ReminiDesign.space8) {
                            ForEach(EnhancementMode.allCases) { tool in
                                Button(action: {
                                    viewModel.selectModeAndReprocess(tool)
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: tool.iconName)
                                            .font(.system(size: 11))
                                        Text(tool.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        viewModel.selectedMode == tool
                                        ? ReminiDesign.primary
                                        : ReminiDesign.secondarySurface
                                    )
                                    .foregroundColor(
                                        viewModel.selectedMode == tool
                                        ? .white
                                        : ReminiDesign.primary
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, ReminiDesign.space16)
                    }
                    
                    // Save Button
                    Button(action: {
                        viewModel.saveEnhancedImage()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 17))
                            Text("Save to Camera Roll")
                        }
                    }
                    .buttonStyle(ReminiPrimaryButtonStyle())
                    .padding(.horizontal, ReminiDesign.space16)
                    .padding(.bottom, ReminiDesign.space12)
                }
                .background(ReminiDesign.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner24))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -3)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = viewModel.displayEnhancedImage {
                ShareSheet(items: [image])
            }
        }
        .alert("Saved Successfully", isPresented: $viewModel.saveSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The enhanced photo (at \(Int(viewModel.strength * 100))% strength) has been saved to your iPhone Camera Roll and recorded in Activity.")
        }
    }
    
    /// For HD Upscale, resamples the original to match the 2× pixel dimensions so the Before/After comparison stays perfectly aligned!
    private var comparisonBeforeImage: UIImage? {
        guard let orig = viewModel.selectedImage else { return nil }
        if viewModel.selectedMode == .hdUpscale, let after = viewModel.unblendedEnhancedImage {
            return ImageEnhancerService.shared.resampleToTargetDimensions(image: orig, targetSize: after.size)
        }
        return orig
    }
}
