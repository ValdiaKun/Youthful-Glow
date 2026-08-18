import SwiftUI
import SwiftData
import UserNotifications

@main
struct YouthfulApp: App {
    init() {
        // Youthful uses a warm editorial light theme. Keeping the system sheet
        // in the same appearance prevents dark-mode controls from becoming
        // unreadable against the premium light UI.
        UINavigationBar.appearance().tintColor = UIColor(PremiumTheme.ink)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appearanceCoachEntry()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self])
    }
}
