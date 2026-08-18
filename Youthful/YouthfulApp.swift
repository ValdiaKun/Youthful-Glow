import SwiftUI
import SwiftData
import UserNotifications
import UIKit

// MARK: - Global appearance

enum YouthfulAppearance: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case amoled = "AMOLED"
    var id: String { rawValue }
    var icon: String {
        switch self { case .light: return "sun.max.fill"; case .dark: return "moon.fill"; case .amoled: return "circle.lefthalf.filled" }
    }
    var colorScheme: ColorScheme { self == .light ? .light : .dark }
    var description: String {
        switch self { case .light: return "Bright, warm and airy."; case .dark: return "Dark surfaces with softer contrast."; case .amoled: return "Pure-black OLED-friendly appearance." }
    }
}

private struct AppearanceSettingsView: View {
    @AppStorage("youthfulAppearance") private var appearanceRaw = YouthfulAppearance.light.rawValue
    private var appearance: YouthfulAppearance { YouthfulAppearance(rawValue: appearanceRaw) ?? .light }

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(YouthfulAppearance.allCases) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { appearanceRaw = mode.rawValue }
                            CoachHaptics.selection()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: mode.icon)
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(mode == .amoled ? .white : .primary)
                                    .background(mode == .amoled ? Color.black : Color.primary.opacity(0.08))
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.rawValue).font(.headline)
                                    Text(mode.description).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if appearance == mode { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                Section {
                    Text("Light keeps the original Youthful Glow look. Dark uses iOS dark appearance. AMOLED uses the dark appearance with pure-black presentation where the app's custom palette permits it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(appearance.colorScheme)
    }
}

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
    @AppStorage("youthfulAppearance") private var appearanceRaw = YouthfulAppearance.light.rawValue
    init() { UINavigationBar.appearance().tintColor = UIColor(PremiumTheme.ink) }
    private var appearance: YouthfulAppearance { YouthfulAppearance(rawValue: appearanceRaw) ?? .light }
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView().background(TabHapticInstaller())
                UnifiedFeatureLauncher().zIndex(9999)
            }
            .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(for: [DailyLog.self, Product.self, ProgressPhoto.self, ScheduledGoal.self, ProductIntelligence.self, SmartReminder.self, PhotoNote.self])
    }
}

