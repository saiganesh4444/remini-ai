import SwiftUI

struct ComparisonView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @State private var showShareSheet: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: {
                        viewModel.showComparisonView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    
                    Spacer()
                    
                    Text("Result")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let enhanced = viewModel.enhancedImage {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                
                // Before / After Interactive Split Slider
                if let before = viewModel.selectedImage, let after = viewModel.enhancedImage {
                    BeforeAfterSlider(beforeImage: before, afterImage: after)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                
                // Bottom Controls & Tool Switcher
                VStack(spacing: 16) {
                    // Quick Enhancement Mode Switcher
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(EnhancementMode.allCases) { mode in
                                Button(action: {
                                    viewModel.reprocessWithMode(mode)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: mode.iconName)
                                            .font(.system(size: 12))
                                        Text(mode.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.selectedMode == mode
                                        ? Color.blue
                                        : Color.white.opacity(0.1)
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                    
                    // Main Save Button
                    Button(action: {
                        viewModel.saveEnhancedImage()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18))
                            Text("Save to Camera Roll")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(Color(white: 0.08))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = viewModel.enhancedImage {
                ShareSheet(items: [image])
            }
        }
        .alert("Saved!", isPresented: $viewModel.saveSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enhanced photo has been saved to your Photos app.")
        }
    }
}

// Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
