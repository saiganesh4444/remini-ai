import SwiftUI

struct ProcessingView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @State private var scanOffset: CGFloat = -180
    @State private var pulseGlow: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Top Header
                HStack {
                    Button(action: {
                        viewModel.isProcessing = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    Spacer()
                    Text("AI RESTORATION")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.gray)
                    Spacer()
                    // Balance header
                    Spacer().frame(width: 36)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Photo Container with Scanning Laser Line
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 320, maxHeight: 380)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: Color.blue.opacity(pulseGlow ? 0.35 : 0.15), radius: 24, x: 0, y: 0)
                            
                        // Glowing Laser Scanning Bar
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.cyan.opacity(0.9),
                                        Color.white,
                                        Color.cyan.opacity(0.9),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 320, height: 3)
                            .shadow(color: .cyan, radius: 8, x: 0, y: 0)
                            .offset(y: scanOffset)
                            .clipped()
                    }
                }
                .frame(height: 380)
                
                Spacer()
                
                // Processing Status & Progress Bar
                VStack(spacing: 16) {
                    HStack {
                        Text(viewModel.statusMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .animation(.easeInOut, value: viewModel.statusMessage)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 32)
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * viewModel.progress, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 32)
                    
                    Text("Powered by Apple Neural Engine & GPU")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                scanOffset = 180
                pulseGlow = true
            }
        }
    }
}
