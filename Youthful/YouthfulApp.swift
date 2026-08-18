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

                ScheduledGoalsLauncher()
                RoutineStreaksLauncher()
                V2FeatureLauncher()
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

// MARK: - Routine streaks launcher

private struct RoutineStreaksLauncher: View {
    @State private var showingStreaks = false

    var body: some View {
        Button {
            CoachHaptics.selection()
            showingStreaks = true
        } label: {
            Image(systemName: "flame.fill")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 130)
        .sheet(isPresented: $showingStreaks) {
            SmartFeaturesView()
        }
    }
}
