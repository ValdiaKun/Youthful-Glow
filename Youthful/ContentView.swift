
import SwiftUI
import SwiftData
import UserNotifications
import PhotosUI

// MARK: - Theme

enum PremiumTheme {
    static let ink = Color(red: 0.10, green: 0.11, blue: 0.12)
    static let cream = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let warm = Color(red: 0.72, green: 0.62, blue: 0.50)
    static let sage = Color(red: 0.43, green: 0.49, blue: 0.43)
    static let muted = Color(red: 0.42, green: 0.41, blue: 0.39)
    static let card = Color.white.opacity(0.72)
}

struct PremiumBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: PremiumTheme.cream, location: 0),
                .init(color: Color.white, location: 0.55),
                .init(color: PremiumTheme.cream.opacity(0.65), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct CapsuleLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(PremiumTheme.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.055))
            .clipShape(Capsule())
    }
}

struct PremiumCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.76))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.9), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }
}

// MARK: - App

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "circle.hexagongrid.fill") }
            ProgressDashboard().tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
            PhotosView().tabItem { Label("Photos", systemImage: "person.crop.rectangle.stack") }
            ProductsView().tabItem { Label("Routine", systemImage: "drop.circle") }
            SettingsView().tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .tint(PremiumTheme.ink)
    }
}

// MARK: - Today

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var logs: [DailyLog]

    private var log: DailyLog {
        let d = Calendar.current.startOfDay(for: .now)
        if let x = logs.first(where: { $0.date == d }) { return x }
        let x = DailyLog(date: d)
        context.insert(x)
        try? context.save()
        return x
    }

    private var completed: Int { log.completedIDs.count }
    private var total: Int { RoutineCatalog.all.count }
    private var pct: Double { Double(completed) / Double(total) }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        topBar
                        hero
                        dailyMetrics
                        routineSection(title: "Morning ritual", subtitle: "Protect • hydrate • present", items: RoutineCatalog.morning)
                        routineSection(title: "Evening ritual", subtitle: "Reset • repair • recover", items: RoutineCatalog.evening)
                        lifestyle
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var topBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUTHFUL")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(3)
                Text("Your daily ritual")
                    .font(.system(size: 25, weight: .semibold, design: .serif))
            }
            Spacer()
            CapsuleLabel(text: Date.now.formatted(.dateTime.month(.abbreviated).day()))
        }
    }

    private var hero: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("CONSISTENCY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(PremiumTheme.muted)
                        Text("Look after\nwhat you have.")
                            .font(.system(size: 31, weight: .semibold, design: .serif))
                            .foregroundStyle(PremiumTheme.ink)
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.black.opacity(0.07), lineWidth: 9)
                        Circle()
                            .trim(from: 0, to: pct)
                            .stroke(PremiumTheme.ink, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(Int(pct * 100))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("%")
                                .font(.caption2)
                                .foregroundStyle(PremiumTheme.muted)
                        }
                    }
                    .frame(width: 78, height: 78)
                }

                HStack {
                    Text("\(completed) of \(total) rituals complete")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: pct == 1 ? "checkmark.seal.fill" : "sparkles")
                        .foregroundStyle(PremiumTheme.warm)
                }
                ProgressView(value: pct)
                    .tint(PremiumTheme.ink)
            }
        }
    }

    private var dailyMetrics: some View {
        HStack(spacing: 12) {
            MetricTile(icon: "bed.double.fill", title: "Sleep", value: log.sleepHours == 0 ? "—" : String(format: "%.1f", log.sleepHours) + "h") {
                log.sleepHours = log.sleepHours >= 9 ? 0 : min(9, log.sleepHours + 1)
                try? context.save()
            }
            MetricTile(icon: "drop.fill", title: "Water", value: "\(log.waterGlasses)/\(AppGoals.waterTarget)") {
                log.waterGlasses = (log.waterGlasses + 1) % 8
                try? context.save()
            }
        }
    }

    private func routineSection(title: String, subtitle: String, items: [RoutineItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 21, weight: .semibold, design: .serif))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.muted)
                }
                Spacer()
                CapsuleLabel(text: "\(items.filter { log.isCompleted($0.id) }.count)/\(items.count)")
            }

            PremiumCard {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button {
                            log.toggle(item.id)
                            try? context.save()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 15, weight: .medium))
                                    .frame(width: 40, height: 40)
                                    .background(PremiumTheme.cream)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(PremiumTheme.muted)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: log.isCompleted(item.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(log.isCompleted(item.id) ? PremiumTheme.ink : .secondary)
                            }
                            .padding(.vertical, 11)
                        }
                        .buttonStyle(.plain)

                        if index < items.count - 1 {
                            Divider().opacity(0.5)
                        }
                    }
                }
            }
        }
    }

    private var lifestyle: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The foundation")
                .font(.system(size: 21, weight: .semibold, design: .serif))

            PremiumCard {
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .frame(width: 40, height: 40)
                            .background(PremiumTheme.cream)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Movement")
                                .font(.subheadline.weight(.semibold))
                            Text("Aim for 3–4 strength sessions/week.")
                                .font(.caption)
                                .foregroundStyle(PremiumTheme.muted)
                        }
                        Spacer()
                        Button {
                            log.workoutDone.toggle()
                            try? context.save()
                        } label: {
                            Image(systemName: log.workoutDone ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .frame(width: 40, height: 40)
                            .background(PremiumTheme.cream)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sleep")
                                .font(.subheadline.weight(.semibold))
                            Text("Target 7–9 hours, consistently.")
                                .font(.caption)
                                .foregroundStyle(PremiumTheme.muted)
                        }
                        Spacer()
                        Text("7–9 h")
                            .font(.caption.weight(.bold))
                    }
                }
            }
        }
    }
}

