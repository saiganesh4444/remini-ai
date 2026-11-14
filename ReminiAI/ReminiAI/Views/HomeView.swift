import SwiftUI
import PhotosUI

/// ReminiAI Home Screen
/// Light theme with Inter typography, 8px spacing scale, and 390 × 844 reference layout
struct HomeView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                ReminiDesign.background.ignoresSafeArea()
                
                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: ReminiDesign.space24) {
                        
                        // MARK: - Header: Aperture Logo + Wordmark + Profile Button
                        HStack(spacing: ReminiDesign.space12) {
                            ApertureLogo(size: 30, color: ReminiDesign.primary)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("ReminiAI")
                                    .font(.reminiTitle)
                                    .foregroundColor(ReminiDesign.text)
                                
                                Text("Natural portrait & photo clarity")
                                    .font(.reminiCaption)
                                    .foregroundColor(ReminiDesign.secondaryText)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.showSettingsView = true
                            }) {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(ReminiDesign.primary)
                                    .frame(width: ReminiDesign.minTouchTarget, height: ReminiDesign.minTouchTarget)
                                    .background(ReminiDesign.secondarySurface)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Profile and Settings")
                        }
                        .padding(.horizontal, ReminiDesign.space16)
                        .padding(.top, ReminiDesign.space8)
                        
                        // MARK: - Search Tools Field
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15))
                                .foregroundColor(ReminiDesign.secondaryText)
                            
                            TextField("Search tools...", text: $viewModel.searchQuery)
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
                                .accessibilityLabel("Clear search")
                            }
                        }
                        .padding(.horizontal, ReminiDesign.space12)
                        .frame(height: 46)
                        .background(ReminiDesign.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
                        .overlay(
                            RoundedRectangle(cornerRadius: ReminiDesign.corner16)
                                .stroke(isSearchFocused ? ReminiDesign.primary : ReminiDesign.borderSubtle, lineWidth: 1)
                        )
                        .padding(.horizontal, ReminiDesign.space16)
                        
                        // Search Results or Standard Layout
                        if !viewModel.searchQuery.isEmpty {
                            searchResultsSection
                        } else {
                            standardContentSection
                        }
                        
                        // Bottom buffer to prevent overlap with sticky CTA
                        Spacer().frame(height: 100)
                    }
                }
                
                // MARK: - Sticky Bottom CTA (Bottom 40% of screen)
                VStack(spacing: 8) {
                    PhotosPicker(
                        selection: $viewModel.photoPickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Choose photo")
                                .font(.reminiButton)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(ReminiDesign.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: ReminiDesign.corner16))
                        .shadow(color: ReminiDesign.primary.opacity(0.18), radius: 8, x: 0, y: 3)
                    }
                    .accessibilityLabel("Choose photo from library using \(viewModel.selectedMode.rawValue)")
                    
                    Text("Using \(viewModel.selectedMode.rawValue) • \(viewModel.selectedEngine == .onDevice ? "On-Device Neural Engine" : "Cloud AI")")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(ReminiDesign.secondaryText)
                }
                .padding(.horizontal, ReminiDesign.space16)
                .padding(.top, 12)
                .padding(.bottom, ReminiDesign.space8)
                .background(
                    ReminiDesign.background
                        .opacity(0.96)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -4)
                )
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Standard Layout (Featured Card + 2-Column Grid)
    private var standardContentSection: some View {
        VStack(alignment: .leading, spacing: ReminiDesign.space24) {
            // Featured Card (Natural Enhance by default or selected tool)
            FeaturedToolCard(mode: viewModel.selectedMode) {
                viewModel.showImagePicker = true
            }
            .padding(.horizontal, ReminiDesign.space16)
            
            // 2-Column Grid for Remaining Tools
            VStack(alignment: .leading, spacing: ReminiDesign.space12) {
                Text("ALL ENHANCEMENT TOOLS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(ReminiDesign.secondaryText)
                    .padding(.horizontal, ReminiDesign.space16)
                
                let remainingTools = EnhancementMode.allCases.filter { $0 != viewModel.selectedMode }
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: ReminiDesign.space8),
                        GridItem(.flexible(), spacing: ReminiDesign.space8)
                    ],
                    spacing: ReminiDesign.space8
                ) {
                    ForEach(remainingTools) { tool in
                        ToolCard(
                            mode: tool,
                            isSelected: viewModel.selectedMode == tool
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.selectedMode = tool
                            }
                        }
                    }
                }
                .padding(.horizontal, ReminiDesign.space16)
            }
        }
    }
    
    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: ReminiDesign.space12) {
            if viewModel.filteredTools.isEmpty {
                VStack(spacing: ReminiDesign.space12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(ReminiDesign.secondaryText.opacity(0.5))
                        .padding(.top, 30)
                    
                    Text("No tools found")
                        .font(.reminiSection)
                        .foregroundColor(ReminiDesign.text)
                    
                    Text("Try searching for 'Upscale', 'Sharpen', 'Vintage', or 'Blur'.")
                        .font(.reminiCaption)
                        .foregroundColor(ReminiDesign.secondaryText)
                    
                    Button("Clear Search") {
                        viewModel.searchQuery = ""
                    }
                    .font(.reminiButton)
                    .foregroundColor(ReminiDesign.primary)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("MATCHING TOOLS (\(viewModel.filteredTools.count))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(ReminiDesign.secondaryText)
                    .padding(.horizontal, ReminiDesign.space16)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: ReminiDesign.space8),
                        GridItem(.flexible(), spacing: ReminiDesign.space8)
                    ],
                    spacing: ReminiDesign.space8
                ) {
                    ForEach(viewModel.filteredTools) { tool in
                        ToolCard(
                            mode: tool,
                            isSelected: viewModel.selectedMode == tool
                        ) {
                            viewModel.selectedMode = tool
                        }
                    }
                }
                .padding(.horizontal, ReminiDesign.space16)
            }
        }
    }
}
