import SwiftUI
import SwiftData
import UserNotifications
import PhotosUI

// MARK: - V2 feature models

@Model
final class ProductIntelligence {
    var productName: String
    var openedAt: Date?
    var estimatedDays: Int
    var expirationDate: Date?
    var note: String
    var usageDays: Int

    init(productName: String, openedAt: Date? = nil, estimatedDays: Int = 90, expirationDate: Date? = nil, note: String = "", usageDays: Int = 0) {
        self.productName = productName
        self.openedAt = openedAt
        self.estimatedDays = estimatedDays
        self.expirationDate = expirationDate
        self.note = note
        self.usageDays = usageDays
    }

    var estimatedRunOut: Date? {
        guard let openedAt else { return nil }
        return Calendar.current.date(byAdding: .day, value: max(1, estimatedDays), to: openedAt)
    }

    var isLow: Bool {
        guard let openedAt, let runOut = estimatedRunOut else { return false }
        let total = max(1, estimatedDays)
        let remaining = Calendar.current.dateComponents([.day], from: .now, to: runOut).day ?? total
        return remaining <= max(7, total / 5)
    }
}

@Model
final class SmartReminder {
    var id: String
    var title: String
    var detail: String
    var hour: Int
    var minute: Int
    var enabled: Bool
    var repeatDaily: Bool

    init(title: String, detail: String, hour: Int, minute: Int, enabled: Bool = true, repeatDaily: Bool = true) {
        self.id = UUID().uuidString
        self.title = title
        self.detail = detail
        self.hour = hour
        self.minute = minute
        self.enabled = enabled
        self.repeatDaily = repeatDaily
    }
}

@Model
final class PhotoNote {
    var photoDate: Date
    var text: String
    init(photoDate: Date, text: String = "") {
        self.photoDate = photoDate
        self.text = text
    }
}

// MARK: - Smart routine engine

enum RoutineEngine {
    static let order = ["cleanser", "toner", "serum", "retinol", "treatment", "moisturizer", "spf", "hair", "beard", "other"]

    static func rank(_ product: Product) -> Int {
        let text = (product.name + " " + product.category).lowercased()
        if text.contains("cleanser") || text.contains("wash") { return 0 }
        if text.contains("toner") || text.contains("essence") { return 1 }
        if text.contains("serum") { return 2 }
        if text.contains("retinol") || text.contains("retinal") || text.contains("tretinoin") || text.contains("adapalene") { return 3 }
        if text.contains("acid") || text.contains("aha") || text.contains("bha") || text.contains("treatment") { return 4 }
        if text.contains("moistur") || text.contains("cream") || text.contains("lotion") { return 5 }
        if text.contains("spf") || text.contains("sunscreen") || text.contains("sunblock") { return 6 }
        if text.contains("hair") { return 7 }
        if text.contains("beard") { return 8 }
        return 9
    }

    static func ordered(_ products: [Product], night: Bool) -> [Product] {
        products.filter(\.isActive).filter { product in
            let text = (product.name + " " + product.category).lowercased()
            if night { return !(text.contains("spf") || text.contains("sunscreen") || text.contains("sunblock")) }
            return true
        }.sorted { a, b in
            let ar = rank(a), br = rank(b)
            return ar == br ? a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending : ar < br
        }
    }

    static func missingSteps(_ products: [Product], night: Bool) -> [String] {
        let names = products.filter(\.isActive).map { $0.name.lowercased() }
        var missing: [String] = []
        let hasCleanser = names.contains { $0.contains("cleanser") || $0.contains("wash") }
        let hasMoist = names.contains { $0.contains("moistur") || $0.contains("cream") || $0.contains("lotion") }
        if !hasCleanser { missing.append("gentle cleanser") }
        if !hasMoist { missing.append("moisturizer") }
        if !night && !names.contains(where: { $0.contains("spf") || $0.contains("sunscreen") || $0.contains("sunblock") }) { missing.append("daily SPF") }
        return missing
    }

    static func overlapWarnings(_ products: [Product]) -> [String] {
        let activeNames = products.filter(\.isActive).map { $0.name.lowercased() }
        let acids = activeNames.filter { $0.contains("aha") || $0.contains("bha") || $0.contains("glycolic") || $0.contains("lactic") || $0.contains("salicylic") || $0.contains("acid") }.count
        let retinoids = activeNames.filter { $0.contains("retinol") || $0.contains("retinal") || $0.contains("tretinoin") || $0.contains("adapalene") }.count
        var warnings: [String] = []
        if acids > 1 { warnings.append("Several exfoliating/acid products are active. Avoid stacking them unless you already know your skin tolerates the combination.") }
        if acids > 0 && retinoids > 0 { warnings.append("You have both an active exfoliant and a retinoid. Consider alternating nights if irritation occurs.") }
        return warnings
    }

