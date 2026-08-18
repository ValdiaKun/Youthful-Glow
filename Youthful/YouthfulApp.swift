import SwiftUI
import SwiftData
import UserNotifications

@main
struct YouthfulApp: App {
    init() {
        // Youthful uses a warm editorial light theme.
        UINavigationBar.appearance().tintColor = UIColor(PremiumTheme.ink)
    }

    var body: some Scene {
        WindowGroup {
            // Use the custom SwiftUI root. ContentView still contains the
            // legacy TabView, so it must not be the app's root while the
            // iOS tab-bar crash is being worked around.
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self])
    }
}
