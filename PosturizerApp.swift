import SwiftUI

@main
struct PosturizerApp: App {
    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environmentObject(PageRouter())
        }
    }
}
