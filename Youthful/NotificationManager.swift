import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func enable() async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        if granted { schedule() }
    }

    func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["am", "pm", "photo"])

        var am = DateComponents(); am.hour = 8; am.minute = 0
        var pm = DateComponents(); pm.hour = 21; pm.minute = 30

        let morning = UNMutableNotificationContent()
        morning.title = "☀️ Youthful"
        morning.body = "Cleanse, moisturize, SPF 50 and style your hair."
        morning.sound = .default

        let evening = UNMutableNotificationContent()
        evening.title = "🌙 Youthful"
        evening.body = "Time for your night routine."
        evening.sound = .default

        center.add(UNNotificationRequest(identifier:"am", content:morning, trigger:UNCalendarNotificationTrigger(dateMatching:am, repeats:true)))
        center.add(UNNotificationRequest(identifier:"pm", content:evening, trigger:UNCalendarNotificationTrigger(dateMatching:pm, repeats:true)))
    }

    func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["am","pm","photo"])
    }
}