    static func recommendation(_ products: [Product], night: Bool) -> String {
        let missing = missingSteps(products, night: night)
        if let first = missing.first { return "Your routine is missing \(first). Consider adding this step before increasing complexity." }
        let warnings = overlapWarnings(products)
        if !warnings.isEmpty { return "You have several potentially active products. Keep tonight simple and prioritize comfort." }
        return night ? "Your evening routine has the basics covered. Apply products from lightest to heaviest and keep active nights consistent." : "Your morning routine is in good shape. Finish with broad-spectrum SPF before going outdoors."
    }
}

// MARK: - Streak helpers

struct RoutineStats {
    static func completedDays(logs: [DailyLog], calendar: Calendar = .current) -> Int {
        logs.filter { $0.completedIDs.count >= RoutineCatalog.all.count }.count
    }

    static func streak(logs: [DailyLog], calendar: Calendar = .current) -> Int {
        let completed = Set(logs.filter { $0.completedIDs.count >= RoutineCatalog.all.count }.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: .now)
        var count = 0
        if !completed.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day) ?? day }
        while completed.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    static func weekCompleted(logs: [DailyLog], calendar: Calendar = .current) -> Int {
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return logs.filter { $0.date >= start && $0.completedIDs.count >= RoutineCatalog.all.count }.count
    }
}

// MARK: - Feature hub

struct SmartFeaturesView: View {
    @Query private var products: [Product]
    @Query private var logs: [DailyLog]
    @Query(sort: \ProductIntelligence.productName) private var intelligence: [ProductIntelligence]
    @Query(sort: \SmartReminder.hour) private var reminders: [SmartReminder]
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]

    var body: some View {
        NavigationStack {
            ZStack { PremiumBackground(); ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    recommendation
                    streakCard
                    routinePreview
                    productHealth
                    remindersCard
                    photoPreview
                }.padding(20).padding(.bottom, 34)
            }}.toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            CapsuleLabel(text: "My progress")
            Text("Your Glow dashboard").font(.system(size: 34, weight: .semibold, design: .serif))
            Text("A single place for consistency, products and progress.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
        }
    }

    private var recommendation: some View {
        PremiumCard { VStack(alignment: .leading, spacing: 12) {
            HStack { Image(systemName: "sparkles").foregroundStyle(PremiumTheme.warm); Text("Tonight's recommendation").font(.headline); Spacer() }
            Text(RoutineEngine.recommendation(products, night: true)).font(.subheadline).foregroundStyle(PremiumTheme.muted)
            let warnings = RoutineEngine.overlapWarnings(products)
            if let warning = warnings.first { Label(warning, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.orange) }
        }}
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            stat("flame.fill", "Streak", "\(RoutineStats.streak(logs: logs)) days")
            stat("calendar", "This week", "\(RoutineStats.weekCompleted(logs: logs))/7")
            stat("checkmark.circle", "All time", "\(RoutineStats.completedDays(logs: logs)) days")
        }
    }

    private func stat(_ icon: String, _ title: String, _ value: String) -> some View {
        PremiumCard { VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(PremiumTheme.warm); Text(title).font(.caption).foregroundStyle(PremiumTheme.muted); Text(value).font(.system(size: 18, weight: .bold, design: .rounded)) }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private var routinePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Smart routine", subtitle: "Products ordered by application sequence")
            PremiumCard { VStack(alignment: .leading, spacing: 9) {
                routineLine("Morning", products: RoutineEngine.ordered(products, night: false))
                Divider()
                routineLine("Night", products: RoutineEngine.ordered(products, night: true))
                let missing = RoutineEngine.missingSteps(products, night: false)
                if !missing.isEmpty { Label("Missing: " + missing.joined(separator: ", "), systemImage: "plus.circle").font(.caption).foregroundStyle(PremiumTheme.muted) }
            }}
        }
    }

    private func routineLine(_ title: String, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline.weight(.bold))
            if products.isEmpty { Text("No active products yet").font(.caption).foregroundStyle(PremiumTheme.muted) }
            else { Text(products.map(\.name).joined(separator: " → ")).font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(3) }
        }
    }

    private var productHealth: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Product health", subtitle: "Opened, running low and expiring soon")
            if intelligence.isEmpty { PremiumCard { Text("Open a product from the Routine tab and add its estimated lifespan to start tracking run-out dates.").font(.subheadline).foregroundStyle(PremiumTheme.muted) } }
            else { ForEach(intelligence) { item in PremiumCard { HStack { VStack(alignment: .leading, spacing: 5) { Text(item.productName).font(.subheadline.weight(.semibold)); if let date = item.estimatedRunOut { Text("Estimated run-out: \(date.formatted(.dateTime.month(.abbreviated).day()))").font(.caption).foregroundStyle(PremiumTheme.muted) } }; Spacer(); if item.isLow { Text("LOW").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.orange).padding(.horizontal, 8).padding(.vertical, 5).background(Color.orange.opacity(0.12)).clipShape(Capsule()) } } } } }
        }
    }

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Reminders", subtitle: "\(reminders.filter(\.enabled).count) active")
            PremiumCard { VStack(alignment: .leading, spacing: 10) { if reminders.isEmpty { Text("Set morning, evening or custom reminders from the Reminders button below.").font(.subheadline).foregroundStyle(PremiumTheme.muted) } else { ForEach(reminders) { reminder in HStack { Image(systemName: reminder.enabled ? "bell.fill" : "bell.slash").foregroundStyle(PremiumTheme.warm); Text(reminder.title).font(.subheadline.weight(.semibold)); Spacer(); Text(String(format: "%02d:%02d", reminder.hour, reminder.minute)).font(.caption.weight(.bold)) } } } } }
        }
    }

    private var photoPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Progress photos", subtitle: "\(photos.count) saved")
            if photos.count >= 2 {
                PremiumCard { HStack(spacing: 10) { photoThumb(photos[1]); photoThumb(photos[0]) } }
            } else { PremiumCard { Text("Save two or more dated photos to compare your progress side-by-side.").font(.subheadline).foregroundStyle(PremiumTheme.muted) } }
        }
    }

    private func photoThumb(_ photo: ProgressPhoto) -> some View {
        Group { if let image = UIImage(data: photo.imageData) { Image(uiImage: image).resizable().scaledToFill() } else { Color.black.opacity(0.05) } }
            .frame(maxWidth: .infinity).frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .bottomLeading) { Text(photo.date.formatted(.dateTime.month(.abbreviated).day().year())).font(.caption2.weight(.bold)).padding(7).background(.ultraThinMaterial).clipShape(Capsule()).padding(8) }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View { VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 21, weight: .semibold, design: .serif)); Text(subtitle).font(.caption).foregroundStyle(PremiumTheme.muted) } }
}