// MARK: - AssistiveTouch-style unified feature menu
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
    private enum Destination: String, Identifiable { case smartFeatures, progress, scheduledGoals, appearance; var id: String { rawValue } }
    private enum MenuHorizontalSide { case left, right, center }

    var body: some View {
        GeometryReader { proxy in
            let safe = proxy.safeAreaInsets
            let bounds = proxy.size
            let defaultPosition = CGPoint(x: bounds.width - edgePadding - buttonSize / 2, y: bounds.height - safe.bottom - defaultBottomOffset)
            let current = launcherPoint(defaultPosition: defaultPosition, bounds: bounds, safe: safe)
            ZStack {
                if showing { menu(for: current, in: bounds, safe: safe).zIndex(1).transition(.scale(scale: 0.88).combined(with: .opacity)) }
                dock.position(current).zIndex(2).onAppear { if !hasStoredPosition { position = defaultPosition; dragStartPosition = defaultPosition } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showing)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(item: $selectedDestination) { destination in destinationView(destination) }
    }

    private var menuHeight: CGFloat { itemHeight * 4 + itemSpacing * 3 }
    private func launcherPoint(defaultPosition: CGPoint, bounds: CGSize, safe: EdgeInsets) -> CGPoint { hasStoredPosition ? clamped(position, in: bounds, safe: safe) : defaultPosition }
    private func menuSide(for point: CGPoint, in size: CGSize) -> MenuHorizontalSide { if point.x <= edgeActivation { return .right }; if point.x >= size.width - edgeActivation { return .left }; return .center }

    private func menu(for point: CGPoint, in size: CGSize, safe: EdgeInsets) -> some View {
        let side = menuSide(for: point, in: size)
        let isTop = point.y <= safe.top + edgeActivation
        let menuX: CGFloat = side == .left ? point.x - menuWidth + iconColumnWidth / 2 : side == .right ? point.x - iconColumnWidth / 2 : point.x - menuWidth / 2
        let menuY = isTop ? point.y + buttonSize / 2 + menuGap + menuHeight / 2 : point.y - buttonSize / 2 - menuGap - menuHeight / 2
        let minX: CGFloat = 8
        let maxX = size.width - menuWidth - 8 + (side == .right ? iconColumnWidth : 0)
        let minY = safe.top + menuHeight / 2 + 8
        let maxY = size.height - safe.bottom - menuHeight / 2 - 8
        return menuContents(side: side).position(x: min(max(menuX, minX), maxX) + menuWidth / 2, y: min(max(menuY, minY), maxY))
    }

    private func menuContents(side: MenuHorizontalSide) -> some View {
        VStack(spacing: itemSpacing) {
            menuButton(.smartFeatures, "Smart Features", "sparkles.rectangle.stack.fill", side: side)
            menuButton(.progress, "My Progress", "chart.xyaxis.line", side: side)
            menuButton(.scheduledGoals, "Scheduled Goals", "calendar.badge.clock", side: side)
            menuButton(.appearance, "Appearance", "circle.lefthalf.filled", side: side)
        }
        .frame(width: menuWidth, height: menuHeight, alignment: side == .right ? .leading : (side == .left ? .trailing : .trailing))
    }

    private var dock: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(.white.opacity(0.10))
            Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1)
            Image(systemName: showing ? "xmark" : "sparkles").font(.system(size: 20, weight: .bold)).foregroundStyle(PremiumTheme.ink)
        }
        .frame(width: buttonSize, height: buttonSize)
        .shadow(color: .black.opacity(0.18), radius: 15, y: 6)
        .contentShape(Circle())
        .highPriorityGesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
            if !hasStoredPosition { hasStoredPosition = true; position = value.location; dragStartPosition = position }
            let moved = abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold
            if moved && !didDrag { didDrag = true; CoachHaptics.impact() }
            if didDrag { position = CGPoint(x: dragStartPosition.x + value.translation.width, y: dragStartPosition.y + value.translation.height) }
        }.onEnded { value in
            let moved = abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold
            if moved { position = clamped(position, in: UIScreen.main.bounds.size, safe: EdgeInsets()); dragStartPosition = position; CoachHaptics.selection() }
            else { withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { showing.toggle() }; CoachHaptics.selection() }
            didDrag = false
        })
        .accessibilityLabel(showing ? "Close feature menu" : "Open feature menu")
        .accessibilityAddTraits(.isButton)
    }

    private func menuButton(_ destination: Destination, _ title: String, _ icon: String, side: MenuHorizontalSide) -> some View {
        Button {
            CoachHaptics.selection(); withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { showing = false }; selectedDestination = destination
        } label: {
            HStack(spacing: 8) {
                if side == .left { labelView(title); iconView(icon) }
                else if side == .right { iconView(icon); labelView(title) }
                else { labelView(title); iconView(icon) }
            }
            .frame(width: menuWidth, height: itemHeight, alignment: side == .left ? .trailing : (side == .right ? .leading : .trailing))
            .contentShape(Rectangle()).shadow(color: .black.opacity(0.11), radius: 9, y: 3)
        }
        .buttonStyle(.plain)
    }
    private func iconView(_ icon: String) -> some View { Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(PremiumTheme.ink).frame(width: itemHeight, height: itemHeight).background(.ultraThinMaterial).overlay { Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.8) }.clipShape(Circle()) }
    private func labelView(_ title: String) -> some View { Text(title).font(.caption.weight(.semibold)).foregroundStyle(PremiumTheme.ink).padding(.horizontal, 13).frame(height: itemHeight).background(.ultraThinMaterial).clipShape(Capsule()) }

    @ViewBuilder private func destinationView(_ destination: Destination) -> some View {
        switch destination { case .smartFeatures: V2FeatureMenu(); case .progress: SmartFeaturesView(); case .scheduledGoals: ScheduledGoalsView(); case .appearance: AppearanceSettingsView() }
    }
    private func clamped(_ point: CGPoint, in size: CGSize, safe: EdgeInsets) -> CGPoint {
        let minX = edgePadding + buttonSize / 2, maxX = size.width - edgePadding - buttonSize / 2
        let minY = safe.top + edgePadding + buttonSize / 2, maxY = size.height - safe.bottom - edgePadding - buttonSize / 2
        return CGPoint(x: min(max(point.x, minX), maxX), y: min(max(point.y, minY), maxY))
    }
}
