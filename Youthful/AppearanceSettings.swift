import SwiftUI

// MARK: - Global appearance

enum YouthfulAppearance: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case amoled = "AMOLED"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .amoled: return "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark, .amoled: return .dark
        }
    }
}

struct AppearanceStore {
    static let key = "youthfulAppearance"
    static var current: YouthfulAppearance {
        YouthfulAppearance(rawValue: UserDefaults.standard.string(forKey: key) ?? "Light") ?? .light
    }
    static func save(_ value: YouthfulAppearance) {
        UserDefaults.standard.set(value.rawValue, forKey: key)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage(AppearanceStore.key) private var appearanceRaw = YouthfulAppearance.light.rawValue

    private var appearance: Binding<YouthfulAppearance> {
        Binding(
            get: { YouthfulAppearance(rawValue: appearanceRaw) ?? .light },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppearanceBackground(mode: appearance.wrappedValue)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Appearance")
                                .font(.system(size: 34, weight: .semibold, design: .serif))
                            Text("Choose the look that feels best throughout Youthful Glow.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 10) {
                            ForEach(YouthfulAppearance.allCases) { mode in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        appearance.wrappedValue = mode
                                    }
                                    CoachHaptics.selection()
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 17, weight: .semibold))
                                            .frame(width: 42, height: 42)
                                            .background(mode == .amoled ? Color.black : Color.primary.opacity(0.08))
                                            .foregroundStyle(mode == .amoled ? Color.white : Color.primary)
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(mode.rawValue)
                                                .font(.headline)
                                            Text(description(for: mode))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: appearance.wrappedValue == mode ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(appearance.wrappedValue == mode ? Color.accentColor : Color.secondary)
                                    }
                                    .padding(14)
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(appearance.wrappedValue.colorScheme)
    }

    private func description(for mode: YouthfulAppearance) -> String {
        switch mode {
        case .light: return "Bright, warm and airy."
        case .dark: return "Dark surfaces with softer contrast."
        case .amoled: return "Pure black surfaces for OLED displays."
        }
    }
}

struct AppearanceBackground: View {
    let mode: YouthfulAppearance
    var body: some View {
        Group {
            if mode == .amoled {
                Color.black
            } else if mode == .dark {
                Color(uiColor: UIColor { _ in UIColor(white: 0.045, alpha: 1) })
            } else {
                LinearGradient(stops: [
                    .init(color: Color(red: 0.96, green: 0.95, blue: 0.92), location: 0),
                    .init(color: .white, location: 0.55),
                    .init(color: Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.65), location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .ignoresSafeArea()
    }
}
