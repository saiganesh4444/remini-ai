import SwiftUI
import PhotosUI

/// Main 5-Tab Navigation Container
/// Home, Search, Add (Photos/Camera modal), Activity, Profile
struct MainTabView: View {
    @EnvironmentObject var viewModel: EnhanceViewModel
    @State private var showingAddSheet: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Selected Tab Content
            Group {
                switch viewModel.selectedTab {
                case .home:
                    HomeView()
                case .search:
                    SearchView()
                case .add:
                    HomeView() // Fallback; tapping Add presents sheet
                case .activity:
                    ActivityView()
                case .profile:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 64) // Tab bar height offset
            
            // Custom Tab Bar (Pill style active state, 44pt touch target)
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Processing Full Screen Cover
        .fullScreenCover(isPresented: $viewModel.isProcessing) {
            ProcessingView()
                .environmentObject(viewModel)
        }
        // Result Comparison Full Screen Cover
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
            CameraPicker { image in
                viewModel.setImageFromCamera(image)
            }
        }
        // Add Photo Sheet / Action
        .confirmationDialog("Add Photo to Enhance", isPresented: $showingAddSheet, titleVisibility: .visible) {
            Button("Choose from Photo Library") {
                viewModel.showImagePicker = true
            }
            Button("Take Photo with Camera") {
                viewModel.showCameraPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        // Native PhotosPicker trigger when showImagePicker is active
        .photosPicker(
            isPresented: $viewModel.showImagePicker,
            selection: $viewModel.photoPickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        // Global Error Alert
        .alert("Processing Notice", isPresented: $viewModel.showErrorAlert) {
            if viewModel.offerSwitchToOnDevice {
                Button("Switch to On-Device", role: .none) {
                    viewModel.switchToOnDeviceAndRetry()
                }
            } else if viewModel.selectedImage != nil {
                Button("Try Again", role: .none) {
                    viewModel.startEnhancement()
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .home)
            tabButton(tab: .search)
            
            // Add Button (Raised Circle)
            Button(action: {
                showingAddSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(ReminiDesign.primary)
                        .frame(width: 48, height: 48)
                        .shadow(color: ReminiDesign.primary.opacity(0.25), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add Photo to Enhance")
            
            tabButton(tab: .activity)
            tabButton(tab: .profile)
        }
        .padding(.horizontal, ReminiDesign.space8)
        .padding(.vertical, ReminiDesign.space8)
        .background(
            ReminiDesign.cardBackground
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -2)
        )
    }
    
    private func tabButton(tab: EnhanceViewModel.Tab) -> some View {
        Button(action: {
            if tab == .add {
                showingAddSheet = true
            } else {
                viewModel.selectedTab = tab
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 19, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(viewModel.selectedTab == tab ? ReminiDesign.primary : ReminiDesign.secondaryText)
                
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: viewModel.selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(viewModel.selectedTab == tab ? ReminiDesign.primary : ReminiDesign.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: ReminiDesign.minTouchTarget)
            .background(
                viewModel.selectedTab == tab
                ? ReminiDesign.secondarySurface.opacity(0.7)
                : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.rawValue) Tab")
        .accessibilityAddTraits(viewModel.selectedTab == tab ? [.isSelected, .isButton] : [.isButton])
    }
}
