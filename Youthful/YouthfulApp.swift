import SwiftUI
import SwiftData
import UserNotifications

@main
struct YouthfulApp: App {
    init() {
        UINavigationBar.appearance().tintColor = UIColor(PremiumTheme.ink)
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottomTrailing) {
                ContentView()
                    .preferredColorScheme(.light)
                ScheduledGoalsLauncher()
            }
        }
        .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self, ScheduledGoal.self])
    }
}

private struct ScheduledGoalsLauncher: View {
    @State private var showingGoals = false

    var body: some View {
        Button {
            CoachHaptics.selection()
            showingGoals = true
        } label: {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 72)
        .sheet(isPresented: $showingGoals) {
            ScheduledGoalsView()
        }
    }
}
