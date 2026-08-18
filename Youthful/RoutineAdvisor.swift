import SwiftUI
import SwiftData

// MARK: - Smart routine guidance

struct RoutineAdvisor {
    static func recommendations(for products: [Product]) -> [RoutineRecommendation] {
        let active = products.filter(\.isActive)
        let names = active.map { $0.name.lowercased() }
        let categories = active.map { $0.category.lowercased() }
        var result: [RoutineRecommendation] = []

        let hasSPF = names.contains { $0.contains("spf") || $0.contains("sunscreen") || $0.contains("sunblock") }
        let hasMoisturizer = names.contains { name in
            name.contains("moistur") || name.contains("cream") || name.contains("lotion")
        }
        let hasCleanser = names.contains { name in
            name.contains("cleanser") || name.contains("face wash") || name.contains("facial wash")
        }
        let hasRetinoid = names.contains { name in
            name.contains("retinol") || name.contains("retinal") || name.contains("tretinoin") || name.contains("adapalene")
        }
        let activeCount = names.filter { name in
            name.contains("retinol") || name.contains("retinal") || name.contains("tretinoin") ||
            name.contains("adapalene") || name.contains("aha") || name.contains("bha") ||
            name.contains("glycolic") || name.contains("lactic") || name.contains("salicylic")
        }.count

        if !hasSPF {
            result.append(.init(
                icon: "sun.max.fill",
                title: "Add daily sun protection",
                detail: "Your library doesn't appear to contain an SPF product. A broad-spectrum sunscreen is the most useful daily protection step."
            ))
        }

        if !hasMoisturizer {
            result.append(.init(
                icon: "humidity.fill",
                title: "Add a moisturizer",
                detail: "A simple moisturizer can help keep the skin barrier comfortable, especially when using active products."
            ))
        }

        if !hasCleanser {
            result.append(.init(
                icon: "drop.fill",
                title: "Add a gentle cleanser",
                detail: "A gentle cleanser gives you a simple way to remove sunscreen, oil and daily buildup without aggressive scrubbing."
            ))
        }

        if activeCount > 1 {
            result.append(.init(
                icon: "exclamationmark.triangle.fill",
                title: "Keep active nights simple",
                detail: "You have several products that may be active treatments. Avoid automatically layering multiple strong actives together; introduce changes gradually and follow each product's directions."
            ))
        } else if hasRetinoid {
            result.append(.init(
                icon: "moon.stars.fill",
                title: "Give your retinoid a simple night",
                detail: "Keep retinoid nights uncomplicated: cleanse, use the treatment as directed, then moisturize if needed."
            ))
        }

        if result.isEmpty {
            result.append(.init(
                icon: "checkmark.seal.fill",
                title: "Your basics look covered",
                detail: "You have a solid-looking product foundation. Focus on consistency rather than adding more products."
            ))
        }

        // Categories are intentionally kept in the calculation so future product types
        // can be added without changing the view's interface.
        _ = categories
        return Array(result.prefix(3))
    }
}

struct RoutineRecommendation: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

struct SmartRoutineCard: View {
    @Query(sort: \\Product.name) private var products: [Product]
    @State private var expanded = false

    private var recommendations: [RoutineRecommendation] {
        RoutineAdvisor.recommendations(for: products)
    }

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(PremiumTheme.cream)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("SMART ROUTINE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(PremiumTheme.muted)
                        Text("A simpler next step")
                            .font(.system(size: 21, weight: .semibold, design: .serif))
                        Text("Based on the products in your library.")
                            .font(.caption)
                            .foregroundStyle(PremiumTheme.muted)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, recommendation in
                        if index > 0 { Divider().opacity(0.5) }
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: recommendation.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PremiumTheme.warm)
                                .frame(width: 24)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(recommendation.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(recommendation.detail)
                                    .font(.caption)
                                    .foregroundStyle(PremiumTheme.muted)
                                    .lineLimit(expanded ? nil : 2)
                            }
                        }
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                    CoachHaptics.selection()
                } label: {
                    Text(expanded ? "Show less" : "Read guidance")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PremiumTheme.ink)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
