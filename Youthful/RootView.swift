import SwiftUI

/// Custom root navigation used instead of SwiftUI's TabView.
///
/// The previous root relied on TabView/UITabBarController. On affected iOS 26
/// builds the UIKit tab-bar hierarchy can enter a recursive controller lookup
/// (`UIViewController.findTabBarController`). Keeping the tabs in pure SwiftUI
/// avoids that UIKit traversal while preserving the same five destinations.
struct RootView: View {
    private enum Tab: Int, CaseIterable {
        case today, coach, routine, progress, more

        var title: String {
            switch self {
            case .today: return "Today"
            case .coach: return "Coach"
            case .routine: return "Routine"
            case .progress: return "Progress"
            case .more: return "More"
            }
        }

        var icon: String {
            switch self {
            case .today: return "circle.hexagongrid.fill"
            case .coach: return "sparkles"
            case .routine: return "drop.circle"
            case .progress: return "chart.xyaxis.line"
            case .more: return "ellipsis.circle"
            }
        }
    }

    @State private var selectedTab: Tab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .today:
                    TodayView()
                case .coach:
                    AppearanceCoachView()
                case .routine:
                    ProductsView()
                case .progress:
                    ProgressDashboard()
                case .more:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .tint(PremiumTheme.ink)
    }

    private var bottomBar: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: selectedTab == tab ? .semibold : .regular))
                            .frame(height: 22)
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? PremiumTheme.ink : PremiumTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 9)
                    .padding(.bottom, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selectedTab == tab ? PremiumTheme.cream : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.5)
        }
    }
}
