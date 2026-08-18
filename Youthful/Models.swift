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
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Routine").font(.system(size: 35, weight: .semibold, design: .serif))
                                Text("Your products, organized into one simple ritual.").foregroundStyle(PremiumTheme.muted)
                            }
                            Spacer()
                            Text("\(products.count)").font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.muted)
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(Color.black.opacity(0.05)).clipShape(Capsule())
                        }

                        Button { showingAdd = true; CoachHaptics.selection() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill").font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add product").font(.subheadline.weight(.bold))
                                    Text("Cleanser, SPF, moisturizer, hair care…").font(.caption).opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.bold)).opacity(0.7)
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(PremiumTheme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
                        }.buttonStyle(.plain)

                        if products.isEmpty {
                            PremiumCard { VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "drop.circle").font(.title2).foregroundStyle(PremiumTheme.warm)
                                Text("No products yet").font(.headline)
                                Text("Add the products you actually use. They will stay here as your personal routine library.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                            }}
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your products").font(.system(size: 21, weight: .semibold, design: .serif))
                                ForEach(products) { product in
                                    PremiumCard { HStack(spacing: 12) {
                                        Image(systemName: product.isActive ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(product.isActive ? PremiumTheme.ink : PremiumTheme.muted)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.name).font(.subheadline.weight(.semibold))
                                            Text(product.category + (product.notes.isEmpty ? "" : " · " + product.notes))
                                                .font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(2)
                                        }
                                        Spacer()
                                        Toggle("Active", isOn: Binding(get: { product.isActive }, set: { product.isActive = $0; try? context.save(); CoachHaptics.selection() }))
                                            .labelsHidden()
                                    }}
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            context.delete(product); try? context.save(); CoachHaptics.impact()
                                        } label: { Label("Delete product", systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }.padding(20).padding(.bottom, 32)
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
    @FocusState private var nameFocused: Bool
    private let categories = ["Skincare", "Hair", "Beard", "Grooming", "Other"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            CapsuleLabel(text: "Routine library")
                            Text("Add a product").font(.system(size: 32, weight: .semibold, design: .serif))
                            Text("Save the products you actually use so your routine stays easy to maintain.")
                                .font(.subheadline).foregroundStyle(PremiumTheme.muted)
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PRODUCT DETAILS").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(PremiumTheme.muted)
                                TextField("Product name", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .focused($nameFocused)
                                    .padding(14)
                                    .background(Color.black.opacity(0.045))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Picker("Category", selection: $category) {
                                    ForEach(categories, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("Notes (optional)", text: $notes, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(14)
                                    .background(Color.black.opacity(0.045))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        Text("You can change whether a product is active later from the Routine tab.")
                            .font(.caption).foregroundStyle(PremiumTheme.muted)
                            .padding(.horizontal, 4)

                        // Extra bottom space keeps the form content above the persistent save action.
                        Color.clear.frame(height: 84)
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }

                VStack(spacing: 8) {
                    Button(action: saveProduct) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Add to routine").fontWeight(.bold)
                            Spacer()
                            Image(systemName: "arrow.right").font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(canSave ? PremiumTheme.ink : PremiumTheme.muted.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(!canSave)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); CoachHaptics.selection() }
                }
            }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { nameFocused = true } }
        }
    }

    private func saveProduct() {
        guard canSave else { return }
        let product = Product(name: trimmedName, category: category, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(product)
        try? context.save()
        CoachHaptics.success()
        dismiss()
    }
}

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var hapticIntensity = CoachHaptics.intensity

    var body: some View {
        NavigationStack {
            ZStack { PremiumBackground(); Form {
                Section("Youthful") {
                    HStack { Text("Appearance Coach"); Spacer(); Text("V1.4b").foregroundStyle(PremiumTheme.muted) }
                }
                Section("Reminders") {
                    Toggle("Daily routine reminders", isOn: Binding(get: { notificationsEnabled }, set: { value in notificationsEnabled = value; CoachHaptics.selection(); if value { Task { await NotificationManager.shared.enable() } } else { NotificationManager.shared.disable() } }))
                }
                Section("Haptics") {
                    Picker("Global haptic intensity", selection: $hapticIntensity) {
                        ForEach(HapticIntensity.allCases) { intensity in
                            Text(intensity.rawValue).tag(intensity)
                        }
                    }
                    .onChange(of: hapticIntensity) { _, newValue in
                        CoachHaptics.setIntensity(newValue)
                        if newValue != .off { CoachHaptics.selection() }
                    }
                    Text("Controls haptic feedback throughout Youthful, including tabs, switches and actions.")
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.muted)
                }
            }.scrollContentBackground(.hidden) }
            .navigationTitle("More")
        }
    }
}
