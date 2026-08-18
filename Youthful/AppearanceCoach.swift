import SwiftUI
import UIKit

// MARK: - V1.4 Appearance Coach

struct AppearanceCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal = "Overall"
    @State private var favorites: Set<String> = []

    private let goals = ["Overall", "Skin", "Hair", "Beard", "Grooming"]

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        goalPicker
                        recommendations
                        hairSection
                        beardSection
                        skinSection
                        groomingSection
                    }
                    .padding(20)
                    .padding(.bottom, 36)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("APPEARANCE COACH")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(PremiumTheme.muted)
                Text("Improve your look\nwith intention.")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
            }
            Spacer()
            Button {
                CoachHaptics.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.75))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var goalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What do you want to improve?")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(goals, id: \.self) { goal in
                        Button {
                            selectedGoal = goal
                            CoachHaptics.selection()
                        } label: {
                            Text(goal)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .background(selectedGoal == goal ? PremiumTheme.ink : .white.opacity(0.72))
                                .foregroundStyle(selectedGoal == goal ? .white : PremiumTheme.ink)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recommendations: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Label("Your plan", systemImage: "sparkles")
                        .font(.headline)
                    Spacer()
                    Text(selectedGoal)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PremiumTheme.muted)
                }

                coachTip("Protect your skin daily", detail: "Use a broad-spectrum SPF 30+ every morning, especially when spending time outdoors.", icon: "sun.max.fill")
                coachTip("Keep grooming consistent", detail: "Small, repeatable habits usually look better than occasional intensive sessions.", icon: "checkmark.circle.fill")
                coachTip("Choose one style to maintain", detail: "A haircut and beard shape that fit your maintenance preference are easier to keep looking sharp.", icon: "person.crop.square.fill")
            }
        }
    }

    private func coachTip(_ title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 34, height: 34)
                .background(PremiumTheme.cream)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(PremiumTheme.muted)
            }
        }
    }

    private var hairSection: some View {
        coachSection(title: "Hair", subtitle: "Styles worth discussing with your barber", icon: "scissors") {
            ForEach(["Low taper", "Textured crop", "Ivy League", "Classic side part"], id: \.self) { style in
                coachOption(style, detail: hairDetail(style), icon: "scissors")
            }
        }
    }

    private func hairDetail(_ style: String) -> String {
        switch style {
        case "Low taper": return "Clean around the edges while keeping more length through the top."
        case "Textured crop": return "Short, textured top with an easy everyday finish."
        case "Ivy League": return "Neat, versatile length that works dressed up or casual."
        default: return "A classic shape with enough length to style naturally."
        }
    }

    private var beardSection: some View {
        coachSection(title: "Beard", subtitle: "Simple options from clean to fuller", icon: "face.smiling") {
            ForEach(["Clean shave", "Short stubble", "Short boxed beard", "Natural short beard"], id: \.self) { style in
                coachOption(style, detail: beardDetail(style), icon: "face.smiling")
            }
        }
    }

    private func beardDetail(_ style: String) -> String {
        switch style {
        case "Clean shave": return "Crisp, minimal maintenance between shaves."
        case "Short stubble": return "Low-length definition with frequent edge cleanup."
        case "Short boxed beard": return "Defined cheek and neckline with controlled length."
        default: return "Keep the natural shape tidy with regular trimming."
        }
    }

    private var skinSection: some View {
        coachSection(title: "Skin", subtitle: "Choose a goal instead of chasing a skin tone", icon: "drop.fill") {
            coachOption("Brighter, more even-looking", detail: "Prioritize daily sun protection, gentle cleansing and consistent hydration.", icon: "sun.max.fill")
            coachOption("Hydrated", detail: "Use a gentle cleanser and moisturizer; add a hydrating serum if useful for you.", icon: "drop.fill")
            coachOption("Smoother texture", detail: "Keep the routine simple and introduce exfoliating or treatment products gradually.", icon: "wand.and.stars")
            coachOption("Dark-spot care", detail: "Daily SPF is foundational; avoid picking and use gentle, consistent brightening care.", icon: "circle.lefthalf.filled")
        }
    }

    private var groomingSection: some View {
        coachSection(title: "Grooming", subtitle: "Small details that make the whole look feel finished", icon: "sparkles") {
            coachOption("Brows", detail: "Keep the natural shape and remove only obvious stray hairs.", icon: "eye")
            coachOption("Lips", detail: "Use a simple moisturizing lip balm when dry.", icon: "mouth")
            coachOption("Nails", detail: "Keep nails clean, trimmed and even.", icon: "hand.raised")
            coachOption("Fragrance", detail: "A small amount applied to pulse points is usually enough.", icon: "wind")
        }
    }

    private func coachSection<Content: View>(title: String, subtitle: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 21, weight: .semibold, design: .serif))
                    Text(subtitle).font(.caption).foregroundStyle(PremiumTheme.muted)
                }
                Spacer()
                Image(systemName: icon).foregroundStyle(PremiumTheme.warm)
            }
            PremiumCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    private func coachOption(_ title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 38, height: 38)
                .background(PremiumTheme.cream)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(PremiumTheme.muted)
            }
            Spacer(minLength: 6)
            Button {
                if favorites.contains(title) { favorites.remove(title) } else { favorites.insert(title) }
                CoachHaptics.selection()
            } label: {
                Image(systemName: favorites.contains(title) ? "heart.fill" : "heart")
                    .foregroundStyle(favorites.contains(title) ? PremiumTheme.warm : .secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

struct AppearanceCoachEntryModifier: ViewModifier {
    @State private var showingCoach = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                Button {
                    CoachHaptics.impact()
                    showingCoach = true
                } label: {
                    Label("Coach", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 11)
                        .background(PremiumTheme.ink)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.16), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.bottom, 78)
            }
            .sheet(isPresented: $showingCoach) {
                AppearanceCoachView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func appearanceCoachEntry() -> some View {
        modifier(AppearanceCoachEntryModifier())
    }
}
