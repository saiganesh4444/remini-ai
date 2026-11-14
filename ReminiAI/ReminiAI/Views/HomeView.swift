import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Top Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Remini")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("AI")
                                        .font(.system(size: 13, weight: .black, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 7, height: 7)
                                    Text("iPhone 13 A15 Neural Engine")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.showSettingsView = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(10)
                                    .background(Circle().fill(Color.white.opacity(0.08)))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // MARK: - Hero Upload Card
                        VStack(spacing: 18) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.35),
                                                Color.purple.opacity(0.2),
                                                Color.black.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.blue.opacity(0.5), Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                
                                VStack(spacing: 16) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 38, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.cyan, .blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .padding(.top, 8)
                                    
                                    VStack(spacing: 4) {
                                        Text("Enhance Any Photo")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("Turn low-res, blurry, or old photos into crystal-clear HD portraits")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }
                                    
                                    // Action Buttons: Choose Photo or Take Photo
                                    HStack(spacing: 12) {
                                        PhotosPicker(
                                            selection: $viewModel.photoPickerItem,
                                            matching: .images,
                                            photoLibrary: .shared()
                                        ) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "photo.on.rectangle.angled")
                                                    .font(.system(size: 15, weight: .bold))
                                                Text("Choose Photo")
                                                    .font(.system(size: 15, weight: .bold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.cyan],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                        
                                        Button(action: {
                                            viewModel.showCameraPicker = true
                                        }) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 16, weight: .bold))
                                                .frame(width: 48, height: 48)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12)
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Enhancement Modes Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ENHANCEMENT MODES")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(EnhancementMode.allCases) { mode in
                                    ToolCard(
                                        mode: mode,
                                        isSelected: viewModel.selectedMode == mode
                                    ) {
                                        viewModel.selectedMode = mode
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        // Processing Screen Overlay
        .fullScreenCover(isPresented: $viewModel.isProcessing) {
            ProcessingView()
                .environmentObject(viewModel)
        }
        // Before / After Comparison Screen
        .fullScreenCover(isPresented: $viewModel.showComparisonView) {
            ComparisonView()
                .environmentObject(viewModel)
        }
        // Settings Sheet
        .sheet(isPresented: $viewModel.showSettingsView) {
            SettingsView()
                .environmentObject(viewModel)
        }
        // Camera Picker Sheet
        .sheet(isPresented: $viewModel.showCameraPicker) {
            CameraPicker { capturedImage in
                viewModel.setImageFromCamera(capturedImage)
            }
        }
        // Error Alert
        .alert("Notice", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
    }
}

// Camera Picker UIViewControllerRepresentable
struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