// MARK: - Product intelligence editor

struct ProductIntelligenceView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \ProductIntelligence.productName) private var records: [ProductIntelligence]
    @State private var selectedProduct: Product?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack { ZStack { PremiumBackground(); ScrollView(showsIndicators: false) { VStack(alignment: .leading, spacing: 16) {
            Text("Product intelligence").font(.system(size: 34, weight: .semibold, design: .serif))
            Text("Track opening dates, run-out estimates, expiration and how each product behaves for you.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
            ForEach(products) { product in
                let record = records.first(where: { $0.productName == product.name })
                PremiumCard { HStack { VStack(alignment: .leading, spacing: 5) { Text(product.name).font(.subheadline.weight(.semibold)); Text(record?.note.isEmpty == false ? record!.note : "No tracking details yet").font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(2) }; Spacer(); Button(record == nil ? "Track" : "Edit") { selectedProduct = product; showingEditor = true }.font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.ink) } }
            }
        }.padding(20).padding(.bottom, 30) }}.toolbar(.hidden, for: .navigationBar) }
        .sheet(isPresented: $showingEditor) { if let selectedProduct { ProductIntelligenceEditor(product: selectedProduct) } }
    }
}

struct ProductIntelligenceEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var records: [ProductIntelligence]
    let product: Product
    @State private var opened = Date.now
    @State private var estimatedDays = 90
    @State private var expiration = Date.now
    @State private var hasExpiration = false
    @State private var note = ""

    var body: some View {
        NavigationStack { Form {
            Section("Usage") { Toggle("Product has been opened", isOn: Binding(get: { true }, set: { _ in })); DatePicker("Opened", selection: $opened, displayedComponents: .date); Stepper("Estimated lifespan: \(estimatedDays) days", value: $estimatedDays, in: 7...730, step: 7) }
            Section("Expiration") { Toggle("Track expiration date", isOn: $hasExpiration); if hasExpiration { DatePicker("Expires", selection: $expiration, displayedComponents: .date) } }
            Section("Experience note") { TextField("Works well, caused irritation, etc.", text: $note, axis: .vertical).lineLimit(3...6) }
            Button("Save product tracking") { save() }.fontWeight(.semibold)
        }.navigationTitle(product.name).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }.onAppear { if let existing = records.first(where: { $0.productName == product.name }) { opened = existing.openedAt ?? .now; estimatedDays = existing.estimatedDays; expiration = existing.expirationDate ?? .now; hasExpiration = existing.expirationDate != nil; note = existing.note } } }
    }

    private func save() {
        let existing = records.first(where: { $0.productName == product.name })
        let record = existing ?? ProductIntelligence(productName: product.name)
        if existing == nil { context.insert(record) }
        record.openedAt = opened
        record.estimatedDays = estimatedDays
        record.expirationDate = hasExpiration ? expiration : nil
        record.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        dismiss()
    }
}

