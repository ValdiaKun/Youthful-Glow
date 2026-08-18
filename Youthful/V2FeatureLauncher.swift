import SwiftUI

struct V2FeatureLauncher: View {
    @State private var showing = false
    @State private var selectedFeature: V2FeatureMenu.SmartFeature?
    @State private var position: CGPoint = .zero
    @State private var dragStartPosition: CGPoint = .zero
    @State private var hasStoredPosition = false

    private let dockSize: CGFloat = 48
    private let shortcutSize: CGFloat = 40
    private let edgePadding: CGFloat = 18
    private let shortcutSpacing: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let safe = proxy.safeAreaInsets
            let bounds = proxy.size
            let defaultPosition = CGPoint(
                x: bounds.width - edgePadding - dockSize / 2,
                y: bounds.height - safe.bottom - 150
            )

            dock
                .position(hasStoredPosition ? clamped(position, in: bounds, safe: safe) : defaultPosition)
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            if !hasStoredPosition {
                                position = defaultPosition
                                dragStartPosition = defaultPosition
                                hasStoredPosition = true
                                CoachHaptics.selection()
                            }
                            position = CGPoint(
                                x: dragStartPosition.x + value.translation.width,
                                y: dragStartPosition.y + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                position = snap(position, in: bounds, safe: safe)
                            }
                            CoachHaptics.selection()
                        }
                )
                .onAppear {
                    if !hasStoredPosition {
                        position = defaultPosition
                    }
                }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(item: $selectedFeature) { feature in
            SmartFeatureSheet(feature: feature)
        }
    }

    private var dock: some View {
        ZStack(alignment: .bottom) {
            if showing {
                expandedMenu
                    .offset(y: -(dockSize + 14))
                    .transition(.scale(scale: 0.82, anchor: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    showing.toggle()
                }
                CoachHaptics.selection()
            } label: {
                Image(systemName: showing ? "xmark" : "sparkles.rectangle.stack.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: dockSize, height: dockSize)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showing ? "Close smart features" : "Open smart features")
        }
        .frame(width: dockSize, height: 4 * shortcutSize + 3 * shortcutSpacing + dockSize + 24)
    }

    private var expandedMenu: some View {
        VStack(spacing: shortcutSpacing) {
            featureShortcut(.progress, "chart.xyaxis.line", "Progress")
            featureShortcut(.intelligence, "drop.circle.fill", "Products")
            featureShortcut(.reminders, "bell.badge.fill", "Reminders")
            featureShortcut(.photos, "rectangle.split.2x1", "Photos")
        }
    }

    private func featureShortcut(_ feature: V2FeatureMenu.SmartFeature, _ icon: String, _ label: String) -> some View {
        Button {
            CoachHaptics.selection()
            showing = false
            selectedFeature = feature
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: shortcutSize, height: shortcutSize)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
                .contentShape(Circle())
                .accessibilityLabel(label)
        }
        .buttonStyle(.plain)
    }

    private func clamped(_ point: CGPoint, in size: CGSize, safe: EdgeInsets) -> CGPoint {
        let minX = edgePadding + dockSize / 2
        let maxX = size.width - edgePadding - dockSize / 2
        let minY = safe.top + edgePadding + dockSize / 2
        let maxY = size.height - safe.bottom - edgePadding - dockSize / 2
        return CGPoint(x: min(max(point.x, minX), maxX), y: min(max(point.y, minY), maxY))
    }

    private func snap(_ point: CGPoint, in size: CGSize, safe: EdgeInsets) -> CGPoint {
        let clampedPoint = clamped(point, in: size, safe: safe)
        let left = edgePadding + dockSize / 2
        let right = size.width - edgePadding - dockSize / 2
        return CGPoint(
            x: clampedPoint.x < size.width / 2 ? left : right,
            y: clampedPoint.y
        )
    }
}

struct V2FeatureMenu: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: SmartFeature?

    enum SmartFeature: String, Identifiable {
        case progress, intelligence, reminders, photos
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
                            Text("Smart tools").font(.system(size: 34, weight: .semibold, design: .serif))
                            Text("Everything added to make your routine more useful, measurable and personal.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                        }

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