struct MetricTile: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 9) {
                    Image(systemName: icon)
                        .foregroundStyle(PremiumTheme.warm)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.muted)
                    Text(value)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress

struct ProgressDashboard: View {
    @Query private var logs: [DailyLog]

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Progress")
                            .font(.system(size: 35, weight: .semibold, design: .serif))
                        Text("A quiet record of consistency.")
                            .foregroundStyle(PremiumTheme.muted)

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Last 14 days")
                                    .font(.headline)
                                ForEach(0..<14, id: \.self) { offset in
                                    let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now)!
                                    let start = Calendar.current.startOfDay(for: date)
                                    let count = logs.first(where: { $0.date == start })?.completedIDs.count ?? 0
                                    HStack(spacing: 10) {
                                        Text(date.formatted(.dateTime.weekday(.narrow)))
                                            .font(.caption.weight(.bold))
                                            .frame(width: 18)
                                        ProgressView(value: Double(count) / Double(RoutineCatalog.all.count))
                                            .tint(PremiumTheme.ink)
                                        Text("\(count)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(PremiumTheme.muted)
                                            .frame(width: 18)
                                    }
                                }
                            }
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 8) {
                                CapsuleLabel(text: "Mindset")
                                Text("Consistency beats intensity.")
                                    .font(.system(size: 25, weight: .semibold, design: .serif))
                                Text("The app tracks habits you can control. It doesn't assign a beauty score.")
                                    .font(.subheadline)
                                    .foregroundStyle(PremiumTheme.muted)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Photos

struct PhotosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @State private var picker: PhotosPickerItem?
    @State private var label = "Front"
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Progress photos")
                            .font(.system(size: 35, weight: .semibold, design: .serif))
                        Text("One set per month. Same distance, lighting and expression.")
                            .font(.subheadline)
                            .foregroundStyle(PremiumTheme.muted)

                        Picker("Angle", selection: $label) {
                            Text("Front").tag("Front")
                            Text("Left").tag("Left")
                            Text("Right").tag("Right")
                        }
                        .pickerStyle(.segmented)

                        Button {
                            showPicker = true
                        } label: {
                            Label("Add a progress photo", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(PremiumTheme.ink)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        ForEach(photos) { photo in
                            if let ui = UIImage(data: photo.imageData) {
                                PremiumCard {
                                    VStack(alignment: .leading, spacing: 9) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                        HStack {
                                            Text(photo.label)
                                                .font(.headline)
                                            Spacer()
                                            Text(photo.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                                .font(.caption)
                                                .foregroundStyle(PremiumTheme.muted)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .photosPicker(isPresented: $showPicker, selection: $picker, matching: .images)
            .onChange(of: picker) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        context.insert(ProgressPhoto(label: label, imageData: data))
                        try? context.save()
                        picker = nil
                    }
                }
            }
        }
    }
}

// MARK: - Routine / Products

struct ProductsView: View {
    @Environment(\.modelContext) private var context
    @Query private var products: [Product]
    @State private var showAdd = false
    @State private var name = ""
    @State private var category = "SPF"

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                List {
                    Section {
                        if products.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your essentials")
                                    .font(.system(size: 24, weight: .semibold, design: .serif))
                                Text("Keep the routine simple: cleanser, moisturizer, SPF and retinoid.")
                                    .foregroundStyle(PremiumTheme.muted)
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(products) { product in
                                HStack(spacing: 12) {
                                    Image(systemName: "drop.circle.fill")
                                        .foregroundStyle(PremiumTheme.warm)
                                    VStack(alignment: .leading) {
                                        Text(product.name).font(.subheadline.weight(.semibold))
                                        Text(product.category).font(.caption).foregroundStyle(PremiumTheme.muted)
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.65))
                            }
                            .onDelete { offsets in
                                offsets.map { products[$0] }.forEach(context.delete)
                                try? context.save()
                            }
                        }
                    }
                    Section {
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add product", systemImage: "plus")
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(Color.white.opacity(0.65))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Routine")
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    Form {
                        TextField("Product name", text: $name)
                        Picker("Category", selection: $category) {
                            Text("Cleanser").tag("Cleanser")
                            Text("Moisturizer").tag("Moisturizer")
                            Text("SPF").tag("SPF")
                            Text("Retinol").tag("Retinol")
                            Text("Other").tag("Other")
                        }
                    }
                    .navigationTitle("New product")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAdd = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let trimmed = name.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                context.insert(Product(name: trimmed, category: category))
                                try? context.save()
                                name = ""
                                showAdd = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("reminders") private var reminders = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your plan") {
                    LabeledContent("Hair", value: "Textured low taper")
                    LabeledContent("Facial hair", value: "Clean-shaven / 1–2 mm")
                    LabeledContent("SPF", value: "50 every morning")
                    LabeledContent("Retinol", value: "Start 2× / week")
                    LabeledContent("Exercise", value: "3–4× / week")
                    LabeledContent("Sleep", value: "7–9 hours")
                }
                Section("Reminders") {
                    Toggle("Morning & evening", isOn: $reminders)
                        .onChange(of: reminders) { _, enabled in
                            Task {
                                if enabled {
                                    await NotificationManager.shared.enable()
                                } else {
                                    NotificationManager.shared.disable()
                                }
                            }
                        }
                }
                Section("Design") {
                    Text("Quiet, editorial, minimal. The app is designed to feel like a personal ritual rather than a health dashboard.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("More")
        }
    }
}
