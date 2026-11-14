import SwiftUI

/// Recent Edits & Enhancement History Tab
struct ActivityView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @State private var showingClearConfirm: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReminiDesign.background.ignoresSafeArea()
                
                if viewModel.activityItems.isEmpty {
                    // Empty State
                    VStack(spacing: ReminiDesign.space16) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 54))
                            .foregroundColor(ReminiDesign.secondaryText.opacity(0.4))
                        
                        Text("No recent edits")
                            .font(.reminiSection)
                            .foregroundColor(ReminiDesign.text)
                        
                        Text("Enhanced photos you save or share will appear here with export dimensions and tuning parameters.")
                            .font(.reminiBody)
                            .foregroundColor(ReminiDesign.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ReminiDesign.space32)
                        
                        Button(action: {
                            viewModel.showImagePicker = true
                        }) {
                            Text("Choose photo")
                                .padding(.horizontal, ReminiDesign.space24)
                        }
                        .buttonStyle(ReminiPrimaryButtonStyle())
                        .frame(maxWidth: 220)
                        .padding(.top, ReminiDesign.space12)
                    }
                    .padding(ReminiDesign.space24)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ReminiDesign.space12) {
                            ForEach(viewModel.activityItems) { item in
                                ActivityCard(item: item)
                            }
                        }
                        .padding(.horizontal, ReminiDesign.space16)
                        .padding(.vertical, ReminiDesign.space12)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.activityItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showingClearConfirm = true
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ReminiDesign.error)
                    }
                }
            }
            .confirmationDialog("Clear Recent Activity?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Clear All Activity", role: .destructive) {
                    ActivityHistoryManager.shared.clearHistory()
                    viewModel.activityItems.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the local log of recent edits. Your saved photos in the Camera Roll will remain untouched.")
            }
        }
    }
}

private struct ActivityCard: View {
    let item: ActivityItem
    
    var body: some View {
        HStack(spacing: ReminiDesign.space12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ReminiDesign.secondarySurface)
                    .frame(width: 58, height: 58)
                
                if let thumb = ActivityHistoryManager.shared.loadThumbnail(for: item) {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: item.mode.iconName)
                        .foregroundColor(ReminiDesign.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.mode.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ReminiDesign.text)
                    
                    Spacer()
                    
                    Text("\(Int(item.strength * 100))% strength")
                        .font(.reminiBadge)
                        .foregroundColor(ReminiDesign.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ReminiDesign.secondarySurface)
                        .clipShape(Capsule())
                }
                
                Text(item.formattedDate)
                    .font(.reminiCaption)
                    .foregroundColor(ReminiDesign.secondaryText)
                
                HStack(spacing: 8) {
                    Text(item.dimensionsText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ReminiDesign.secondaryText)
                    
                    Text("•")
                        .foregroundColor(ReminiDesign.secondaryText)
                    
                    Text(item.engine == .onDevice ? "On-Device" : "Cloud AI")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
            }
        }
        .padding(ReminiDesign.space12)
        .background(ReminiDesign.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
        .overlay(
            RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                .stroke(ReminiDesign.borderSubtle, lineWidth: 1)
        )
    }
}
