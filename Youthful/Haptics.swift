import SwiftUI
import UIKit
import ObjectiveC

/// Centralized tactile feedback for Youthful's native iOS controls.
enum YouthfulHaptics {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true

        DispatchQueue.main.async {
            installTabBarDelegate()
            installSwitchFeedback()
        }
    }

    private static func installTabBarDelegate() {
        guard let tabBarController = findTabBarController() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                installTabBarDelegate()
            }
            return
        }

        let delegate = HapticTabBarDelegate()
        tabBarController.delegate = delegate
        objc_setAssociatedObject(
            tabBarController,
            &AssociatedKeys.tabDelegate,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    private static func findTabBarController() -> UITabBarController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows {
                if let controller = findTabBarController(in: window.rootViewController) {
                    return controller
                }
            }
        }
        return nil
    }

    private static func findTabBarController(in controller: UIViewController?) -> UITabBarController? {
        guard let controller else { return nil }
        if let tab = controller as? UITabBarController { return tab }

        for child in controller.children {
            if let tab = findTabBarController(in: child) { return tab }
        }
        if let presented = controller.presentedViewController,
           let tab = findTabBarController(in: presented) {
            return tab
        }
        return nil
    }

    private static func installSwitchFeedback() {
        guard
            let original = class_getInstanceMethod(UIControl.self, #selector(UIControl.sendAction(_:to:for:))),
            let swizzled = class_getInstanceMethod(UIControl.self, #selector(UIControl.youthful_sendAction(_:to:for:)))
        else { return }

        method_exchangeImplementations(original, swizzled)
    }

    private enum AssociatedKeys {
        static var tabDelegate: UInt8 = 0
    }
}

private final class HapticTabBarDelegate: NSObject, UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

private extension UIControl {
    @objc func youthful_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if self is UISwitch {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }

        youthful_sendAction(action, to: target, for: event)
    }
}
