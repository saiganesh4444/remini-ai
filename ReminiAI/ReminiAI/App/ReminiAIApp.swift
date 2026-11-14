import SwiftUI

@main
struct ReminiAIApp: App {
    @StateObject private var viewModel = EnhanceViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(viewModel)
                .preferredColorScheme(.light) // Premium Light Theme
        }
    }
}
