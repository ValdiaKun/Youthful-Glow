import SwiftUI

struct V2FeatureLauncher: View {
    @State private var showing = false

    var body: some View {
        Button {
            CoachHaptics.selection()
            showing = true
        } label: {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 188)
        .sheet(isPresented: $showing) {
            V2FeatureMenu()
        }
    }
}

struct V2FeatureMenu: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            CapsuleLabel(text: "Youthful 2")
                            Text("Smart tools").font(.system(size: 34, weight: .semibold, design: .serif))
                            Text("Everything added to make your routine more useful, measurable and personal.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                        }

                        featureLink("My Progress", "Streaks, completion, recommendations and product health.", "chart.xyaxis.line", SmartFeaturesView())
                        featureLink("Product Intelligence", "Opened dates, run-out estimates, expiration and notes.", "drop.circle.fill", ProductIntelligenceView())
                        featureLink("Smart Reminders", "Morning, evening and custom reminder times.", "bell.badge.fill", SmartRemindersView())
                        featureLink("Compare Progress Photos", "Add photos from your library or camera, then compare two dates side-by-side.", "rectangle.split.2x1", ProgressPhotoCaptureView())
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Smart tools")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private func featureLink<Destination: View>(_ title: String, _ detail: String, _ icon: String, _ destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            PremiumCard {
                HStack(spacing: 13) {
                    Image(systemName: icon)
                        .font(.title3)
                        .frame(width: 46, height: 46)
                        .background(PremiumTheme.cream)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.subheadline.weight(.semibold))
                        Text(detail).font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}