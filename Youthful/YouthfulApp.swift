import SwiftUI
import SwiftData
import UserNotifications

@main
struct YouthfulApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self])
    }
}
