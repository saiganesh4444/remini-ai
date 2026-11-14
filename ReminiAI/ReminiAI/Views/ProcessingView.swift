import SwiftUI

/// Processing Screen Overlay
/// Clean light aesthetic with gentle scanning indicator and real-time status
struct ProcessingView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @State private var scanOffset: CGFloat = -160
    
    var body: some View {
        ZStack {
            ReminiDesign.background.ignoresSafeArea()
            
            VStack(spacing: ReminiDesign.space24) {
                // Top Header
                HStack {
                    Button(action: {
                        viewModel.isProcessing = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                            .frame(width: 36, height: 36)
                            .background(ReminiDesign.secondarySurface)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Cancel processing")
                    
                    Spacer()
                    
                    Text("REMINI ENHANCER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(ReminiDesign.secondaryText)
                    
                    Spacer()
                    Spacer().frame(width: 36)
                }
                .padding(.horizontal, ReminiDesign.space24)
                .padding(.top, ReminiDesign.space12)
                
                Spacer()
                
                // Photo Preview with Gentle Scanning Line
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 360)
                            .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner24))
                            .overlay(
                                RoundedRectangle(cornerRadius: ReminiDesign.corner24)
                                    .stroke(ReminiDesign.primary.opacity(0.2), lineWidth: 1.5)
                            )
                            .shadow(color: ReminiDesign.primary.opacity(0.08), radius: 16, x: 0, y: 6)
                        
                        // Gentle Precision Scanline
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        ReminiDesign.primary.opacity(0.8),
                                        Color.white,
                                        ReminiDesign.primary.opacity(0.8),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 300, height: 2.5)
                            .shadow(color: ReminiDesign.primary.opacity(0.5), radius: 6, x: 0, y: 0)
                            .offset(y: scanOffset)
                            .clipped()
                    }
                }
                .frame(height: 360)
                
                Spacer()
                
                // Status & Progress Card
                VStack(spacing: ReminiDesign.space12) {
                    HStack {
                        Text(viewModel.statusMessage)
                            .font(.reminiBody)
                            .foregroundColor(ReminiDesign.text)
                            .lineLimit(2)
                            .animation(.easeInOut, value: viewModel.statusMessage)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ReminiDesign.primary)
                    }
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ReminiDesign.secondarySurface)
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(ReminiDesign.primary)
                                .frame(width: geo.size.width * viewModel.progress, height: 6)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.progress)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("Powered by \(viewModel.selectedEngine.rawValue)")
                        .font(.reminiCaption)
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                .padding(ReminiDesign.space16)
                .background(ReminiDesign.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
                .overlay(
                    RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                        .stroke(ReminiDesign.borderSubtle, lineWidth: 1)
                )
                .padding(.horizontal, ReminiDesign.space24)
                .padding(.bottom, ReminiDesign.space32)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
            ) {
                scanOffset = 160
            }
        }
    }
}
