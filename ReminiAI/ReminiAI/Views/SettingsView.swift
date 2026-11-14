import SwiftUI

/// Profile & Application Settings View
struct SettingsView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingSavedNotification: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Engine Selector
                Section {
                    Picker("Engine", selection: $viewModel.selectedEngine) {
                        ForEach(EngineType.allCases) { engine in
                            Text(engine.rawValue).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    
                    Text(viewModel.selectedEngine.description)
                        .font(.reminiCaption)
                        .foregroundColor(ReminiDesign.secondaryText)
                } header: {
                    Text("PROCESSING ENGINE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                } footer: {
                    if viewModel.selectedEngine == .cloudAI {
                        Text("Notice: When Cloud AI is selected, photos are uploaded to Replicate servers for inference using GFPGAN or Real-ESRGAN.")
                            .font(.reminiCaption)
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                }
                
                // MARK: - Cloud API Credentials
                if viewModel.selectedEngine == .cloudAI {
                    Section {
                        SecureField("Replicate API Token (r8_...)", text: $viewModel.cloudApiKey)
                            .font(.reminiBody)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(ReminiDesign.primary)
                                .font(.system(size: 13))
                            Text("Stored securely in iOS Keychain")
                                .font(.reminiCaption)
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                    } header: {
                        Text("REPLICATE API CREDENTIALS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ReminiDesign.secondaryText)
                    } footer: {
                        Text("Get an API token from replicate.com/account/api-tokens. GFPGAN runs for Natural Enhance and Real-ESRGAN runs for HD Upscale.")
                            .font(.reminiCaption)
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                }
                
                // MARK: - Tool Capabilities & Routing
                Section {
                    ToolCapabilityRow(
                        name: "Natural Enhance",
                        localSupport: "CoreImage + Vision",
                        cloudSupport: "GFPGAN v1.4"
                    )
                    ToolCapabilityRow(
                        name: "HD Upscale",
                        localSupport: "2× Lanczos Resampling",
                        cloudSupport: "Real-ESRGAN 2×"
                    )
                    ToolCapabilityRow(
                        name: "Soft Sharpen",
                        localSupport: "Luminance Edge Refinement",
                        cloudSupport: "On-Device Only"
                    )
                    ToolCapabilityRow(
                        name: "Vintage Tone",
                        localSupport: "Warm Midtone Calibration",
                        cloudSupport: "On-Device Only"
                    )
                    ToolCapabilityRow(
                        name: "Portrait Blur",
                        localSupport: "Subject & Multi-Face Vision Mask",
                        cloudSupport: "On-Device Only"
                    )
                } header: {
                    Text("MODEL ROUTING & CAPABILITIES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                
                // MARK: - Hardware Information
                Section {
                    HStack {
                        Label("Target Device", systemImage: "iphone")
                        Spacer()
                        Text("iPhone 13 (390 × 844 pt)")
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    HStack {
                        Label("Processor", systemImage: "cpu")
                        Spacer()
                        Text("Apple A15 Bionic")
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    HStack {
                        Label("Neural Engine", systemImage: "bolt.fill")
                        Spacer()
                        Text("16-Core ANE + Metal 3")
                            .foregroundColor(ReminiDesign.primary)
                    }
                } header: {
                    Text("DEVICE HARDWARE ACCELERATION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                
                // MARK: - Privacy
                Section {
                    HStack(alignment: .top, spacing: ReminiDesign.space12) {
                        Image(systemName: "hand.raised.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ReminiDesign.primary)
                        
                        Text("On-device processing keeps your photos 100% private on your iPhone. Photos are never uploaded or retained anywhere outside your device unless you explicitly enable Cloud AI.")
                            .font(.reminiCaption)
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("PRIVACY & SECURITY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                
                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0 (Build 2)")
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    HStack {
                        Text("Design System")
                        Spacer()
                        Text("ReminiAI Light (Inter 8px scale)")
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                } header: {
                    Text("ABOUT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.reminiButton)
                    .foregroundColor(ReminiDesign.primary)
                }
            }
        }
    }
}

private struct ToolCapabilityRow: View {
    let name: String
    let localSupport: String
    let cloudSupport: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ReminiDesign.text)
            
            HStack {
                Text("On-Device: \(localSupport)")
                    .font(.system(size: 11))
                    .foregroundColor(ReminiDesign.secondaryText)
                Spacer()
                Text(cloudSupport)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(cloudSupport == "On-Device Only" ? ReminiDesign.secondaryText.opacity(0.6) : ReminiDesign.primary)
            }
        }
        .padding(.vertical, 2)
    }
}
