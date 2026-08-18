import SwiftUI
import SwiftData
import UserNotifications

@Model
final class ScheduledGoal {
    var id: String
    var title: String
    var detail: String
    var icon: String
    var hour: Int
    var minute: Int
    var repeats: Bool
    var enabled: Bool

    init(id: String = UUID().uuidString, title: String, detail: String = "", icon: String = "bell.fill", hour: Int = 21, minute: Int = 30, repeats: Bool = true, enabled: Bool = true) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
        self.hour = hour
        self.minute = minute
        self.repeats = repeats
        self.enabled = enabled
    }
}

enum GoalTemplates {
    static let all: [(String, String, String, Int, Int)] = [
        ("Face cleanse", "Cleanse gently and avoid aggressive scrubbing.", "drop.fill", 21, 30),
        ("Morning SPF", "Apply broad-spectrum sunscreen before heading outdoors.", "sun.max.fill", 8, 0),
        ("Moisturize", "Keep your skin comfortable and hydrated.", "humidity.fill", 21, 35),
        ("Hair-care day", "Wash or condition according to your hair needs.", "scissors", 9, 0),
        ("Beard trim", "Tidy edges and neckline without over-trimming.", "person.crop.square.fill", 10, 0),
        ("Grooming reset", "A short weekly reset for nails, shaving and general grooming.", "sparkles", 10, 30)
    ]
}

struct ScheduledGoalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ScheduledGoal.hour) private var goals: [ScheduledGoal]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SCHEDULED GOALS").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(PremiumTheme.muted)
                            Text("Stay consistent, automatically.").font(.system(size: 30, weight: .semibold, design: .serif))
                            Text("Set a goal once and Youthful will remind you at the time you choose.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                        }

                        Button { showingAdd = true; CoachHaptics.selection() } label: {
                            Label("Schedule a goal", systemImage: "plus").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(15).background(PremiumTheme.ink).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)

                        if goals.isEmpty {
                            PremiumCard { VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "calendar.badge.clock").font(.title2).foregroundStyle(PremiumTheme.warm)
                                Text("No scheduled goals yet").font(.headline)
                                Text("Add reminders for face care, SPF, hair care or grooming.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                            }}
                        } else {
                            ForEach(goals) { goal in
                                PremiumCard { HStack(spacing: 13) {
                                    Image(systemName: goal.icon).frame(width: 42, height: 42).background(PremiumTheme.cream).clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.title).font(.subheadline.weight(.semibold))
                                        Text(goal.detail).font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(2)
                                        Text(timeText(goal.hour, goal.minute) + (goal.repeats ? " • Every day" : " • Once")).font(.caption2.weight(.semibold)).foregroundStyle(PremiumTheme.warm)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(get: { goal.enabled }, set: { value in
                                        goal.enabled = value
                                        GoalNotificationScheduler.shared.schedule(goal)
                                        try? context.save()
                                        CoachHaptics.selection()
                                    })).labelsHidden()
                                }}
                            }
                        }
                    }.padding(20).padding(.bottom, 30)
                }
            }.toolbar(.hidden, for: .navigationBar)
        }.sheet(isPresented: $showingAdd) { AddScheduledGoalView() }
    }

    private func timeText(_ hour: Int, _ minute: Int) -> String {
        var components = DateComponents(); components.hour = hour; components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

struct AddScheduledGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = "Face cleanse"
    @State private var detail = "Cleanse gently and avoid aggressive scrubbing."
    @State private var icon = "drop.fill"
    @State private var hour = 21
    @State private var minute = 30
    @State private var repeats = true
    @State private var enabled = true

    private let templateNames = GoalTemplates.all.map { $0.0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    Picker("Suggested goal", selection: $title) { ForEach(templateNames, id: \.self) { Text($0) } }
                    TextField("Goal name", text: $title)
                    TextField("What should the reminder say?", text: $detail)
                }
                Section("Schedule") {
                    DatePicker("Reminder time", selection: Binding(get: {
                        var c = DateComponents(); c.hour = hour; c.minute = minute
                        return Calendar.current.date(from: c) ?? .now
                    }, set: { value in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: value)
                        hour = c.hour ?? hour; minute = c.minute ?? minute
                    }), displayedComponents: .hourAndMinute)
                    Toggle("Repeat every day", isOn: $repeats)
                    Toggle("Enable reminder", isOn: $enabled)
                }
                Section {
                    Button("Save scheduled goal") {
                        let goal = ScheduledGoal(title: title.trimmingCharacters(in: .whitespacesAndNewlines), detail: detail, icon: icon, hour: hour, minute: minute, repeats: repeats, enabled: enabled)
                        context.insert(goal); try? context.save()
                        Task { await GoalNotificationScheduler.shared.requestPermissionIfNeeded(); GoalNotificationScheduler.shared.schedule(goal) }
                        CoachHaptics.success(); dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Schedule goal")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onChange(of: title) { _, newValue in
                if let template = GoalTemplates.all.first(where: { $0.0 == newValue }) {
                    detail = template.1; icon = template.2; hour = template.3; minute = template.4
                }
            }
        }
    }
}

final class GoalNotificationScheduler {
    static let shared = GoalNotificationScheduler()
    private init() {}

    func requestPermissionIfNeeded() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(_ goal: ScheduledGoal) {
        let center = UNUserNotificationCenter.current()
        let identifier = "goal-" + goal.id
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard goal.enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Youthful • \(goal.title)"
        content.body = goal.detail.isEmpty ? "Time for your scheduled goal." : goal.detail
        content.sound = .default
        var components = DateComponents(); components.hour = goal.hour; components.minute = goal.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: goal.repeats)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
