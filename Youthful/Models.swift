import Foundation
import SwiftUI
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

    init(label: String, imageData: Data, date: Date = .now) {
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

// V1.4a support views. Kept in this file so the branch remains self-contained.
struct ProductsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Product.name) private var products: [Product]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack { PremiumBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Routine").font(.system(size: 35, weight: .semibold, design: .serif))
                        Text("Build a routine around the products you actually use.").foregroundStyle(PremiumTheme.muted)
                        Button { showingAdd = true } label: {
                            Label("Add product", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(15)
                                .background(PremiumTheme.ink).foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)

                        if products.isEmpty {
                            PremiumCard { VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "drop.circle").font(.title2).foregroundStyle(PremiumTheme.warm)
                                Text("No products yet").font(.headline)
                                Text("Add your cleanser, moisturizer, SPF, hair products and other essentials.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                            }}
                        } else {
                            ForEach(products) { product in
                                PremiumCard { HStack(spacing: 12) {
                                    Image(systemName: product.isActive ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(product.isActive ? PremiumTheme.ink : PremiumTheme.muted)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(product.name).font(.subheadline.weight(.semibold))
                                        Text(product.category + (product.notes.isEmpty ? "" : " · " + product.notes))
                                            .font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(2)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(get: { product.isActive }, set: { product.isActive = $0; try? context.save() }))
                                        .labelsHidden()
                                }}
                            }.onDelete { offsets in
                                offsets.forEach { context.delete(products[$0]) }
                                try? context.save()
                            }
                        }
                    }.padding(20)
                }
            }.toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingAdd) { AddProductView() }
    }
}

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var category = "Skincare"
    @State private var notes = ""
    private let categories = ["Skincare", "Hair", "Beard", "Grooming", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Product name", text: $name)
                    Picker("Category", selection: $category) { ForEach(categories, id: \.self) { Text($0) } }
                    TextField("Notes (optional)", text: $notes)
                }
                Section { Button("Add to routine") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    context.insert(Product(name: trimmed, category: category, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)))
                    try? context.save(); dismiss()
                }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .navigationTitle("Add product")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    var body: some View {
        NavigationStack {
            ZStack { PremiumBackground(); Form {
                Section("Youthful") {
                    HStack { Text("Appearance Coach"); Spacer(); Text("V1.4a").foregroundStyle(PremiumTheme.muted) }
                }
                Section("Reminders") {
                    Toggle("Daily routine reminders", isOn: Binding(get: { notificationsEnabled }, set: { value in notificationsEnabled = value; if value { Task { await NotificationManager.shared.enable() } } else { NotificationManager.shared.disable() } }))
                }
            }.scrollContentBackground(.hidden) }
            .navigationTitle("More")
        }
    }
}
