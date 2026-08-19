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
    @State private var editingProduct: Product?
    @State private var searchText = ""
    @State private var showingInactive = true
    @State private var productToDelete: Product?

    private var filteredProducts: [Product] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return products.filter { product in
            (showingInactive || product.isActive) &&
            (query.isEmpty || product.name.localizedCaseInsensitiveContains(query) ||
             product.category.localizedCaseInsensitiveContains(query) ||
             product.notes.localizedCaseInsensitiveContains(query))
        }
    }

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
                            Text("\(products.count)").font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.ink)
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(PremiumTheme.labelFill)
                                .clipShape(Capsule())
                        }

                        Button { showingAdd = true; CoachHaptics.selection() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill").font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add product").font(.subheadline.weight(.bold))
                                    Text("Cleanser, SPF, moisturizer, hair care…").font(.caption).opacity(0.85)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.bold)).opacity(0.75)
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(PremiumTheme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
                        }.buttonStyle(.plain)

                        if !products.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass").foregroundStyle(PremiumTheme.muted)
                                TextField("Search products", text: $searchText)
                                    .textInputAutocapitalization(.never)
                                    .foregroundStyle(PremiumTheme.ink)
                                if !searchText.isEmpty {
                                    Button { searchText = "" } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(PremiumTheme.muted)
                                    }.buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(PremiumTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(PremiumTheme.labelFill, lineWidth: 1)
                            }

                            HStack {
                                Text("Your products").font(.system(size: 21, weight: .semibold, design: .serif))
                                    .foregroundStyle(PremiumTheme.ink)
                                Spacer()
                                Menu {
                                    Button(showingInactive ? "Hide inactive" : "Show inactive") {
                                        showingInactive.toggle()
                                        CoachHaptics.selection()
                                    }
                                } label: {
                                    Label(showingInactive ? "All" : "Active", systemImage: showingInactive ? "line.3.horizontal.decrease.circle" : "checkmark.circle")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.muted)
                                }
                            }
                        }

                        if products.isEmpty {
                            PremiumCard { VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "drop.circle").font(.title2).foregroundStyle(PremiumTheme.warm)
                                Text("No products yet").font(.headline).foregroundStyle(PremiumTheme.ink)
                                Text("Add the products you actually use. They will stay here as your personal routine library.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                            }}
                        } else if filteredProducts.isEmpty {
                            PremiumCard { VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "magnifyingglass").font(.title2).foregroundStyle(PremiumTheme.warm)
                                Text("No matching products").font(.headline).foregroundStyle(PremiumTheme.ink)
                                Text(searchText.isEmpty ? "There are no active products to show." : "Try a different name, category or note.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                                if !searchText.isEmpty {
                                    Button("Clear search") { searchText = ""; CoachHaptics.selection() }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                }
                            }}
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(filteredProducts) { product in
                                    PremiumCard {
                                        HStack(spacing: 12) {
                                            Image(systemName: product.isActive ? "checkmark.circle.fill" : "circle")
                                                .font(.title3)
                                                .foregroundStyle(product.isActive ? PremiumTheme.ink : PremiumTheme.muted)
                                            VStack(alignment: .leading, spacing: 5) {
                                                HStack(spacing: 7) {
                                                    Text(product.name)
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundStyle(PremiumTheme.ink)
                                                        .lineLimit(1)
                                                    if !product.isActive {
                                                        Text("Inactive")
                                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                                            .foregroundStyle(PremiumTheme.muted)
                                                            .padding(.horizontal, 7).padding(.vertical, 3)
                                                            .background(PremiumTheme.labelFill)
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                                Text(product.category + (product.notes.isEmpty ? "" : " · " + product.notes))
                                                    .font(.caption)
                                                    .foregroundStyle(PremiumTheme.muted)
                                                    .lineLimit(2)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            Spacer(minLength: 8)
                                        }
                                        .contentShape(Rectangle())
                                        .contextMenu {
                                            Button {
                                                editingProduct = product
                                                CoachHaptics.selection()
                                            } label: { Label("Edit product", systemImage: "pencil") }

                                            Button {
                                                product.isActive.toggle()
                                                try? context.save()
                                                CoachHaptics.selection()
                                            } label: {
                                                Label(product.isActive ? "Mark inactive" : "Mark active", systemImage: product.isActive ? "pause.circle" : "checkmark.circle")
                                            }

                                            Divider()

                                            Button(role: .destructive) {
                                                productToDelete = product
                                                CoachHaptics.selection()
                                            } label: { Label("Delete product", systemImage: "trash") }
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(20).padding(.bottom, 32)
                }
            }.toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingAdd) { AddProductView() }
        .sheet(item: $editingProduct) { product in EditProductView(product: product) }
        .confirmationDialog("Delete product?", isPresented: Binding(get: { productToDelete != nil }, set: { if !$0 { productToDelete = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let product = productToDelete {
                    context.delete(product)
                    try? context.save()
                    CoachHaptics.impact()
                }
                productToDelete = nil
            }
            Button("Cancel", role: .cancel) { productToDelete = nil }
        } message: {
            Text("This removes the product from your library. This action cannot be undone.")
        }
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
                            VStack(alignment: .leading, spacing: 18) {
                                Text("PRODUCT DETAILS")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .tracking(2)
                                    .foregroundStyle(PremiumTheme.muted)

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Product name")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                    TextField("Enter product name", text: $name)
                                        .textInputAutocapitalization(.words)
                                        .focused($nameFocused)
                                        .font(.body)
                                        .foregroundStyle(PremiumTheme.ink)
                                        .tint(PremiumTheme.ink)
                                        .padding(.horizontal, 14)
                                        .frame(minHeight: 50)
                                        .background(PremiumTheme.labelFill)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(PremiumTheme.muted.opacity(0.28), lineWidth: 1)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Category")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                    HStack {
                                        Text(category)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(PremiumTheme.ink)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(PremiumTheme.muted)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(minHeight: 50)
                                    .background(PremiumTheme.labelFill)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(PremiumTheme.muted.opacity(0.28), lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay {
                                        Picker("Category", selection: $category) {
                                            ForEach(categories, id: \.self) { Text($0).foregroundStyle(PremiumTheme.ink).tag($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        .opacity(0.02)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Notes")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                    TextField("Optional notes about this product", text: $notes, axis: .vertical)
                                        .lineLimit(3...5)
                                        .font(.body)
                                        .foregroundStyle(PremiumTheme.ink)
                                        .tint(PremiumTheme.ink)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(minHeight: 88, alignment: .topLeading)
                                        .background(PremiumTheme.labelFill)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(PremiumTheme.muted.opacity(0.28), lineWidth: 1)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }

                        Text("You can change whether a product is active later from the Routine tab.")
                            .font(.caption).foregroundStyle(PremiumTheme.muted)
                            .padding(.horizontal, 4)

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

struct EditProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let product: Product
    @State private var name: String
    @State private var category: String
    @State private var notes: String
    @State private var isActive: Bool
    @FocusState private var nameFocused: Bool

    private let categories = ["Skincare", "Hair", "Beard", "Grooming", "Other"]

    init(product: Product) {
        self.product = product
        _name = State(initialValue: product.name)
        _category = State(initialValue: product.category)
        _notes = State(initialValue: product.notes)
        _isActive = State(initialValue: product.isActive)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            CapsuleLabel(text: "Routine library")
                            Text("Edit product").font(.system(size: 32, weight: .semibold, design: .serif))
                            Text("Keep the details current so your routine stays useful.")
                                .font(.subheadline).foregroundStyle(PremiumTheme.muted)
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("PRODUCT DETAILS")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .tracking(2)
                                    .foregroundStyle(PremiumTheme.muted)

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Product name")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                    TextField("Enter product name", text: $name)
                                        .textInputAutocapitalization(.words)
                                        .focused($nameFocused)
                                        .font(.body)
                                        .foregroundStyle(PremiumTheme.ink)
                                        .tint(PremiumTheme.ink)
                                        .padding(.horizontal, 14)
                                        .frame(minHeight: 50)
                                        .background(PremiumTheme.labelFill)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(PremiumTheme.muted.opacity(0.28), lineWidth: 1)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Category")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                    HStack {
                                        Text(category)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(PremiumTheme.ink)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(PremiumTheme.muted)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(minHeight: 50)
                                    .background(PremiumTheme.labelFill)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(PremiumTheme.muted.opacity(0.28), lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay {
                                        Picker("Category", selection: $category) {
                                            ForEach(categories, id: \.self) { Text($0).foregroundStyle(PremiumTheme.ink).tag($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        .opacity(0.02)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Notes")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PremiumTheme.ink)
                                    TextField("Optional notes about this product", text: $notes, axis: .vertical)
                                        .lineLimit(3...5)
                                        .font(.body)
                                        .foregroundStyle(PremiumTheme.ink)
                                        .tint(PremiumTheme.ink)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(minHeight: 88, alignment: .topLeading)
                                        .background(PremiumTheme.labelFill)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(PremiumTheme.muted.opacity(0.28), lineWidth: 1)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }

                                Toggle("Active product", isOn: $isActive)
                                    .tint(PremiumTheme.ink)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); CoachHaptics.selection() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProduct() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { nameFocused = true } }
        }
    }

    private func saveProduct() {
        guard canSave else { return }
        product.name = trimmedName
        product.category = category
        product.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        product.isActive = isActive
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
