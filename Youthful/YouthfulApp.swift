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
    var multiplier: CGFloat { switch self { case .off: return 0; case .light: return 0.35; case .medium: return 0.65; case .strong: return 1.0 } }
}

enum CoachHaptics {
    private static let key = "globalHapticIntensity"
    static var intensity: HapticIntensity { HapticIntensity(rawValue: UserDefaults.standard.string(forKey: key) ?? HapticIntensity.medium.rawValue) ?? .medium }
    static func setIntensity(_ value: HapticIntensity) { UserDefaults.standard.set(value.rawValue, forKey: key) }
    static func selection() { guard intensity != .off else { return }; let generator = UISelectionFeedbackGenerator(); generator.prepare(); generator.selectionChanged() }
    static func impact() { guard intensity != .off else { return }; let generator = UIImpactFeedbackGenerator(style: impactStyle); generator.prepare(); generator.impactOccurred(intensity: intensity.multiplier) }
    static func success() { guard intensity != .off else { return }; let generator = UINotificationFeedbackGenerator(); generator.prepare(); generator.notificationOccurred(.success) }
    private static var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle { switch intensity { case .off, .light: return .light; case .medium: return .medium; case .strong: return .heavy } }
}

private struct TabHapticInstaller: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIViewController(context: Context) -> UIViewController { let controller = UIViewController(); controller.view.backgroundColor = .clear; return controller }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { DispatchQueue.main.async { guard let tabBarController = uiViewController.findTabBarController() else { return }; if tabBarController.delegate !== context.coordinator { tabBarController.delegate = context.coordinator } } }
    final class Coordinator: NSObject, UITabBarControllerDelegate { func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) { CoachHaptics.selection() } }
}

private extension UIViewController {
    func findTabBarController() -> UITabBarController? { var current: UIViewController? = self; while let controller = current { if let tab = controller as? UITabBarController { return tab }; if let tab = controller.tabBarController { return tab }; current = controller.parent }; return nil }
}

@main
struct YouthfulApp: App {
    init() { UINavigationBar.appearance().tintColor = UIColor(PremiumTheme.ink) }
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView().preferredColorScheme(.light).background(TabHapticInstaller())
                UnifiedFeatureLauncher()
            }
        }
        .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self, ScheduledGoal.self, ProductIntelligence.self, SmartReminder.self, PhotoNote.self])
    }
}

// MARK: - AssistiveTouch-style unified floating feature menu
private struct UnifiedFeatureLauncher: View {
    @State private var showing = false
    @State private var selectedDestination: Destination?
    @State private var position: CGPoint = .zero
    @State private var dragStartPosition: CGPoint = .zero
    @State private var hasStoredPosition = false
    @State private var didDrag = false

    private let buttonSize: CGFloat = 58
    private let itemHeight: CGFloat = 44
    private let itemSpacing: CGFloat = 9
    private let edgePadding: CGFloat = 18
    private let defaultBottomOffset: CGFloat = 105
    private enum Destination: String, Identifiable { case smartFeatures, progress, scheduledGoals; var id: String { rawValue } }

    var body: some View {
        GeometryReader { proxy in
            let safe = proxy.safeAreaInsets
            let bounds = proxy.size
            let defaultPosition = CGPoint(x: bounds.width - edgePadding - buttonSize / 2, y: bounds.height - safe.bottom - defaultBottomOffset)
            dock
                .position(hasStoredPosition ? clamped(position, in: bounds, safe: safe) : defaultPosition)
                .contentShape(Circle().size(width: buttonSize + 28, height: buttonSize + 28))
                .onAppear { if !hasStoredPosition { position = defaultPosition } }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(item: $selectedDestination) { destination in destinationView(destination) }
    }

    private var dock: some View {
        ZStack(alignment: .bottomTrailing) {
            if showing {
                menu
                    .padding(.trailing, 3)
                    .padding(.bottom, buttonSize + 12)
                    .transition(.scale(scale: 0.88, anchor: .bottomTrailing).combined(with: .opacity))
            }

            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(.white.opacity(0.10))
                Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1)
                Image(systemName: showing ? "xmark" : "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(PremiumTheme.ink)
            }
            .frame(width: buttonSize, height: buttonSize)
            .shadow(color: .black.opacity(0.18), radius: 15, y: 6)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if !hasStoredPosition {
                            position = CGPoint(x: value.startLocation.x, y: value.startLocation.y)
                            hasStoredPosition = true
                        }
                        if !didDrag && (abs(value.translation.width) > 6 || abs(value.translation.height) > 6) {
                            didDrag = true
                            CoachHaptics.impact()
                        }
                        guard didDrag else { return }
                        position = CGPoint(
                            x: dragStartPosition.x + value.translation.width,
                            y: dragStartPosition.y + value.translation.height
                        )
                    }
                    .onEnded { value in
                        let moved = abs(value.translation.width) > 6 || abs(value.translation.height) > 6
                        if !moved {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { showing.toggle() }
                            CoachHaptics.selection()
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                position = clamped(position, in: UIScreen.main.bounds.size, safe: EdgeInsets())
                            }
                            CoachHaptics.selection()
                        }
                        dragStartPosition = position
                        didDrag = false
                    }
            )
            .accessibilityLabel(showing ? "Close feature menu" : "Open feature menu")
            .accessibilityAddTraits(.isButton)
        }
        .frame(width: buttonSize, height: buttonSize, alignment: .bottomTrailing)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showing)
        .onAppear { dragStartPosition = position }
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
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { showing = false }
            selectedDestination = destination
        } label: {
            HStack(spacing: 8) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(PremiumTheme.ink).padding(.horizontal, 13).frame(height: itemHeight).background(.ultraThinMaterial).clipShape(Capsule())
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(PremiumTheme.ink).frame(width: itemHeight, height: itemHeight).background(.ultraThinMaterial).overlay { Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.8) }.clipShape(Circle())
            }
            .shadow(color: .black.opacity(0.11), radius: 9, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func destinationView(_ destination: Destination) -> some View {
        switch destination { case .smartFeatures: V2FeatureMenu(); case .progress: SmartFeaturesView(); case .scheduledGoals: ScheduledGoalsView() }
    }

    private func clamped(_ point: CGPoint, in size: CGSize, safe: EdgeInsets) -> CGPoint {
        let minX = edgePadding + buttonSize / 2, maxX = size.width - edgePadding - buttonSize / 2
        let minY = safe.top + edgePadding + buttonSize / 2, maxY = size.height - safe.bottom - edgePadding - buttonSize / 2
        return CGPoint(x: min(max(point.x, minX), maxX), y: min(max(point.y, minY), maxY))
    }
}
