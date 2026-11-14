import SwiftUI
import PhotosUI

/// Dedicated Search & Tool Discovery View
struct SearchView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input Field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(ReminiDesign.secondaryText)
                    
                    TextField("Search tools (e.g., Upscale, Blur, Vintage)...", text: $viewModel.searchQuery)
                        .font(.reminiBody)
                        .foregroundColor(ReminiDesign.text)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled(true)
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ReminiDesign.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, ReminiDesign.space12)
                .frame(height: 48)
                .background(ReminiDesign.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
                .overlay(
                    RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                        .stroke(isSearchFocused ? ReminiDesign.primary : ReminiDesign.borderSubtle, lineWidth: 1)
                )
                .padding(.horizontal, ReminiDesign.space16)
                .padding(.vertical, ReminiDesign.space12)
                
                // Tool List or Empty State
                if viewModel.filteredTools.isEmpty {
                    VStack(spacing: ReminiDesign.space16) {
                        Spacer()
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 48))
                            .foregroundColor(ReminiDesign.secondaryText.opacity(0.6))
                        
                        Text("No tools found")
                            .font(.reminiSection)
                            .foregroundColor(ReminiDesign.text)
                        
                        Text("No enhancement tools match '\(viewModel.searchQuery)'. Try searching for sharpen, upscale, or blur.")
                            .font(.reminiBody)
                            .foregroundColor(ReminiDesign.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ReminiDesign.space32)
                        
                        Button("Clear Search") {
                            viewModel.searchQuery = ""
                        }
                        .font(.reminiButton)
                        .foregroundColor(ReminiDesign.primary)
                        .padding(.top, ReminiDesign.space8)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ReminiDesign.space12) {
                            ForEach(viewModel.filteredTools) { tool in
                                SearchToolRow(tool: tool, isSelected: viewModel.selectedMode == tool) {
                                    viewModel.selectedMode = tool
                                    viewModel.showImagePicker = true
                                }
                            }
                        }
                        .padding(.horizontal, ReminiDesign.space16)
                        .padding(.vertical, ReminiDesign.space8)
                    }
                }
            }
            .background(ReminiDesign.background.ignoresSafeArea())
            .navigationTitle("Search Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SearchToolRow: View {
    let tool: EnhancementMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ReminiDesign.space12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? ReminiDesign.primary : ReminiDesign.secondarySurface)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: tool.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : ReminiDesign.primary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(tool.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ReminiDesign.text)
                        
                        if let badge = tool.badgeText {
                            Text(badge)
                                .font(.reminiBadge)
                                .foregroundColor(ReminiDesign.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ReminiDesign.secondarySurface)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(tool.detailedDescription)
                        .font(.reminiCaption)
                        .foregroundColor(ReminiDesign.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ReminiDesign.secondaryText.opacity(0.6))
            }
            .padding(ReminiDesign.space16)
            .background(ReminiDesign.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
            .overlay(
                RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                    .stroke(isSelected ? ReminiDesign.primary : ReminiDesign.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
