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
                UnifiedFeatureLauncher().zIndex(9999)
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
    private let dragThreshold: CGFloat = 8
    private let menuGap: CGFloat = 12
    private let menuWidth: CGFloat = 210
    private let edgeActivation: CGFloat = 105
    private let iconColumnWidth: CGFloat = 44
    private enum Destination: String, Identifiable { case smartFeatures, progress, scheduledGoals; var id: String { rawValue } }
    private enum MenuHorizontalSide { case left, right, center }

    var body: some View {
        GeometryReader { proxy in
            let safe = proxy.safeAreaInsets
            let bounds = proxy.size
            let defaultPosition = CGPoint(x: bounds.width - edgePadding - buttonSize / 2, y: bounds.height - safe.bottom - defaultBottomOffset)
            let current = launcherPoint(defaultPosition: defaultPosition, bounds: bounds, safe: safe)

            ZStack {
                if showing {
                    menu(for: current, in: bounds, safe: safe)
                        .zIndex(1)
                        .transition(.scale(scale: 0.88, anchor: .center).combined(with: .opacity))
                }

                dock
                    .position(current)
                    .zIndex(2)
                    .onAppear {
                        if !hasStoredPosition { position = defaultPosition; dragStartPosition = defaultPosition }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showing)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(item: $selectedDestination) { destination in destinationView(destination) }
    }

    private var menuHeight: CGFloat { itemHeight * 3 + itemSpacing * 2 }

    private func launcherPoint(defaultPosition: CGPoint, bounds: CGSize, safe: EdgeInsets) -> CGPoint {
        hasStoredPosition ? clamped(position, in: bounds, safe: safe) : defaultPosition
    }

    private func menuSide(for point: CGPoint, in size: CGSize) -> MenuHorizontalSide {
        if point.x <= edgeActivation { return .right }
        if point.x >= size.width - edgeActivation { return .left }
        return .center
    }

    private func menu(for point: CGPoint, in size: CGSize, safe: EdgeInsets) -> some View {
        let side = menuSide(for: point, in: size)
        let isTop = point.y <= safe.top + edgeActivation
        let isBottom = point.y >= size.height - safe.bottom - edgeActivation

        // The menu is positioned so the center of its icon column always lands
        // exactly on the floating button's center. Labels then extend outward.
        let menuX: CGFloat = {
            switch side {
            case .left: return point.x - menuWidth + iconColumnWidth / 2
            case .right: return point.x - iconColumnWidth / 2
            case .center: return point.x - menuWidth / 2
            }
        }()

        let menuY = isTop
            ? point.y + buttonSize / 2 + menuGap + menuHeight / 2
            : point.y - buttonSize / 2 - menuGap - menuHeight / 2

        let minX: CGFloat = {
            switch side {
            case .left: return 8
            case .right: return 8 - (iconColumnWidth / 2)
            case .center: return 8
            }
        }()
        let maxX = size.width - menuWidth - 8 + (side == .right ? iconColumnWidth : 0)
        let clampedX = min(max(menuX, minX), maxX)
        let minY = safe.top + menuHeight / 2 + 8
        let maxY = size.height - safe.bottom - menuHeight / 2 - 8
        let clampedY = min(max(menuY, minY), maxY)

        return menuContents(side: side)
            .position(x: clampedX + menuWidth / 2, y: clampedY)
    }

    private func menuContents(side: MenuHorizontalSide) -> some View {
        VStack(spacing: itemSpacing) {
            menuButton(.smartFeatures, "Smart Features", "sparkles.rectangle.stack.fill", side: side)
            menuButton(.progress, "My Progress", "chart.xyaxis.line", side: side)
            menuButton(.scheduledGoals, "Scheduled Goals", "calendar.badge.clock", side: side)
        }
        .frame(width: menuWidth, height: menuHeight, alignment: side == .right ? .leading : (side == .left ? .trailing : .center))
    }

    private var dock: some View {
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
        .allowsHitTesting(true)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if !hasStoredPosition {
                        hasStoredPosition = true
                        position = CGPoint(x: value.location.x, y: value.location.y)
                        dragStartPosition = position
                    }
                    let moved = abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold
                    if moved && !didDrag { didDrag = true; CoachHaptics.impact() }
                    if didDrag { position = CGPoint(x: dragStartPosition.x + value.translation.width, y: dragStartPosition.y + value.translation.height) }
                }
                .onEnded { value in
                    let moved = abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold
                    if moved {
                        position = clamped(position, in: UIScreen.main.bounds.size, safe: EdgeInsets())
                        dragStartPosition = position
                        CoachHaptics.selection()
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { showing.toggle() }
                        CoachHaptics.selection()
                    }
                    didDrag = false
                }
        )
        .accessibilityLabel(showing ? "Close feature menu" : "Open feature menu")
        .accessibilityAddTraits(.isButton)
    }

    private func menuButton(_ destination: Destination, _ title: String, _ icon: String, side: MenuHorizontalSide) -> some View {
        Button {
            CoachHaptics.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { showing = false }
            selectedDestination = destination
        } label: {
            HStack(spacing: 8) {
                if side == .left {
                    labelView(title)
                    iconView(icon)
                } else if side == .right {
                    iconView(icon)
                    labelView(title)
                } else {
                    labelView(title)
                    iconView(icon)
                }
            }
            .frame(width: menuWidth, height: itemHeight, alignment: side == .left ? .trailing : (side == .right ? .leading : .trailing))
            .contentShape(Rectangle())
            .shadow(color: .black.opacity(0.11), radius: 9, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func iconView(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(PremiumTheme.ink)
            .frame(width: itemHeight, height: itemHeight)
            .background(.ultraThinMaterial)
            .overlay { Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.8) }
            .clipShape(Circle())
    }

    private func labelView(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(PremiumTheme.ink)
            .padding(.horizontal, 13)
            .frame(height: itemHeight)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
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
