import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI PROCESSING ENGINE")) {
                    Picker("Engine", selection: $viewModel.selectedEngine) {
                        ForEach(EngineType.allCases) { engine in
                            Text(engine.rawValue).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    
                    Text(viewModel.selectedEngine.description)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                if viewModel.selectedEngine == .cloudAI {
                    Section(
                        header: Text("CLOUD NEURAL API KEY"),
                        footer: Text("Get an API token from replicate.com to run server-grade GFPGAN & Real-ESRGAN.")
                    ) {
                        SecureField("Replicate API Token (r8_...)", text: $viewModel.cloudApiKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                Section(header: Text("DEVICE HARDWARE ACCELERATION")) {
                    HStack {
                        Label("Device", systemImage: "iphone")
                        Spacer()
                        Text("iPhone 13")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Label("SoC", systemImage: "cpu")
                        Spacer()
                        Text("Apple A15 Bionic")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Label("Neural Engine", systemImage: "bolt.fill")
                        Spacer()
                        Text("16-Core (15.8 TOPS)")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Label("Graphics Acceleration", systemImage: "rectangle.fill.on.rectangle.angled.fill")
                        Spacer()
                        Text("Metal 3 / CoreImage GPU")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("PRIVACY & SECURITY")) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("On-device processing keeps your photos 100% on your iPhone 13. Nothing is sent to third-party servers unless Cloud AI is enabled.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("ReminiAI")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
