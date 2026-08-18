import SwiftUI
import SwiftData
import UserNotifications

@main
struct YouthfulApp: App {
    init() {
        // Keep the system navigation controls consistent with the light editorial UI.
        UINavigationBar.appearance().tintColor = UIColor(PremiumTheme.ink)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self])
    }
}
