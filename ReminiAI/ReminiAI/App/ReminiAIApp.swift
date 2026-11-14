import SwiftUI

@main
struct ReminiAIApp: App {
    @StateObject private var viewModel = EnhanceViewModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
