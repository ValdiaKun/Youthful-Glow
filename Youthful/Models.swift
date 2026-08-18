import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var completedIDs: [String]
    var sleepHours: Double
    var waterGlasses: Int
    var workoutDone: Bool

    init(date: Date = .now, completedIDs: [String] = [], sleepHours: Double = 0, waterGlasses: Int = 0, workoutDone: Bool = false) {
        self.date = Calendar.current.startOfDay(for: date)
        self.completedIDs = completedIDs
        self.sleepHours = sleepHours
        self.waterGlasses = waterGlasses
        self.workoutDone = workoutDone
    }

    func isCompleted(_ id: String) -> Bool { completedIDs.contains(id) }

    func toggle(_ id: String) {
        if let i = completedIDs.firstIndex(of: id) { completedIDs.remove(at: i) }
        else { completedIDs.append(id) }
    }
}

@Model
final class Product {
    var name: String
    var category: String
    var notes: String
    var isActive: Bool

    init(name: String, category: String, notes: String = "", isActive: Bool = true) {
        self.name = name
        self.category = category
        self.notes = notes
        self.isActive = isActive
    }
}

@Model
final class ProgressPhoto {
    var date: Date
    var label: String
    var imageData: Data

    init(date: Date = .now, label: String, imageData: Data) {
        self.date = date
        self.label = label
        self.imageData = imageData
    }
}

struct RoutineItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let schedule: String?
}

enum RoutineCatalog {
    static let morning = [
        RoutineItem(id:"cleanse-am", title:"Gentle cleanse", subtitle:"Clean without scrubbing or stripping.", icon:"drop.fill", schedule:nil),
        RoutineItem(id:"moist-am", title:"Moisturizer", subtitle:"Use a lightweight, non-greasy moisturizer.", icon:"humidity.fill", schedule:nil),
        RoutineItem(id:"spf", title:"SPF 50", subtitle:"Apply generously to face, ears and neck.", icon:"sun.max.fill", schedule:"Every morning"),
        RoutineItem(id:"hair", title:"Style hair", subtitle:"Textured low taper; lift the front slightly.", icon:"scissors", schedule:nil)
    ]

    static let evening = [
        RoutineItem(id:"cleanse-pm", title:"Cleanse", subtitle:"Wash away sunscreen, oil and the day.", icon:"drop.fill", schedule:nil),
        RoutineItem(id:"retinol", title:"Retinol", subtitle:"Start 2 nights/week and increase only if tolerated.", icon:"moon.stars.fill", schedule:"2× / week"),
        RoutineItem(id:"moist-pm", title:"Moisturizer", subtitle:"Keep the skin barrier comfortable.", icon:"humidity.fill", schedule:nil),
        RoutineItem(id:"lips", title:"Lip care", subtitle:"Balm during the day; petrolatum before bed if dry.", icon:"heart.fill", schedule:nil)
    ]

    static let all = morning + evening
}

enum AppGoals {
    static let sleepTarget = 7.0
    static let waterTarget = 6
}
