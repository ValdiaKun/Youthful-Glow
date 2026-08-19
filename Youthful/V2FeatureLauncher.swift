import SwiftUI

// The old V2FeatureLauncher has been removed. The app now uses the unified
// AssistiveTouch-style launcher in YouthfulApp.swift. This file retains the
// smart-feature destination views used by that unified launcher.

struct V2FeatureMenu: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: SmartFeature?

    enum SmartFeature: String, Identifiable {
        case progress, intelligence, reminders, photos, discovery
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            CapsuleLabel(text: "Youthful 2")
                            Text("Smart tools")
                                .font(.system(size: 34, weight: .semibold, design: .serif))
                            Text("Everything added to make your routine more useful, measurable and personal.")
                                .font(.subheadline)
                                .foregroundStyle(PremiumTheme.muted)
                        }

                        featureButton(.discovery, "Discover Products", "Explore a curated Philippine-market personal-care catalog and add products to your library.", "bag.fill")
                        featureButton(.progress, "My Progress", "Streaks, completion, recommendations and product health.", "chart.xyaxis.line")
                        featureButton(.intelligence, "Product Intelligence", "Opened dates, run-out estimates, expiration and notes.", "drop.circle.fill")
                        featureButton(.reminders, "Smart Reminders", "Morning, evening and custom reminder times.", "bell.badge.fill")
                        featureButton(.photos, "Compare Progress Photos", "Add photos from your library or camera, then compare two dates side-by-side.", "rectangle.split.2x1")
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Smart tools")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        CoachHaptics.selection()
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedFeature) { feature in
            SmartFeatureSheet(feature: feature)
        }
    }

    private func featureButton(_ feature: SmartFeature, _ title: String, _ detail: String, _ icon: String) -> some View {
        Button {
            CoachHaptics.selection()
            selectedFeature = feature
        } label: {
            PremiumCard {
                HStack(spacing: 13) {
                    Image(systemName: icon)
                        .font(.title3)
                        .frame(width: 46, height: 46)
                        .background(PremiumTheme.cream)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.subheadline.weight(.semibold))
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(PremiumTheme.muted)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PremiumTheme.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SmartFeatureSheet: View {
    @Environment(\.dismiss) private var dismiss
    let feature: V2FeatureMenu.SmartFeature

    var body: some View {
        ZStack(alignment: .topTrailing) {
            destination
                .padding(.top, 8)

            Button {
                CoachHaptics.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PremiumTheme.ink)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.top, 8)
            .accessibilityLabel("Close smart feature")
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch feature {
        case .discovery:
            ProductDiscoveryView()
        case .progress:
            SmartFeaturesView()
        case .intelligence:
            ProductIntelligenceView()
        case .reminders:
            SmartRemindersView()
        case .photos:
            ProgressPhotoCaptureView()
        }
    }
}