// MARK: - Reminders

struct SmartRemindersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SmartReminder.hour) private var reminders: [SmartReminder]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack { ZStack { PremiumBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
            Text("Smart reminders").font(.system(size: 34, weight: .semibold, design: .serif))
            Text("Morning, evening and custom times. You can disable any reminder without deleting it.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
            Button { showingAdd = true } label: { Label("Add reminder", systemImage: "plus.circle.fill").frame(maxWidth: .infinity).padding(15).background(PremiumTheme.ink).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain)
            ForEach(reminders) { reminder in PremiumCard { HStack { VStack(alignment: .leading, spacing: 4) { Text(reminder.title).font(.subheadline.weight(.semibold)); Text(String(format: "%02d:%02d", reminder.hour, reminder.minute)).font(.caption).foregroundStyle(PremiumTheme.muted) }; Spacer(); Toggle("", isOn: Binding(get: { reminder.enabled }, set: { value in reminder.enabled = value; ReminderScheduler.schedule(reminder); try? context.save() })).labelsHidden() } } }
        }.padding(20) }}.toolbar(.hidden, for: .navigationBar) }
        .sheet(isPresented: $showingAdd) { AddSmartReminderView() }
    }
}

struct AddSmartReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = "Morning routine"
    @State private var detail = "Time for your morning routine."
    @State private var time = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? .now
    @State private var enabled = true

    var body: some View { NavigationStack { Form { Section("Reminder") { TextField("Title", text: $title); TextField("Message", text: $detail, axis: .vertical); DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute); Toggle("Enabled", isOn: $enabled) }; Button("Save") { save() }.fontWeight(.semibold) }.navigationTitle("New reminder").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } } } }

    private func save() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        let reminder = SmartReminder(title: title.trimmingCharacters(in: .whitespacesAndNewlines), detail: detail, hour: c.hour ?? 8, minute: c.minute ?? 0, enabled: enabled)
        context.insert(reminder); try? context.save()
        Task { await ReminderScheduler.requestPermission(); ReminderScheduler.schedule(reminder) }
        dismiss()
    }
}

enum ReminderScheduler {
    static func requestPermission() async { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
    static func schedule(_ reminder: SmartReminder) {
        let center = UNUserNotificationCenter.current(); let id = "smart-" + reminder.id
        center.removePendingNotificationRequests(withIdentifiers: [id]); guard reminder.enabled else { return }
        let content = UNMutableNotificationContent(); content.title = "Youthful • \(reminder.title)"; content.body = reminder.detail; content.sound = .default
        var c = DateComponents(); c.hour = reminder.hour; c.minute = reminder.minute
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: c, repeats: reminder.repeatDaily)))
    }
}

// MARK: - Photo comparison

struct PhotoComparisonView: View {
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @State private var leftIndex = 1
    @State private var rightIndex = 0

    var body: some View { NavigationStack { ZStack { PremiumBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
        Text("Compare progress").font(.system(size: 34, weight: .semibold, design: .serif))
        Text("Choose any two saved dates and view them side-by-side.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
        if photos.count >= 2 {
            Picker("Earlier", selection: $leftIndex) { ForEach(0..<photos.count, id: \.self) { i in Text(photos[i].date.formatted(.dateTime.month(.abbreviated).day().year())).tag(i) } }.pickerStyle(.menu)
            Picker("Later", selection: $rightIndex) { ForEach(0..<photos.count, id: \.self) { i in Text(photos[i].date.formatted(.dateTime.month(.abbreviated).day().year())).tag(i) } }.pickerStyle(.menu)
            HStack(alignment: .top, spacing: 10) { comparisonImage(photos[min(leftIndex, photos.count - 1)]); comparisonImage(photos[min(rightIndex, photos.count - 1)]) }
        } else { PremiumCard { Text("Add at least two progress photos to unlock comparison.").font(.subheadline).foregroundStyle(PremiumTheme.muted) } }
    }.padding(20) }}.toolbar(.hidden, for: .navigationBar) } }

    private func comparisonImage(_ photo: ProgressPhoto) -> some View { VStack(alignment: .leading, spacing: 6) { if let image = UIImage(data: photo.imageData) { Image(uiImage: image).resizable().scaledToFill().frame(maxWidth: .infinity).frame(height: 250).clipped().clipShape(RoundedRectangle(cornerRadius: 18)) }; Text(photo.date.formatted(.dateTime.month(.abbreviated).day().year())).font(.caption.weight(.bold)) } }
}
