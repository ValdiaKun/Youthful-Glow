import SwiftUI
import SwiftData
import UserNotifications
import UIKit

// MARK: - Global haptics

enum HapticIntensity: String, CaseIterable, Identifiable {
    case off = "Off"
    case light = "Light"
    case medium = "Medium"
    case strong = "Strong"

    var id: String { rawValue }
    var multiplier: CGFloat {
        switch self {
        case .off: return 0
        case .light: return 0.35
        case .medium: return 0.65
        case .strong: return 1.0
        }
    }
}

enum CoachHaptics {
    private static let key = "globalHapticIntensity"

    static var intensity: HapticIntensity {
        HapticIntensity(rawValue: UserDefaults.standard.string(forKey: key) ?? HapticIntensity.medium.rawValue) ?? .medium
    }

    static func setIntensity(_ value: HapticIntensity) {
        UserDefaults.standard.set(value.rawValue, forKey: key)
    }

    static func selection() {
        guard intensity != .off else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func impact() {
        guard intensity != .off else { return }
        let generator = UIImpactFeedbackGenerator(style: impactStyle)
        generator.prepare()
        generator.impactOccurred(intensity: intensity.multiplier)
    }

    static func success() {
        guard intensity != .off else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private static var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch intensity {
        case .off, .light: return .light
        case .medium: return .medium
        case .strong: return .heavy
        }
    }
}

private struct TabHapticInstaller: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let tabBarController = uiViewController.findTabBarController() else { return }
            if tabBarController.delegate !== context.coordinator {
                tabBarController.delegate = context.coordinator
            }
        }
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            CoachHaptics.selection()
        }
    }
}

private extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        var current: UIViewController? = self
        while let controller = current {
            if let tab = controller as? UITabBarController { return tab }
            if let tab = controller.tabBarController { return tab }
            current = controller.parent
        }
        return nil
    }
}

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
                    .background(TabHapticInstaller())

                UnifiedFeatureLauncher()
            }
        }
        .modelContainer(for: [
            DailyLog.self,
            Product.self,
            ProgressPhoto.self,
            ScheduledGoal.self,
            ProductIntelligence.self,
            SmartReminder.self,
            PhotoNote.self
        ])
    }
}

// MARK: - Unified floating feature menu

private struct UnifiedFeatureLauncher: View {
    @State private var showing = false
    @State private var selectedDestination: Destination?

    private let buttonSize: CGFloat = 50
    private let itemHeight: CGFloat = 44
    private let itemSpacing: CGFloat = 10
    private let trailingPadding: CGFloat = 18
    private let bottomPadding: CGFloat = 72

    private enum Destination: String, Identifiable {
        case smartFeatures
        case progress
        case scheduledGoals

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: itemSpacing) {
            if showing {
                menu
                    .transition(.scale(scale: 0.88, anchor: .bottomTrailing).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showing.toggle()
                }
                CoachHaptics.selection()
            } label: {
                Image(systemName: showing ? "xmark" : "sparkles.rectangle.stack.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: buttonSize, height: buttonSize)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showing ? "Close feature menu" : "Open feature menu")
        }
        .padding(.trailing, trailingPadding)
        .padding(.bottom, bottomPadding)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showing)
        .sheet(item: $selectedDestination) { destination in
            destinationView(destination)
        }
    }

    private var menu: some View {
        VStack(alignment: .trailing, spacing: itemSpacing) {
            menuButton(.smartFeatures, "Smart Features", "sparkles.rectangle.stack.fill")
            menuButton(.progress, "My Progress", "chart.xyaxis.line")
            menuButton(.scheduledGoals, "Scheduled Goals", "calendar.badge.clock")
        }
    }

    private func menuButton(_ destination: Destination, _ title: String, _ icon: String) -> some View {
        Button {
            CoachHaptics.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                showing = false
            }
            selectedDestination = destination
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PremiumTheme.ink)
                    .padding(.horizontal, 13)
                    .frame(height: itemHeight)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: itemHeight, height: itemHeight)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destinationView(_ destination: Destination) -> some View {
        switch destination {
        case .smartFeatures:
            V2FeatureMenu()
        case .progress:
            SmartFeaturesView()
        case .scheduledGoals:
            ScheduledGoalsView()
        }
    }
}
