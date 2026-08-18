import SwiftUI
import SwiftData

// MARK: - Routine streaks

struct RoutineStreaksLauncher: View {
    @State private var showingStreaks = false

    var body: some View {
        Button {
            CoachHaptics.selection()
            showingStreaks = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Streak")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(PremiumTheme.ink)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.leading, 18)
        .padding(.bottom, 72)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .sheet(isPresented: $showingStreaks) {
            RoutineStreaksView()
        }
    }
}

struct RoutineStreaksView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]

    private var completedDates: Set<Date> {
        let calendar = Calendar.current
        return Set(logs.compactMap { log in
            guard !log.completedIDs.isEmpty else { return nil }
            return calendar.startOfDay(for: log.date)
        })
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)

        // If today has not started yet, allow the streak to continue from yesterday.
        if !completedDates.contains(day),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
           completedDates.contains(yesterday) {
            day = yesterday
        }

        guard completedDates.contains(day) else { return 0 }

        var streak = 0
        while completedDates.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private var bestStreak: Int {
        let calendar = Calendar.current
        let dates = completedDates.sorted()
        guard !dates.isEmpty else { return 0 }

        var best = 1
        var running = 1
        for index in 1..<dates.count {
            if calendar.dateComponents([.day], from: dates[index - 1], to: dates[index]).day == 1 {
                running += 1
                best = max(best, running)
            } else {
                running = 1
            }
        }
        return best
    }

    private var recentDays: [(Date, Bool)] {
        let calendar = Calendar.current
        return (0..<14).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let day = calendar.startOfDay(for: date)
            return (day, completedDates.contains(day))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            CapsuleLabel(text: "Consistency")
                            Text("Routine streak").font(.system(size: 32, weight: .semibold, design: .serif))
                            Text("A streak day means you completed at least one routine step. Small wins count.")
                                .font(.subheadline)
                                .foregroundStyle(PremiumTheme.muted)
                        }

                        PremiumCard {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(PremiumTheme.cream)
                                        .frame(width: 82, height: 82)
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 31, weight: .semibold))
                                        .foregroundStyle(PremiumTheme.warm)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CURRENT STREAK")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .tracking(1.8)
                                        .foregroundStyle(PremiumTheme.muted)
                                    Text("\(currentStreak) \(currentStreak == 1 ? "day" : "days")")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                    Text(currentStreak == 0 ? "Start today with one ritual." : "Keep the rhythm going.")
                                        .font(.caption)
                                        .foregroundStyle(PremiumTheme.muted)
                                }
                                Spacer(minLength: 0)
                            }
                        }

                        HStack(spacing: 12) {
                            streakStat(title: "Best", value: "\(bestStreak)", icon: "trophy.fill")
                            streakStat(title: "Active days", value: "\(completedDates.count)", icon: "checkmark.circle.fill")
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Last 14 days").font(.headline)
                                    Spacer()
                                    Text("\(recentDays.filter(\.1).count)/14")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(PremiumTheme.muted)
                                }

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 7), spacing: 10) {
                                    ForEach(recentDays.reversed(), id: \.0) { item in
                                        VStack(spacing: 5) {
                                            Text(item.0.formatted(.dateTime.weekday(.narrow)))
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                .foregroundStyle(PremiumTheme.muted)
                                            Circle()
                                                .fill(item.1 ? PremiumTheme.ink : Color.black.opacity(0.07))
                                                .frame(width: 25, height: 25)
                                                .overlay {
                                                    if item.1 {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KEEP IT SIMPLE")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .tracking(1.8)
                                    .foregroundStyle(PremiumTheme.muted)
                                Text("Never miss twice.")
                                    .font(.system(size: 24, weight: .semibold, design: .serif))
                                Text("If you miss a day, restart the next day. The goal is a sustainable ritual, not perfection.")
                                    .font(.subheadline)
                                    .foregroundStyle(PremiumTheme.muted)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func streakStat(title: String, value: String, icon: String) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(PremiumTheme.warm)
                Text(title).font(.caption).foregroundStyle(PremiumTheme.muted)
                Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
