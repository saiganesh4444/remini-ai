import SwiftUI

/// Edit Effects Sheet
/// Provides independent controls for Face Enhancement, Face Retouch,
/// Background Enhancement, Background Depth Blur, and Selective People Removal.
struct EditEffectsSheet: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var draftEffects: CombinedEffects = .defaults
    @State private var showingPeoplePicker: Bool = false
    @State private var availablePeople: [DetectedPerson] = []
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Section 1: Facial Enhancements
                Section {
                    Toggle(isOn: $draftEffects.faceEnhancement) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Face Enhancement")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ReminiDesign.text)
                            Text("Mild, face-local detail refinement for eyes, lashes, and hair")
                                .font(.reminiCaption)
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                    }
                    .tint(ReminiDesign.primary)
                    
                    Toggle(isOn: $draftEffects.faceRetouch) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Face Retouch")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ReminiDesign.text)
                            Text("Gentle smoothing that preserves freckles, moles, and natural skin texture")
                                .font(.reminiCaption)
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                    }
                    .tint(ReminiDesign.primary)
                } header: {
                    Text("PORTRAIT & FACE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                
                // MARK: - Section 2: Background Controls
                Section {
                    Toggle(isOn: $draftEffects.backgroundEnhancement) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Background Enhancement")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ReminiDesign.text)
                            Text("Mild denoising & detail refinement outside the protected subject")
                                .font(.reminiCaption)
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                    }
                    .tint(ReminiDesign.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Background Blur")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ReminiDesign.text)
                        
                        Picker("Background Blur", selection: $draftEffects.backgroundBlur) {
                            ForEach(BlurPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(draftEffects.backgroundBlur.subtitle)
                            .font(.reminiCaption)
                            .foregroundColor(ReminiDesign.secondaryText)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("BACKGROUND ADJUSTMENTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                
                // MARK: - Section 3: Selective People Removal
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Remove Background People")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ReminiDesign.text)
                            
                            Text(draftEffects.selectedPeopleIds.isEmpty
                                 ? "Tap below to select photo photobombers or bystanders"
                                 : "\(draftEffects.selectedPeopleIds.count) person(s) marked for inpainting")
                                .font(.reminiCaption)
                                .foregroundColor(draftEffects.selectedPeopleIds.isEmpty ? ReminiDesign.secondaryText : ReminiDesign.primary)
                        }
                        Spacer()
                    }
                    
                    Button(action: {
                        Task {
                            if let img = viewModel.selectedImage {
                                availablePeople = await ImageEnhancerService.shared.getDetectedPeople(
                                    for: img,
                                    sessionId: viewModel.currentPhotoSessionId
                                )
                                showingPeoplePicker = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text(draftEffects.selectedPeopleIds.isEmpty ? "Select People in Photo..." : "Edit Selected People (\(draftEffects.selectedPeopleIds.count))")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ReminiDesign.primary)
                    }
                } header: {
                    Text("OBJECT & PEOPLE CLEANUP")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ReminiDesign.secondaryText)
                } footer: {
                    Text("On-device inpainting seamlessly reconstructs the background scenery while keeping your primary subject protected.")
                        .font(.reminiCaption)
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                
                // MARK: - Status Preview
                Section {
                    HStack {
                        Text("Active Adjustments")
                        Spacer()
                        Text(draftEffects.isAllDisabled ? "None (Original)" : "\(draftEffects.activeCount) active")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(draftEffects.isAllDisabled ? ReminiDesign.secondaryText : ReminiDesign.primary)
                    }
                    
                    Button(action: {
                        draftEffects = .defaults
                    }) {
                        Text("Reset to Defaults")
                            .foregroundColor(ReminiDesign.error)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .navigationTitle("Edit Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ReminiDesign.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.applyCombinedEffects(draftEffects)
                        dismiss()
                    }
                    .font(.reminiButton)
                    .foregroundColor(ReminiDesign.primary)
                }
            }
            .sheet(isPresented: $showingPeoplePicker) {
                if let img = viewModel.selectedImage {
                    PeopleSelectionSheet(
                        image: img,
                        sessionId: viewModel.currentPhotoSessionId,
                        detectedPeople: $availablePeople,
                        selectedPeopleIds: $draftEffects.selectedPeopleIds
                    ) { updatedSelection in
                        draftEffects.removeBackgroundPeople = !updatedSelection.isEmpty
                    }
                }
            }
            .onAppear {
                draftEffects = viewModel.activeCombinedEffects
            }
        }
    }
}
